`timescale 1ns / 100ps

module tb_lfsr_generator();

   
    parameter LFSR_WIDTH = 16;
    
    // Entradas al módulo (registros para poder cambiar su valor)
    reg                     clock;
    reg                     i_rst;
    reg                     i_soft_reset;
    reg                     i_valid;
    reg  [LFSR_WIDTH-1:0]   i_seed;
    
    // Salidas del módulo (cables para leer el valor)
    wire [LFSR_WIDTH-1:0]   o_lfsr;

    lfsr lfsr_dut (
        .clock(clock),
        .i_rst(i_rst),
        .i_soft_reset(i_soft_reset),
        .i_valid(i_valid),
        .i_seed(i_seed),
        .o_lfsr(o_lfsr)
    );

 
    // Invierte la señal cada 10ns (Periodo de 100ns = 10 MHz)
    always #50 clock = ~clock;

   
    initial begin
    
        // Estado Inicial (Tiempo 0)
        clock        = 0;
        i_rst        = 0;
        i_soft_rst = 0;
        i_valid      = 0;
        i_seed       = 16'hDEAD; // Semilla de prueba para el soft_reset (1101 1110 1010 1101)

        // Prueba 1: Reset Asincrónico 
        $display("Aplicando Reset Asincrónico");
        #15 i_rst = 1;  // Se activa en un momento random (15ns)
        #20 i_rst = 0;

        #20;

        // Prueba 2: Reset Sincrónico ---
        $display("Aplicando Reset Sincronico");
        @(posedge clock); // Espera al flanco de subida
        i_soft_reset = 1;
        @(posedge clock); // Mantiene por un ciclo
        i_soft_reset = 0;

        #20;

        // Prueba 3: Habilitar Generación 
        $display("Iniciando generacion de secuencia");
        @(posedge clock);
        i_valid = 1;

        #100;

        // Prueba 4: Pausar Generación 
        $display("Pausa en la generacion de secuencia");
        @(posedge clock); 
        i_valid = 0;

        #40;

        // --- Fin de la simulación ---
        $display("FIN");
        $finish;
    end

endmodule