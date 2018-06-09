module Floating_Point_Adder(
    input   logic Clock,
    input   logic [31:0]A,B,
    output  logic [31:0]SUM
);
    logic [3:0]State = 4'h0;
    logic sgnA,sgnB;
    logic [23:0]mtsA,mtsB,mtsSUM;
    logic [7:0]expA,expB,expSUM;
    logic [24:0]mtsSUM_final;

    always_ff @(posedge Clock) begin

    end
endmodule