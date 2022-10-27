#include "se/summarization/context/context.h"

using namespace se::summarization;

Context::Context(std::unique_ptr<State> state, std::deque<std::shared_ptr<Frame>> call_stack)
    : _state(std::move(state)), _call_stack(std::move(call_stack)) {}

std::ostream &Context::print(std::ostream &os) const {
    std::stringstream str;
    str << "(\n";
    str << "\tstate: " << *_state << "\n";
    str << "\tcall stack: ";
    str << "[";
    for (auto frame = _call_stack.begin(); frame != _call_stack.end(); ++frame) {
        str << **frame;
        if (std::next(frame) != _call_stack.end()) {
            str << ", ";
        }
    }
    str << "]\n";
    str << ")";
    return os << str.str();
}

State &Context::getState() const {
    return *_state;
}

Frame &Context::getFrame() const {
    assert(!_call_stack.empty());
    return *_call_stack.back();
}

std::unique_ptr<Context> Context::fork(const Vertex &vertex) const {
    std::unique_ptr<State> state = _state->fork(vertex);
    return std::make_unique<Context>(std::move(state), _call_stack);
}
