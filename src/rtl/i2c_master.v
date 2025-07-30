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
    
    parameter SLAVE_ADDR = 7'b0101101;
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
        reg rw_sent;
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
                    if (rw_sent == 1'b1) state <= STATE_ADDR_ACK;
                    
                end
                STATE_ADDR_ACK: state <= STATE_READ_BYTE;
                STATE_READ_BYTE: state <= STATE_IDLE; // go to idle temporarily
            endcase
        end
    end
    
    
    // ------------------------------------------ //
    // --------------- SDA Driver --------------- //
    // ------------------------------------------ //
    reg prev_scl;
    reg [7:0] addr_sr;
    
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
//            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            addr_read_cnt <= 3'd0;
            
            scl_oe <= 1'b0;
            addr_sent <= 1'b0;
            rw_sent <= 1'b0;
            
            prev_scl <= 1'b1; //necessary?
        end else begin
            case (state)
                STATE_IDLE: begin
                    sda_oe <= 1'b0;
                    scl_oe <= 1'b0;
                    addr_sent <= 1'b0;
                end
                STATE_START: begin
                    sda_oe <= 1'b1;     // start signal
                    scl_oe <= 1'b1;
                    // 0101101 -> 10101101
                    addr_sr <= {SLAVE_ADDR, 1'b0};
                end
                STATE_ADDR: begin
                    
                    /*
                        Master sends prepares data on falling edge of scl
                        Slave reads data on rising edge
                         --> SCL enable should remain ON for 8 RISING EDGES of SCL
                         --> DATA should be prepared on the falling edges
                         Rising edge: scl_inter == 1'b0 && scl_prev == 1'b1
                         Falling edge: scl_inter == 1'b1 && scl_prev == 1'b0
                         
                         if Falling Edge
                            if addr_read_cnt <= 7
                                if addr_bit == 1
                                    sda_oe = 0
                                else (addr_bit == 0)
                                    sda_oe = 1
                                addr_sr = addr_sr << 1
                         if Rising Edge
                            if addr_read_cnt <= 7
                                addr_read_cnt++
                    */
                    
                    // SEND on SCL falling edge
                    if (scl_inter == 1'b0 && prev_scl == 1'b1) begin
                        if ((addr_read_cnt <= 3'd7) && (addr_sent == 1'b0)) begin   // Send address bits 
 
                            if (addr_sr[7] == 1'b1) sda_oe <= 1'b0;
                            else sda_oe <= 1'b1;
                            addr_sr <= {addr_sr[6:0], 1'b0};
                                
                            // Address sent
                            if (addr_read_cnt == 3'd7) begin addr_sent <= 1'b1; end
                            addr_read_cnt <= addr_read_cnt + 1;
                            
                        end else if (addr_sent == 1'b1) begin  // scl on for one more cycle
//                            sda_oe <= 1'b0;
                            scl_oe <= 1'b1;
                            rw_sent <= 1'b1;
                            
                        end else begin // Reset regs
                            addr_sent <= 1'b0;
                            rw_sent <= 1'b0;
                            addr_read_cnt <= 3'd0;
                            sda_oe <= 1'b0;
                            scl_oe <= 1'b1; // scl should remain ON for slave to ACK in next state
                        end
                    end 
                    
                    if (prev_scl != scl_inter) prev_scl <= scl_inter;
                end
                STATE_ADDR_ACK: begin
                    // slave must ACK by pulling SDA low
//                    if (sda ==
                end
            endcase
        end
    end
    assign sda = (sda_oe == 1'b1) ? 1'b0 : 1'bz;
    
    
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
