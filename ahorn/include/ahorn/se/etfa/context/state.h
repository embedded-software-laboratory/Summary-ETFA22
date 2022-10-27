#ifndef AHORN_ETFA_STATE_H
#define AHORN_ETFA_STATE_H

#include "cfg/vertex.h"

#include "z3++.h"

#include <map>
#include <memory>
#include <vector>

namespace se::etfa {
    class State {
    private:
        friend class Executor;

    public:
        // XXX default constructor disabled
        State() = delete;
        // XXX copy constructor disabled
        State(const State &other) = delete;
        // XXX copy assignment disabled
        State &operator=(const State &) = delete;

        State(const Vertex &vertex, std::map<std::string, z3::expr> symbolic_valuations,
              std::vector<z3::expr> path_constraint, std::map<std::string, unsigned int> flattened_name_to_version);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const State &state) {
            return state.print(os);
        }

        const Vertex &getVertex() const;

        void setVertex(const Vertex &vertex);

        const std::map<std::string, z3::expr> &getSymbolicValuations() const;

        z3::expr getSymbolicValuation(const std::string &contextualized_name) const;

        void setSymbolicValuation(const std::string &contextualized_name, const z3::expr &valuation);

        const std::vector<z3::expr> &getPathConstraint() const;

        void pushPathConstraint(const z3::expr &expression);

        unsigned int getVersion(const std::string &flattened_name) const;

        void setVersion(const std::string &flattened_name, unsigned int version);

        std::unique_ptr<State> fork(const Vertex &vertex, const z3::expr &expression) const;

        std::unique_ptr<State> clone() const;

    private:
        const Vertex *_vertex;
        std::map<std::string, z3::expr> _symbolic_valuations;
        std::vector<z3::expr> _path_constraint;
        // memoization of the highest version of a symbolic variable for quick look-up
        std::map<std::string, unsigned int> _flattened_name_to_version;
    };
}// namespace se::etfa

#endif//AHORN_ETFA_STATE_H
