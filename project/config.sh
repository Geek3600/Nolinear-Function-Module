#!/bin/bash

PROJECT_NAME=nolinear

###########################################
# for tcl flow
###########################################
# device definition
VIVADO_DEVICE=xc7z020
VIVADO_PACKAGE=clg400
VIVADO_SPEED=-2
VIVADO_PART=\$device\$package\$speed

# top module
VIVADO_TOP_MODULES=nolinear

# bd module
VIVADO_BD_TOP_MODULES=

# source files
VIVADO_VERILOG_FILELIST=(
    rtl/systolic_odd_even_sort/sort_controller.v 
    rtl/systolic_odd_even_sort/sort_pe.v 
    rtl/systolic_odd_even_sort/sort4.v 
    rtl/systolic_odd_even_sort/systolic_odd_even_sort.v
    rtl/add.v
    rtl/const_mul.v
    rtl/exp2.v
    rtl/log2.v
    rtl/nolinear.v
    rtl/register.v
    rtl/ru.v
    rtl/selector.v
    rtl/controller.v
    rtl/nolinear_top.v
)
VIVADO_INC_PATH_FILELIST=(
    rtl
)
VIVADO_GLOBAL_INC_FILE_LIST=
VIVADO_XCI_FILELIST=
VIVADO_BD_FILE=
VIVADO_BD_TCL_FILELIST=
VIVADO_XDC_FILELIST=(
)
VIVADO_SIM_FILELIST=(
    tb/tb_nolinear.v
)
VIVADO_POST_SYNTH_SCRIPTS_FILELIST=

# ip repository path
VIVAOD_USER_IP_REPOSITORY=

# synth oprions
VIVADO_SYNTH_OPT="-directive PerformanceOptimized -flatten_hierarchy full -keep_equivalent_registers -retiming"
VIVADO_OPT_OPT=""
VIVADO_PLACE_OPT=""
VIDODO_PHYS_OPT_OPT=""
VIVADO_ROUTE_OPT_OPT=""

###########################################
# for vcs flow
###########################################
VCS_ENABLE=1

# pre-compiled simulation library
VCS_COMPILE_LIB_DIR=/home/hyyuan/vcs_lib

# simulation config
VCS_TIMESCALE="1ns/1ps"

# simulation_mode
# 1. RTL
# 2. POST_SYNTH
VCS_SIM_MODE=RTL

VCS_SIM_TOP_MODULE=tb_${VIVADO_TOP_MODULES}
VCS_FSDB_FILE=${VCS_SIM_TOP_MODULE}.fsdb

###########################################
# for iverilog flow
###########################################
IVERILOG_ENABLE=1

IVERILOG_SIM_TOP_MODULE=tb_${VIVADO_TOP_MODULES}
IVERILOG_VCD_FILE=${VCS_SIM_TOP_MODULE}.vcd