#include "se/summarization/memoization/summarizer.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/fmt/ranges.h"
#include "spdlog/spdlog.h"

using namespace se::summarization;

Summarizer::Summarizer(etfa::Solver &solver)
    : _solver(&solver), _name_to_summaries(std::map<std::string, std::vector<std::shared_ptr<Summary>>>()) {}

Summarizer::Summarizer(etfa::Solver &solver,
                       std::map<std::string, std::vector<std::shared_ptr<Summary>>> name_to_summaries)
    : _solver(&solver), _name_to_summaries(std::move(name_to_summaries)) {}

const std::map<std::string, std::vector<std::shared_ptr<Summary>>> &Summarizer::getSummaries() const {
    return _name_to_summaries;
}

const std::vector<std::shared_ptr<Summary>> &Summarizer::getSummaries(const std::string &name) const {
    assert(_name_to_summaries.count(name));
    return _name_to_summaries.at(name);
}

std::vector<Summary *> Summarizer::findApplicableSummary(const etfa::Context &context) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_INFO(logger, "Trying to find an applicable summary...");

    unsigned int cycle = context.getCycle();
    const etfa::State &state = context.getState();
    const etfa::Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();

    std::vector<Summary *> applicable_summaries;
    auto it = _name_to_summaries.find(cfg.getFullyQualifiedName());
    if (it == _name_to_summaries.end()) {
        SPDLOG_LOGGER_INFO(logger, "No summary exists yet for function block \"{}\".", cfg.getFullyQualifiedName());
    } else {
        // true for checking, false for evaluating
        // checking is expensive but always yields correct results, what i want to investigate is whether evaluating
        // is not only quicker but also correct
        bool check_or_evaluate = false;
        if (check_or_evaluate) {
            const std::vector<std::shared_ptr<Summary>> &summaries = _name_to_summaries.at(cfg.getFullyQualifiedName());
            std::set<std::string> necessary_hard_constraints;
            std::map<std::string, z3::expr> current_symbolic_valuations;
            const ir::Interface &interface = cfg.getInterface();
            for (auto variable = interface.variablesBegin(); variable != interface.variablesEnd(); ++variable) {
                if (variable->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
                    continue;
                }
                std::string name = variable->getName();
                std::string flattened_name = frame.getScope() + "." + name;
                unsigned int version = state.getVersion(flattened_name);
                std::string contextualized_name =
                        flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
                z3::expr current_symbolic_valuation = state.getSymbolicValuation(contextualized_name);
                // extractNecessaryHardConstraints(necessary_hard_constraints, state, current_symbolic_valuation);
                std::string reversioned_name = flattened_name + "_0";
                /*
                SPDLOG_LOGGER_TRACE(logger, "{} reversioned to {} -> {}", contextualized_name, reversioned_name,
                                    current_symbolic_valuation.to_string());
                */
                current_symbolic_valuations.emplace(reversioned_name, current_symbolic_valuation);
            }
            const std::vector<z3::expr> &path_constraint = state.getPathConstraint();
            /*
            for (const std::string &necessary_hard_constraint : necessary_hard_constraints) {
                current_symbolic_valuations.emplace(necessary_hard_constraint,
                                                    state.getSymbolicValuation(necessary_hard_constraint));
            }
            */

            // add all symbolic valuations to the set of current symbolic valuations because they might be referenced
            // by a reversioned symbolic valuation's right-hand side
            for (const auto &symbolic_valuation : state.getSymbolicValuations()) {
                current_symbolic_valuations.emplace(symbolic_valuation.first, symbolic_valuation.second);
            }

            bool old_check = true;
            if (old_check) {
                // set of z3::expr ids belonging to assumptions that are in an unsat core of any summary applicability check
                std::set<unsigned int> unsat_core_ids;
                for (const std::shared_ptr<Summary> &summary : summaries) {
                    // SPDLOG_LOGGER_TRACE(logger, "Trying to apply:\n{}", *summary);
                    // std::cout << "Trying to apply:\n" << *summary;
                    // assumptions do not yet violate the execution context and hence must be checked
                    auto result = isSummaryApplicable(*summary, current_symbolic_valuations, path_constraint);
                    if (result.first) {
                        SPDLOG_LOGGER_TRACE(logger, "Summary is applicable.");
                        applicable_summaries.push_back(summary.get());
                    } else {
                        SPDLOG_LOGGER_TRACE(logger, "Summary is not applicable.");
                        for (unsigned int id : *result.second) {
                            unsat_core_ids.insert(id);
                        }
                    }
                }
            } else {
                applicable_summaries = getApplicableSummaries(current_symbolic_valuations, summaries);
            }
        } else {
            // trying to check if evaluation works
            const auto &summaries = _name_to_summaries.at(cfg.getFullyQualifiedName());
            for (const auto &summary : summaries) {
                bool result = isSummaryApplicableViaEvaluation(*summary, context);
                if (result) {
                    SPDLOG_LOGGER_TRACE(logger, "Summary is applicable.");
                    applicable_summaries.push_back(summary.get());
                } else {
                    SPDLOG_LOGGER_TRACE(logger, "Summary is not applicable.");
                }
            }
        }
    }
    SPDLOG_LOGGER_INFO(logger, "Found {} applicable summaries.", applicable_summaries.size());
    return applicable_summaries;
}

std::vector<std::pair<std::shared_ptr<Summary>, z3::model>>
Summarizer::findConcretelyApplicableSummaries(const etfa_no_merge::Context &context) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_INFO(logger, "Trying to find concretely applicable summaries...");
    unsigned int cycle = context.getCycle();
    const etfa_no_merge::State &state = context.getState();
    const etfa_no_merge::Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();
    std::vector<std::pair<std::shared_ptr<Summary>, z3::model>> applicable_summaries_and_models;
    auto it = _name_to_summaries.find(cfg.getFullyQualifiedName());
    if (it == _name_to_summaries.end()) {
        SPDLOG_LOGGER_INFO(logger, "No summary exists yet for function block \"{}\".", cfg.getFullyQualifiedName());
    } else {
        // "reversion" current concrete valuations
        std::map<std::string, z3::expr> reversioned_concrete_valuations;
        const ir::Interface &interface = cfg.getInterface();
        for (auto variable = interface.variablesBegin(); variable != interface.variablesEnd(); ++variable) {
            if (variable->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
                continue;
            }
            std::string name = variable->getName();
            std::string flattened_name = frame.getScope() + "." + name;
            unsigned int version = state.getVersion(flattened_name);
            std::string contextualized_name =
                    flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
            z3::expr current_concrete_valuation = state.getConcreteValuation(contextualized_name);
            std::string reversioned_name = flattened_name + "_0";
            SPDLOG_LOGGER_TRACE(logger, "{} reversioned to {} -> {}", contextualized_name, reversioned_name,
                                current_concrete_valuation.to_string());
            reversioned_concrete_valuations.emplace(reversioned_name, current_concrete_valuation);
        }

        // build a model
        z3::model model(_solver->getContext());
        for (const auto &reversioned_concrete_valuation : reversioned_concrete_valuations) {
            if (reversioned_concrete_valuation.second.is_bool()) {
                z3::expr lhs = _solver->makeBooleanConstant(reversioned_concrete_valuation.first);
                z3::func_decl decl = lhs.decl();
                z3::expr rhs = reversioned_concrete_valuation.second;
                model.add_const_interp(decl, rhs);
            } else if (reversioned_concrete_valuation.second.is_int()) {
                z3::expr lhs = _solver->makeIntegerConstant(reversioned_concrete_valuation.first);
                z3::func_decl decl = lhs.decl();
                z3::expr rhs = reversioned_concrete_valuation.second;
                model.add_const_interp(decl, rhs);
            } else {
                throw std::runtime_error("Invalid z3::sort encountered.");
            }
        }
        SPDLOG_LOGGER_TRACE(logger, "model:\n{}", model);

        const std::vector<std::shared_ptr<Summary>> &summaries = _name_to_summaries.at(cfg.getFullyQualifiedName());
        for (const std::shared_ptr<Summary> &summary : summaries) {
            SPDLOG_LOGGER_TRACE(logger, "Trying to apply:\n{}", *summary);
            for (const auto &hard_constraint : summary->getHardConstraints()) {
                if (hard_constraint.second.is_bool()) {
                    z3::expr lhs = _solver->makeBooleanConstant(hard_constraint.first);
                    z3::func_decl decl = lhs.decl();
                    z3::expr rhs = hard_constraint.second;
                    z3::expr result = model.eval(rhs);
                    if (result.is_true() || result.is_false()) {
                        model.add_const_interp(decl, result);
                    } else {
                        // check for self-reference
                        // e.g., non-deterministic variables in timers such as "SFAntivalent.Timer.timeout_1"
                        // or "Main.SFSafelyLimitSpeed.Q_1"
                        if (hard_constraint.first == hard_constraint.second.to_string()) {
                            z3::expr value = _solver->makeBooleanValue(false);
                            model.add_const_interp(decl, value);
                        } else {
                            throw std::logic_error("Not implemented yet.");
                        }
                    }
                } else if (hard_constraint.second.is_int()) {
                    z3::expr lhs = _solver->makeIntegerConstant(hard_constraint.first);
                    z3::func_decl decl = lhs.decl();
                    z3::expr rhs = hard_constraint.second;
                    z3::expr result = model.eval(rhs);
                    if (result.is_numeral()) {
                        model.add_const_interp(decl, result);
                    } else {
                        // does not have to be a numeral value, can be a self-reference
                        // e.g., non-deterministic variables in timers such as ""SFAntivalent.Timer.ET_1""
                        if (hard_constraint.first == hard_constraint.second.to_string()) {
                            z3::expr value = _solver->makeIntegerValue(0);
                            model.add_const_interp(decl, value);
                        } else {
                            throw std::logic_error("Not implemented yet.");
                        }
                    }
                } else {
                    throw std::runtime_error("Invalid z3::sort encountered.");
                }
            }
            SPDLOG_LOGGER_TRACE(logger, "model:\n{}", model);

            // TODO: Why don't we care about the current path constraint when evaluating the assumptions of the
            //  summary? Because the current concrete valuations respect the path constraint and an unsatisfying
            //  assignment would imply a contradiction between the path constraint and the assumptions, hence it is
            //  implicitly already "modeled".
            bool failed = false;
            for (const auto &assumption : summary->getAssumptions()) {
                z3::expr result = model.eval(assumption, true);
                SPDLOG_LOGGER_TRACE(logger, "{} evaluates to {} under model.", assumption.to_string(),
                                    result.to_string());
                assert(result.is_true() || result.is_false());
                if (result.is_false()) {
                    failed = true;
                    break;
                }
            }
            if (!failed) {
                applicable_summaries_and_models.emplace_back(summary, model);
            } else {
                // TODO: We need to check whether it is truly not possible to apply this summary by checking
                //  whether a different input assignment may be satisfiable -> check "symbolically"!
                auto result = isSymbolicallyApplicable(summary, context);
                if (result.first) {
                    assert(result.second.has_value());
                    applicable_summaries_and_models.emplace_back(summary, *result.second);
                }
            }
        }
    }
    return applicable_summaries_and_models;
}

std::pair<bool, boost::optional<z3::model>>
Summarizer::isSymbolicallyApplicable(const std::shared_ptr<Summary> &summary, const etfa_no_merge::Context &context) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_TRACE(logger, "Trying to symbolically apply:\n{}", *summary);

    unsigned int cycle = context.getCycle();
    const etfa_no_merge::State &state = context.getState();
    const etfa_no_merge::Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();

    std::map<std::string, z3::expr> current_symbolic_valuations;
    const ir::Interface &interface = cfg.getInterface();
    for (auto variable = interface.variablesBegin(); variable != interface.variablesEnd(); ++variable) {
        if (variable->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
            continue;
        }
        std::string name = variable->getName();
        std::string flattened_name = frame.getScope() + "." + name;
        unsigned int version = state.getVersion(flattened_name);
        std::string contextualized_name = flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
        z3::expr current_symbolic_valuation = state.getSymbolicValuation(contextualized_name);
        std::string reversioned_name = flattened_name + "_0";
        SPDLOG_LOGGER_TRACE(logger, "{} reversioned to {} -> {}", contextualized_name, reversioned_name,
                            current_symbolic_valuation.to_string());
        current_symbolic_valuations.emplace(reversioned_name, current_symbolic_valuation);
    }
    for (const auto &symbolic_valuation : state.getSymbolicValuations()) {
        current_symbolic_valuations.emplace(symbolic_valuation.first, symbolic_valuation.second);
    }
    using namespace std::literals;
    std::chrono::time_point<std::chrono::system_clock> begin_time_point = std::chrono::system_clock::now();
    z3::context &z3_context = _solver->getContext();
    // Encode the current context's valuations reaching summary application point
    z3::expr_vector valuations(z3_context);
    for (const auto &symbolic_valuation : current_symbolic_valuations) {
        if (symbolic_valuation.second.is_bool()) {
            valuations.push_back(_solver->makeBooleanConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else if (symbolic_valuation.second.is_int()) {
            valuations.push_back(_solver->makeIntegerConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }

    // Encode summary
    z3::expr_vector assumptions(z3_context);
    z3::expr_vector assumption_literals(z3_context);
    unsigned int index = 0;
    for (const z3::expr &assumption : summary->getAssumptions()) {
        z3::expr assumption_literal = _solver->makeBooleanConstant("b" + std::to_string(index));
        assumptions.push_back(z3::implies(assumption_literal, assumption));
        assumption_literals.push_back(assumption_literal);
        index++;
    }

    z3::expr_vector hard_constraints(z3_context);
    for (const auto &hard_constraint : summary->getHardConstraints()) {
        if (hard_constraint.second.is_bool()) {
            hard_constraints.push_back(_solver->makeBooleanConstant(hard_constraint.first) == hard_constraint.second);
        } else if (hard_constraint.second.is_int()) {
            hard_constraints.push_back(_solver->makeIntegerConstant(hard_constraint.first) == hard_constraint.second);
        } else {
            throw std::runtime_error("Unsupported z3::sort encountered.");
        }
    }

    z3::tactic tactic = z3::tactic(_solver->getContext(), "simplify") & z3::tactic(_solver->getContext(), "solve-eqs") &
                        z3::tactic(_solver->getContext(), "smt");
    z3::solver solver = tactic.mk_solver();
    solver.set("unsat_core", true);

    solver.add(valuations);
    solver.add(assumptions);
    solver.add(hard_constraints);

    SPDLOG_LOGGER_TRACE(logger, "Solver assertions:\n{}\nunder assumption literals:\n{}", solver.assertions(),
                        assumption_literals);

    z3::check_result result = solver.check(assumption_literals);

    std::pair<bool, boost::optional<z3::model>> res;
    switch (result) {
        case z3::unsat: {
            SPDLOG_LOGGER_TRACE(logger, "solver returned unsat, summary is not applicable.");
            z3::expr_vector unsat_core = solver.unsat_core();
            SPDLOG_LOGGER_TRACE(logger, "unsat core: {}", unsat_core);
            res.first = false;
            break;
        }
        case z3::sat: {
            z3::model z3_model = solver.get_model();
            SPDLOG_LOGGER_TRACE(logger, "solver returned sat, summary is applicable.");
            std::stringstream str;
            for (unsigned int i = 0; i < z3_model.size(); ++i) {
                z3::func_decl constant_declaration = z3_model.get_const_decl(i);
                assert(constant_declaration.is_const() && constant_declaration.arity() == 0);
                std::string contextualized_name = constant_declaration.name().str();
                z3::expr interpretation = z3_model.get_const_interp(constant_declaration);
                str << contextualized_name << " -> " << interpretation << "\n";
            }
            res.first = true;
            res.second = z3_model;
            SPDLOG_LOGGER_TRACE(logger, "model:\n{}", str.str());
            break;
        }
        case z3::unknown:
            // XXX fall-through
        default:
            throw std::runtime_error("Invalid z3::check_result encountered.");
    }
    long elapsed_time = (std::chrono::system_clock::now() - begin_time_point) / 1ms;
    // std::cout << "Checking if summary is applicable took " << elapsed_time << "ms." << std::endl;
    return res;
}

void Summarizer::summarizePath(const Context &context) {
    auto version_comparer = [](const std::string &contextualized_name_1, const std::string &contextualized_name_2) {
        std::size_t version_position_1 = contextualized_name_1.find('_');
        assert(version_position_1 != std::string::npos);
        std::size_t version_position_2 = contextualized_name_2.find('_');
        assert(version_position_2 != std::string::npos);
        std::string name_1 = contextualized_name_1.substr(0, version_position_1);
        std::string name_2 = contextualized_name_2.substr(0, version_position_2);
        unsigned int version_1 =
                std::stoi(contextualized_name_1.substr(version_position_1 + 1, contextualized_name_1.length()));
        unsigned int version_2 =
                std::stoi(contextualized_name_2.substr(version_position_2 + 1, contextualized_name_2.length()));
        if (name_1 < name_2) {
            return true;
        } else if (name_1 == name_2) {
            if (version_1 < version_2) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    };

    auto logger = spdlog::get("Summarization");
    SPDLOG_LOGGER_TRACE(logger, "Trying to summarize path...");
    const Frame &frame = context.getFrame();

    // "Re-versioning"
    const Cfg &cfg = frame.getCfg();
    const ir::Interface &interface = cfg.getInterface();
    std::map<std::string, std::set<std::string, decltype(version_comparer)>> flattened_names_to_contextualized_names;
    std::set<std::string, decltype(version_comparer)> modified_contextualized_names(version_comparer);
    for (auto it = interface.variablesBegin(); it != interface.variablesEnd(); ++it) {
        if (it->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
            continue;
        }
        std::string name = it->getName();
        std::string flattened_name = frame.getScope() + "." + name;
        flattened_names_to_contextualized_names.emplace(
                flattened_name, std::set<std::string, decltype(version_comparer)>(version_comparer));
    }

    const State &state = context.getState();
    std::vector<z3::expr> flattened_assumption_literals = flattenAssumptionLiterals(context);
    std::vector<z3::expr> assumption_literals;
    for (const z3::expr &assumption_literal : flattened_assumption_literals) {
        std::string assumption_literal_name = assumption_literal.to_string();
        assumption_literals.push_back(_solver->makeBooleanConstant(assumption_literal_name));
    }

    {// Pass 1
        const std::map<std::string, std::vector<z3::expr>> &assumptions = state.getAssumptions();
        const std::map<std::string, std::map<std::string, z3::expr>> &hard_constraints = state.getHardConstraints();
        for (const z3::expr &assumption_literal : flattened_assumption_literals) {
            std::string assumption_literal_name = assumption_literal.to_string();
            auto assumptions_it =
                    std::find_if(assumptions.begin(), assumptions.end(),
                                 [&assumption_literal_name](const auto &assumption_literal_name_to_assumptions) {
                                     return assumption_literal_name == assumption_literal_name_to_assumptions.first;
                                 });
            if (assumptions_it != assumptions.end()) {
                for (const z3::expr &assumption : assumptions_it->second) {
                    for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(assumption)) {
                        std::string contextualized_name = uninterpreted_constant.to_string();
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                }
            }
            auto hard_constraints_it = std::find_if(
                    hard_constraints.begin(), hard_constraints.end(),
                    [&assumption_literal_name](const auto &assumption_literal_name_to_hard_constraints) {
                        return assumption_literal_name == assumption_literal_name_to_hard_constraints.first;
                    });
            if (hard_constraints_it != hard_constraints.end()) {
                for (const auto &hard_constraint : hard_constraints_it->second) {
                    {// lhs
                        std::string contextualized_name = hard_constraint.first;
                        modified_contextualized_names.insert(contextualized_name);
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                    // rhs
                    z3::expr expression = hard_constraint.second;
                    for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(expression)) {
                        std::string contextualized_name = uninterpreted_constant.to_string();
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                }
            }
        }
    }

    std::map<std::string, std::string, decltype(version_comparer)> contextualized_names_to_reversioned_names(
            version_comparer);
    for (const auto &flattened_name_to_contextualized_name : flattened_names_to_contextualized_names) {
        unsigned int version = 0;
        for (const std::string &contextualized_name : flattened_name_to_contextualized_name.second) {
            auto it = modified_contextualized_names.find(contextualized_name);
            std::string reversioned_name;
            if (it == modified_contextualized_names.end()) {
                // variable is read
                reversioned_name = flattened_name_to_contextualized_name.first + "_" + std::to_string(version);
            } else {
                // variable is written, ensure versioning always starts at 1
                version = version + 1;
                reversioned_name = flattened_name_to_contextualized_name.first + "_" + std::to_string(version);
            }
            contextualized_names_to_reversioned_names.emplace(contextualized_name, reversioned_name);
        }
    }

    // Pass 2: reversion contextualized names across the assumptions and hard constraints
    std::vector<z3::expr> assumptions;
    std::map<std::string, std::vector<z3::expr>> assumption_literals_to_assumptions;
    std::map<std::string, z3::expr> hard_constraints;
    std::map<std::string, std::map<std::string, z3::expr>> assumption_literals_to_hard_constraints;
    for (const z3::expr &assumption_literal : flattened_assumption_literals) {
        std::string assumption_literal_name = assumption_literal.to_string();
        auto assumptions_it =
                std::find_if(state.getAssumptions().begin(), state.getAssumptions().end(),
                             [&assumption_literal_name](const auto &assumption_literal_name_to_assumptions) {
                                 return assumption_literal_name == assumption_literal_name_to_assumptions.first;
                             });
        if (assumptions_it != state.getAssumptions().end()) {
            std::vector<z3::expr> assumption_expressions;
            for (const z3::expr &assumption_expression : assumptions_it->second) {
                z3::expr substituted_assumption_expression = assumption_expression;
                for (const z3::expr &uninterpreted_constant :
                     _solver->getUninterpretedConstants(substituted_assumption_expression)) {
                    std::string contextualized_name = uninterpreted_constant.to_string();
                    std::string reversioned_name = contextualized_names_to_reversioned_names.at(contextualized_name);
                    z3::expr_vector src(_solver->getContext());
                    src.push_back(uninterpreted_constant);
                    z3::expr_vector dst(_solver->getContext());
                    if (uninterpreted_constant.is_bool()) {
                        dst.push_back(_solver->makeBooleanConstant(reversioned_name));
                    } else if (uninterpreted_constant.is_int()) {
                        dst.push_back(_solver->makeIntegerConstant(reversioned_name));
                    } else {
                        throw std::runtime_error("Unsupported z3::sort encountered.");
                    }
                    substituted_assumption_expression = substituted_assumption_expression.substitute(src, dst);
                }
                assumptions.push_back(substituted_assumption_expression);
                assumption_expressions.push_back(substituted_assumption_expression);
            }
            assumption_literals_to_assumptions.emplace(assumption_literal_name, std::move(assumption_expressions));
        }
        auto hard_constraints_it =
                std::find_if(state.getHardConstraints().begin(), state.getHardConstraints().end(),
                             [&assumption_literal_name](const auto &assumption_literal_name_to_hard_constraints) {
                                 return assumption_literal_name == assumption_literal_name_to_hard_constraints.first;
                             });
        if (hard_constraints_it != state.getHardConstraints().end()) {
            std::map<std::string, z3::expr> hard_constraint_expressions;
            for (const auto &hard_constraint : hard_constraints_it->second) {
                z3::expr substituted_hard_constraint = hard_constraint.second;
                for (const z3::expr &uninterpreted_constant :
                     _solver->getUninterpretedConstants(substituted_hard_constraint)) {
                    std::string contextualized_name = uninterpreted_constant.to_string();
                    std::string reversioned_name = contextualized_names_to_reversioned_names.at(contextualized_name);
                    z3::expr_vector src(_solver->getContext());
                    src.push_back(uninterpreted_constant);
                    z3::expr_vector dst(_solver->getContext());
                    if (uninterpreted_constant.is_bool()) {
                        dst.push_back(_solver->makeBooleanConstant(reversioned_name));
                    } else if (uninterpreted_constant.is_int()) {
                        dst.push_back(_solver->makeIntegerConstant(reversioned_name));
                    } else {
                        throw std::runtime_error("Unsupported z3::sort encountered.");
                    }
                    substituted_hard_constraint = substituted_hard_constraint.substitute(src, dst);
                }
                std::string reversioned_name = contextualized_names_to_reversioned_names.at(hard_constraint.first);
                hard_constraints.emplace(reversioned_name, substituted_hard_constraint);
                hard_constraint_expressions.emplace(reversioned_name, substituted_hard_constraint);
            }
            assumption_literals_to_hard_constraints.emplace(assumption_literal_name,
                                                            std::move(hard_constraint_expressions));
        }
    }

    std::unique_ptr<Summary> summary = std::make_unique<Summary>(
            std::move(assumptions), std::move(hard_constraints), std::move(assumption_literals),
            std::move(assumption_literals_to_assumptions), std::move(assumption_literals_to_hard_constraints));

    auto it = _name_to_summaries.find(cfg.getFullyQualifiedName());
    if (it == _name_to_summaries.end()) {
        _name_to_summaries.emplace(cfg.getFullyQualifiedName(), std::vector<std::shared_ptr<Summary>>());
    } else {
        const auto &existing_summaries = it->second;
        // TODO (26.04.2022): Move this check way earlier to prevent redundant work...
        for (const auto &existing_summary : existing_summaries) {
            if (*existing_summary == *summary) {
                SPDLOG_LOGGER_TRACE(logger, "Path has already been summarized, skipping summary generation...");
                return;
            }
        }
    }
    SPDLOG_LOGGER_TRACE(logger, "Generated summary:\n{}", *summary);
    _name_to_summaries.at(cfg.getFullyQualifiedName()).push_back(std::move(summary));
}

void Summarizer::extractNecessaryHardConstraints(std::set<std::string> &necessary_hard_constraints,
                                                 const etfa::State &state, const z3::expr &expression) const {
    std::vector<z3::expr> uninterpreted_constants = _solver->getUninterpretedConstants(expression);
    if (uninterpreted_constants.empty()) {
        assert(expression.is_true() || expression.is_false() || expression.is_numeral());
    } else if (uninterpreted_constants.size() == 1) {
        std::string contextualized_name = uninterpreted_constants.at(0).decl().name().str();
        z3::expr nested_expression = state.getSymbolicValuation(contextualized_name);
        std::vector<z3::expr> nested_uninterpreted_constants = _solver->getUninterpretedConstants(nested_expression);
        if (nested_uninterpreted_constants.empty()) {
            assert(nested_expression.is_true() || nested_expression.is_false() || nested_expression.is_numeral());
            necessary_hard_constraints.insert(contextualized_name);
        } else if (nested_uninterpreted_constants.size() == 1) {
            std::string nested_contextualized_name = nested_uninterpreted_constants.at(0).decl().name().str();
            if (contextualized_name == nested_contextualized_name) {
                // XXX "truly" symbolic
                necessary_hard_constraints.insert(contextualized_name);
            } else {
                necessary_hard_constraints.insert(contextualized_name);
                extractNecessaryHardConstraints(necessary_hard_constraints, state, nested_expression);
            }
        } else {
            necessary_hard_constraints.insert(contextualized_name);
            extractNecessaryHardConstraints(necessary_hard_constraints, state, nested_expression);
        }
    } else {
        for (const z3::expr &uninterpreted_constant : uninterpreted_constants) {
            std::string contextualized_name = uninterpreted_constant.decl().name().str();
            necessary_hard_constraints.insert(contextualized_name);
            extractNecessaryHardConstraints(necessary_hard_constraints, state, uninterpreted_constant);
        }
    }
}

std::pair<bool, boost::optional<std::set<unsigned int>>>
Summarizer::isSummaryApplicable(const Summary &summary, const std::map<std::string, z3::expr> &symbolic_valuations,
                                const std::vector<z3::expr> &path_constraint) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_TRACE(logger, "Checking summary for applicability...\n{}", summary);

    z3::context &context = _solver->getContext();
    // Encode the current context's valuations reaching summary application point
    z3::expr_vector valuations(context);
    for (const auto &symbolic_valuation : symbolic_valuations) {
        if (symbolic_valuation.second.is_bool()) {
            valuations.push_back(_solver->makeBooleanConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else if (symbolic_valuation.second.is_int()) {
            valuations.push_back(_solver->makeIntegerConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }

    // Encode path constraint
    z3::expr_vector pc(context);
    for (const auto &constraint : path_constraint) {
        pc.push_back(constraint);
    }

    // Encode summary
    z3::expr_vector assumptions(context);
    z3::expr_vector assumption_literals(context);
    unsigned int index = 0;
    // debug
    std::map<std::string, z3::expr> assumption_literal_to_assumption;
    for (const z3::expr &assumption : summary.getAssumptions()) {
        std::string assumption_literal_name = "b" + std::to_string(index);
        z3::expr assumption_literal = _solver->makeBooleanConstant(assumption_literal_name);
        assumptions.push_back(z3::implies(assumption_literal, assumption));
        assumption_literals.push_back(assumption_literal);
        // debug
        assumption_literal_to_assumption.emplace(assumption_literal_name, assumption);
        index++;
    }

    z3::expr_vector hard_constraints(context);
    for (const auto &hard_constraint : summary.getHardConstraints()) {
        if (hard_constraint.second.is_bool()) {
            hard_constraints.push_back(_solver->makeBooleanConstant(hard_constraint.first) == hard_constraint.second);
        } else if (hard_constraint.second.is_int()) {
            hard_constraints.push_back(_solver->makeIntegerConstant(hard_constraint.first) == hard_constraint.second);
        } else {
            throw std::runtime_error("Unsupported z3::sort encountered.");
        }
    }

    z3::tactic tactic = z3::tactic(_solver->getContext(), "simplify") & z3::tactic(_solver->getContext(), "solve-eqs") &
                        z3::tactic(_solver->getContext(), "smt");
    z3::solver solver = tactic.mk_solver();
    solver.set("unsat_core", true);

    solver.add(valuations);
    solver.add(pc);
    solver.add(assumptions);
    solver.add(hard_constraints);

    SPDLOG_LOGGER_TRACE(logger, "Solver assertions:\n{}\nunder assumption literals:\n{}", solver.assertions(),
                        assumption_literals);

    z3::check_result check_result = solver.check(assumption_literals);

    std::pair<bool, boost::optional<std::set<unsigned int>>> result;
    switch (check_result) {
        case z3::unsat: {
            SPDLOG_LOGGER_TRACE(logger, "solver returned unsat, summary is not applicable.");
            z3::expr_vector unsat_core = solver.unsat_core();
            SPDLOG_LOGGER_TRACE(logger, "unsat core: {}", unsat_core);
            // std::cout << "summary is not applicable, unsat core:\n";
            std::set<unsigned int> unsat_ids;
            for (const z3::expr &unsat_ass_lit : unsat_core) {
                /*std::cout << unsat_ass_lit.to_string() << " -> "
                          << assumption_literal_to_assumption.at(unsat_ass_lit.to_string()) << std::endl;*/
                unsat_ids.insert(assumption_literal_to_assumption.at(unsat_ass_lit.to_string()).id());
            }
            result.first = false;
            result.second = unsat_ids;
            break;
        }
        case z3::sat: {
            z3::model z3_model = solver.get_model();
            SPDLOG_LOGGER_TRACE(logger, "solver returned sat, summary is applicable.");
            //std::cout << "summary is applicable" << std::endl;
            /*
            std::stringstream str;
            for (unsigned int i = 0; i < z3_model.size(); ++i) {
                z3::func_decl constant_declaration = z3_model.get_const_decl(i);
                assert(constant_declaration.is_const() && constant_declaration.arity() == 0);
                std::string contextualized_name = constant_declaration.name().str();
                z3::expr interpretation = z3_model.get_const_interp(constant_declaration);
                str << contextualized_name << " -> " << interpretation << "\n";
            }
            SPDLOG_LOGGER_TRACE(logger, "model:\n{}", str.str());
            */
            result.first = true;
            result.second = boost::none;
            break;
        }
        case z3::unknown:
            // XXX fall-through
        default:
            throw std::runtime_error("Invalid z3::check_result encountered.");
    }
    return result;
}

bool Summarizer::isSummaryApplicableViaEvaluation(const se::summarization::Summary &summary,
                                                  const etfa::Context &context) {
    auto logger = spdlog::get("ETFA");
    SPDLOG_LOGGER_TRACE(logger, "Checking summary for applicability...\n{}", summary);

    z3::context &z3_ctx = _solver->getContext();

    const auto &assumptions = summary.getAssumptions();
    z3::expr_vector lowered_assumptions(z3_ctx);
    for (const z3::expr &assumption : assumptions) {
        lowered_assumptions.push_back(lowerExpressionForEvaluation(summary, assumption));
    }
    // SPDLOG_LOGGER_TRACE(logger, "Lowered assumptions:\n{}", lowered_assumptions.to_string());

    // build a model from the current context
    unsigned int cycle = context.getCycle();
    const etfa::State &state = context.getState();
    const etfa::Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();

    z3::model model(z3_ctx);
    // XXX: this part is code duplication from "findConcretelyApplicableSummaries" with changes
    // "reversion" current valuations
    std::map<std::string, z3::expr> reversioned_valuations;
    const ir::Interface &interface = cfg.getInterface();
    for (auto variable = interface.variablesBegin(); variable != interface.variablesEnd(); ++variable) {
        if (variable->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
            continue;
        }
        std::string name = variable->getName();
        std::string flattened_name = frame.getScope() + "." + name;
        unsigned int version = state.getVersion(flattened_name);
        std::string contextualized_name = flattened_name + "_" + std::to_string(version) + "__" + std::to_string(cycle);
        z3::expr current_valuation = state.getSymbolicValuation(contextualized_name);
        std::string reversioned_name = flattened_name + "_0";
        //SPDLOG_LOGGER_TRACE(logger, "{} reversioned to {} -> {}", contextualized_name, reversioned_name,
        //                    current_valuation.to_string());
        reversioned_valuations.emplace(reversioned_name, current_valuation);
    }

    // TODO: the lowered valuations may contain other valuations that are not lowered,
    //  hence making the model incomplete -> how to consider all necessary hard constraints?
    // (define-fun P.f.x_0 () Int
    //  P.a_0__1)
    // (define-fun P.f.y_0 () Int
    //  (ite (and (>= P.f.x_1__0 32) (not (>= P.f.y_4__0 3))) P.f.y_4__0 P.f.y_2__0))
    // (define-fun P.f.z_0 () Bool
    //  false)

    // add all symbolic valuations to the set of current symbolic valuations because they might be referenced
    // by a reversioned symbolic valuation's right-hand side
    for (const auto &symbolic_valuation : state.getSymbolicValuations()) {
        reversioned_valuations.emplace(symbolic_valuation.first, symbolic_valuation.second);
    }

    for (const auto &reversioned_valuation : reversioned_valuations) {
        if (reversioned_valuation.second.is_bool()) {
            z3::expr lhs = _solver->makeBooleanConstant(reversioned_valuation.first);
            z3::func_decl decl = lhs.decl();
            z3::expr rhs = reversioned_valuation.second;
            model.add_const_interp(decl, rhs);
        } else if (reversioned_valuation.second.is_int()) {
            z3::expr lhs = _solver->makeIntegerConstant(reversioned_valuation.first);
            z3::func_decl decl = lhs.decl();
            z3::expr rhs = reversioned_valuation.second;
            model.add_const_interp(decl, rhs);
        } else {
            throw std::runtime_error("Invalid z3::sort encountered.");
        }
    }
    //SPDLOG_LOGGER_TRACE(logger, "current model:\n{}", model.to_string());

    z3::expr result = model.eval(z3::mk_and(lowered_assumptions), true);
    //SPDLOG_LOGGER_TRACE(logger, "Result of evaluation:\n{}", result.to_string());
    if (result.is_true()) {
        return true;
    } else if (result.is_false()) {
        return false;
    } else {
        // this case occurs if summary consists of one or more whole-program inputs
        // TODO: can we simply return true? whole-program inputs can not invalidate the summary, can they? -> NO!
        //  because while they can not invalidate them, choices dependent on whole-program inputs can! For example:
        //  (define-fun P.f.y_0 () Int
        //    (ite (and (>= P.f.x_1__0 32) (not (>= P.f.y_4__0 3))) P.f.y_4__0 P.f.y_2__0)
        // TODO: We must test the result for positive (>= x_1_0 32) and negative (not (>= x_1_0 32)) values! If both
        //  are false, then the summary is not applicable, if one or both are true then the summary is deemed to be
        //  applicable.

        // TODO: extracting necessary hard constraints is slower than just putting everything on the solver
        /*
        std::set<std::string> necessary_hard_constraints;
        extractNecessaryHardConstraints(necessary_hard_constraints, state, result);

        SPDLOG_LOGGER_TRACE(logger, "Necessary hard constraints:{}", necessary_hard_constraints);

        const auto &symbolic_valuations = state.getSymbolicValuations();

        z3::expr_vector exprs(z3_ctx);
        exprs.push_back(result);
        for (const std::string &necessary_hard_constraint : necessary_hard_constraints) {
            z3::expr rhs = symbolic_valuations.at(necessary_hard_constraint);
            if (rhs.is_bool()) {
                z3::expr lhs = _solver->makeBooleanConstant(necessary_hard_constraint);
                exprs.push_back(lhs == rhs);
            } else if (rhs.is_int()) {
                z3::expr lhs = _solver->makeIntegerConstant(necessary_hard_constraint);
                exprs.push_back(lhs == rhs);
            } else {
                throw std::runtime_error("Invalid z3::sort type encountered.");
            }
        }
        */

        z3::expr_vector exprs(z3_ctx);
        exprs.push_back(result);

        const auto &symbolic_valuations = state.getSymbolicValuations();
        for (const auto &symbolic_valuation : symbolic_valuations) {
            z3::expr rhs = symbolic_valuation.second;
            if (rhs.is_bool()) {
                z3::expr lhs = _solver->makeBooleanConstant(symbolic_valuation.first);
                exprs.push_back(lhs == rhs);
            } else if (rhs.is_int()) {
                z3::expr lhs = _solver->makeIntegerConstant(symbolic_valuation.first);
                exprs.push_back(lhs == rhs);
            } else {
                throw std::runtime_error("Invalid z3::sort type encountered.");
            }
        }

        // Encode path constraint
        const std::vector<z3::expr> &path_constraint = state.getPathConstraint();
        for (const auto &constraint : path_constraint) {
            exprs.push_back(constraint);
        }

        auto res = _solver->check(exprs);
        if (res.first == z3::sat) {
            z3::model new_model = *(res.second);
            // SPDLOG_LOGGER_TRACE(logger, "Result of checking:\n{}", new_model.to_string());
            return true;
        } else {
            assert(res.first == z3::unsat);
            SPDLOG_LOGGER_TRACE(logger, "Result of checking: is unsat.");
            return false;
        }
    }
}

z3::expr Summarizer::lowerExpressionForEvaluation(const se::summarization::Summary &summary,
                                                  const z3::expr &expression) const {
    z3::context &context = _solver->getContext();
    z3::expr lowered_expression = expression.simplify();
    std::vector<z3::expr> uninterpreted_constants = _solver->getUninterpretedConstants(expression);
    if (uninterpreted_constants.empty()) {
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
            return lowerExpressionForEvaluation(summary, lowered_expression);
        }
    } else {
        for (const z3::expr &uninterpreted_constant : uninterpreted_constants) {
            z3::expr_vector source(context);
            source.push_back(uninterpreted_constant);
            z3::expr_vector destination(context);
            z3::expr lowered_uninterpreted_constant = lowerExpressionForEvaluation(summary, uninterpreted_constant);
            destination.push_back(lowered_uninterpreted_constant);
            lowered_expression = lowered_expression.substitute(source, destination).simplify();
        }
        return lowered_expression;
    }
}

std::vector<Summary *> Summarizer::getApplicableSummaries(const std::map<std::string, z3::expr> &symbolic_valuations,
                                                          const std::vector<std::shared_ptr<Summary>> &summaries) {
    z3::context &context = _solver->getContext();

    std::vector<Summary *> applicable_summaries;
    // Encode the current context's valuations reaching summary application point
    z3::expr_vector valuations(context);
    for (const auto &symbolic_valuation : symbolic_valuations) {
        if (symbolic_valuation.second.is_bool()) {
            valuations.push_back(_solver->makeBooleanConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else if (symbolic_valuation.second.is_int()) {
            valuations.push_back(_solver->makeIntegerConstant(symbolic_valuation.first) == symbolic_valuation.second);
        } else {
            throw std::runtime_error("Unexpected z3::sort encountered.");
        }
    }

    z3::tactic tactic = z3::tactic(_solver->getContext(), "smt") & z3::tactic(_solver->getContext(), "simplify") &
                        z3::tactic(_solver->getContext(), "solve-eqs");
    z3::solver solver = tactic.mk_solver();
    solver.add(valuations);

    for (const std::shared_ptr<Summary> &summary : summaries) {
        // Encode summary
        z3::expr_vector assumptions(context);
        z3::expr_vector assumption_literals(context);
        // unsigned int index = 0;
        for (const z3::expr &assumption : summary->getAssumptions()) {
            /*z3::expr assumption_literal = _solver->makeBooleanConstant("b" + std::to_string(index));
            assumptions.push_back(z3::implies(assumption_literal, assumption));
            assumption_literals.push_back(assumption_literal);
            index++;*/
            assumptions.push_back(assumption);
        }

        z3::expr_vector hard_constraints(context);
        for (const auto &hard_constraint : summary->getHardConstraints()) {
            if (hard_constraint.second.is_bool()) {
                hard_constraints.push_back(_solver->makeBooleanConstant(hard_constraint.first) ==
                                           hard_constraint.second);
            } else if (hard_constraint.second.is_int()) {
                hard_constraints.push_back(_solver->makeIntegerConstant(hard_constraint.first) ==
                                           hard_constraint.second);
            } else {
                throw std::runtime_error("Unsupported z3::sort encountered.");
            }
        }

        solver.push();
        solver.add(hard_constraints);
        solver.push();
        solver.add(assumptions);

        //z3::check_result result = solver.check(assumption_literals);
        z3::check_result result = solver.check();

        switch (result) {
            case z3::unsat: {
                z3::expr_vector unsat_core = solver.unsat_core();
                solver.pop();
                break;
            }
            case z3::sat: {
                z3::model z3_model = solver.get_model();
                applicable_summaries.push_back(summary.get());
                break;
            }
            case z3::unknown:
                // XXX fall-through
            default:
                throw std::runtime_error("Invalid z3::check_result encountered.");
        }
    }

    return applicable_summaries;
}

std::string Summarizer::decontextualize(const std::string &contextualized_name) const {
    std::size_t position = contextualized_name.find('_');
    assert(position != std::string::npos);
    return contextualized_name.substr(0, position);
}

std::vector<z3::expr> Summarizer::flattenAssumptionLiterals(const Context &context) const {
    const Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();
    const State &state = context.getState();

    const z3::expr &current_assumption_literal = state.getAssumptionLiteral();
    std::string current_assumption_literal_name = current_assumption_literal.to_string();

    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());

    std::vector<z3::expr> flattened_assumption_literals{current_assumption_literal};
    while (current_assumption_literal_name != entry_assumption_literal_name) {
        std::vector<z3::expr> preceding_assumption_literals =
                state.getAssumptionLiterals(current_assumption_literal_name);
        // XXX invariant always holds if no call to another FB or no merge within this FB has occurred
        assert(preceding_assumption_literals.size() == 1);
        const z3::expr &preceding_assumption_literal = preceding_assumption_literals.at(0);
        flattened_assumption_literals.emplace_back(preceding_assumption_literal);
        current_assumption_literal_name = preceding_assumption_literal.to_string();
    }
    std::reverse(flattened_assumption_literals.begin(), flattened_assumption_literals.end());
    return flattened_assumption_literals;
}

std::vector<z3::expr> Summarizer::flattenAssumptionLiterals(const se::reuse::Context &context) const {
    const reuse::Frame &frame = context.getFrame();
    const Cfg &cfg = frame.getCfg();
    const reuse::State &state = context.getState();

    std::vector<z3::expr> flattened_assumption_literals;
    for (const auto &kvp : state.getAssumptionLiterals()) {
        flattened_assumption_literals.push_back(_solver->makeBooleanConstant(kvp.first));
    }
    return flattened_assumption_literals;

    /*
    const z3::expr &current_assumption_literal = state.getAssumptionLiteral();
    std::string current_assumption_literal_name = current_assumption_literal.to_string();

    std::string entry_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(cfg.getEntryLabel());

    std::vector<z3::expr> flattened_assumption_literals{current_assumption_literal};
    while (current_assumption_literal_name != entry_assumption_literal_name) {
        std::vector<z3::expr> preceding_assumption_literals =
                state.getAssumptionLiterals(current_assumption_literal_name);
        // XXX invariant always holds if no call to another FB or no merge within this FB has occurred
        assert(preceding_assumption_literals.size() == 1);
        const z3::expr &preceding_assumption_literal = preceding_assumption_literals.at(0);
        flattened_assumption_literals.emplace_back(preceding_assumption_literal);
        current_assumption_literal_name = preceding_assumption_literal.to_string();
    }
    std::reverse(flattened_assumption_literals.begin(), flattened_assumption_literals.end());
    return flattened_assumption_literals;
    */
}

std::unique_ptr<Summary> Summarizer::summarizePath(const se::reuse::Context &context,
                                                   const std::vector<z3::expr> &path) const {
    auto version_comparer = [](const std::string &contextualized_name_1, const std::string &contextualized_name_2) {
        std::size_t version_position_1 = contextualized_name_1.find('_');
        assert(version_position_1 != std::string::npos);
        std::size_t version_position_2 = contextualized_name_2.find('_');
        assert(version_position_2 != std::string::npos);
        std::string name_1 = contextualized_name_1.substr(0, version_position_1);
        std::string name_2 = contextualized_name_2.substr(0, version_position_2);
        unsigned int version_1 =
                std::stoi(contextualized_name_1.substr(version_position_1 + 1, contextualized_name_1.length()));
        unsigned int version_2 =
                std::stoi(contextualized_name_2.substr(version_position_2 + 1, contextualized_name_2.length()));
        if (name_1 < name_2) {
            return true;
        } else if (name_1 == name_2) {
            if (version_1 < version_2) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    };

    auto logger = spdlog::get("Summarization");
    SPDLOG_LOGGER_TRACE(logger, "Trying to summarize path in the new program version...");
    const reuse::Frame &frame = context.getFrame();

    // "Re-versioning"
    const Cfg &cfg = frame.getCfg();
    const ir::Interface &interface = cfg.getInterface();
    std::map<std::string, std::set<std::string, decltype(version_comparer)>> flattened_names_to_contextualized_names;
    std::set<std::string, decltype(version_comparer)> modified_contextualized_names(version_comparer);
    for (auto it = interface.variablesBegin(); it != interface.variablesEnd(); ++it) {
        if (it->getDataType().getKind() == ir::DataType::Kind::DERIVED_TYPE) {
            continue;
        }
        std::string name = it->getName();
        std::string flattened_name = frame.getScope() + "." + name;
        flattened_names_to_contextualized_names.emplace(
                flattened_name, std::set<std::string, decltype(version_comparer)>(version_comparer));
    }

    const reuse::State &state = context.getState();
    std::vector<z3::expr> assumption_literals;
    for (const z3::expr &assumption_literal : path) {
        std::string assumption_literal_name = assumption_literal.to_string();
        assumption_literals.push_back(_solver->makeBooleanConstant(assumption_literal_name));
    }

    {// Pass 1
        const std::map<std::string, std::vector<z3::expr>> &assumptions = state.getAssumptions();
        const std::map<std::string, std::map<std::string, z3::expr>> &hard_constraints = state.getHardConstraints();
        for (const z3::expr &assumption_literal : path) {
            std::string assumption_literal_name = assumption_literal.to_string();
            auto assumptions_it =
                    std::find_if(assumptions.begin(), assumptions.end(),
                                 [&assumption_literal_name](const auto &assumption_literal_name_to_assumptions) {
                                     return assumption_literal_name == assumption_literal_name_to_assumptions.first;
                                 });
            if (assumptions_it != assumptions.end()) {
                for (const z3::expr &assumption : assumptions_it->second) {
                    for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(assumption)) {
                        std::string contextualized_name = uninterpreted_constant.to_string();
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                }
            }
            auto hard_constraints_it = std::find_if(
                    hard_constraints.begin(), hard_constraints.end(),
                    [&assumption_literal_name](const auto &assumption_literal_name_to_hard_constraints) {
                        return assumption_literal_name == assumption_literal_name_to_hard_constraints.first;
                    });
            if (hard_constraints_it != hard_constraints.end()) {
                for (const auto &hard_constraint : hard_constraints_it->second) {
                    {// lhs
                        std::string contextualized_name = hard_constraint.first;
                        modified_contextualized_names.insert(contextualized_name);
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                    // rhs
                    z3::expr expression = hard_constraint.second;
                    for (const z3::expr &uninterpreted_constant : _solver->getUninterpretedConstants(expression)) {
                        std::string contextualized_name = uninterpreted_constant.to_string();
                        std::string flattened_name = decontextualize(contextualized_name);
                        flattened_names_to_contextualized_names.at(flattened_name).insert(contextualized_name);
                    }
                }
            }
        }
    }

    std::map<std::string, std::string, decltype(version_comparer)> contextualized_names_to_reversioned_names(
            version_comparer);
    for (const auto &flattened_name_to_contextualized_name : flattened_names_to_contextualized_names) {
        unsigned int version = 0;
        for (const std::string &contextualized_name : flattened_name_to_contextualized_name.second) {
            auto it = modified_contextualized_names.find(contextualized_name);
            std::string reversioned_name;
            if (it == modified_contextualized_names.end()) {
                // variable is read
                reversioned_name = flattened_name_to_contextualized_name.first + "_" + std::to_string(version);
            } else {
                // variable is written, ensure versioning always starts at 1
                version = version + 1;
                reversioned_name = flattened_name_to_contextualized_name.first + "_" + std::to_string(version);
            }
            contextualized_names_to_reversioned_names.emplace(contextualized_name, reversioned_name);
        }
    }

    // Pass 2: reversion contextualized names across the assumptions and hard constraints
    std::vector<z3::expr> assumptions;
    std::map<std::string, std::vector<z3::expr>> assumption_literals_to_assumptions;
    std::map<std::string, z3::expr> hard_constraints;
    std::map<std::string, std::map<std::string, z3::expr>> assumption_literals_to_hard_constraints;
    for (const z3::expr &assumption_literal : path) {
        std::string assumption_literal_name = assumption_literal.to_string();
        auto assumptions_it =
                std::find_if(state.getAssumptions().begin(), state.getAssumptions().end(),
                             [&assumption_literal_name](const auto &assumption_literal_name_to_assumptions) {
                                 return assumption_literal_name == assumption_literal_name_to_assumptions.first;
                             });
        if (assumptions_it != state.getAssumptions().end()) {
            std::vector<z3::expr> assumption_expressions;
            for (const z3::expr &assumption_expression : assumptions_it->second) {
                z3::expr substituted_assumption_expression = assumption_expression;
                for (const z3::expr &uninterpreted_constant :
                     _solver->getUninterpretedConstants(substituted_assumption_expression)) {
                    std::string contextualized_name = uninterpreted_constant.to_string();
                    std::string reversioned_name = contextualized_names_to_reversioned_names.at(contextualized_name);
                    z3::expr_vector src(_solver->getContext());
                    src.push_back(uninterpreted_constant);
                    z3::expr_vector dst(_solver->getContext());
                    if (uninterpreted_constant.is_bool()) {
                        dst.push_back(_solver->makeBooleanConstant(reversioned_name));
                    } else if (uninterpreted_constant.is_int()) {
                        dst.push_back(_solver->makeIntegerConstant(reversioned_name));
                    } else {
                        throw std::runtime_error("Unsupported z3::sort encountered.");
                    }
                    substituted_assumption_expression = substituted_assumption_expression.substitute(src, dst);
                }
                assumptions.push_back(substituted_assumption_expression);
                assumption_expressions.push_back(substituted_assumption_expression);
            }
            assumption_literals_to_assumptions.emplace(assumption_literal_name, std::move(assumption_expressions));
        }
        auto hard_constraints_it =
                std::find_if(state.getHardConstraints().begin(), state.getHardConstraints().end(),
                             [&assumption_literal_name](const auto &assumption_literal_name_to_hard_constraints) {
                                 return assumption_literal_name == assumption_literal_name_to_hard_constraints.first;
                             });
        if (hard_constraints_it != state.getHardConstraints().end()) {
            std::map<std::string, z3::expr> hard_constraint_expressions;
            for (const auto &hard_constraint : hard_constraints_it->second) {
                z3::expr substituted_hard_constraint = hard_constraint.second;
                for (const z3::expr &uninterpreted_constant :
                     _solver->getUninterpretedConstants(substituted_hard_constraint)) {
                    std::string contextualized_name = uninterpreted_constant.to_string();
                    std::string reversioned_name = contextualized_names_to_reversioned_names.at(contextualized_name);
                    z3::expr_vector src(_solver->getContext());
                    src.push_back(uninterpreted_constant);
                    z3::expr_vector dst(_solver->getContext());
                    if (uninterpreted_constant.is_bool()) {
                        dst.push_back(_solver->makeBooleanConstant(reversioned_name));
                    } else if (uninterpreted_constant.is_int()) {
                        dst.push_back(_solver->makeIntegerConstant(reversioned_name));
                    } else {
                        throw std::runtime_error("Unsupported z3::sort encountered.");
                    }
                    substituted_hard_constraint = substituted_hard_constraint.substitute(src, dst);
                }
                std::string reversioned_name = contextualized_names_to_reversioned_names.at(hard_constraint.first);
                hard_constraints.emplace(reversioned_name, substituted_hard_constraint);
                hard_constraint_expressions.emplace(reversioned_name, substituted_hard_constraint);
            }
            assumption_literals_to_hard_constraints.emplace(assumption_literal_name,
                                                            std::move(hard_constraint_expressions));
        }
    }

    std::unique_ptr<Summary> summary = std::make_unique<Summary>(
            std::move(assumptions), std::move(hard_constraints), std::move(assumption_literals),
            std::move(assumption_literals_to_assumptions), std::move(assumption_literals_to_hard_constraints));

    SPDLOG_LOGGER_TRACE(logger, "Regenerated a summary for the new program version from invalid summary:\n{}",
                        *summary);
    return summary;
}