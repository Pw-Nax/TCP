`default_nettype none
`timescale 1ns/1ns

module top_leds_tb();

localparam N_SWITCH = 4 ;
localparam N_LED    = 4 ;

wire [N_LED - 1 : 0] o_led  ;
wire [N_LED - 1 : 0] o_led_b;
wire [N_LED - 1 : 0] o_led_g;

reg  [N_SWITCH - 1 : 0] i_sw;
reg                     i_reset;
reg                     clock;

top_leds
u_top_leds
(
//----> Output
  .o_led      (o_led),
  .o_led_b    (o_led_b),
  .o_led_g    (o_led_g),
//----> Inputs
  .i_sw       (i_sw   ),
  .i_reset    (i_reset),
  .clock      (clock  )
);


//----> Generamos clock
initial
begin
  clock   <= 'd0;
end
always #5 clock = ~clock;


//----> Task para el reset
task reset ();
time reset_time;
begin
  //----> Reset en 0
  i_reset <= 'd0;

  //----> Randomizo duracion del reset
  reset_time = $urandom_range(1,100);
  #reset_time;

  //----> Levanto reset de manera sincronica
  @(posedge clock);

  //----> Levanto reset
  i_reset <= 'd1; 
end
endtask


`define TEST1



`ifdef TEST1

// `include "./test1.sv"

  localparam NB_COUNTER = 32;

  reg [N_LED      - 1 : 0] prev_o_led    ;
  reg [NB_COUNTER - 1 : 0] clock_counter ;

  initial
  begin

    force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

    //----> Corremos el test por 100 iteraciones
    for(integer i=0; i<100; i=i+1)
    begin

      //----> Inicializamos las variables
      i_sw[0]       = 'd0;
      i_sw[3:1]     = $urandom_range(0,7);
      prev_o_led    = 'd0;
      clock_counter = 'd0;

      //----> Reset
      reset();

      //----> Habilitamos el contador
      i_sw[0] = 'd1;

      //----> Esperamos un momento random
      #($urandom_range(1,5) * 1us);

      //----> Deshabilitamos el contador y guardamos el valor del led en ese instante.
      i_sw[0]     = 'd0   ;
      prev_o_led  = o_led ;

      //----> Esperamos un momento random.
      clock_counter = $urandom_range(50,500);

      //----> Checkeamos funcionamiento.
      for(integer j=0; j<clock_counter; j=j+1)
      begin
        @(posedge clock);
        if(prev_o_led != o_led)
        begin
          $display("ERROR: El valor del led cambio.");
          $display("TEST FAILED");
          $finish(2);
        end 
      end
    end

    $display("TEST PASSED");
    $finish();
  end
`endif
`ifdef TEST2
`endif 

endmodule