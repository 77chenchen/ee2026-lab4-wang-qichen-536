`timescale 1ns / 1ps

module gpt4_wang_qichen_536 (
    input CLOCK,
    input [15:0] sw,
    input btnC,
    input btnU,
    input btnL,
    input btnR,
    input btnD,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an
);
    wire startup_done;
    wire [15:0] startup_led_mask;
    wire blink_025hz;
    wire blink_5hz;
    wire blink_23hz;
    wire unlocked;
    wire [2:0] display_char;
    wire [1:0] display_digit;

    startup_sequencer #(
        .TIME_COUNT_CYCLES(178_000_000),
        .TOTAL_LEDS(9)
    ) startup (
        .clk(CLOCK),
        .done(startup_done),
        .led_mask(startup_led_mask)
    );

    blink_generator #(.HALF_PERIOD_CYCLES(200_000_000)) blink_slow (
        .clk(CLOCK),
        .blink(blink_025hz)
    );

    blink_generator #(.HALF_PERIOD_CYCLES(10_000_000)) blink_mid (
        .clk(CLOCK),
        .blink(blink_5hz)
    );

    blink_generator #(.HALF_PERIOD_CYCLES(2_173_913)) blink_fast (
        .clk(CLOCK),
        .blink(blink_23hz)
    );

    button_unlock_fsm unlock_fsm (
        .clk(CLOCK),
        .enabled(startup_done),
        .btnC(btnC),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .unlocked(unlocked),
        .display_char(display_char),
        .display_digit(display_digit)
    );

    sevenseg_one_char sevenseg (
        .enabled(startup_done),
        .char_code(display_char),
        .digit_index(display_digit),
        .seg(seg),
        .an(an)
    );

    led_controller leds (
        .startup_done(startup_done),
        .startup_led_mask(startup_led_mask),
        .sw(sw),
        .blink_025hz(blink_025hz),
        .blink_5hz(blink_5hz),
        .blink_23hz(blink_23hz),
        .unlocked(unlocked),
        .led(led)
    );
endmodule

module startup_sequencer #(
    parameter integer TIME_COUNT_CYCLES = 178_000_000,
    parameter integer TOTAL_LEDS = 9
) (
    input clk,
    output done,
    output [15:0] led_mask
);
    reg [31:0] timer = 32'd0;
    reg [3:0] lit_count = 4'd0;

    assign done = (lit_count >= TOTAL_LEDS);
    assign led_mask = (lit_count == 4'd0) ? 16'h0000 : ((16'h0001 << lit_count) - 16'h0001);

    always @(posedge clk) begin
        if (!done) begin
            if (timer == TIME_COUNT_CYCLES - 1) begin
                timer <= 32'd0;
                lit_count <= lit_count + 4'd1;
            end else begin
                timer <= timer + 32'd1;
            end
        end
    end
endmodule

module blink_generator #(
    parameter integer HALF_PERIOD_CYCLES = 50_000_000
) (
    input clk,
    output reg blink = 1'b0
);
    reg [31:0] count = 32'd0;

    always @(posedge clk) begin
        if (count == HALF_PERIOD_CYCLES - 1) begin
            count <= 32'd0;
            blink <= ~blink;
        end else begin
            count <= count + 32'd1;
        end
    end
endmodule

module led_controller (
    input startup_done,
    input [15:0] startup_led_mask,
    input [15:0] sw,
    input blink_025hz,
    input blink_5hz,
    input blink_23hz,
    input unlocked,
    output reg [15:0] led
);
    always @(*) begin
        led = startup_led_mask;

        if (startup_done) begin
            led = 16'h01E3;       // LD8..LD5, LD1 and LD0 stay ON after Subtask A.
            led[2] = 1'b1;
            led[3] = 1'b1;
            led[4] = 1'b1;

            if (sw[4]) begin
                led[4] = blink_23hz;
            end else if (sw[3]) begin
                led[3] = blink_5hz;
            end else if (sw[2]) begin
                led[2] = blink_025hz;
            end

            led[15] = unlocked;
        end
    end
endmodule

module button_unlock_fsm (
    input clk,
    input enabled,
    input btnC,
    input btnU,
    input btnL,
    input btnR,
    input btnD,
    output reg unlocked = 1'b0,
    output reg [2:0] display_char = 3'd4,
    output reg [1:0] display_digit = 2'd0
);
    localparam [2:0] CHAR_C = 3'd0;
    localparam [2:0] CHAR_L = 3'd1;
    localparam [2:0] CHAR_U = 3'd2;
    localparam [2:0] CHAR_R = 3'd3;

    reg [2:0] step = 3'd0;
    reg [4:0] btn_meta = 5'd0;
    reg [4:0] btn_sync = 5'd0;
    reg [4:0] btn_prev = 5'd0;
    wire [4:0] btn_now = {btnD, btnR, btnL, btnU, btnC};
    wire [4:0] btn_edge = btn_sync & ~btn_prev;

    reg correct_press;

    always @(*) begin
        correct_press = 1'b0;
        display_char = CHAR_C;
        display_digit = 2'd0;

        case (unlocked ? 3'd0 : step)
            3'd0: begin
                display_char = CHAR_C;
                display_digit = 2'd0;  // rightmost anode
                correct_press = btn_edge[0]; // BTNC
            end
            3'd1: begin
                display_char = CHAR_L;
                display_digit = 2'd1;
                correct_press = btn_edge[2]; // BTNL
            end
            3'd2: begin
                display_char = CHAR_U;
                display_digit = 2'd2;
                correct_press = btn_edge[1]; // BTNU
            end
            3'd3: begin
                display_char = CHAR_R;
                display_digit = 2'd3;
                correct_press = btn_edge[3]; // BTNR
            end
            3'd4: begin
                display_char = CHAR_C;
                display_digit = 2'd0;
                correct_press = btn_edge[0]; // BTNC
            end
            3'd5: begin
                display_char = CHAR_L;
                display_digit = 2'd1;
                correct_press = btn_edge[2]; // BTNL
            end
            default: begin
                display_char = CHAR_C;
                display_digit = 2'd0;
                correct_press = 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        btn_meta <= btn_now;
        btn_sync <= btn_meta;
        btn_prev <= btn_sync;

        if (!enabled) begin
            step <= 3'd0;
            unlocked <= 1'b0;
        end else if (!unlocked && correct_press) begin
            if (step == 3'd5) begin
                unlocked <= 1'b1;
                step <= 3'd0;
            end else begin
                step <= step + 3'd1;
            end
        end
    end
endmodule

module sevenseg_one_char (
    input enabled,
    input [2:0] char_code,
    input [1:0] digit_index,
    output reg [7:0] seg,
    output reg [3:0] an
);
    localparam [2:0] CHAR_C = 3'd0;
    localparam [2:0] CHAR_L = 3'd1;
    localparam [2:0] CHAR_U = 3'd2;
    localparam [2:0] CHAR_R = 3'd3;

    always @(*) begin
        an = 4'b1111;
        seg = 8'b1111_1111;

        if (enabled) begin
            an = ~(4'b0001 << digit_index);

            case (char_code)
                CHAR_C: seg = 8'b1110_0101; // c
                CHAR_L: seg = 8'b1110_0011; // l
                CHAR_U: seg = 8'b1000_0011; // u
                CHAR_R: seg = 8'b1111_0101; // r
                default: seg = 8'b1111_1111;
            endcase
        end
    end
endmodule
