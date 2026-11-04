`timescale 1ns/1ps
module rand_tb;
    reg clk = 0;
    wire [5:0] led;

    top dut (.clk(clk), .btn(1'b0), .led(led));  

    always #18.5 clk = ~clk;

    always @(posedge clk)
        if (dut.mem_we && dut.mem_addr == 32'h4000_0000)
            $display("OUT %h", dut.mem_wdata);

    initial begin
        #50000;
        $finish;
    end
endmodule   