#ifndef AHORN_SUMMARIZATIONEXECUTOR_H
#define AHORN_SUMMARIZATIONEXECUTOR_H

#include "ir/instruction/instruction_visitor.h"
#include "se/etfa/z3/solver.h"
#include "se/summarization/context/context.h"
#include "se/summarization/execution/encoder.h"
#include "se/summarization/memoization/summarizer.h"

#include "boost/optional.hpp"

#include <memory>

namespace se::summarization {
    class Executor : private ir::InstructionVisitor {
    private:
        friend class Engine;

    public:
        explicit Executor(etfa::Solver &solver);

        std::vector<std::unique_ptr<Context>> execute(std::unique_ptr<Context> context);

    private:
        void initialize(const Cfg &cfg);

        std::vector<std::unique_ptr<Context>> handleRegularVertex(const Vertex &vertex,
                                                                  std::unique_ptr<Context> context);

        void handleIntermediateDecisionVertex(const Vertex &vertex);

    private:
        void visit(const ir::AssignmentInstruction &instruction) override;
        void visit(const ir::CallInstruction &instruction) override;
        void visit(const ir::IfInstruction &instruction) override;
        void visit(const ir::SequenceInstruction &instruction) override;
        void visit(const ir::WhileInstruction &instruction) override;
        void visit(const ir::GotoInstruction &instruction) override;
        void visit(const ir::HavocInstruction &instruction) override;

    private:
        etfa::Solver *const _solver;
        std::unique_ptr<Encoder> _encoder;
        std::unique_ptr<Summarizer> _summarizer;
        // "Globally" managed variable versioning for implicit SSA-form
        std::map<std::string, unsigned int> _flattened_name_to_version;
        std::unique_ptr<Context> _context;
        boost::optional<std::unique_ptr<Context>> _forked_context;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATIONEXECUTOR_H
