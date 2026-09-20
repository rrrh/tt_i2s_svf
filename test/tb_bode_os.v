`default_nettype none
`timescale 1ns / 1ps

module tb_bode_os;
    reg clk, rst_n;
    reg [3:0] f_shift, q_shift;
    reg signed [15:0] audio_in;
    wire signed [15:0] audio_bp;

    svf_multiplierless #(.DATA_WIDTH(16), .CLK_DIV(100)) uut (
        .clk(clk), .rst_n(rst_n),
        .f_shift(f_shift), .q_shift(q_shift),
        .audio_in(audio_in), .audio_bp(audio_bp)
    );

    always #10 clk = ~clk;

    integer fd, i, f_val;

    initial begin
        fd = $fopen("bode_data_os.csv", "w");
        $fdisplay(fd, "f_shift,sample,bp");

        clk = 0; rst_n = 0; audio_in = 0;
        q_shift = 4'd2;
        #2000;

        for (f_val = 2; f_val <= 8; f_val = f_val + 2) begin
            f_shift = f_val;
            rst_n = 0; #1000; rst_n = 1; #1000;

            audio_in = 16'd16000;
            #20813; // Hold impulse for one 48kHz period
            $fdisplay(fd, "%0d,%0d,%0d", f_shift, 0, audio_bp);

            audio_in = 16'd0;
            for (i = 1; i < 16384; i = i + 1) begin
                #20813;
                $fdisplay(fd, "%0d,%0d,%0d", f_shift, i, audio_bp);
            end
        end
        $fclose(fd);$finish;
    end
endmodule
