#include "se/etfa/execution/executor.h"
#include "ir/instruction/assignment_instruction.h"
#include "ir/instruction/call_instruction.h"
#include "ir/instruction/if_instruction.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/spdlog.h"

#include <chrono>

using namespace se::etfa;

Executor::Executor(Solver &solver, Explorer &explorer, TestSuite &test_suite)
    : _solver(&solver), _explorer(&explorer), _test_suite(&test_suite), _encoder(std::make_unique<Encoder>(*_solver)),
      _summarizer(nullptr), _flattened_name_to_version(std::map<std::string, unsigned int>()),
      _whole_program_inputs(std::set<std::string>()), _context(nullptr), _forked_context(boost::none),
      _summarized_contexts(std::vector<std::unique_ptr<Context>>()) {}

unsigned int Executor::getVersion(const std::string &flattened_name) const {
    assert(_flattened_name_to_version.find(flattened_name) != _flattened_name_to_version.end());
    return _flattened_name_to_version.at(flattened_name);
}

void Executor::setVersion(const std::string &flattened_name, unsigned int version) {
    assert(_flattened_name_to_version.find(flattened_name) != _flattened_name_to_version.end());
    _flattened_name_to_version.at(flattened_name) = version;
}

bool Executor::isWholeProgramInput(const std::string &flattened_name) const {
    return _whole_program_inputs.find(flattened_name) != _whole_program_inputs.end();
}

std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>>
Executor::execute(std::unique_ptr<Context> context) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_TRACE(logger, "Executing context: \n{}", *context);

    State &state = context->getState();
    const Vertex &vertex = state.getVertex();
    Frame &frame = context->getFrame();
    const Cfg &cfg = frame.getCfg();
    SPDLOG_LOGGER_INFO(logger, "{}", vertex);

    std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>> succeeding_contexts;
    switch (vertex.getType()) {
        case Vertex::Type::ENTRY: {
            switch (cfg.getType()) {
                case Cfg::Type::PROGRAM: {
                    handleProgramEntryVertex(cfg, vertex, state);
                    succeeding_contexts.first.push_back(std::move(context));
                    break;
                }
                case Cfg::Type::FUNCTION_BLOCK: {
                    handleFunctionBlockEntryVertex(frame, *context, state);
                    succeeding_contexts.first.push_back(std::move(context));
                    break;
                }
                case Cfg::Type::FUNCTION: {
                    handleFunctionEntryVertex();
                    break;
                }
                default:
                    throw std::runtime_error("Unexpected cfg type encountered.");
            }
            break;
        }
        case Vertex::Type::REGULAR: {
            succeeding_contexts = handleRegularVertex(vertex, std::move(context));
            break;
        }
        case Vertex::Type::EXIT: {
            switch (cfg.getType()) {
                case Cfg::Type::PROGRAM: {
                    handleProgramExitVertex(frame, *context, state);
                    succeeding_contexts.first.push_back(std::move(context));
                    break;
                }
                case Cfg::Type::FUNCTION_BLOCK: {
                    handleFunctionBlockExitVertex(frame, *context, state);
                    succeeding_contexts.first.push_back(std::move(context));
                    break;
                }
                case Cfg::Type::FUNCTION: {
                    handleFunctionExitVertex();
                    break;
                }
                default:
                    throw std::runtime_error("Unexpected cfg type encountered.");
            }
            break;
        }
        default:
            throw std::runtime_error("Unexpected vertex type encountered.");
    }

    return succeeding_contexts;
}

void Executor::initialize(summarization::Summarizer &summarizer, const Cfg &cfg) {
    // reset
    _flattened_name_to_version.clear();
    _whole_program_inputs.clear();
    // initialize
    _summarizer = &summarizer;
    for (auto it = cfg.flattenedInterfaceBegin(); it != cfg.flattenedInterfaceEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        _flattened_name_to_version.emplace(std::move(flattened_name), 0);
    }
    const ir::Interface &interface = cfg.getInterface();
    for (auto it = interface.inputVariablesBegin(); it != interface.inputVariablesEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        _whole_program_inputs.emplace(std::move(flattened_name));
    }
}

void Executor::handleProgramEntryVertex(const Cfg &cfg, const Vertex &vertex, State &state) {
    unsigned int label = vertex.getLabel();
    std::vector<unsigned int> succeeding_labels = cfg.getSucceedingLabels(label);
    assert(succeeding_labels.size() == 1);
    unsigned int next_label = succeeding_labels.at(0);
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);
}

void Executor::handleFunctionBlockEntryVertex(const Frame &frame, const Context &context, State &state) {
    const Vertex &vertex = state.getVertex();
    const Cfg &cfg = frame.getCfg();
    unsigned int cycle = context.getCycle();
    unsigned int label = vertex.getLabel();
    std::vector<unsigned int> succeeding_labels = cfg.getSucceedingLabels(label);
    assert(succeeding_labels.size() == 1);
    unsigned int next_label = succeeding_labels.at(0);
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);
}

void Executor::handleFunctionEntryVertex() {
    throw std::logic_error("Not implemented yet.");
}

std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>>
Executor::handleRegularVertex(const Vertex &vertex, std::unique_ptr<Context> context) {
    _context = std::move(context);
    _forked_context = boost::none;
    _summarized_contexts.clear();

    ir::Instruction *instruction = vertex.getInstruction();
    if (instruction == nullptr) {
        // XXX intermediate decision vertex
        handleIntermediateDecisionVertex(vertex);
    } else {
        assert(instruction != nullptr);
        instruction->accept(*this);
    }

    std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>> succeeding_contexts;
    if (_forked_context.has_value()) {
        succeeding_contexts.second = std::move(*_forked_context);
    }
    if (_summarized_contexts.empty()) {
        succeeding_contexts.first.push_back(std::move(_context));
    } else {
        for (std::unique_ptr<Context> &summarized_context : _summarized_contexts) {
            succeeding_contexts.first.push_back(std::move(summarized_context));
        }
    }
    return succeeding_contexts;
}

void Executor::handleIntermediateDecisionVertex(const Vertex &vertex) {
    const Frame &frame = _context->getFrame();
    const Cfg &cfg = frame.getCfg();
    State &state = _context->getState();

    // update control-flow
    unsigned int label = vertex.getLabel();
    std::vector<std::shared_ptr<Edge>> outgoing_edges = cfg.getOutgoingEdges(label);
    assert(outgoing_edges.size() == 1);
    const Edge &edge = *outgoing_edges[0];
    unsigned int next_label = edge.getTargetLabel();
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);
}

void Executor::handleProgramExitVertex(Frame &frame, Context &context, State &state) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_TRACE(logger, "Handling program exit vertex...");

    unsigned int cycle = context.getCycle();
    unsigned int next_cycle = cycle + 1;
    const Cfg &cfg = frame.getCfg();
    assert(context.getCallStackDepth() == 1);
    unsigned int next_label = frame.getReturnLabel();

    // prepare "initial" valuations for the next cycle, relate "local" variables with each other and keep
    // "whole-program" input variables unconstrained
    for (auto it = cfg.flattenedInterfaceBegin(); it != cfg.flattenedInterfaceEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        // reset version globally
        _flattened_name_to_version.at(flattened_name) = 0;
        std::string contextualized_name = flattened_name + "_" + std::to_string(0) + "__" + std::to_string(next_cycle);

        // distinguish between "whole-program" input variables and local/output variables
        if (isWholeProgramInput(flattened_name)) {
            z3::expr symbolic_valuation = _solver->makeConstant(contextualized_name, it->getDataType());
            state.setSymbolicValuation(contextualized_name, symbolic_valuation);
        } else {
            unsigned int highest_version = state.getVersion(flattened_name);
            z3::expr symbolic_valuation = state.getSymbolicValuation(
                    flattened_name + "_" + std::to_string(highest_version) + "__" + std::to_string(cycle));
            state.setSymbolicValuation(contextualized_name, symbolic_valuation);
        }
    }

    // XXX resetting the versions locally must be done after coupling the valuations of the prior cycle into the next
    // XXX cycle, else it is not possible to retrieve the highest version of a valuation reaching the end of the cycle
    for (auto it = cfg.flattenedInterfaceBegin(); it != cfg.flattenedInterfaceEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        // reset version locally
        state.setVersion(flattened_name, 0);
    }

    // XXX clear the path constraint (only possible AFTER merge, because the path constraint is embedded in the
    // XXX "ite"-expressions of the respective symbolic variables)
    state._path_constraint.clear();

    // update control-flow
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);
    context.setCycle(next_cycle);
}

void Executor::handleFunctionBlockExitVertex(const Frame &frame, Context &context, State &state) {
    unsigned int next_label = frame.getReturnLabel();
    context.popFrame();
    const Frame &caller_frame = context.getFrame();
    const Cfg &caller_cfg = caller_frame.getCfg();
    const Vertex &next_vertex = caller_cfg.getVertex(next_label);
    state.setVertex(next_vertex);
}

void Executor::handleFunctionExitVertex() {
    throw std::logic_error("Not implemented yet.");
}

void Executor::visit(const ir::AssignmentInstruction &instruction) {
    const ir::Expression &expression = instruction.getExpression();

    // encode rhs of the assignment
    z3::expr encoded_expression = _encoder->encode(expression, *_context);

    // encode lhs of the assignment
    const Frame &frame = _context->getFrame();
    const Cfg &cfg = frame.getCfg();
    const ir::VariableReference &variable_reference = instruction.getVariableReference();
    std::string name = variable_reference.getName();
    std::string flattened_name = frame.getScope() + "." + name;

    unsigned int cycle = _context->getCycle();
    State &state = _context->getState();
    unsigned int version = _flattened_name_to_version.at(flattened_name) + 1;
    // update version globally
    _flattened_name_to_version.at(flattened_name) = version;
    // update version locally
    state.setVersion(flattened_name, version);

    std::string contextualized_name = flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);

    // update concrete and symbolic valuations
    state.setSymbolicValuation(contextualized_name, encoded_expression);

    // update control-flow
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    const Edge &edge = cfg.getIntraproceduralEdge(label);
    unsigned int next_label = edge.getTargetLabel();
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);
}

void Executor::visit(const ir::CallInstruction &instruction) {
    using namespace std::literals;
    auto logger = spdlog::get("ETFA");

    const Frame &frame = _context->getFrame();
    const Cfg &caller = frame.getCfg();

    State &state = _context->getState();
    const Vertex &vertex = state.getVertex();

    unsigned int label = vertex.getLabel();
    const Edge &intraprocedural_edge = caller.getIntraproceduralCallToReturnEdge(label);
    unsigned int return_label = intraprocedural_edge.getTargetLabel();
    const Edge &interprocedural_edge = caller.getInterproceduralCallEdge(label);
    unsigned int next_label = interprocedural_edge.getTargetLabel();

    const ir::VariableAccess &variable_access = instruction.getVariableAccess();
    std::shared_ptr<ir::Variable> variable = variable_access.getVariable();
    const ir::DataType &data_type = variable->getDataType();
    assert(data_type.getKind() == ir::DataType::Kind::DERIVED_TYPE);
    std::string type_representative_name = data_type.getName();
    const Cfg &callee = caller.getCfg(type_representative_name);
    std::string scope = frame.getScope() + "." + variable->getName();
    std::shared_ptr<Frame> callee_frame = std::make_shared<Frame>(callee, scope, return_label);
    _context->pushFrame(callee_frame);

    std::chrono::time_point<std::chrono::system_clock> begin_time_point = std::chrono::system_clock::now();
    std::vector<summarization::Summary *> applicable_summaries = _summarizer->findApplicableSummary(*_context);
    long elapsed_time = (std::chrono::system_clock::now() - begin_time_point) / 1ms;
    _summary_application_checking_time += elapsed_time;
    if (!applicable_summaries.empty()) {
        for (summarization::Summary *applicable_summary : applicable_summaries) {
            SPDLOG_LOGGER_TRACE(logger, "Cloning context and applying applicable summary...");
            std::unique_ptr<Context> summarized_context = _context->clone();
            applySummary(*applicable_summary, *summarized_context);
            // update coverage
            for (const z3::expr &assumption_literal : applicable_summary->getAssumptionLiterals()) {
                std::string name = assumption_literal.to_string().substr(2, assumption_literal.to_string().size());
                std::size_t pos = name.find('_');
                unsigned int summarized_label = std::stoi(name.substr(pos + 1, name.length()));
                std::pair<bool, bool> coverage = _explorer->updateCoverage(callee, label, summarized_label);
                // If coverage increases, derive a test case
                if (coverage.second) {
                    SPDLOG_LOGGER_TRACE(
                            logger, "Branch coverage has been increased, deriving test case from summarized context.");
                    _test_suite->deriveTestCase(*summarized_context);
                }
                label = summarized_label;
            }
            _explorer->updateCoverage(callee, label, return_label);
            // update control-flow to the next intraprocedural label in the caller
            const Vertex &next_vertex = caller.getVertex(return_label);
            summarized_context->getState().setVertex(next_vertex);
            summarized_context->popFrame();
            SPDLOG_LOGGER_TRACE(logger, "Context:\n{}\nafter applying summary:\n{}", *summarized_context,
                                *applicable_summary);
            _summarized_contexts.push_back(std::move(summarized_context));
        }
        SPDLOG_LOGGER_TRACE(logger, "Summarized contexts:\n");
        for (const std::unique_ptr<Context> &summarized_context : _summarized_contexts) {
            SPDLOG_LOGGER_TRACE(logger, "{}", *summarized_context);
        }
    } else {
        // update control-flow
        const Vertex &next_vertex = callee.getVertex(next_label);
        state.setVertex(next_vertex);
    }
}

void Executor::visit(const ir::IfInstruction &instruction) {
    auto logger = spdlog::get("ETFA");

    const ir::Expression &expression = instruction.getExpression();

    // encode condition symbolically
    z3::expr encoded_expression = _encoder->encode(expression, *_context);
    z3::expr negated_encoded_expression = (!encoded_expression).simplify();

    // determine control-flow
    Frame &frame = _context->getFrame();
    const Cfg &cfg = frame.getCfg();
    State &state = _context->getState();
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    const Edge &true_edge = cfg.getTrueEdge(label);
    unsigned int next_positive_label = true_edge.getTargetLabel();
    const Vertex &next_positive_vertex = cfg.getVertex(next_positive_label);
    const Edge &false_edge = cfg.getFalseEdge(label);
    unsigned int next_negative_label = false_edge.getTargetLabel();
    const Vertex &next_negative_vertex = cfg.getVertex(next_negative_label);
    const std::vector<z3::expr> &path_constraint = state.getPathConstraint();

    z3::expr_vector expressions(_solver->getContext());
    for (const z3::expr &constraint : path_constraint) {
        expressions.push_back(constraint);
    }
    // add hard constraints, i.e., evaluate path constraint and expression under current valuations
    for (const auto &symbolic_valuation : state.getSymbolicValuations()) {
        if (symbolic_valuation.second.is_bool()) {
            expressions.push_back(_solver->makeBooleanConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else if (symbolic_valuation.second.is_int()) {
            expressions.push_back(_solver->makeIntegerConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }
    // try positive path
    expressions.push_back(encoded_expression);
    std::pair<z3::check_result, boost::optional<z3::model>> result = _solver->check(expressions);
    switch (result.first) {
        case z3::unsat: {
            assert(!result.second.has_value());
            SPDLOG_LOGGER_TRACE(logger,
                                "True branch is unsatisfiable, false branch must be satisfiable (no need to check).");
            // update control-flow
            state.setVertex(next_negative_vertex);
            state.pushPathConstraint(negated_encoded_expression);
            break;
        }
        case z3::sat: {
            SPDLOG_LOGGER_TRACE(logger, "True branch is satisfiable, checking whether false branch is satisfiable.");
            // check if negative path is also possible
            expressions.pop_back();
            expressions.push_back(negated_encoded_expression);
            result = _solver->check(expressions);
            switch (result.first) {
                case z3::unsat: {
                    assert(!result.second.has_value());
                    SPDLOG_LOGGER_TRACE(logger, "False branch is unsatisfiable, no fork.");
                    break;
                }
                case z3::sat: {
                    SPDLOG_LOGGER_TRACE(logger, "False branch is satisfiable, fork of execution context.");
                    _forked_context = _context->fork(next_negative_vertex, negated_encoded_expression);
                    break;
                }
                case z3::unknown:
                    // XXX fall-through
                default:
                    throw std::runtime_error("Unexpected z3::check_result encountered.");
            }
            // update control-flow
            state.setVertex(next_positive_vertex);
            state.pushPathConstraint(encoded_expression);
            break;
        }
        case z3::unknown:
            // XXX fall-through
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }
}

void Executor::visit(const ir::SequenceInstruction &instruction) {
    throw std::logic_error("Not implemented yet.");
}

void Executor::visit(const ir::WhileInstruction &instruction) {
    throw std::logic_error("Not implemented yet.");
}

void Executor::visit(const ir::GotoInstruction &instruction) {
    throw std::logic_error("Not implemented yet.");
}

void Executor::visit(const ir::HavocInstruction &instruction) {
    throw std::logic_error("Not implemented yet.");
}

bool Executor::containsUnconstrainedUninterpretedConstant(const State &state, const z3::expr &expression) const {
    z3::expr simplified_expression = expression.simplify();
    std::vector<z3::expr> uninterpreted_constants = _solver->getUninterpretedConstants(simplified_expression);
    if (uninterpreted_constants.empty()) {
        assert(simplified_expression.is_true() || simplified_expression.is_false() ||
               simplified_expression.is_numeral());
        return false;
    } else if (uninterpreted_constants.size() == 1) {
        std::string contextualized_name = uninterpreted_constants.at(0).decl().name().str();
        z3::expr nested_expression = state.getSymbolicValuation(contextualized_name);
        std::vector<z3::expr> nested_uninterpreted_constants = _solver->getUninterpretedConstants(nested_expression);
        if (nested_uninterpreted_constants.empty()) {
            assert(nested_expression.is_true() || nested_expression.is_false() || nested_expression.is_numeral());
            return false;
        } else if (nested_uninterpreted_constants.size() == 1) {
            std::string nested_contextualized_name = nested_uninterpreted_constants.at(0).decl().name().str();
            // XXX check for self-reference, as checking for whole-program input is not enough, because it could have
            // XXX been assigned or we have a havoc'ed variable
            if (contextualized_name == nested_contextualized_name) {
                return true;
            } else {
                return containsUnconstrainedUninterpretedConstant(state, nested_expression);
            }
        } else {
            return containsUnconstrainedUninterpretedConstant(state, nested_expression);
        }
    } else {
        bool contains_unconstrained_constant = false;
        for (const z3::expr &uninterpreted_constant : uninterpreted_constants) {
            if (containsUnconstrainedUninterpretedConstant(state, uninterpreted_constant)) {
                contains_unconstrained_constant = true;
                break;
            } else {
                std::string contextualized_name = uninterpreted_constant.decl().name().str();
                z3::expr nested_expression = state.getSymbolicValuation(contextualized_name);
                if (containsUnconstrainedUninterpretedConstant(state, nested_expression)) {
                    contains_unconstrained_constant = true;
                    break;
                }
            }
        }
        return contains_unconstrained_constant;
    }
}

void Executor::applySummary(const summarization::Summary &summary, Context &context) {
    auto logger = spdlog::get("ETFA");
    // 1. go through the symbolic valuations and collect the highest versions of the summarized fb's
    // variables
    // 2. go through the hard constraints of the summary and add for this particular cycle the symbolic
    // valuations by adding to the highest versions of 1. the local versioning -> does this ensure that there
    // is no conflict with other contexts? shouldn't we use the "global" SSA versioning from the executor
    // rather then the "local" one from the context?
    // 3. add them to the symbolic valuations of the context
    // 4. "reversioning" is the same for the assumptions, but add the assumptions to the path constraint
    // TODO: Step 4 may lead to bugs in the code, as the versions are not correctly aligned
    unsigned int cycle = context.getCycle();
    State &state = context.getState();

    // TODO: Problem: new variable versions are introduced for variables that are only read, invalidating the local
    //  store of the context.
    // Collect all written variables. Only add the read variables that were not written. Align the versions of the
    // written variables with the global store by introducing a new version. Align the versions of the read variables
    // with the local store.

    // collect all names from the summary
    std::set<std::string> written_names;
    std::set<std::string> read_names;
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        std::string name = hard_constraint.first;
        written_names.emplace(name);
    }
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(hard_constraint.second)) {
            std::string name = uninterpreted_constant.to_string();
            if (!written_names.count(name)) {
                read_names.emplace(name);
            }
        }
    }
    for (const z3::expr &assumption : summary.getAssumptions()) {
        for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(assumption)) {
            std::string name = uninterpreted_constant.to_string();
            if (!written_names.count(name)) {
                read_names.emplace(name);
            }
        }
    }

    std::map<std::string, unsigned int> flattened_name_to_highest_version;
    std::map<std::string, std::string> used_name_to_reversioned_name;
    for (const std::string &written_name : written_names) {
        std::size_t position = written_name.find('_');
        assert(position != std::string::npos);
        unsigned int summary_version = std::stoi(written_name.substr(position + 1, written_name.size()));
        std::string flattened_name = written_name.substr(0, position);
        unsigned int global_version = getVersion(flattened_name);
        unsigned int version = summary_version + global_version + 1;
        auto it = flattened_name_to_highest_version.find(flattened_name);
        if (it == flattened_name_to_highest_version.end()) {
            flattened_name_to_highest_version.emplace(flattened_name, version);
        } else {
            if (version > it->second) {
                it->second = version;
            }
        }
        std::string reversioned_name = flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
        used_name_to_reversioned_name.emplace(written_name, reversioned_name);
    }
    for (const std::string &read_name : read_names) {
        std::size_t position = read_name.find('_');
        assert(position != std::string::npos);
        unsigned int summary_version = std::stoi(read_name.substr(position + 1, read_name.size()));
        std::string flattened_name = read_name.substr(0, position);
        unsigned int local_version = state.getVersion(flattened_name);
        unsigned int version = local_version;
        auto it = flattened_name_to_highest_version.find(flattened_name);
        if (it == flattened_name_to_highest_version.end()) {
            flattened_name_to_highest_version.emplace(flattened_name, version);
        } else {
            if (version > it->second) {
                it->second = version;
            }
        }
        std::string reversioned_name = flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
        used_name_to_reversioned_name.emplace(read_name, reversioned_name);
    }

    std::map<std::string, z3::expr> symbolic_valuations;
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        std::string lhs = used_name_to_reversioned_name.at(hard_constraint.first);
        z3::expr rhs = hard_constraint.second;
        for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(rhs)) {
            z3::expr_vector src(_solver->getContext());
            src.push_back(uninterpreted_constant);
            z3::expr_vector dst(_solver->getContext());
            if (uninterpreted_constant.is_bool()) {
                dst.push_back(_solver->makeBooleanConstant(
                        used_name_to_reversioned_name.at(uninterpreted_constant.to_string())));
            } else if (uninterpreted_constant.is_int()) {
                dst.push_back(_solver->makeIntegerConstant(
                        used_name_to_reversioned_name.at(uninterpreted_constant.to_string())));
            } else {
                throw std::runtime_error("Unexpected z3::sort encountered.");
            }
            rhs = rhs.substitute(src, dst);
        }
        symbolic_valuations.emplace(lhs, rhs);
    }

    for (const auto &symbolic_valuation : symbolic_valuations) {
        SPDLOG_LOGGER_TRACE(logger, "{} -> {}", symbolic_valuation.first, symbolic_valuation.second.to_string());
    }

    std::vector<z3::expr> path_constraint;
    for (const auto &assumption : summary.getAssumptions()) {
        z3::expr substituted_assumption = assumption;
        for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(assumption)) {
            z3::expr_vector src(_solver->getContext());
            src.push_back(uninterpreted_constant);
            z3::expr_vector dst(_solver->getContext());
            if (uninterpreted_constant.is_bool()) {
                dst.push_back(_solver->makeBooleanConstant(
                        used_name_to_reversioned_name.at(uninterpreted_constant.to_string())));
            } else if (uninterpreted_constant.is_int()) {
                dst.push_back(_solver->makeIntegerConstant(
                        used_name_to_reversioned_name.at(uninterpreted_constant.to_string())));
            } else {
                throw std::runtime_error("Unexpected z3::sort encountered.");
            }
            substituted_assumption = substituted_assumption.substitute(src, dst);
        }
        path_constraint.push_back(substituted_assumption);
    }

    for (const z3::expr &constraint : path_constraint) {
        SPDLOG_LOGGER_TRACE(logger, "{}", constraint.to_string());
    }

    // update state with contents of summary
    for (const auto &symbolic_valuation : symbolic_valuations) {
        state.setSymbolicValuation(symbolic_valuation.first, symbolic_valuation.second);
    }
    for (const z3::expr &constraint : path_constraint) {
        state.pushPathConstraint(constraint);
    }

    // update versions "locally" and "globally"
    for (const auto &flattened_name_to_version : flattened_name_to_highest_version) {
        unsigned int version = getVersion(flattened_name_to_version.first);
        if (version < flattened_name_to_version.second) {
            setVersion(flattened_name_to_version.first, flattened_name_to_version.second);
        }
        state.setVersion(flattened_name_to_version.first, flattened_name_to_version.second);
    }
}