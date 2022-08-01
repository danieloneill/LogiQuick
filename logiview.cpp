#include "logiview.h"
#include "animationdriver.h"

#include <QDebug>
#include <QQmlContext>
#include <QQuickStyle>

#include "LogitechLCDLib.h"

QT_BEGIN_NAMESPACE
Q_GUI_EXPORT void qt_gl_set_global_share_context(QOpenGLContext* context);
Q_GUI_EXPORT QOpenGLContext* qt_gl_global_share_context();
QT_END_NAMESPACE

// Just for convenience, keep LCDkeys and QTkeys matching. (0=0, 1=1, etc)
const quint32 LCDkeys[] = {
    LOGI_LCD_COLOR_BUTTON_LEFT,
    LOGI_LCD_COLOR_BUTTON_RIGHT,
    LOGI_LCD_COLOR_BUTTON_UP,
    LOGI_LCD_COLOR_BUTTON_DOWN,
    LOGI_LCD_COLOR_BUTTON_OK,
    LOGI_LCD_COLOR_BUTTON_CANCEL,
    LOGI_LCD_COLOR_BUTTON_MENU
};

const Qt::Key QTkeys[] = {
    Qt::Key_Left,
    Qt::Key_Right,
    Qt::Key_Up,
    Qt::Key_Down,
    Qt::Key_Return,
    Qt::Key_Escape,
    Qt::Key_Menu
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
      m_rootItem{nullptr},
      m_fbo{nullptr},
      m_size{size},
      m_animationDriver{nullptr},
      m_status{NotRunning},
      m_fps{fps},
      m_currentFrame{false}
{
    QSurfaceFormat format;

    // Qt Quick may need a depth and stencil buffer. Always make sure these are available.
    format.setDepthBufferSize(16);
    format.setStencilBufferSize(8);
    format.setSwapBehavior(QSurfaceFormat::TripleBuffer);

    m_context = new QOpenGLContext;
    m_context->setFormat(format);

    // Shared context:
    if( QCoreApplication::testAttribute(Qt::AA_ShareOpenGLContexts) )
    {
        qDebug() << "Attempting to use a shared context...";
        QOpenGLContext *qtContext = qt_gl_global_share_context();
        m_context->setShareContext(qtContext);
        //qt_gl_set_global_share_context(m_context);
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
        m_status = NotRunning;
        qApp->quit();
    } );

    m_qmlEngine->rootContext()->setContextProperty("LogiView", this);

    m_context->makeCurrent(m_offscreenSurface);
    m_renderControl->initialize(m_context);

    connect( this, SIGNAL(stop()), this, SLOT(cleanup()) );

    m_animationDriver = new AnimationDriver();
    m_animationDriver->install();

    const int interval = floor(1000.0f / m_fps);
    qDebug() << "Frame interval set to" << interval << "ms";
    m_refreshTimer.setTimerType(Qt::PreciseTimer);
    m_refreshTimer.setInterval(interval);
    m_refreshTimer.setSingleShot(false);
    connect( &m_refreshTimer, &QTimer::timeout, this, &LogiView::updateFrame );

    // For convenience, but there are other more flexible ways of specifying the Controls style
    // See: https://doc.qt.io/qt-5/qtquickcontrols2-styles.html
    QQuickStyle::setStyle("Material");
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

    m_animationDriver->uninstall();
    delete m_animationDriver;

    LogiLcdShutdown();
}

bool LogiView::loadQML(const QUrl &qmlUrl)
{
    if( m_qmlComponent != nullptr )
        delete m_qmlComponent;
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

    QObject *rootObject = m_qmlComponent->create();
    if( m_qmlComponent->isError() )
    {
        const QList<QQmlError> errorList = m_qmlComponent->errors();
        for( const QQmlError &error : errorList )
            qWarning() << error.url() << error.line() << error;

        delete m_qmlComponent;
        m_qmlComponent = nullptr;

        return false;
    }

    m_rootItem = qobject_cast<QQuickItem *>(rootObject);
    if( !m_rootItem )
    {
        qWarning("loadQML: Not a QQuickItem");
        delete rootObject;
        return false;
    }

    // The root item is ready. Associate it with the window.
    m_rootItem->setParentItem(m_quickWindow->contentItem());

    m_rootItem->setWidth(m_size.width());
    m_rootItem->setHeight(m_size.height());

    m_quickWindow->setGeometry(0, 0, m_size.width(), m_size.height());

    m_rootItem->setFocus(true);

    qDebug() << "Loaded" << qmlUrl;
    return true;
}


void LogiView::cleanup()
{
    m_status = NotRunning;
    destroyFbo();
}

void LogiView::createFbo()
{
    if( m_fbo )
        return;

    m_fbo = new QOpenGLFramebufferObject(m_size, QOpenGLFramebufferObject::CombinedDepthStencil);
    m_quickWindow->setRenderTarget(m_fbo);
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
    wchar_t wname[] = L"LogiView";
    LogiLcdInit(wname, LOGI_LCD_TYPE_COLOR);

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
}

void LogiView::postKeyPressed(Qt::Key key)
{
    if( !m_rootItem )
        return;

    //qDebug() << "Press: " << key;
    QKeyEvent *n = new QKeyEvent(QEvent::KeyPress, key, Qt::NoModifier);
    qApp->postEvent(m_rootItem, n);
}

void LogiView::postKeyReleased(Qt::Key key)
{
    if( !m_rootItem )
        return;

    //qDebug() << "Release: " << key;
    QKeyEvent *n = new QKeyEvent(QEvent::KeyRelease, key, Qt::NoModifier);
    qApp->postEvent(m_rootItem, n);
}

void LogiView::updateFrame()
{
    if( !m_rootItem || m_status != Running )
        return;

    if( m_grabbing )
    {
        qDebug() << "Dropping frame. This scene is too complicated/dynamic to render at the requested framerate!";
        return;
    }

    // Inject keyboard events if pending:
    quint32 newPressed = 0;
    for( int x=0; x < sizeof(LCDkeys) / sizeof(quint32); x++ )
    {
        quint32 logiKey = LCDkeys[x];
        if( LogiLcdIsButtonPressed(logiKey) )
        {
            newPressed |= logiKey;
            if( !(m_pressed & logiKey) )
                postKeyPressed(QTkeys[x]);
        }
        else if( m_pressed & logiKey )
            postKeyReleased(QTkeys[x]);
    }
    m_pressed = newPressed;

    if( !m_newFrame )
        return;

    // Begin meat:
    m_grabbing = true;
    m_newFrame = false;

    // Polish, synchronize and render the next frame (into our fbo).
    m_renderControl->polishItems();
    if( !m_renderControl->sync() )
    {
        m_grabbing = false;
        return;
    }

    m_currentFrame++;
    emit currentFrameChanged();

    m_renderControl->render();
    m_context->functions()->glFlush();

    // This conversion chain only has overhead if
    // it has anything to do.
    //
    // The size and format are required to display
    // on the g19s, but the surface *should* already
    // fit:
    QImage img = m_fbo->toImage()
            .scaled(m_size.width(), m_size.height())
            .convertToFormat(QImage::Format_ARGB32);

    LogiLcdColorSetBackground( (uchar *)img.constBits() );
    LogiLcdUpdate();

    m_animationDriver->advance();

    m_grabbing = false;
}

void LogiView::sceneChanged()
{
    m_newFrame = true;
}
