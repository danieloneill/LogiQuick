#ifndef INPUTWINDOW_H
#define INPUTWINDOW_H

#include <QImage>
#include <QObject>
#include <QScreen>
#include <QWidget>

class LogiView;
class InputWindow : public QWidget
{
    Q_OBJECT

    LogiView    *m_logiview;
    QImage      m_image;

public:
    InputWindow(LogiView *lv, QWidget *parent = nullptr);

private slots:
    void updateImage(const QImage &image);

protected:
    void 	paintEvent(QPaintEvent *event) override;
    void 	focusInEvent(QFocusEvent *event) override;
    void    focusOutEvent(QFocusEvent *event) override;
    void 	keyPressEvent(QKeyEvent *event) override;
    void 	keyReleaseEvent(QKeyEvent *event) override;
    void 	mouseMoveEvent(QMouseEvent *event) override;
    void 	mousePressEvent(QMouseEvent *event) override;
    void 	mouseReleaseEvent(QMouseEvent *event) override;
    void    mouseDoubleClickEvent(QMouseEvent *event) override;
    void 	wheelEvent(QWheelEvent *event) override;
};

#endif // INPUTWINDOW_H
