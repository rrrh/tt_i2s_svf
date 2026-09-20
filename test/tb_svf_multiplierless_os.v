`default_nettype none
`timescale 1ns / 1ps

module tb_svf_multiplierless_os;
    reg clk, rst_n, sample_tick;
    reg [3:0] f_shift, q_shift;
    reg signed [15:0] audio_in;
    
    wire signed [15:0] audio_lp, audio_bp, audio_hp;

    svf_multiplierless #(.DATA_WIDTH(16), .CLK_DIV(100)) uut (
        .clk(clk), .rst_n(rst_n), .sample_tick(sample_tick),
        .f_shift(f_shift), .q_shift(q_shift),
        .audio_in(audio_in), .audio_lp(audio_lp), .audio_bp(audio_bp), .audio_hp(audio_hp)
    );

    always #10 clk = ~clk;

    real PI = 3.14159265359;
    real fs = 48000.0;
    real freq_start = 20.0;
    real freq_end = 20000.0;
    integer total_samples = 4800;
    real current_freq, phase;
    real amplitude = 16000.0;
    integer i;

    initial begin
        $dumpfile("tb_svf_multiplierless_os.vcd");
        $dumpvars(0, tb_svf_multiplierless_os);
        
        clk = 0; rst_n = 0; sample_tick = 0; audio_in = 0; phase = 0.0;
        f_shift = 4'd4; q_shift = 4'd2; 

        #2000; rst_n = 1; #2000;
        
        for (i = 0; i < total_samples; i = i + 1) begin
            current_freq = freq_start + (freq_end - freq_start) * (i * 1.0 / total_samples);
            phase = phase + 2.0 * PI * (current_freq / fs);
            if (phase > 2.0 * PI) phase = phase - 2.0 * PI;
            
            audio_in = $rtoi(amplitude * $sin(phase));
            tick_sample();
        end
        $finish;
    end
    
    task tick_sample;
        begin
            #20813; // 48kHz audio tick on 50MHz clock
            @(posedge clk);
            sample_tick = 1'b1;
            @(posedge clk);
            sample_tick = 1'b0;
        end
    endtask
endmodule
