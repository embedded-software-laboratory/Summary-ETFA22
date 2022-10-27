#ifndef AHORN_REUSE_ENGINE_H
#define AHORN_REUSE_ENGINE_H

#include "cfg/cfg.h"
#include "ir/instruction/call_instruction.h"
#include "se/etfa/z3/solver.h"
#include "se/reuse/execution/executor.h"
#include "se/reuse/exploration/explorer.h"
#include "se/reuse/memoization/merger.h"
#include "se/summarization/memoization/summarizer.h"
#include "se/summarization/memoization/summary.h"

#include <chrono>
#include <memory>
#include <set>

namespace se::reuse {
    class Engine {
    public:
        // XXX default constructor disabled
        Engine() = delete;
        // XXX copy constructor disabled
        Engine(const Engine &other) = delete;
        // XXX copy assignment disabled
        Engine &operator=(const Engine &) = delete;

        explicit Engine(etfa::Solver &solver);

        std::shared_ptr<se::summarization::Summarizer> run(const Cfg &cfg, summarization::Summarizer &summarizer);

    private:
        std::set<unsigned int> getChangeAnnotatedLabels(const Cfg &cfg);

        std::unique_ptr<Context> getInitialContext(const Cfg &cfg, unsigned int label,
                                                   const ir::CallInstruction &instruction);

        bool predicateSensitiveAnalysis(const Context &context, const std::set<unsigned int> &change_annotated_labels,
                                        const summarization::Summary &summary);

        bool validityCheck(const Context &context, const summarization::Summary &summary);

        std::unique_ptr<Context> generateVerificationConditions(std::unique_ptr<Context> context, bool old);

        std::unique_ptr<Context> step(bool old);

        z3::expr lowerExpression(const summarization::Summary &summary, const z3::expr &expression) const;

        std::vector<std::vector<z3::expr>> determineAssumptionLiteralPaths(const Context &context) const;

        std::vector<std::vector<z3::expr>>
        determinePathCandidates(const Context &context,
                                const std::vector<z3::expr> &uncovered_assumption_literals) const;

    private:
        etfa::Solver *const _solver;
        std::unique_ptr<Executor> _executor;
        std::unique_ptr<Explorer> _explorer;
        std::unique_ptr<Merger> _merger;

        std::chrono::time_point<std::chrono::system_clock> _begin_time_point;
    };
}// namespace se::reuse

#endif//AHORN_REUSE_ENGINE_H
