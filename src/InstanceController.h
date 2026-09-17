#pragma once

#include <QObject>
#include <QPointer>

class QWindow;

class InstanceController : public QObject
{
    Q_OBJECT

public:
    explicit InstanceController(QObject *parent = nullptr);
    void setWindow(QWindow *window);

public slots:
    Q_SCRIPTABLE void show();

private:
    QPointer<QWindow> m_window;
    bool m_showPending = false;
};
