CFLAGS= -g

HEADER_FILES = src
SOURCE_FILES = src/captcha.c

OBJECT_FILES = $(SOURCE_FILES:.c=.o)

priv/captcha: clean $(OBJECT_FILES) | priv
	$(CC) -I $(HEADER_FILES) -o $@ $(LDFLAGS) $(OBJECT_FILES) $(LDLIBS)

priv:
	mkdir -p priv

clean:
	rm -f priv/captcha $(OBJECT_FILES) $(BEAM_FILES)
