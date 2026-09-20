// src/audio_filter_core.v
`default_nettype none

module audio_filter_core #(
    parameter DATA_WIDTH = 16,
    parameter CLK_DIV = 100
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    input  wire                    spi_cs_n,
    input  wire                    spi_sck,
    input  wire                    spi_mosi,
    output wire                    spi_miso,
    
    input  wire signed [DATA_WIDTH-1:0] audio_in,
    output wire signed [DATA_WIDTH-1:0] audio_lp,
    output wire signed [DATA_WIDTH-1:0] audio_bp,
    output wire signed [DATA_WIDTH-1:0] audio_hp,
    output wire [1:0]              out_sel
);

    wire [3:0] f_shift_cfg;
    wire [3:0] q_shift_cfg;

    spi_reg_bank u_reg_bank (
        .clk(clk),
        .rst_n(rst_n),
        .spi_cs_n(spi_cs_n),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .f_shift_out(f_shift_cfg),
        .q_shift_out(q_shift_cfg),
        .out_sel(out_sel)
    );

    svf_multiplierless #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) u_svf (
        .clk(clk),
        .rst_n(rst_n),
        .f_shift(f_shift_cfg),
        .q_shift(q_shift_cfg),
        .audio_in(audio_in),
        .audio_lp(audio_lp),
        .audio_bp(audio_bp),
        .audio_hp(audio_hp)
    );
endmodule
