module ram (
    input clk,
    input mem_we,
    input [31:0] address,
    input [31:0] regB_data, //valeur à écrire dans RAM à l'address
    output [31:0] read_data // quand on veut lire dans la RAM
);


reg [31:0] ram [0:1023];

initial begin
    $readmemh("dataram.hex", ram);
end

assign read_data = ram[address[11:2]]; //on coupe les deux derniers bits
                                        // pour diviser par 4 car 1 tiroir
                                        // = 4 octets

                                        //on ne prend pas les bits 31 à 12 
                                       // mais ils ne contiennent pas l'adresse
                                       // car sinon on aurait 4 milliards d'adresses


always@(posedge clk) begin
    if (mem_we == 1) begin
        ram[address[11:2]] <= regB_data;
    end

end

endmodule
