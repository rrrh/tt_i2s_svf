// src/i2s_rx.v
`default_nettype none

module i2s_rx (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire        i2s_sck,
    input  wire        i2s_ws,
    input  wire        i2s_sd,
    
    output reg signed [15:0] data_out,
    output reg         sample_tick
);

    reg [2:0] sck_sync;
    reg [2:0] ws_sync;
    reg [1:0] sd_sync;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_sync <= 0;
            ws_sync  <= 0;
            sd_sync  <= 0;
        end else begin
            sck_sync <= {sck_sync[1:0], i2s_sck};
            ws_sync  <= {ws_sync[1:0],  i2s_ws};
            sd_sync  <= {sd_sync[0],    i2s_sd};
        end
    end

    wire sck_rise = (sck_sync[2:1] == 2'b01);
    wire ws_edge  = (ws_sync[2:1]  == 2'b01) || (ws_sync[2:1] == 2'b10);
    wire ws_state = ws_sync[2]; 
    
    reg [4:0]  bit_cnt;
    reg [15:0] shift_reg;
    reg        receiving;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out    <= 0;
            sample_tick <= 0;
            bit_cnt     <= 0;
            shift_reg   <= 0;
            receiving   <= 0;
        end else begin
            sample_tick <= 0;
            
            if (ws_edge) begin
                bit_cnt   <= 0;
                receiving <= 1;
            end
            
            if (sck_rise && receiving) begin
                shift_reg <= {shift_reg[14:0], sd_sync[1]};
                bit_cnt   <= bit_cnt + 1;
                
                if (bit_cnt == 5'd15) begin
                    receiving <= 0;
                    if (ws_state == 1'b0) begin 
                        data_out    <= {shift_reg[14:0], sd_sync[1]};
                        sample_tick <= 1'b1;
                    end
                end
            end
        end
    end
endmodule
