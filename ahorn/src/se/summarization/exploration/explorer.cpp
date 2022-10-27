#include "se/summarization/exploration/explorer.h"

using namespace se::summarization;

Explorer::Explorer() : _contexts(std::vector<std::unique_ptr<Context>>()) {}

bool Explorer::isEmpty() const {
    return _contexts.empty();
}

void Explorer::push(std::unique_ptr<Context> context) {
    _contexts.push_back(std::move(context));
}

std::unique_ptr<Context> Explorer::pop() {
    std::unique_ptr<Context> context = std::move(_contexts.back());
    _contexts.pop_back();
    return context;
}