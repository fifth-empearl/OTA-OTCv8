#ifndef CREATUREGHOST_H
#define CREATUREGHOST_H

#include "thing.h"
#include "outfit.h"
#include <framework/core/timer.h>

class CreatureGhost : public Thing
{
public:
    CreatureGhost();

    void draw(const Point& dest, bool animate = true, LightView* lightView = nullptr) override;

    Point getFloatOffset() const;
    float getOpacity() const;

    void setOutfit(const Outfit& outfit) { m_outfit = outfit; }
    void setDirection(Otc::Direction dir) { m_direction = dir; }

    CreatureGhostPtr asCreatureGhost() { return static_self_cast<CreatureGhost>(); }
    bool isCreatureGhost() override { return true; }

protected:
    void onAppear() override;

private:
    Outfit m_outfit;
    Otc::Direction m_direction = Otc::North;
    Timer m_timer;
    float m_duration = 1500.f; // milliseconds
};

#endif
