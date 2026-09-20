// src/i2s_tx.v
`default_nettype none

module i2s_tx (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire        i2s_sck,
    input  wire        i2s_ws,
    output reg         i2s_sd,
    
    input  wire signed [15:0] data_in
);

    reg [2:0] sck_sync;
    reg [2:0] ws_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_sync <= 0;
            ws_sync  <= 0;
        end else begin
            sck_sync <= {sck_sync[1:0], i2s_sck};
            ws_sync  <= {ws_sync[1:0],  i2s_ws};
        end
    end

    wire sck_fall = (sck_sync[2:1] == 2'b10);
    wire ws_edge  = (ws_sync[2:1]  == 2'b01) || (ws_sync[2:1] == 2'b10);
    
    reg [4:0]  bit_cnt;
    reg [15:0] shift_reg;
    reg        transmitting;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2s_sd       <= 0;
            bit_cnt      <= 0;
            shift_reg    <= 0;
            transmitting <= 0;
        end else begin
            if (ws_edge) begin
                bit_cnt      <= 0;
                shift_reg    <= data_in;
                transmitting <= 1;
            end
            
            if (sck_fall && transmitting) begin
                i2s_sd    <= shift_reg[15];
                shift_reg <= {shift_reg[14:0], 1'b0};
                bit_cnt   <= bit_cnt + 1;
                
                if (bit_cnt == 5'd15) begin
                    transmitting <= 0;
                end
            end
        end
    end
endmodule
