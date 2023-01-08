#include "inputwindow.h"
#include "logiview.h"

#include <QDebug>
#include <QPainter>

InputWindow::InputWindow(LogiView *lv, QWidget *parent)
    : QWidget(parent),
      m_logiview{lv}
{
    resize(320, 240);
    setFocusPolicy(Qt::ClickFocus);
    setMouseTracking(true);

    connect( lv, &LogiView::framebufferUpdated, this, &InputWindow::updateImage );
}

void InputWindow::updateImage(const QImage &image)
{
    m_image = image;
    if( !isMinimized() )
        update();
}

void InputWindow::paintEvent(QPaintEvent *event)
{
    QPainter p(this);
    p.drawImage(0, 0, m_image);
    event->accept();
}

void InputWindow::focusInEvent(QFocusEvent *event)
{
    event->accept();
}

void InputWindow::focusOutEvent(QFocusEvent *event)
{
    event->accept();
}

void InputWindow::keyPressEvent(QKeyEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::keyReleaseEvent(QKeyEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::mouseMoveEvent(QMouseEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::mousePressEvent(QMouseEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::mouseReleaseEvent(QMouseEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::mouseDoubleClickEvent(QMouseEvent *event)
{
    m_logiview->postEvent(event);
}

void InputWindow::wheelEvent(QWheelEvent *event)
{
    m_logiview->postEvent(event);
}
