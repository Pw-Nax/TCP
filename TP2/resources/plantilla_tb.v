// 1. EL TIEMPO: Le decimos al simulador cómo medir el tiempo
// "Cada unidad vale 1 nanosegundo, con una precisión de 1 picosegundo"
`timescale 1ns / 1ps

// 2. EL MÓDULO (No tiene puertos)
module tb_mi_sistema;

    // --- PARTE A: Declaración de señales ---
    // Usamos 'reg' para las señales que VAMOS A INYECTAR al DUT
    reg         clk;
    reg         i_rst;
    reg         i_enable;
    
    // Usamos 'wire' para las señales que VAMOS A LEER del DUT
    wire [7:0]  o_datos;
    wire        o_alarma;

    // --- PARTE B: Instanciación del DUT (Device Under Test) ---
    // Traemos nuestro chip a la mesa de trabajo y le conectamos los cables
    mi_chip_genial dut_chip (
        .clk        (clk),
        .i_rst      (i_rst),
        .i_enable   (i_enable),
        .o_datos    (o_datos),
        .o_alarma   (o_alarma)
    );

    // --- PARTE C: Generación del Reloj (El latido del corazón) ---
    // Esto hace que el reloj cambie de estado (invierta su valor) para siempre.
    // El "#5" significa "espera 5 nanosegundos". Por ende, un ciclo completo dura 10ns.
    always #5 clk = ~clk;

    // --- PARTE D: El Guion de Estímulos (Lo que tú controlas) ---
    initial begin
        // 1. Inicialización (Estado seguro)
        // AL EMPEZAR EL TIEMPO CERO, PONEMOS TODO EN UN VALOR CONOCIDO
        clk      = 1'b0;
        i_rst    = 1'b1; // Mantenemos presionado el botón de reset
        i_enable = 1'b0;

        // 2. Liberamos el Reset
        #20;             // Dejamos pasar 20 nanosegundos
        i_rst = 1'b0;    // Soltamos el reset

        // 3. Empezamos a probar el sistema
        #10;             // Esperamos 10 ns
        i_enable = 1'b1; // Encendemos el equipo
        
        // 4. Dejamos que el sistema trabaje
        #100;            // Dejamos pasar 100 ns de simulación

        // 5. Apagamos todo y cerramos la simulación
        i_enable = 1'b0;
        #20;
        $finish;         // ¡Comando mágico que le dice al simulador que cierre el programa!
    end

    // --- PARTE E: (Opcional) Monitor de eventos ---
    // Imprime texto en la consola cuando algo interesante pasa
    always @(posedge o_alarma) begin
        $display("¡CUIDADO! La alarma se encendió en el tiempo %0t", $time);
    end

endmodule