module register_file(
    input clk,
    input we,
    input [4:0] rs1_adress,
    input [4:0] rs2_adress,
    output [31:0] rs1_data,
    output [31:0] rs2_data,

    input [4:0] rd_adress,
    input [31:0] rd_data 
);

integer i;
reg [31:0] registers [31:0];

// Initialisation de tous les registres à 0 au démarrage pour chasser les 'x'
initial begin
    for (i = 0; i < 32; i = i + 1) begin
        registers[i] = 32'b0;
    end
end

// Lecture
assign rs1_data = (rs1_adress == 5'b00000) ? 32'b0 : registers[rs1_adress];
assign rs2_data = (rs2_adress == 5'b00000) ? 32'b0 : registers[rs2_adress];

// Ecriture
always @(posedge clk) begin 
    if (we == 1 && rd_adress != 5'b00000) begin
        registers[rd_adress] <= rd_data;
    end
end


endmodule