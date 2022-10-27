#include "se/reuse/exploration/explorer.h"
#include "se/reuse/exploration/heuristic/depth_first_heuristic.h"

using namespace se::reuse;

Explorer::Explorer() : _contexts(std::vector<std::unique_ptr<Context>>()) {}

bool Explorer::isEmpty() const {
    return _contexts.empty();
}

void Explorer::push(std::unique_ptr<Context> context) {
    _contexts.push_back(std::move(context));
    std::push_heap(_contexts.begin(), _contexts.end(), DepthFirstHeuristic());
}

std::unique_ptr<Context> Explorer::pop() {
    std::pop_heap(_contexts.begin(), _contexts.end(), DepthFirstHeuristic());
    std::unique_ptr<Context> context = std::move(_contexts.back());
    _contexts.pop_back();
    return context;
}

void Explorer::initialize() {
    _contexts.clear();
}