module imm_gen (
    input [31:0] instr,
    output reg [31:0] imm
);

always @(*) begin
    case(instr[6:0])
        7'b0010011 : imm = {{20{instr[31]}},instr[31:20]};                                 // ADDI copie du bit de signe et extension à 32
        7'b0000011 : imm = {{20{instr[31]}},instr[31:20]};                                 //LW  
        7'b0100011 : imm = {{20{instr[31]}},instr[31:25],instr[11:7]};                     //SW
        //car dans ce cas l'imm est coupé en deux dans l'instr de la ROM
        7'b1100011 : imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};   // BEQ / BNE / BLT / BGE (Type B)
        7'b1101111 : imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // JAL (Type J)
        7'b1100111 : imm = {{20{instr[31]}}, instr[31:20]};                                // JALR (Type I)
        7'b0110111 : imm = {instr[31:12], 12'b0};                                          // LUI (Type U), imm sur les 20 bits de poids fort
        default : imm = 32'b0;
endcase

end


endmodule