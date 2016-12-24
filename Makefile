BIN?=bin
EXT?=exe

DFLAGS?="-Iapi/native"
LINK?=clang

all: $(BIN)/full.$(EXT) $(BIN)/test-full.$(EXT)

clean:
	rm -rf $(BIN)

$(BIN)/%.$(EXT): $(BIN)/%.bc
	@mkdir -p $(dir $@)
	$(LINK) $(CFLAGS) $(LDFLAGS) -w $^ -o "$@" -lSDL

$(BIN)/%.bc: %.d
	@mkdir -p $(dir $@)
	ldc2 $(DFLAGS) -release -boundscheck=off -Isrc -Irt $< -c -output-bc -of$@

$(BIN)/%.bc: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -c -emit-llvm -o "$@"

$(BIN)/full.bc: \
	$(BIN)/src/main.bc \
	$(BIN)/src/game.bc \
	$(BIN)/src/vec.bc \
	$(BIN)/src/draw.bc \
	$(BIN)/rt/runtime.bc \
	$(BIN)/rt/standard.bc \
	$(BIN)/rt/object.bc
	@mkdir -p $(dir $@)
	llvm-link -o "$@" $^

