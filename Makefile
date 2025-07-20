# ---------- CONFIG -----------

TOP      ?= mkSpeculaCore
SRC_DIR  ?= src
OUT_DIR  ?= build
EXE      ?= sim

BSC_FLAGS := -sim -p +:src:src/frontend:src/backend

# ---------- TARGETS -----------

.PHONY: all run clean

all: $(OUT_DIR)/$(EXE)

$(OUT_DIR)/$(EXE): $(SRC_DIR)/SpeculaCore.bsv | $(OUT_DIR)
	@echo "[1/3] Compiling $(TOP)"
	bsc $(BSC_FLAGS) -u -g $(TOP) -bdir $(OUT_DIR) -info-dir $(OUT_DIR) $(SRC_DIR)/SpeculaCore.bsv
	@echo "[2/3] Elaborating"
	bsc $(BSC_FLAGS) -e $(TOP) -bdir $(OUT_DIR) -info-dir $(OUT_DIR) -o $(OUT_DIR)/$(EXE)

run: all
	@echo "[3/3] Running simulation"
	./$(OUT_DIR)/$(EXE)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

clean:
	rm -rf $(OUT_DIR)