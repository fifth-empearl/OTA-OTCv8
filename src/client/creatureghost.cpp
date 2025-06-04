#include "creatureghost.h"
#include "map.h"
#include "spritemanager.h"
#include <framework/graphics/drawqueue.h>
#include <framework/core/eventdispatcher.h>

CreatureGhost::CreatureGhost()
{
}

void CreatureGhost::onAppear()
{
    m_timer.restart();
    auto self = asCreatureGhost();
    g_dispatcher.scheduleEvent([self]() { g_map.removeThing(self); }, m_duration);
}

void CreatureGhost::draw(const Point& dest, bool animate, LightView* lightView)
{
    m_outfit.draw(dest, m_direction, 0, animate, lightView);
}

Point CreatureGhost::getFloatOffset() const
{
    float t = std::min<float>(m_timer.ticksElapsed() / m_duration, 1.f);
    return Point(-32 * t, -32 * t) * g_sprites.getOffsetFactor();
}

float CreatureGhost::getOpacity() const
{
    float t = std::min<float>(m_timer.ticksElapsed() / m_duration, 1.f);
    return 1.f - t;
}
