#ifndef AHORN_CBMC_STATE_H
#define AHORN_CBMC_STATE_H

#include "cfg/vertex.h"

#include "z3++.h"

#include <map>
#include <vector>

namespace se::cbmc {

    class AssumptionLiteralNameComparator {
    public:
        bool operator()(const std::string &assumption_literal_name_1,
                        const std::string &assumption_literal_name_2) const {
            // cut prefix "b_"
            std::string ass_lit_name_1 = assumption_literal_name_1.substr(2, assumption_literal_name_1.length());
            std::string ass_lit_name_2 = assumption_literal_name_2.substr(2, assumption_literal_name_2.length());
            std::size_t version_position_1 = ass_lit_name_1.find('_');
            std::size_t version_position_2 = ass_lit_name_2.find('_');
            std::size_t cycle_position_1 = ass_lit_name_1.find("__");
            std::size_t cycle_position_2 = ass_lit_name_2.find("__");
            std::string flattened_name_1 = ass_lit_name_1.substr(0, version_position_1);
            std::string flattened_name_2 = ass_lit_name_2.substr(0, version_position_2);
            std::size_t scope_count_1 = std::count(ass_lit_name_1.begin(), ass_lit_name_1.end(), '.');
            std::size_t scope_count_2 = std::count(ass_lit_name_2.begin(), ass_lit_name_2.end(), '.');
            unsigned int version_1 =
                    std::stoi(ass_lit_name_1.substr(version_position_1 + 1, cycle_position_1 - version_position_1 - 1));
            unsigned int version_2 =
                    std::stoi(ass_lit_name_2.substr(version_position_2 + 1, cycle_position_2 - version_position_2 - 1));
            unsigned int cycle_1 = std::stoi(ass_lit_name_1.substr(cycle_position_1 + 2, ass_lit_name_1.size()));
            unsigned int cycle_2 = std::stoi(ass_lit_name_2.substr(cycle_position_2 + 2, ass_lit_name_2.size()));
            if (cycle_1 < cycle_2) {
                return true;
            } else if (cycle_1 == cycle_2) {
                if (scope_count_1 < scope_count_2) {
                    return true;
                } else if (scope_count_1 == scope_count_2) {
                    if (flattened_name_1 < flattened_name_2) {
                        return true;
                    } else if (flattened_name_1 == flattened_name_2) {
                        if (version_1 < version_2) {
                            return true;
                        } else {
                            return false;
                        }
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
    };

    class State {
    public:
        // XXX default constructor disabled
        State() = delete;
        // XXX copy constructor disabled
        State(const State &other) = delete;
        // XXX copy assignment disabled
        State &operator=(const State &) = delete;

        State(std::map<std::string, z3::expr> initial_valuations,
              std::map<std::string, unsigned int> flattened_name_to_version, const Vertex &vertex,
              z3::expr assumption_literal,
              std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> assumption_literals,
              std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> assumptions,
              std::map<std::string, std::map<std::string, z3::expr>, AssumptionLiteralNameComparator> hard_constraints);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const State &state) {
            return state.print(os);
        }

        const std::map<std::string, z3::expr> &getInitialValuations() const;

        const std::map<std::string, unsigned int> &getLocalVersioning() const;

        unsigned int getVersion(const std::string &flattened_name) const;

        void setVersion(const std::string &flattened_name, unsigned int version);

        const Vertex &getVertex() const;

        void setVertex(const Vertex &vertex);

        z3::expr getAssumptionLiteral() const;

        void setAssumptionLiteral(z3::expr assumption_literal);

        const std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> &
        getAssumptionLiterals() const;

        const std::vector<z3::expr> &getAssumptionLiterals(const std::string &assumption_literal_name) const;

        void pushAssumptionLiteral(std::string assumption_literal_name, z3::expr assumption_literal);

        const std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> &getAssumptions() const;

        void pushAssumption(std::string assumption_literal_name, z3::expr assumption);

        const std::map<std::string, std::map<std::string, z3::expr>, AssumptionLiteralNameComparator> &
        getHardConstraints() const;

        void pushHardConstraint(std::string assumption_literal_name, const std::string &contextualized_name,
                                z3::expr expression);

        std::unique_ptr<State> fork(const Vertex &vertex, z3::expr next_assumption_literal,
                                    const std::string &next_assumption_literal_name, z3::expr encoded_expression);

    private:
        // initial valuations
        std::map<std::string, z3::expr> _initial_valuations;

        // "locally" managed variable versioning for implicit SSA-form
        std::map<std::string, unsigned int> _flattened_name_to_version;

        const Vertex *_vertex;
        z3::expr _assumption_literal;
        // keeps track of the topology-induced control-flow in form of assumption literals, maps an assumption
        // literal name to the set of predecessor assumption literals (or/disjunction) that can reach the encoded vertex
        std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> _assumption_literals;
        std::map<std::string, std::vector<z3::expr>, AssumptionLiteralNameComparator> _assumptions;
        std::map<std::string, std::map<std::string, z3::expr>, AssumptionLiteralNameComparator> _hard_constraints;
    };
}// namespace se::cbmc

#endif//AHORN_CBMC_STATE_H
