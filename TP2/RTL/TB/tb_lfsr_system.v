`timescale 1ns / 1ps

module tb_lfsr_system;

    // ------------------------------------------------
    // PARÁMETROS DEL SISTEMA Y RELOJ
    // ------------------------------------------------
    parameter LFSR_WIDTH = 16;
    parameter real FREQ_MHZ  = 100.0;                  // Frecuencia del reloj
    parameter real HALF_PER  = (1000.0 / FREQ_MHZ) / 2.0;

    // Generadores de señales (Entradas al sistema)
    reg                       clk;
    reg                       reset;
    reg  [LFSR_WIDTH - 1 : 0] i_seed;
    reg                       i_valid;
    reg                       i_soft_rst;

    // ------------------------------------------------
    // CABLES Y CONTROL DE INYECCIÓN DE ERRORES
    // ------------------------------------------------
    wire [LFSR_WIDTH - 1 : 0] lfsr_data_clean;     // Salida real del generador
    wire [LFSR_WIDTH - 1 : 0] lfsr_data_corrupted; // Entrada modificada hacia el checker
    reg  [LFSR_WIDTH - 1 : 0] error_mask = 16'd0;  // Máscara XOR (0 = sin error)

    wire                      serial_data;
    wire                      checker_status;

    // Parámetros y variables para el test
    integer test_id = 1;

    // El "Hombre en el medio": Inyector de errores combinacional
    assign lfsr_data_corrupted = lfsr_data_clean ^ error_mask;

    // ------------------------------------------------
    // INSTANCIACIÓN DEL GENERADOR 
    // ------------------------------------------------
    lfsr dut_lfsr (
        .clk          (clk),
        .i_rst        (reset),
        .i_soft_rst   (i_soft_rst),
        .i_valid      (i_valid),
        .i_seed       (i_seed),
        .o_lfsr       (lfsr_data_clean),  // SALE LIMPIO
        .o_serial_out (serial_data) 
    );

    // ------------------------------------------------
    // INSTANCIACIÓN DEL CHECKER 
    // ------------------------------------------------
    checker_lfsr dut_checker (
        .clk              (clk),
        .i_reset          (reset),
        .i_soft_rst       (i_soft_rst),
        .i_valid          (i_valid),
        .i_output_lfsr    (lfsr_data_corrupted), // ENTRA CON POSIBLE ERROR
        .o_status_checker (checker_status)
    );
 
    // ------------------------------------------------
    // TESTBENCH Y GENERACIÓN DE RELOJ
    // ------------------------------------------------

    // Generación del reloj parametrizado (Corre en paralelo)
    initial begin
        clk = 0;
        forever #(HALF_PER) clk = ~clk;
    end
    
    // Inclusión de las tareas
    `include "lfsr_task.vh"

    // Bloque principal de estímulos
    initial begin
        // Inicialización básica
        test_id = 7;
        
        $display ("\n========================================");
        $display ("  Test seleccionado: %0d", test_id);
        $display ("========================================\n");
    
        // Llamada a la tarea de reset inicial
        aplicar_reset;

        // Selector de pruebas falta agregar las nuevas
  // Selector de pruebas
        case (test_id)
            3'd1: test_normal;
            3'd2: test_forzar_error;
            3'd3: test_seed_random;
            3'd4: test_frontera_4v_1i;           // Test de umbral
            3'd5: test_reset_aleatorio;          // Test de reset random
            3'd6: test_histeresis_tolerancia;    // Test de tolerancia a fallos 
            3'd7: test_error_como_semilla;       // Test de inyección de error como semilla 
            default: $display("No existe el test %0d", test_id);
        endcase

        // Fin de la simulación
        $finish;
    end

endmodule