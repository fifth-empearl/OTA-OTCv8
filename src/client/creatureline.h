#ifndef CREATURELINE_H
#define CREATURELINE_H

#include "declarations.h"
#include <framework/graphics/texturemanager.h>
#include <framework/util/color.h>
#include <memory>

class MapView;

struct CreatureLineType
{
    std::string image;
    Color color{Color::white};
    bool stretched{true};
    bool antialias{true};
    TexturePtr texture;
};

class CreatureLine
{
public:
    CreatureLine(uint32 fromId, uint32 toId, CreatureLineType* type);

    uint32 getFromId() const { return m_fromId; }
    uint32 getToId() const { return m_toId; }

    void draw(MapView* mapView, const Rect& rect, const Position& cameraPos, const Point& drawOffset,
              float hFactor, float vFactor);

private:
    uint32 m_fromId{0};
    uint32 m_toId{0};
    CreatureLineType* m_type{nullptr};
};

using CreatureLinePtr = std::shared_ptr<CreatureLine>;

#endif
