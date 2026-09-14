`timescale 1ns / 1ps

module task6_one_led_per_second (
    input CLOCK,
    output [3:0] LEDS
);
    wire one_second_tick;
    wire [1:0] count;

    one_second_tick_generator tick_gen (
        .clk(CLOCK),
        .tick(one_second_tick)
    );

    second_counter counter (
        .clk(CLOCK),
        .tick(one_second_tick),
        .count(count)
    );

    led_decoder led_control (
        .count(count),
        .leds(LEDS)
    );
endmodule

module one_second_tick_generator (
    input clk,
    output reg tick = 1'b0
);
    reg [26:0] count = 27'd0;

    always @(posedge clk) begin
        if (count == 100_000_000 - 1) begin
            count <= 27'd0;
            tick <= 1'b1;
        end else begin
            count <= count + 27'd1;
            tick <= 1'b0;
        end
    end
endmodule

module second_counter (
    input clk,
    input tick,
    output reg [1:0] count = 2'b00
);
    always @(posedge clk) begin
        if (tick) begin
            count <= count + 2'b01;
        end
    end
endmodule

module led_decoder (
    input [1:0] count,
    output reg [3:0] leds
);
    always @(*) begin
        case (count)
            2'b00: leds = 4'b0001;
            2'b01: leds = 4'b0010;
            2'b10: leds = 4'b0100;
            2'b11: leds = 4'b1000;
            default: leds = 4'b0001;
        endcase
    end
endmodule
