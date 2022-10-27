#ifndef AHORN_ETFA_ENGINE_H
#define AHORN_ETFA_ENGINE_H

#include <gtest/gtest_prod.h>

#include "cfg/cfg.h"
#include "se/configuration.h"
#include "se/etfa/execution/executor.h"
#include "se/etfa/exploration/explorer.h"
#include "se/etfa/memoization/merger.h"
#include "se/etfa/test/test_suite.h"
#include "se/etfa/z3/solver.h"
#include "se/summarization/memoization/summarizer.h"

#include "boost/optional.hpp"

#include <chrono>
#include <memory>

class TestLibSeETFA_EmergencyStopTest_Test;

namespace se::etfa {
    class Engine {
    private:
        FRIEND_TEST(::TestLibSeETFA, EmergencyStopTest);

    public:
        explicit Engine(std::unique_ptr<Configuration> configuration);

        Solver &getSolver() const;

        void run(summarization::Summarizer &summarizer, const Cfg &cfg);

    private:
        enum TerminationCriteria { TIME_OUT = 1 << 0, CYCLE_BOUND = 1 << 1, COVERAGE = 1 << 2 };

        friend inline TerminationCriteria operator|(TerminationCriteria tc1, TerminationCriteria tc2) {
            return static_cast<TerminationCriteria>(static_cast<int>(tc1) | static_cast<int>(tc2));
        }

        void initialize(summarization::Summarizer &summarizer, const Cfg &cfg);

        bool isTerminationCriteriaMet() const;

        boost::optional<TerminationCriteria> isLocalTerminationCriteriaMet() const;

        bool isTimeOut() const;

        std::pair<std::unique_ptr<Context>, boost::optional<TerminationCriteria>> step();

    private:
        std::unique_ptr<Configuration> _configuration;
        TerminationCriteria _termination_criteria;
        long _time_out = 10000;
        unsigned int _cycle;
        unsigned int _cycle_bound = 5;
        std::unique_ptr<Solver> _solver;
        std::unique_ptr<TestSuite> _test_suite;
        std::unique_ptr<Explorer> _explorer;
        std::unique_ptr<Executor> _executor;
        std::unique_ptr<Merger> _merger;

        std::chrono::time_point<std::chrono::system_clock> _begin_time_point;
    };
}// namespace se::etfa

#endif//AHORN_ETFA_ENGINE_H
