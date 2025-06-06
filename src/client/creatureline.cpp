#include "creatureline.h"
#include "map.h"
#include "mapview.h"
#include "creature.h"
#include "spritemanager.h"
#include "game.h"
#include <framework/graphics/drawqueue.h>
#include <cmath>

CreatureLine::CreatureLine(uint32 fromId, uint32 toId, const std::string& name, const Color& color)
    : m_fromId(fromId), m_toId(toId), m_name(name), m_color(color)
{
    std::string file = "images/lines/" + name + ".png";
    m_texture = g_textures.getTexture(file);
    if (!m_texture)
        m_texture = g_textures.getTexture("images/lines/white.png");
}

void CreatureLine::draw(MapView* mapView, const Rect& rect, const Position& cameraPos, const Point& drawOffset,
                        float hFactor, float vFactor)
{
    CreaturePtr from = g_map.getCreatureById(m_fromId);
    CreaturePtr to = g_map.getCreatureById(m_toId);
    if (!from || !to)
        return;
    if (!from->canBeSeen() || !to->canBeSeen())
        return;
    Position aPos = from->getPrewalkingPosition();
    Position bPos = to->getPrewalkingPosition();
    if (aPos.z != cameraPos.z || bPos.z != cameraPos.z)
        return;

    Point a = mapView->transformPositionTo2D(aPos, cameraPos) - drawOffset +
               Point(16 * g_sprites.getOffsetFactor(), 16 * g_sprites.getOffsetFactor());
    Point b = mapView->transformPositionTo2D(bPos, cameraPos) - drawOffset +
               Point(16 * g_sprites.getOffsetFactor(), 16 * g_sprites.getOffsetFactor());
    a.x *= hFactor; a.y *= vFactor;
    b.x *= hFactor; b.y *= vFactor;
    a += rect.topLeft();
    b += rect.topLeft();

    float dx = b.x - a.x;
    float dy = b.y - a.y;
    float len = std::sqrt(dx * dx + dy * dy);
    if (len < 1.f)
        return;

    Size texSize = m_texture->getSize();
    Rect dest(a - Point(texSize.width() / 2, 0), Size(texSize.width(), len));
    size_t start = g_drawQueue->size();
    g_drawQueue->addTexturedRect(dest, m_texture, Rect(0, 0, texSize), m_color);
    float angle = std::atan2(dy, dx) - Fw::pi / 2.f;
    g_drawQueue->setRotation(start, a, angle);
}
