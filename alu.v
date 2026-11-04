module alu (
    input  [31:0] a,          // Valeur du registre A (32 bits)
    input  [31:0] b,          // Valeur de l'ALUSrc (32 bits) RegB ou IMM
    input  [2:0]  alu_ctrl,   // Opération a faire
    output reg [31:0] result,  // Résultat à écrire dans banc (ou RAM si Type-S)
    output zero
);

    always @(*) begin
        case (alu_ctrl)
            3'b000: result = a + b;                                      // ADD
            3'b001: result = a - b;                                      // SUB
            3'b010: result = a & b;                                      // AND
            3'b011: result = a | b;                                      // OR
            3'b100: result = a ^ b;                                      // XOR 
            3'b101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // SLT (était en 100)
            3'b110: result = a << b[4:0];                                // SLL 
            3'b111: result = a >> b[4:0];                                // SRL 

            default: result = 32'b0; 
        endcase
    end

    assign zero = (result == 32'b0) ? 1'b1 : 1'b0;

endmodule