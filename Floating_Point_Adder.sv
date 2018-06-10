module Floating_Point_Adder(
    input   logic Clock,
    input   logic [63:0]A,B,
    output  logic [63:0]SUM
);
    localparam INIT         = 4'h0,
               IDLE         = 4'h1,
               ACTIVE       = 4'h2,
               NAN_CHECK    = 4'h3,
               INF_CHECK    = 4'h4,
               FINISHED     = 4'h5,
               ONE_INFINITY = 4'h6,
               EXP_CHECK    = 4'h7,
               OPERATION    = 4'h8,
               ADDITION     = 4'h9,
               SUBTRACTION  = 4'hA,
               A_SIGN       = 4'hB,
               LEADING_ZERO = 4'hC,
               SIGN_CHECK   = 4'hD,
               NOT_SIGN     = 4'hE;

    logic [3:0]State = 4'h0;
    logic sgnA,sgnB;
    logic [23:0]mtsA,mtsB,mtsSUM;
    logic [7:0]expA,expB,expSUM;
    logic [24:0]mtsSUM_final;
    always_ff @(posedge Clock) begin
        case(State) begin

        endcase
    end
endmodule