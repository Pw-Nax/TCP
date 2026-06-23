module shiftregister 
#(
    parameter NB_LEDS = 4 
)
(
    output [NB_LEDS - 1 : 0] o_shift, // Salida del registro de desplazamiento
    input                    i_valid, // Señal de habilitación
    input                    i_dir  , // 0: izquierda, 1: derecha - se conecta en switch[3]
    input                    i_reset, // Reset asíncrono activo en alto
    input                    clock    // Reloj
);
    
    reg [NB_LEDS - 1 : 0] shiftreg;

    always @(posedge clock or posedge i_reset) begin
        if(i_reset) begin
            shiftreg <= {{NB_LEDS-1{1'b0}},1'b1}; // 000...1
        end
        else if(i_valid) begin
            if (i_dir == 1'b0) begin
                // Desplazamiento a la izquierda
                shiftreg <= {shiftreg[NB_LEDS-2:0], shiftreg[NB_LEDS-1]};
            end
            else begin
                // Desplazamiento a la derecha
                shiftreg <= {shiftreg[0], shiftreg[NB_LEDS-1:1]};
            end
        end
    end

    assign o_shift = shiftreg;

endmodule
