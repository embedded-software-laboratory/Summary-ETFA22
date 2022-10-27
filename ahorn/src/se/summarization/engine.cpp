#include "se/summarization/engine.h"
#include "ir/instruction/call_instruction.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/spdlog.h"

using namespace se::summarization;

Engine::Engine(etfa::Solver &solver)
    : _solver(&solver), _executor(std::make_unique<Executor>(*_solver)), _explorer(std::make_unique<Explorer>()) {}

void Engine::run(const Cfg &cfg) {
    using namespace std::literals;
    auto logger = spdlog::get("Summarization");
    _begin_time_point = std::chrono::system_clock::now();
    initialize(cfg);
    while (!_explorer->isEmpty()) {
        step();
    }
    long elapsed_time = (std::chrono::system_clock::now() - _begin_time_point) / 1ms;
    std::cout << "Summarization took " << elapsed_time << "ms." << std::endl;
    for (auto &name_to_summaries : _executor->_summarizer->_name_to_summaries) {
        std::cout << "Generated " << name_to_summaries.second.size() << " summarie(s) for function block "
                  << name_to_summaries.first << "." << std::endl;
    }
}

Summarizer &Engine::getSummarizer() const {
    return *_executor->_summarizer;
}

// XXX this function is responsible for determining what code fragments to summarize; currently FBs
void Engine::initialize(const Cfg &cfg) {
    _executor->initialize(cfg);
    assert(cfg.getType() == Cfg::Type::PROGRAM);
    std::shared_ptr<Frame> frame = std::make_shared<Frame>(cfg, cfg.getName(), cfg.getEntryLabel());
    std::set<std::string> type_representative_names;
    for (auto it = cfg.verticesBegin(); it != cfg.verticesEnd(); ++it) {
        unsigned int label = it->getLabel();
        ir::Instruction *instruction = it->getInstruction();
        if (auto *call_instruction = dynamic_cast<ir::CallInstruction *>(instruction)) {
            const Edge &intraprocedural_edge = cfg.getIntraproceduralCallToReturnEdge(label);
            unsigned int return_label = intraprocedural_edge.getTargetLabel();
            const ir::VariableAccess &variable_access = call_instruction->getVariableAccess();
            std::shared_ptr<ir::Variable> variable = variable_access.getVariable();
            const ir::DataType &data_type = variable->getDataType();
            assert(data_type.getKind() == ir::DataType::Kind::DERIVED_TYPE);
            std::string type_representative_name = data_type.getName();
            if (type_representative_names.count(type_representative_name)) {
                // XXX there can be multiple calls to the same function block
                // XXX As summarization does not consider the context it suffices to only summarize the call
                // XXX once for all call locations
                continue;
            } else {
                type_representative_names.insert(type_representative_name);
            }
            const Cfg &callee_cfg = cfg.getCfg(type_representative_name);
            // XXX currently we only support "one-callee-depth", i.e., nested FBs can't be summarized yet
            assert(!callee_cfg.hasCallees());
            std::string scope = frame->getScope() + "." + variable->getName();
            std::shared_ptr<Frame> callee_frame = std::make_shared<Frame>(callee_cfg, scope, return_label);

            const Vertex &vertex = callee_cfg.getEntry();
            std::string assumption_literal_name =
                    "b_" + callee_frame->getScope() + "_" + std::to_string(callee_cfg.getEntryLabel());
            z3::expr assumption_literal = _solver->makeBooleanConstant(assumption_literal_name);
            std::map<std::string, std::vector<z3::expr>> assumption_literals{
                    {assumption_literal_name, std::vector<z3::expr>{_solver->makeBooleanValue(true)}}};
            std::map<std::string, std::vector<z3::expr>> assumptions;
            std::map<std::string, std::map<std::string, z3::expr>> hard_constraints;
            std::map<std::string, z3::expr> symbolic_valuations;
            std::map<std::string, unsigned int> flattened_name_to_version;
            const ir::Interface &interface = callee_cfg.getInterface();
            for (auto var_it = interface.variablesBegin(); var_it != interface.variablesEnd(); ++var_it) {
                std::string flattened_name = callee_frame->getScope() + "." + var_it->getName();
                flattened_name_to_version.emplace(flattened_name, 0);
                std::string contextualized_name = flattened_name + "_" + std::to_string(0);
                const ir::DataType &var_data_type = var_it->getDataType();
                z3::expr symbolic_valuation = _solver->makeConstant(contextualized_name, var_data_type);
                symbolic_valuations.emplace(contextualized_name, symbolic_valuation);
            }

            std::unique_ptr<State> state = std::make_unique<State>(
                    vertex, assumption_literal, std::move(assumption_literals), std::move(assumptions),
                    std::move(hard_constraints), std::move(flattened_name_to_version));

            // initial context construction
            std::deque<std::shared_ptr<Frame>> call_stack{frame, callee_frame};
            std::unique_ptr<Context> context = std::make_unique<Context>(std::move(state), std::move(call_stack));
            _explorer->push(std::move(context));
        }
    }
}

void Engine::step() {
    std::unique_ptr<Context> context = _explorer->pop();
    std::vector<std::unique_ptr<Context>> succeeding_contexts = _executor->execute(std::move(context));
    for (std::unique_ptr<Context> &succeeding_context : succeeding_contexts) {
        _explorer->push(std::move(succeeding_context));
    }
}