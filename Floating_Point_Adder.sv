/**
  * http://pages.cs.wisc.edu/~markhill/cs354/Fall2008/notes/flpt.apprec.html
  */

module Floating_Point_Adder(
    input   logic Clock,Reset,A_store_bit,B_store_bit,
    input   logic [63:0]A,B,
    output  logic A_acknowledgment,B_acknowledgment,SUM_acknowledgment,SUM_store_bit,
    output  logic [63:0]SUM
);
    localparam Store_a          = 4'h0,
               Store_b          = 4'h1,
               Unpack           = 4'h2,
               Limiting_Cases   = 4'h3,
               Alignment        = 4'h4,
               Add_0            = 4'h5,
               Add_1            = 4'h6,
               Normalize_0      = 4'h7,
               Normalize_1      = 4'h8,
               Round            = 4'h9,
               Pack             = 4'hA,
               SUM_output       = 4'hB;


    logic temp_SUM_store_bit,temp_a_acknowledgment,temp_b_acknowledgment;
    logic [63:0]temp_SUM;

    logic [3:0]State;

    logic [63:0]a,b,sum;
    logic [55:0]a_mantissa,b_mantissa;
    logic [52:0]sum_mantissa;
    logic [12:0]a_exponent,b_exponent,sum_exponent;
    logic a_sign,b_sign,sum_sign;
    logic guard_bit,round_bit,sticky_bit;
    logic [56:0]Unrounded_Sum;
    always_ff @(posedge Clock) begin
        case(State)

            Store_a: 
            begin
                temp_a_acknowledgment <= 1;
                if (A_store_bit && temp_a_acknowledgment) begin
                    a <= A;
                    temp_a_acknowledgment <= 0;
                    State <= Store_b;
                end
            end

            Store_b: 
            begin
                temp_b_acknowledgment <= 1;
                if (B_store_bit && temp_b_acknowledgment) begin
                    b <= B;
                    temp_b_acknowledgment <= 0;
                    State <= Unpack;
                end
            end

            Unpack:
            begin

                a_sign      <= a[63];
                b_sign      <= a[63];
                a_exponent  <= a[62 : 52] - 10'h3FF;
                b_exponent  <= b[62 : 52] - 10'h3FF;
                a_mantissa  <= {a[51 : 0], 3'h0};
                b_mantissa  <= {b[51 : 0], 3'h0};
                State       <= Limiting_Cases;
            end

        endcase
    end
endmodule