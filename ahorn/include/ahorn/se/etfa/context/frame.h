#ifndef AHORN_ETFA_FRAME_H
#define AHORN_ETFA_FRAME_H

#include "cfg/cfg.h"

#include "z3++.h"

namespace se::etfa {
    class Frame {
    private:
        friend class Executor;

    public:
        // XXX default constructor disabled
        Frame() = delete;
        // XXX copy constructor disabled
        Frame(const Frame &other) = delete;
        // XXX copy assignment disabled
        Frame &operator=(const Frame &) = delete;

        Frame(const Cfg &cfg, std::string scope, unsigned int return_label);

        std::ostream &print(std::ostream &os) const;

        friend std::ostream &operator<<(std::ostream &os, const Frame &frame) {
            return frame.print(os);
        }

        const Cfg &getCfg() const;

        const std::string &getScope() const;

        unsigned int getReturnLabel() const;

    private:
        const Cfg &_cfg;
        std::string _scope;
        unsigned int _return_label;
    };
}// namespace se::etfa

#endif//AHORN_ETFA_FRAME_H
