#ifndef AHORN_SUMMARIZATION_CONTEXT_H
#define AHORN_SUMMARIZATION_CONTEXT_H

#include "se/summarization/context/frame.h"
#include "se/summarization/context/state.h"

#include <memory>
#include <deque>

namespace se::summarization {
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

        Frame &getFrame() const;

        std::unique_ptr<Context> fork(const Vertex &vertex) const;

    private:
        std::unique_ptr<State> _state;
        std::deque<std::shared_ptr<Frame>> _call_stack;
    };
}// namespace se::summarization

#endif//AHORN_SUMMARIZATION_CONTEXT_H
