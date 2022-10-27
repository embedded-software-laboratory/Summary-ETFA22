#include "se/reuse/context/state.h"

#include <sstream>

using namespace se::reuse;

State::State(const Vertex &vertex, z3::expr assumption_literal,
             std::map<std::string, std::vector<z3::expr>> assumption_literals,
             std::map<std::string, std::vector<z3::expr>> assumptions,
             std::map<std::string, std::map<std::string, z3::expr>> hard_constraints,
             std::map<std::string, unsigned int> flattened_name_to_version)
    : _vertex(&vertex), _assumption_literal(std::move(assumption_literal)),
      _assumption_literals(std::move(assumption_literals)), _assumptions(std::move(assumptions)),
      _hard_constraints(std::move(hard_constraints)), _flattened_name_to_version(std::move(flattened_name_to_version)) {
}

std::ostream &State::print(std::ostream &os) const {
    std::stringstream str;
    str << "(\n";
    str << "\t\tvertex: " << *_vertex << ",\n";
    str << "\t\tassumption literal: " << _assumption_literal << ",\n";
    str << "\t\tassumption literals: {\n";
    for (auto it = _assumption_literals.begin(); it != _assumption_literals.end(); ++it) {
        str << "\t\t\t"
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
        if (std::next(it) != _assumption_literals.end()) {
            str << ",\n";
        }
    }
    str << "\n\t\t},\n";
    str << "\t\tassumptions: {";
    if (_assumptions.empty()) {
        str << "},\n";
    } else {
        str << "\n";
        for (auto it = _assumptions.begin(); it != _assumptions.end(); ++it) {
            str << "\t\t\t"
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
            if (std::next(it) != _assumptions.end()) {
                str << ",\n";
            }
        }
        str << "\n\t\t},\n";
    }
    str << "\t\thard constraints: {";
    if (_hard_constraints.empty()) {
        str << "}\n";
    } else {
        str << "\n";
        for (auto it = _hard_constraints.begin(); it != _hard_constraints.end(); ++it) {
            str << "\t\t\t"
                << "\"" << it->first << "\""
                << ": [";
            for (auto valuation = it->second.begin(); valuation != it->second.end(); ++valuation) {
                str << valuation->first << " = " << valuation->second;
                if (std::next(valuation) != it->second.end()) {
                    str << ", ";
                }
            }
            str << "]";
            if (std::next(it) != _hard_constraints.end()) {
                str << ",\n";
            }
        }
        str << "\n\t\t}\n";
    }
    str << "\t)";
    return os << str.str();
}

const Vertex &State::getVertex() const {
    return *_vertex;
}

void State::setVertex(const Vertex &vertex) {
    _vertex = &vertex;
}

z3::expr State::getAssumptionLiteral() const {
    return _assumption_literal;
}

void State::setAssumptionLiteral(const z3::expr &assumption_literal) {
    _assumption_literal = assumption_literal;
}

const std::map<std::string, std::vector<z3::expr>> &State::getAssumptionLiterals() const {
    return _assumption_literals;
}

const std::vector<z3::expr> &State::getAssumptionLiterals(const std::string &assumption_literal_name) const {
    assert(_assumption_literals.find(assumption_literal_name) != _assumption_literals.end());
    return _assumption_literals.at(assumption_literal_name);
}

void State::pushAssumptionLiteral(const std::string &assumption_literal_name, const z3::expr &assumption_literal) {
    auto it = _assumption_literals.find(assumption_literal_name);
    if (it == _assumption_literals.end()) {
        _assumption_literals.emplace(assumption_literal_name, std::vector<z3::expr>{assumption_literal});
    } else {
        // XXX check if assumption literal already exists, if yes, do not add it (prevents duplicates)
        if (std::find_if(_assumption_literals.at(assumption_literal_name).begin(),
                         _assumption_literals.at(assumption_literal_name).end(),
                         [assumption_literal](const auto &existing_assumption_literal) {
                             return z3::eq(assumption_literal, existing_assumption_literal);
                         }) == _assumption_literals.at(assumption_literal_name).end()) {
            it->second.push_back(assumption_literal);
        }
    }
}

const std::map<std::string, unsigned int> &State::getLocalVersioning() const {
    return _flattened_name_to_version;
}

unsigned int State::getVersion(const std::string &flattened_name) const {
    return _flattened_name_to_version.at(flattened_name);
}

void State::setVersion(const std::string &flattened_name, unsigned int version) {
    assert(_flattened_name_to_version.find(flattened_name) != _flattened_name_to_version.end());
    _flattened_name_to_version.at(flattened_name) = version;
}

const std::map<std::string, std::vector<z3::expr>> &State::getAssumptions() const {
    return _assumptions;
}

void State::pushAssumption(const std::string &assumption_literal_name, const z3::expr &assumption) {
    auto it = _assumptions.find(assumption_literal_name);
    if (it == _assumptions.end()) {
        _assumptions.emplace(assumption_literal_name, std::vector<z3::expr>{assumption});
    } else {
        it->second.push_back(assumption);
    }
}

const std::map<std::string, std::map<std::string, z3::expr>> &State::getHardConstraints() const {
    return _hard_constraints;
}

void State::pushHardConstraint(const std::string &assumption_literal_name, const std::string &contextualized_name,
                               const z3::expr &expression) {
    auto it = _hard_constraints.find(assumption_literal_name);
    if (it == _hard_constraints.end()) {
        _hard_constraints.emplace(assumption_literal_name,
                                  std::map<std::string, z3::expr>{std::make_pair(contextualized_name, expression)});
    } else {
        it->second.emplace(contextualized_name, expression);
    }
}

std::unique_ptr<State> State::fork(const Vertex &vertex) const {
    return std::make_unique<State>(vertex, _assumption_literal, _assumption_literals, _assumptions, _hard_constraints,
                                   _flattened_name_to_version);
}