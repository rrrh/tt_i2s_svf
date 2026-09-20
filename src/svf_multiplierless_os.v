// src/svf_multiplierless_os.v
`default_nettype none

module svf_multiplierless #(
    parameter DATA_WIDTH = 16,
    parameter CLK_DIV = 100
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    input  wire [3:0]              f_shift,
    input  wire [3:0]              q_shift,
    
    input  wire signed [DATA_WIDTH-1:0] audio_in,
    output wire signed [DATA_WIDTH-1:0] audio_lp,
    output wire signed [DATA_WIDTH-1:0] audio_bp,
    output wire signed [DATA_WIDTH-1:0] audio_hp
);

    reg [6:0] clk_cnt;
    wire os_tick = (clk_cnt == 0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
        end else if (clk_cnt >= CLK_DIV - 1) begin
            clk_cnt <= 0;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end

    reg signed [DATA_WIDTH-1:0] lp_state;
    reg signed [DATA_WIDTH-1:0] bp_state;
    
    wire signed [DATA_WIDTH-1:0] hp_calc = audio_in - lp_state - (bp_state >>> q_shift);
    wire signed [DATA_WIDTH-1:0] bp_next = bp_state + (hp_calc >>> f_shift);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lp_state <= 0;
            bp_state <= 0;
        end else if (os_tick) begin
            bp_state <= bp_next;
            lp_state <= lp_state + (bp_next >>> f_shift);
        end
    end

    assign audio_bp = bp_state;
    assign audio_lp = lp_state;
    assign audio_hp = hp_calc;
endmodule
