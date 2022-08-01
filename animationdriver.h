#ifndef ANIMATIONDRIVER_H
#define ANIMATIONDRIVER_H

#include <QObject>
#include <QAnimationDriver>
#include <QElapsedTimer>

class AnimationDriver : public QAnimationDriver
{
    Q_OBJECT

    QElapsedTimer   m_elapsed;

public:
    explicit AnimationDriver();

    void advance() override;
    qint64 elapsed() const override;
};

#endif // ANIMATIONDRIVER_H
