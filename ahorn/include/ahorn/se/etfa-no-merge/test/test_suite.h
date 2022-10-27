#ifndef AHORN_ETFA_NO_MERGE_TEST_SUITE_H
#define AHORN_ETFA_NO_MERGE_TEST_SUITE_H

#include "se/etfa-no-merge/context/context.h"
#include "se/etfa-no-merge/test/test_case.h"
#include "se/etfa/z3/solver.h"

#include <memory>
#include <vector>

namespace se::etfa_no_merge {
    class TestSuite {
    private:
        friend class Engine;

    public:
        // XXX default constructor disabled
        TestSuite() = delete;
        // XXX copy constructor disabled
        TestSuite(const TestSuite &other) = delete;
        // XXX copy assignment disabled
        TestSuite &operator=(const TestSuite &) = delete;

        explicit TestSuite(se::etfa::Solver &solver);

        void deriveTestCase(const Context &context);

        void toXML(const std::string &path = std::string()) const;

        void fromXML(const std::string &path);

    private:
        void toXML(const TestCase &test_case, const std::string &path) const;

        std::unique_ptr<TestCase> buildFromXML(const std::string &path) const;

    private:
        se::etfa::Solver *const _solver;

        std::vector<std::unique_ptr<TestCase>> _test_cases;
    };
}// namespace se::etfa_no_merge

#endif//AHORN_ETFA_NO_MERGE_TEST_SUITE_H
