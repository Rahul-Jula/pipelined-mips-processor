//////////////////////////////////////////////////////////////////////

// Controller module (SystemVerilog)

// Submodules:

// 1. controller

// 2. maindec

// 3. aludec

//////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps



module controller (

    input  logic [5:0] op,

    input  logic [5:0] funct,

    output logic       memtoreg,

    output logic       memwrite,

    output logic       branch,

    output logic       alusrc,

    output logic       regdst,

    output logic       regwrite,

    output logic       jump,

    output logic [2:0] alucontrol

);

    logic [1:0] aluop;



    maindec md (

        .op(op),

        .memtoreg(memtoreg),

        .memwrite(memwrite),

        .branch(branch),

        .alusrc(alusrc),

        .regdst(regdst),

        .regwrite(regwrite),

        .jump(jump),

        .aluop(aluop)

    );



    aludec ad (

        .funct(funct),

        .aluop(aluop),

        .alucontrol(alucontrol)

    );



endmodule





//////////////////////////////////////////////////////////////////////

// Main Decoder module

//////////////////////////////////////////////////////////////////////

module maindec (

    input  logic [5:0] op,

    output logic       memtoreg,

    output logic       memwrite,

    output logic       branch,

    output logic       alusrc,

    output logic       regdst,

    output logic       regwrite,

    output logic       jump,

    output logic [1:0] aluop

);

    logic [8:0] controls;



    assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop} = controls;



    always_comb begin

        case (op)

            6'b000000: controls = 9'b110000010; // R-type (add, sub, and, or, slt)

            6'b100011: controls = 9'b101001000; // LW

            6'b101011: controls = 9'b001010000; // SW

            6'b000100: controls = 9'b000100001; // BEQ

            6'b001000: controls = 9'b101000000; // ADDI

            6'b000010: controls = 9'b000000100; // J

            default:   controls = 9'b000000000; // illegal/nop

        endcase

    end

endmodule





//////////////////////////////////////////////////////////////////////

// ALU Decoder module

//////////////////////////////////////////////////////////////////////

module aludec (

    input  logic [5:0] funct,

    input  logic [1:0] aluop,

    output logic [2:0] alucontrol

);

    always_comb begin

        case (aluop)

            2'b00: alucontrol = 3'b010; // add (lw/sw/addi)

            2'b01: alucontrol = 3'b110; // sub (beq)

            default: begin // R-type

                case (funct)

                    6'b100000: alucontrol = 3'b010; // ADD

                    6'b100010: alucontrol = 3'b110; // SUB

                    6'b100100: alucontrol = 3'b000; // AND

                    6'b100101: alucontrol = 3'b001; // OR

                    6'b101010: alucontrol = 3'b111; // SLT

                    default:   alucontrol = 3'b000; // default/nop

                endcase

            end

        endcase

    end

endmodule
