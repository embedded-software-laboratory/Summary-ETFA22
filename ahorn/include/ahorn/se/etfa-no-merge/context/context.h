#ifndef AHORN_ETFA_NO_MERGE_CONTEXT_H
#define AHORN_ETFA_NO_MERGE_CONTEXT_H

#include "se/etfa-no-merge/context/frame.h"
#include "se/etfa-no-merge/context/state.h"

#include <deque>
#include <memory>

namespace se::etfa_no_merge {
    class Context {
    public:
        // XXX default constructor disabled
        Context() = delete;
        // XXX copy constructor disabled
        Context(const Context &other) = delete;
        // XXX copy assignment disabled
        Context &operator=(const Context &) = delete;

        Context(unsigned int cycle, std::unique_ptr<State> state, std::deque<std::shared_ptr<Frame>> call_stack);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const Context &context) {
            return context.print(os);
        }

        unsigned int getCycle() const;

        void setCycle(unsigned int cycle);

        State &getState() const;

        Frame &getFrame() const;

        const Frame &getMainFrame() const;

        void pushFrame(std::shared_ptr<Frame> frame);

        void popFrame();

        const std::deque<std::shared_ptr<Frame>> &getCallStack() const;

        unsigned int getCallStackDepth() const;

        std::unique_ptr<Context> fork(const Vertex &vertex, const z3::expr &expression, z3::model &model) const;

        std::unique_ptr<Context> clone() const;

    private:
        unsigned int _cycle;
        std::unique_ptr<State> _state;
        std::deque<std::shared_ptr<Frame>> _call_stack;
    };
}// namespace se::etfa_no_merge

#endif//AHORN_ETFA_CONTEXT_H
