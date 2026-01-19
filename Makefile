PROJECT = $(notdir $(CURDIR))

SRC_DIR ?= src
SYN_DIR ?= syn
SIM_DIR ?= sim

REGION := ${POST_SIM_REGION}

SOURCE_FILES ?= $(wildcard *.v)
CONSTRAINT_FILES ?= $(wildcard *.sdc)

# ModelSim compilation arguments
VLOG_ARGS ?=
# Exclude the top-level module from post-simulation sourcess
POST_SIM_SOURCES ?= $(filter-out $(PROJECT).v,$(wildcard *.v *.sv)) $(PROJECT).vo

SYNTHESIS_SETTINGS = \
	"SMART_RECOMPILE=ON" \
	"INFER_RAMS_FROM_RAW_LOGIC=OFF" \
	"AUTO_RAM_RECOGNITION=OFF" \
	"AUTO_DSP_RECOGNITION=OFF" \
	"AUTO_SHIFT_REGISTER_RECOGNITION=OFF"

initial:
	@mkdir -p "$(SRC_DIR)"
	@mkdir -p "$(SYN_DIR)"
	@mkdir -p "$(SIM_DIR)"
	@touch "$(SRC_DIR)/${PROJECT}.v"

clean:
	rm -rf sim/*
	rm -rf syn/*

syn:
	@mkdir -p "$(SYN_DIR)"
	@if ls "$(SRC_DIR)"/*.v >/dev/null 2>&1; then cp -f "$(SRC_DIR)"/*.v "$(SYN_DIR)/"; fi
	@if ls "$(SRC_DIR)"/*.sdc >/dev/null 2>&1; then cp -f "$(SRC_DIR)"/*.sdc "$(SYN_DIR)/"; fi
	$(MAKE) -C "$(SYN_DIR)" -f "$(CURDIR)/Makefile" PROJECT="$(PROJECT)" do_syn

sim:
	@mkdir -p "$(SIM_DIR)"
	@cp -f "$(SRC_DIR)"/* "$(SIM_DIR)/"
	$(MAKE) -C "$(SIM_DIR)" -f "$(CURDIR)/Makefile" VLOG_ARGS="$(VLOG_ARGS)" PROJECT="$(PROJECT)" do_pre_sim

post_sim:
	@mkdir -p "$(SIM_DIR)"
	@cp -f "$(SRC_DIR)"/* "$(SIM_DIR)/"
	$(MAKE) -C "$(SIM_DIR)" -f "$(CURDIR)/Makefile" VLOG_ARGS="$(VLOG_ARGS)" PROJECT="$(PROJECT)" do_post_sim

##################################################
# Synthesis step
##################################################
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf

$(ASSIGNMENT_FILES):
	quartus_sh --prepare -f "$(FAMILY)" -d "${DEVICE}" "$(PROJECT)"
	@$(foreach setting,$(SYNTHESIS_SETTINGS), quartus_sh --set $(setting) "$(PROJECT)"; )

do_syn: $(ASSIGNMENT_FILES) $(SOURCE_FILES) $(CONSTRAINT_FILES)
	quartus_sh --flow compile "$(PROJECT)"
	quartus_eda "$(PROJECT)" --simulation --tool=modelsim --format=verilog

##################################################
# Simulation step
##################################################
work/_info:
	vlib work

do_pre_sim: work/_info
	vlog $(wildcard *.v *.sv) $(VLOG_ARGS) -novopt -R -c -do "run -all; quit"

do_post_sim: work/_info $(PROJECT)_v.sdo $(PROJECT).vo
	vlog $(POST_SIM_SOURCES) $(VLOG_ARGS) -novopt -R $(addprefix -L ,$(SIM_LIBS)) -c \
	 -sdftyp $(REGION)=$(PROJECT)_v.sdo -do "run -all; quit"

$(PROJECT)_v.sdo $(PROJECT).vo:
	@cp "../$(SYN_DIR)/simulation/modelsim/$(PROJECT)_v.sdo" .
	@cp "../$(SYN_DIR)/simulation/modelsim/$(PROJECT).vo" .

##################################################
# Phony targets
##################################################
.PHONY: initial clean sim syn post_sim eda check_work do_syn do_pre_sim do_post_sim
