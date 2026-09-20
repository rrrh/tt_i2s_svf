// src/tt_um_audio_filter.v
`default_nettype none

module tt_um_audio_filter (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire i2s_ws    = ui_in[0];
    wire i2s_sck   = ui_in[1];
    wire i2s_sd_in = ui_in[2];
    wire spi_cs_n  = ui_in[3];
    wire spi_sck   = ui_in[4];
    wire spi_mosi  = ui_in[5];
    
    assign uio_oe  = 8'hFF; 
    assign uio_out = 8'h00;
    
    assign uo_out[3:1] = 3'b000;
    assign uo_out[7:5] = 3'b000;

    wire signed [15:0] audio_in_data, audio_lp_data, audio_bp_data, audio_hp_data;
    wire sample_ready, spi_miso;
    wire [1:0] out_sel;
    
    assign uo_out[4] = spi_miso;

    i2s_rx u_i2s_rx (
        .clk(clk), .rst_n(rst_n), 
        .i2s_sck(i2s_sck), .i2s_ws(i2s_ws), .i2s_sd(i2s_sd_in),
        .data_out(audio_in_data), .sample_tick(sample_ready)
    );

    audio_filter_core #(.DATA_WIDTH(16), .CLK_DIV(100)) u_core (
        .clk(clk), .rst_n(rst_n),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .audio_in(audio_in_data),
        .audio_lp(audio_lp_data),
        .audio_bp(audio_bp_data),
        .audio_hp(audio_hp_data),
        .out_sel(out_sel)
    );

    // --- Output Multiplexer ---
    reg signed [15:0] selected_tx_audio;
    always @(*) begin
        case (out_sel)
            2'b00: selected_tx_audio = audio_in_data;
            2'b01: selected_tx_audio = audio_lp_data;
            2'b10: selected_tx_audio = audio_bp_data;
            2'b11: selected_tx_audio = audio_hp_data;
        endcase
    end

    i2s_tx u_i2s_tx_out (
        .clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws),
        .data_in(selected_tx_audio), .i2s_sd(uo_out[0])
    );
endmodule
