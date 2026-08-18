



task aplicar_reset;
    begin
        $display("[%0t] Aplicando Reset...", $time);
        reset      = 1'b1;
        i_soft_rst = 1'b0;
        i_valid    = 1'b0;
        i_seed     = $random;
        #20; 
        reset      = 1'b0;
        #10;
    end
endtask

task test_normal;
    begin
        $display("[%0t] TEST: Sincronizacion Normal", $time);
        i_valid = 1'b1; 
        #300; 
        if (checker_status == 1'b1)
            $display("   -> [EXITO] El Checker llego a LOCKED.");
        else
            $display("   -> [FALLO] El Checker NO llego a LOCKED.");
    end
endtask

task test_forzar_error;
    begin
        $display("[%0t] TEST: Inyeccion de Error", $time);
        i_valid = 1'b1; 
        #200; // Dejamos que llegue a LOCKED
        
        $display("[%0t] Forzando error (apagando generador)...", $time);
        i_valid = 1'b0; 
        #100; 
        
        if (checker_status == 1'b0)
            $display("   -> [EXITO] El Checker detecto el error y volvio a UNLOCKED.");
        else
            $display("   -> [FALLO] El Checker se quedo en LOCKED.");
    end
endtask


task test_seed_random;
    begin
    $display("%0t TEST: semilla random" , $time );
    i_soft_rst = 1'b1;
    i_seed     = $random;
    #10; 
    i_soft_rst = 1'b0;
    #10;


    i_valid    = 1'b1;
    #350;

    if (checker_status == 1'b1)
        $display("%0t  TODO OK" , $time);
    else
        $display("%0t ERROR con el bit" , $time) ;

    i_valid  = 1'b0;

    $display("%0t Debería volver a UNLOCKED" , $time);

    




    end
endtask



// 1. TEST DE FRONTERA: 4 válidos y 1 inválido

task test_frontera_4v_1i;
    integer i;
    begin
        $display("[%0t] TEST umbrales (4 validos, 1 invalido)", $time);
        i_valid = 1'b1;
        
       
        for (i = 0; i < 5; i = i + 1) begin
        
            #40; 
            // Inyectamos 1 error forzado antes de que llegue al quinto
            force dut_checker.i_output_lfsr = ~serial_data;
            #10;
            release dut_checker.i_output_lfsr;
        end
        
        #50;
        if (checker_status == 1'b0)
            $display("test OK - Checker no locked");
        else
            $display("test fail - el Checker se lockeo con el error ingresado.");
        
        i_valid = 1'b0;
        #20;
    end
endtask


// 2. TEST DE RESET EN MOMENTO ALEATORIO

task test_reset_aleatorio;
    integer tiempo_random;
    begin
        $display("[%0t] test  inyectando Reset en un momento aleatorio", $time);
        i_valid = 1'b1;
        
       //Espero a que el sistema se lockee
        wait(checker_status == 1'b1);
        $display("[%0t] Sistema LOCKED detectado.", $time);
        
        // Generamos un desfase aleatorio entre 10ns y 70ns usando $random
        tiempo_random = ($random % 60) + 10;
        #tiempo_random;
        
        $display("[%0t] Reset RANDOM", $time);
        reset = 1'b1;
        #20;
        reset = 1'b0;
        
        // Verificamos estado de sistema sistema
        #300;
        if (checker_status == 1'b1)
            $display("Test OK -  El Checker se recupero del reset random y volvio a LOCKED.");
        else
            $display("  TEST FAIL El Checker no entro a LOCKED.");
        
        i_valid = 1'b0;
        #20;
    end
endtask


// 3. TEST DE TRANSICIÓN Y OSCILACIÓN (Valid/Invalid)

task test_oscilacion_estados;
    begin
        $display("[%0t] TEST: Probando transiciones entre LOCKED y UNLOCKED", $time);
        i_valid = 1'b1;
        
        // 1. Esperamos a que llegue a LOCKED por primera vez
        wait(checker_status == 1'b1);
        $display("[%0t] Primer LOCKED alcanzado con exito.", $time);
        #50;
        
        // 2. Forzamos errores consecutivos para forzar la caída a UNLOCKED
        $display("[%0t] Forzando errores ", $time);
        force dut_checker.i_output_lfsr = ~serial_data; #10;
        force dut_checker.i_output_lfsr = ~serial_data; #10;
        force dut_checker.i_output_lfsr = ~serial_data; #10;
        release dut_checker.i_output_lfsr;
        
        #50;
        if (checker_status == 1'b0)
            $display("[%0t] Transicion exitosa a UNLOCKED confirmada.", $time);
            
        // 3. Dejamos que se recupere y vuelva a lockearse solo con tráfico limpio
        #200;
        if (checker_status == 1'b1)
            $display(" Test OK - volvio a LOCKED tras el desenganche");
        else
            $display(" FAIL El sistema no pudo re-engancharse.");

        i_valid = 1'b0;
        #20;
    end
endtask

task test_rafagas_con_metricas_y_resets_variables;
    integer racha;
    integer tipo_reset;
    integer duracion_rafaga;
    begin
        $display("[%0t] test random rafagas y resets", $time);
        
        // Ejecutamos 4 rondas de prueba de estrés
        for (racha = 0; racha < 4; racha = racha + 1) begin
            
            // 1. Definimos una duración aleatoria para la ráfaga (entre 20 y 80 ciclos)
            duracion_rafaga = ($random % 60) + 20;
            $display("[%0t] --- rafaga %0d iniciada (duracion: %0d ciclos) ---", $time, racha, duracion_rafaga);
            
            i_valid = 1'b1;
            
            // Dejamos correr el tráfico el tiempo estipulado
            repeat(duracion_rafaga) @(posedge clk);
            
            // 2. Decidimos al azar qué tipo de reset aplicar (0 = Hard Reset, 1 = Soft Reset)
            tipo_reset = $random % 2;
            
            if (tipo_reset == 0) begin
                // --- HARD RESET ---
                $display("[%0t] i_reset ON, Bits ok acumulados antes del corte: %0d", 
                         $time, dut_checker.count_bits_ok);
                reset = 1'b1;
                #20;
                reset = 1'b0;
            end 
            else begin
                // --- SOFT RESET CON NUEVA SEMILLA ---
                $display("[%0t] i_reset_soft ON Aplicando SOFT RESET (Cambio de semilla). Bits OK acumulados: %0d", 
                         $time, dut_checker.count_bits_ok);
                i_soft_rst = 1'b1;
                i_seed     = $random; // Inyectamos una semilla totalmente nueva al vuelo
                #10;
                i_soft_rst = 1'b0;
            end
            
            // 3. Damos un respiro para ver cómo el sistema se recupera y vuelve a lockearse
            #150;
        end
        
        i_valid = 1'b0;
        $display("[%0t] TEST  finalizado ok.", $time);
    end
endtask