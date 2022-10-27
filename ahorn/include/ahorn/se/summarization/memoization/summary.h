#ifndef AHORN_SUMMARIZATION_SUMMARY_H
#define AHORN_SUMMARIZATION_SUMMARY_H

#include "z3++.h"

#include <map>
#include <vector>

namespace se::summarization {
    // A summary represents one path through a function block.
    class Summary {
    public:
        // XXX default constructor disabled
        Summary() = delete;
        // XXX copy constructor disabled
        Summary(const Summary &other) = delete;
        // XXX copy assignment disabled
        Summary &operator=(const Summary &) = delete;

        Summary(std::vector<z3::expr> assumptions, std::map<std::string, z3::expr> hard_constraints);

        Summary(std::vector<z3::expr> assumptions, std::map<std::string, z3::expr> hard_constraints,
                std::vector<z3::expr> assumption_literals,
                std::map<std::string, std::vector<z3::expr>> assumption_literals_to_assumptions,
                std::map<std::string, std::map<std::string, z3::expr>> assumption_literals_to_hard_constraints);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const Summary &summary) {
            return summary.print(os);
        }

        // summaries are equal if they summarize the same path characterized by the assumptions along that path
        friend inline bool operator==(const Summary &summary_1, const Summary &summary_2) {
            const std::vector<z3::expr> &assumptions_1 = summary_1.getAssumptions();
            const std::vector<z3::expr> &assumptions_2 = summary_2.getAssumptions();
            if (assumptions_1.size() != assumptions_2.size()) {
                return false;
            }
            for (std::size_t i = 0; i < assumptions_1.size(); ++i) {
                if (assumptions_1.at(i).id() != assumptions_2.at(i).id()) {
                    return false;
                }
            }
            return true;
        }

        const std::vector<z3::expr> &getAssumptions() const;

        const std::map<std::string, z3::expr> &getHardConstraints() const;

        const std::vector<z3::expr> &getAssumptionLiterals() const;

    private:
        // Godefroid et al.
        // Assumptions on input and state variables
        std::vector<z3::expr> _assumptions;
        // Hard constraints, i.e., everything that is written during execution
        std::map<std::string, z3::expr> _hard_constraints;

        // ETFA
        // These members are used internally for the reuse within one version. It facilitates test case generation as
        // the paths are completely described by the assumption literals.
        std::vector<z3::expr> _assumption_literals;
        std::map<std::string, std::vector<z3::expr>> _assumption_literals_to_assumptions;
        std::map<std::string, std::map<std::string, z3::expr>> _assumption_literals_to_hard_constraints;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_SUMMARY_H
