/*--------------------------------------------------------
Módulo: contador_parametrizable
Descripción:
-Contador configurable por parámetros.
-Genera un pulso válido (o_valid) cada vez que llega a un limite
seleccionado con switches.
-Reset asíncrono activo en alto
-------------------------------------------------------*/
module count
#(
    parameter NB_SWITCH      = 4 ,
    parameter NB_COUNTER     = 32 
)
(
    output                    o_valid,
    input [NB_SWITCH - 1 : 0] i_switch,
    input                     i_reset,
    input                     clock   
);
    
    /*-----------------------------------------------------------
      Constantes internas (localparam)
      - No se pueden cambiar desde afuera.
      - Se calculan a partir del ancho del contador.
      - Pensadas para que en simulación (NB_COUNTER chico) sea rápido.
    -----------------------------------------------------------*/
    localparam LIMIT_R0 = (2**(NB_COUNTER-14))-1;
    localparam LIMIT_R1 = (2**(NB_COUNTER-12))-1;
    localparam LIMIT_R2 = (2**(NB_COUNTER-10))-1;
    localparam LIMIT_R3 = (2**(NB_COUNTER- 8))-1;

    /*
    Señales Internas del modulo.
    */

    reg  [NB_COUNTER - 1 : 0] counter;
    reg                       valid;

    // Mux para seleccionar el límite según i_switch[2:1]

    reg [NB_COUNTER - 1 : 0] limit_count;
    always @(*) begin
        case (i_switch[2:1])
            2'b00: limit_count = LIMIT_R0;
            2'b01: limit_count = LIMIT_R1;
            2'b10: limit_count = LIMIT_R2;
            2'b11: limit_count = LIMIT_R3;
            default: limit_count = LIMIT_R0; // Default case
        endcase
    end

    always @(posedge clock or posedge i_reset) begin
        if(i_reset) begin
            counter <= {NB_COUNTER{1'b0}}; // 0;
            valid   <= 1'b0;
        end
        else if(i_switch[0])begin
            if(counter >= limit_count) begin
                counter <= 0;
                valid   <= 1'b1;
            end
            else begin
                counter <= counter + 1;
                valid   <= 1'b0;
            end
        end
        else  begin
            counter <= counter;
            valid   <= valid;
        end
    end

    assign o_valid = valid;

endmodule