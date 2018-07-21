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

// extern "C" value caml_print_hack(value _msg) {
//   CAMLparam1(_msg);
//   char* msg = String_val(_msg);
//   __android_log_print(ANDROID_LOG_INFO, "kamlo", "fromCaml: %s\n", msg);
//   CAMLreturn(Val_unit);
// }

}

// const QString doCaml() {
//   static value *closure = nullptr;
//   if (closure == nullptr) {
//     closure = caml_named_value("doCaml");
//   }
//   if (closure==nullptr) {
//     __android_log_print(ANDROID_LOG_ERROR, "kamlo", "no closure");
//     return "FUCK";
//   }
//   value b = caml_callback(*closure, Val_unit); // should be a unit
//   char* s = String_val(b);
//   const QString& ans = QString::fromLocal8Bit(s);
//   return ans;
// }

void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
  Q_UNUSED(context);
  __android_log_print(ANDROID_LOG_WARN,    "kamlo", "myMessageOutput");
  QByteArray localMsg = msg.toLocal8Bit();
  auto level = ANDROID_LOG_ERROR;
  switch (type) {
  case QtDebugMsg:
    level = ANDROID_LOG_INFO;
    break;
  case QtInfoMsg:
    level = ANDROID_LOG_INFO;
    break;
  case QtWarningMsg:
    level = ANDROID_LOG_WARN;
    break;
  case QtCriticalMsg:
    level = ANDROID_LOG_ERROR;
    break;
  case QtFatalMsg:
    level = ANDROID_LOG_ERROR;
    abort();
  default:
    Q_ASSERT(false);
  }
  __android_log_print(level, "Qt", "%s", localMsg.constData() );
}

int main(int argc, char** argv) {
  qDebug() << "qDebug" << __FILE__ << __LINE__;
  __android_log_print(ANDROID_LOG_ERROR,   "kamlo", "%s %d", __FILE__, __LINE__);
  __android_log_print(ANDROID_LOG_INFO,    "kamlo", "%s %d", __FILE__, __LINE__);
  __android_log_print(ANDROID_LOG_DEBUG,   "kamlo", "%s %d", __FILE__, __LINE__);
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  qInstallMessageHandler(myMessageOutput);
  QGuiApplication app(argc, argv);
  __android_log_print(ANDROID_LOG_WARN,    "kamlo", "%s %d", __FILE__, __LINE__);

  char * argv1[2];
  argv1[0]="--";
  argv1[1]=NULL;
  caml_startup(argv1);
  //caml_main(argv1);

  __android_log_print(ANDROID_LOG_ERROR, "kamlo", "main");
  QQmlPropertyMap ownerData;

  QString msg = "no OCaml";
  // msg = doCaml();
  __android_log_print(ANDROID_LOG_WARN,    "kamlo", "%s %d", __FILE__, __LINE__);
  ownerData.insert("name", QVariant(msg));

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("demo", &ownerData);

  engine.load(QUrl(QLatin1String("qrc:/main.qml")));
  qDebug() << "qDebug" << __FILE__ << __LINE__;
  return app.exec();
}
