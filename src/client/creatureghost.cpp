#include "creatureghost.h"
#include <framework/graphics/graphics.h>

CreatureGhost::CreatureGhost()
{
    m_timer.restart();
}

void CreatureGhost::draw(const Point& dest, bool /*animate*/, LightView* lightView)
{
    float t = std::min<float>(m_timer.ticksElapsed() / static_cast<float>(m_duration), 1.f);
    Point offset(-32 * t, -32 * t);
    size_t start = g_drawQueue->size();
    m_outfit.draw(dest + offset, m_direction, 0, true, lightView);
    g_drawQueue->setOpacity(start, 0.8f * (1.f - t));
}
