NDK=/home/kakadu/prog/qt/android-ndk-r13b
SDK=/home/kakadu/prog/qt/android-sdk-linux

CC=$(NDK)/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-g++
QT_BIN=$(shell qmake -query QT_INSTALL_BINS)
RCC=$(QT_BIN)/rcc
CXXFLAGS=-Wno-psabi -march=armv7-a -mfloat-abi=softfp -mfpu=vfp -ffunction-sections -funwind-tables -fstack-protector \
	-fno-short-enums -DANDROID -Wa,--noexecstack -fno-builtin-memmove -std=c++11 -O2 -Os -fomit-frame-pointer -fno-strict-aliasing \
	-finline-limit=64 -mthumb -Wall -Wno-psabi -W -D_REENTRANT -fPIC
QT_INCLUDES=-I. -I`qmake -query QT_INSTALL_HEADERS` \
	-I`qmake -query QT_INSTALL_HEADERS`/QtQuick \
	-I`qmake -query QT_INSTALL_HEADERS`/QtGui \
	-I`qmake -query QT_INSTALL_HEADERS`/QtQml \
	-I`qmake -query QT_INSTALL_HEADERS`/QtNetwork \
	-I`qmake -query QT_INSTALL_HEADERS`/QtCore \
	-I. \
	-I$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/include \
	-I$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a/include \
	-I$(NDK)/platforms/android-9/arch-arm/usr/include -I../qt_off/5.7/android_armv7/mkspecs/android-g++

QT_LINK_FLAGS=-L/home/kakadu/prog/qt/android-ndk-r13b/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a -L/home/kakadu/prog/qt/android-ndk-r13b/platforms/android-9/arch-arm//usr/lib -L/home/kakadu/prog/qt/qt_off/5.7/android_armv7/lib -lQt5Quick -L/opt/android/ndk/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a -L/opt/android/ndk/platforms/android-9/arch-arm//usr/lib -lQt5Gui -lQt5Qml -lQt5Network -lQt5Core -lGLESv2

OUT=libtest-android2.so
.PHONY: kamlo lib deploy
.SUFFIXES: .cpp .o .ml .cmo .cmx .mli .qrc
all: kamlo lib apk deploy

lib: main.o qrc_qml.cpp qrc_qml.o $(OUT)
main.o:
	$(CC) -c $(CXXFLAGS) -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB $(QT_INCLUDES)   \
	-o main.o main.cpp
qrc_qml.cpp: qml.qrc
	$(RCC) -name qml qml.qrc -o qrc_qml.cpp

qrc_qml.o: qrc_qml.cpp
	$(CC) -c $(CXXFLAGS) -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB $(QT_INCLUDES)   \
	-o $@ $<
$(OUT):
	$(CC) --sysroot=$(NDK)/platforms/android-9/arch-arm/ -Wl,-soname,$(OUT) -Wl,-rpath=/home/kakadu/prog/qt/qt_off/5.7/android_armv7/lib -Wl,--no-undefined -Wl,-z,noexecstack -shared -o $@ main.o qrc_qml.o   $(QT_LINK_FLAGS) -lgnustl_shared -llog -lz -lm -ldl -lc -lgcc
kamlo:

apk:
	@mkdir -p ./android-build/libs/armeabi-v7a/
	install -m 755 -p $(OUT) ./android-build/libs/armeabi-v7a/$(OUT)
	`qmake -query QT_INSTALL_BINS`/androiddeployqt --input android-libtest-android2.so-deployment-settings.json \
	--output ./android-build \
	--deployment bundled \
	--android-platform android-22 \
	--jdk /usr/lib/jvm/java-8-openjdk-amd64 \
	--ant /usr/bin/ant

deploy:
	$(SDK)/platform-tools/adb install -r ./android-build/bin/QtApp-debug.apk
	#-r means reinstall

# look for the right IDs in the output of
# $(SDK)/build-tools/25.0.1/aapt dump badging android-build/bin/QtApp-debug.apk
#     package: name='org.qtproject.example.test_android2'
#     launchable-activity: name='org.qtproject.qt5.android.bindings.QtActivity'
run:
	$(SDK)/platform-tools/adb shell am start -n org.qtproject.example.test_android2/org.qtproject.qt5.android.bindings.QtActivity

clean:
	$(RM) -r *.o *.so *.cm[ioxa] qrc_qml.cpp ./android-build
