module checker_lfsr #(

parameter          LFSR_SEED = 65535         ,
parameter          LFSR_WIDTH = 16
)
(

//Entradas y sálidas.
input  wire                  clk             , 
input  wire                  i_reset         ,
input  wire                  i_output_lfsr   ,
input  wire                  i_valid         , 
input  wire [LFSR_WIDTH-1:0] i_seed          , 
output wire                  o_checker         // 1 si la secuencia es correcta, 0 si no lo es
);

reg                  state ; //Toma los valores de LOCKED o UNLOCKED
reg                  state_next;
reg [2:0]            valid_counter; // contador de aciertos
reg [2:0]            valid_counter_next;
reg [LFSR_WIDTH-1:0] internal_lfsr;
reg [31:0]           count_bits_ok; 
reg [31:0]           count_bits_ok_next;
 
 //Estados de la máquina de estados
localparam LOCKED   = 1'b1;  //Si acierta 5 veces y se mantiene así
localparam UNLOCKED = 1'b0; // Mientras no acierte 5 veces o erre

wire feedback_expected;
wire bit_match;


assign feedback_expected = internal_lfsr[15] ^ !internal_lfsr;

assign bit_match = (feedback_expected == i_output_lfsr) ? 1'b1 : 1'b0;

assign o_checker = state;
/*

always @(*) lógica combinacional , lee todo dentro del bloque
always (@posedge clk) lógica secuencial, analiza cuando se actualiza


*/

/*

Lógica secuencial para calcular el LFSR interno y el estado del checker

no decido los valores de la máquina de estado.

*/



always @(posedge clk or posedge i_reset) begin
    
    if (i_reset) begin
        state <= UNLOCKED;
        valid_counter <= 3'b000;
        internal_lfsr <= i_seed; // Tengo una duda acá, pues debería ser el valor de la semilla que le ingresamos
         count_bits_ok <= 32'd0;

    end
    else if (i_valid)begin // Si mi señal es válida, actualizo la memoria de mi LFSR
        internal_lfsr[0]     <= i_output_lfsr; 
        internal_lfsr[1]     <= internal_lfsr[0];
        internal_lfsr[2]     <= internal_lfsr[1] ^ i_output_lfsr;
        internal_lfsr[3]     <= internal_lfsr[2] ^ i_output_lfsr;
        internal_lfsr[4]     <= internal_lfsr[3];
        internal_lfsr[5]     <= internal_lfsr[4] ^ i_output_lfsr;
        internal_lfsr[15:6]  <= internal_lfsr[14:5];
        
    // Actualizo la máquina de estados
        state <= state_next;
        valid_counter <= valid_counter_next;
        count_bits_ok <= count_bits_ok_next;

    end



end
// Lógica Combinacional
always @(*) begin

    //Recorda que tenemos estados extras de 'X' y 'Z' (alta impedancia) 

    
    //Valores por defecto
    state_next = state;
    valid_counter_next = valid_counter;
    count_bits_ok_next = count_bits_ok;


    case (state)


    UNLOCKED: begin
        if (bit_match) begin
            valid_counter_next = valid_counter + 3'd1;
            count_bits_ok_next = count_bits_ok + 32'd1;
            if (valid_counter == 3'd4)begin
                state_next = LOCKED;
            end

        end

        else begin
            valid_counter_next      = 3'd0;
             count_bits_ok_next     = 32'd0;
        end
    end

    
    LOCKED: begin
        if (bit_match)begin
             count_bits_ok_next = count_bits_ok + 32'd1;
        end

        else begin
            
            valid_counter_next      = 3'd0;
             count_bits_ok_next     = 32'd0;
            state_next = UNLOCKED;


        end
        
    end

    default: begin
        state_next = UNLOCKED;
        valid_counter_next = 3'd0;
        count_bits_ok_next = 32'd0;
        
    end

 endcase


end


endmodule