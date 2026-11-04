module cpu(
    input clk,
    input rst,
    output  mem_we,        
    output [31:0] mem_addr,      
    output [31:0] mem_wdata,     
    input  [31:0] mem_rdata 
);

// Fetch 
wire [31:0] next_pc, current_pc, instr;

// Control Unit
wire reg_we, alu_src, mem_to_reg;
wire [2:0] alu_ctrl;

// Data
wire [31:0] rs1_data, rs2_data; 
wire [31:0] imm;                //sortie de immgen
wire [31:0] alu_result;         
wire zero;


// Mux
wire [31:0] alu_a_input;        //  première entrée de l'ALU (0 pour LUI)
wire [31:0] alu_b_input;        //deuxième entrée de l'ALU
wire [31:0] writeback_data;     //ce qu'on écrit dans rd

//Branch
wire branch;
wire take_branch;
wire [31:0] branch_pc;

//JAL et JALR
wire jal;
wire jalr;

wire [31:0] jal_pc;   
wire [31:0] jalr_pc;  
wire pc_to_reg;


assign mem_addr  = alu_result;
assign mem_wdata = rs2_data;

assign branch_pc = current_pc + imm; //cible du saut : ligne actuelle du pc + l'offset qui est dans l'immediat

assign take_branch = branch && (   //condition pour sauter : si c'est un BEQ et que l'alu a zero pour resultat
                                   // OU si c'est un BNE et que l'ALU a pas zero pour resultat
    (instr[14:12] == 3'b000 && zero) ||  
    (instr[14:12] == 3'b001 && !zero) ||
    (instr[14:12] == 3'b100 && alu_result[0]) ||   //  BLT (SLT : rs1 < rs2 => résultat = 1)
    (instr[14:12] == 3'b101 && !alu_result[0])     //  BGE (SLT : rs1 >= rs2 => résultat = 0)
);

assign jal_pc = current_pc + imm;
assign jalr_pc = (rs1_data + imm) & ~32'h1;


assign next_pc = jalr ? jalr_pc :
                 jal ? jal_pc :
                 take_branch ? branch_pc :
                 (current_pc + 4); //soit le saut, soit l'instruction suivante (une instruction dans la ROM = 4 octets)




assign alu_b_input = (alu_src == 1) ? imm : rs2_data; //immediat ou rgB ?

assign alu_a_input = (instr[6:0] == 7'b0110111) ? 32'b0 : rs1_data; //  LUI => 0 + imm

assign writeback_data = pc_to_reg ? (current_pc + 4): // SI cas JAL ou JALR
                        ((mem_to_reg == 1) ? mem_rdata : alu_result); // SINON stockage de la lecture ram
                                                                        //ou du resultat ALU ?

pc compteur_pc(
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .current_pc(current_pc)
);

rom romemory(
    .pc_adress(current_pc),
    .instr(instr)
);

control_unit control_unit(
    .opcode(instr[6:0]),
    .funct3(instr[14:12]),
    .funct7_5(instr[30]),       // nécessaire pour ADD/SUB
    .reg_we(reg_we),
    .alu_src(alu_src),
    .mem_we(mem_we),
    .mem_to_reg(mem_to_reg),
    .alu_ctrl(alu_ctrl),
    .branch(branch),
    .jal(jal),
    .jalr(jalr),
    .pc_to_reg(pc_to_reg)
);  

register_file reg_file(
    .clk(clk),
    .we(reg_we),
    .rs1_adress(instr[19:15]),  //adresses contenues dans l'instruction
    .rs2_adress(instr[24:20]),
    .rd_adress(instr[11:7]), //si on veut écrire dans le reg
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .rd_data(writeback_data)
);  

imm_gen immediat(
    .instr(instr),
    .imm(imm)
);

alu alu(
    .a(alu_a_input),            // rs1_data , 0 si LUI
    .b(alu_b_input),
    .alu_ctrl(alu_ctrl),
    .result(alu_result),
    .zero(zero)
);

endmodule