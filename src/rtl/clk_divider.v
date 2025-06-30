`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2025 10:00:25 PM
// Design Name: 
// Module Name: clk_divider
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


module clk_divider #(
    parameter CLK_DIV=250
    // or pass input clk frequency
)(
    input wire clk_in,
    input wire resetn,
    output reg clk_out
    );
    reg [$clog2(CLK_DIV):0] count;
    
    always @(posedge clk_in or negedge resetn) begin
        if (!resetn) begin
            count <= 0;
            clk_out <= 1;
        end else begin
            count <= count + 1;
            if (count == CLK_DIV) begin
                count <= 0;
                clk_out <= ~clk_out;
            end
        end
    end
endmodule
