
module HarmonicMean (
    input wire clk,
    input wire reset,
    input wire [15:0] data1,
    input wire [15:0] data2,
    input wire [15:0] data3,
    input wire [15:0] data4,
    input wire data_valid1,
    input wire data_valid2,
    input wire data_valid3,
    input wire data_valid4,
    output reg [15:0] harmonic_mean,
    output reg data_ready
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        harmonic_mean <= 0;
        data_ready <= 0;
    end else if (data_valid1 && data_valid2 && data_valid3 && data_valid4) begin
        // взял из инета:
        //harmonic_mean <= 4 * 65536 / ((65536 / data1) + (65536 / data2) + (65536 / data3) + (65536 / data4));
        
        // гармоническое среднее из ТЗ
        harmonic_mean <= (data1 * data2 * data3 * data4) / (data1 + data2 + data3 + data4);
        
        data_ready <= 1;
    end else begin
        data_ready <= 0;
    end
end

endmodule
