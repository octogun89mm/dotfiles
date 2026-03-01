CC      ?= gcc
CFLAGS  ?= -Wall -Wextra -Wshadow -Wformat-truncation -Wno-unused-result -O2
LDFLAGS ?=
LIBS    = -lpthread -lm

TARGET  = eww-bar
SRCDIR  = src
VENDIR  = vendor

SRCS = $(wildcard $(SRCDIR)/*.c) $(VENDIR)/cJSON.c
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(SRCDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(VENDIR)/%.o: $(VENDIR)/%.c
	$(CC) $(CFLAGS) -Wno-unused-parameter -c -o $@ $<

clean:
	rm -f $(SRCDIR)/*.o $(VENDIR)/*.o $(TARGET)

.PHONY: all clean
