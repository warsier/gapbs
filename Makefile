# See LICENSE.txt for license details.
LLVM_HOME = /usr/lib/llvm-7
CXX = $(LLVM_HOME)/bin/clang++
OPT = $(LLVM_HOME)/bin/opt
# CXX = clang++-7
# OPT = opt-7
PAR_FLAG = -fopenmp
CXX_FLAGS += -std=c++11 -fPIC -O3  $(PAR_FLAG)
EMITBC_CXX_FLAGS = $(CXX_FLAGS) -flto

KERNELS = bc bfs cc cc_sv pr sssp tc
SUITE = $(KERNELS) converter
TESTING = 
#	for i in $$(SUITE) ; do \
#		TESTING = $$(TESTING) $$(i).greedy.test $$(i).offload.test $$(i).cpu.test $$(i).pim.test; \
#	done 

.PHONY: all testing
all: $(SUITE) $(TESTING)

testing: bfs.greedy.test bfs.offload.test bfs.cpu.test bfs.pim.test
out: $(addsuffix .out,$(KERNELS))

%.greedy.test : %.greedy.bc ../PIMProf/TestCase/PIMProfOffloader.bc
	$(CXX) $(CXX_FLAGS) $^ -o $@

%.offload.test : %.offload.bc ../PIMProf/TestCase/PIMProfOffloader.bc
	$(CXX) $(CXX_FLAGS) $^ -o $@

%.cpu.test : %.cpu.bc ../PIMProf/TestCase/PIMProfOffloader.bc
	$(CXX) $(CXX_FLAGS) $^ -o $@

%.pim.test : %.pim.bc ../PIMProf/TestCase/PIMProfOffloader.bc
	$(CXX) $(CXX_FLAGS) $^ -o $@

% : %.out.bc ../PIMProf/TestCase/PIMProfAnnotator.bc
	$(CXX) $(CXX_FLAGS) $^ -o $@

%.out.bc: src/%.cc src/*.h
	$(CXX) $(EMITBC_CXX_FLAGS) -c $< -o $@
	$(OPT) -load ../PIMProf/build/LLVMAnalysis/libAnnotatorInjection.so -AnnotatorInjection $@ -o $@
	../PIMProf/build/LLVMAnalysis/CFGDump.exe $@ -o basicblock.out

%.greedy.bc: src/%.cc src/*.h
	$(CXX) $(EMITBC_CXX_FLAGS) -c $< -o $@
	$(OPT) -load ../PIMProf/build/LLVMAnalysis/libOffloaderInjection.so -OffloaderInjection $@ -o $@ -decision=greedy_decision.txt > /dev/null

%.offload.bc: src/%.cc src/*.h
	$(CXX) $(EMITBC_CXX_FLAGS) -c $< -o $@
	$(OPT) -load ../PIMProf/build/LLVMAnalysis/libOffloaderInjection.so -OffloaderInjection $@ -o $@ -decision=offload_decision.txt > instruction_dump.ll

%.cpu.bc: src/%.cc src/*.h
	$(CXX) $(EMITBC_CXX_FLAGS) -c $< -o $@
	$(OPT) -load ../PIMProf/build/LLVMAnalysis/libOffloaderInjection.so -OffloaderInjection $@ -o $@ -CPU > /dev/null

%.pim.bc: src/%.cc src/*.h
	$(CXX) $(EMITBC_CXX_FLAGS) -c $< -o $@
	$(OPT) -load ../PIMProf/build/LLVMAnalysis/libOffloaderInjection.so -OffloaderInjection $@ -o $@ -PIM > /dev/null

# Testing
include test/test.mk

# Benchmark Automation
include benchmark/bench.mk


.PHONY: clean
clean:
	rm -f $(SUITE) test/out/* *.out *.bc *.test
