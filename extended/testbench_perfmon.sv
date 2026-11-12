`timescale 1ns/1ps



module testbench_perfmon;



    logic clk;

    logic reset;



    logic [31:0] writedata;

    logic [31:0] dataadr;

    logic memwrite;



    logic [31:0] saved_cycles;

    logic [31:0] saved_instructions;



    logic cycle_seen;

    logic instruction_seen;



    integer timeout_count;



    // Instantiate the pipelined MIPS processor

    top dut (

        .clk(clk),

        .reset(reset),

        .writedata(writedata),

        .dataadr(dataadr),

        .memwrite(memwrite)

    );



    // Clock: 10 ns period

    initial begin

        clk = 0;

        forever #5 clk = ~clk;

    end



    // Reset

    initial begin

        reset = 1;

        cycle_seen = 0;

        instruction_seen = 0;

        saved_cycles = 0;

        saved_instructions = 0;



        #22;

        reset = 0;

    end



    // Generate waveforms

    initial begin

        $fsdbDumpfile("perfmon.fsdb");

        $fsdbDumpvars(0, testbench_perfmon);

    end



    // Monitor memory writes

    always @(negedge clk) begin



        if (!reset && memwrite) begin



            if (dataadr == 32'h00000050) begin



                saved_cycles = writedata;

                cycle_seen = 1;



                $display("[PERFMON] Cycle count = %0d", writedata);



            end



            if (dataadr == 32'h00000054) begin



                saved_instructions = writedata;

                instruction_seen = 1;



                $display("[PERFMON] Instruction count = %0d", writedata);



            end



        end



    end



    // Verify results

    initial begin



        timeout_count = 0;



        wait (cycle_seen && instruction_seen);



        #10;



        $display("--------------------------------------------");

        $display("PERFORMANCE MONITOR TEST RESULTS");

        $display("--------------------------------------------");



        $display("Cycle count       = %0d", saved_cycles);

        $display("Instruction count = %0d", saved_instructions);



       if (saved_cycles == 32'd2 &&

    saved_instructions == 32'd4) begin



            $display("[TB PASS] PERFMON counters returned plausible values!");



        end else begin



            $display("[TB FAIL] PERFMON counter values are invalid!");

            $fatal(1);



        end



        $finish;



    end



    // Timeout protection

    initial begin

        #2000;



        $display("[TB ERROR] PERFMON simulation timeout!");

        $fatal(1);



    end



endmodule
