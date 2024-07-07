
module SPIController(
	input wire clk,
	input wire reset,
	input wire start,
	input wire [7:0] input_data,
	input wire spi_miso,
	output wire spi_clk,
	output reg spi_cs,
	output reg spi_mosi,
	output reg [7:0] output_data
);

reg [4:0] state_num = 5'b11111;
reg [2:0] cnt = 3'b0;

wire bit_start = (cnt == 4);
wire wait_state = (state_num == 5'b11111);

assign spi_clk = bit_start;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		cnt <= 1'b0;
	end
	else if (start && wait_state) begin
		cnt <= 1'b0;
	end
	else if (bit_start) begin
		cnt <= 1'b0;
	end
	else
		cnt <= cnt + 3'h1;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		state_num <= 5'b11111;
		spi_cs <= 1'b1;
		spi_mosi <= 1'b0;
	end
	else if (start && wait_state) begin
		state_num <= 5'b00000;
		spi_cs <= 1'b0;
		spi_mosi <= 1'b0;
	end
	else if (bit_start) begin
		case (state_num)
		5'b00000: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[0];
			state_num <= 5'b00001;
		end
		5'b00001: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[1];
			state_num <= 5'b00010;
		end
		5'b00010: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[2];
			state_num <= 5'b00011;
		end
		5'b00011: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[3];
			state_num <= 5'b00100;
		end
		5'b00100: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[4];
			state_num <= 5'b00101;
		end
		5'b00101: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[5];
			state_num <= 5'b00110;
		end
		5'b00110: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[6];
			state_num <= 5'b10000;
		end
		5'b01111: begin
			spi_cs <= 1'b0;
			spi_mosi <= input_data[7];
			state_num <= 5'b10000;
		end
		5'b10000: begin
			spi_cs <= 1'b1;
			spi_mosi <= 1'b0;
			state_num <= 5'b11111;
		end
		default: begin
			state_num <= 5'b11111;
		end
		endcase
	end
end

endmodule


module AccelerometerReceiver (
    input wire clk,
    input wire reset,
    input wire spi_cs,
    input wire spi_clk,
    input wire spi_miso,
    output reg spi_mosi,
    input wire [7:0] reg_address,
    input wire [7:0] reg_data,
    input wire reg_write,
    output reg [15:0] data,
    output reg data_valid
);

reg [3:0] bit_counter;
reg [15:0] shift_reg;
reg [7:0] config_reg_addr;
reg [7:0] config_reg_data;
reg config_reg_write;
reg [1:0] state;

localparam IDLE = 2'b00;
localparam WRITE_REG = 2'b01;
localparam READ_DATA = 2'b10;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        bit_counter <= 0;
        shift_reg <= 0;
        data <= 0;
        data_valid <= 0;
        config_reg_write <= 0;
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                if (reg_write) begin
                    config_reg_addr <= reg_address;
                    config_reg_data <= reg_data;
                    config_reg_write <= 1;
                    state <= WRITE_REG;
                end else if (~spi_cs) begin
                    state <= READ_DATA;
                end
            end
            WRITE_REG: begin
                if (config_reg_write) begin
                    shift_reg <= {config_reg_addr, config_reg_data};
                    bit_counter <= 0;
                    config_reg_write <= 0;
                end else if (bit_counter < 16) begin
                    spi_mosi <= shift_reg[15 - bit_counter];
                    if (spi_clk) begin
                        bit_counter <= bit_counter + 4'b1;
                    end
                end else begin
                    state <= IDLE;
                end
            end
            READ_DATA: begin
                if (~spi_cs && spi_clk) begin
                    shift_reg <= {shift_reg[14:0], spi_miso};
                    bit_counter <= bit_counter + 4'b1;
                    if (bit_counter == 15) begin
                        data <= shift_reg;
                        data_valid <= 1;
                        state <= IDLE;
                    end
                end else begin
                    bit_counter <= 0;
                    data_valid <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule



/*module SPIController (
	input wire clk,
	input wire reset,
	input wire spi_miso,
	output reg spi_cs,
	output wire spi_clk,
	output reg [7:0] data,
	output reg data_valid
);

reg [2:0] bit_counter;
reg [7:0] shift_reg;

assign spi_clk = clk;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		bit_counter <= 0;
		shift_reg <= 0;
		spi_cs <= 1;
		data <= 0;
		data_valid <= 0;
	end
	else begin
		if (!spi_cs) begin
			shift_reg <= {shift_reg[6:0], spi_miso};
			bit_counter <= bit_counter + 1;
			if (bit_counter == 7) begin
				data <= shift_reg;
				data_valid <= 1;
				spi_cs <= 1; 
			end
		end
		else begin
			spi_cs <= 0;
			bit_counter <= 0;
			data_valid <= 0;
		end
	end
end

endmodule
*/

/* 
 *  Iiaoeu i?eaia aaiiuo ii SPI iaienaiiay ChatGPT 4o, y aoiae ?aai?ay, e iia eae-oi ?aaioaao, 
 * ii y ?aoee iaienaou naie iiaoeu e eae ?aaioaao ii iia iii?aaeeinu aieuoa
 */
/*module SPIController (
    input wire clk,          // Aoiaiie neaiae oaeoiaiai neaiaea
    input wire reset,        // Neaiae na?ina
    input wire spi_cs,       // Neaiae auai?a ono?ienoaa ia SPI (?ei-naeaeo)
    input wire spi_clk,      // Neaiae oaeoiaiai neaiaea SPI
    input wire spi_miso,     // Aoiaiie neaiae aaiiuo io aao?eea ii SPI
    output reg [7:0] data,  // Auoiaiie ?aaeno? aey aaiiuo n aenaea?iiao?a
    output reg data_valid    // Oeaa iaee?ey aaeeaiuo aaiiuo
);

reg [2:0] bit_counter;       // N?ao?ee aeoia aey ionea?eaaiey eiee?anoaa i?eiyouo aeoia
reg [7:0] shift_reg;        // ?aaeno? naaeaa aey i?eaia aaiiuo ii SPI

always @(posedge clk or posedge reset) begin
    if (reset) begin
        bit_counter <= 0;
        shift_reg <= 0;
        data <= 0;
        data_valid <= 0;
    end 
    else begin
        if (~spi_cs) begin  // I?iaa?yai, ?oi ?ei-naeaeo aeoeaai (ieceee o?iaaiu)
            if (spi_clk) begin  // Ia ea?aii oaeoiaii o?iioa SPI
                shift_reg <= {shift_reg[6:0], spi_miso};  // Naaeaaai ?aaeno? e aiaaaeyai iiaue aeo
                bit_counter <= bit_counter + 1;
                if (bit_counter == 7) begin  // Eiaaa ana 16 aeo i?eiyou
                    data <= shift_reg;        // Iaiiaeyai auoiaiie ?aaeno? aaiiuo
                    data_valid <= 1;          // Onoaiaaeeaaai oeaa aaeeaiuo aaiiuo
                end
            end
        end 
        else begin
            bit_counter <= 0;  // Na?anuaaai n?ao?ee aeoia, anee ?ei-naeaeo ia aeoeaai
            data_valid <= 0;   // Na?anuaaai oeaa aaeeaiuo aaiiuo
        end
    end
end

endmodule
*/

/*
 *  ?aaeecaoey iiaoey i?eaia aaiiuo ii SPI i?e iiiiue eiia?iiai aaoiiaoa
 */
/*module SPIController(
    input wire clk,          // Aoiaiie neaiae oaeoiaiai neaiaea
    input wire reset,        // Neaiae na?ina
    input wire spi_cs,       // Neaiae auai?a ono?ienoaa ia SPI
    input wire spi_clk,      // Neaiae oaeoiaiai neaiaea SPI
    input wire spi_miso,     // Aoiaiie neaiae aaiiuo io aao?eea ii SPI
    output reg [7:0] data   // Auoiaiie ?aaeno? aey aaiiuo n aenaea?iiao?a
);

reg state;
reg [3:0] bit_counter;
reg [7:0] shift_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= 4'b0000; // Na?ineou ninoiyiea
    end 
    else begin
        case(state)
            1'b0: begin // I?eaaiea aeoeaaoee ?ei-naeaeoa
                if (spi_cs == 1'b0) begin
                    state <= 1'b1; // Ia?aeoe e ?oaie? aaiiuo
                end
            end
            1'b1: begin // ?oaiea aaiiuo
                shift_reg <= {shift_reg[6:0], spi_miso}; // Nio?aieou i?eiyoua aaiiua
                if (bit_counter == 7) begin
					data <= shift_reg;
					state <= 1'b0; // Aa?ioouny a ninoiyiea i?eaaiey
					bit_counter <= 0;
				end
				else begin
					bit_counter <= bit_counter + 1;
				end
            end
            default: state <= 1'b0; // Aa?ioouny a ninoiyiea i?eaaiey a neo?aa iai?aaaeaaiiiai ninoiyiey
        endcase
    end
end

endmodule
*/