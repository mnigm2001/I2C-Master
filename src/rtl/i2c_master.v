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
    
    // TOP FSM States
    localparam [2:0]
        STATE_IDLE = 3'd0,
        STATE_START = 3'd1,
        STATE_ADDR = 3'd2,
        STATE_ADDR_ACK = 3'd3,
        STATE_READ_BYTE = 3'd4,
        STATE_READ_ACK = 3'd5,
        STATE_STOP = 3'd6,
        STATE_DONE = 3'd7;
    reg [2:0] state;
    
    // SDA drive support
    reg sda_out;    // sda driver reg
    reg sda_oe;     // sda output enable
    reg [2:0] addr_read_cnt;    // slave address bit counter
    reg addr_sent;
    
    // SCL Enable
    reg scl_toggle_en;

    
    /*
    I need to generate SCL only when needed
    scynronize to SCL not to clk_100k
    
    
    */
    
    // ------------------------------------------ //
    // --------------- SCL Driver --------------- //
    // ------------------------------------------ //
    wire clk_100k;
    clk_divider #(.CLK_DIV(CLK_DIV)) clk_div (
        .clk_in(clk),
        .resetn(resetn),
        .clk_out(clk_100k)
    );
    always @(posedge clk or negedge resetn) begin
        if (!resetn) scl = 1'b1;
        else scl = (scl_toggle_en == 1'b1) ? clk_100k : 1'b1;
    end
    // ------------------------------------------ //
    // -------------- State Update -------------- //
    // ------------------------------------------ //
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                  if (start == 1'b1)
                    state <= STATE_START;  
                end
                STATE_START:    state <= STATE_ADDR;
                STATE_ADDR: begin
                    if (addr_sent == 1'b1) state <= STATE_IDLE; //temp go back to IDLE for now
                end
            endcase
        end
    end
    
    
     // ------------------------------------------- //
    // -------------- Output Status  -------------- //
    // ------------------------------------------- //
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
            busy <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    data_valid <= 1'b0;
                end
                STATE_START: begin
                    busy <= 1'b1;
                end
                STATE_ADDR: begin
                   
                end
            endcase
        end
    end
    
    // ------------------------------------------ //
    // --------------- SDA Driver --------------- //
    // ------------------------------------------ //
    always @ (posedge clk_100k or negedge resetn) begin
        if (!resetn) begin
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            addr_read_cnt <= 3'd0;
            
            scl_toggle_en <= 1'b0;
            addr_sent <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    sda_out <= 1'b1;
                    sda_oe <= 1'b0;
                    scl_toggle_en <= 1'b0;
                    addr_sent <= 1'b0;
                end
                STATE_START: begin
                    sda_out <= 1'b0;    // start signal
                    sda_oe <= 1'b1;
                end
                STATE_ADDR: begin
                    scl_toggle_en <= 1'b1;
                    // -- Send 7-bit address -- //
                    if (addr_read_cnt < 3'd7) begin
                        addr_read_cnt <= addr_read_cnt + 1;
                        sda_oe <= 1'b1;
                        sda_out <=  ((SLAVE_ADDR << 1) >> addr_read_cnt ) & 1'b1; // shift out 1 bit from slave address
                    end else begin
                        addr_read_cnt <= 3'd0;
                        sda_oe <= 1'b0;
                        sda_out <= 1'b1;
                        scl_toggle_en <= 1'b0;
                        addr_sent <= 1'b1;
                    end
                end
            endcase
        end
    end
    assign sda = (sda_oe == 1'b1) ? sda_out : 1'bz;

    // ------------------------------------------ //
    // --------------- SCL Driver --------------- //
    // ------------------------------------------ //
//    always @ (posedge clk_100k or negedge resetn) begin
//        if (!resetn) begin
//            scl <= 1'b1;
//        end else begin
//            scl <= 1'b1;
//            if (scl_toggle_en == 1'b1) begin
//                scl = ~scl;
//            end
//        end
//    end
    
    
    
endmodule
