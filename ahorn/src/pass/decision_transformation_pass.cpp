#include "pass/decision_transformation_pass.h"

using namespace pass;

DecisionTransformationPass::DecisionTransformationPass()
    : _label(9000),
      _decision_label_to_intermediate_successors(std::map<unsigned int, std::pair<unsigned int, unsigned int>>()) {}

std::shared_ptr<Cfg> DecisionTransformationPass::apply(const Cfg &cfg) {
    std::vector<std::shared_ptr<ir::Variable>> variables;
    for (auto it = cfg.getInterface().variablesBegin(); it != cfg.getInterface().variablesEnd(); ++it) {
        if (it->hasInitialization()) {
            variables.push_back(std::make_shared<ir::Variable>(it->getName(), it->getDataType().clone(),
                                                               it->getStorageType(), it->getInitialization().clone()));
        } else {
            variables.push_back(
                    std::make_shared<ir::Variable>(it->getName(), it->getDataType().clone(), it->getStorageType()));
        }
    }
    std::unique_ptr<ir::Interface> interface = std::make_unique<ir::Interface>(std::move(variables));
    std::map<std::string, std::shared_ptr<Cfg>> type_representative_name_to_cfg;
    // recurse on callees
    for (auto callee_it = cfg.calleesBegin(); callee_it != cfg.calleesEnd(); ++callee_it) {
        std::shared_ptr<Cfg> callee_cfg = apply(*callee_it);
        type_representative_name_to_cfg.emplace(callee_cfg->getName(), std::move(callee_cfg));
    }

    std::map<unsigned int, std::shared_ptr<Vertex>> label_to_vertex;
    for (auto vertex_it = cfg.verticesBegin(); vertex_it != cfg.verticesEnd(); ++vertex_it) {
        unsigned int label = vertex_it->getLabel();
        switch (vertex_it->getType()) {
            case Vertex::Type::ENTRY: {
                label_to_vertex.emplace(label, std::make_shared<Vertex>(label, Vertex::Type::ENTRY));
                break;
            }
            case Vertex::Type::REGULAR: {
                const ir::Instruction *instruction = vertex_it->getInstruction();
                assert(instruction != nullptr);
                switch (instruction->getKind()) {
                    case ir::Instruction::Kind::ASSIGNMENT:
                    case ir::Instruction::Kind::HAVOC:
                    case ir::Instruction::Kind::CALL:
                    case ir::Instruction::Kind::GOTO: {
                        label_to_vertex.emplace(label, std::make_shared<Vertex>(label, instruction->clone()));
                        break;
                    }
                    case ir::Instruction::Kind::IF: {
                        label_to_vertex.emplace(label, std::make_shared<Vertex>(label, instruction->clone()));
                        unsigned int intermediate_true_label = _label++;
                        label_to_vertex.emplace(intermediate_true_label,
                                                std::make_shared<Vertex>(intermediate_true_label));
                        unsigned int intermediate_false_label = _label++;
                        label_to_vertex.emplace(intermediate_false_label,
                                                std::make_shared<Vertex>(intermediate_false_label));
                        _decision_label_to_intermediate_successors.emplace(
                                label, std::make_pair(intermediate_true_label, intermediate_false_label));
                        break;
                    }
                    case ir::Instruction::Kind::SEQUENCE:
                    case ir::Instruction::Kind::WHILE: {
                        throw std::logic_error("Not implemented yet.");
                    }
                    default:
                        throw std::runtime_error("Invalid instruction type encountered.");
                }
                break;
            }
            case Vertex::Type::EXIT: {
                label_to_vertex.emplace(label, std::make_shared<Vertex>(label, Vertex::Type::EXIT));
                break;
            }
            default:
                throw std::runtime_error("Invalid vertex type encountered.");
        }
    }

    std::vector<std::shared_ptr<Edge>> edges;
    for (auto edge_it = cfg.edgesBegin(); edge_it != cfg.edgesEnd(); ++edge_it) {
        unsigned int source_label = edge_it->getSourceLabel();
        unsigned int target_label = edge_it->getTargetLabel();
        switch (edge_it->getType()) {
            case Edge::Type::INTRAPROCEDURAL_CALL_TO_RETURN: {
                // XXX fall-through
            }
            case Edge::Type::INTRAPROCEDURAL: {
                // XXX fall-through
            }
            case Edge::Type::INTERPROCEDURAL_CALL: {
                edges.push_back(std::make_shared<Edge>(source_label, target_label, edge_it->getType()));
                break;
            }
            case Edge::Type::TRUE_BRANCH: {
                assert(_decision_label_to_intermediate_successors.find(source_label) !=
                       _decision_label_to_intermediate_successors.end());
                unsigned int intermediate_label = _decision_label_to_intermediate_successors.at(source_label).first;
                edges.push_back(std::make_shared<Edge>(source_label, intermediate_label, Edge::Type::TRUE_BRANCH));
                edges.push_back(std::make_shared<Edge>(intermediate_label, target_label, Edge::Type::INTRAPROCEDURAL));
                break;
            }
            case Edge::Type::FALSE_BRANCH: {
                assert(_decision_label_to_intermediate_successors.find(source_label) !=
                       _decision_label_to_intermediate_successors.end());
                unsigned int intermediate_label = _decision_label_to_intermediate_successors.at(source_label).second;
                edges.push_back(std::make_shared<Edge>(source_label, intermediate_label, Edge::Type::FALSE_BRANCH));
                edges.push_back(std::make_shared<Edge>(intermediate_label, target_label, Edge::Type::INTRAPROCEDURAL));
                break;
            }
            case Edge::Type::INTERPROCEDURAL_RETURN: {
                edges.push_back(std::make_shared<Edge>(source_label, target_label, edge_it->getCallerName(),
                                                       edge_it->getCallLabel(), edge_it->getType()));
                break;
            }
            default:
                throw std::runtime_error("Unexpected edge type encountered.");
        }
    }

    return std::make_shared<Cfg>(cfg.getType(), cfg.getName(), std::move(interface),
                                 std::move(type_representative_name_to_cfg), std::move(label_to_vertex),
                                 std::move(edges), cfg.getEntryLabel(), cfg.getExitLabel());
}