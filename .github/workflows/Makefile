ARCHS = arm64 arm64e
TARGET = iphone:clang:17.0:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AimAssist
AimAssist_FILES = Tweak.xm
AimAssist_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
