// src/tt_um_audio_filter.v
`default_nettype none

module tt_um_audio_filter (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,      // 50 MHz System Clock
    input  wire       rst_n
);

    // --- IO Mapping ---
    wire i2s_ws    = ui_in[0];
    wire i2s_sck   = ui_in[1];
    wire i2s_sd_in = ui_in[2];
    wire spi_cs_n  = ui_in[3];
    wire spi_sck   = ui_in[4];
    wire spi_mosi  = ui_in[5];
    
    assign uio_oe  = 8'hFF; 
    assign uio_out = 8'h00;
    assign uo_out[7:5] = 3'b000;

    // --- Internal Buses ---
    wire signed [15:0] audio_in_data;
    wire signed [15:0] audio_lp_data;
    wire signed [15:0] audio_bp_data;
    wire signed [15:0] audio_hp_data;
    wire sample_ready;
    wire spi_miso;
    
    assign uo_out[4] = spi_miso;

    // --- 1. I2S Receiver ---
    i2s_rx u_i2s_rx (
        .clk(clk), .rst_n(rst_n), 
        .i2s_sck(i2s_sck), .i2s_ws(i2s_ws), .i2s_sd(i2s_sd_in),
        .data_out(audio_in_data), .sample_tick(sample_ready)
    );

    // --- 2. Filter Core ---
    audio_filter_core #(
        .DATA_WIDTH(16),
        .CLK_DIV(100) // 50 MHz clk / 100 = 500 kHz Oversampling
    ) u_core (
        .clk(clk), .rst_n(rst_n),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .sample_tick(sample_ready),
        .audio_in(audio_in_data),
        .audio_lp(audio_lp_data), .audio_bp(audio_bp_data), .audio_hp(audio_hp_data)
    );

    // --- 3. I2S Transmitters ---
    i2s_tx u_i2s_tx_thru (
        .clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws),
        .data_in(audio_in_data), .i2s_sd(uo_out[0])
    );
    i2s_tx u_i2s_tx_lp (
        .clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws),
        .data_in(audio_lp_data), .i2s_sd(uo_out[1])
    );
    i2s_tx u_i2s_tx_bp (
        .clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws),
        .data_in(audio_bp_data), .i2s_sd(uo_out[2])
    );
    i2s_tx u_i2s_tx_hp (
        .clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws),
        .data_in(audio_hp_data), .i2s_sd(uo_out[3])
    );
endmodule
