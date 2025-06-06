#include "creatureline.h"
#include "map.h"
#include "mapview.h"
#include "creature.h"
#include "spritemanager.h"
#include "game.h"
#include <framework/graphics/drawqueue.h>
#include <framework/graphics/coordsbuffer.h>
#include <cmath>

CreatureLine::CreatureLine(uint32 fromId, uint32 toId, uint32 typeId, CreatureLineType* type)
    : m_fromId(fromId), m_toId(toId), m_typeId(typeId), m_type(type)
{
    if (!m_type)
        return;

    if (!m_type->texture) {
        std::string file = m_type->image.empty() ? "images/lines/white.png" : m_type->image;
        m_type->texture = g_textures.getTexture(file);
        if (!m_type->texture)
            m_type->texture = g_textures.getTexture("images/lines/white.png");
        if (m_type->texture) {
            m_type->texture->setSmooth(m_type->antialias);
            m_type->texture->setRepeat(!m_type->stretched);
        }
    }
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

    if (!m_type || !m_type->texture)
        return;

    Size texSize = m_type->texture->getSize();
    Rect dest(a - Point(texSize.width() / 2, 0), Size(texSize.width(), len));
    size_t start = g_drawQueue->size();

    if (m_type->stretched) {
        g_drawQueue->addTexturedRect(dest, m_type->texture, Rect(0, 0, texSize), m_type->color);
    } else {
        CoordsBuffer coords;
        coords.addRepeatedRects(dest, Rect(0, 0, texSize));
        g_drawQueue->addTextureCoords(coords, m_type->texture, m_type->color);
    }

    float angle = std::atan2(dy, dx) - Fw::pi / 2.f;
    g_drawQueue->setRotation(start, a, angle);
}
