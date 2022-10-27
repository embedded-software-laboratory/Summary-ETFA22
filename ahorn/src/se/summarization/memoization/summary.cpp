#include "se/summarization/memoization/summary.h"

#include <sstream>

using namespace se::summarization;

Summary::Summary(std::vector<z3::expr> assumptions, std::map<std::string, z3::expr> hard_constraints)
    : _assumptions(std::move(assumptions)), _hard_constraints(std::move(hard_constraints)) {}

Summary::Summary(std::vector<z3::expr> assumptions, std::map<std::string, z3::expr> hard_constraints,
                 std::vector<z3::expr> assumption_literals,
                 std::map<std::string, std::vector<z3::expr>> assumption_literals_to_assumptions,
                 std::map<std::string, std::map<std::string, z3::expr>> assumption_literals_to_hard_constraints)
    : _assumptions(std::move(assumptions)), _hard_constraints(std::move(hard_constraints)),
      _assumption_literals(std::move(assumption_literals)),
      _assumption_literals_to_assumptions(std::move(assumption_literals_to_assumptions)),
      _assumption_literals_to_hard_constraints(std::move(assumption_literals_to_hard_constraints)) {}

std::ostream &Summary::print(std::ostream &os) const {
    std::stringstream str;
    str << "(\n";
    str << "\tassumptions: [";
    for (auto it = _assumptions.begin(); it != _assumptions.end(); ++it) {
        str << *it;
        if (std::next(it) != _assumptions.end()) {
            str << ", ";
        }
    }
    str << "]\n";
    str << "\thard constraints: [";
    for (auto it = _hard_constraints.begin(); it != _hard_constraints.end(); ++it) {
        str << it->first << " = " << it->second;
        if (std::next(it) != _hard_constraints.end()) {
            str << ", ";
        }
    }
    str << "]\n";
    if (!_assumption_literals.empty()) {
        str << "\tassumption literals: [";
        for (auto it = _assumption_literals.begin(); it != _assumption_literals.end(); ++it) {
            str << "\"" << *it << "\"";
            if (std::next(it) != _assumption_literals.end()) {
                str << ", ";
            }
        }
        str << "],\n";
    }
    if (!_assumption_literals_to_assumptions.empty()) {
        str << "\tassumption literals to assumptions: {";
        str << "\n";
        for (auto it = _assumption_literals_to_assumptions.begin(); it != _assumption_literals_to_assumptions.end();
             ++it) {
            str << "\t\t"
                << "\"" << it->first << "\""
                << ": [";
            for (auto assumption_literal_it = it->second.begin(); assumption_literal_it != it->second.end();
                 ++assumption_literal_it) {
                str << *assumption_literal_it;
                if (std::next(assumption_literal_it) != it->second.end()) {
                    str << ", ";
                }
            }
            str << "]";
            if (std::next(it) != _assumption_literals_to_assumptions.end()) {
                str << ",\n";
            }
        }
        str << "\n\t},\n";
    }
    if (!_assumption_literals_to_hard_constraints.empty()) {
        str << "\thard constraints: {";
        str << "\n";
        for (auto it = _assumption_literals_to_hard_constraints.begin();
             it != _assumption_literals_to_hard_constraints.end(); ++it) {
            str << "\t\t"
                << "\"" << it->first << "\""
                << ": [";
            for (auto valuation = it->second.begin(); valuation != it->second.end(); ++valuation) {
                str << valuation->first << " = " << valuation->second;
                if (std::next(valuation) != it->second.end()) {
                    str << ", ";
                }
            }
            str << "]";
            if (std::next(it) != _assumption_literals_to_hard_constraints.end()) {
                str << ",\n";
            }
        }
        str << "\n\t}\n";
    }
    str << ")";
    return os << str.str();
}

const std::vector<z3::expr> &Summary::getAssumptions() const {
    return _assumptions;
}

const std::map<std::string, z3::expr> &Summary::getHardConstraints() const {
    return _hard_constraints;
}

const std::vector<z3::expr> &Summary::getAssumptionLiterals() const {
    return _assumption_literals;
}