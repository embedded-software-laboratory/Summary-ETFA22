#ifndef AHORN_REUSE_CONTEXT_H
#define AHORN_REUSE_CONTEXT_H

#include "se/reuse/context/frame.h"
#include "se/reuse/context/state.h"

#include <deque>
#include <memory>

namespace se::reuse {
    class Context {
    public:
        // XXX default constructor disabled
        Context() = delete;
        // XXX copy constructor disabled
        Context(const Context &other) = delete;
        // XXX copy assignment disabled
        Context &operator=(const Context &) = delete;

        Context(std::unique_ptr<State> state, std::deque<std::shared_ptr<Frame>> call_stack);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const Context &context) {
            return context.print(os);
        }

        State &getState() const;

        Frame &getMainFrame() const;

        Frame &getFrame() const;

        const std::deque<std::shared_ptr<Frame>> &getCallStack() const;

        unsigned int getCallStackDepth() const;

        void setEncoded(bool encoded);

        bool getEncoded() const;

        std::unique_ptr<Context> fork(const Vertex &vertex) const;

    private:
        std::unique_ptr<State> _state;
        std::deque<std::shared_ptr<Frame>> _call_stack;
        bool _encoded;
    };
}// namespace se::reuse

#endif//AHORN_REUSE_CONTEXT_H
