`default_nettype none
`timescale 1ns / 1ps

module tb_sine_sweep;
    reg clk, rst_n, spi_cs_n, spi_sck, spi_mosi;
    wire spi_miso;
    reg signed [15:0] audio_in;
    wire signed [15:0] audio_bp;

    audio_filter_core #(.DATA_WIDTH(16), .CLK_DIV(100)) uut (
        .clk(clk), .rst_n(rst_n),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .audio_in(audio_in), .audio_bp(audio_bp)
    );

    always #10 clk = ~clk; 

    real PI = 3.14159265359;
    real fs = 48000.0;
    real f_start = 20.0;
    real f_end = 5000.0; 
    integer total_samples = 48000; 
    
    real current_freq, phase;
    real amplitude = 16000.0;
    integer i, cfg_idx, fd;

    reg [7:0] configs [0:3];

    initial begin
        $dumpfile("tb_sine_sweep.vcd");
        $dumpvars(0, tb_sine_sweep);
        
        fd = $fopen("sweep_data.csv", "w");
        $fdisplay(fd, "f_shift,sample,in,bp");

        configs[0] = 8'h29; 
        configs[1] = 8'h28; 
        configs[2] = 8'h26; 
        configs[3] = 8'h25; 

        clk = 0; rst_n = 0; spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;
        audio_in = 0; phase = 0.0;
        #2000; rst_n = 1; #2000;

        for (cfg_idx = 0; cfg_idx < 4; cfg_idx = cfg_idx + 1) begin
            rst_n = 0; #1000; rst_n = 1; #1000;
            
            // Use the task to safely write the 16-bit configuration word
            spi_transaction({8'h80, configs[cfg_idx]});
            
            phase = 0.0;
            for (i = 0; i < total_samples; i = i + 1) begin
                current_freq = f_start + (f_end - f_start) * (i * 1.0 / total_samples);
                phase = phase + 2.0 * PI * (current_freq / fs);
                if (phase >= 2.0 * PI) phase = phase - 2.0 * PI;
                
                audio_in = $rtoi(amplitude * $sin(phase));
                #20813; // Hold audio sample
                
                $fdisplay(fd, "%0d,%0d,%0d,%0d", configs[cfg_idx][3:0], i, audio_in, audio_bp);
            end
        end
        $fclose(fd);$finish;
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
