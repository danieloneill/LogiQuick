#ifndef LOGIVIEW_H
#define LOGIVIEW_H

#include <QDebug>
#include <QEventLoop>
#include <QImage>
#include <QMutex>
#include <QObject>
#include <QThread>
#include <QTimer>

#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLFramebufferObject>
#include <QOpenGLShaderProgram>
#include <QOpenGLVertexArrayObject>
#include <QOpenGLBuffer>
#include <QOpenGLVertexArrayObject>
#include <QOffscreenSurface>
#include <QScreen>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QQuickWindow>
#include <QQuickRenderControl>
#include <QEvent>

class AnimationDriver;
class LogiView : public QObject
{
    Q_OBJECT

    QTimer m_refreshTimer;
    bool m_grabbing;
    bool m_newFrame;
    quint32 m_pressed;

public:
    explicit LogiView(const QSize size, const double fpsLimit, QObject *parent = nullptr);
    ~LogiView();

    Q_PROPERTY(quint64 currentFrame READ getCurrentFrame NOTIFY currentFrameChanged)

    void start();

    typedef enum {
        NotRunning,
        Running
    } Status;
    Q_ENUM(Status)

public slots:
    bool loadQML(const QUrl &qmlFile);

private slots:
    void sceneChanged();
    void updateFrame();
    void createFbo();
    void destroyFbo();
    void cleanup();

    quint64 getCurrentFrame() { return m_currentFrame; }

    void postKeyPressed(Qt::Key key);
    void postKeyReleased(Qt::Key key);

private:
    QOpenGLContext *m_context;
    QOffscreenSurface *m_offscreenSurface;
    QQuickRenderControl *m_renderControl;
    QQuickWindow *m_quickWindow;
    QQmlEngine *m_qmlEngine;
    QQmlComponent *m_qmlComponent;
    QQuickItem *m_rootItem;
    QOpenGLFramebufferObject *m_fbo;
    QSize m_size;
    AnimationDriver *m_animationDriver;

    Status m_status;

    double m_fps;
    quint64 m_currentFrame;

signals:
    void stop();
    void currentFrameChanged();
};

#endif // LOGIVIEW_H
