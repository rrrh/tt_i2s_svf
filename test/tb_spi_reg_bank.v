// test/tb_spi_reg_bank.v
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

    // Instantiate UUT
    spi_reg_bank uut (
        .clk(clk),
        .rst_n(rst_n),
        .spi_cs_n(spi_cs_n),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .f_shift_out(f_shift_out),
        .q_shift_out(q_shift_out)
    );

    // 50 MHz System Clock
    always #10 clk = ~clk;

    integer errors;
    reg [15:0] rx_val;

    initial begin
        $dumpfile("tb_spi_reg_bank.vcd");
        $dumpvars(0, tb_spi_reg_bank);

        // Initialize
        errors = 0;
        clk = 0;
        rst_n = 0;
        spi_cs_n = 1;
        spi_sck = 0;
        spi_mosi = 0;

        #200;
        rst_n = 1;
        #200;

        $display("==================================================");
        $display("   SPI Register Bank Self-Verifying Testbench");
        $display("==================================================");

        // ----------------------------------------------------
        // Test 1: Check hardware defaults
        // ----------------------------------------------------
        if (f_shift_out !== 4'd4 || q_shift_out !== 4'd2) begin
            $display("[FAIL] Defaults incorrect. Expected f=4, q=2. Got f=%0d, q=%0d", f_shift_out, q_shift_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Hardware reset defaults are correct.");
        end

        // ----------------------------------------------------
        // Test 2: Write to Reg 0x00 (Set q=3, f=5 -> 8'h35)
        // ----------------------------------------------------
        spi_transfer(16'h8035, rx_val);
        #200; // Let internal logic settle
        if (f_shift_out !== 4'd5 || q_shift_out !== 4'd3) begin
            $display("[FAIL] Write 0x35 failed. Got f=%0d, q=%0d", f_shift_out, q_shift_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Write transaction successfully updated configuration outputs.");
        end

        // ----------------------------------------------------
        // Test 3: Read from Reg 0x00
        // ----------------------------------------------------
        spi_transfer(16'h0000, rx_val);
        if ((rx_val & 16'h00FF) !== 16'h0035) begin
            $display("[FAIL] Read 0x00 failed. Expected 0x35, got 0x%02x", (rx_val & 16'h00FF));
            errors = errors + 1;
        end else begin
            $display("[PASS] Read transaction verified configuration state (0x35).");
        end

        // ----------------------------------------------------
        // Test 4: Write to Reg 0x00 (Set q=10, f=11 -> 8'hAB)
        // ----------------------------------------------------
        spi_transfer(16'h80AB, rx_val);
        #200;
        if (f_shift_out !== 4'd11 || q_shift_out !== 4'd10) begin
            $display("[FAIL] Write 0xAB failed. Got f=%0d, q=%0d", f_shift_out, q_shift_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Subsequent Write transaction successful.");
        end

        // ----------------------------------------------------
        // Test 5: Read from invalid/reserved Reg 0x01
        // ----------------------------------------------------
        spi_transfer(16'h0100, rx_val);
        if ((rx_val & 16'h00FF) !== 16'h0000) begin
            $display("[FAIL] Read invalid address failed. Expected 0x00, got 0x%02x", (rx_val & 16'h00FF));
            errors = errors + 1;
        end else begin
            $display("[PASS] Reading invalid address safely returned 0x00.");
        end

        // ----------------------------------------------------
        // Final Results
        // ----------------------------------------------------
        $display("==================================================");
        if (errors == 0) begin
            $display("   [SUCCESS] All SPI Register Bank tests passed!");
        end else begin
            $display("   [ERROR] %0d test(s) failed.", errors);
        end
        $display("==================================================");
        $finish;
    end

    // Task to emulate an SPI Master (Mode 0) executing a full-duplex transfer
    task spi_transfer(input [15:0] tx_data, output [15:0] rx_data);
        integer i;
        begin
            spi_cs_n = 0;
            rx_data = 16'h0000;
            
            // Allow time for the 3-stage CS_n synchronizer to detect active low
            #200; 
            
            for (i = 15; i >= 0; i = i - 1) begin
                spi_mosi = tx_data[i];
                #200; // Setup time before rising edge
                
                spi_sck = 1; // Slave samples MOSI internally ~3 cycles after this edge
                #200; // Hold SCK high
                
                rx_data[i] = spi_miso; // Sample the MISO line while SCK is high
                
                spi_sck = 0; // Slave updates MISO internally ~3 cycles after this edge
                #200; // Hold SCK low to allow slave MISO to propagate
            end
            
            spi_cs_n = 1;
            #200; // Delay between consecutive SPI transactions
        end
    endtask

endmodule
