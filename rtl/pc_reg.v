module pc (
    input clk,
    input rst,
    input [31:0] next_pc, // prochaine instruction
    output reg [31:0] current_pc // vers la ram
);

// Ecriture, séquentiel
always @(posedge clk or posedge rst) begin 
    if (rst == 1) begin
        current_pc <= 32'b0;
    end
    else begin
        current_pc <= next_pc;
    end
end

endmodule
