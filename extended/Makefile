VCS       = vcs
VCS_FLAGS = -sverilog -kdb -debug_access+all -timescale=1ns/1ps -full64 +define+FSDB
DC        = dc_shell-t

SRCS = top.sv controller.sv datapath.sv performance_monitor.sv

.PHONY: all sim sim_forwarding sim_flushing syn verdi clean help

all: sim

sim:
	cp memfile.dat memfile.dat.current 2>/dev/null || true
	$(VCS) $(VCS_FLAGS) $(SRCS) testbench.sv -o simv
	./simv

sim_forwarding:
	cp memfile_forwarding.dat memfile.dat
	$(VCS) $(VCS_FLAGS) $(SRCS) testbench_forwarding.sv -o simv_fwd
	./simv_fwd
	cp memfile.dat.current memfile.dat 2>/dev/null || true

sim_flushing:
	cp memfile_flushing.dat memfile.dat
	$(VCS) $(VCS_FLAGS) $(SRCS) testbench_flushing.sv -o simv_flush
	./simv_flush
	cp memfile.dat.current memfile.dat 2>/dev/null || true

syn:
	$(DC) -f compile_with_sram.tcl

verdi:
	verdi -ssf simulation.fsdb &

clean:
	rm -rf simv simv.* csrc *.daidir ucli.key *.vcd *.fsdb verdiLog nova* DVEfiles
	rm -rf WORK *.rep *.log command.log default.svf


clean:

	rm -rf simv simv.* csrc *.daidir ucli.key *.vcd *.fsdb verdiLog nova* DVEfiles

	rm -rf WORK *.rep *.log command.log default.svf



sim_muladd:

	cp memfile.dat memfile.dat.current

	cp memfile_muladd_forward.dat memfile.dat

	$(VCS) $(VCS_FLAGS) $(SRCS) testbench_muladd.sv -top testbench_muladd -o simv_muladd

	./simv_muladd

	cp memfile.dat.current memfile.dat


sim_perfmon:

	cp memfile.dat memfile.dat.current

	cp memfile_perfmon.dat memfile.dat

	$(VCS) $(VCS_FLAGS) $(SRCS) testbench_perfmon.sv -top testbench_perfmon -o simv_perfmon

	./simv_perfmon

	cp memfile.dat.current memfile.dat
