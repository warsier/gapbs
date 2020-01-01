# See LICENSE.txt for license details.
CXX = /usr/bin/clang++-7
OPT = /usr/bin/opt-7
PIMPROF_ROOT = /home/warsier/Documents/PIMProf/

CXX_FLAGS = -std=c++11 -O3 -Wall -fopenmp -g -march=skylake-avx512 -I$(PIMPROF_ROOT)/LLVMAnalysis
CXX_FLAGS_2 = -std=c++11 -O3 -Wall -g -I$(PIMPROF_ROOT)/LLVMAnalysis
CXX_INJ_FLAGS = $(CXX_FLAGS) -Xclang -load -Xclang $(PIMPROF_ROOT)/build/LLVMAnalysis/libAnnotationInjection.so
CXX_OFF_FLAGS += $(CXX_FLAGS) -Xclang -load -Xclang $(PIMPROF_ROOT)/build/LLVMAnalysis/libOffloaderInjection.so
LD_FLAGS = -L$(PIMPROF_ROOT)/build/LLVMAnalysis -Wl,-rpath=$(PIMPROF_ROOT)/build/LLVMAnalysis -lPIMProfAnnotation -lzsimhooks

KERNELS = bc bfs cc cc_sv pr sssp tc
SUITE = $(KERNELS) converter
SUITE_ZSIM = $(SUITE:=.zsim)
SUITE_FINAL = $(SUITE:=.final)

.PHONY: all
all: $(SUITE)

zsim: $(SUITE_ZSIM)

final: $(SUITE_FINAL)

%.ll2 : src/%.cc src/*.h
	$(CXX) $(CXX_FLAGS_2) -S -emit-llvm $< -o $@

%.ll : src/%.cc src/*.h
	$(CXX) $(CXX_FLAGS) -S -emit-llvm $< -o $@

% : src/%.cc src/*.h
	$(CXX) $(CXX_INJ_FLAGS) $< -o $@ $(LD_FLAGS)

%.zsim : src/%.cc src/*.h
	$(CXX) $(CXX_FLAGS) -DZSIM=1 $< -o $@ $(LD_FLAGS)

%.cpu : src/%.cc src/*.h
	export PIMPROFDECISION=$(shell pwd)/gapbs-32/$(@:.cpu=_defaultconfig_32.out) && export PIMPROFROI=CPUONLY && $(CXX) $(CXX_OFF_FLAGS) $< -o $@ $(LD_FLAGS) > $(@:.cpu=.cpu.dump) 2>&1

%.pim : src/%.cc src/*.h
	export PIMPROFDECISION=$(shell pwd)/gapbs-32/$(@:.pim=_defaultconfig_32.out) && export PIMPROFROI=PIMONLY && $(CXX) $(CXX_OFF_FLAGS) $< -o $@ $(LD_FLAGS) > $(@:.pim=.pim.dump) 2>&1

%.final : src/%.cc src/*.h
	export PIMPROFDECISION=$(shell pwd)/gapbs-32/$(@:.final=_defaultconfig_32.out) && export PIMPROFROI=DEFAULT && $(CXX) $(CXX_OFF_FLAGS) $< -o $@ $(LD_FLAGS) > $(@:.final=.default.dump) 2>&1

# Testing
include test/test.mk

# Benchmark Automation
include benchmark/bench.mk


.PHONY: clean
clean:
	rm -f $(SUITE) $(SUITE:=.ll) $(SUITE_ZSIM) $(SUITE_FINAL) *.cpu *.pim *.dump test/out/*
