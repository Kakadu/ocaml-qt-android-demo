#include <QtCore/QObject>
#include <QtCore/QDebug>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlPropertyMap>
#include <QtQml/QQmlContext>

// Kakadu: using this seems to be better than qDebug.
// use `$(SDK)/platform-tools/adb shell logcat` for viewing a log
#include <android/log.h>

extern "C" {
#include <caml/startup.h>
#include <caml/callback.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

extern "C" value caml_print_hack(value _msg) {
  CAMLparam1(_msg);
  char* msg = String_val(_msg);
  __android_log_print(ANDROID_LOG_INFO, "kamlo", "fromCaml: %s\n", msg);
  CAMLreturn(Val_unit);
}

}

const QString doCaml() {
  static value *closure = nullptr;
  if (closure == nullptr) {
    closure = caml_named_value("doCaml");
  }
  if (closure==nullptr) {
    __android_log_print(ANDROID_LOG_ERROR, "kamlo", "no closure");
    return "FUCK";
  }
  value b = caml_callback(*closure, Val_unit); // should be a unit
  char* s = String_val(b);
  const QString& ans = QString::fromLocal8Bit(s);
  return ans;
}

int main(int argc, char** argv) {
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QGuiApplication app(argc, argv);

  caml_main(argv);

  __android_log_print(ANDROID_LOG_INFO, "kamlo", "main");
  QQmlPropertyMap ownerData;

  const QString& msg = doCaml();
  ownerData.insert("name", QVariant(msg));

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("demo", &ownerData);

  engine.load(QUrl(QLatin1String("qrc:/main.qml")));
  return app.exec();
}
