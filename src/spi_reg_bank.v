// src/spi_reg_bank.v
`default_nettype none

module spi_reg_bank (
    input  wire       clk,
    input  wire       rst_n,
    
    input  wire       spi_cs_n,
    input  wire       spi_sck,
    input  wire       spi_mosi,
    output reg        spi_miso,
    
    output wire [3:0] f_shift_out,
    output wire [3:0] q_shift_out,
    output wire [1:0] out_sel
);

    reg [7:0] reg_00_ctrl;
    reg [1:0] reg_01_mux;
    
    assign q_shift_out = reg_00_ctrl[7:4];
    assign f_shift_out = reg_00_ctrl[3:0];
    assign out_sel     = reg_01_mux;

    reg [2:0] sck_sync;
    reg [2:0] cs_n_sync;
    reg [1:0] mosi_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_sync  <= 3'b000;
            cs_n_sync <= 3'b111;
            mosi_sync <= 2'b00;
        end else begin
            sck_sync  <= {sck_sync[1:0], spi_sck};
            cs_n_sync <= {cs_n_sync[1:0], spi_cs_n};
            mosi_sync <= {mosi_sync[0], spi_mosi};
        end
    end

    wire sck_rise  = (sck_sync[2:1] == 2'b01);
    wire sck_fall  = (sck_sync[2:1] == 2'b10);
    wire cs_n_act  = ~cs_n_sync[1];
    wire cs_n_fall = (cs_n_sync[2:1] == 2'b10);

    reg [15:0] shift_reg;
    reg [7:0]  read_data;  
    reg [4:0]  bit_cnt;
    reg        is_write;
    reg [6:0]  req_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_00_ctrl <= 8'h24; 
            reg_01_mux  <= 2'b10; // Default to Band-Pass
            bit_cnt     <= 0;
            shift_reg   <= 0;
            read_data   <= 0;
            is_write    <= 0;
            req_addr    <= 0;
            spi_miso    <= 0;
        end else begin
            if (cs_n_fall) bit_cnt <= 0;
            
            if (cs_n_act) begin
                if (sck_rise) begin
                    shift_reg <= {shift_reg[14:0], mosi_sync[1]};
                    bit_cnt   <= bit_cnt + 1;
                    
                    if (bit_cnt == 7) begin
                        is_write <= shift_reg[6];
                        req_addr <= {shift_reg[5:0], mosi_sync[1]};
                    end
                    
                    if (bit_cnt == 15 && is_write) begin
                        if (req_addr == 7'h00) reg_00_ctrl <= {shift_reg[6:0], mosi_sync[1]};
                        if (req_addr == 7'h01) reg_01_mux  <= {shift_reg[0], mosi_sync[1]};
                    end
                end
                
                if (sck_fall) begin
                    if (!is_write) begin
                        if (bit_cnt == 8) begin
                            if (req_addr == 7'h00) begin
                                spi_miso  <= reg_00_ctrl[7];
                                read_data <= {reg_00_ctrl[6:0], 1'b0};
                            end else if (req_addr == 7'h01) begin
                                spi_miso  <= 1'b0;
                                read_data <= {6'b0, reg_01_mux};
                            end else begin
                                spi_miso  <= 1'b0;
                                read_data <= 8'h00;
                            end
                        end else if (bit_cnt > 8) begin
                            spi_miso  <= read_data[7];
                            read_data <= {read_data[6:0], 1'b0};
                        end
                    end
                end
            end else begin
                spi_miso <= 0;
            end
        end
    end
endmodule
