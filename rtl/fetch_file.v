// fait le lien entre pc et rom, = soudure

module fetch_stage (
    input clk,
    input rst,
    output [31:0] instr // instruction qui sort de la ROM suite a la demande PC
);

wire [31:0] current_pc;
wire [31:0] next_pc;
assign next_pc = current_pc + 4; //le pc demande l'instruction suivante (le tiroir suivant)
                                 //mais un tiroir = 4 octets (car une instruction = 32 bits)

pc compteur_pc ( //instanciation (on va brancher les pattes du compteur_pc.(sur les fils du fetch)
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .current_pc(current_pc)
);

rom romemory (
    .pc_adress(current_pc),
    .instr(instr)
);


endmodule
