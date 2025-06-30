`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2025 10:04:29 PM
// Design Name: 
// Module Name: i2c_master_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_divider_tb();
    reg clk_50m=0, resetn;
    wire clk_100k;
    
    always #10 clk_50m = ~clk_50m;
    
    clk_divider #(.CLK_DIV(250)) clk_div_dut (
        .clk_in(clk_50m),
        .resetn(resetn),
        .clk_out(clk_100k)
    );
    
    initial begin
        resetn = 1;
        @(posedge clk_50m); resetn = 0;
        @(posedge clk_50m);
        @(posedge clk_50m); resetn = 1;
        
        @(posedge clk_100k);
        @(posedge clk_100k);
        @(posedge clk_100k);
        #100;
        $finish;
    
    end
    
    

endmodule


