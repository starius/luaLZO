
T = .
include $T/Rules.mk

C_SRCS		= minilzo.c luaLZO.c
C_OBJS 		= $(C_SRCS:.c=.o)
C_DEPS		= $(C_SRCS:.c=.d)
LIBNAME		= luaLZO
SLIB			= $(LIB_PREFIX)$(LIBNAME)$(STATICLIB_SUFFIX)
DLIB			= $(LIBNAME)$(SHLIB_SUFFIX)
PLIBS		  = -llua -llualib


all: staticlib shlib
staticlib: 	$(SLIB) 
shlib:			$(DLIB)

$(C_DEPS): $(C_SRCS)
-include $(C_DEPS)

$(SLIB): $(C_OBJS)
$(DLIB): $(C_OBJS)
	$(PLUG_LINK_CMD)

distclean: clean
	$(RM) $(C_DEPS)

clean:
	$(RM) $(SLIB) $(DLIB) $(C_OBJS)

test: test.lua $(DLIB)
	OS=$(OS) lua test.lua

.PHONY: test staticlib shlib

