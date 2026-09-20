// test/tb_system.v
`default_nettype none
`timescale 1ns / 1ps

module tb_system;
    // --- System Signals ---
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

    // --- Device Under Test ---
    tt_um_audio_filter uut (
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out),
        .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    // --- External Receiver (To verify output multiplexing) ---
    wire signed [15:0] out_tx;
    wire tick_tx;
    i2s_rx tb_rx_out (
        .clk(clk), .rst_n(rst_n), 
        .i2s_sck(i2s_sck), .i2s_ws(i2s_ws), .i2s_sd(uo_out[0]), 
        .data_out(out_tx), .sample_tick(tick_tx)
    );

    // --- Internal Probes ---
    wire signed [15:0] probe_in = uut.audio_in_data;
    wire signed [15:0] probe_lp = uut.audio_lp_data;
    wire signed [15:0] probe_bp = uut.audio_bp_data;
    wire signed [15:0] probe_hp = uut.audio_hp_data;
    wire [1:0]         probe_mux= uut.out_sel;

    // --- Clocks ---
    always #10 clk = ~clk;                 // 50 MHz System Clock
    always #325.52 i2s_sck = ~i2s_sck;     // ~1.536 MHz I2S Clock

    integer fd;

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("tb_system.vcd");
        $dumpvars(0, tb_system);

        // Open CSV file for Python plotting
        fd = $fopen("system_out.csv", "w");
        $fdisplay(fd, "time,mux_sel,out_tx,lp,bp,hp");

        // Initialize
        clk = 0; rst_n = 0; ena = 1;
        i2s_sck = 0; i2s_ws = 0; i2s_sd_in = 0;
        spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;

        #1000; rst_n = 1; #1000;

        // 1. Configure Filter params (Reg 0x00 -> f_shift=4, q_shift=2 -> 0x24)
        spi_transaction(16'h8024);

        // 2. Test Output Multiplexer: THRU (Reg 0x01 -> 0x00)
        spi_transaction(16'h8100);
        send_i2s_sample(16'd5000);
        
        // 3. Test Output Multiplexer: LOW-PASS (Reg 0x01 -> 0x01)
        spi_transaction(16'h8101);
        send_i2s_sample(16'd5000);

        // 4. Test Output Multiplexer: BAND-PASS (Reg 0x01 -> 0x02)
        spi_transaction(16'h8102);
        send_i2s_sample(16'd5000);

        // 5. Test Output Multiplexer: HIGH-PASS (Reg 0x01 -> 0x03)
        spi_transaction(16'h8103);
        send_i2s_sample(16'd5000);

        #50000;
        $fclose(fd);$display("\n[SUCCESS] System simulation completed cleanly!");
        $finish;
    end

    // --- Monitor Printouts & CSV Logging ---
    always @(posedge tick_tx) begin
        if (rst_n) begin
            $display("Time: %0t | Mux Sel: %b | Serial Output: %0d | (Internal LP: %0d, BP: %0d, HP: %0d)", 
                      $time, probe_mux, out_tx, probe_lp, probe_bp, probe_hp);
            $fdisplay(fd, "\%0d,\%b,\%0d,\%0d,\%0d,\%0d", $time, probe_mux, out_tx, probe_lp, probe_bp, probe_hp);
        end
    end

    // --- SPI Transaction Task ---
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

    // --- I2S Sample Task ---
    task send_i2s_sample(input signed [15:0] audio_val);
        integer b;
        begin
            // Left Channel (Active data)
            i2s_ws = 0; @(negedge i2s_sck); i2s_sd_in = 0;
            for (b = 15; b >= 0; b = b - 1) begin
                @(negedge i2s_sck); i2s_sd_in = audio_val[b];
            end
            for (b = 14; b >= 0; b = b - 1) begin
                @(negedge i2s_sck); i2s_sd_in = 0; 
            end

            // Right Channel (Ignored/Zeroed)
            @(negedge i2s_sck); i2s_ws = 1; i2s_sd_in = 0; 
            for (b = 30; b >= 0; b = b - 1) begin
                @(negedge i2s_sck); i2s_sd_in = 0;
            end
        end
    endtask

endmodule
