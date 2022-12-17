#ifndef LOGIVIEW_H
#define LOGIVIEW_H

#include <QDebug>
#include <QEventLoop>
#include <QFileDialog>

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

#include "g19device.hpp"

class QSettings;
class LogiView : public QObject
{
    Q_OBJECT

    QTimer m_refreshTimer;
    bool m_grabbing;
    bool m_newFrame;
    quint32 m_pressed;

    G19Device m_g19device;
    QSettings *m_settings;

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

    QSettings *settings() { return m_settings; }

    void postEvent(QEvent *event);
    bool loadQML(const QUrl &qmlFile);

public slots:
    void showLoadDialogue();
    void load(const QString &path);
    void setDisplayBrightness(int brightness);
    void postKeyPressed(Qt::Key key, Qt::KeyboardModifiers modifiers=Qt::NoModifier);
    void postKeyReleased(Qt::Key key, Qt::KeyboardModifiers modifiers=Qt::NoModifier);

    QString getOpenFileName(const QString &caption = QString(), const QString &dir = QString(), const QString &filter = QString());

private slots:
    void sceneChanged();
    void updateFrame();
    void createFbo();
    void destroyFbo();
    void cleanup();

    quint64 getCurrentFrame() { return m_currentFrame; }
    void keyPressed();

    void grabFrame();

private:
    QOpenGLContext *m_context;
    QOffscreenSurface *m_offscreenSurface;
    QQuickRenderControl *m_renderControl;
    QQuickWindow *m_quickWindow;
    QQmlEngine *m_qmlEngine;
    QQmlComponent *m_qmlComponent;
    QObject *m_rootObject;
    QQuickItem *m_rootItem;
    QOpenGLFramebufferObject *m_fbo;
    QSize m_size;

    QFileDialog *m_openDialogue;

    Status m_status;

    double m_fps;
    quint64 m_currentFrame;

signals:
    void stop();
    void currentFrameChanged();
    void deferredLoad(const QUrl &path);
    void framebufferUpdated(const QImage &image);
    void gKeyPressed(Qt::Key key);
};

#endif // LOGIVIEW_H
