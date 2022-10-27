#ifndef AHORN_SUMMARIZATION_STATE_H
#define AHORN_SUMMARIZATION_STATE_H

#include "cfg/cfg.h"
#include "cfg/vertex.h"

#include "z3++.h"

#include <map>
#include <vector>

namespace se::summarization {
    class State {
    public:
        // XXX default constructor disabled
        State() = delete;
        // XXX copy constructor disabled
        State(const State &other) = delete;
        // XXX copy assignment disabled
        State &operator=(const State &) = delete;

        State(const Vertex &vertex, z3::expr assumption_literal,
              std::map<std::string, std::vector<z3::expr>> assumption_literals,
              std::map<std::string, std::vector<z3::expr>> assumptions,
              std::map<std::string, std::map<std::string, z3::expr>> hard_constraints,
              std::map<std::string, unsigned int> flattened_name_to_version);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const State &state) {
            return state.print(os);
        }

        const Vertex &getVertex() const;

        void setVertex(const Vertex &vertex);

        z3::expr getAssumptionLiteral() const;

        void setAssumptionLiteral(const z3::expr &assumption_literal);

        const std::map<std::string, std::vector<z3::expr>> &getAssumptionLiterals() const;

        const std::vector<z3::expr> &getAssumptionLiterals(const std::string &assumption_literal_name) const;

        void pushAssumptionLiteral(const std::string &assumption_literal_name, const z3::expr &assumption_literal);

        const std::map<std::string, std::vector<z3::expr>> &getAssumptions() const;

        void pushAssumption(const std::string &assumption_literal_name, const z3::expr &assumption);

        const std::map<std::string, std::map<std::string, z3::expr>> &getHardConstraints() const;

        void pushHardConstraint(const std::string &assumption_literal_name, const std::string &contextualized_name,
                                const z3::expr &expression);

        unsigned int getVersion(const std::string &flattened_name) const;

        void setVersion(const std::string &flattened_name, unsigned int version);

        std::unique_ptr<State> fork(const Vertex &vertex) const;

    private:
        const Vertex *_vertex;
        z3::expr _assumption_literal;
        std::map<std::string, std::vector<z3::expr>> _assumption_literals;
        std::map<std::string, std::vector<z3::expr>> _assumptions;
        std::map<std::string, std::map<std::string, z3::expr>> _hard_constraints;
        std::map<std::string, unsigned int> _flattened_name_to_version;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_STATE_H
