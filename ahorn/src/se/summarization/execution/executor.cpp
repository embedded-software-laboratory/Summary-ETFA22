#include "se/summarization/execution/executor.h"
#include "ir/expression/field_access.h"
#include "ir/instruction/assignment_instruction.h"
#include "ir/instruction/havoc_instruction.h"
#include "ir/instruction/if_instruction.h"

#include "spdlog/fmt/ostr.h"
#include "spdlog/spdlog.h"

using namespace se::summarization;

Executor::Executor(etfa::Solver &solver)
    : _solver(&solver), _encoder(std::make_unique<Encoder>(*_solver)),
      _summarizer(std::make_unique<Summarizer>(*_solver)), _context(nullptr), _forked_context(boost::none) {}

std::vector<std::unique_ptr<Context>> Executor::execute(std::unique_ptr<Context> context) {
    auto logger = spdlog::get("Summarization");
    SPDLOG_LOGGER_TRACE(logger, "Executing context: \n{}", *context);

    State &state = context->getState();
    const Vertex &vertex = state.getVertex();
    Frame &frame = context->getFrame();
    const Cfg &cfg = frame.getCfg();

    std::vector<std::unique_ptr<Context>> succeeding_contexts;
    switch (vertex.getType()) {
        case Vertex::Type::ENTRY: {
            unsigned int label = vertex.getLabel();
            std::vector<unsigned int> succeeding_labels = cfg.getSucceedingLabels(label);
            assert(succeeding_labels.size() == 1);
            unsigned int next_label = succeeding_labels.at(0);
            const Vertex &next_vertex = cfg.getVertex(next_label);
            state.setVertex(next_vertex);

            z3::expr assumption_literal = state.getAssumptionLiteral();
            // relate the next assumption literal to the current assumption literal
            std::string next_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(next_label);
            state.pushAssumptionLiteral(next_assumption_literal_name, assumption_literal);
            z3::expr next_assumption_literal = _solver->makeBooleanConstant(next_assumption_literal_name);
            state.setAssumptionLiteral(next_assumption_literal);

            succeeding_contexts.push_back(std::move(context));
            break;
        }
        case Vertex::Type::REGULAR: {
            succeeding_contexts = handleRegularVertex(vertex, std::move(context));
            break;
        }
        case Vertex::Type::EXIT: {
            _summarizer->summarizePath(*context);
            break;
        }
    }
    return succeeding_contexts;
}

void Executor::initialize(const Cfg &cfg) {
    for (auto it = cfg.flattenedInterfaceBegin(); it != cfg.flattenedInterfaceEnd(); ++it) {
        std::string flattened_name = it->getFullyQualifiedName();
        _flattened_name_to_version.emplace(std::move(flattened_name), 0);
    }
}

std::vector<std::unique_ptr<Context>> Executor::handleRegularVertex(const Vertex &vertex,
                                                                    std::unique_ptr<Context> context) {
    _context = std::move(context);
    _forked_context = boost::none;

    ir::Instruction *instruction = vertex.getInstruction();
    if (instruction == nullptr) {
        // XXX intermediate decision vertex
        handleIntermediateDecisionVertex(vertex);
    } else {
        assert(instruction != nullptr);
        instruction->accept(*this);
    }

    std::vector<std::unique_ptr<Context>> succeeding_contexts;
    succeeding_contexts.push_back(std::move(_context));
    if (_forked_context.has_value()) {
        succeeding_contexts.push_back(std::move(*_forked_context));
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

    // encode assumption literal
    z3::expr assumption_literal = state.getAssumptionLiteral();
    // relate the next assumption literal to the current assumption literal
    std::string next_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(next_label);
    state.pushAssumptionLiteral(next_assumption_literal_name, assumption_literal);
    z3::expr next_assumption_literal = _solver->makeBooleanConstant(next_assumption_literal_name);
    state.setAssumptionLiteral(next_assumption_literal);
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

    State &state = _context->getState();
    unsigned int version = _flattened_name_to_version.at(flattened_name) + 1;
    // update version globally
    _flattened_name_to_version.at(flattened_name) = version;
    // update version locally
    state.setVersion(flattened_name, version);

    std::string contextualized_name = flattened_name + "_" + std::to_string(version);

    // update control-flow
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    const Edge &edge = cfg.getIntraproceduralEdge(label);
    unsigned int next_label = edge.getTargetLabel();
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);

    // encode assumption literal
    z3::expr assumption_literal = state.getAssumptionLiteral();
    // add the effect of this instruction
    state.pushHardConstraint(assumption_literal.to_string(), contextualized_name, encoded_expression);
    // relate the next assumption literal to the current assumption literal
    std::string next_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(next_label);
    state.pushAssumptionLiteral(next_assumption_literal_name, assumption_literal);
    z3::expr next_assumption_literal = _solver->makeBooleanConstant(next_assumption_literal_name);
    state.setAssumptionLiteral(next_assumption_literal);
}

void Executor::visit(const ir::CallInstruction &instruction) {
    throw std::runtime_error("Nested calls are not supported yet.");
}

void Executor::visit(const ir::IfInstruction &instruction) {
    auto logger = spdlog::get("Summarization");

    const ir::Expression &expression = instruction.getExpression();

    // encode condition symbolically
    z3::expr encoded_expression = _encoder->encode(expression, *_context);
    z3::expr negated_encoded_expression = (!encoded_expression).simplify();

    // determine control-flow
    const Frame &frame = _context->getFrame();
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

    z3::expr assumption_literal = state.getAssumptionLiteral();
    std::string next_positive_assumption_literal_name =
            "b_" + frame.getScope() + "_" + std::to_string(next_positive_label);
    z3::expr next_positive_assumption_literal = _solver->makeBooleanConstant(next_positive_assumption_literal_name);
    std::string next_negative_assumption_literal_name =
            "b_" + frame.getScope() + "_" + std::to_string(next_negative_label);
    z3::expr next_negative_assumption_literal = _solver->makeBooleanConstant(next_negative_assumption_literal_name);

    z3::expr_vector expressions(_solver->getContext());
    // control-flow constraints
    for (const auto &assumption_literals : state.getAssumptionLiterals()) {
        std::string assumption_literal_name = assumption_literals.first;
        z3::expr_vector preceding_assumption_literals(_solver->getContext());
        for (const auto &preceding_assumption_literal : assumption_literals.second) {
            preceding_assumption_literals.push_back(preceding_assumption_literal);
        }
        expressions.push_back(z3::implies(_solver->makeBooleanConstant(assumption_literal_name),
                                          z3::mk_or(preceding_assumption_literals).simplify()));
    }

    // assumption constraints
    for (const auto &assumptions : state.getAssumptions()) {
        std::string assumption_literal_name = assumptions.first;
        z3::expr_vector assumption_expressions(_solver->getContext());
        for (const auto &assumption : assumptions.second) {
            assumption_expressions.push_back(assumption);
        }
        expressions.push_back(
                z3::implies(_solver->makeBooleanConstant(assumption_literal_name), z3::mk_and(assumption_expressions)));
    }

    // hard constraints
    for (const auto &hard_constraints : state.getHardConstraints()) {
        std::string assumption_literal_name = hard_constraints.first;
        z3::expr_vector hard_constraint_expressions(_solver->getContext());
        for (const auto &hard_constraint_expression : hard_constraints.second) {
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

    // check if either "true/positive" or "false/negative" or both paths are realizable
    z3::expr_vector assumptions(_solver->getContext());
    assumptions.push_back(next_positive_assumption_literal);
    expressions.push_back(z3::implies(next_positive_assumption_literal, assumption_literal));
    expressions.push_back(z3::implies(next_positive_assumption_literal, encoded_expression));

    SPDLOG_LOGGER_TRACE(logger, "Querying solver with expressions:\n{}\nunder assumptions:\n{}", expressions,
                        assumptions);

    std::pair<z3::check_result, boost::optional<z3::model>> result =
            _solver->checkUnderAssumptions(expressions, assumptions);

    switch (result.first) {
        case z3::unsat: {
            assert(!result.second.has_value());
            SPDLOG_LOGGER_TRACE(logger,
                                "True/positive choice {} is unsatisfiable, false/negative choice {} must be "
                                "satisfiable (no need to check).",
                                next_positive_assumption_literal_name, next_negative_assumption_literal_name);

            // update control-flow
            state.setVertex(next_negative_vertex);

            // relate the next assumption literal to the current assumption literal
            state.pushAssumptionLiteral(next_negative_assumption_literal_name, assumption_literal);
            // XXX the effect is pushed into the succeeding block
            state.pushAssumption(next_negative_assumption_literal_name, !encoded_expression);
            state.setAssumptionLiteral(next_negative_assumption_literal);
            break;
        }
        case z3::sat: {
            SPDLOG_LOGGER_TRACE(logger,
                                "True/positive choice {} is satisfiable, check if false/negative choice {} is "
                                "satisfiable and execution context should be forked.",
                                next_positive_assumption_literal_name, next_negative_assumption_literal_name);

            // check if false/negative choice is satisfiable and execution context should be forked
            assumptions.pop_back();
            assumptions.push_back(next_negative_assumption_literal);
            expressions.pop_back();
            expressions.pop_back();
            expressions.push_back(z3::implies(next_negative_assumption_literal, assumption_literal));
            expressions.push_back(z3::implies(next_negative_assumption_literal, !encoded_expression));

            result = _solver->checkUnderAssumptions(expressions, assumptions);

            switch (result.first) {
                case z3::unsat: {
                    assert(!result.second.has_value());
                    SPDLOG_LOGGER_TRACE(logger,
                                        "False/negative choice {} is unsatisfiable, no fork of execution "
                                        "context.",
                                        next_negative_assumption_literal_name);
                    break;
                }
                case z3::sat: {
                    SPDLOG_LOGGER_TRACE(logger, "False/negative choice {} is satisfiable, fork of execution context.",
                                        next_negative_assumption_literal_name);

                    _forked_context = _context->fork(next_negative_vertex);
                    State &forked_state = (*_forked_context)->getState();
                    // relate the next assumption literal to the current assumption literal
                    forked_state.pushAssumptionLiteral(next_negative_assumption_literal_name, assumption_literal);
                    // XXX the effect is pushed into the succeeding block
                    forked_state.pushAssumption(next_negative_assumption_literal_name, negated_encoded_expression);
                    forked_state.setAssumptionLiteral(next_negative_assumption_literal);
                    break;
                }
                case z3::unknown: {
                    // XXX fall-through
                }
                default:
                    throw std::runtime_error("Unexpected z3::check_result encountered.");
            }

            // update control-flow
            state.setVertex(next_positive_vertex);

            // relate the next assumption literal to the current assumption literal
            state.pushAssumptionLiteral(next_positive_assumption_literal_name, assumption_literal);
            // XXX the effect is pushed into the succeeding block
            state.pushAssumption(next_positive_assumption_literal_name, encoded_expression);
            state.setAssumptionLiteral(next_positive_assumption_literal);
            break;
        }
        case z3::unknown: {
            // XXX fall-through
        }
        default:
            throw std::runtime_error("Unexpected z3::check_result encountered.");
    }
}

void Executor::visit(const ir::SequenceInstruction &instruction) {
    throw std::runtime_error("Basic block encoding is not supported yet.");
}

void Executor::visit(const ir::WhileInstruction &instruction) {
    throw std::runtime_error("Summarization of loops is not supported yet.");
}

void Executor::visit(const ir::GotoInstruction &instruction) {
    throw std::runtime_error("Should not be reachable.");
}

void Executor::visit(const ir::HavocInstruction &instruction) {
    // encode lhs of the assignment
    const Frame &frame = _context->getFrame();
    const Cfg &cfg = frame.getCfg();
    const ir::VariableReference &variable_reference = instruction.getVariableReference();
    std::string name = variable_reference.getName();
    std::string flattened_name = frame.getScope() + "." + name;

    State &state = _context->getState();
    // TODO: this is a DIRTY work-around, how does versioning in havoc generalize?
    // TODO: fix, buggy for the general case
    // unsigned int version = _flattened_name_to_version.at(flattened_name) + 1;
    unsigned int version = 0;
    // update version globally
    _flattened_name_to_version.at(flattened_name) = version;
    // update version locally
    state.setVersion(flattened_name, version);

    std::string contextualized_name = flattened_name + "_" + std::to_string(version);

    std::shared_ptr<ir::Variable> variable = nullptr;
    if (const auto *variable_access = dynamic_cast<const ir::VariableAccess *>(&variable_reference)) {
        variable = variable_access->getVariable();
    } else if (const auto *field_access = dynamic_cast<const ir::FieldAccess *>(&variable_reference)) {
        variable = field_access->getVariableAccess().getVariable();
    } else {
        throw std::runtime_error("Unexpected variable reference type encountered.");
    }
    assert(variable != nullptr);
    const auto &data_type = variable->getDataType();
    z3::expr encoded_expression = _solver->makeConstant(contextualized_name, data_type);

    // update control-flow
    const Vertex &vertex = state.getVertex();
    unsigned int label = vertex.getLabel();
    const Edge &edge = cfg.getIntraproceduralEdge(label);
    unsigned int next_label = edge.getTargetLabel();
    const Vertex &next_vertex = cfg.getVertex(next_label);
    state.setVertex(next_vertex);

    // encode assumption literal
    z3::expr assumption_literal = state.getAssumptionLiteral();
    // add the effect of this instruction
    state.pushHardConstraint(assumption_literal.to_string(), contextualized_name, encoded_expression);
    // relate the next assumption literal to the current assumption literal
    std::string next_assumption_literal_name = "b_" + frame.getScope() + "_" + std::to_string(next_label);
    state.pushAssumptionLiteral(next_assumption_literal_name, assumption_literal);
    z3::expr next_assumption_literal = _solver->makeBooleanConstant(next_assumption_literal_name);
    state.setAssumptionLiteral(next_assumption_literal);
}
