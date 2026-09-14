`timescale 1ns / 1ps

module task5_blink_mux (
    input CLOCK,
    input SW0,
    input SW1,
    input SW2,
    output LD15
);
    wire blink_30hz;
    wire blink_3hz;
    wire blink_1hz;

    clock_blink #(.HALF_PERIOD_CYCLES(1_666_667)) gen_30hz (
        .clk(CLOCK),
        .blink(blink_30hz)
    );

    clock_blink #(.HALF_PERIOD_CYCLES(16_666_667)) gen_3hz (
        .clk(CLOCK),
        .blink(blink_3hz)
    );

    clock_blink #(.HALF_PERIOD_CYCLES(50_000_000)) gen_1hz (
        .clk(CLOCK),
        .blink(blink_1hz)
    );

    assign LD15 = SW2 ? blink_1hz :
                  SW1 ? blink_3hz :
                  SW0 ? blink_30hz :
                  1'b0;
endmodule

module clock_blink #(
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
