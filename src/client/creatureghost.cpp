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
    float t = std::min<float>(m_timer.ticksElapsed() / m_duration, 1.f);
    Point offset = Point(-32 * t, -32 * t) * g_sprites.getOffsetFactor();
    size_t start = g_drawQueue->size();
    m_outfit.draw(dest + offset, m_direction, 0, animate, lightView);
    g_drawQueue->setOpacity(start, 1.f - t);
}
