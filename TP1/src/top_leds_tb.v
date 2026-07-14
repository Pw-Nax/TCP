/*
Probar usar task creando funciones y despues con un makefile llamar haciendo variables 
'include TEST_FILE INCLUIR "TEST(tests/test_reset.svh)" revisar el makefile para poder meter varios test una regresion
duid , makefile (orquestador de test, usando timings que me permite setear la cantidad de cpu 
lo que hace el makefile es llamarse a si mismo pero para cada uno de los test.)
funcion con times , arma una white card 
 buscar jenkins para correr regresiones.

 para chequear dos cosas al mismo tiempo usamos fork (join) 

 UVM framework basado en system verilog se usa mucho en verificacion 

 verificacion con system verilog
 y diseño con verilog
*/

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

//----> Instanciación del módulo Top
top_leds u_top_leds (
  //----> Output
  .o_led      (o_led),
  .o_led_b    (o_led_b),
  .o_led_g    (o_led_g),
  //----> Inputs
  .i_sw       (i_sw   ),
  .i_reset    (i_reset),
  .clock      (clock  )
);

//----> Generamos clock (100 MHz)
initial begin
  clock   <= 'd0;
end
always #5 clock = ~clock;

//----> Task para el reset
task reset ();
  time reset_time;
  begin
    i_reset <= 'd0; // Reset activo en bajo
    reset_time = $urandom_range(1,100);
    #reset_time;
    @(posedge clock);
    i_reset <= 'd1; // Libera reset
  end
endtask


`define TEST1 



`ifdef TEST1
  initial begin
    $display("TEST 1: Comprobacion Reset");
    
 
    i_sw = 4'b1111;
    i_reset = 1'b0;
    #25; 
    
  
    if (o_led !== 4'b1000 && o_led_b !== 4'b1000 && o_led_g !== 4'b1000) begin
      $display("error: El Shift no se inicializó correctamente en el reset.");
      $display("fail");
      $finish(2);
    end else begin
      $display("Reset inicializa ok.");
    end
    
    
    i_reset = 1'b1;
    #100;
    $display("test 1 ok");
    $finish();
  end
`endif



// TEST 2: Control de Habilitación (Enable / Pause) 

`ifdef TEST2
  localparam NB_COUNTER = 32;
  reg [N_LED      - 1 : 0] prev_o_led    ;
  reg [NB_COUNTER - 1 : 0] clock_counter ;

  initial begin
    $display("TEST 2: Control de Pausa");
    
    // Forzamos límites para simulación rápida
    force u_top_leds.u_counter.limit_0   = 32'h0000_0010;
    force u_top_leds.u_counter.limit_1   = 32'h0000_0020;
    force u_top_leds.u_counter.limit_2   = 32'h0000_0040;
    force u_top_leds.u_counter.limit_3   = 32'h0000_0080;

    for(integer i=0; i<100; i=i+1) begin
      i_sw[0]       = 'd0;
      i_sw[3:1]     = $urandom_range(0,7);
      prev_o_led    = 'd0;
      clock_counter = 'd0;

      reset();
      i_sw[0] = 'd1; // Habilitamos
      #($urandom_range(1,5) * 1us);

      i_sw[0]     = 'd0   ; // pausa
      prev_o_led  = o_led ; // save state

      clock_counter = $urandom_range(50,500);

      // Chequeamos que no se mueva mientras está pausado
      for(integer j=0; j<clock_counter; j=j+1) begin
        @(posedge clock);
        if(prev_o_led != o_led) begin
          $display("error");
          $display("test fail");
          $finish(2);
        end 
      end
    end
    $display("TEST 2 ok");
    $finish();
  end
`endif


// TEST 3: Selección de Límites y Desplazamiento del SR

`ifdef TEST3
  initial begin
    $display("--- INICIANDO TEST 3: Seleccion de Limites (R0 a R3) ---");
    

    force u_top_leds.u_counter.limit_0   = 32'd10;
    force u_top_leds.u_counter.limit_1   = 32'd20;
    force u_top_leds.u_counter.limit_2   = 32'd30;
    force u_top_leds.u_counter.limit_3   = 32'd40;

    reset();
    i_sw[0] = 1'b1; // enable  contador
    
    // Límite R0
    $display("Probando Limite R0");
    i_sw[2:1] = 2'b00; 
    #1000; 
    
    // Límite R1
    $display("Probando Limite R1");
    i_sw[2:1] = 2'b01;
    #2000; 
    
    // Límite R3
    $display("Probando Limite R3");
    i_sw[2:1] = 2'b11;
    #4000;
    
    $display("test 3 terminado: Revisar osciloscopio");
    $finish();
  end
`endif


// TEST 4: Cambio de Límite 

`ifdef TEST4
  initial begin
    $display("TEST 4: Cambio de Limite");
    
    // Límites de prueba
    force u_top_leds.u_counter.limit_0   = 32'd20;
    force u_top_leds.u_counter.limit_3   = 32'd100;

    reset();
    i_sw[0] = 1'b1; // Enable
    
   
    $display("Iniciando  R3 (Lento)");
    i_sw[2:1] = 2'b11; 
    

    repeat(60) @(posedge clock); 
    
  
    $display("Cambio R0");
    i_sw[2:1] = 2'b00;
    
   //run - error

    #1000; 
    
    $display("test 4 finish mira osc.");
    $finish();
  end
`endif

endmodule