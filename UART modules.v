
/*
 *  Модуль Tx интерфейса UART
 * Описание:
 * - настройка интерфейса является самой базовой (вполне стандартной) 
 * для самого простого использования передатчика uart, параметры дальше описывают стандарт
 * - частота передачи 9600 бод (Bit Rate bits/s)
 * - количество бит данных 8, сформированная одна посылка содержит 8 бит данных + упр. биты (от этого зависит общее ко-во битов посылки)
 * - длительность стоп-бита один бит данных, бывают ставят для уверенности 1.5 и 2 бита (от этого зависит общее ко-во битов посылки)
 * - бит четности отсутсвует, обычно он записывается в конце слова данных до стоп бита (от этого зависит общее ко-во битов посылки)
 * - последовательность передачи бит - данные начинаются с младшего значащего бита, такая последовательность называется LSB first
 * - полярность сигнала, мой сигнал не инвертирован, поэтому значение 0 бита данных = 0 уровню сигнала, 1 бита данных = 1 уровню сигнала
 */
module UARTTransmitter(
	input wire clk,				// тактовый сигнал, он всегда есть
	input wire reset,
	input wire start,			// управляющий сигнал, который мы подаем когда хотим начать передачу данных
	input wire [7:0] data,		// входная линия для данных которые мы хотим передать
	output reg tx,				// сам выход модуля передатчика (в момент когда мы ничего не передаем на линии всегда должна быть 1
	output reg valid_tx			// валидация, показывает когда что-то отправляется (0) и когда отправка прошла успешно (1 до следующей передачи)
);

reg [12:0] cnt = 13'b0;
wire bit_start = (cnt == 2604); // 25 МГц / 2604 = 9600 бод

reg [3:0] bit_num = 4'hf;
wire wait_state = (bit_num == 4'hf);

always @(posedge clk or posedge reset) begin
	if (reset)
		cnt <= 13'b0;
	else if (start && wait_state)
		cnt <= 13'b0;
	else if (bit_start)
		cnt <= 13'b0;
	else
		cnt <= cnt + 13'b1;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		bit_num <= 4'hf;
		tx <= 1'b1;
		valid_tx <= 1'b1;
	end
	else if (start && wait_state) begin
		bit_num <= 4'h0;
		tx <= 1'b0;				// старт бит
		valid_tx <= 1'b0;
	end
	else if (bit_start) begin
		case (bit_num)
		4'h0: begin				// передача первого бита данных
			bit_num <= 4'h1;
			tx <= data[0];		// первым идет младший бит (LSB)
		end
		4'h1: begin
			bit_num <= 4'h2;
			tx <= data[1];
		end
		4'h2: begin
			bit_num <= 4'h3;
			tx <= data[2];
		end
		4'h3: begin
			bit_num <= 4'h4;
			tx <= data[3];
		end
		4'h4: begin
			bit_num <= 4'h5;
			tx <= data[4];
		end
		4'h5: begin
			bit_num <= 4'h6;
			tx <= data[5];
		end
		4'h6: begin
			bit_num <= 4'h7;
			tx <= data[6];
		end
		4'h7: begin
			bit_num <= 4'h8;
			tx <= data[7];
		end
		4'h8: begin				// Передача Стоп бита
			bit_num <= 4'h9;
			tx <= 1'b1;
		end
		default: begin
			bit_num <= 4'hf;
			valid_tx <= 1'b1;
		end
		endcase
	end
end

endmodule

/*
 *	Модуль Rx интерфейса UART - новый вариант
 */
module UARTReceiver (
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] data_out,
    output reg data_ready
//    output wire test_uart_clk
);

wire start = (rx == 1'b0);

reg [15:0] uart_clk_cnt = 16'b0;
wire uart_clk = (uart_clk_cnt == 2604);	// 25МГц / 2604 = 9600 бод

reg only_first = 1'b0;
wire offset_clk = (uart_clk_cnt == 1302); // смещение нужное только для стартовго бита

//assign test_uart_clk = uart_clk;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		uart_clk_cnt <= 16'b0;
		only_first <= 1'b0;
	end
	else if (start & (state == IDLE)) begin
		uart_clk_cnt <= 16'b0;
		only_first <= 1'b1;
	end
	else if (offset_clk & only_first) begin
		uart_clk_cnt <= 16'b0;
		only_first <= 1'b0;
	end
	else if (uart_clk)
		uart_clk_cnt <= 16'b0;
	else
		uart_clk_cnt <= uart_clk_cnt + 16'b1;
end

reg [3:0] bit_counter;
reg [7:0] shift_reg;
reg [1:0] state;

localparam IDLE = 2'b00;
localparam START_BIT = 2'b01;
localparam DATA_BITS = 2'b10;
localparam STOP_BIT = 2'b11;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        bit_counter <= 0;
        shift_reg <= 0;
        data_ready <= 1;
    end 
    else begin
        case (state)
            IDLE: begin
                data_ready <= 1'b1;
                if (start) begin
					data_ready <= 1'b0;
                    state <= START_BIT;
                end
            end
            START_BIT: begin
                if (offset_clk) begin
                    state <= DATA_BITS;
                    bit_counter <= 0;
                end
            end
            DATA_BITS: begin
                if (uart_clk) begin
                    shift_reg[bit_counter] <= rx;
                    
                    if (bit_counter == 7) begin
                        state <= STOP_BIT;
                    end 
                    else begin
                        bit_counter <= bit_counter + 4'b1;
                    end
                end
            end
            STOP_BIT: begin
                if (uart_clk) begin
					if (rx) begin
						data_out <= shift_reg;
						state <= IDLE;
					end
				end
            end
        endcase
    end
end

endmodule
