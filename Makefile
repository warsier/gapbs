# See LICENSE.txt for license details.
CXX = /usr/bin/clang++-7
OPT = /usr/bin/opt-7
PIMPROF_ROOT = /home/warsier/Documents/PIMProf/

CXX_FLAGS = -std=c++11 -O3 -Wall -fopenmp -g -march=skylake-avx512
CXX_INJ_FLAGS = $(CXX_FLAGS) -Xclang -load -Xclang $(PIMPROF_ROOT)/build/LLVMAnalysis/libAnnotationInjection.so
CXX_OFF_FLAGS += $(CXX_FLAGS) -Xclang -load -Xclang $(PIMPROF_ROOT)/build/LLVMAnalysis/libAnnotationInjection.so -Xclang -decision=$(@:.ll=_23.decision.out) 
LD_FLAGS = -L$(PIMPROF_ROOT)/build/LLVMAnalysis -Wl,-rpath=$(PIMPROF_ROOT)/build/LLVMAnalysis -lPIMProfAnnotation

KERNELS = bc bfs cc cc_sv pr sssp tc
SUITE = $(KERNELS) converter
SUITE_LL = $(SUITE:=.ll)

.PHONY: all
all: $(SUITE) $(SUITE_LL)

% : src/%.cc src/*.h
	$(CXX) $(CXX_INJ_FLAGS) $< -o $@ $(LD_FLAGS)

%.ll : src/%.cc src/*.h
	$(CXX) $(CXX_INJ_FLAGS) -S -emit-llvm -o $@ $<
	$(OPT) -load $(PIMPROF_ROOT)/build/LLVMAnalysis/libOffloaderInjection.so -OffloaderInjection -decision=$(@:.ll=.decision_23.out) -S $@ -o $@ > $(@:.ll=.dump) 2>&1

# Testing
include test/test.mk

# Benchmark Automation
include benchmark/bench.mk


.PHONY: clean
clean:
	rm -f $(SUITE) $(SUITE:=.ll) test/out/*
