#ifndef AHORN_SUMMARIZATION_EXPLORER_H
#define AHORN_SUMMARIZATION_EXPLORER_H

#include "se/summarization/context/context.h"

#include <memory>
#include <vector>

namespace se::summarization {
    class Explorer {
    public:
        Explorer();

        bool isEmpty() const;

        void push(std::unique_ptr<Context> context);

        std::unique_ptr<Context> pop();

    private:
        std::vector<std::unique_ptr<Context>> _contexts;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_EXPLORER_H
