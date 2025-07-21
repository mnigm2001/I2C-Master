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
    output wire scl,
    inout wire sda
    );
    
    parameter SLAVE_ADDR = 7'b1111111;
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
    reg scl_oe;


    
    // ------------------------------------------ //
    // --------------- SCL Driver --------------- //
    // ------------------------------------------ //
    wire scl_inter;
    clk_divider #(.CLK_DIV(CLK_DIV)) clk_div (
        .clk_in(clk),
        .resetn(resetn),
        .clk_out(scl_inter)
    );
//    always @(posedge clk or negedge resetn) begin
//        if (!resetn) scl = 1'b1;
//        else scl = (scl_oe == 1'b1) ? scl_inter : 1'b1;
//    end
    assign scl = (scl_oe == 1'b1) ? scl_inter : 1'bz;

    
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
    
    
    // ------------------------------------------ //
    // --------------- SDA Driver --------------- //
    // ------------------------------------------ //
    reg prev_scl;
    
    reg sda_oe_flag;
    reg [7:0] sda_addr_first_shift;
    reg [7:0] sda_addr_second_shift;
    reg sda_addr_final;
    
    reg [7:0] addr_sr;
    reg addr_sr_out;
    
    reg rw_sent;
    
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
//            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            addr_read_cnt <= 3'd0;
            
            scl_oe <= 1'b0;
            addr_sent <= 1'b0;
            prev_scl <= 1'b1; //necessary?
        end else begin
            case (state)
                STATE_IDLE: begin
//                    sda_out <= 1'b1;
                    sda_oe <= 1'b1; // temp change to 1'b1
                    scl_oe <= 1'b0;
                    addr_sent <= 1'b0;
                end
                STATE_START: begin
                    sda_oe <= 1'b1;     // start signal
                    scl_oe <= 1'b1;
                    // 0101101 -> 10101101
                    addr_sr <= {1'b1, SLAVE_ADDR};
                end
                STATE_ADDR: begin
//                      sda_oe <= 1'b0;
//                    scl_oe <= 1'b1;

                    // SEND on SCL falling edge
                    if (scl_inter == 1'b0 && prev_scl == 1'b1) begin
                        if (addr_read_cnt < 3'd7) begin   // Send address bits 
                            addr_read_cnt <= addr_read_cnt + 1;
//                            scl_oe <= 1'b1;
                            sda_addr_first_shift <= (SLAVE_ADDR << 1);
                            sda_addr_second_shift <= ((SLAVE_ADDR << 1) >> addr_read_cnt );
                            sda_addr_final <= (((SLAVE_ADDR << 1) >> addr_read_cnt ) & 1'b1);
                            addr_sr_out <= addr_sr >> addr_read_cnt & 1'b1;
                            if (((SLAVE_ADDR << 1) >> addr_read_cnt ) & 1'b1) begin
                                sda_oe <= 1'b0; // if address bit 1 -> sda_oe = 1'b0 -> sda = 1'bz
                                sda_oe_flag <= 1'b0;
                            end else begin
                                sda_oe <= 1'b1;
                                sda_oe_flag <= 1'b1;
                            end
                        end else begin  // Send R/W bit
                            
                            addr_read_cnt <= 3'd0;
                            sda_oe <= 1'b0;
    //                        sda_out <= 1'b1;
                            scl_oe <= 1'b0;
                            addr_sent <= 1'b1;      // For state change
                        end
                    end 
                    
                    if (prev_scl != scl_inter) prev_scl <= scl_inter;

                end
            endcase
        end
    end
    assign sda = (sda_oe == 1'b1) ? 1'b0 : 1'b1;
    
    
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
    
endmodule
