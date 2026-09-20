`default_nettype none
`timescale 1ns / 1ps

module tb_bode_os;
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

    integer fd, i, f_val;

    initial begin
        fd = $fopen("bode_data_os.csv", "w");
        $fdisplay(fd, "f_shift,sample,hp,bp,lp");

        clk = 0; rst_n = 0; sample_tick = 0; audio_in = 0;
        q_shift = 4'd2;
        #2000;

        for (f_val = 2; f_val <= 8; f_val = f_val + 2) begin
            f_shift = f_val;
            rst_n = 0; #1000; rst_n = 1; #1000;

            audio_in = 16'd16000;
            tick_sample();
            $fdisplay(fd, "%0d,%0d,%0d,%0d,%0d", f_shift, 0, audio_hp, audio_bp, audio_lp);

            audio_in = 16'd0;
            for (i = 1; i < 16384; i = i + 1) begin
                tick_sample();
                $fdisplay(fd, "%0d,%0d,%0d,%0d,%0d", f_shift, i, audio_hp, audio_bp, audio_lp);
            end
        end
        $fclose(fd);$finish;
    end

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
