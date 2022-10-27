#ifndef AHORN_REUSE_EXECUTOR_H
#define AHORN_REUSE_EXECUTOR_H

#include "cfg/cfg.h"
#include "ir/instruction/instruction_visitor.h"
#include "se/etfa/z3/solver.h"
#include "se/reuse/execution/encoder.h"

#include <map>
#include <memory>

namespace se::reuse {
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

        explicit Executor(etfa::Solver &solver);

        unsigned int getVersion(const std::string &flattened_name) const;

        void setVersion(const std::string &flattened_name, unsigned int version);

        std::pair<std::unique_ptr<Context>, boost::optional<std::unique_ptr<Context>>>
        execute(std::unique_ptr<Context> context, bool old);

    private:
        void initialize(const Cfg &cfg);

        std::pair<std::unique_ptr<Context>, boost::optional<std::unique_ptr<Context>>>
        handleRegularVertex(const Vertex &vertex, std::unique_ptr<Context> context);

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
        bool _old;
        etfa::Solver *const _solver;
        std::unique_ptr<Encoder> _encoder;
        // "Globally" managed variable versioning for implicit SSA-form
        std::map<std::string, unsigned int> _flattened_name_to_version;
        std::unique_ptr<Context> _context;
        boost::optional<std::unique_ptr<Context>> _forked_context;
    };
}// namespace se::reuse

#endif//AHORN_REUSE_EXECUTOR_H
