`timescale 1ns / 100ps

//! @title LFSR Checker Paralelo
//! @author Cabero, Mauro Ezequiel
//! @company Laboratorio de Informática y Telecomunicaciones LIT (Curso de Protocolos de Comunicación)
//!
//! @brief Valida el funcionamiento de un generador LFSR externo recibiendo el estado completo en cada ciclo.
//! 
//! Implementa una máquina de estados para indicar si el sistema está sincronizado (LOCKED) o 
//! perdido (UNLOCKED), tolerando hasta un número máximo de fallos consecutivos (3).
//! Como el módulo no conoce la semilla inicial, realiza un "auto-sembrado" leyendo el bus de 
//! entrada en su primer ciclo de operación.

module checker_lfsr #(
    parameter LFSR_WIDTH   = 16,                        //! Ancho de palabra del bus del LFSR.
    parameter COUNTER_FAIL = 3                          //! Cantidad máxima de fallos permitidos antes de perder el lock.
)
(
    // Puertos de control y sincronización
    input  wire                  clk,                   //! Reloj principal del sistema
    input  wire                  i_reset,               //! Reset asincrónico (activo en alto)
    input  wire                  i_soft_rst,            //! Reset sincrónico (activo en alto)
    input  wire                  i_valid,               //! Habilitador de operación (Clock Enable)
    
    // Puertos de datos
    input  wire [LFSR_WIDTH-1:0] i_output_lfsr,         //! Bus paralelo con el valor actual del generador externo
    
    // Salida de estado
    output wire                  o_status_checker       //! 1 (LOCKED) si la secuencia es correcta, 0 (UNLOCKED) si se perdió la sincronía
);

    // ---------------------------------------------------------
    // DECLARACIÓN DE VARIABLES INTERNAS
    // ---------------------------------------------------------
    
    reg                      state, state_next;                 //! Estado actual y futuro de la máquina (LOCKED o UNLOCKED)
    
    reg [2:0]                valid_counter, valid_counter_next; //! Cuenta aciertos consecutivos para lograr el bloqueo (lock)
    reg [1:0]                count_fail, count_fail_next;       //! Cuenta errores consecutivos para perder el bloqueo (unlock)
    reg [31:0]               count_bits_ok, count_bits_ok_next; //! Total histórico de aciertos
    
    reg [LFSR_WIDTH-1:0]     internal_lfsr, internal_lfsr_next; //! Guardan la foto actual del LFSR y calculan el estado del futuro ciclo

    wire                     feedback;                          //! Bit de realimentación calculado internamente
    wire [LFSR_WIDTH-1:0]    expected_next_lfsr;                //! Palabra de 16 bits esperada matemáticamente para el próximo ciclo
    wire                     is_match;                          //! Bandera de comprobación (1 = acierto, 0 = fallo)

    localparam UNLOCKED = 1'b0;                                 //! Estado de sincronía perdida
    localparam LOCKED   = 1'b1;                                 //! Estado de sincronía lograda


    // ---------------------------------------------------------------
    // 1. MOTOR MATEMÁTICO PARALELO (El Predictor)
    // ---------------------------------------------------------------
    // Esta sección calcula de forma combinacional cuál debería ser el 
    // estado exacto del LFSR en el próximo ciclo, utilizando la matemática 
    // Galois en base a nuestro registro actual (internal_lfsr).
    
    // Cálculo del bit de realimentación (Evita el Zero-Lock inyectando un 1 si todo es 0)
    assign feedback = internal_lfsr[15] ^ (internal_lfsr == 16'd0);

    // Mapeo de compuertas XOR según el polinomio utilizado
    assign expected_next_lfsr[0]    = feedback;
    assign expected_next_lfsr[1]    = internal_lfsr[0];
    assign expected_next_lfsr[2]    = internal_lfsr[1] ^ feedback;
    assign expected_next_lfsr[3]    = internal_lfsr[2] ^ feedback;
    assign expected_next_lfsr[4]    = internal_lfsr[3];
    assign expected_next_lfsr[5]    = internal_lfsr[4] ^ feedback;
    assign expected_next_lfsr[15:6] = internal_lfsr[14:5];

    // Se evalúa si la palabra paralela completa recibida coincide con la predicción
    assign is_match = (expected_next_lfsr == i_output_lfsr);
    
    // La salida del módulo refleja directamente el estado actual de la máquina
    assign o_status_checker = state;


    // ---------------------------------------------------------------
    // 2. BLOQUE SECUENCIAL (Flip-Flops y Memoria)
    // ---------------------------------------------------------------
    // En cada flanco de subida del reloj, este bloque actualiza los 
    // registros físicos tomando los valores calculados por la máquina 
    // de estados. También maneja los resets.
    
    always @(posedge clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= UNLOCKED;
            valid_counter <= 3'd0;
            count_bits_ok <= 32'd0;
            count_fail    <= 2'd0;
            internal_lfsr <= {LFSR_WIDTH{1'b0}}; // Inicializa en 0 
        end
        else if (i_soft_rst) begin
            state         <= UNLOCKED;
            internal_lfsr <= {LFSR_WIDTH{1'b0}};
        end
        else if (i_valid) begin 
            // Transferencia de los estados futuros a la memoria física
            state         <= state_next;
            valid_counter <= valid_counter_next;
            count_bits_ok <= count_bits_ok_next;
            count_fail    <= count_fail_next;
            internal_lfsr <= internal_lfsr_next;
        end
    end


    // ---------------------------------------------------------------
    // 3. BLOQUE COMBINACIONAL (Lógica de la Máquina de Estados)
    // ---------------------------------------------------------------
    //  Evalúa los aciertos o fallos para transicionar entre LOCKED y UNLOCKED .
    
    always @(*) begin
        // Valores por defecto (evita la inferencia de Latches)
        state_next         = state;
        valid_counter_next = valid_counter;
        count_bits_ok_next = count_bits_ok;
        count_fail_next    = count_fail;
        internal_lfsr_next = internal_lfsr;

        case (state)
            
            UNLOCKED: begin
                // Auto-sembrado: Copiamos el bus entrante para predecir el próximo ciclo
                internal_lfsr_next = i_output_lfsr;

                if (is_match) begin
                    valid_counter_next = valid_counter + 3'd1;
                    count_bits_ok_next = count_bits_ok + 32'd1;
                    
                    // Si acertamos 5 veces consecutivas (0 a 4), logramos sincronización
                    if (valid_counter == 3'd4) begin
                        state_next = LOCKED;
                    end
                end
                else begin
                    // Al primer error, reiniciamos los contadores de búsqueda
                    valid_counter_next = 3'd0;
                    count_bits_ok_next = 32'd0;
                end
            end
            
            LOCKED: begin
                // Sincronizados: Calculamos internamente el próximo estado esperado
                internal_lfsr_next = expected_next_lfsr;

                if (is_match) begin
                    count_bits_ok_next = count_bits_ok + 32'd1;
                    count_fail_next    = 2'd0; // Un acierto limpia el historial de fallos
                end
                else begin
                    count_fail_next = count_fail + 2'd1;
                    
                    // Histéresis: Perdemos el lock al alcanzar el umbral de errores seguidos
                    if (count_fail == COUNTER_FAIL - 1) begin 
                        valid_counter_next = 3'd0;
                        count_bits_ok_next = 32'd0;
                        count_fail_next    = 2'd0;
                        state_next         = UNLOCKED;
                    end
                end
            end
            
            default: begin
                // Estado de seguridad
                state_next         = UNLOCKED;
                valid_counter_next = 3'd0;
                count_bits_ok_next = 32'd0;
                count_fail_next    = 2'd0;
            end
            
        endcase
    end

endmodule