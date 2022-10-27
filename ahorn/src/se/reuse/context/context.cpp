#include "se/reuse/context/context.h"

using namespace se::reuse;

Context::Context(std::unique_ptr<State> state, std::deque<std::shared_ptr<Frame>> call_stack)
    : _state(std::move(state)), _call_stack(std::move(call_stack)), _encoded(false) {}

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

Frame &Context::getMainFrame() const {
    assert(!_call_stack.empty());
    return *_call_stack.front();
}

Frame &Context::getFrame() const {
    assert(!_call_stack.empty());
    return *_call_stack.back();
}

const std::deque<std::shared_ptr<Frame>> &Context::getCallStack() const {
    return _call_stack;
}

unsigned int Context::getCallStackDepth() const {
    return _call_stack.size();
}

void Context::setEncoded(bool encoded) {
    _encoded = encoded;
}

bool Context::getEncoded() const {
    return _encoded;
}

std::unique_ptr<Context> Context::fork(const Vertex &vertex) const {
    std::unique_ptr<State> state = _state->fork(vertex);
    return std::make_unique<Context>(std::move(state), _call_stack);
}