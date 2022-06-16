`timescale 1ns / 1ps

module test;

reg reset, clk;

reg [7:0] a;
reg [7:0] b;
reg start;
wire busy;
wire [15:0] y_bo;

integer i, j;
reg [7:0] expected_val;


accel accel_t(
	.clk_i(clk),
	.rst_i(reset),
	.start_i(start),
	.a_in(a),
	.b_in(b),
	.busy_out(busy),
	.y_out(y_bo)
);

always #10 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    
    #10
    
    reset = 1'b0;
    
    for (i = 0; i < 15; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            start = 1'b1;
            
            a = i;    
            b = j * j * j;
            
            #20
            
            start = 1'b0;
            
            expected_val = 3 * a + 2 * j;
            
            @(negedge busy);
            #10
            
            $display("3 * %d + 2 * cube(%d) = %d", a, b, y_bo);
            
            if (expected_val == y_bo) begin
                $display("CORRECT: %d", y_bo);
            end else begin
                $display("ERROR! Expected: %d, got: %d", expected_val, y_bo);
            end         
        end
    end 
	reset = 1'b1;	
	#100 $stop;
end

endmodule