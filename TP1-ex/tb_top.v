`timescale 1ns/100ps

module tb_top ();

    parameter NB_SW      = 4  ;
    parameter NB_BTN     = 4  ;
    parameter NB_COUNTER = 16  ;   // bajo para simular más rápido
    parameter NB_LEDS    = 4  ;

    // DUT signals
    wire [NB_LEDS - 1 : 0] o_led_r ;
    wire [NB_LEDS - 1 : 0] o_led_g ;
    wire [NB_LEDS - 1 : 0] o_led_b ;
    wire [NB_LEDS - 1 : 0] o_led   ;

    reg [NB_SW - 1 : 0]    i_sw    ;
    reg [NB_BTN - 1 : 0]   i_btn   ;
    reg                    i_reset ;
    reg                    clock   ;

    // Clock
    always #5 clock = ~clock;

    // --F - F  ---
    task pulse_btn(input integer id);
    begin
        @(posedge clock);
        i_btn[id] = 1'b1;
        #25;
        @(posedge clock);
        i_btn[id] = 1'b0;
    end
    endtask

    task set_speed(input [1:0] speed, integer hold_time);
    begin
        @(posedge clock);
        i_sw[2:1] = speed;
        #(hold_time);
    end
    endtask

    // --- Estímulo ---
    initial begin
       
        clock   = 1'b0;
        i_reset = 1'b1;
        i_sw    = 4'b0000;
        i_btn   = 4'b0000;

        // Reset inicial
        #20;
        i_reset = 1'b0;   // liberar reset

        // ---- Enable contador ----
        @(posedge clock);
        i_sw[0] = 1'b1;
        i_sw[1] = 1'b1;
        i_sw[2] = 1'b0; // R0

        // ---- Probar colores ----
        #20; pulse_btn(1);   // Rojo
        #20; pulse_btn(2);   // Verde
        #20; pulse_btn(3);   // Azul
        #20; pulse_btn(1);   // Volver a Rojo

        // ---- Probar velocidades ----
        set_speed(2'b00, 1000); // R0
        #50; pulse_btn(2);
        set_speed(2'b01, 1000); // R1
        #50; pulse_btn(3);
        set_speed(2'b10, 1000); // R2
        #50; pulse_btn(2);
        set_speed(2'b11, 1000); // R3

        // ---- Cambiar dirección SR ----
        @(posedge clock);
        i_sw[3] = 1'b1;
        #200;
        @(posedge clock);
        i_sw[3] = 1'b0;
        #300;

        // ---- Cambiar a modo Flash ----
        $display("t=%0t | Mode flash", $time);
        #200; pulse_btn(0); // Toggle a FS
        #2000;
        pulse_btn(0); // Volver a SR
        #2000;

        // ---- Apagar enable (todo se congela) ----
        @(posedge clock);
        i_sw[0] = 1'b0;
        #500;
        @(posedge clock);
        i_sw[0] = 1'b1;  // reanudar
        #1000;
        // ---- Finalizar simulación ----

        $finish;
    end

    // --- Monitoreo ---
    initial begin
        $monitor("t=%0t | R=%b G=%b B=%b | o_led=%b | SW=%b BTN=%b reset=%b",
                  $time, o_led_r, o_led_g, o_led_b, o_led, i_sw, i_btn, i_reset);
    end

    // --- Instancia del DUT ---
    top 
    #(
        .NB_SWITCH (NB_SW) ,
        .NB_BTN    (NB_BTN) ,
        .NB_COUNTER(NB_COUNTER) ,
        .NB_LEDS   (NB_LEDS) 
    )
    u_top 
    (
        .o_led_r (o_led_r),
        .o_led_g (o_led_g),
        .o_led_b (o_led_b),
        .o_led   (o_led),

        .i_sw    (i_sw),
        .i_btn   (i_btn),
        .i_reset (i_reset),
        .clock   (clock)       
    );
    
endmodule
