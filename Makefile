CFLAGS= -g

HEADER_FILES = src
SOURCE_FILES = src/captcha.c

OBJECT_FILES = $(SOURCE_FILES:.c=.o)

.PHONY: all compile priv clean

all: compile

compile: priv $(OBJECT_FILES)
	@$(CC) -I $(HEADER_FILES) -o priv/captcha $(LDFLAGS) $(OBJECT_FILES) $(LDLIBS)

priv:
	@mkdir -p priv

clean:
	@rm -f priv/captcha $(OBJECT_FILES)
