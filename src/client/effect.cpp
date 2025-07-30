/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "effect.h"
#include "map.h"
#include "game.h"
#include <framework/core/eventdispatcher.h>
#include <framework/util/extras.h>
#include <framework/stdext/fastrand.h>
#include <algorithm>

int Effect::TICKS_PER_FRAME = Effect::DEFAULT_EFFECT_TICKS;

void Effect::setTicksPerFrame(int ticks)
{
    TICKS_PER_FRAME = std::max(1, ticks);
}

int Effect::getTicksPerFrame()
{
    return TICKS_PER_FRAME;
}

void Effect::draw(const Point& dest, int offsetX, int offsetY, bool animate, LightView* lightView)
{
    if(m_id == 0)
        return;

    if(animate) {
        if(g_game.getFeature(Otc::GameEnhancedAnimations) && rawGetThingType()->getAnimator()) {
            // adjust timer ticks so animations respect the configured frame speed
            float scale = static_cast<float>(Effect::DEFAULT_EFFECT_TICKS) / TICKS_PER_FRAME;

            Timer timer;
            timer.adjust(-static_cast<int>(m_animationTimer.ticksElapsed() * scale));

            // This requires a separate getPhaseAt method as using getPhase would make all magic effects use the same phase regardless of their appearance time
            m_animationPhase = std::max<int>(0, rawGetThingType()->getAnimator()->getPhaseAt(timer, m_randomSeed, m_animationPhase));
        } else {
            // hack to fix some animation phases duration, currently there is no better solution
            int ticks = TICKS_PER_FRAME;
            if (m_id == 33) {
                ticks <<= 2;
            }

            m_animationPhase = std::max<int>(0, std::min<int>((int)(m_animationTimer.ticksElapsed() / ticks), getAnimationPhases() - 1));
        }
    }

    int xPattern = m_position.x % getNumPatternX();
    if(xPattern < 0)
        xPattern += getNumPatternX();

    int yPattern = m_position.y % getNumPatternY();
    if(yPattern < 0)
        yPattern += getNumPatternY();

    rawGetThingType()->draw(dest, 0, xPattern, yPattern, 0, m_animationPhase, Color::white, lightView);
}

void Effect::onAppear()
{
    m_animationTimer.restart();

    int duration = 0;
    if(g_game.getFeature(Otc::GameEnhancedAnimations)) {
        m_randomSeed = (uint32_t)stdext::fastrand();
        duration = getThingType()->getAnimator() ? getThingType()->getAnimator()->getTotalDuration(m_randomSeed) : 1000;
        duration = static_cast<int>(duration * TICKS_PER_FRAME / Effect::DEFAULT_EFFECT_TICKS);
    } else {
        duration = TICKS_PER_FRAME;

        // hack to fix some animation phases duration, currently there is no better solution
        if(m_id == 33) {
            duration <<= 2;
        }

        duration *= getAnimationPhases();
    }

    // schedule removal
    auto self = asEffect();
    g_dispatcher.scheduleEvent([self]() { g_map.removeThing(self); }, duration);
}

void Effect::setId(uint32 id)
{
    if(!g_things.isValidDatId(id, ThingCategoryEffect))
        id = 0;
    m_id = id;
}

const ThingTypePtr& Effect::getThingType()
{
    return g_things.getThingType(m_id, ThingCategoryEffect);
}

ThingType *Effect::rawGetThingType()
{
    return g_things.rawGetThingType(m_id, ThingCategoryEffect);
}
