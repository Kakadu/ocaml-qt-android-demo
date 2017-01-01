#include <QtCore/QObject>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>

int main(int argc, char** argv) {
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;
  engine.load(QUrl(QLatin1String("qrc:/main.qml")));
/*
  engine.load(QUrl(QLatin1String("import QtQuick 2.7 \n\
import QtQuick.Controls 2.0\n\
import QtQuick.Layouts 1.0\n\
ApplicationWindow { title: 'x' } \n\
")));
*/
  return app.exec();
}
