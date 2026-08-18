`timescale 1ns / 1ps

module tb_lfsr_system;

parameter                 LFSR_WIDTH = 16;

//Generadores de señales
reg                        clk       ;
reg                        reset     ;
reg  [LFSR_WIDTH - 1 : 0 ] i_seed    ;
reg                        i_valid   ;
reg                        i_soft_rst;

wire [LFSR_WIDTH - 1 : 0] lfsr_data ;
wire                      serial_data;
wire                      checker_status;

// Parametros y variables para el test

integer test_id        = 1;


// Instanciación del generador

// Instanciación del generador
lfsr dut_lfsr (
    .clk          (clk),
    .i_rst        (reset),
    .i_soft_rst   (i_soft_rst),
    .i_valid      (i_valid),
    .i_seed       (i_seed),
    .o_lfsr       (lfsr_data),
    .o_serial_out (serial_data) 
);

// Instanciación del checker
checker_lfsr dut_checker (
    .clk           (clk),
    .i_reset       (reset),
    .i_output_lfsr (serial_data), 
    .i_valid       (i_valid),
    .i_seed        (i_seed),
    .o_checker     (checker_status)
);

 
/*TB */


always #5 clk = ~clk;

`include "lfsr_task.vh"


initial begin
    clk = 0;
    test_id = 7;
        $display ("Test seleccionado: %0d", test_id);
    

    // Llamada a la tarea sin paréntesis
    aplicar_reset;

    case (test_id)
    3'd1: test_normal;
    3'd2: test_forzar_error;
    3'd3: test_seed_random;
    3'd4: test_frontera_4v_1i;       // test de umbral
    3'd5: test_reset_aleatorio;      // test de reset random
    3'd6: test_oscilacion_estados;   //  test de transición
    3'd7: test_rafagas_con_metricas_y_resets_variables;
    default: $display("No existe el test %0d", test_id);
endcase

    $finish;
end









endmodule