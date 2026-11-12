///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Testbench for ADD Data Hazard & Forwarding Verification (SystemVerilog)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module testbench_forwarding ();

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

        expected_data[1] = 32'h00000028; // 40

        expected_addr[1] = 32'h00000000;



        expected_data[2] = 32'h0000002d; // 45

        expected_addr[2] = 32'h00000004;



        expected_data[3] = 32'h00000055; // 85

        expected_addr[3] = 32'h00000008;

    end



    always begin

        clk = 1'b0;

        #5;

        clk = 1'b1;

        #5;

    end



    initial begin

        $dumpfile("simulation_forwarding.vcd");

        $dumpvars(0, testbench_forwarding);

`ifdef FSDB

        $fsdbDumpfile("simulation_forwarding.fsdb");

        $fsdbDumpvars(0, testbench_forwarding);

`endif

    end



    initial begin

        errors = 0;

        reset = 1'b1;

        @(posedge clk);

        @(posedge clk);

        #1;

        reset = 1'b0;

        $display("[TB FORWARDING] --- Testing ADD Data Hazards and Forwarding ---");



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

            $display("[TB FORWARDING COMPLETE] ALL %0d WRITES MATCHED (DATA FORWARDING VERIFIED)!", N);

        end else begin

            $display("[TB FORWARDING COMPLETE] FAILED WITH %0d MISMATCHES!", errors);

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
