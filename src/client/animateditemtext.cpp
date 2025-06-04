#include "animateditemtext.h"
#include "map.h"
#include "game.h"
#include "spritemanager.h"
#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/graphics/graphics.h>

AnimatedItemText::AnimatedItemText()
{
    m_cachedText.setFont(g_fonts.getFont("verdana-11px-rounded"));
    m_cachedText.setAlign(Fw::AlignLeft);
    m_item = Item::create(0);
}

void AnimatedItemText::drawText(const Point& dest, const Rect& visibleRect)
{
    static float tf = Otc::ANIMATED_ITEM_TEXT_DURATION;
    Point p = dest;
    float t = m_animationTimer.ticksElapsed();

    p.y += (-Otc::ANIMATED_ITEM_TEXT_OFFSET * t) / tf;
    p += m_offset;

    Color color = Color::white;
    color.setAlpha(std::max<float>(0.f, 1.f - t / tf));

    const Size itemSize(g_sprites.spriteSize(), g_sprites.spriteSize());
    Rect itemRect(p, itemSize);
    if (visibleRect.contains(itemRect)) {
        m_item->setColor(color);
        m_item->draw(p);
        m_item->setColor(Color::alpha);
    }

    Size textSize = m_cachedText.getTextSize();
    Point textOffset((itemSize.width() - textSize.width()) / 2,
                     (itemSize.height() - textSize.height()) / 2);
    Rect textRect(p + textOffset, textSize);
    if (visibleRect.contains(textRect)) {
        m_cachedText.draw(textRect, color);
    }
}

void AnimatedItemText::onAppear()
{
    m_animationTimer.restart();
    auto self = asAnimatedItemText();
    g_dispatcher.scheduleEvent([self]() { g_map.removeThing(self); }, Otc::ANIMATED_ITEM_TEXT_DURATION);
}

void AnimatedItemText::setItemId(int id)
{
    if(!m_item)
        m_item = Item::create(id);
    else
        m_item->setId(id);
}

void AnimatedItemText::setText(const std::string& text)
{
    m_cachedText.setText(text);
}

void AnimatedItemText::setFont(const std::string& fontName)
{
    m_cachedText.setFont(g_fonts.getFont(fontName));
}

