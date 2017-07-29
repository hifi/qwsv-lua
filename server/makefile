LUA_CFLAGS  := $(shell pkg-config lua5.3 --cflags 2>/dev/null || pkg-config lua --cflags)
LUA_LIBS    := $(shell pkg-config lua5.3 --libs 2>/dev/null || pkg-config lua --libs)

CFLAGS=-DSERVERONLY -Dstricmp=strcasecmp -g -Wall -fomit-frame-pointer -fno-strength-reduce -Wno-format-truncation

EXE = qwsv

OBJS = \
    sv_init.o \
    sv_main.o \
    sv_ents.o \
    sv_send.o \
    sv_move.o \
    sv_phys.o \
    sv_user.o \
    sv_ccmds.o \
    sv_nchan.o \
    world.o \
    sys_unix.o \
    model.o \
    cmd.o \
    common.o \
    md4.o \
    crc.o \
    cvar.o \
    mathlib.o \
    zone.o \
    pmove.o \
    pmovetst.o \
    net_chan.o \
    net_udp.o 

PR_OBJS = $(OBJS) \
    pr_cmds.o \
    pr_edict.o \
    pr_exec.o

PRL_OBJS = $(OBJS) \
    lua_cmds.o \
    lua_edict.o \
    lua_vector.o

LDFLAGS = -lm

all: $(EXE)-lua

$(EXE) : $(PR_OBJS)
	cc $(CFLAGS) -o $(EXE) $(PR_OBJS) $(LDFLAGS) 

$(EXE)-lua : CFLAGS += -DWITH_LUA $(LUA_CFLAGS)
$(EXE)-lua : $(PRL_OBJS)
	cc $(CFLAGS) -o $(EXE) $(PRL_OBJS) $(LDFLAGS) $(LUA_LIBS)

clean:
	rm -f $(PR_OBJS) $(PRL_OBJS) $(EXE) $(EXE)-lua

app:
	make "CFLAGS = -O4 -g -Wall  -I../client  -DSERVERONLY"

profile:
	make "CFLAGS = -g -pg -O -Wall -I../client -DPROFILE"
	cp $(EXE) /LocalApps

.c.o: ; cc -c $(CFLAGS) -o $@ $*.c
.s.o: ; cc -c $(CFLAGS) -o $@ $*.s

