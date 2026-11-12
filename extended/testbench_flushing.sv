///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Testbench for BEQ Control Hazard & Pipeline Flushing Verification (SystemVerilog)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module testbench_flushing ();

    logic        clk;

    logic        reset;

    logic [31:0] writedata, dataadr;

    logic        memwrite;



    integer i;

    integer errors;



    localparam int N = 3;

    logic [31:0] expected_data [N:1];

    logic [31:0] expected_addr [N:1];



    top dut (

        .clk(clk),

        .reset(reset),

        .writedata(writedata),

        .dataadr(dataadr),

        .memwrite(memwrite)

    );



    initial begin

        expected_data[1] = 32'h00000000; // 0 (addi $3, $0, 99 was flushed)

        expected_addr[1] = 32'h00000000;



        expected_data[2] = 32'h0000000a; // 10 (target1 executed)

        expected_addr[2] = 32'h00000004;



        expected_data[3] = 32'h0000001e; // 30 (sequential target2 executed)

        expected_addr[3] = 32'h00000008;

    end



    always begin

        clk = 1'b0;

        #5;

        clk = 1'b1;

        #5;

    end



    initial begin

        $dumpfile("simulation_flushing.vcd");

        $dumpvars(0, testbench_flushing);

`ifdef FSDB

        $fsdbDumpfile("simulation_flushing.fsdb");

        $fsdbDumpvars(0, testbench_flushing);

`endif

    end



    initial begin

        errors = 0;

        reset = 1'b1;

        @(posedge clk);

        @(posedge clk);

        #1;

        reset = 1'b0;

        $display("[TB FLUSHING] --- Testing BEQ Control Hazards and Pipeline Flushing ---");



        for (i = 1; i <= N; i = i + 1) begin

            @(posedge memwrite);

            @(negedge clk);



            if (dataadr === expected_addr[i] && writedata === expected_data[i]) begin

                $display("[TB PASS] Memory write %0d successful: wrote %h to address %h",

                         i, writedata, dataadr);

            end else begin

                $display("[TB FAIL] Memory write %0d: wrote %h to address %h | Expected %h to address %h",

                         i, writedata, dataadr, expected_data[i], expected_addr[i]);

                errors = errors + 1;

            end

        end



        repeat (5) @(posedge clk);



        $display("-----------------------------------------------------------------");

        if (errors == 0) begin

            $display("[TB FLUSHING COMPLETE] ALL %0d WRITES MATCHED (PIPELINE FLUSHING VERIFIED)!", N);

        end else begin

            $display("[TB FLUSHING COMPLETE] FAILED WITH %0d MISMATCHES!", errors);

        end

        $display("-----------------------------------------------------------------");

        $finish;

    end



    initial begin

        #5000;

        $display("[TB ERROR] Simulation timeout!");

        $finish;

    end



endmodule
