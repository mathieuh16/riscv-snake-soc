`timescale 1ns/1ps

module snake_tb;

    reg  clk = 0;
    wire [5:0] led;

    top dut (
        .clk (clk),
        .btn (1'b0),          // mets 1'b1 si BTN_ACTIVE_LOW = 1 dans top.v
        .led (led)
    );

    always #18.5 clk = ~clk;  // environ 27 MHz

    integer errors = 0;

    // ---------- Mémorise la dernière valeur écrite sur les LED ----------
    reg [31:0] led_last = 32'hFFFF_FFFF;
    always @(posedge clk)
        if (dut.mem_we && dut.mem_addr == 32'h4000_0000)
            led_last <= dut.mem_wdata;

    // ---------- Outils ----------
    // Attend que le CPU écrive la tête du serpent (valeur 1) dans la grille,
    // puis laisse passer un demi-cycle pour que la RAM soit à jour.
    task wait_step;
        begin
            @(posedge clk);
            while ((dut.mem_we
                    && dut.mem_addr[31:8] == 24'h000008   // 0x800 à 0x8FF
                    && dut.mem_wdata == 32'd1) !== 1'b1)
                @(posedge clk);
            @(negedge clk);
        end
    endtask

    task press;                       // simule le registre de commande
        input [31:0] cmd;
        begin
            dut.ramemory.ram[1023] = cmd;
        end
    endtask

    task check_cell;
        input [31:0] cx, cy, expv;
        begin
            if (dut.ramemory.ram[512 + (cy << 3) + cx] !== expv) begin
                $display("KO  case (%0d,%0d) : attendu %0d, obtenu %0h",
                         cx, cy, expv, dut.ramemory.ram[512 + (cy << 3) + cx]);
                errors = errors + 1;
            end else
                $display("OK  case (%0d,%0d) = %0d", cx, cy, expv);
        end
    endtask

    task check_led;
        input [31:0] expv;
        begin
            if (led_last !== expv) begin
                $display("KO  LED : attendu %0d, obtenu %0h", expv, led_last);
                errors = errors + 1;
            end else
                $display("OK  LED = %0d", expv);
        end
    endtask

    // ---------- Scénario ----------
    initial begin
        $dumpfile("snake_tb.vcd");
        $dumpvars(0, snake_tb);

        #1 press(0);                       // aucun bouton appuyé

        // 1. Démarrage : tête en (5,5), pomme en (2,2)
        wait_step;
        $display("--- démarrage");
        check_cell(5, 5, 1);
        check_cell(2, 2, 2);

        // 2. Gauche, puis bouton relâché : le serpent doit garder sa direction
        $display("--- direction mémorisée");
        press(3);
        wait_step;  press(0);
        check_cell(4, 5, 1);
        wait_step;  check_cell(3, 5, 1);
        wait_step;  check_cell(2, 5, 1);

        // 3. Haut jusqu'à la pomme en (2,2)
        $display("--- manger la pomme");
        press(1);
        wait_step;  press(0);
        check_cell(2, 4, 1);
        wait_step;  check_cell(2, 3, 1);
        wait_step;  check_cell(2, 2, 1);   // la tête remplace la pomme
        check_led(1);                      // score = 1
        check_cell(3, 5, 2);               // nouvelle pomme en (3,5)

        // 4. Il continue vers le haut et sort de la grille
        $display("--- défaite : retour à zéro");
        wait_step;  check_cell(2, 1, 1);
        wait_step;  check_cell(2, 0, 1);
        wait_step;                         // le prochain pas dessiné est celui d'après le reset
        check_led(0);                      // score remis à 0
        check_cell(2, 2, 2);               // pomme replacée en (2,2)
        check_cell(2, 0, 0);               // traînée effacée
        check_cell(3, 5, 0);               // ancienne pomme effacée
        check_cell(5, 5, 1);               // serpent revenu en (5,5)

        if (errors == 0) $display("PASS : le Snake se comporte comme prévu");
        else             $display("FAIL : %0d erreur(s)", errors);
        $finish;
    end

    // ---------- Garde-fou ----------
    initial begin
    #1_000_000; $display("1 ms : pc = %h", dut.cpu_inst.current_pc);
    #1_000_000; $display("2 ms : pc = %h", dut.cpu_inst.current_pc);
    #1_000_000; $display("3 ms : pc = %h", dut.cpu_inst.current_pc);
    #7_000_000; $display("TIMEOUT : pc = %h", dut.cpu_inst.current_pc);
    $finish;
end

always @(posedge clk)
    if (dut.mem_we)
        $display("%0t  W addr=%h data=%h pc=%h",
                 $time, dut.mem_addr, dut.mem_wdata, dut.cpu_inst.current_pc);

endmodule