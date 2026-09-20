`default_nettype none
`timescale 1ns / 1ps

module tb_system;
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

    always #10 clk = ~clk;
    always #325.52 i2s_sck = ~i2s_sck;

    real PI = 3.14159265359;
    real fs = 48000.0;
    real freq = 440.0;
    real phase = 0.0;
    real amplitude = 16000.0;
    
    integer fd, cfg_idx;
    reg [7:0] configs [0:2];

    initial begin
        $dumpfile("tb_system.vcd");
        $dumpvars(0, tb_system);
        
        fd = $fopen("system_out.csv", "w");
        $fdisplay(fd, "f_shift,in,lp,bp,hp");

        clk = 0; rst_n = 0; ena = 1;
        i2s_sck = 0; i2s_ws = 0; i2s_sd_in = 0;
        spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;

        configs[0] = 8'h2A;
        configs[1] = 8'h28;
        configs[2] = 8'h26;

        #1000; rst_n = 1; #1000;

        fork
            i2s_master_process();
            test_sequence();
        join
        
        $fclose(fd);$finish;
    end

    always @(negedge uut.sample_ready) begin
        if (rst_n) begin
            $fdisplay(fd, "%0d,%0d,%0d,%0d,%0d", 
                      uut.u_core.f_shift_cfg, 
                      uut.audio_in_data, uut.audio_lp_data, 
                      uut.audio_bp_data, uut.audio_hp_data);
        end
    end

    task test_sequence;
        begin
            for (cfg_idx = 0; cfg_idx < 3; cfg_idx = cfg_idx + 1) begin
                spi_transaction({8'h80, configs[cfg_idx]});
                #15000000;
            end
        end
    endtask

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

    task i2s_master_process;
        integer bit_idx, sample_val;
        reg [15:0] current_audio;
        begin
            forever begin
                sample_val = $rtoi(amplitude * $sin(phase));
                current_audio = sample_val[15:0];
                
                phase = phase + 2.0 * PI * (freq / fs);
                if (phase > 2.0 * PI) phase = phase - 2.0 * PI;

                i2s_ws = 0;
                @(negedge i2s_sck);
                i2s_sd_in = 0;
                
                for (bit_idx = 15; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck);
                    i2s_sd_in = current_audio[bit_idx];
                end
                
                for (bit_idx = 14; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck);
                    i2s_sd_in = 0; 
                end

                @(negedge i2s_sck);
                i2s_ws = 1; i2s_sd_in = 0; 
                for (bit_idx = 15; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck); i2s_sd_in = 0;
                end
                for (bit_idx = 14; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                    @(negedge i2s_sck); i2s_sd_in = 0;
                end
            end
        end
    endtask
endmodule
