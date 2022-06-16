`timescale 1ns / 1ps

module accel(
	input rst_i,
	input clk_i,
	input start_i,
	input [7 : 0] a_in,
	input [7 : 0] b_in,
	output busy_out,
	output reg [15 : 0] y_out
);

    wire [15 : 0] result;

    reg [7 : 0] a, b;
    reg [2 : 0] state, state_next;

    localparam IDLE = 3'b000;
    localparam CUBE_ON = 3'b001;
    localparam CUBE_WORK = 3'b010;
    localparam MUL_ON = 3'b011;
    localparam MUL_WORK = 3'b100;

    wire [7:0] cube1_out;
    wire cube1_busy;
    reg cube1_start;
    
    wire [7:0] double_cube_res;

    cube cube1(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(b),
        .start_i(cube1_start),
        .busy_o(cube1_busy),
        .y_bo(cube1_out)
    );

    wire [15 : 0] mul1_out;
    wire mul1_busy;
    reg mul1_start;

    mul mul1(
    	.clk_i(clk_i),
    	.rst_i(rst_i),
    	.a_bi(a),
    	.b_bi(3),
    	.start_i(mul1_start),
    	.busy_o(mul1_busy),
    	.y_bo(mul1_out)
    );

    assign busy_out = rst_i | (state != 0);
    assign double_cube_res = cube1_out << 1;
    assign result = double_cube_res + mul1_out;

    always @(posedge clk_i)
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end

// *_ON states are needed to apply some latency to give modules more time to work
    always @* begin
        case(state)
            IDLE:  state_next <= (start_i) ? CUBE_ON : IDLE;
            CUBE_ON: state_next <= CUBE_WORK;
            CUBE_WORK: state_next <= (cube1_busy) ? CUBE_WORK : MUL_ON;
            MUL_ON: state_next <= MUL_WORK;
            MUL_WORK: state_next <= (mul1_busy) ? MUL_WORK : IDLE; 
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            y_out <= 0;
            cube1_start <= 1'b0;
            mul1_start <= 1'b0;
        end else begin
            case (state)
                IDLE:
                    begin
                    if (start_i) begin
                       a <= a_in;
                       b <= b_in;
                       cube1_start <= 1'b1;
                       end
                    end
                CUBE_WORK:
                    begin
                        cube1_start <= 1'b0;
                        if (!cube1_busy) begin
                            mul1_start <= 1'b1;
                        end
                    end
                MUL_WORK:
                    begin
                        mul1_start <= 1'b0;
                        if (!mul1_busy) begin
                            y_out <= result;
                        end
                    end
            endcase
        end
    end
endmodule