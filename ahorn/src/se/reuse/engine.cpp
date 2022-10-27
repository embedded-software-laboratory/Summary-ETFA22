#include "se/reuse/engine.h"
#include "ir/instruction/call_instruction.h"
#include "pass/change_annotation_collection_pass.h"
#include "se/utilities/fmt_formatter.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/fmt/ranges.h"
#include "spdlog/spdlog.h"

#include <memory>

using namespace se::reuse;

Engine::Engine(etfa::Solver &solver)
    : _solver(&solver), _executor(std::make_unique<Executor>(*_solver)), _explorer(std::make_unique<Explorer>()),
      _merger(std::make_unique<Merger>(*_solver, *_executor)) {}

// Phase 1 - Static Change Impact Analysis:
// Every summary which summarizes a path in a modified function block is invalidated in phase 1, regardless of the
// actual path taken within the summary. This is a quick and imprecise over-approximating classification.
std::shared_ptr<se::summarization::Summarizer> Engine::run(const Cfg &cfg, summarization::Summarizer &summarizer) {
    using namespace std::literals;
    auto logger = spdlog::get("Reuse");
    _begin_time_point = std::chrono::system_clock::now();
    std::map<std::string, std::vector<std::shared_ptr<summarization::Summary>>> name_to_valid_summaries;
    std::vector<std::shared_ptr<summarization::Summary>> invalid_summaries;
    std::map<std::string, std::vector<std::shared_ptr<summarization::Summary>>> name_to_regenerated_summaries;
    long p1_elapsed_time = 0;
    long p2_elapsed_time = 0;
    long p3_elapsed_time = 0;
    for (auto it = cfg.verticesBegin(); it != cfg.verticesEnd(); ++it) {
        unsigned int label = it->getLabel();
        ir::Instruction *instruction = it->getInstruction();
        if (auto *call_instruction = dynamic_cast<ir::CallInstruction *>(instruction)) {
            std::unique_ptr<Context> old_context = getInitialContext(cfg, label, *call_instruction);
            const Frame &frame = old_context->getFrame();
            const Cfg &callee_cfg = frame.getCfg();
            std::string name = callee_cfg.getFullyQualifiedName();
            name_to_valid_summaries.emplace(name, std::vector<std::shared_ptr<summarization::Summary>>());
            const auto &summaries = summarizer.getSummaries(callee_cfg.getFullyQualifiedName());
            std::unique_ptr<Context> old_encoded_context = generateVerificationConditions(std::move(old_context), true);
            std::unique_ptr<Context> new_context = getInitialContext(cfg, label, *call_instruction);
            std::unique_ptr<Context> new_encoded_context =
                    generateVerificationConditions(std::move(new_context), false);
            auto p1_begin_time_point = std::chrono::system_clock::now();
            std::set<unsigned int> change_annotated_labels = getChangeAnnotatedLabels(callee_cfg);
            p1_elapsed_time += (std::chrono::system_clock::now() - p1_begin_time_point) / 1ms;
            if (change_annotated_labels.empty()) {
                // all summaries are valid in the new version
                for (const auto &summary : summaries) {
                    name_to_valid_summaries.at(name).push_back(summary);
                }
            } else {
                for (const std::shared_ptr<summarization::Summary> &summary : summaries) {
                    auto p2_begin_time_point = std::chrono::system_clock::now();
                    bool valid = predicateSensitiveAnalysis(*old_encoded_context, change_annotated_labels, *summary);
                    p2_elapsed_time += (std::chrono::system_clock::now() - p2_begin_time_point) / 1ms;
                    if (valid) {
                        name_to_valid_summaries.at(name).push_back(summary);
                    } else {
                        auto p3_begin_time_point = std::chrono::system_clock::now();
                        valid = validityCheck(*new_encoded_context, *summary);
                        p3_elapsed_time += (std::chrono::system_clock::now() - p3_begin_time_point) / 1ms;
                        if (valid) {
                            name_to_valid_summaries.at(name).push_back(summary);
                        } else {
                            invalid_summaries.push_back(summary);
                            SPDLOG_LOGGER_TRACE(logger, "Summary is invalidated by all three phases, not reusable!");
                        }
                    }
                }
            }
            SPDLOG_LOGGER_TRACE(logger, "Validated {} of {} summaries for function block {}.",
                                name_to_valid_summaries.at(name).size(), summaries.size(), name);
            std::set<std::string> covered_assumption_literals;
            for (const std::shared_ptr<summarization::Summary> &valid_summary : name_to_valid_summaries.at(name)) {
                SPDLOG_LOGGER_TRACE(logger, "\n{}", *valid_summary);
                for (const z3::expr &assumption_literal : valid_summary->getAssumptionLiterals()) {
                    covered_assumption_literals.insert(assumption_literal.to_string());
                }
            }
            SPDLOG_LOGGER_TRACE(logger, "Invalidated {} of {} summaries for function block {}.",
                                invalid_summaries.size(), summaries.size(), callee_cfg.getFullyQualifiedName());
            for (const auto &invalid_summary : invalid_summaries) {
                SPDLOG_LOGGER_INFO(logger, "\n{}", *invalid_summary);
            }
            // remove all "visited" assumption literals -> only assumption literals not traversed by a summarized path
            // are left over, amounts to paths that need to be regenerated
            auto flattened_ass_lits = summarizer.flattenAssumptionLiterals(*new_encoded_context);
            for (const std::string &leck_mich : covered_assumption_literals) {
                auto itme = std::find_if(flattened_ass_lits.begin(), flattened_ass_lits.end(),
                                         [&leck_mich](const auto &lit) { return lit.to_string() == leck_mich; });
                if (itme != flattened_ass_lits.end()) {
                    flattened_ass_lits.erase(itme);
                }
            }
            SPDLOG_LOGGER_INFO(logger, "covered assumption literals: {}", covered_assumption_literals);
            // SPDLOG_LOGGER_INFO(logger, "new encoded context: {}", *new_encoded_context);

            auto path_candidates = determinePathCandidates(*new_encoded_context, flattened_ass_lits);
            SPDLOG_LOGGER_INFO(logger, "path candidates: {}", path_candidates);
            std::vector<std::vector<z3::expr>> paths = determineAssumptionLiteralPaths(*new_encoded_context);
            // TODO: determine paths that need to be "resummarized" as context encodes the whole FB
            // Idea: collect all paths through the FB, check which paths are already "summarized" by
            // comparing with the assumption literals in the valid summaries
            // TODO: It does not suffice to only look at the paths that were invalidated, does it? I
            //  think if new code has been added or code has been deleted, the assumption literals
            //  representing the paths are also "invalid" (not invariant to the change), hence
            //  collecting all paths and regenerating summaries for the paths that are left over when
            //  removing from the valid summary paths is the way to go
            // auto regenerated_valid_summary = summarizer.summarizePath(*new_encoded_context);
            // XXX remove all paths that are already summarized by a valid summary
            for (const auto &valid_summary : name_to_valid_summaries.at(name)) {
                auto summarized_path = valid_summary->getAssumptionLiterals();
                auto path_it = std::find_if(paths.begin(), paths.end(), [&summarized_path](const auto &path) {
                    bool found_path = true;
                    if (summarized_path.size() != path.size()) {
                        return false;
                    } else {
                        for (size_t i = 0; i < summarized_path.size(); ++i) {
                            if (!z3::eq(summarized_path.at(i), path.at(i))) {
                                found_path = false;
                            }
                        }
                    }
                    return found_path;
                });
                if (path_it != paths.end()) {
                    path_it->clear();
                    paths.erase(path_it);
                }
                SPDLOG_LOGGER_TRACE(logger, "{}", valid_summary->getAssumptionLiterals());
            }
            SPDLOG_LOGGER_TRACE(logger, "Remaining paths that require summary regeneration:\n{}", paths);
            SPDLOG_LOGGER_TRACE(logger, "Using new encoded context for summary regeneration:\n{}",
                                *new_encoded_context);
            if (!paths.empty()) {
                name_to_regenerated_summaries.emplace(name, std::vector<std::shared_ptr<summarization::Summary>>());
            }
            for (const std::vector<z3::expr> &path : paths) {
                auto summary = summarizer.summarizePath(*new_encoded_context, path);
                name_to_regenerated_summaries.at(name).push_back(std::move(summary));
            }
        }
    }
    long elapsed_time = (std::chrono::system_clock::now() - _begin_time_point) / 1ms;
    std::cout << "Summary reusability checking took " << elapsed_time << "ms." << std::endl;
    std::cout << "Phase 1 took " << p1_elapsed_time << "ms." << std::endl;
    std::cout << "Phase 2 took " << p2_elapsed_time << "ms." << std::endl;
    std::cout << "Phase 3 took " << p3_elapsed_time << "ms." << std::endl;
    for (auto &name_to_summaries : name_to_valid_summaries) {
        std::cout << "Validated " << name_to_summaries.second.size() << " summarie(s) for function block "
                  << name_to_summaries.first << "." << std::endl;
    }
    std::cout << "Invalidated " << invalid_summaries.size() << " summarie(s)." << std::endl;
    for (auto &name_to_summaries : name_to_regenerated_summaries) {
        std::cout << "Regenerated " << name_to_summaries.second.size() << " summarie(s) for function block "
                  << name_to_summaries.first << "." << std::endl;
        for (std::shared_ptr<summarization::Summary> &summary : name_to_summaries.second) {
            name_to_valid_summaries.at(name_to_summaries.first).push_back(summary);
        }
    }
    return std::make_shared<summarization::Summarizer>(*_solver, std::move(name_to_valid_summaries));
}

std::set<unsigned int> Engine::getChangeAnnotatedLabels(const Cfg &cfg) {
    auto change_annotation_collection_pass = std::make_unique<pass::ChangeAnnotationCollectionPass>();
    std::set<unsigned int> change_annotated_labels = change_annotation_collection_pass->apply(cfg, false);
    return change_annotated_labels;
}

std::unique_ptr<Context> Engine::getInitialContext(const Cfg &cfg, unsigned int label,
                                                   const ir::CallInstruction &instruction) {
    assert(cfg.getType() == Cfg::Type::PROGRAM);
    std::shared_ptr<Frame> frame = std::make_shared<Frame>(cfg, cfg.getName(), cfg.getEntryLabel());
    _explorer->initialize();
    _executor->initialize(cfg);
    _merger->initialize(cfg);

    const Edge &intraprocedural_edge = cfg.getIntraproceduralCallToReturnEdge(label);
    unsigned int return_label = intraprocedural_edge.getTargetLabel();
    const ir::VariableAccess &variable_access = instruction.getVariableAccess();
    std::shared_ptr<ir::Variable> variable = variable_access.getVariable();
    const ir::DataType &data_type = variable->getDataType();
    assert(data_type.getKind() == ir::DataType::Kind::DERIVED_TYPE);
    std::string type_representative_name = data_type.getName();
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

    std::unique_ptr<State> state =
            std::make_unique<State>(vertex, assumption_literal, std::move(assumption_literals), std::move(assumptions),
                                    std::move(hard_constraints), std::move(flattened_name_to_version));

    // initial context construction
    std::deque<std::shared_ptr<Frame>> call_stack{frame, callee_frame};
    std::unique_ptr<Context> context = std::make_unique<Context>(std::move(state), std::move(call_stack));

    return context;
}

bool Engine::predicateSensitiveAnalysis(const Context &context, const std::set<unsigned int> &change_annotated_labels,
                                        const summarization::Summary &summary) {
    auto logger = spdlog::get("Reuse");
    SPDLOG_LOGGER_TRACE(logger, "Predicate sensitive analysis of summary:\n{}\nunder context:\n{}", summary, context);

    const Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();
    const State &state = context.getState();
    std::map<std::string, std::map<std::string, z3::expr>> hard_constraints = state.getHardConstraints();
    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());
    hard_constraints.emplace(entry_assumption_literal_name, std::map<std::string, z3::expr>());
    hard_constraints.at(entry_assumption_literal_name).emplace("modified", _solver->makeBooleanValue(false));
    for (unsigned int label : change_annotated_labels) {
        std::string assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(label);
        auto it = hard_constraints.find(assumption_literal_name);
        if (it == hard_constraints.end()) {
            // XXX e.g., if instruction contains change expression
            hard_constraints.emplace(assumption_literal_name, std::map<std::string, z3::expr>());
            hard_constraints.at(assumption_literal_name).emplace("modified", _solver->makeBooleanValue(true));
        } else {
            it->second.emplace("modified", _solver->makeBooleanValue(true));
        }
    }
    std::map<std::string, std::vector<z3::expr>> assumptions = state.getAssumptions();

    z3::context &z3_context = _solver->getContext();

    // lower assumptions of summary
    z3::expr_vector lowered_assumptions(z3_context);
    for (const z3::expr &assumption : summary.getAssumptions()) {
        lowered_assumptions.push_back(lowerExpression(summary, assumption));
    }
    SPDLOG_LOGGER_TRACE(logger, "lowered assumptions:\n{}", lowered_assumptions.to_string());

    // For each variable, retrieve the highest version of the hard constraints.
    // Lower the rhs of the highest version and remove all intermediate hard constraints.
    std::map<std::string, unsigned int> flattened_names_to_versions;
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        unsigned int version_position = hard_constraint.first.find("_");
        std::string flattened_name = hard_constraint.first.substr(0, version_position);
        unsigned int version =
                std::stoi(hard_constraint.first.substr(version_position + 1, hard_constraint.first.size()));
        assert(version > 0);
        auto it = flattened_names_to_versions.find(flattened_name);
        if (it == flattened_names_to_versions.end()) {
            flattened_names_to_versions.emplace(flattened_name, version);
        } else {
            if (it->second < version) {
                it->second = version;
            }
        }
    }
    SPDLOG_LOGGER_TRACE(logger, "Flattened names to versions: {}", flattened_names_to_versions);

    std::map<std::string, z3::expr> lowered_hard_constraints;
    for (const auto &flattened_name_to_version : flattened_names_to_versions) {
        std::string flattened_name = flattened_name_to_version.first;
        unsigned int version = flattened_name_to_version.second;
        z3::expr lowered_expression = lowerExpression(
                summary, summary.getHardConstraints().at(flattened_name + "_" + std::to_string(version)));
        lowered_hard_constraints.emplace(flattened_name, lowered_expression);
    }
    SPDLOG_LOGGER_TRACE(logger, "Lowered hard constraints: {}", lowered_hard_constraints);

    z3::expr_vector reversioned_hard_constraints(z3_context);
    for (const auto &lowered_hard_constraint : lowered_hard_constraints) {
        std::string flattened_name = lowered_hard_constraint.first;
        unsigned int version = state.getVersion(flattened_name);
        if (lowered_hard_constraint.second.is_bool()) {
            reversioned_hard_constraints.push_back(
                    _solver->makeBooleanConstant(flattened_name + "_" + std::to_string(version)) ==
                    lowered_hard_constraint.second);
        } else if (lowered_hard_constraint.second.is_int()) {
            reversioned_hard_constraints.push_back(
                    _solver->makeIntegerConstant(flattened_name + "_" + std::to_string(version)) ==
                    lowered_hard_constraint.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }
    SPDLOG_LOGGER_TRACE(logger, "lowered and reversioned hard constraints:\n{}",
                        reversioned_hard_constraints.to_string());

    z3::tactic tactic =
            z3::tactic(z3_context, "simplify") & z3::tactic(z3_context, "solve-eqs") & z3::tactic(z3_context, "smt");
    z3::solver solver = tactic.mk_solver();
    solver.set("unsat_core", true);

    z3::expr P = _solver->makeBooleanConstant("P");
    z3::expr Q = _solver->makeBooleanConstant("Q");
    z3::expr modified = _solver->makeBooleanConstant("modified");

    z3::expr precondition = z3::implies(P, z3::mk_and(lowered_assumptions));
    z3::expr postcondition = z3::implies(Q, z3::mk_and(reversioned_hard_constraints));

    std::string exit_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getExitLabel());
    z3::expr exit = z3::implies(_solver->makeBooleanConstant(exit_assumption_literal_name), z3::implies(Q, !modified));

    z3::expr_vector expressions(z3_context);
    for (const auto &assumption_literals : state.getAssumptionLiterals()) {
        std::string assumption_literal_name = assumption_literals.first;
        z3::expr_vector preceding_assumption_literals(_solver->getContext());
        for (const auto &preceding_assumption_literal : assumption_literals.second) {
            preceding_assumption_literals.push_back(preceding_assumption_literal);
        }
        expressions.push_back(z3::implies(_solver->makeBooleanConstant(assumption_literal_name),
                                          z3::mk_or(preceding_assumption_literals).simplify()));
    }

    for (const auto &assumption : assumptions) {
        std::string assumption_literal_name = assumption.first;
        z3::expr_vector assumption_expressions(_solver->getContext());
        for (const auto &expression : assumption.second) {
            assumption_expressions.push_back(expression);
        }
        expressions.push_back(
                z3::implies(_solver->makeBooleanConstant(assumption_literal_name), z3::mk_and(assumption_expressions)));
    }

    for (const auto &hard_constraint : hard_constraints) {
        std::string assumption_literal_name = hard_constraint.first;
        z3::expr_vector hard_constraint_expressions(_solver->getContext());
        for (const auto &hard_constraint_expression : hard_constraint.second) {
            if (hard_constraint_expression.second.is_bool()) {
                hard_constraint_expressions.push_back(_solver->makeBooleanConstant(hard_constraint_expression.first) ==
                                                      hard_constraint_expression.second);
            } else if (hard_constraint_expression.second.is_int()) {
                hard_constraint_expressions.push_back(_solver->makeIntegerConstant(hard_constraint_expression.first) ==
                                                      hard_constraint_expression.second);
            } else {
                throw std::runtime_error("Unsupported z3::sort encountered.");
            }
        }
        expressions.push_back(z3::implies(_solver->makeBooleanConstant(assumption_literal_name),
                                          z3::mk_and(hard_constraint_expressions)));
    }

    solver.add(expressions);
    solver.add(precondition);
    solver.add(postcondition);
    solver.add(exit);

    SPDLOG_LOGGER_TRACE(logger, "solver:\n{}", solver.assertions());

    z3::expr_vector assumption_literals(z3_context);
    assumption_literals.push_back(_solver->makeBooleanConstant(exit_assumption_literal_name));
    assumption_literals.push_back(P);
    assumption_literals.push_back(Q);
    z3::check_result result = solver.check(assumption_literals);

    switch (result) {
        case z3::unsat: {
            SPDLOG_LOGGER_TRACE(logger, "UNSAT");
            z3::expr_vector unsat_core = solver.unsat_core();
            SPDLOG_LOGGER_TRACE(logger, "unsat core:\n{}", unsat_core.to_string());
            break;
        }
        case z3::sat: {
            SPDLOG_LOGGER_TRACE(logger, "SAT");
            z3::model model = solver.get_model();
            SPDLOG_LOGGER_TRACE(logger, "model:\n{}", model.to_string());
            break;
        }
        case z3::unknown:
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }

    return z3::sat == result;
}

bool Engine::validityCheck(const Context &context, const summarization::Summary &summary) {
    auto logger = spdlog::get("Reuse");
    SPDLOG_LOGGER_TRACE(logger, "Validity checking of summary:\n{}\nunder context:\n{}", summary, context);

    const Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();
    const State &state = context.getState();

    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());
    std::string exit_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getExitLabel());

    std::map<std::string, std::map<std::string, z3::expr>> hard_constraints = state.getHardConstraints();
    // hard_constraints.emplace(entry_assumption_literal_name, std::map<std::string, z3::expr>());
    // hard_constraints.at(entry_assumption_literal_name).emplace("reach_lq", _solver->makeBooleanValue(false));
    // hard_constraints.emplace(exit_assumption_literal_name, std::map<std::string, z3::expr>());
    // hard_constraints.at(exit_assumption_literal_name).emplace("reach_lq", _solver->makeBooleanValue(true));

    std::map<std::string, std::vector<z3::expr>> assumptions = state.getAssumptions();

    z3::context &z3_context = _solver->getContext();
    // lower assumptions of summary
    z3::expr_vector lowered_assumptions(z3_context);
    for (const z3::expr &assumption : summary.getAssumptions()) {
        lowered_assumptions.push_back(lowerExpression(summary, assumption));
    }
    SPDLOG_LOGGER_TRACE(logger, "lowered assumptions:\n{}", lowered_assumptions.to_string());

    // For each variable, retrieve the highest version of the hard constraints.
    // Lower the rhs of the highest version and remove all intermediate hard constraints.
    std::map<std::string, unsigned int> flattened_names_to_versions;
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        unsigned int version_position = hard_constraint.first.find("_");
        std::string flattened_name = hard_constraint.first.substr(0, version_position);
        unsigned int version =
                std::stoi(hard_constraint.first.substr(version_position + 1, hard_constraint.first.size()));
        assert(version > 0);
        auto it = flattened_names_to_versions.find(flattened_name);
        if (it == flattened_names_to_versions.end()) {
            flattened_names_to_versions.emplace(flattened_name, version);
        } else {
            if (it->second < version) {
                it->second = version;
            }
        }
    }
    SPDLOG_LOGGER_TRACE(logger, "Flattened names to versions: {}", flattened_names_to_versions);

    std::map<std::string, z3::expr> lowered_hard_constraints;
    for (const auto &flattened_name_to_version : flattened_names_to_versions) {
        std::string flattened_name = flattened_name_to_version.first;
        unsigned int version = flattened_name_to_version.second;
        z3::expr lowered_expression = lowerExpression(
                summary, summary.getHardConstraints().at(flattened_name + "_" + std::to_string(version)));
        lowered_hard_constraints.emplace(flattened_name, lowered_expression);
    }
    SPDLOG_LOGGER_TRACE(logger, "Lowered hard constraints: {}", lowered_hard_constraints);

    z3::expr_vector reversioned_hard_constraints(z3_context);
    for (const auto &lowered_hard_constraint : lowered_hard_constraints) {
        std::string flattened_name = lowered_hard_constraint.first;
        unsigned int version = state.getVersion(flattened_name);
        if (lowered_hard_constraint.second.is_bool()) {
            reversioned_hard_constraints.push_back(
                    _solver->makeBooleanConstant(flattened_name + "_" + std::to_string(version)) ==
                    lowered_hard_constraint.second);
        } else if (lowered_hard_constraint.second.is_int()) {
            reversioned_hard_constraints.push_back(
                    _solver->makeIntegerConstant(flattened_name + "_" + std::to_string(version)) ==
                    lowered_hard_constraint.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }
    SPDLOG_LOGGER_TRACE(logger, "lowered and reversioned hard constraints:\n{}",
                        reversioned_hard_constraints.to_string());

    z3::tactic tactic =
            z3::tactic(z3_context, "simplify") & z3::tactic(z3_context, "solve-eqs") & z3::tactic(z3_context, "smt");
    z3::solver solver = tactic.mk_solver();
    solver.set("unsat_core", true);

    z3::expr P = _solver->makeBooleanConstant("P");
    z3::expr Q = _solver->makeBooleanConstant("Q");
    z3::expr reach_lq = _solver->makeBooleanConstant("reach_lq");
    z3::expr exit = z3::implies(_solver->makeBooleanConstant(exit_assumption_literal_name), reach_lq);

    z3::expr precondition = z3::implies(P, z3::mk_and(lowered_assumptions));
    z3::expr postcondition = z3::implies(Q, z3::mk_and(reversioned_hard_constraints));

    z3::expr_vector expressions(z3_context);
    for (const auto &assumption_literals : state.getAssumptionLiterals()) {
        std::string assumption_literal_name = assumption_literals.first;
        z3::expr_vector preceding_assumption_literals(_solver->getContext());
        for (const auto &preceding_assumption_literal : assumption_literals.second) {
            preceding_assumption_literals.push_back(preceding_assumption_literal);
        }
        expressions.push_back(z3::implies(_solver->makeBooleanConstant(assumption_literal_name),
                                          z3::mk_or(preceding_assumption_literals).simplify()));
    }

    for (const auto &assumption : assumptions) {
        std::string assumption_literal_name = assumption.first;
        z3::expr_vector assumption_expressions(_solver->getContext());
        for (const auto &expression : assumption.second) {
            assumption_expressions.push_back(expression);
        }
        expressions.push_back(
                z3::implies(_solver->makeBooleanConstant(assumption_literal_name), z3::mk_and(assumption_expressions)));
    }

    for (const auto &hard_constraint : hard_constraints) {
        std::string assumption_literal_name = hard_constraint.first;
        z3::expr_vector hard_constraint_expressions(_solver->getContext());
        for (const auto &hard_constraint_expression : hard_constraint.second) {
            if (hard_constraint_expression.second.is_bool()) {
                hard_constraint_expressions.push_back(_solver->makeBooleanConstant(hard_constraint_expression.first) ==
                                                      hard_constraint_expression.second);
            } else if (hard_constraint_expression.second.is_int()) {
                hard_constraint_expressions.push_back(_solver->makeIntegerConstant(hard_constraint_expression.first) ==
                                                      hard_constraint_expression.second);
            } else {
                throw std::runtime_error("Unsupported z3::sort encountered.");
            }
        }
        expressions.push_back(z3::implies(_solver->makeBooleanConstant(assumption_literal_name),
                                          z3::mk_and(hard_constraint_expressions)));
    }

    solver.add(expressions);
    solver.add(precondition);
    solver.add(postcondition);
    // solver.add(exit);

    SPDLOG_LOGGER_TRACE(logger, "solver:\n{}", solver.assertions());

    z3::expr_vector assumption_literals(z3_context);
    assumption_literals.push_back(_solver->makeBooleanConstant(exit_assumption_literal_name));
    assumption_literals.push_back(P);
    assumption_literals.push_back(Q);
    z3::check_result result = solver.check(assumption_literals);

    switch (result) {
        case z3::unsat: {
            SPDLOG_LOGGER_TRACE(logger, "UNSAT");
            z3::expr_vector unsat_core = solver.unsat_core();
            SPDLOG_LOGGER_TRACE(logger, "unsat core:\n{}", unsat_core.to_string());
            break;
        }
        case z3::sat: {
            SPDLOG_LOGGER_TRACE(logger, "SAT");
            z3::model model = solver.get_model();
            SPDLOG_LOGGER_TRACE(logger, "model:\n{}", model.to_string());
            break;
        }
        case z3::unknown:
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }

    return z3::sat == result;
}

std::unique_ptr<Context> Engine::generateVerificationConditions(std::unique_ptr<Context> context, bool old) {
    _explorer->push(std::move(context));
    std::unique_ptr<Context> encoded_context = nullptr;
    while (!_explorer->isEmpty()) {
        encoded_context = step(old);
    }
    assert(encoded_context != nullptr);
    return encoded_context;
}

std::unique_ptr<Context> Engine::step(bool old) {
    while (!_explorer->isEmpty() || !_merger->isEmpty()) {
        if (_explorer->isEmpty()) {
            assert(!_merger->isEmpty());
            std::unique_ptr<Context> merged_context = _merger->merge();
            _explorer->push(std::move(merged_context));
        } else {
            std::unique_ptr<Context> context = _explorer->pop();
            std::pair<std::unique_ptr<Context>, boost::optional<std::unique_ptr<Context>>> succeeding_contexts =
                    _executor->execute(std::move(context), old);
            std::unique_ptr<Context> succeeding_context = std::move(succeeding_contexts.first);
            if (succeeding_context->getEncoded()) {
                assert(!succeeding_contexts.second.has_value());
                return succeeding_context;
            }
            if (_merger->reachedMergePoint(*succeeding_context)) {
                _merger->push(std::move(succeeding_context));
            } else {
                _explorer->push(std::move(succeeding_context));
            }
            if (succeeding_contexts.second.has_value()) {
                std::unique_ptr<Context> forked_succeeding_context = std::move(*succeeding_contexts.second);
                if (_merger->reachedMergePoint(*forked_succeeding_context)) {
                    _merger->push(std::move(forked_succeeding_context));
                } else {
                    _explorer->push(std::move(forked_succeeding_context));
                }
            }
        }
    }
}

z3::expr Engine::lowerExpression(const summarization::Summary &summary, const z3::expr &expression) const {
    z3::context &context = _solver->getContext();
    z3::expr lowered_expression = expression.simplify();
    std::vector<z3::expr> uninterpreted_constants = _solver->getUninterpretedConstants(expression);
    if (uninterpreted_constants.empty()) {
        lowered_expression = lowered_expression.simplify();
        assert(lowered_expression.is_true() || lowered_expression.is_false() || lowered_expression.is_numeral());
        return lowered_expression;
    } else if (uninterpreted_constants.size() == 1) {
        // recursive base case
        z3::expr uninterpreted_constant = uninterpreted_constants.at(0);
        std::string name = uninterpreted_constant.decl().name().str();
        const std::map<std::string, z3::expr> &hard_constraints = summary.getHardConstraints();
        auto it = hard_constraints.find(name);
        if (it == hard_constraints.end()) {
            return lowered_expression;
        } else {
            // TODO: check if it is a self-reference
            if (name == it->second.to_string()) {
                // self-reference
                return lowered_expression;
            }
            z3::expr_vector source(context);
            source.push_back(uninterpreted_constant);
            z3::expr_vector destination(context);
            destination.push_back(it->second);
            lowered_expression = lowered_expression.substitute(source, destination).simplify();
            return lowerExpression(summary, lowered_expression);
        }
    } else {
        for (const z3::expr &uninterpreted_constant : uninterpreted_constants) {
            z3::expr_vector source(context);
            source.push_back(uninterpreted_constant);
            z3::expr_vector destination(context);
            z3::expr lowered_uninterpreted_constant = lowerExpression(summary, uninterpreted_constant);
            destination.push_back(lowered_uninterpreted_constant);
            lowered_expression = lowered_expression.substitute(source, destination).simplify();
        }
        return lowered_expression;
    }
}

std::vector<std::vector<z3::expr>> Engine::determineAssumptionLiteralPaths(const Context &context) const {
    auto logger = spdlog::get("Reuse");
    SPDLOG_LOGGER_TRACE(logger, "Determining assumption literal paths for summary regeneration...");

    const State &state = context.getState();
    const Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();

    z3::expr assumption_literal = state.getAssumptionLiteral();
    std::string assumption_literal_name = assumption_literal.to_string();

    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());

    std::vector<std::vector<z3::expr>> open_paths;
    std::vector<std::vector<z3::expr>> closed_paths;

    // initialize the open paths
    for (const auto &preceding_assumption_literal : state.getAssumptionLiterals(assumption_literal_name)) {
        open_paths.emplace_back(std::vector<z3::expr>{assumption_literal, preceding_assumption_literal});
    }

    while (!open_paths.empty()) {
        std::vector<z3::expr> current_path = open_paths.back();
        open_paths.pop_back();
        std::string current_assumption_literal_name = current_path.back().to_string();
        bool should_close_path = true;
        while (current_assumption_literal_name != entry_assumption_literal_name) {
            std::vector<z3::expr> preceding_assumption_literals =
                    state.getAssumptionLiterals(current_assumption_literal_name);
            if (preceding_assumption_literals.size() == 1) {
                current_path.emplace_back(preceding_assumption_literals.at(0));
                current_assumption_literal_name = preceding_assumption_literals.at(0).to_string();
            } else {
                for (const auto &preceding_assumption_literal : preceding_assumption_literals) {
                    std::vector<z3::expr> new_path = current_path;
                    new_path.emplace_back(preceding_assumption_literal);
                    open_paths.emplace_back(std::move(new_path));
                }
                should_close_path = false;
                break;
            }
        }
        if (should_close_path) {
            std::reverse(current_path.begin(), current_path.end());
            closed_paths.emplace_back(current_path);
        }
    }

    // DEBUG
    std::stringstream str;
    int path_count = 0;
    for (const auto &closed_path : closed_paths) {
        str << path_count << ": [";
        for (auto it = closed_path.begin(); it != closed_path.end(); ++it) {
            str << *it;
            if (std::next(it) != closed_path.end()) {
                str << ", ";
            }
        }
        str << "]\n";
        path_count++;
    }
    assert(!closed_paths.empty());
    SPDLOG_LOGGER_TRACE(logger, "Paths through encoded context:\n{}", str.str());

    return closed_paths;
}

std::vector<std::vector<z3::expr>>
Engine::determinePathCandidates(const Context &context,
                                const std::vector<z3::expr> &uncovered_assumption_literals) const {
    std::vector<std::vector<z3::expr>> path_candidates;
    const State &state = context.getState();
    const Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();

    z3::expr assumption_literal = state.getAssumptionLiteral();
    std::string assumption_literal_name = assumption_literal.to_string();

    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());
    for (const z3::expr &uncovered_assumption_literal : uncovered_assumption_literals) {
        std::vector<z3::expr> current_path;
        std::string current_assumption_literal_name = assumption_literal_name;
        while (current_assumption_literal_name != entry_assumption_literal_name) {
            std::vector<z3::expr> preceding_assumption_literals =
                    state.getAssumptionLiterals(current_assumption_literal_name);
            if (preceding_assumption_literals.size() == 1) {
                current_path.emplace_back(preceding_assumption_literals.at(0));
                current_assumption_literal_name = preceding_assumption_literals.at(0).to_string();
            } else {
                auto it = std::find_if(
                        preceding_assumption_literals.begin(), preceding_assumption_literals.end(),
                        [&uncovered_assumption_literals](const z3::expr &preceding_assumption_literal) {
                            return std::find(uncovered_assumption_literals.begin(), uncovered_assumption_literals.end(),
                                             preceding_assumption_literal) != uncovered_assumption_literals.end();
                        });
                assert(it != preceding_assumption_literals.end());
                current_path.emplace_back(*it);
                current_assumption_literal_name = it->to_string();
            }
        }
        std::reverse(current_path.begin(), current_path.end());
        path_candidates.push_back(current_path);
    }
    return path_candidates;
}