#include "InstanceController.h"

#include <QWindow>

InstanceController::InstanceController(QObject *parent)
    : QObject(parent)
{
}

void InstanceController::setWindow(QWindow *window)
{
    m_window = window;
    if (m_showPending)
        show();
}

void InstanceController::show()
{
    if (!m_window) {
        m_showPending = true;
        return;
    }
    m_showPending = false;
    // Main.qml keeps visible=false only as the startup default for --background.
    // If visibility ever becomes a live QML binding, prefer a dedicated QML
    // activation method instead of fighting that binding from QWindow::show().
    m_window->show();
    m_window->raise();
    m_window->requestActivate();
}
