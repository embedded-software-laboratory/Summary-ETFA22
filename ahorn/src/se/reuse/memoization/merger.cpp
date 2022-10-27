#include "se/reuse/memoization/merger.h"
#include "ir/instruction/call_instruction.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/spdlog.h"

using namespace se::reuse;

Merger::Merger(etfa::Solver &solver, Executor &executor)
    : _solver(&solver), _executor(&executor),
      _merge_point_to_contexts(std::map<merge_point_t, std::vector<std::unique_ptr<Context>>>()) {}

bool Merger::isEmpty() const {
    bool is_empty = true;
    for (const auto &merge_point_to_contexts : _merge_point_to_contexts) {
        if (!merge_point_to_contexts.second.empty()) {
            is_empty = false;
            break;
        }
    }
    return is_empty;
}

bool Merger::reachedMergePoint(const Context &context) const {
    const Frame &frame = context.getFrame();
    unsigned int return_label = frame.getReturnLabel();
    std::string scope = frame.getScope();
    unsigned int depth = context.getCallStackDepth();
    const State &state = context.getState();
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    return _merge_points.count(std::tuple(scope, depth, label, return_label)) != 0;
}

void Merger::push(std::unique_ptr<Context> context) {
    const Frame &frame = context->getFrame();
    unsigned int return_label = frame.getReturnLabel();
    std::string scope = frame.getScope();
    unsigned int depth = context->getCallStackDepth();
    const State &state = context->getState();
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    assert(_merge_points.count(std::tuple(scope, depth, label, return_label)) != 0);
    assert(_merge_point_to_contexts.count(std::tuple(scope, depth, label, return_label)) != 0);
    _merge_point_to_contexts.at(std::tuple(scope, depth, label, return_label)).push_back(std::move(context));
}

std::unique_ptr<Context> Merger::merge() {
    auto logger = spdlog::get("Reuse");
    auto it = std::find_if(_merge_point_to_contexts.begin(), _merge_point_to_contexts.end(),
                           [](const auto &merge_point_to_context) { return !merge_point_to_context.second.empty(); });
    assert(it != _merge_point_to_contexts.end());
    merge_point_t eligible_merge_point = it->first;
    for (const auto &merge_point_to_contexts : _merge_point_to_contexts) {
        merge_point_t merge_point = merge_point_to_contexts.first;
        if (merge_point_to_contexts.second.empty()) {
            // XXX only consider non-empty merge points
            continue;
        }
        unsigned int depth = std::get<1>(merge_point);
        unsigned int label = std::get<2>(merge_point);
        unsigned int return_label = std::get<3>(merge_point);
        if (std::get<1>(eligible_merge_point) < depth) {
            eligible_merge_point = merge_point;
        } else if (std::get<1>(eligible_merge_point) == depth && std::get<3>(eligible_merge_point) > return_label) {
            eligible_merge_point = merge_point;
        } else if (std::get<1>(eligible_merge_point) == depth && std::get<3>(eligible_merge_point) == return_label &&
                   std::get<2>(eligible_merge_point) > label) {
            // XXX always prioritize lower labels at same depth
            eligible_merge_point = merge_point;
        }
    }
    std::vector<std::unique_ptr<Context>> contexts = std::move(_merge_point_to_contexts.at(eligible_merge_point));
    std::string scope = std::get<0>(eligible_merge_point);
    unsigned int depth = std::get<1>(eligible_merge_point);
    unsigned int label = std::get<2>(eligible_merge_point);
    unsigned int return_label = std::get<3>(eligible_merge_point);
    SPDLOG_LOGGER_TRACE(logger, "Trying to merge contexts at merge point: ({}, {}, {}, {})", scope, depth, label,
                        return_label);
    std::unique_ptr<Context> merged_context = std::move(contexts.at(0));
    contexts.erase(contexts.begin());
    while (!contexts.empty()) {
        std::unique_ptr<Context> context = std::move(contexts.at(0));
        contexts.erase(contexts.begin());
        merged_context = merge(std::move(merged_context), std::move(context));
    }
    return merged_context;
}

void Merger::initialize(const Cfg &cfg) {
    _merge_point_to_contexts.clear();
    // collect potential locations for merging
    std::string scope = cfg.getName();
    std::set<std::string> visited_cfgs;
    initializeMergePoints(cfg, scope, 1, cfg.getEntryLabel(), visited_cfgs);
    // initialize context queues
    for (const auto &merge_point : _merge_points) {
        _merge_point_to_contexts.emplace(merge_point, std::vector<std::unique_ptr<Context>>());
    }
}

void Merger::initializeMergePoints(const Cfg &cfg, const std::string &scope, unsigned int depth,
                                   unsigned int return_label, std::set<std::string> &visited_cfgs) {
    std::string name = cfg.getName();
    for (auto it = cfg.verticesBegin(); it != cfg.verticesEnd(); ++it) {
        switch (it->getType()) {
            case Vertex::Type::ENTRY: {
                break;
            }
            case Vertex::Type::REGULAR: {
                unsigned int label = it->getLabel();
                std::vector<std::shared_ptr<Edge>> incoming_edges = cfg.getIncomingEdges(label);
                if (incoming_edges.size() > 1) {
                    bool eligible_merge_point = true;
                    for (const auto &incoming_edge : incoming_edges) {
                        if ((incoming_edge->getType() == Edge::Type::INTRAPROCEDURAL_CALL_TO_RETURN) ||
                            ((incoming_edge->getType() == Edge::Type::INTERPROCEDURAL_CALL)) ||
                            ((incoming_edge->getType() == Edge::Type::INTERPROCEDURAL_RETURN))) {
                            eligible_merge_point = false;
                        }
                    }
                    if (eligible_merge_point) {
                        _merge_points.emplace(scope, depth, label, return_label);
                    }
                }
                if (auto call_instruction = dynamic_cast<const ir::CallInstruction *>(it->getInstruction())) {
                    std::string callee_scope = scope + "." + call_instruction->getVariableAccess().getName();
                    std::shared_ptr<Cfg> callee = cfg.getCallee(label);
                    const auto &edge = cfg.getIntraproceduralCallToReturnEdge(label);
                    initializeMergePoints(*callee, callee_scope, depth + 1, edge.getTargetLabel(), visited_cfgs);
                }
                break;
            }
            case Vertex::Type::EXIT: {
                _merge_points.emplace(scope, depth, cfg.getExitLabel(), return_label);
                break;
            }
        }
    }
}

std::unique_ptr<Context> Merger::merge(std::unique_ptr<Context> context_1, std::unique_ptr<Context> context_2) {
    auto logger = spdlog::get("Reuse");
    SPDLOG_LOGGER_TRACE(logger, "Merging...\n{}\n{}", *context_1, *context_2);

    State &state_1 = context_1->getState();
    State &state_2 = context_2->getState();

    const Vertex &vertex_1 = state_1.getVertex();
    const Vertex &vertex_2 = state_2.getVertex();
    assert(vertex_1.getLabel() == vertex_2.getLabel());
    const Vertex &vertex = vertex_1;

    z3::expr assumption_literal_1 = state_1.getAssumptionLiteral();
    z3::expr assumption_literal_2 = state_2.getAssumptionLiteral();
    assert(z3::eq(assumption_literal_1, assumption_literal_2));
    z3::expr assumption_literal = assumption_literal_1;

    // maps the corresponding assumption literal of the hard constraints to the mapping of the contextualized
    // name representing the merged version to the modified variable that comes in different versions at the merge point
    std::map<std::string, std::map<std::string, z3::expr>> modified_variable_instances;
    // identify variables whose instances are not the same across both contexts, c.f. (ii)
    std::map<std::string, unsigned int> flattened_name_to_version = state_1.getLocalVersioning();
    for (const auto &local_versioning_2 : state_2.getLocalVersioning()) {
        std::string flattened_name_2 = local_versioning_2.first;
        assert(flattened_name_to_version.find(flattened_name_2) != flattened_name_to_version.end());
        unsigned int version_1 = flattened_name_to_version.at(flattened_name_2);
        unsigned int version_2 = local_versioning_2.second;
        if (version_1 != version_2) {
            std::string contextualized_name_1 = flattened_name_2 + "_" + std::to_string(version_1);
            std::string contextualized_name_2 = flattened_name_2 + "_" + std::to_string(version_2);

            SPDLOG_LOGGER_TRACE(logger, "Merging on variable {} with versions {} and {}.", flattened_name_2,
                                contextualized_name_1, contextualized_name_2);

            // maximum version + 1 of both contexts might not be the highest version, hence retrieve the maximum
            // version from the global version store of the solver and increment it
            unsigned int merged_version = _executor->getVersion(flattened_name_2) + 1;
            // propagate merged version to the "global" and "local" version store
            _executor->setVersion(flattened_name_2, merged_version);
            flattened_name_to_version.at(flattened_name_2) = merged_version;

            // merged contextualized name
            std::string contextualized_name = flattened_name_2 + "_" + std::to_string(merged_version);

            mergeVariable(contextualized_name, *context_1, flattened_name_2, contextualized_name_1,
                          modified_variable_instances);
            mergeVariable(contextualized_name, *context_2, flattened_name_2, contextualized_name_2,
                          modified_variable_instances);
        }
    }

    // merge assumption literals
    std::map<std::string, std::vector<z3::expr>> assumption_literals = state_1.getAssumptionLiterals();
    for (const auto &assumption_literals_2 : state_2.getAssumptionLiterals()) {
        const std::string &name = assumption_literals_2.first;
        auto it = std::find_if(assumption_literals.begin(), assumption_literals.end(),
                               [name](const auto &existing_assumption_literals) {
                                   return existing_assumption_literals.first == name;
                               });
        if (it == assumption_literals.end()) {
            assumption_literals.emplace(name, assumption_literals_2.second);
        } else {
            // merge vectors without duplicates, c.f. (i)
            for (const auto &mergeable_assumption_literal_2 : assumption_literals_2.second) {
                if (std::find_if(assumption_literals.at(name).begin(), assumption_literals.at(name).end(),
                                 [mergeable_assumption_literal_2](const auto &existing_assumption_literal) {
                                     return z3::eq(mergeable_assumption_literal_2, existing_assumption_literal);
                                 }) == assumption_literals.at(name).end()) {
                    it->second.push_back(mergeable_assumption_literal_2);
                }
            }
        }
    }

    // merge assumptions
    std::map<std::string, std::vector<z3::expr>> assumptions = state_1.getAssumptions();
    for (const auto &assumptions_2 : state_2.getAssumptions()) {
        std::string assumption_literal_2_name = assumptions_2.first;
        auto it = std::find_if(assumptions.begin(), assumptions.end(),
                               [assumption_literal_2_name](const auto &assumptions) {
                                   return assumption_literal_2_name == assumptions.first;
                               });
        if (it == assumptions.end()) {
            // XXX merged contexts have different path prefixes
            assumptions.emplace(assumption_literal_2_name, assumptions_2.second);
        } else {
            // XXX contexts share the same path prefix, however, the assumptions may differ -> check and merge!
            z3::expr_vector ass_1(_solver->getContext());
            for (const z3::expr &assumption_1 : it->second) {
                ass_1.push_back(assumption_1);
            }
            z3::expr_vector ass_2(_solver->getContext());
            for (const z3::expr &assumption_2 : assumptions_2.second) {
                ass_2.push_back(assumption_2);
            }
            z3::expr ass_1_expr = z3::mk_and(ass_1);
            z3::expr ass_2_expr = z3::mk_and(ass_2);
            if (z3::eq(ass_1_expr, ass_2_expr)) {
                continue;
            } else {
                // XXX if they are unequal, we need to merge the differing assumptions
                z3::expr merged_ass_expr = (ass_1_expr && ass_2_expr).simplify();
                it->second = std::vector<z3::expr>({merged_ass_expr});
            }
        }
    }

    // hard constraints
    std::map<std::string, std::map<std::string, z3::expr>> hard_constraints = state_1.getHardConstraints();
    for (const auto &hard_constraints_2 : state_2.getHardConstraints()) {
        std::string hard_constraint_literal_2_name = hard_constraints_2.first;
        auto it = std::find_if(hard_constraints.begin(), hard_constraints.end(),
                               [hard_constraint_literal_2_name](const auto &hard_constraints) {
                                   return hard_constraint_literal_2_name == hard_constraints.first;
                               });
        if (it == hard_constraints.end()) {
            hard_constraints.emplace(hard_constraint_literal_2_name, hard_constraints_2.second);
        } else {
            // XXX contexts share the same prefix
            continue;
        }
    }

    // update hard constraints with the modified variables and their merged version, c.f. (iii)
    for (const auto &modified_variable_instance : modified_variable_instances) {
        const std::string &assumption_literal_name = modified_variable_instance.first;
        SPDLOG_LOGGER_TRACE(logger, "{}", assumption_literal_name);
        for (const auto &valuation : modified_variable_instance.second) {
            SPDLOG_LOGGER_TRACE(logger, "{} -> {}", valuation.first, valuation.second.to_string());
            auto it = hard_constraints.find(assumption_literal_name);
            if (it == hard_constraints.end()) {
                // XXX merged valuation is pushed into a preceding node that has no hard constraints
                hard_constraints.emplace(assumption_literal_name, std::map<std::string, z3::expr>());
            }
            assert(hard_constraints.at(assumption_literal_name).find(valuation.first) ==
                   hard_constraints.at(assumption_literal_name).end());
            hard_constraints.at(assumption_literal_name).emplace(valuation);
        }
    }

    auto state = std::make_unique<State>(vertex, std::move(assumption_literal), std::move(assumption_literals),
                                         std::move(assumptions), std::move(hard_constraints),
                                         std::move(flattened_name_to_version));

    const std::deque<std::shared_ptr<Frame>> &call_stack_1 = context_1->getCallStack();
    const std::deque<std::shared_ptr<Frame>> &call_stack_2 = context_2->getCallStack();
    std::deque<std::shared_ptr<Frame>> call_stack;
    for (const auto &frame : call_stack_1) {
        call_stack.push_back(std::make_shared<Frame>(frame->getCfg(), frame->getScope(), frame->getReturnLabel()));
    }
    auto context = std::make_unique<Context>(std::move(state), std::move(call_stack));
    return context;
}

void Merger::mergeVariable(const std::string &merged_contextualized_name, const Context &context,
                           const std::string &flattened_name, const std::string &contextualized_name_to_merge,
                           std::map<std::string, std::map<std::string, z3::expr>> &modified_variable_instances) {
    auto logger = spdlog::get("Reuse");

    const Frame &main_frame = context.getMainFrame();
    const Cfg &main_cfg = main_frame.getCfg();

    auto it = std::find_if(
            main_cfg.flattenedInterfaceBegin(), main_cfg.flattenedInterfaceEnd(),
            [&flattened_name](const auto &variable) { return variable.getFullyQualifiedName() == flattened_name; });
    assert(it != main_cfg.flattenedInterfaceEnd());
    const ir::DataType &data_type = it->getDataType();
    z3::expr expression = _solver->makeConstant(contextualized_name_to_merge, data_type);

    const State &state = context.getState();

    // 1. get predecessors of both states
    // 2. push merged valuation into predecessors as hard constraints
    const std::vector<z3::expr> &predecessors = state.getAssumptionLiterals(state.getAssumptionLiteral().to_string());

    // Save a mapping from new merged valuation to the respective assumption literal which used the prior valuation
    for (const z3::expr &preceding_assumption_literal : predecessors) {
        std::string preceding_assumption_literal_name = preceding_assumption_literal.to_string();
        SPDLOG_LOGGER_TRACE(logger, "Introducing {} -> {} at {}.", merged_contextualized_name,
                            contextualized_name_to_merge, preceding_assumption_literal_name,
                            contextualized_name_to_merge, expression.to_string());
        if (modified_variable_instances.count(preceding_assumption_literal_name)) {
            modified_variable_instances.at(preceding_assumption_literal_name)
                    .emplace(merged_contextualized_name, expression);
        } else {
            modified_variable_instances.emplace(
                    preceding_assumption_literal_name,
                    std::map<std::string, z3::expr>({{merged_contextualized_name, expression}}));
        }
    }
}