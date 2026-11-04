module top (
    input  wire clk,      
    input  wire  btn,       
    output wire [5:0] led   //adresse mémoire LED  
);

    localparam BTN_ACTIVE_LOW = 1'b0;

    reg [3:0] por_cnt = 4'd0;
    always @(posedge clk)
        if (!(&por_cnt)) por_cnt <= por_cnt + 4'd1; //incrémente por_cnt jusque 15 fronts montants

    wire btn_pressed = BTN_ACTIVE_LOW ? ~btn : btn; 
    wire rst = ~(&por_cnt) | btn_pressed;   // reset actif à 1 pdt 15 premiers cycles de clk
                                            // ou si bouton pressé

    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    cpu cpu_inst (
        .clk       (clk),
        .rst       (rst),
        .mem_we    (mem_we), //droit ecriture (sw)
        .mem_addr  (mem_addr), //adresse cible lw et sw
        .mem_wdata (mem_wdata), // sw valeur a ecrire
        .mem_rdata (mem_rdata) //valeur lue par lw
    );

    // 0x4000_0000 : registre de LED
    // tout le reste ram
    wire sel_led = (mem_addr[31:28] == 4'h4); //1 si on communique avec LED
    wire sel_ram = ~sel_led; // 1 si on communique avec RAM

                                // si aucun des deux (ex ADD) pas grave car mem_we=0

    wire [31:0] ram_rdata;
    ram ramemory (
        .clk       (clk),
        .mem_we    (mem_we & sel_ram),
        .address   (mem_addr),
        .regB_data (mem_wdata),
        .read_data (ram_rdata)
    );

    reg [5:0] led_reg = 6'd0; //mem tampon état de la LED
    always @(posedge clk)
        if (mem_we && sel_led) //on essaye d'ecrire dans LED
            led_reg <= mem_wdata[5:0];

    assign led = ~led_reg;   //souvent LED polarisées en inverse sur cartes physiques
                            // (0 pour s'allumer)

    
    assign mem_rdata = sel_led ? {26'b0, led_reg} : ram_rdata; //cas de lw avec complement a 32 bits si LED
                                                                // car la led a que 6 bits
endmodule