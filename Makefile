LUA_CFLAGS  := $(shell pkg-config lua5.3 --cflags 2>/dev/null || pkg-config lua --cflags)
LUA_LIBS    := $(shell pkg-config lua5.3 --libs 2>/dev/null || pkg-config lua --libs)

CFLAGS=-DSERVERONLY -Dstricmp=strcasecmp -g -Wall -fomit-frame-pointer -fno-strength-reduce -Wno-format-truncation
LDFLAGS = -lm

EXE = qwsv

OBJS = \
    server/sv_init.o \
    server/sv_main.o \
    server/sv_ents.o \
    server/sv_send.o \
    server/sv_move.o \
    server/sv_phys.o \
    server/sv_user.o \
    server/sv_ccmds.o \
    server/sv_nchan.o \
    server/world.o \
    server/sys_unix.o \
    server/model.o \
    server/cmd.o \
    server/common.o \
    server/md4.o \
    server/crc.o \
    server/cvar.o \
    server/mathlib.o \
    server/zone.o \
    server/pmove.o \
    server/pmovetst.o \
    server/net_chan.o \
    server/net_udp.o

PR_OBJS = \
    server/pr_cmds.o \
    server/pr_edict.o \
    server/pr_exec.o

LUA_OBJS = \
    server/lua_cmds.o \
    server/lua_edict.o \
    server/lua_vector.o

ifdef USE_PR1
    OBJS += $(PR_OBJS)
else
    CFLAGS += -DWITH_LUA $(LUA_CFLAGS)
    OBJS += $(LUA_OBJS)
endif

all: $(EXE)

$(EXE) : $(OBJS)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJS) $(LUA_LIBS) $(LDFLAGS) 

qwprogs:
	cd qw && gmqcc -std=qcc

clean:
	$(RM) $(OBJS) $(EXE)
