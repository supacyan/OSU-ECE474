module uart_ctrl(
  input                clk_bud, // 1 baud rate 9600
  input              clk_8xbud, // 1 8 x baud rate
  input                    rst, // 1 rst
  input        [16:0] adc_cntr, // 17 adc cntr for send
  input        [15:0]      bcd, // 16 number to send
  input                adc_rdy, // 1 adc ready
  input               uart_rxd, // 1 uart rxd pin
  output logic        uart_txd, // 1 uart txd pin
  output logic [2:0]  adc_ch_s  // 3 adc channel sel 
  );  

  logic [7:0]          tx_data; // 8 tx data 
  logic [7:0]          rx_data; // 8 rx data 
  logic [15:0]        tx_bytes; // reg hold value
  logic [2:0]         char_sel; // character loop
  logic [3:0]        bud_state; // baud send state
  logic [2:0]          rx_cntr; // rx sample cntr
  logic [2:0]      rx_bit_cntr; // rx bit cntr
  logic            edge_detect; // if edge detected
  enum{txIDLE,txSTART,txNEXT,txSTOP}tx_state;
  enum{rxIDLE,EGDET,rxSTART,rxSTOP}rx_state;
  enum{edIDLE,HIGH,LOW,edSTOP}edge_state;

  /*********************************************
  * tx state machine
  *********************************************/
  always_ff @(posedge clk_bud, negedge rst)
  if (!rst)
    tx_state <= txIDLE;
  else
    case (tx_state)
    txIDLE  : tx_state <= (adc_cntr<22)?txSTART:txIDLE;
    txSTART : // not a robust way to start 
    if (bud_state == 9)
      tx_state <= txNEXT;
    else
      bud_state <= bud_state + 1; 
    txNEXT  :  
    if (char_sel == 5)
      tx_state <= txSTOP;
    else
    begin
      char_sel <= char_sel + 1;
      bud_state <= 0;
      tx_state <= txSTART;
    end
    txSTOP  :  
    begin
      char_sel <= 2'd0;
      bud_state <= 4'd10;
      tx_state <= txIDLE;
    end
    endcase

  /*********************************************
  * bcd2ascii
  *********************************************/
  always_ff @(posedge clk_bud, negedge rst)
  if (!rst)
    tx_data <= 0;
  else 
    case (char_sel)
    3'd0    : tx_data <= tx_bytes[15:12]+48;
    3'd1    : tx_data <= 8'd46;
    3'd2    : tx_data <= tx_bytes[11:8]+48;
    3'd3    : tx_data <= tx_bytes[7:4]+48;
    3'd4    : tx_data <= tx_bytes[3:0]+48;
    3'd5    : tx_data <= 8'd13;
    3'd6    : tx_data <= 8'd10;
    default : tx_data <= 8'hff;
    endcase

  /*********************************************
  * shift register 8bits input to 10bits
  *********************************************/
  always_ff @(posedge clk_bud, negedge rst)
  if (!rst)
    uart_txd <= 0;
  else
    case (bud_state)
    4'd0    : uart_txd <= 0;
    4'd1    : uart_txd <= tx_data[0];
    4'd2    : uart_txd <= tx_data[1];
    4'd3    : uart_txd <= tx_data[2];
    4'd4    : uart_txd <= tx_data[3];
    4'd5    : uart_txd <= tx_data[4];
    4'd6    : uart_txd <= tx_data[5];
    4'd7    : uart_txd <= tx_data[6];
    4'd8    : uart_txd <= tx_data[7];
    4'd9    : uart_txd <= 1;
    default : uart_txd <= 1;
    endcase
	
  /*********************************************
  * make sure the data would change during tx
  *********************************************/
  always_ff @(negedge adc_rdy, negedge rst)
  if (!rst)
    tx_bytes <= 0;
  else 
	 tx_bytes <= (char_sel == 0)?bcd:tx_bytes;
	 
  /*********************************************
  * edge detection for rx
  *********************************************/
  always_ff @(posedge clk_8xbud, negedge rst)
  if (!rst)
  begin
    edge_state <= edIDLE;
    edge_detect <= 0;
  end
  else
    case (edge_state)
    edIDLE  : edge_state <= uart_rxd?HIGH:edIDLE;
    HIGH    : edge_state <= uart_rxd?HIGH:LOW;
    LOW     : begin
                edge_detect <= 1;
                edge_state <= edSTOP;
              end
    edSTOP  : begin
                edge_detect <= 0;
                edge_state <= edIDLE;
              end
    endcase
     
  /*********************************************
  * rx state machine
  *********************************************/
  always_ff @(posedge clk_8xbud, negedge rst)
  if (!rst)
  begin
    rx_state <= rxIDLE;
    rx_cntr <= 0;
    rx_bit_cntr <= 0;
    adc_ch_s <= 0;
  end
  else
    case (rx_state)
    rxIDLE  : rx_state <= edge_detect?EGDET:rxIDLE; 
    EGDET   : begin
                rx_cntr <= rx_cntr + 1;
                if (rx_cntr == 2)
                  rx_state <= (uart_rxd==0)?rxSTART:rxIDLE;
              end
    rxSTART : begin
                rx_cntr <= rx_cntr + 1; // rx sample counter
                if (rx_cntr == 2) 
                begin
                  rx_data[rx_bit_cntr] <= uart_rxd;
                  rx_bit_cntr <= rx_bit_cntr + 1;
                  if (rx_bit_cntr == 7)
                    rx_state <= rxSTOP; // not a robust stop
                end
              end
    rxSTOP  : begin
                adc_ch_s <= rx_data - 8'd48;
                rx_cntr <= 0;
                rx_bit_cntr <= 0;
                rx_state <= rxIDLE;
              end
    endcase

endmodule 
