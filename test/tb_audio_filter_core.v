`default_nettype none
`timescale 1ns / 1ps

module tb_audio_filter_core;
    reg clk, rst_n, spi_cs_n, spi_sck, spi_mosi, sample_tick;
    wire spi_miso;
    reg signed [15:0] audio_in;
    wire signed [15:0] audio_lp, audio_bp, audio_hp;

    audio_filter_core #(.DATA_WIDTH(16), .CLK_DIV(100)) uut (
        .clk(clk), .rst_n(rst_n),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .sample_tick(sample_tick), .audio_in(audio_in),
        .audio_lp(audio_lp), .audio_bp(audio_bp), .audio_hp(audio_hp)
    );

    always #10 clk = ~clk;

    real PI = 3.14159265359;
    real fs = 48000.0;
    real test_freq = 440.0; 
    real amplitude = 16000.0;
    real phase, norm_phase, tri_val;
    integer i, cfg_idx;

    reg [7:0] configs [0:2];

    initial begin
        $dumpfile("tb_audio_filter_core.vcd");
        $dumpvars(0, tb_audio_filter_core);

        configs[0] = 8'h24; 
        configs[1] = 8'h33;
        configs[2] = 8'h16;

        clk = 0; rst_n = 0; spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;
        sample_tick = 0; audio_in = 0; phase = 0.0;
        #2000; rst_n = 1; #2000;

        for (cfg_idx = 0; cfg_idx < 3; cfg_idx = cfg_idx + 1) begin
            rst_n = 0; #1000; rst_n = 1; #1000;
            spi_transaction({8'h80, configs[cfg_idx]});
            
            // SINE WAVE
            phase = 0.0;
            for (i = 0; i < 1000; i = i + 1) begin
                audio_in = $rtoi(amplitude * $sin(phase));
                tick_sample(); advance_phase();
            end
            
            // SQUARE WAVE
            phase = 0.0;
            for (i = 0; i < 1000; i = i + 1) begin
                if (phase < PI) audio_in = $rtoi(amplitude);
                else audio_in = $rtoi(-amplitude);
                tick_sample(); advance_phase();
            end
            
            // TRIANGLE WAVE
            phase = 0.0;
            for (i = 0; i < 1000; i = i + 1) begin
                norm_phase = phase / (2.0 * PI);
                if (norm_phase < 0.25) tri_val = amplitude * (4.0 * norm_phase);
                else if (norm_phase < 0.75) tri_val = amplitude * (1.0 - 4.0 * (norm_phase - 0.25));
                else tri_val = amplitude * (-1.0 + 4.0 * (norm_phase - 0.75));
                audio_in = $rtoi(tri_val);
                tick_sample(); advance_phase();
            end
        end
        $finish;
    end

    task advance_phase;
        begin
            phase = phase + 2.0 * PI * (test_freq / fs);
            if (phase >= 2.0 * PI) phase = phase - 2.0 * PI;
        end
    endtask

    task spi_transaction(input [15:0] data);
        integer i;
        begin
            spi_cs_n = 0; #100; 
            for (i = 15; i >= 0; i = i - 1) begin
                spi_mosi = data[i]; #100; spi_sck = 1; #100; spi_sck = 0;
            end
            #100; spi_cs_n = 1; #100; 
        end
    endtask

    task tick_sample;
        begin
            #20813; 
            @(posedge clk);
            sample_tick = 1'b1;
            @(posedge clk);
            sample_tick = 1'b0;
        end
    endtask
endmodule
