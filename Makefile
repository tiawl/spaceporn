SRC_DIR := src
OBJ_DIR := obj
HEAD_DIR := include
SHAD_DIR := shaders
TEXT_DIR := textures
CONF_DIR := conf
BIN := spaceporn
BIN_DIR := bin
PWD_DIR := ${PWD}
ALL_DIR := $(BIN_DIR)/all
COV_DIR := $(BIN_DIR)/cov

HOST_BIN_DIR := /usr/local/bin
HOST_LOCAL_DIR := ~/.local/bin

SRC_FILES := $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_FILES))

PREFIX := ma variable
ENV_FLAGS := -D'PREFIX="$(PREFIX)"'
OBJ_FLAGS := -Wall -g -I ./$(HEAD_DIR) $(ENV_FLAGS)
ALL_FLAGS := -lX11 -lGL -lGLEW -lpng -lm
COV_FLAGS := --coverage $(patsubst %.c, $(PWD_DIR)/%.c, $(SRC_FILES)) \
  -I $(PWD_DIR)/$(HEAD_DIR) $(ALL_FLAGS)

all: $(ALL_DIR)/$(BIN)

coverage: $(COV_DIR)/$(BIN)

$(ALL_DIR)/$(BIN): $(OBJ_FILES)
	@mkdir -p $(ALL_DIR)
	$(CC) -o $@ $^ $(ALL_FLAGS)

$(COV_DIR)/$(BIN):
	@mkdir -p $(COV_DIR)
	cd $(COV_DIR) && $(CC) $(COV_FLAGS) -o $(BIN)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(OBJ_FLAGS) -c -o $@ $<

clean:
	@if test -d $(OBJ_DIR); then rm -r $(OBJ_DIR); fi
	@if test -d $(BIN_DIR); then rm -r $(BIN_DIR); fi

install: all
	@mkdir -p $(HOST_BIN_DIR) && cp -n $(BIN_DIR)/$(BIN) $(HOST_BIN_DIR) && \
chmod 755 $(HOST_BIN_DIR)/$(BIN) && cp -r $(SHAD_DIR) $(HOST_LOCAL_DIR) && \
cp -r $(TEXT_DIR) $(HOST_LOCAL_DIR)
