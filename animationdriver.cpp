#include "animationdriver.h"

AnimationDriver::AnimationDriver()
{
    m_elapsed.restart();
}

void AnimationDriver::advance()
{
    advanceAnimation();
}

qint64 AnimationDriver::elapsed() const
{
    return m_elapsed.elapsed();
}
