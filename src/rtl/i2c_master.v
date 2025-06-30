`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2025 09:38:29 PM
// Design Name: 
// Module Name: i2c_master
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


module i2c_master(
    input wire clk,
    input wire resetn,
    input wire start,
    output reg busy,
    output reg [15:0] data_out,
    output reg data_valid,
    output reg scl,
    inout wire sda
    );
    
    parameter SLAVE_ADDR = 7'b1001000;
    parameter CLK_DIV = 250;
    
    // Clock Divider
    reg [$clog2(CLK_DIV):0] count;
    reg clk_100k;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            count <= 0;
            clk_100k <= 0;
        end else begin
            count <= count + 1;
            if (count == CLK_DIV) begin
                count <= 0;
                clk_100k <= ~clk_100k;
            end
        
        end
    end
    
    
    
    
endmodule
