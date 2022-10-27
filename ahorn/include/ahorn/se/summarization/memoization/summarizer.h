#ifndef AHORN_SUMMARIZATION_SUMMARIZER_H
#define AHORN_SUMMARIZATION_SUMMARIZER_H

#include "se/etfa-no-merge/context/context.h"
#include "se/etfa/context/context.h"
#include "se/etfa/context/state.h"
#include "se/etfa/z3/solver.h"
#include "se/reuse/context/context.h"
#include "se/summarization/context/context.h"
#include "se/summarization/memoization/summary.h"

#include "boost/optional.hpp"

#include <memory>
#include <vector>

namespace se::summarization {
    class Summarizer {
    private:
        friend class Engine;

    public:
        // XXX default constructor disabled
        Summarizer() = delete;
        // XXX copy constructor disabled
        Summarizer(const Summarizer &other) = delete;
        // XXX copy assignment disabled
        Summarizer &operator=(const Summarizer &) = delete;

        explicit Summarizer(etfa::Solver &solver);

        Summarizer(etfa::Solver &solver,
                   std::map<std::string, std::vector<std::shared_ptr<Summary>>> name_to_summaries);

        const std::map<std::string, std::vector<std::shared_ptr<Summary>>> &getSummaries() const;

        const std::vector<std::shared_ptr<Summary>> &getSummaries(const std::string &name) const;

        std::vector<Summary *> findApplicableSummary(const etfa::Context &context);

        std::vector<std::pair<std::shared_ptr<Summary>, z3::model>>
        findConcretelyApplicableSummaries(const etfa_no_merge::Context &context);

        std::pair<bool, boost::optional<z3::model>> isSymbolicallyApplicable(const std::shared_ptr<Summary> &summary,
                                                                             const etfa_no_merge::Context &context);

        void summarizePath(const Context &context);

        std::unique_ptr<Summary> summarizePath(const se::reuse::Context &context,
                                               const std::vector<z3::expr> &path) const;

        std::vector<z3::expr> flattenAssumptionLiterals(const se::reuse::Context &context) const;

    private:
        void extractNecessaryHardConstraints(std::set<std::string> &necessary_hard_constraints,
                                             const etfa::State &state, const z3::expr &expression) const;

        std::pair<bool, boost::optional<std::set<unsigned int>>>
        isSummaryApplicable(const Summary &summary, const std::map<std::string, z3::expr> &symbolic_valuations,
                            const std::vector<z3::expr> &path_constraint);

        bool isSummaryApplicableViaEvaluation(const Summary &summary, const etfa::Context &context);

        z3::expr lowerExpressionForEvaluation(const Summary &summary, const z3::expr &expression) const;

        std::vector<Summary *> getApplicableSummaries(const std::map<std::string, z3::expr> &symbolic_valuations,
                                                      const std::vector<std::shared_ptr<Summary>> &summaries);

        std::string decontextualize(const std::string &contextualized_name) const;

        std::vector<z3::expr> flattenAssumptionLiterals(const Context &context) const;

    private:
        etfa::Solver *const _solver;
        std::map<std::string, std::vector<std::shared_ptr<Summary>>> _name_to_summaries;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_SUMMARIZER_H
