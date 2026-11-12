////////////////////////////////////////////////////////////////////////////

// Top module with SRAM macros (SystemVerilog)

////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module top (

    input  logic        clk, reset,

    output logic [31:0] writedata, dataadr,

    output logic        memwrite

);

    logic [31:0] pc, instr, readdata;



    mips mips (

        .clk(clk),

        .reset(reset),

        .pc(pc),

        .instr(instr),

        .memwrite(memwrite),

        .aluout(dataadr),

        .writedata(writedata),

        .readdata(readdata)

    );



    imem imem (

        .a(pc[7:2]),

        .rd(instr)

    );



    dmem dmem (

        .clk(clk),

        .we(memwrite),

        .a(dataadr),

        .wd(writedata),

        .rd(readdata)

    );



endmodule



module mips (

    input  logic        clk, reset,

    output logic [31:0] pc,

    input  logic [31:0] instr,

    output logic        memwrite,

    output logic [31:0] aluout, writedata,

    input  logic [31:0] readdata

);

    logic        memtoregD, memwriteD, branchD, alusrcD, regdstD, regwriteD, jumpD;

    logic [2:0]  alucontrolD;

    logic [31:0] instrD;



    controller c (

        .op(instrD[31:26]),

        .funct(instrD[5:0]),

        .memtoreg(memtoregD),

        .memwrite(memwriteD),

        .branch(branchD),

        .alusrc(alusrcD),

        .regdst(regdstD),

        .regwrite(regwriteD),

        .jump(jumpD),

        .alucontrol(alucontrolD)

    );



    datapath dp (

        .clk(clk),

        .reset(reset),

        .memtoregD(memtoregD),

        .memwriteD(memwriteD),

        .branchD(branchD),

        .alusrcD(alusrcD),

        .regdstD(regdstD),

        .regwriteD(regwriteD),

        .jumpD(jumpD),

        .alucontrolD(alucontrolD),

        .pc(pc),

        .instr(instr),

        .instrD(instrD),

        .memwriteM(memwrite),

        .aluoutM(aluout),

        .writedataM(writedata),

        .readdata(readdata)

    );



endmodule



module dmem (

    input  logic        clk, we,

    input  logic [31:0] a, wd,

    output logic [31:0] rd

);

    logic        csb0;

    logic        web0;

    logic [5:0]  addr0;

    logic [31:0] din0;

    logic [31:0] dout0;



    assign csb0  = 1'b0;

    assign web0  = ~we;

    assign addr0 = a[7:2];

    assign din0  = wd;

    assign rd    = dout0;



    SRAM_32x64_1rw dmem_ram (

        .clk0(clk),

        .csb0(csb0),

        .web0(web0),

        .addr0(addr0),

        .din0(din0),

        .dout0(dout0)

    );



endmodule



module imem (

    input  logic [5:0]  a,

    output logic [31:0] rd

);

    logic        clk0;

    logic        csb0;

    logic        web0;

    logic [5:0]  addr0;

    logic [31:0] din0;

    logic [31:0] dout0;



    assign clk0  = 1'b0;

    assign csb0  = 1'b0;

    assign web0  = 1'b1;

    assign addr0 = a;

    assign din0  = 32'b0;

    assign rd    = dout0;



    SRAM_32x64_1rw imem_ram (

        .clk0(clk0),

        .csb0(csb0),

        .web0(web0),

        .addr0(addr0),

        .din0(din0),

        .dout0(dout0)

    );



endmodule
