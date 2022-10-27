#ifndef AHORN_SUMMARIZATION_ENCODER_H
#define AHORN_SUMMARIZATION_ENCODER_H

#include "ir/expression/expression_visitor.h"
#include "se/etfa/z3/solver.h"
#include "se/summarization/context/context.h"

#include "z3++.h"

#include <stack>

namespace se::summarization {
    class Encoder : private ir::ExpressionVisitor {
    public:
        // XXX default constructor disabled
        Encoder() = delete;
        // XXX copy constructor disabled
        Encoder(const Encoder &other) = delete;
        // XXX copy assignment disabled
        Encoder &operator=(const Encoder &) = delete;

        explicit Encoder(etfa::Solver &solver);

        z3::expr encode(const ir::Expression &expression, const Context &context);

    private:
        void visit(const ir::BinaryExpression &expression) override;
        void visit(const ir::BooleanToIntegerCast &expression) override;
        void visit(const ir::ChangeExpression &expression) override;
        void visit(const ir::UnaryExpression &expression) override;
        void visit(const ir::BooleanConstant &expression) override;
        void visit(const ir::IntegerConstant &expression) override;
        void visit(const ir::TimeConstant &expression) override;
        void visit(const ir::EnumeratedValue &expression) override;
        void visit(const ir::NondeterministicConstant &expression) override;
        void visit(const ir::Undefined &expression) override;
        void visit(const ir::VariableAccess &expression) override;
        void visit(const ir::FieldAccess &expression) override;
        void visit(const ir::IntegerToBooleanCast &expression) override;
        void visit(const ir::Phi &expression) override;

    private:
        etfa::Solver *const _solver;
        const Context *_context;
        std::stack<z3::expr> _expression_stack;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_ENCODER_H
