SRC_DIR := src
OBJ_DIR := obj
HEAD_DIR := include
SHAD_DIR := shaders
TEXT_DIR := textures
CONF_DIR := conf
BIN := spaceporn
BIN_DIR := bin
ALL_DIR := $(BIN_DIR)/all
COV_DIR := $(BIN_DIR)/cov
MAKE_SCRIPTS := scripts/make

SRC_FILES := $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_FILES))

# PREFIX := /usr/local ????
PREFIX := ${PWD}/
ENV_FLAGS := -D'PREFIX="$(PREFIX)"'
LIB_FLAGS := -lX11 -lGL -lGLEW -lpng -lm
OBJ_FLAGS := -Wall -g -I ./$(HEAD_DIR) $(ENV_FLAGS)
ALL_FLAGS := $(LIB_FLAGS)
COV_FLAGS := --coverage $(patsubst %.c, ${PWD}/%.c, $(SRC_FILES)) \
  -I ${PWD}/$(HEAD_DIR) $(LIB_FLAGS) $(ENV_FLAGS)

all: $(ALL_DIR)/$(BIN)

coverage: $(COV_DIR)/$(BIN)

$(ALL_DIR)/$(BIN): $(OBJ_FILES)
	$(CC) -o $@ $^ $(ALL_FLAGS)

$(COV_DIR)/$(BIN):
	mkdir -p $(COV_DIR) && cd $(COV_DIR) && $(CC) $(COV_FLAGS) -o $(BIN)

$(OBJ_DIR)/%.o: init
	$(CC) $(OBJ_FLAGS) -c -o $@ $(patsubst $(OBJ_DIR)/%.o,$(SRC_DIR)/%.c,$@)

init:
	./$(MAKE_SCRIPTS)/init.sh $(PREFIX) $(ALL_DIR) $(OBJ_DIR)

clean:
	./$(MAKE_SCRIPTS)/clean.sh $(OBJ_DIR) $(BIN_DIR)

install: all
