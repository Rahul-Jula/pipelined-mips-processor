///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Testbench for 5-Stage Pipelined MIPS processor (SystemVerilog)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module testbench ();

    logic        clk;

    logic        reset;

    logic [31:0] writedata, dataadr;

    logic        memwrite;



    integer i;

    integer errors;



    localparam int N = 2;

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

        expected_data[1] = 32'h00000007;

        expected_addr[1] = 32'h00000050;



        expected_data[2] = 32'h00000007;

        expected_addr[2] = 32'h00000054;

    end



    always begin

        clk = 1'b0;

        #5;

        clk = 1'b1;

        #5;

    end



    initial begin

        $dumpfile("simulation.vcd");

        $dumpvars(0, testbench);

`ifdef FSDB

        $fsdbDumpfile("simulation.fsdb");

        $fsdbDumpvars(0, testbench);

`endif

    end



    initial begin

        errors = 0;

        reset = 1'b1;

        @(posedge clk);

        @(posedge clk);

        #1;

        reset = 1'b0;

        $display("[TB] --- Starting Simulation of 5-Stage Pipelined MIPS ---");



        for (i = 1; i <= N; i = i + 1) begin

            @(posedge memwrite);

            @(negedge clk);



            if (dataadr === expected_addr[i] && writedata === expected_data[i]) begin

                $display("[TB PASS] Memory write %0d successful: wrote %h to address %h (time = %0t)",

                         i, writedata, dataadr, $time);

            end else begin

                $display("[TB FAIL] Memory write %0d: wrote %h to address %h | Expected %h to address %h (time = %0t)",

                         i, writedata, dataadr, expected_data[i], expected_addr[i], $time);

                errors = errors + 1;

            end

        end



        repeat (5) @(posedge clk);



        $display("-----------------------------------------------------------------");

        if (errors == 0) begin

            $display("[TB COMPLETE] ALL %0d MEMORY WRITES MATCHED EXPECTED VALUES!", N);

        end else begin

            $display("[TB COMPLETE] FAILED WITH %0d MISMATCHES!", errors);

        end

        $display("-----------------------------------------------------------------");

        $finish;

    end



    initial begin

        #5000;

        $display("[TB ERROR] Simulation timeout reached!");

        $finish;

    end



endmodule
