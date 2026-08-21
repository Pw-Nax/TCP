/*
LFSR GALOIS
*/

`timescale 1ns / 100ps

module lfsr
#(
    parameter                       LFSR_WIDTH = 16     ,
    parameter  [LFSR_WIDTH-1:0]     LFSR_SEED  = 16'd65535   
    
)
(
    input  wire                     clk                 ,
    input  wire                     i_rst               ,
    input  wire                     i_soft_rst          ,
    input  wire                     i_valid             ,
    input  wire [LFSR_WIDTH-1:0]    i_seed              ,
    output reg  [LFSR_WIDTH-1:0]    o_lfsr              ,

);
    wire internal_feedback;

    

    always @(posedge clk or posedge i_rst) begin

        if(i_rst)
            o_lfsr          <= LFSR_SEED                                                ;
        else if(i_soft_rst)
            o_lfsr          <= i_seed                                                   ;
        else if(i_valid) begin
            
            o_lfsr[0]       <= internal_feedback                                             ;
            o_lfsr[1]       <= o_lfsr[0]                                                ;
            o_lfsr[2]       <= o_lfsr[1] ^ internal_feedback                                 ;
            o_lfsr[3]       <= o_lfsr[2] ^ internal_feedback                                 ;
            o_lfsr[4]       <= o_lfsr[3]                                                ;
            o_lfsr[5]       <= o_lfsr[4] ^ internal_feedback                                 ;
            o_lfsr[15:6]    <= o_lfsr[14:5]                                             ;
        end
        else
            o_lfsr          <= o_lfsr                                                   ;

    end

    // Calculamos el valor y lo sacamos directo por el pin
    assign  internal_feedback      = o_lfsr[15] ^ !(o_lfsr==16'd0)                      ;

endmodule