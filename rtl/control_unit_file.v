module control_unit(
    input [6:0] opcode,
    input [2:0] funct3,   
    input funct7_5,       
    output reg reg_we,
    output reg alu_src,   // 0 : rs2, 1 : immédiat
    output reg mem_we,
    output reg [2:0] alu_ctrl,
    output reg mem_to_reg,
    output reg branch,
    output reg jal,
    output reg jalr,
    output reg pc_to_reg
);


always @(*) begin
    reg_we     = 0;
    alu_src    = 0;
    mem_we     = 0;
    mem_to_reg = 0;
    alu_ctrl   = 3'b000;
    branch     = 0;
    jal        = 0;
    jalr       = 0;
    pc_to_reg  = 0;

    case (opcode)

        // TYPE-R : ADD SUB AND OR XOR SLT SLL SRL
        // funct3 : choisit l'opération
        // funct7_5 : pour différencier ADD et SUB
        7'b0110011: begin
            reg_we  = 1;
            alu_src = 0;                              // rs1 et rs2 sont utilisés
            case (funct3)
                3'b000: begin                         // ADD ou SUB
                    if (funct7_5) alu_ctrl = 3'b001;  // SUB 
                    else          alu_ctrl = 3'b000;  // ADD 
                end
                3'b001: alu_ctrl = 3'b110;            // SLL
                3'b010: alu_ctrl = 3'b101;            // SLT
                3'b100: alu_ctrl = 3'b100;            // XOR
                3'b101: alu_ctrl = 3'b111;            // SRL
                3'b110: alu_ctrl = 3'b011;            // OR
                3'b111: alu_ctrl = 3'b010;            // AND
                default: alu_ctrl = 3'b000;
            endcase
        end

        // TYPE-I ALU : ADDI SLTI XORI ORI ANDI SLLI SRLI
        // funct3 : choisit l'opération

        7'b0010011: begin
            reg_we  = 1;
            alu_src = 1;                              // rs1 op immédiat
            case (funct3)
                3'b000: alu_ctrl = 3'b000;            // ADDI
                3'b001: alu_ctrl = 3'b110;            // SLLI
                3'b010: alu_ctrl = 3'b101;            // SLTI
                3'b100: alu_ctrl = 3'b100;            // XORI
                3'b101: alu_ctrl = 3'b111;            // SRLI
                3'b110: alu_ctrl = 3'b011;            // ORI
                3'b111: alu_ctrl = 3'b010;            // ANDI
                default: alu_ctrl = 3'b000;
            endcase
        end

        // LOAD : LW
        // funct3 : pas utilisé

        7'b0000011: begin
            reg_we     = 1;
            alu_src    = 1;
            mem_to_reg = 1;
            alu_ctrl   = 3'b000;                      // ADD car rs1 + imm = adresse
        end

        // STORE : SW
        // funct3 : pas utilisé


        7'b0100011: begin
            alu_src  = 1;
            mem_we   = 1;
            alu_ctrl = 3'b000;                        // ADD : rs1 + imm = adresse
        end

        // TYPE-B : BEQ BNE BLT BGE
        // funct3 : choisit la fonction
        //   BEQ/BNE : SUB
        //   BLT/BGE : SLT

        7'b1100011: begin
            branch  = 1;
            alu_src = 0;                              // compare rs1 et rs2
            case (funct3)
                3'b000,                               // BEQ ou
                3'b001: alu_ctrl = 3'b001;            // BNE alors ALU SUB
                3'b100,                               // BLT ou
                3'b101: alu_ctrl = 3'b101;            // BGE alors ALU SLT
                default: alu_ctrl = 3'b001;
            endcase
        end


        // LUI : rd = imm (imm déjà décalé de 12 bits par imm_gen)


        7'b0110111: begin
            reg_we   = 1;
            alu_src  = 1;
            alu_ctrl = 3'b000;                        // ADD : 0 + imm
        end


        // JAL (saut vers PC + offset pas géré par ALU)
   
        7'b1101111: begin
            reg_we    = 1;
            jal       = 1;
            pc_to_reg = 1;
        end

        // JALR (saut vers rs1 + offset géré par ALU)
        7'b1100111: begin
            reg_we    = 1;
            alu_src   = 1;
            jalr      = 1;
            pc_to_reg = 1;
            alu_ctrl  = 3'b000;                       // ADD : rs1 + imm
        end

        default: ;

    endcase
end

endmodule