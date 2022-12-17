#include "logiview.h"

#include <QDebug>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSettings>
#include <QStandardPaths>
#if QT_VERSION >= 0x060400
# include <QQuickRenderTarget>
#endif

QT_BEGIN_NAMESPACE
Q_GUI_EXPORT void qt_gl_set_global_share_context(QOpenGLContext* context);
Q_GUI_EXPORT QOpenGLContext* qt_gl_global_share_context();
QT_END_NAMESPACE

const Qt::Key QTkeys[] = {
    Qt::Key_Launch0,    // G1
    Qt::Key_Launch1,    // G2
    Qt::Key_Launch2,    // G3
    Qt::Key_Launch3,    // G4
    Qt::Key_Launch4,    // G5
    Qt::Key_Launch5,    // G6
    Qt::Key_Launch6,    // G7
    Qt::Key_Launch7,    // G8
    Qt::Key_Launch8,    // G9
    Qt::Key_Launch9,    // G10
    Qt::Key_LaunchA,    // G11
    Qt::Key_LaunchB,    // G12

    Qt::Key_LaunchC,    // M1
    Qt::Key_LaunchD,    // M2
    Qt::Key_LaunchE,    // M3
    Qt::Key_LaunchF,    // MR

    Qt::Key_HomePage,   // Home
    Qt::Key_Stop,       // Cancel
    Qt::Key_Favorites,  // Menu
    Qt::Key_Go,         // OK

    Qt::Key_Right,      // Right
    Qt::Key_Left,       // Left
    Qt::Key_Down,       // Down
    Qt::Key_Up,         // Up

    Qt::Key_LightBulb   // Light
};

LogiView::LogiView(const QSize size, const double fps, QObject *parent)
    : QObject(parent),
      m_grabbing{false},
      m_pressed{0},
      m_context{nullptr},
      m_offscreenSurface{nullptr},
      m_renderControl{nullptr},
      m_quickWindow{nullptr},
      m_qmlEngine{nullptr},
      m_qmlComponent{nullptr},
      m_rootObject{nullptr},
      m_rootItem{nullptr},
      m_fbo{nullptr},
      m_size{size},
      m_status{NotRunning},
      m_fps{fps},
      m_currentFrame{false}
{
    m_settings = new QSettings("danieloneill", "LogiQuick", this);

    QStringList paths = QStandardPaths::standardLocations(QStandardPaths::DesktopLocation);
    if( paths.length() == 0 )
        paths << "C:/";

    m_openDialogue = new QFileDialog(nullptr, tr("Open QML File"), paths[0]);

    QSurfaceFormat format;

    // Qt Quick may need a depth and stencil buffer. Always make sure these are available.
    format.setDepthBufferSize(16);
    format.setStencilBufferSize(8);
    format.setSwapBehavior(QSurfaceFormat::DoubleBuffer);

    m_context = new QOpenGLContext;
    m_context->setFormat(format);

    // Shared context:
    if( QCoreApplication::testAttribute(Qt::AA_ShareOpenGLContexts) )
    {
        QOpenGLContext *qtContext = qt_gl_global_share_context();
        m_context->setShareContext(qtContext);
    }

    m_context->create();

    m_offscreenSurface = new QOffscreenSurface;
    m_offscreenSurface->setFormat(m_context->format());
    m_offscreenSurface->create();

    m_renderControl = new QQuickRenderControl(this);
    connect( m_renderControl, SIGNAL(sceneChanged()), this, SLOT(sceneChanged()) );
    connect( m_renderControl, SIGNAL(renderRequested()), this, SLOT(sceneChanged()) );

    m_quickWindow = new QQuickWindow(m_renderControl);
    m_quickWindow->setGeometry(0, 0, m_size.width(), m_size.height());

    m_qmlEngine = new QQmlEngine;
    if (!m_qmlEngine->incubationController())
        m_qmlEngine->setIncubationController(m_quickWindow->incubationController());

    connect( m_qmlEngine, &QQmlEngine::quit, qApp, [this](){
        qDebug() << "QQmlEngine::quit requested.";
        m_status = NotRunning;
        qApp->quit();
    } );

    m_qmlEngine->rootContext()->setContextProperty("LogiView", this);

    m_context->makeCurrent(m_offscreenSurface);
#if QT_VERSION >= 0x060400
    m_renderControl->initialize();
#else
    m_renderControl->initialize(m_context);
#endif

    connect( this, SIGNAL(stop()), this, SLOT(cleanup()) );

    const int interval = floor(1000.0f / m_fps);
    qDebug() << "Frame interval set to" << interval << "ms";
    m_refreshTimer.setTimerType(Qt::PreciseTimer);
    m_refreshTimer.setInterval(interval);
    m_refreshTimer.setSingleShot(false);
    connect( &m_refreshTimer, &QTimer::timeout, this, &LogiView::updateFrame );

    connect( this, &LogiView::deferredLoad, this, [this](const QUrl &path){
        loadQML(path);
    }, Qt::QueuedConnection );

    m_g19device.initializeDevice();
    connect( &m_g19device, &G19Device::lKey, this, &LogiView::keyPressed );
    connect( &m_g19device, &G19Device::gKey, this, &LogiView::keyPressed );
}

LogiView::~LogiView()
{
    m_context->makeCurrent(m_offscreenSurface);

    cleanup();
    destroyFbo();

    delete m_renderControl;
    delete m_qmlComponent;
    delete m_quickWindow;
    delete m_qmlEngine;
    delete m_fbo;

    m_context->doneCurrent();

    delete m_offscreenSurface;
    delete m_context;
}

void LogiView::load(const QString &path)
{
    emit deferredLoad(QUrl::fromLocalFile(path));
}

void LogiView::setDisplayBrightness(int brightness)
{
    m_g19device.setDisplayBrightness(brightness);
}

QString LogiView::getOpenFileName(const QString &caption, const QString &dir, const QString &filter)
{
    return QFileDialog::getOpenFileName(nullptr, caption, dir, filter);
}

bool LogiView::loadQML(const QUrl &qmlUrl)
{
    if( m_qmlComponent != nullptr )
        delete m_qmlComponent;

    m_qmlEngine->clearComponentCache();
    m_qmlEngine->collectGarbage();
    m_qmlComponent = new QQmlComponent(m_qmlEngine, qmlUrl, QQmlComponent::PreferSynchronous);

    if( m_qmlComponent->isError() )
    {
        const QList<QQmlError> errorList = m_qmlComponent->errors();
        for( const QQmlError &error : errorList )
            qWarning() << error.url() << error.line() << error;

        delete m_qmlComponent;
        m_qmlComponent = nullptr;

        return false;
    }

    if( m_rootObject )
    {
        m_rootItem->setParentItem(nullptr);
        delete m_rootObject;
        m_rootItem = nullptr;
        m_rootObject = nullptr;
    }

    m_rootObject = m_qmlComponent->create();
    if( !m_rootObject || m_qmlComponent->isError() )
    {
        const QList<QQmlError> errorList = m_qmlComponent->errors();
        for( const QQmlError &error : errorList )
            qWarning() << error.url() << error.line() << error;

        delete m_qmlComponent;
        m_qmlComponent = nullptr;

        return false;
    }

    m_rootItem = qobject_cast<QQuickItem *>(m_rootObject);
    if( !m_rootItem )
    {
        qWarning("loadQML: Not a QQuickItem");
        delete m_rootObject;
        m_rootObject = nullptr;
        return false;
    }

    // The root item is ready. Associate it with the window.
    m_rootItem->setParentItem(m_quickWindow->contentItem());

    m_rootItem->setWidth(m_size.width());
    m_rootItem->setHeight(m_size.height());

    m_quickWindow->setGeometry(0, 0, m_size.width(), m_size.height());

    QFocusEvent *qfe = new QFocusEvent(QEvent::FocusIn, Qt::ActiveWindowFocusReason);
    qApp->sendEvent(m_quickWindow, qfe);

    m_rootItem->setFocus(true);

    qDebug() << "Loaded" << qmlUrl;
    m_settings->setValue("lastFile", qmlUrl.toLocalFile());

    return true;
}

void LogiView::showLoadDialogue()
{
    m_openDialogue->setFileMode(QFileDialog::ExistingFile);
    m_openDialogue->setNameFilter(QObject::tr("QML Files (*.qml)"));
    m_openDialogue->setOption(QFileDialog::DontUseNativeDialog, false);

    QObject::connect( m_openDialogue, &QFileDialog::accepted, [this](){
        QStringList selectedFiles = m_openDialogue->selectedFiles();
        QString fileName = selectedFiles.first();
        if( fileName.length() > 0 )
        {
            if( loadQML(QUrl::fromLocalFile(fileName)) )
                m_settings->setValue("lastFile", fileName);
        }

        m_openDialogue->hide();
    } );

    QObject::connect( m_openDialogue, &QFileDialog::rejected, [this](){
        m_openDialogue->hide();
    } );

    m_openDialogue->show();
}

void LogiView::cleanup()
{
    qDebug() << "Cleaning up...";
    if( m_status == Running )
        m_g19device.closeDevice();

    m_refreshTimer.stop();
    m_status = NotRunning;
    destroyFbo();
}

void LogiView::createFbo()
{
    if( m_fbo )
        return;

    QOpenGLFramebufferObjectFormat format = QOpenGLFramebufferObjectFormat();
    qDebug() << m_context->extensions();
    if( m_context->hasExtension("GL_EXT_framebuffer_blit") )
        qDebug() << "GL_EXT_framebuffer_blit is supported, yey.";

    format.setSamples(m_offscreenSurface->format().samples());
    format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);

    m_fbo = new QOpenGLFramebufferObject(m_size, format);

#if QT_VERSION >= 0x060400
    m_quickWindow->setRenderTarget( QQuickRenderTarget::fromOpenGLTexture(m_fbo->texture(), m_fbo->size()) );
#else
    m_quickWindow->setRenderTarget(m_fbo);
#endif
}

void LogiView::destroyFbo()
{
    if( !m_fbo )
        return;

    delete m_fbo;
    m_fbo = nullptr;
}

void LogiView::start()
{
    if( m_status == Running )
        return;

    m_g19device.openDevice();

    m_status = Running;
    createFbo();

    if( !m_context->makeCurrent(m_offscreenSurface) )
    {
        qDebug() << "Failed to make offscreen surface context current.";
        return;
    }

    // Render each frame of movie
    m_currentFrame = 0;

    m_refreshTimer.start();
    qDebug() << "Starting!";
}

void LogiView::postEvent(QEvent *ev)
{
    if( !m_quickWindow )
        return;

    qApp->sendEvent(m_quickWindow, ev);
}

void LogiView::postKeyPressed(Qt::Key key, Qt::KeyboardModifiers modifiers)
{
    if( !m_rootItem )
        return;

    qDebug() << "Press: " << key;
    QKeyEvent *n = new QKeyEvent(QEvent::KeyPress, key, modifiers);
    qApp->sendEvent(m_quickWindow, n);
}

void LogiView::postKeyReleased(Qt::Key key, Qt::KeyboardModifiers modifiers)
{
    if( !m_rootItem )
        return;

    qDebug() << "Release: " << key;
    QKeyEvent *n = new QKeyEvent(QEvent::KeyRelease, key, modifiers);
    qApp->sendEvent(m_quickWindow, n);
}

void LogiView::updateFrame()
{
    if( !m_rootItem || !m_qmlComponent || m_status != Running )
    {
        if( m_status == Running )
        {
            // Placeholder:
            QImage img(m_size.width(), m_size.height(), QImage::Format_ARGB32);
            img.fill(Qt::red);

            m_g19device.updateLcd(&img);
        }

        return;
    }

    if( m_grabbing )
    {
        qDebug() << "Dropping frame. This scene is too complicated/dynamic to render at the requested framerate!";
        return;
    }

    grabFrame();
}

void LogiView::keyPressed()
{
    quint32 keys = m_g19device.getKeys();

    // Inject keyboard events if pending:
    quint32 newPressed = 0;
    quint32 mask = 1;
    for( int x=0; x < 24; x++ )
    {
        bool logiKey = (mask & keys);
        if( logiKey )
        {
            newPressed |= mask;
            if( !(m_pressed & mask) )
            {
                //postKeyPressed(QTkeys[x]);
                emit gKeyPressed(QTkeys[x]);
            }
        }
/*
        else if( m_pressed & logiKey )
            postKeyReleased(QTkeys[x]);
*/
        mask <<= 1;
    }
    m_pressed = newPressed;
}

void LogiView::grabFrame()
{
    if( !m_newFrame )
        return;

    // Begin meat:
    m_grabbing = true;
    m_newFrame = false;

    // Polish, synchronize and render the next frame (into our fbo).
    m_renderControl->polishItems();
#if QT_VERSION >= 0x060400
    m_renderControl->beginFrame();
#endif
    if( !m_renderControl->sync() )
    {
        m_grabbing = false;
        return;
    }

    m_currentFrame++;
    emit currentFrameChanged();

    m_fbo->bind();
    m_renderControl->render();
    m_fbo->release();

#if QT_VERSION >= 0x060400
    m_renderControl->endFrame();
#endif

    QImage img = m_fbo->toImage();
    m_g19device.updateLcd(&img);
    emit framebufferUpdated(img);

    m_grabbing = false;
}

void LogiView::sceneChanged()
{
    m_newFrame = true;
}
