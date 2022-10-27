#ifndef AHORN_ETFA_EXECUTOR_H
#define AHORN_ETFA_EXECUTOR_H

#include "cfg/cfg.h"
#include "ir/instruction/instruction_visitor.h"
#include "se/etfa/context/context.h"
#include "se/etfa/execution/encoder.h"
#include "se/etfa/exploration/explorer.h"
#include "se/etfa/test/test_suite.h"
#include "se/etfa/z3/solver.h"
#include "se/summarization/memoization/summarizer.h"

#include "boost/optional.hpp"

#include <memory>
#include <set>

namespace se::etfa {
    class Executor : private ir::InstructionVisitor {
    private:
        friend class Engine;

    public:
        // XXX default constructor disabled
        Executor() = delete;
        // XXX copy constructor disabled
        Executor(const Executor &other) = delete;
        // XXX copy assignment disabled
        Executor &operator=(const Executor &) = delete;

        Executor(Solver &solver, Explorer &explorer, TestSuite &test_suite);

        unsigned int getVersion(const std::string &flattened_name) const;

        void setVersion(const std::string &flattened_name, unsigned int version);

        bool isWholeProgramInput(const std::string &flattened_name) const;

        std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>>
        execute(std::unique_ptr<Context> context);

    private:
        void initialize(summarization::Summarizer &summarizer, const Cfg &cfg);

        void handleProgramEntryVertex(const Cfg &cfg, const Vertex &vertex, State &state);
        void handleFunctionBlockEntryVertex(const Frame &frame, const Context &context, State &state);
        void handleFunctionEntryVertex();
        std::pair<std::vector<std::unique_ptr<Context>>, boost::optional<std::unique_ptr<Context>>>
        handleRegularVertex(const Vertex &vertex, std::unique_ptr<Context> context);
        void handleIntermediateDecisionVertex(const Vertex &vertex);
        void handleProgramExitVertex(Frame &frame, Context &context, State &state);
        void handleFunctionBlockExitVertex(const Frame &frame, Context &context, State &state);
        void handleFunctionExitVertex();

    private:
        void visit(const ir::AssignmentInstruction &instruction) override;
        void visit(const ir::CallInstruction &instruction) override;
        void visit(const ir::IfInstruction &instruction) override;
        void visit(const ir::SequenceInstruction &instruction) override;
        void visit(const ir::WhileInstruction &instruction) override;
        void visit(const ir::GotoInstruction &instruction) override;
        void visit(const ir::HavocInstruction &instruction) override;

    private:
        bool containsUnconstrainedUninterpretedConstant(const State &state, const z3::expr &expression) const;

        void applySummary(const summarization::Summary &summary, Context &context);

    private:
        long _summary_application_checking_time;
        Solver *const _solver;
        Explorer *const _explorer;
        TestSuite *const _test_suite;
        std::unique_ptr<Encoder> _encoder;
        summarization::Summarizer *_summarizer;
        // "Globally" managed variable versioning for implicit SSA-form
        std::map<std::string, unsigned int> _flattened_name_to_version;
        std::set<std::string> _whole_program_inputs;
        std::unique_ptr<Context> _context;
        boost::optional<std::unique_ptr<Context>> _forked_context;
        std::vector<std::unique_ptr<Context>> _summarized_contexts;
    };
}// namespace se::etfa

#endif//AHORN_ETFA_EXECUTOR_H
