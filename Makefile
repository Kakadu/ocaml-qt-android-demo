#NDK=/home/kakadu/prog/qt/android-ndk-r13b
#NDK=$(system opam config var prefix)/android-ndk
NDK=/home/kakadu/.opam/android-qt/android-ndk
SDK=/home/kakadu/prog/qt/android-sdk-linux
NDK_PLATFORM=android-21# Lollipop 5.0

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
	-I$(NDK)/platforms/$(NDK_PLATFORM)/arch-arm/usr/include -I../qt_off/5.7/android_armv7/mkspecs/android-g++
QT_DEFINES=-DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB
QT_LINK_FLAGS=-L$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a \
  -L$(NDK)/platforms/$(NDK_PLATFORM)/arch-arm//usr/lib \
	-L`qmake -query QT_INSTALL_LIBS` -lQt5Quick \
	-lQt5Gui -lQt5Qml -lQt5Network -lQt5Core -lGLESv2 \
#	-L/opt/android/ndk/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a \
#	-L/opt/android/ndk/platforms/android-9/arch-arm//usr/lib \

OCAMLOPT=ocamlfind -toolchain android opt
OCAML_INCLUDES=-I`ocamlfind -toolchain android opt -where`
OCAML_LINK_FLAGS=-L`ocamlfind -toolchain android opt -where` -lasmrun

OUT=libtest-android2.so
.PHONY: kamlo lib apk deploy
.SUFFIXES: .cpp .o .ml .cmo .cmx .mli .qrc .qml
all: kamlo lib apk deploy

lib: main.o qrc_qml.cpp qrc_qml.o kamlocode.o $(OUT)
main.o: main.cpp
	$(CC) -c $(CXXFLAGS) $(QT_DEFINES) $(QT_INCLUDES) $(OCAML_INCLUDES) -o $@ $^

qrc_qml.cpp: main.qml  Page1Form.ui.qml  Page1.qml
qrc_qml.cpp: qml.qrc
	$(RCC) -name qml $< -o $@

qrc_qml.o: qrc_qml.cpp
	$(CC) -c $(CXXFLAGS) $(QT_DEFINES) $(QT_INCLUDES) -o $@ $<

OBJECTS=main.o qrc_qml.o kamlocode.o
$(OUT):
	$(CC) --sysroot=$(NDK)/platforms/$(NDK_PLATFORM)/arch-arm/ -Wl,-soname,$(OUT) \
	-Wl,-rpath=`qmake -query QT_INSTALL_LIBS` -Wl,--no-undefined -Wl,-z,noexecstack -shared -o $@ \
	$(OBJECTS) \
	$(QT_LINK_FLAGS) $(OCAML_LINK_FLAGS) -lgnustl_shared -llog -lz -lm -ldl -lc -lgcc

kamlo.cmx: kamlo.ml
	$(OCAMLOPT) -c $^ -o $@

kamlocode.o: kamlo.cmx
	$(OCAMLOPT) -o $@ $^ -output-obj -dstartup -linkpkg -linkall

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
