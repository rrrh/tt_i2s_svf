`default_nettype none
`timescale 1ns / 1ps

module tb_spi_reg_bank;
    reg clk;
    reg rst_n;
    reg spi_cs_n;
    reg spi_sck;
    reg spi_mosi;
    
    wire spi_miso;
    wire [3:0] f_shift_out;
    wire [3:0] q_shift_out;

    spi_reg_bank uut (
        .clk(clk), .rst_n(rst_n),
        .spi_cs_n(spi_cs_n), .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
        .f_shift_out(f_shift_out), .q_shift_out(q_shift_out)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_spi_reg_bank.vcd");
        $dumpvars(0, tb_spi_reg_bank);

        clk = 0; rst_n = 0; spi_cs_n = 1; spi_sck = 0; spi_mosi = 0;
        #100; rst_n = 1; #100;

        spi_transaction(16'h8035);
        #50;
        spi_transaction(16'h0000);
        #100;
        $finish;
    end

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
endmodule
