#ifndef AHORN_ETFA_NO_MERGE_EXPLORER_H
#define AHORN_ETFA_NO_MERGE_EXPLORER_H

#include "cfg/cfg.h"
#include "se/etfa-no-merge/context/context.h"
#include "se/summarization/memoization/summarizer.h"

#include <map>
#include <memory>
#include <set>
#include <vector>

namespace se::etfa_no_merge {
    class Explorer {
    private:
        friend class Engine;

    public:
        Explorer();
        // XXX copy constructor disabled
        Explorer(const Explorer &other) = delete;
        // XXX copy assignment disabled
        Explorer &operator=(const Explorer &) = delete;

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const Explorer &explorer) {
            return explorer.print(os);
        }

        bool isEmpty() const;

        void push(std::unique_ptr<Context> context);

        std::unique_ptr<Context> pop();

        std::pair<bool, bool> updateCoverage(unsigned int label, const Context &context);

        std::pair<bool, bool> updateCoverage(const Cfg &cfg, unsigned int label, unsigned int succeeding_label);

    private:
        void initialize(const Cfg &cfg);

        void initializeCoverage(const Cfg &cfg, std::set<std::string> &visited_cfgs);

    private:
        std::vector<std::unique_ptr<Context>> _contexts;
        double _statement_coverage;
        std::map<unsigned int, bool> _covered_statements;
        double _branch_coverage;
        std::map<unsigned int, std::pair<bool, bool>> _covered_branches;
    };
}// namespace se::etfa_no_merge

#endif//AHORN_ETFA_NO_MERGE_EXPLORER_H
