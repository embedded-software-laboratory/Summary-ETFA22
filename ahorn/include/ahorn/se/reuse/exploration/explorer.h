#ifndef AHORN_REUSE_EXPLORER_H
#define AHORN_REUSE_EXPLORER_H

#include "se/reuse/context/context.h"

#include <memory>
#include <vector>

namespace se::reuse {
    class Explorer {
    private:
        friend class Engine;

    public:
        Explorer();

        bool isEmpty() const;

        void push(std::unique_ptr<Context> context);

        std::unique_ptr<Context> pop();

    private:
        void initialize();

    private:
        std::vector<std::unique_ptr<Context>> _contexts;
    };
}// namespace se::reuse

#endif//AHORN_REUSE_EXPLORER_H
