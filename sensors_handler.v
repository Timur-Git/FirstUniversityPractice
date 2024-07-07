
module sensors_handler(
	input wire clk,					
	input wire reset,
	input wire pin_RX,
	output wire LED_TX,
	output wire pin_TX,
	output wire LED_RX
//	input wire spi_miso,
//	output wire spi_clk,
//	output wire spi_cs,
//	output wire spi_mosi
);

wire not_reset = !reset;

///////////////////////////////////////////////////
/*
 * Отсчёт времени для автоматизации отправки данных
 */
///////////////////////////////////////////////////
/*localparam DELAY = 25_000_000;			// отсчитываем 25'000'000 и таким образом поидее получаем 1 Гц для 1 секунды
reg [27:0] cnt = 28'b0;
wire start_cnt = (cnt == DELAY);

always @(posedge clk or posedge not_reset) begin
	if (not_reset)
		cnt <= 28'b0;
	else if (start_cnt) begin
		cnt <= 28'b0;
	end
	else
		cnt <= cnt + 28'b1;
end
*/

//////////////////////////////////////////////////
/*
 * Тестирование UART передатчика
 */
//////////////////////////////////////////////////
/*reg [7:0] tx_data_reg = 8'b0; 		// через этот регистр буду передавать данные в модуль передатчика

wire valid_tx;
assign valid_tx_out = !valid_tx;

always @(posedge clk or posedge not_reset) begin
	if (not_reset)
		tx_data_reg = 8'b0;
	else if (start_cnt)
		tx_data_reg <= 8'b01000110;
end

UARTTransmitter UTx(clk, not_reset, start_cnt, tx_data_reg, pin_TX, valid_tx);
*/

//////////////////////////////////////////////////
/*
 * Тестирование UART приёмника
 */
//////////////////////////////////////////////////
/*wire data_ready;
assign valid_rx_data = !data_ready;

reg pin_RX = 1'b1;
reg [7:0] rx_data = 8'b0;

reg [15:0] clk_cnt = 16'b0;
wire nex_bit = (clk_cnt == 2604);

always @(posedge clk or posedge not_reset) begin
	if (not_reset) begin
		clk_cnt <= 16'b0;
	end
	else if (start_cnt & (state == WAIT)) begin
		clk_cnt <= 16'b0;
	end
	else if (nex_bit) begin
		clk_cnt <= 16'b0;
	end
	else
		clk_cnt <= clk_cnt + 16'b1;
end

reg [3:0] bit_cnt = 4'b0;
reg [1:0] state = 2'b0;

localparam WAIT = 2'b00;
localparam START_BIT = 2'b01;
localparam DATA_BIT = 2'b10;
localparam STOP_BIT = 2'b11;

always @(posedge clk) begin
	case (state)
		WAIT: begin
			if (start_cnt) begin
				pin_RX <= 1'b0;
				rx_data <= 8'b01101010;	// например отправить 01101010 на RX
				state <= START_BIT;
			end
		end
		START_BIT: begin
			if (nex_bit) begin
				bit_cnt <= 4'b0;
				state <= DATA_BIT;
			end
		end
		DATA_BIT: begin
			if (nex_bit) begin
				pin_RX <= rx_data[bit_cnt];
				
				if (bit_cnt == 7) begin
					bit_cnt <= 4'b0;
					state <= STOP_BIT;
				end
				else
					bit_cnt <= bit_cnt + 4'b1;
			end
		end
		STOP_BIT: begin
			if (nex_bit)
				state <= WAIT;
		end
	endcase
end

UARTReceiver URx(clk, not_reset, pin_RX, rx_data_out, data_ready);
*/

//////////////////////////////////////////////////
/*
 * Совмещенное тестирование модуля UART
 */
//////////////////////////////////////////////////
wire start_wire = start;
wire [7:0] data_transmitt = temp;
wire ready_tx;

assign LED_TX = ready_tx;

UARTTransmitter UTX(clk, not_reset, start_wire, data_transmitt, pin_TX, ready_tx);

wire [7:0] data_received;
wire ready_rx;

assign LED_RX = ready_rx;

UARTReceiver URx(clk, not_reset, pin_RX, data_received, ready_rx);

reg start = 1'b0;
reg [7:0] temp = 8'b0;

localparam WAIT 	= 2'b00; 		// ожидание начала приема
localparam RX 		= 2'b01;		// прием данных, ослеживание переключения готовности модуля - окончание приема переход к след. состоянию
localparam VLD_TX	= 2'b10;		// проверка готовности модуля передатчика, ожидание начала передачи если модуль не готов
localparam TX 		= 2'b11;		// передача данных, отслеживание переключения готовности модуля - окончание передачи переход к след. состоянию
reg [1:0] states = WAIT;

//assign states_test = {test_uart_clk, 1'b0}; // запихнул в имеющийся выход нужные отладочные данные

always @(posedge clk or posedge not_reset) begin
	if (not_reset) begin
		start <= 1'b0;
		temp <= 8'b0;
		states <= WAIT;
	end
	else begin
		case (states)
		WAIT: begin
			if (!ready_rx) begin
				states <= RX;
			end
		end
		RX: begin
			if (ready_rx) begin
				temp <= data_received;
				states <= VLD_TX;
			end
		end
		VLD_TX: begin
			if (ready_tx) begin
				start <= 1'b1;
				states <= TX;
			end
		end
		TX: begin
			start <= 1'b0;
			if (ready_tx) begin
				states <= WAIT;
			end
		end
		endcase
	end
end


//////////////////////////////////////////////////
/* 
 *  Управление модулями через UART
 */
//////////////////////////////////////////////////
/*wire start_wire = start_tx_flag;
wire [7:0] data_tx = data_bus;
wire ready_tx;

assign LED_TX = ready_tx; // сигнализируем о передаче с помощью светодиода

UARTTransmitter UTx(
	clk, 
	not_reset, 
	start_wire, 
	data_tx, 
	pin_TX, 
	ready_tx
);

wire [7:0] data_received;
wire ready_rx;

assign LED_RX = ready_rx; // сигнализируем о передаче с помощью светодиода

UARTReceiver URx(
	clk, 
	not_reset, 
	pin_RX, 
	data_received, 
	ready_rx
);

reg start_tx_flag = 1'b0;
reg [7:0] data_bus = 8'b0;

reg [6:0] mem [19:0];
initial begin
	mem[0] = 7'h0a; // перевод строки
	mem[1] = 7'h20; // пробел
	mem[2] = 7'h2b; // плюс
	mem[3] = 7'h2c; // запятая
	mem[4] = 7'h2d; // минус
	mem[5] = 7'h30; // цифры пошли, тут 0
	mem[6] = 7'h31;
	mem[7] = 7'h32;
	mem[8] = 7'h33;
	mem[9] = 7'h34;
	mem[10] = 7'h35;
	mem[11] = 7'h36;
	mem[12] = 7'h37;
	mem[13] = 7'h38;
	mem[14] = 7'h39; // тут 9
	mem[15] = 7'h3a; // двоиточие
	mem[16] = 7'h41; // "A"
	mem[17] = 7'h46; // "F"
	mem[18] = 7'h47; // "G"
	mem[19] = 7'h50; // "P"
end

reg [2:0] count_char = 3'b0;

localparam START 		= 2'b00;
localparam WORK_SENSORS	= 2'b01;
localparam RECEIVE_SET	= 2'b10;
localparam SET_SENSORS	= 2'b11;
reg [1:0] state = START;

reg [31:0] count_time = 32'b0;

always @(posedge clk or posedge not_reset) begin
	if (not_reset) begin
		start_tx_flag <= 1'b0;
		data_bus <= 8'b0;
		count_char <= 3'b0;
		state <= START;
		count_time <= 32'b0;
	end
	else begin
		case (state)
		START: begin
			// Состояние на котором иницилизируются все датчики, сама схема включается и сообщает о включении
			case (count_char)
			3'b000: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[17];
					start_tx_flag <= 1'b1;
					count_char <= 3'b001;
				end
			end
			3'b001: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[19];
					start_tx_flag <= 1'b1;
					count_char <= 3'b010;
				end
			end
			3'b010: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[18];
					start_tx_flag <= 1'b1;
					count_char <= 3'b011;
				end
			end
			3'b011: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[16];
					start_tx_flag <= 1'b1;
					count_char <= 3'b100;
				end
			end
			3'b100: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[15];
					start_tx_flag <= 1'b1;
					count_char <= 3'b101;
				end
			end
			3'b101: begin
				start_tx_flag <= 1'b0;
				if (ready_tx) begin
					data_bus <= mem[0];
					start_tx_flag <= 1'b1;
					count_char <= 3'b111;
				end
			end
			3'b111: begin
				start_tx_flag <= 1'b0;
				state <= WORK_SENSORS;
			end
			endcase
		end
		WORK_SENSORS: begin
			//  Базовое состояние, плис в постоянном цикле параллельно опрашивает все датчики через 
			// определенные промежутки времени, делает матем., расчет в модуле среднего гармонического и 
			// отправляет результаты на управляющий контроллер
			if (next_secund) begin
				if (count_time == 32'hffffffff)
					count_time <= 32'b0;
				else
					count_time <= count_time + 32'b1;
				
				data_bus <= count_time[7:0];
				start_tx_flag <= 1'b1;
			end
			else
				start_tx_flag <= 1'b0;
		end
		RECEIVE_SET: begin
			//  Состояние возникающее по прерыванию, если от управляющего контроллера приходят какие-либо данные,
			// в этих данных определяется команда, если такая есть, и происходит её выполнение
			// (предпологалось что это будут команды по настройке управляющих регистров датчиков)
		end
		SET_SENSORS: begin
			//  Если при приеме команды, были распознаны данные по настройке регистров датчиков, то данные перенаправляются
			// в датчики для их настройки, после чего происходит перезагрузка и возвращение к базовому состоянию с рабочим циклом опроса датчиков
		end
		endcase
	end
end

localparam DELAY = 25_000_000;
reg [27:0] cnt = 28'b0;
wire next_secund = (cnt == DELAY);

always @(posedge clk or posedge not_reset) begin
	if (not_reset)
		cnt <= 28'b0;
	else if (next_secund)
		cnt <= 28'b0;
	else
		cnt <= cnt + 28'b1;
end
*/

//////////////////////////////////////////////////
/*
 * Тестирование SPI
 */
//////////////////////////////////////////////////
/*

reg [7:0] spi_data_input = 8'b0;
wire [7:0] spi_data_output;

always @(posedge clk) begin
	if (start_cnt) begin
		spi_data_input <= 8'b01000110;
	end
end

SPIController SPIMaster(
	clk, 
	not_reset,
	start_cnt, 
	spi_data_input,
	spi_miso, 
	spi_clk,
	spi_cs,
	spi_mosi,
	spi_data_output
);
*/
///////////////////////////////////////////////////
endmodule
///////////////////////////////////////////////////

///////////////////////////////////////////////////
/*
 *	полная сборка
 */
///////////////////////////////////////////////////
/*
module sensors_handler (
    input wire clk,
    input wire reset,
    input wire [3:0] spi_cs,
    input wire spi_clk,
    input wire [3:0] spi_miso,
    input wire uart_rx,
    output wire uart_tx,
    output wire [3:0] spi_mosi
);

wire [15:0] data1, data2, data3, data4;
wire data_valid1, data_valid2, data_valid3, data_valid4;
wire [15:0] harmonic_mean;
wire harmonic_ready;
wire [7:0] rx_data_out;
wire rx_data_ready;
reg [7:0] reg_address;
reg [7:0] reg_data;
reg reg_write;

UARTReceiver URx (
    .clk(clk),
    .reset(reset),
    .rx(uart_rx),
    .data_out(rx_data_out),
    .data_ready(rx_data_ready)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_address <= 0;
        reg_data <= 0;
        reg_write <= 0;
    end 
    else if (rx_data_ready) begin
        // Допустим, что первые байт данных — адрес регистра, и еще два байта - данные для записи в регистр
        reg_address <= rx_data_out[7:0];
        //reg_data <= rx_data_out[15:8];
        reg_write <= 1;
    end 
    else begin
        reg_write <= 0;
    end
end

AccelerometerReceiver acc1 (
    .clk(clk),
    .reset(reset),
    .spi_cs(spi_cs[0]),
    .spi_clk(spi_clk),
    .spi_miso(spi_miso[0]),
    .spi_mosi(spi_mosi[0]),
    .reg_address(reg_address),
    .reg_data(reg_data),
    .reg_write(reg_write),
    .data(data1),
    .data_valid(data_valid1)
);

AccelerometerReceiver acc2 (
    .clk(clk),
    .reset(reset),
    .spi_cs(spi_cs[1]),
    .spi_clk(spi_clk),
    .spi_miso(spi_miso[1]),
    .spi_mosi(spi_mosi[1]),
    .reg_address(reg_address),
    .reg_data(reg_data),
    .reg_write(reg_write),
    .data(data2),
    .data_valid(data_valid2)
);

AccelerometerReceiver acc3 (
    .clk(clk),
    .reset(reset),
    .spi_cs(spi_cs[2]),
    .spi_clk(spi_clk),
    .spi_miso(spi_miso[2]),
    .spi_mosi(spi_mosi[2]),
    .reg_address(reg_address),
    .reg_data(reg_data),
    .reg_write(reg_write),
    .data(data3),
    .data_valid(data_valid3)
);

AccelerometerReceiver acc4 (
    .clk(clk),
    .reset(reset),
    .spi_cs(spi_cs[3]),
    .spi_clk(spi_clk),
    .spi_miso(spi_miso[3]),
    .spi_mosi(spi_mosi[3]),
    .reg_address(reg_address),
    .reg_data(reg_data),
    .reg_write(reg_write),
    .data(data4),
    .data_valid(data_valid4)
);


HarmonicMean hm (
    .clk(clk),
    .reset(reset),
    .data1(data1),
    .data2(data2),
    .data3(data3),
    .data4(data4),
    .data_valid1(data_valid1),
    .data_valid2(data_valid2),
    .data_valid3(data_valid3),
    .data_valid4(data_valid4),
    .harmonic_mean(harmonic_mean),
    .data_ready(harmonic_ready)
);

reg [7:0] tx_data_line = 8'b0;
reg [19:0] count_transmitt = 20'b0;
reg ready_to_transmitt = 1'b0;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		ready_to_transmitt <= 1'b1;
		count_transmitt <= 20'b0;
	end
	else if (harmonic_ready) begin
		if (count_transmitt == 0) begin
			tx_data_line <= harmonic_mean[7:0];
			ready_to_transmitt <= 1'b1;
		end
		else if (count_transmitt == 300000) begin
			tx_data_line <= harmonic_mean[15:8];
			ready_to_transmitt <= 1'b1;
			count_transmitt <= 20'b0;
		end
		else begin
			ready_to_transmitt <= 1'b0;
			count_transmitt <= count_transmitt + 20'b1;
		end
	end
	else 
		ready_to_transmitt <= 1'b0;
end

UARTTransmitter UTx (
    .clk(clk),
    .reset(reset),
    .start(ready_to_transmitt),
    .data(tx_data_line),
    .tx(uart_tx),
    .valid_tx(valid_tx)
);

endmodule
*/
