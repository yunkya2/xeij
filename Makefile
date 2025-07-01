#----------------------------------------------------------------

# Java compiler
ifeq ("$(JAVA_HOME)","")
JAVA_HOME = $(shell readlink -f `which javac` | sed "s:/bin/javac[^/]*$$::")
endif
JAR = $(JAVA_HOME)/bin/jar
JAVA = $(JAVA_HOME)/bin/java
JAVAC = $(JAVA_HOME)/bin/javac
JNI_INCLUDE = $(JAVA_HOME)/include

# classpath separator
ifeq ("$(OS)","Windows_NT")
CP_SEPARATOR = ;
else
CP_SEPARATOR = :
endif

#----------------------------------------------------------------

# C compiler to create shared libraries for Windows
CC = x86_64-w64-mingw32-gcc
CFLAGS = -finput-charset=utf-8 -fexec-charset=utf-8 \
	-std=c11 -pedantic -Wall -Wextra -Winit-self \
	-O3

#----------------------------------------------------------------

# program name
PROGRAM = XEiJ
LOWER_PROGRAM = xeij

# manifest file name
MANIFEST = manifest.txt

# package name
MAIN_PACKAGE = xeij

# main class name
MAIN_CLASS = XEiJ

# class directory name
CLASS_DIR = class

# data directory name
DATA_DIR = data

# jar file names of external libraries
LIBRARY_JAR_1 = jSerialComm-2.11.0.jar

# class names that have native methods
MAIN_NATIVE_1 = NamedPipeInputStream
MAIN_NATIVE_1_1 = NamedPipeInputStream_Win
MAIN_NATIVE_2 = OldSerialPort
MAIN_NATIVE_2_1 = OldSerialPort
MAIN_NATIVE_2_2 = OldSerialPort_SerialInputStream
MAIN_NATIVE_2_3 = OldSerialPort_SerialOutputStream
MAIN_NATIVE_3 = WinDLL
MAIN_NATIVE_5 = ZKeyLEDPort
MAIN_NATIVE = $(MAIN_NATIVE_1)
MAIN_NATIVE += $(MAIN_NATIVE_2)
MAIN_NATIVE += $(MAIN_NATIVE_3)
MAIN_NATIVE += $(MAIN_NATIVE_5)

# native library name
NATIVE_WIN = $(LOWER_PROGRAM)win

# representative file names
REP_CLASS_FILE = $(CLASS_DIR)/$(MAIN_PACKAGE)/$(MAIN_CLASS).class
REP_HEADER_FILE = $(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_1_1).h

# obsolete files
OBSOLETE_FILE_1 = $(MAIN_PACKAGE)/SerialPort.java

#----------------------------------------------------------------

all:
	@echo "Choose from the following"
	@echo "    make gen"
	@echo "        Make for general OS"
	@echo "    make win"
	@echo "        Make for Windows"
	@echo "    make testgen BOOT=... PARAM=\"...\""
	@echo "        Make and run for general OS"
	@echo "    make testwin BOOT=... PARAM=\"...\""
	@echo "        Make and run for Windows"

ifeq ("$(BOOT)","")
BOOT = misc
endif

testgen: gen
	$(JAVA) -jar $(PROGRAM).jar -boot=$(BOOT) $(PARAM)

testwin: win
	$(JAVA) -jar $(PROGRAM).jar -boot=$(BOOT) $(PARAM)

gen:
	@$(MAKE) --no-print-directory $(PROGRAM).jar HEADER_OPTION=""

win:
	@$(MAKE) --no-print-directory $(REP_HEADER_FILE)
	@$(MAKE) --no-print-directory $(PROGRAM).jar HEADER_OPTION="-h $(NATIVE_WIN)"
	@$(MAKE) --no-print-directory $(NATIVE_WIN).dll

#----------------------------------------------------------------

$(PROGRAM).jar: $(MANIFEST) $(REP_CLASS_FILE) $(DATA_DIR)/*
	-rm $@
	$(JAR) cfm $@ $(MANIFEST) -C $(CLASS_DIR) . -C . $(DATA_DIR)/*

$(MANIFEST): Makefile
	echo "Manifest-Version: 1.0" > $@
	echo "Class-Path: . $(LIBRARY_JAR_1)" >> $@
	echo "Main-Class: $(MAIN_PACKAGE)/$(MAIN_CLASS)" >> $@
	echo "Enable-Native-Access: ALL-UNNAMED" >> $@

$(REP_CLASS_FILE): $(MAIN_PACKAGE)/*.java
	@if [ -e $(OBSOLETE_FILE_1) ]; then \
		echo "Obsolete file $(OBSOLETE_FILE_1) should be removed"; \
		exit 1; \
	fi
	-rm -r $(CLASS_DIR)
	-mkdir -p $(CLASS_DIR)/$(MAIN_PACKAGE)
	$(JAVAC) -encoding UTF-8 -cp "$(MAIN_PACKAGE)$(CP_SEPARATOR)$(LIBRARY_JAR_1)" \
		-d $(CLASS_DIR) $(MAIN_PACKAGE)/*.java -Xlint:all,-serial -Xdiags:verbose \
		$(HEADER_OPTION)

$(REP_HEADER_FILE): $(MAIN_NATIVE:%=$(MAIN_PACKAGE)/%.java)
	@$(MAKE) --no-print-directory $(REP_CLASS_FILE) HEADER_OPTION="-h $(NATIVE_WIN)"

#----------------------------------------------------------------

$(NATIVE_WIN).dll: $(NATIVE_WIN)/$(NATIVE_WIN).o
	$(CC) $(CFLAGS) -shared -o $@ $^ -lhid -lsetupapi

$(NATIVE_WIN)/$(NATIVE_WIN).o: $(NATIVE_WIN)/$(NATIVE_WIN).c \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_1_1).h \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_2_1).h \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_2_2).h \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_2_3).h \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_3).h \
		$(NATIVE_WIN)/$(MAIN_PACKAGE)_$(MAIN_NATIVE_5).h
	$(CC) $(CFLAGS) -c -o $@ $< -I$(NATIVE_WIN) -I$(JNI_INCLUDE) -I$(JNI_INCLUDE)/win32

#----------------------------------------------------------------

clean:
	-rm $(PROGRAM).jar
	-rm $(MANIFEST)
	-rm -r $(CLASS_DIR)
	-rm $(NATIVE_WIN).dll
	-rm $(NATIVE_WIN)/*.o
	-rm $(NATIVE_WIN)/*.h

#----------------------------------------------------------------
