#ifndef AHORN_SUMMARIZATION_ENGINE_H
#define AHORN_SUMMARIZATION_ENGINE_H

#include "cfg/cfg.h"
#include "se/etfa/z3/solver.h"
#include "se/summarization/execution/executor.h"
#include "se/summarization/exploration/explorer.h"

#include <chrono>
#include <memory>

namespace se::summarization {
    class Engine {
    public:
        // XXX default constructor disabled
        Engine() = delete;
        // XXX copy constructor disabled
        Engine(const Engine &other) = delete;
        // XXX copy assignment disabled
        Engine &operator=(const Engine &) = delete;

        explicit Engine(etfa::Solver &solver);

        void run(const Cfg &cfg);

        Summarizer &getSummarizer() const;

    private:
        void initialize(const Cfg &cfg);

        void step();

    private:
        etfa::Solver *const _solver;
        std::unique_ptr<Executor> _executor;
        std::unique_ptr<Explorer> _explorer;
        std::chrono::time_point<std::chrono::system_clock> _begin_time_point;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_ENGINE_H
