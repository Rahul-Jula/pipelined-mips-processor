////////////////////////////////////////////////////////////////////////////

// Top module (SystemVerilog)

// Contains: top, mips, dmem, imem

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
    
    logic muladdD;
    
    logic perfmonD;

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

        .alucontrol(alucontrolD),
       
        .muladd(muladdD),
        
	.perfmon(perfmonD)

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
        
        .muladdD(muladdD),
        
	.perfmonD(perfmonD),

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
    logic [31:0] RAM [63:0];

    assign rd = RAM[a[31:2]];

    always_ff @(posedge clk) begin
        if (we)
            RAM[a[31:2]] <= wd;
    end
endmodule



module imem (
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    logic [31:0] RAM [63:0];

    initial begin
        $readmemh("memfile.dat", RAM);
    end

    assign rd = RAM[a];
endmodule
