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

PREFIX := /usr/local/bin/
SPREFIX := /usr/share/$(BIN)/$(SHAD_DIR)/
TPREFIX := /usr/share/$(BIN)/$(TEXT_DIR)/
LOGLEVEL := INFO
FERROR := $(shell ./$(MAKE_SCRIPTS)/erroneous_shader \
  $(SHAD_DIR)/fragment/main.glsl 0)
VERROR := $(shell ./$(MAKE_SCRIPTS)/erroneous_shader \
  $(SHAD_DIR)/vertex/main.glsl 0)
MERROR := $(shell ./$(MAKE_SCRIPTS)/erroneous_shader \
  $(SHAD_DIR)/vertex/main.glsl 1)
LIB_FLAGS := $(shell pkg-config --static --libs gl glx glew x11 libpng \
  libsystemd)
DEV_FLAGS := -Wall -Wextra -g
CFLAGS := $(shell pkg-config --cflags gl glx glew x11 libpng libsystemd) \
  -I./$(HEAD_DIR)
ALL_FLAGS := $(LIB_FLAGS)

all: ENV_FLAGS := -D'GCC_SPREFIX="$(SPREFIX)"' -D'GCC_TPREFIX="$(TPREFIX)"' \
  -D'GCC_DEV=false' -D'GCC_ERRONEOUS_FRAGMENT=$(FERROR)' \
  -D'GCC_ERRONEOUS_VERTEX=$(VERROR)' -D'GCC_MISSINGMAIN_VERTEX=$(MERROR)' \
  -D'GCC_LOGLEVEL=$(LOGLEVEL)' \
  -D'GCC_BRANCH="$(shell git rev-parse --abbrev-ref HEAD)"'
all: OBJ_FLAGS := $(CFLAGS) $(ENV_FLAGS)
all: $(ALL_DIR)/$(BIN)

dev: PREFIX := ${PWD}
dev: SPREFIX := ${PWD}/$(SHAD_DIR)/
dev: TPREFIX := ${PWD}/$(TEXT_DIR)/
dev: LOGLEVEL := ERROR
dev: ENV_FLAGS := -D'GCC_SPREFIX="$(SPREFIX)"' -D'GCC_TPREFIX="$(TPREFIX)"' \
  -D'GCC_DEV=true' -D'GCC_ERRONEOUS_FRAGMENT=$(FERROR)' \
  -D'GCC_ERRONEOUS_VERTEX=$(VERROR)' -D'GCC_MISSINGMAIN_VERTEX=$(MERROR)' \
  -D'GCC_LOGLEVEL=$(LOGLEVEL)' \
  -D'GCC_BRANCH="$(shell git rev-parse --abbrev-ref HEAD)"'
dev: OBJ_FLAGS := $(DEV_FLAGS) $(CFLAGS) $(ENV_FLAGS)
dev: $(ALL_DIR)/$(BIN)

cov: PREFIX := ${PWD}
cov: SPREFIX := ${PWD}/$(SHAD_DIR)/
cov: TPREFIX := ${PWD}/$(TEXT_DIR)/
cov: LOGLEVEL := ERROR
cov:
	./$(MAKE_SCRIPTS)/loglevel $(LOGLEVEL)
cov: ENV_FLAGS := -D'GCC_SPREFIX="$(SPREFIX)"' -D'GCC_TPREFIX="$(TPREFIX)"' \
  -D'GCC_DEV=true' -D'GCC_ERRONEOUS_FRAGMENT=$(FERROR)' \
  -D'GCC_ERRONEOUS_VERTEX=$(VERROR)' -D'GCC_MISSINGMAIN_VERTEX=$(MERROR)' \
  -D'GCC_LOGLEVEL=$(LOGLEVEL)' \
  -D'GCC_BRANCH="$(shell git rev-parse --abbrev-ref HEAD)"'
cov: OBJ_FLAGS := $(DEV_FLAGS) $(CFLAGS) $(ENV_FLAGS)
cov: COV_FLAGS := --coverage $(patsubst %.c, ${PWD}/%.c, $(SRC_FILES)) \
  -I ${PWD}/$(HEAD_DIR) $(LIB_FLAGS) $(ENV_FLAGS)
cov: $(COV_DIR)/$(BIN)

$(ALL_DIR)/$(BIN): $(OBJ_FILES)
	$(CC) -o $@ $^ $(ALL_FLAGS)

$(COV_DIR)/$(BIN):
	mkdir -p $(COV_DIR) && cd $(COV_DIR) && $(CC) $(COV_FLAGS) -o $(BIN)

$(OBJ_DIR)/%.o: init
	$(CC) $(OBJ_FLAGS) -c -o $@ $(patsubst $(OBJ_DIR)/%.o,$(SRC_DIR)/%.c,$@)

init:
	./$(MAKE_SCRIPTS)/init $(PREFIX) $(SPREFIX) $(TPREFIX) $(ALL_DIR) $(OBJ_DIR)

clean:
	./$(MAKE_SCRIPTS)/clean $(OBJ_DIR) $(BIN_DIR)

install:
	./$(MAKE_SCRIPTS)/install
