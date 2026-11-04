module rom(
    input [31:0] pc_adress,
    output [31:0] instr
);

reg [31:0] memory [0:1023]; 

initial begin    // on simule la gravure usine du jeu
    $readmemh("firmware.hex", memory);
end

assign instr = memory[pc_adress[11:2]]; //on ne prend pas les bits 31 à 12 
                                       // mais ils ne contiennent pas l'adresse
                                       // car sinon on aurait 4 milliards d'adresses

endmodule
