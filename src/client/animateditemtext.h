#ifndef ANIMATEDITEMTEXT_H
#define ANIMATEDITEMTEXT_H

#include "thing.h"
#include "item.h"
#include <framework/graphics/fontmanager.h>
#include <framework/core/timer.h>
#include <framework/graphics/cachedtext.h>

class AnimatedItemText : public Thing
{
public:
    AnimatedItemText();

    void drawText(const Point& dest, const Rect& visibleRect);

    void setItemId(int id);
    void setText(const std::string& text);
    void setOffset(const Point& offset) { m_offset = offset; }
    void setFont(const std::string& fontName);

    ItemPtr getItem() { return m_item; }
    std::string getText() { return m_cachedText.getText(); }
    Timer getTimer() { return m_animationTimer; }
    Point getOffset() { return m_offset; }

    AnimatedItemTextPtr asAnimatedItemText() { return static_self_cast<AnimatedItemText>(); }
    bool isAnimatedItemText() override { return true; }

protected:
    void onAppear() override;

private:
    ItemPtr m_item;
    Timer m_animationTimer;
    CachedText m_cachedText;
    Point m_offset;
};

#endif
