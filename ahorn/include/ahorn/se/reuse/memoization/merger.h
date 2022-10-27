#ifndef AHORN_REUSE_MERGER_H
#define AHORN_REUSE_MERGER_H

#include "cfg/cfg.h"
#include "se/etfa/z3/solver.h"
#include "se/reuse/context/context.h"
#include "se/reuse/execution/executor.h"

#include <map>
#include <set>
#include <vector>

namespace se::reuse {
    class Merger {
    private:
        friend class Engine;

    public:
        // XXX default constructor disabled
        Merger() = delete;
        // XXX copy constructor disabled
        Merger(const Merger &other) = delete;
        // XXX copy assignment disabled
        Merger &operator=(const Merger &) = delete;

        Merger(etfa::Solver &solver, Executor &executor);

        bool isEmpty() const;

        bool reachedMergePoint(const Context &context) const;

        void push(std::unique_ptr<Context> context);

        std::unique_ptr<Context> merge();

    private:
        void initialize(const Cfg &cfg);

        void initializeMergePoints(const Cfg &cfg, const std::string &scope, unsigned int depth,
                                   unsigned int return_label, std::set<std::string> &visited_cfgs);

        std::unique_ptr<Context> merge(std::unique_ptr<Context> context_1, std::unique_ptr<Context> context_2);

        void mergeVariable(const std::string &merged_contextualized_name, const Context &context,
                           const std::string &flattened_name, const std::string &contextualized_name_to_merge,
                           std::map<std::string, std::map<std::string, z3::expr>> &modified_variable_instances);

    private:
        etfa::Solver *const _solver;
        Executor *const _executor;
        // enforce only realizable paths, i.e., merge point consists of scope, depth, label, and return label
        using merge_point_t = std::tuple<std::string, unsigned int, unsigned int, unsigned int>;
        std::set<merge_point_t> _merge_points;
        std::map<merge_point_t, std::vector<std::unique_ptr<Context>>> _merge_point_to_contexts;
    };
}// namespace se::reuse

#endif//AHORN_REUSE_MERGER_H
