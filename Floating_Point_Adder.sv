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
            /**
              * A strong control pattern for storing bits, with two control inputs.
              * 
              * Finite State Machines in Hardware - Theory and Design Volnei A. Pedroni pg 16-17
              */
            Store_a: 
            begin
                temp_a_acknowledgment <= 1;
                if (A_store_bit && temp_a_acknowledgment) begin
                    a <= A;
                    temp_a_acknowledgment <= 0;
                    State <= Store_b;
                end
            end
            /**
              * A strong control pattern for storing bits, with two control inputs.
              *
              * Finite State Machines in Hardware - Theory and Design Volnei A. Pedroni pg 16-17 
              */
            Store_b: 
            begin
                temp_b_acknowledgment <= 1;
                if (B_store_bit && temp_b_acknowledgment) begin
                    b <= B;
                    temp_b_acknowledgment <= 0;
                    State <= Unpack;
                end
            end
            /**
              * Unpacks the contents of a and b for further processing.
              * 
              *   
              */
            Unpack:
            begin

                a_sign      <= a[63];
                b_sign      <= a[63];
                a_exponent  <= a[62 : 52] - 11'h3FF;
                b_exponent  <= b[62 : 52] - 11'h3FF;
                a_mantissa  <= {a[51 : 0], 3'h0};
                b_mantissa  <= {b[51 : 0], 3'h0};
                State       <= Limiting_Cases;

            end

            /**
              * Many operations result in values that cannot be represented, we call 
              * these limiting cases. A short list of limiting cases examples:
              *
              * 1/0 = infinity
              * any positive value / 0 = positive infinity
              * any negative value / 0 = negative infinity
              * infinity * any value = infinity
              * 1/infinity = 0
              *
              * 0/0 = NaN
              * 0 * infinity = NaN
              * infinity * infinity = NaN
              * infinity - infinity = NaN
              * infinity/infinity = NaN
              *
              * any value + NaN = NaN
              * NaN + any value = NaN
              * any value - NaN = NaN
              * NaN - any value = NaN
              * sqrt(negative value) = NaN
              * NaN * any value = NaN
              * NaN * 0 = NaN
              * 1/NaN = NaN
              * 
              * In this case I attempt to take of most of the limiting cases. 
              *
              * If you are reading this module after the fact and hex values are hard
              * to understand I suggest inputing the hex value I have for each
              * part into rapid tables (https://www.rapidtables.com/convert/number/hex-to-binary.html)
              * and seeing for yourself what it outputs. Each value is very specific as to why it is what
              * it is. I am attempting to adhere strictly to the IEEE-754 standard.
              * https://en.wikipedia.org/wiki/IEEE_754
              * 
              * The idea for this state came from reading:
              * http://pages.cs.wisc.edu/~markhill/cs354/Fall2008/notes/flpt.apprec.html
              */

            Limiting_Cases:
            begin

                if (a_exponent == 11'h400 && a_mantissa != 0 || b_exponent == 11'h400 && b_mantissa != 0) begin
                    sum     <= 64'hFFF8000000000000;
                    State   <= SUM_output;
                end else if (a_exponent == 11'h400) begin
                    sum     <= {a_sign, 63'h7FF0000000000000};
                    sum     <= b_exponent == 10'h400 && (a_sign != b_sign) ?  64'hFFF8000000000000 : sum;
                    state   <= SUM_output;
                end else if (b_exponent == 11'h400) begin
                    sum     <= {b_sign, 63'h7FF0000000000000};
                    state   <= SUM_output;
                end else if ((($signed(a_exponent) == -11'h3FF) && (a_mantissa == 0)) && (($signed(b_exponent) == -10'h3FF) && (b_mantissa == 0))) begin
                    sum     <= {a_sign & b_sign,b_exponent[10:0] + 11'h3FF,b_mantissa[55:3]};
                    State   <= SUM_output;
                end else if (($signed(a_exponent) == -11'h3FF) && (a_mantissa == 0)) begin
                    sum     <= {b_sign,b_exponent[10:0] + 11'h3FF,b_mantissa[55:3]}
                    State   <= SUM_output;
                end else if (($signed(b_e) == -11'h3FF) && (b_m == 0)) begin
                    sum     <= {a_sign,a_exponent[10:0] + 11'h3FF,a_mantissa[55:3]}
                    State   <= SUM_output;
                end else begin
                    if ($signed(b_exponent) == -11'h3FF) begin
                        b_exponent <= -11'h3FE;
                    end else begin
                        b_mantissa[55] <= 1'h1;
                    end
                end
                State       <= Alignment;
            end
            /**
              * The first step in doing addition or subtraction on flaoting point numbers
              * is to align radix points. 
              * 
              * We first shift the matissa by 1 bit to the right. This ensures that
              * the bits that fall off the end come from the least significant end
              * of the mantissa. Since we shifted the matissa to the right we must also
              * add 1 to the exponent. 
              */

            Alignment:
            begin
                if ($signed(a_exponent) > $signed(b_exponent)) begin
                    b_mantissa <= b_mantissa >> 1;
                    b_exponent <= b_exponent + 1;
                    b_mantissa[0] <= b_mantissa[0] | b_mantissa[1];
                  end else if ($signed(a_exponent) < $signed(b_exponent)) begin
                    a_mantissa <= a_mantissa >> 1;
                    a_exponent <= a_exponent + 1;
                    a_mantissa[0] <= a_mantissa[0] | a_mantissa[1];
                  end else begin
                    State <= Add_0;
                  end 
            end

            Add_0:
            begin
                sum_exponent <= a_exponent;
                if (a_sign != b_sign) begin
                    if (a_mantissa > b_mantissa) begin
                        Unrounded_Sum <= {1'd0, a_mantissa} - b_mantissa;
                        sum_sign <= a_sign;
                    end else begin
                        Unrounded_Sum <= {1'd0, b_mantissa} - a_mantissa;
                        sum_sign <= b_sign;
                    end
                end else begin
                    Unrounded_Sum <= {1'd0, a_mantissa} + b_mantissa;
                    sum_sign <= a_sign;
                end
                State <= Add_1;
            end
            
            Add_1:
            begin
                if (Unrounded_Sum[56]) begin
                    sum_mantissa <= Unrounded_Sum[56:4];
                    guard_bit <= Unrounded_Sum[3];
                    round_bit <= Unrounded_Sum[2];
                    sticky_bit <= Unrounded_Sum[1] | Unrounded_Sum[0];
                    sum_exponent <= sum_exponent + 1;
                end else begin
                    sum_mantissa <= Unrounded_Sum[55:3];
                    guard_bit <= Unrounded_Sum[2];
                    round_bit <= Unrounded_Sum[1];
                    sticky_bit <= Unrounded_Sum[0];
                end
                State <= Normalize_0;
            end

            Normalize_0:
            begin
                if (sum_mantissa[52] == 0 && $signed(sum_exponent) > -11'h3FE) begin
                    sum_exponent <= sum_exponent - 1;
                    sum_mantissa <= sum_mantissa << 1;
                    sum_mantissa[0] <= guard_bit;
                    guard_bit <= round_bit;
                    round_bit <= 0;
                end else Normalize_1
            end

            Normalize_1:
            begin
                if ($signed(sum_exponent) < -11'h3FE) begin
                    sum_exponent <= sum_exponent + 1;
                    sum_mantissa <= sum_mantissa >> 1;
                    guard_bit <= sum_mantissa[0];
                    round_bit <= guard_bit;
                    sticky_bit <= sticky_bit | round_bit;
                end else State <= Round;
            end

            Round:
            begin
                if ((round_bit | sticky_bit | sum_mantissa[0]) && guard_bit) begin
                    sum_mantissa <= sum_mantissa + 1;
                    sum_exponent <= (sum_mantissa == 53'h1FFFFFFFFFFFFF) ? sum_exponent + 1 : sum_exponent; 
                end
                State <= Pack;
            end

        endcase
    end
endmodule