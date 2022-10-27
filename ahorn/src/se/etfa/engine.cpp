#include "se/etfa/engine.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/spdlog.h"

using namespace se::etfa;

Engine::Engine(std::unique_ptr<Configuration> configuration)
    : _configuration(std::move(configuration)),
      _termination_criteria(TerminationCriteria::CYCLE_BOUND | TerminationCriteria::COVERAGE), _cycle(0),
      _solver(std::make_unique<Solver>()), _test_suite(std::make_unique<TestSuite>(*_solver)),
      _explorer(std::make_unique<Explorer>()),
      _executor(std::make_unique<Executor>(*_solver, *_explorer, *_test_suite)),
      _merger(std::make_unique<Merger>(*_solver, *_executor)) {
    if (_configuration->_cycle_bound.has_value()) {
        _cycle_bound = *(_configuration->_cycle_bound);
    }
    if (_configuration->_time_out.has_value()) {
        _time_out = *(_configuration->_time_out);
        _termination_criteria = _termination_criteria | TerminationCriteria::TIME_OUT;
    }
}

Solver &Engine::getSolver() const {
    return *_solver;
}

void Engine::run(summarization::Summarizer &summarizer, const Cfg &cfg) {
    using namespace std::literals;
    auto logger = spdlog::get("ETFA");
    _begin_time_point = std::chrono::system_clock::now();
    initialize(summarizer, cfg);
    while (!isTerminationCriteriaMet()) {
        std::chrono::time_point<std::chrono::system_clock> begin_time_point = std::chrono::system_clock::now();
        SPDLOG_LOGGER_INFO(logger, "#############################################");
        SPDLOG_LOGGER_INFO(logger, "Cycle: {}", _cycle);
        SPDLOG_LOGGER_INFO(logger, "Explorer:\n{}", *_explorer);
        std::pair<std::unique_ptr<Context>, boost::optional<TerminationCriteria>> result = step();
        if (result.second.has_value()) {
            SPDLOG_LOGGER_TRACE(logger, "Engine encountered local termination.");
            break;
        }
        _cycle = _cycle + 1;
        std::unique_ptr<Context> succeeding_cycle_context = std::move(result.first);
        assert(succeeding_cycle_context != nullptr);
        long elapsed_time = (std::chrono::system_clock::now() - begin_time_point) / 1ms;
        SPDLOG_LOGGER_TRACE(logger, "Step took {}ms, resulting succeeding cycle context:\n{}", elapsed_time,
                            *succeeding_cycle_context);
        _explorer->push(std::move(succeeding_cycle_context));
    }
    long elapsed_time = (std::chrono::system_clock::now() - _begin_time_point) / 1ms;
    std::cout << "Run took " << elapsed_time << "ms." << std::endl;
    std::cout << "Of the total run time " << elapsed_time << "ms, summary application checking took "
              << _executor->_summary_application_checking_time << "ms, that is "
              << ((float) _executor->_summary_application_checking_time / (float) elapsed_time) * 100 << "%."
              << std::endl;
    std::cout << "Engine reached the following statement and branch coverage: (" << _explorer->_statement_coverage
              << ", " << _explorer->_branch_coverage << ")." << std::endl;
    std::cout << "A total of " << _test_suite->_test_cases.size() << " branch-covering test cases were created."
              << std::endl;
}

void Engine::initialize(summarization::Summarizer &summarizer, const Cfg &cfg) {
    // reset
    _cycle = 0;
    // initialize
    _executor->initialize(summarizer, cfg);
    _explorer->initialize(cfg);
    _merger->initialize(cfg);
    // initial state construction
    const Vertex &vertex = cfg.getEntry();
    std::map<std::string, z3::expr> symbolic_valuations;
    std::map<std::string, unsigned int> flattened_name_to_version;
    for (auto it = cfg.flattenedInterfaceBegin(); it != cfg.flattenedInterfaceEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        flattened_name_to_version.emplace(flattened_name, 0);
        std::string contextualized_name = flattened_name + "_" + std::to_string(0) + "__" + std::to_string(_cycle);
        const ir::DataType &data_type = it->getDataType();
        z3::expr concrete_valuation = it->hasInitialization() ? _solver->makeValue(it->getInitialization())
                                                              : _solver->makeDefaultValue(data_type);
        // distinguish between "whole-program" input variables and local/output variables
        if (_executor->isWholeProgramInput(flattened_name)) {
            z3::expr symbolic_valuation = _solver->makeConstant(contextualized_name, data_type);
            symbolic_valuations.emplace(contextualized_name, symbolic_valuation);
        } else {
            symbolic_valuations.emplace(contextualized_name, concrete_valuation);
        }
    }
    std::vector<z3::expr> path_constraint{_solver->makeBooleanValue(true)};
    std::unique_ptr<State> state = std::make_unique<State>(
            vertex, std::move(symbolic_valuations), std::move(path_constraint), std::move(flattened_name_to_version));
    // initial context construction
    unsigned int cycle = _cycle;
    std::deque<std::shared_ptr<Frame>> call_stack{std::make_shared<Frame>(cfg, cfg.getName(), cfg.getEntryLabel())};
    std::unique_ptr<Context> context = std::make_unique<Context>(cycle, std::move(state), std::move(call_stack));
    _explorer->push(std::move(context));
}

bool Engine::isTerminationCriteriaMet() const {
    auto logger = spdlog::get("ETFA");
    bool termination_criteria_met = true;
    if (_termination_criteria & TerminationCriteria::TIME_OUT) {
        if (!isTimeOut()) {
            termination_criteria_met = false;
        } else {
            SPDLOG_LOGGER_TRACE(logger, "Termination criteria \"TIME_OUT\" met, terminating engine.");
            return true;
        }
    }
    if (_termination_criteria & TerminationCriteria::CYCLE_BOUND) {
        if (_cycle < _cycle_bound) {
            termination_criteria_met = false;
        } else {
            SPDLOG_LOGGER_TRACE(logger, "Termination criteria \"CYCLE_BOUND\" met, terminating engine.");
            return true;
        }
    }
    if (_termination_criteria & TerminationCriteria::COVERAGE) {
        constexpr float EPSILON = 0.0001;
        if (std::abs(1 - _explorer->_branch_coverage) > EPSILON ||
            std::abs(1 - _explorer->_statement_coverage) > EPSILON) {
            termination_criteria_met = false;
        } else {
            SPDLOG_LOGGER_TRACE(logger, "Termination criteria \"COVERAGE\" met, terminating engine.");
            return true;
        }
    }
    return termination_criteria_met;
}

boost::optional<Engine::TerminationCriteria> Engine::isLocalTerminationCriteriaMet() const {
    auto logger = spdlog::get("ETFA");
    if (_termination_criteria & TerminationCriteria::TIME_OUT) {
        if (isTimeOut()) {
            SPDLOG_LOGGER_TRACE(logger, "Local termination criteria \"TIME_OUT\" met, terminating engine.");
            return TerminationCriteria::TIME_OUT;
        }
    }
    if (_termination_criteria & TerminationCriteria::COVERAGE) {
        constexpr float EPSILON = 0.0001;
        if (std::abs(1 - _explorer->_branch_coverage) <= EPSILON &&
            std::abs(1 - _explorer->_statement_coverage) <= EPSILON) {
            SPDLOG_LOGGER_TRACE(logger, "Local termination criteria \"COVERAGE\" met, terminating engine.");
            return TerminationCriteria::COVERAGE;
        }
    }
    return boost::none;
}

bool Engine::isTimeOut() const {
    using namespace std::literals;
    auto elapsed_time = (std::chrono::system_clock::now() - _begin_time_point) / 1ms;
    if (elapsed_time < _time_out) {
        return false;
    } else {
        return true;
    }
}

std::pair<std::unique_ptr<Context>, boost::optional<Engine::TerminationCriteria>> Engine::step() {
    auto logger = spdlog::get("ETFA");
    std::unique_ptr<Context> succeeding_cycle_context;
    while (!_explorer->isEmpty() || !_merger->isEmpty()) {
        SPDLOG_LOGGER_TRACE(logger, "Explorer:\n{}", *_explorer);
        SPDLOG_LOGGER_TRACE(logger, "Merger:\n{}", *_merger);
        if (_explorer->isEmpty()) {
            assert(!_merger->isEmpty());
            std::unique_ptr<Context> merged_context = _merger->merge();
            _explorer->push(std::move(merged_context));
        } else {
            std::unique_ptr<Context> context = _explorer->pop();
            // XXX the check for local termination should always occur within the main frame, i.e., to allow for the
            // complete generation of summaries
            const Frame &frame = context->getFrame();
            const Cfg &cfg = frame.getCfg();
            if (cfg.getType() == Cfg::Type::PROGRAM) {
                boost::optional<TerminationCriteria> local_termination_criteria = isLocalTerminationCriteriaMet();
                if (local_termination_criteria.has_value()) {
                    return std::pair(nullptr, local_termination_criteria);
                }
            }
            const State &state = context->getState();
            const Vertex &vertex = state.getVertex();
            unsigned int label = vertex.getLabel();
            std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>>
                    succeeding_contexts = _executor->execute(std::move(context));
            for (std::unique_ptr<Context> &succeeding_context : succeeding_contexts.first) {
                std::pair<bool, bool> coverage = _explorer->updateCoverage(label, *succeeding_context);
                if (coverage.second) {
                    SPDLOG_LOGGER_TRACE(
                            logger, "Branch coverage has been increased, deriving test case from succeeding context.");
                    _test_suite->deriveTestCase(*succeeding_context);
                }
                if (_cycle == succeeding_context->getCycle()) {
                    if (_merger->reachedMergePoint(*succeeding_context)) {
                        _merger->push(std::move(succeeding_context));
                    } else {
                        _explorer->push(std::move(succeeding_context));
                    }
                } else {
                    assert(_cycle < succeeding_context->getCycle());
                    assert(!succeeding_contexts.second.has_value());
                    assert(!_merger->reachedMergePoint(*succeeding_context));
                    succeeding_cycle_context = std::move(succeeding_context);
                }
            }
            // forked succeeding context
            if (succeeding_contexts.second.has_value()) {
                assert(succeeding_contexts.first.size() == 1);
                std::unique_ptr<Context> forked_succeeding_context = std::move(*succeeding_contexts.second);
                std::pair<bool, bool> coverage = _explorer->updateCoverage(label, *forked_succeeding_context);
                if (coverage.second) {
                    SPDLOG_LOGGER_TRACE(logger,
                                        "Branch coverage has been increased, deriving test case from forked succeeding "
                                        "context.");
                    _test_suite->deriveTestCase(*forked_succeeding_context);
                }
                assert(_cycle == forked_succeeding_context->getCycle());
                if (_merger->reachedMergePoint(*forked_succeeding_context)) {
                    _merger->push(std::move(forked_succeeding_context));
                } else {
                    _explorer->push(std::move(forked_succeeding_context));
                }
            }
        }
    }
    return std::pair(std::move(succeeding_cycle_context), boost::none);
}