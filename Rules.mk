
#-----
# Useful GNU Make rules for cross-platform compilation.
# Adrian Perez, 2003
#
# $Id: Rules.mak,v 1.5 2003/04/05 14:58:18 themoebius Exp $
# $RCSfile: Rules.mak,v $
#

# Set safe defaults here
T					?= .
OS				?= $(shell $(SHELL) $T/whatOS.sh)
CC 				:= gcc
AR				?= ar
RANLIB		?= ranlib
CFLAGS		?= -D_$(OS) -D_BUILD $(DEFS) $(WARN) $(OPT)
CPPFLAGS	?= 
WARN			?= -Wall
OPT				?= -O2
RELEASE		?= deploy
RM_R			?= $(RM) -r
CP				?= cp


ifeq "$(RELEASE)" "debug"
DEFS	+= -D_DEBUG
OPT		 = -g -O0 
else
OPT		 = -O3 -fomit-frame-pointer
endif

SHLIB_SUFFIX		:= .so
LIB_PREFIX			:= lib
STATICLIB_SUFFIX:= .a

define PLUG_LINK_CMD
$(LD) -r -o $@-master.o $^
$(LD) -shared -o $@ $@-master.o $(PLIBS)
$(RM) $@-master.o
endef

define SHLIB_LINK_CMD
$(LD) -r -o $@-master.o $^
$(LD) -shared -o $@ $@-master.o
$(RM) $@-master.o
endef

define STATICLIB_LINK_CMD
$(AR) cru $@ $^
-$(RANLIB) $@
endef

ifeq "$(OS)" "WIN32"
#----- begin Win32 stuff ---------------
PREFIX ?= $(shell pwd || cd)

define MKDEPEND
endef
#----- end Win32 stuff -----------------
else
#----- begin generic Unixish stuff -----
PREFIX ?= /usr/local

define MKDEPEND
@echo "regenerating dependencies: $<"
@echo "$(<:.c=.o): $< \\" > $@
@echo `grep '#include.*"' $< | sed 's/#include.*"\(.*\)"/\1/'` >> $@ 
endef
#----- end generic Unixish stuff -------
endif


ifeq "$(OS)" "OSX"
#---- begin OSX ------------------------
SHLIB_SUFFIX	:= .dylib
CPPFLAGS	+= -no-cpp-precomp

define PLUG_LINK_CMD
ld -r -o $@-master.o $^
gcc -bundle -o $@ $@-master.o $(PLIBS)
$(RM) $@-master.o
endef

define SHLIB_LINK_CMD
ld -r -o $@-master.o $^
gcc -dynamiclib -o $@ $@-master.o
$(RM) $@-master.o
endef
#----- end OSX -------------------------
endif


ifeq "$(OS)" "WIN32"
#----- begin WIN32 ---------------------
SHLIB_SUFFIX	:= .dll
LIB_PREFIX		:=

define PLUG_LINK_CMD
dllwrap --no-export-all-symbols -o $@ $^
endef

define SHLIB_LINK_CMD
dllwrap --no-export-all-symbols -o $@ $^
endef
#----- end WIN32 -----------------------
endif



#----- Installation --------------------
libdir = $(PREFIX)/lib
bindir = $(PREFIX)/bin
incdir = $(PREFIX)/include

define DO_INSTALL_HEADERS
echo "install-dir: $(incdir)" >> $T/install.log
mkdir -p $(incdir)
for i in $^ ; do \
	file=$(incdir)/$$i ; \
	echo "install-hdr: $$file" >> $T/install.log ; \
	$(CP) $$i $$file ; \
	chmod 644 $$file ; \
done
endef

define DO_INSTALL_LIBS
echo "install-dir: $(libdir)" >> $T/install.log
mkdir -p $(libdir)
for i in $^ ; do \
	file=$(libdir)/$$i ; \
	echo "install-lib: $$file" >> $T/install.log ; \
	$(CP) $$i $$file ; \
done
endef

define DO_INSTALL_BIN
echo "install-dir: $(bindir)" >> $T/install.log
mkdir -p $(bindir)
for i in $^ ; do \
	file=$(bindir)/$$i ; \
	echo "install-bin: $$file" >> $T/install.log ; \
	$(CP) $$i $$file ; \
	chmod 755 $$file ; \
done
endef

.SUFFIXES:
.SUFFIXES: .d .c .h .o $(SHLIB_SUFFIX) $(STATICLIB_SUFFIX) distfiles


%$(STATICLIB_SUFFIX):
	$(STATICLIB_LINK_CMD)

%$(SHLIB_SUFFIX):
	$(SHLIB_LINK_CMD)

%.d: %.c
	$(MKDEPEND)

.c.d:
	$(MKDEPEND)

distfiles:
	@echo $^

.PHONY: distfiles

