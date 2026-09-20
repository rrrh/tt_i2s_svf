// src/svf_multiplierless_os.v
`default_nettype none

module svf_multiplierless #(
    parameter DATA_WIDTH = 16,
    parameter CLK_DIV = 100
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    sample_tick, 
    
    input  wire [3:0]              f_shift,
    input  wire [3:0]              q_shift,
    
    input  wire signed [DATA_WIDTH-1:0] audio_in,
    output reg  signed [DATA_WIDTH-1:0] audio_lp,
    output reg  signed [DATA_WIDTH-1:0] audio_bp,
    output reg  signed [DATA_WIDTH-1:0] audio_hp
);

    reg [7:0] clk_cnt;
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

    reg signed [DATA_WIDTH-1:0] audio_in_zoh;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            audio_in_zoh <= 0;
        end else if (sample_tick) begin
            audio_in_zoh <= audio_in;
        end
    end

    reg signed [DATA_WIDTH+3:0] lp_state;
    reg signed [DATA_WIDTH+3:0] bp_state;
    
    function signed [DATA_WIDTH-1:0] saturate(input signed [DATA_WIDTH+3:0] val);
        begin
            if (val > 20'sd32767) begin
                saturate = 16'sd32767;
            end else if (val < -20'sd32768) begin
                saturate = -16'sd32768;
            end else begin
                saturate = val[DATA_WIDTH-1:0];
            end
        end
    endfunction
    
    wire signed [DATA_WIDTH+3:0] hp_calc;
    wire signed [DATA_WIDTH+3:0] bp_next;
    
    assign hp_calc = audio_in_zoh - lp_state - (bp_state >>> q_shift);
    assign bp_next = bp_state + (hp_calc >>> f_shift);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lp_state <= 0;
            bp_state <= 0;
        end else if (os_tick) begin
            bp_state <= bp_next;
            lp_state <= lp_state + (bp_next >>> f_shift);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            audio_lp <= 0;
            audio_bp <= 0;
            audio_hp <= 0;
        end else if (sample_tick) begin
            audio_bp <= saturate(bp_state);
            audio_lp <= saturate(lp_state);
            audio_hp <= saturate(hp_calc);
        end
    end
endmodule
