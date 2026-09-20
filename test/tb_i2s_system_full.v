`default_nettype none
`timescale 1ns / 1ps

module tb_i2s_system_full;
    reg clk, rst_n, ena;
    wire [7:0] ui_in, uo_out, uio_out, uio_oe;
    wire [7:0] uio_in = 8'h00;

    reg i2s_sck, i2s_ws, i2s_sd_in;
    reg spi_cs_n, spi_sck, spi_mosi;

    assign ui_in[0] = i2s_ws;
    assign ui_in[1] = i2s_sck;
    assign ui_in[2] = i2s_sd_in;
    assign ui_in[3] = spi_cs_n;
    assign ui_in[4] = spi_sck;
    assign ui_in[5] = spi_mosi;
    assign ui_in[7:6] = 2'b00;

    tt_um_audio_filter uut (
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out),
        .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    wire signed [15:0] out_bp;
    wire tick_bp;
    i2s_rx tb_rx_bp (.clk(clk), .rst_n(rst_n), .i2s_sck(i2s_sck), .i2s_ws(i2s_ws), .i2s_sd(uo_out[0]), .data_out(out_bp), .sample_tick(tick_bp));

    always #10 clk = ~clk;                 
    always #325.52 i2s_sck = ~i2s_sck;     

    real PI = 3.14159265359;
    real fs = 48000.0;
    real freq = 440.0;
    real phase = 0.0;
    real amplitude = 16000.0;
    
    integer fd, cfg_idx, sample_count, bit_idx, sample_val;
    reg [7:0] configs [0:2];
    reg [15:0] current_audio;

    initial begin
        $dumpfile("tb_i2s_system_full.vcd");
        $dumpvars(0, tb_i2s_system_full);
        
        fd = $fopen("i2s_system_data.csv", "w");
        $fdisplay(fd, "config,sample,bp");

        clk = 0; rst_n = 0; ena = 1;
        i2s_sck = 0; i2s_ws = 0; i2s_sd_in = 0;
        spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;
        sample_count = 0;

        configs[0] = 8'h29; 
        configs[1] = 8'h28; 
        configs[2] = 8'h25; 

        #1000; rst_n = 1; #1000;

        fork
            // I2S Master process
            forever begin
                sample_val = $rtoi(amplitude * $sin(phase));
                current_audio = sample_val[15:0];
                phase = phase + 2.0 * PI * (freq / fs);
                if (phase > 2.0 * PI) phase = phase - 2.0 * PI;

                i2s_ws = 0; @(negedge i2s_sck); i2s_sd_in = 0;
                for (bit_idx = 15; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck); i2s_sd_in = current_audio[bit_idx];
                end
                for (bit_idx = 14; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck); i2s_sd_in = 0; 
                end

                @(negedge i2s_sck); i2s_ws = 1; i2s_sd_in = 0; 
                for (bit_idx = 30; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck); i2s_sd_in = 0;
                end
            end
            
            // Configuration Sequence
            begin
                for (cfg_idx = 0; cfg_idx < 3; cfg_idx = cfg_idx + 1) begin
                    spi_transaction({8'h80, configs[cfg_idx]});
                    sample_count = 0; 
                    #15000000; 
                end
                $fclose(fd);$finish;
            end
        join
    end

    always @(posedge clk) begin
        if (tick_bp && rst_n) begin
            $fdisplay(fd, "%0h,%0d,%0d", configs[cfg_idx], sample_count, out_bp);
            sample_count = sample_count + 1;
        end
    end

    // Proper SPI Transaction Task
    task spi_transaction(input [15:0] data);
        integer idx;
        begin
            spi_cs_n = 0; #500;
            for (idx = 15; idx >= 0; idx = idx - 1) begin
                spi_mosi = data[idx]; #500; spi_sck = 1; #500; spi_sck = 0;
            end
            #500; spi_cs_n = 1; #500;
        end
    endtask
endmodule
