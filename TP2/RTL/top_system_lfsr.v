module top_system_lfsr #(
    parameter LFSR_WIDTH = 16
)(
    input  wire clk,
    input  wire reset,
    input  wire i_soft_rst,
    input  wire i_valid,
    input  wire [LFSR_WIDTH-1:0] i_seed,
    output wire checker_status
);

    wire [LFSR_WIDTH-1:0] lfsr_data;

    lfsr #(
        .LFSR_WIDTH(LFSR_WIDTH)
    ) u_lfsr (
        .clk        (clk),
        .i_rst      (reset),
        .i_soft_rst (i_soft_rst),
        .i_valid    (i_valid),
        .i_seed     (i_seed),
        .o_lfsr     (lfsr_data)
    );

    checker_lfsr #(
        .LFSR_WIDTH(LFSR_WIDTH)
    ) u_checker (
        .clk              (clk),
        .i_reset          (reset),
        .i_soft_rst       (i_soft_rst),
        .i_valid          (i_valid),
        .i_output_lfsr    (lfsr_data),
        .o_status_checker (checker_status)
    );

endmodule