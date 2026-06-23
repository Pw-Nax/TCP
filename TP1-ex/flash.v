module flash 
#(
    parameter NB_LEDS = 4
)
(
    output reg [NB_LEDS - 1 : 0] o_flash,
    input                        i_valid, // Pulso desde el contador
    input                        i_reset, // Reset asíncrono activo en alto
    input                        clock
);
    
    always @(posedge clock or posedge i_reset) begin
        if (i_reset) begin
            o_flash <= {NB_LEDS{1'b1}}; // Todas las salidas en 1
        end
        else if (i_valid) begin
            o_flash <= ~o_flash; // Cambia el estado
        end
        // Si i_valid = 0, mantiene el estado
    end
endmodule