//////////////////////////////////////////////////////////////////////

// Datapath module (SystemVerilog)

// Strictly follows the 9-stage order specified in Lab 2:

// 1. Fetch logic

// 2. Fetch-to-decode pipeline registers

// 3. Decode/RF logic (Including register file and hazard/forwarding logic)

// 4. Decode-to-execute pipeline registers

// 5. Execute logic (Including ALU, forwarding muxes, regdst mux)

// 6. Execute-to-memory pipeline registers

// 7. Memory logic

// 8. Memory-to-writeback pipeline registers

// 9. Writeback logic

//////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module datapath (

    input  logic        clk, reset,

    // Control signals from controller (Decode stage)

    input  logic        memtoregD, memwriteD,

    input  logic        branchD, alusrcD,

    input  logic        regdstD, regwriteD,

    input  logic        jumpD,

    input  logic [2:0]  alucontrolD,

    // Top-level memory interface

    output logic [31:0] pc,

    input  logic [31:0] instr,

    output logic [31:0] instrD,

    output logic        memwriteM,

    output logic [31:0] aluoutM, writedataM,

    input  logic [31:0] readdata

);



    // Hazard Unit signals

    logic        stallF, stallD, flushD, flushE;

    logic        forwardaD, forwardbD;

    logic [1:0]  forwardaE, forwardbE;

    logic        lwstall, branchstall;



    // Fetch signals

    logic [31:0] pcplus4F, pcnext;



    // Decode signals

    logic [31:0] pcplus4D;

    logic [4:0]  rsD, rtD, rdD;

    logic [31:0] signimmD, signimmshD;

    logic [31:0] srcaD, srcbD, srca2D, srcb2D;

    logic [31:0] pcbranchD, pcjumpD;

    logic        equalD, pcsrcD;



    // Execute signals

    logic        regwriteE, memtoregE, memwriteE, alusrcE, regdstE;

    logic [2:0]  alucontrolE;

    logic [31:0] srcaE, srcbE, signimmE;

    logic [4:0]  rsE, rtE, rdE, writeregE;

    logic [31:0] srca2E, writedata2E, srcb2E, aluoutE;

    logic        zeroE;



    // Memory signals

    logic        regwriteM, memtoregM;

    logic [4:0]  writeregM;



    // Writeback signals

    logic        regwriteW, memtoregW;

    logic [31:0] aluoutW, readdataW, resultW;

    logic [4:0]  writeregW;



    // =========================================================================

    // 1. Fetch logic

    // =========================================================================

    assign pcnext = jumpD  ? pcjumpD :

                    pcsrcD ? pcbranchD : pcplus4F;



    always_ff @(posedge clk or posedge reset) begin

        if (reset)

            pc <= 32'b0;

        else if (!stallF)

            pc <= pcnext;

    end



    adder pcadd1 (

        .a(pc),

        .b(32'd4),

        .y(pcplus4F)

    );



    // =========================================================================

    // 2. Fetch-to-decode pipeline registers (IF/ID)

    // =========================================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            instrD   <= 32'b0;

            pcplus4D <= 32'b0;

        end else if (!stallD) begin

            if (flushD) begin

                instrD   <= 32'b0;

                pcplus4D <= 32'b0;

            end else begin

                instrD   <= instr;

                pcplus4D <= pcplus4F;

            end

        end

    end



    // =========================================================================

    // 3. Decode/RF logic (Including register file and hazard/forwarding logic)

    // =========================================================================

    assign rsD = instrD[25:21];

    assign rtD = instrD[20:16];

    assign rdD = instrD[15:11];



    regfile rf (

        .clk(clk),

        .we3(regwriteW),

        .ra1(rsD),

        .ra2(rtD),

        .wa3(writeregW),

        .wd3(resultW),

        .rd1(srcaD),

        .rd2(srcbD)

    );



    signext se (

        .a(instrD[15:0]),

        .y(signimmD)

    );



    sl2 immsh (

        .a(signimmD),

        .y(signimmshD)

    );



    adder pcadd2 (

        .a(pcplus4D),

        .b(signimmshD),

        .y(pcbranchD)

    );



    assign pcjumpD = {pcplus4D[31:28], instrD[25:0], 2'b00};



    // Forwarding to Decode stage for early BEQ comparison

    assign forwardaD = (rsD != 5'b0) && (rsD == writeregM) && regwriteM;

    assign forwardbD = (rtD != 5'b0) && (rtD == writeregM) && regwriteM;



    assign srca2D = forwardaD ? aluoutM : srcaD;

    assign srcb2D = forwardbD ? aluoutM : srcbD;



    assign equalD = (srca2D == srcb2D);

    assign pcsrcD = branchD & equalD;



    // Hazard Detection Logic

    // 1. Load-use data hazard

    assign lwstall = memtoregE & ((rtE == rsD) | (rtE == rtD));



    // 2. Branch data hazard

    assign branchstall = (branchD & regwriteE & ((writeregE == rsD) | (writeregE == rtD))) |

                         (branchD & memtoregM & ((writeregM == rsD) | (writeregM == rtD)));



    assign stallF = lwstall | branchstall;

    assign stallD = lwstall | branchstall;

    assign flushE = lwstall | branchstall;

    assign flushD = pcsrcD | jumpD;



    // =========================================================================

    // 4. Decode-to-execute pipeline registers (ID/EX)

    // =========================================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            regwriteE   <= 1'b0;

            memtoregE   <= 1'b0;

            memwriteE   <= 1'b0;

            alucontrolE <= 3'b000;

            alusrcE     <= 1'b0;

            regdstE     <= 1'b0;

            srcaE       <= 32'b0;

            srcbE       <= 32'b0;

            signimmE    <= 32'b0;

            rsE         <= 5'b0;

            rtE         <= 5'b0;

            rdE         <= 5'b0;

        end else if (flushE) begin

            regwriteE   <= 1'b0;

            memtoregE   <= 1'b0;

            memwriteE   <= 1'b0;

            alucontrolE <= 3'b000;

            alusrcE     <= 1'b0;

            regdstE     <= 1'b0;

            srcaE       <= 32'b0;

            srcbE       <= 32'b0;

            signimmE    <= 32'b0;

            rsE         <= 5'b0;

            rtE         <= 5'b0;

            rdE         <= 5'b0;

        end else begin

            regwriteE   <= regwriteD;

            memtoregE   <= memtoregD;

            memwriteE   <= memwriteD;

            alucontrolE <= alucontrolD;

            alusrcE     <= alusrcD;

            regdstE     <= regdstD;

            srcaE       <= srca2D;

            srcbE       <= srcb2D;

            signimmE    <= signimmD;

            rsE         <= rsD;

            rtE         <= rtD;

            rdE         <= rdD;

        end

    end



    // =========================================================================

    // 5. Execute logic (Including ALU and other logic)

    // =========================================================================

    always_comb begin

        if ((rsE != 5'b0) && (rsE == writeregM) && regwriteM)

            forwardaE = 2'b10; // Forward from Memory stage (aluoutM)

        else if ((rsE != 5'b0) && (rsE == writeregW) && regwriteW)

            forwardaE = 2'b01; // Forward from Writeback stage (resultW)

        else

            forwardaE = 2'b00; // No forwarding

    end



    always_comb begin

        if ((rtE != 5'b0) && (rtE == writeregM) && regwriteM)

            forwardbE = 2'b10; // Forward from Memory stage (aluoutM)

        else if ((rtE != 5'b0) && (rtE == writeregW) && regwriteW)

            forwardbE = 2'b01; // Forward from Writeback stage (resultW)

        else

            forwardbE = 2'b00; // No forwarding

    end



    mux3 #(32) forwardamux (

        .d0(srcaE),

        .d1(resultW),

        .d2(aluoutM),

        .s(forwardaE),

        .y(srca2E)

    );



    mux3 #(32) forwardbmux (

        .d0(srcbE),

        .d1(resultW),

        .d2(aluoutM),

        .s(forwardbE),

        .y(writedata2E)

    );



    mux2 #(32) srcbmux (

        .d0(writedata2E),

        .d1(signimmE),

        .s(alusrcE),

        .y(srcb2E)

    );



    alu alu_inst (

        .a(srca2E),

        .b(srcb2E),

        .control(alucontrolE),

        .result(aluoutE),

        .zero(zeroE)

    );



    mux2 #(5) wrmux (

        .d0(rtE),

        .d1(rdE),

        .s(regdstE),

        .y(writeregE)

    );



    // =========================================================================

    // 6. Execute-to-memory pipeline registers (EX/MEM)

    // =========================================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            regwriteM  <= 1'b0;

            memtoregM  <= 1'b0;

            memwriteM  <= 1'b0;

            aluoutM    <= 32'b0;

            writedataM <= 32'b0;

            writeregM  <= 5'b0;

        end else begin

            regwriteM  <= regwriteE;

            memtoregM  <= memtoregE;

            memwriteM  <= memwriteE;

            aluoutM    <= aluoutE;

            writedataM <= writedata2E;

            writeregM  <= writeregE;

        end

    end



    // =========================================================================

    // 7. Memory logic

    // =========================================================================

    // aluoutM -> dataadr; writedataM -> writedata; memwriteM -> memwrite



    // =========================================================================

    // 8. Memory-to-writeback pipeline registers (MEM/WB)

    // =========================================================================

    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            regwriteW  <= 1'b0;

            memtoregW  <= 1'b0;

            aluoutW    <= 32'b0;

            readdataW  <= 32'b0;

            writeregW  <= 5'b0;

        end else begin

            regwriteW  <= regwriteM;

            memtoregW  <= memtoregM;

            aluoutW    <= aluoutM;

            readdataW  <= readdata;

            writeregW  <= writeregM;

        end

    end



    // =========================================================================

    // 9. Writeback logic

    // =========================================================================

    mux2 #(32) resmux (

        .d0(aluoutW),

        .d1(readdataW),

        .s(memtoregW),

        .y(resultW)

    );



endmodule





//////////////////////////////////////////////////////////////////////

// Helper Modules

//////////////////////////////////////////////////////////////////////

module regfile (

    input  logic        clk,

    input  logic        we3,

    input  logic [4:0]  ra1, ra2, wa3,

    input  logic [31:0] wd3,

    output logic [31:0] rd1, rd2

);

    logic [31:0] rf [31:0];



    always_ff @(posedge clk) begin

        if (we3 && (wa3 != 5'b0))

            rf[wa3] <= wd3;

    end



    assign rd1 = (ra1 == 5'b0) ? 32'b0 :

                 (we3 && (ra1 == wa3)) ? wd3 : rf[ra1];

    assign rd2 = (ra2 == 5'b0) ? 32'b0 :

                 (we3 && (ra2 == wa3)) ? wd3 : rf[ra2];

endmodule



module alu (

    input  logic [31:0] a,

    input  logic [31:0] b,

    input  logic [2:0]  control,

    output logic [31:0] result,

    output logic        zero

);

    localparam logic [2:0] ALU_AND = 3'b000;

    localparam logic [2:0] ALU_OR  = 3'b001;

    localparam logic [2:0] ALU_ADD = 3'b010;

    localparam logic [2:0] ALU_SUB = 3'b110;

    localparam logic [2:0] ALU_SLT = 3'b111;



    always_comb begin

        case (control)

            ALU_AND: result = a & b;

            ALU_OR:  result = a | b;

            ALU_ADD: result = a + b;

            ALU_SUB: result = a - b;

            ALU_SLT: result = {31'b0, ($signed(a) < $signed(b))};

            default: result = 32'b0;

        endcase

    end



    assign zero = (result == 32'b0);

endmodule



module adder (

    input  logic [31:0] a, b,

    output logic [31:0] y

);

    assign y = a + b;

endmodule



module mux2 #(parameter WIDTH = 32) (

    input  logic [WIDTH-1:0] d0, d1,

    input  logic             s,

    output logic [WIDTH-1:0] y

);

    assign y = s ? d1 : d0;

endmodule



module mux3 #(parameter WIDTH = 32) (

    input  logic [WIDTH-1:0] d0, d1, d2,

    input  logic [1:0]       s,

    output logic [WIDTH-1:0] y

);

    always_comb begin

        case (s)

            2'b00:   y = d0;

            2'b01:   y = d1;

            2'b10:   y = d2;

            default: y = d0;

        endcase

    end

endmodule



module sl2 (

    input  logic [31:0] a,

    output logic [31:0] y

);

    assign y = {a[29:0], 2'b00};

endmodule



module signext (

    input  logic [15:0] a,

    output logic [31:0] y

);

    assign y = {{16{a[15]}}, a};

endmodule
