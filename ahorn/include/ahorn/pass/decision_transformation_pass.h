#ifndef AHORN_DECISION_TRANSFORMATION_PASS_H
#define AHORN_DECISION_TRANSFORMATION_PASS_H

#include "cfg/cfg.h"

#include <map>
#include <memory>

namespace pass {
    class DecisionTransformationPass {
    public:
        DecisionTransformationPass();

        std::shared_ptr<Cfg> apply(const Cfg &cfg);

    private:
        unsigned int _label;
        std::map<unsigned int, std::pair<unsigned int, unsigned int>> _decision_label_to_intermediate_successors;
    };
}// namespace pass

#endif//AHORN_DECISION_TRANSFORMATION_PASS_H
