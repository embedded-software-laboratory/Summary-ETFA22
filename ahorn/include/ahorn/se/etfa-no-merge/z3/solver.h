#ifndef AHORN_ETFA_NO_MERGE_SOLVER_H
#define AHORN_ETFA_NO_MERGE_SOLVER_H

#include "ir/expression/constant/constant.h"
#include "ir/type/data_type.h"

#include "boost/optional.hpp"

#include "z3++.h"

#include <memory>
#include <map>
#include <vector>

namespace se::etfa_no_merge {
    class Solver {
    public:
        Solver();
        // XXX copy constructor disabled
        Solver(const Solver &other) = delete;
        // XXX copy assignment disabled
        Solver &operator=(const Solver &) = delete;

        z3::context &getContext();

        z3::expr makeBooleanValue(bool value);

        z3::expr makeIntegerValue(int value);

        z3::expr makeDefaultValue(const ir::DataType &data_type);

        z3::expr makeValue(const ir::Constant &constant);

        z3::expr makeBooleanConstant(const std::string &contextualized_name);

        z3::expr makeIntegerConstant(const std::string &contextualized_name);

        z3::expr makeConstant(const std::string &contextualized_name, const ir::DataType &data_type);

        std::pair<z3::check_result, boost::optional<z3::model>> check(const z3::expr_vector &expressions);

        std::pair<z3::check_result, boost::optional<z3::model>>
        checkUnderAssumptions(const z3::expr_vector &expressions, const z3::expr_vector &assumptions);

        std::vector<z3::expr> getUninterpretedConstants(const z3::expr &expression);

    private:
        // https://github.com/Z3Prover/z3/blob/master/examples/c%2B%2B/example.cpp#L805
        void visit(std::vector<bool> &visited, std::vector<z3::expr> &uninterpreted_constants,
                   const z3::expr &expression) const;

    private:
        std::unique_ptr<z3::context> _context;
        std::map<unsigned int, std::vector<z3::expr>> _id_to_uninterpreted_constants;
    };
}// namespace se::etfa_no_merge

#endif//AHORN_ETFA_NO_MERGE_SOLVER_H
