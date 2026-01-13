#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "databasemanager.h"
#include "taskmodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("ToDoManager");
    app.setOrganizationName("ToDoManager");
    app.setApplicationVersion("1.0");

    // Создаем менеджер базы данных
    DatabaseManager dbManager;

    // Подключаемся к базе данных (настройте параметры под свою базу)
    bool connected = dbManager.connectToDatabase(
        "localhost",      // host
        "project",    // database name
        "postgres",       // username
        "1234",  // password
        5432             // port
        );

    // Создаем модель задач
    TaskModel taskModel(&dbManager);

    if (connected) {
        taskModel.refreshAll();
    }

    QQmlApplicationEngine engine;

    // Регистрируем объекты в QML
    engine.rootContext()->setContextProperty("dbManager", &dbManager);
    engine.rootContext()->setContextProperty("taskModel", &taskModel);

    const QUrl url(QStringLiteral("qrc:/ToDoManager/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
        );

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qWarning() << "Failed to load QML";
        return -1;
    }

    return app.exec();
}
