#ifndef CREATUREGHOST_H
#define CREATUREGHOST_H

#include "thing.h"
#include "outfit.h"
#include <framework/core/timer.h>

class CreatureGhost : public Thing {
public:
    CreatureGhost();

    void draw(const Point& dest, bool animate = true, LightView* lightView = nullptr) override;

    void setOutfit(const Outfit& outfit) { m_outfit = outfit; }
    void setDirection(Otc::Direction dir) { m_direction = dir; }
    void setDuration(int duration) { m_duration = duration; }

    bool isCreature() override { return false; }

private:
    Outfit m_outfit;
    Otc::Direction m_direction = Otc::South;
    Timer m_timer;
    int m_duration = 1500; // milliseconds
};

using CreatureGhostPtr = std::shared_ptr<CreatureGhost>;

#endif
