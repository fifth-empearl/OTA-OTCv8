#ifndef CREATURELINE_H
#define CREATURELINE_H

#include "declarations.h"
#include <framework/graphics/texturemanager.h>
#include <framework/util/color.h>
#include <memory>

class MapView;

class CreatureLine
{
public:
    CreatureLine(uint32 fromId, uint32 toId, const std::string& name, const Color& color);

    uint32 getFromId() const { return m_fromId; }
    uint32 getToId() const { return m_toId; }

    void draw(MapView* mapView, const Rect& rect, const Position& cameraPos, const Point& drawOffset,
              float hFactor, float vFactor);

private:
    uint32 m_fromId;
    uint32 m_toId;
    std::string m_name;
    Color m_color;
    TexturePtr m_texture;
};

using CreatureLinePtr = std::shared_ptr<CreatureLine>;

#endif
