SRC_DIR := src
OBJ_DIR := obj
HEAD_DIR := include
SHAD_DIR := shaders
TEXT_DIR := textures
BIN := xtelesktop
BIN_DIR := bin
HOST_BIN_DIR := /usr/local/bin
HOST_LOCAL_DIR := ~/.local/bin
SRC_FILES := $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_FILES))
FLAGS := -lX11 -lGL -lGLEW -lpng
CPPFLAGS := -Wall -g -I ./$(HEAD_DIR)

all: directories $(BIN_DIR)/$(BIN)

directories:
	mkdir -p $(OBJ_DIR) $(BIN_DIR)

$(BIN_DIR)/$(BIN): $(OBJ_FILES)
	$(mkdir -p $(BIN_DIR))
	gcc -o $(BIN_DIR)/$(BIN) $^ $(FLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(mkdir -p $(OBJ_DIR))
	gcc $(CPPFLAGS) $(FLAGS) -c -o $@ $<

clean:
	if test -d $(OBJ_DIR); then rm -r $(OBJ_DIR); fi
	if test -f $(BIN_DIR)/$(BIN); then rm -r $(BIN_DIR)/$(BIN); fi
	if test -f $(BIN_DIR)/config.status; then rm -r $(BIN_DIR)/config.status; fi

install: all
	mkdir -p $(HOST_BIN_DIR)
	cp -n $(BIN_DIR)/$(BIN) $(HOST_BIN_DIR)
	chmod 755 $(HOST_BIN_DIR)/$(BIN)
	cp -r $(SHAD_DIR) $(HOST_LOCAL_DIR)
	cp -r $(TEXT_DIR) $(HOST_LOCAL_DIR)
