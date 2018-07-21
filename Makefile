#NDK=/home/kakadu/prog/qt/android-ndk-r13b
#NDK=$(system opam config var prefix)/android-ndk
NDK=/home/kakadu/.opam_android/4.04.0+32bit/android-ndk
SDK=/home/kakadu/prog/qt/android-sdk-tools_r25.2.5
# Lollipop    5.0 21
# Marshmallow 6.x 23
ANDROID_API_LEVEL=23
NDK_PLATFORM=android-$(ANDROID_API_LEVEL)

CC=$(NDK)/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-g++
QT_BIN=$(shell qmake -query QT_INSTALL_BINS)
RCC=$(QT_BIN)/rcc
CXXFLAGS=-Wno-psabi -march=armv7-a -mfloat-abi=softfp -mfpu=vfp \
  -ffunction-sections -funwind-tables -fstack-protector \
	-fno-short-enums -DANDROID -Wa,--noexecstack -fno-builtin-memmove \
  -std=c++11 -O2 -Os -fomit-frame-pointer -fno-strict-aliasing \
	-finline-limit=64 -mthumb -Wall -Wno-psabi -W -D_REENTRANT -fPIE -pie

QT_INCLUDES=-I. \
  -I`qmake -query QT_INSTALL_HEADERS` \
	-I`qmake -query QT_INSTALL_HEADERS`/QtQuick \
	-I`qmake -query QT_INSTALL_HEADERS`/QtGui \
	-I`qmake -query QT_INSTALL_HEADERS`/QtQml \
	-I`qmake -query QT_INSTALL_HEADERS`/QtNetwork \
	-I`qmake -query QT_INSTALL_HEADERS`/QtCore \
	-I$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/include \
	-I$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a/include \
	-I$(NDK)/platforms/$(NDK_PLATFORM)/arch-arm/usr/include \
  -I`qmake -query QT_INSTALL_HEADERS`/mkspecs/android-g++

QT_DEFINES=-DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB
QT_LINK_FLAGS=\
  -L$(NDK)/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a \
  -L$(NDK)/platforms/$(NDK_PLATFORM)/arch-arm//usr/lib \
	-L`qmake -query QT_INSTALL_LIBS` \
	-lQt5Quick -lQt5Gui -lQt5Qml -lQt5Network -lQt5Core -lGLESv2 \
#	-L/opt/android/ndk/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a \
#	-L/opt/android/ndk/platforms/android-9/arch-arm//usr/lib \

OCAMLOPT=ocamlfind -toolchain android opt -ccopt -fPIC -ccopt -pic
OCAMLC=  ocamlfind -toolchain android c   -ccopt -fPIC #-ccopt -pic
OCAML_INCLUDES=-I`ocamlfind -toolchain android opt -where`
OCAML_OPTLINK_FLAGS=-L`ocamlfind -toolchain android opt -where` -lasmrun
OCAML_BYTELINK_FLAGS=-L`ocamlfind -toolchain android c  -where` -lcamlrun

OUT=libtest-android2.so
.PHONY: kamlo lib apk deploy celan
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
	$(QT_LINK_FLAGS) $(OCAML_BYTELINK_FLAGS) \
	-lgnustl_shared -llog -lz -lm -ldl -lc -lgcc

kamlo.cmx: kamlo.ml
	$(OCAMLOPT) -c $^ -o $@

kamlo.cmo: kamlo.ml
	$(OCAMLC) -c $^ -o $@

kamlocode.o: kamlo.cmo
	$(OCAMLC) -o $@ $^ -custom -output-obj -linkpkg -linkall

JSON_CONFIG_NAME=android-libtest-android2.so-deployment-settings.json
apk:
	@mkdir -p ./android-build/libs/armeabi-v7a/
	install -m 755 -p $(OUT) ./android-build/libs/armeabi-v7a/$(OUT)
	`qmake -query QT_INSTALL_BINS`/androiddeployqt --verbose \
  --input $(JSON_CONFIG_NAME) \
	--output ./android-build \
	--deployment bundled \
	--android-platform $(NDK_PLATFORM) \
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

celan: clean
clean:
	$(RM) -r *.o *.so *.cm[ioxa] qrc_qml.cpp ./android-build kamlocode.o.startup.s


###################################################################
.PHONY: opam_conf config $(JSON_CONFIG_NAME)
opam_conf:
	ARCH=arm SUBARCH=armv7 SYSTEM=linux_eabi \
		CCARCH=arm TOOLCHAIN=arm-linux-androideabi-4.9 \
	  TRIPLE=arm-linux-androideabi LEVEL=$(ANDROID_API_LEVEL) \
	  STLVER=4.9 STLARCH=armeabi \
		opam install conf-android

# JSON config for building android APK
config: $(JSON_CONFIG_NAME)
$(JSON_CONFIG_NAME):
	cat json.template | sed \
		-e "s~QT~$(shell qmake -query QT_HOST_PREFIX)~" \
		-e "s/SDKVERSION/25.2.5/" \
		-e "s~SDKPATH~$(SDK)~" \
		-e "s/SDKBUILDTOOLSVERSION/21.1.2/" \
		-e "s~NDKPATH~$(NDK)~" \
			> $@
