// =========================================================================
// ARCHIVO: lfsr_task.vh
// DESCRIPCION: Tareas de estimulo y Aserciones para el sistema LFSR
// =========================================================================

task aplicar_reset;
    begin
        $display("[%0t] Aplicando Reset Sincronizado...", $time);
        reset      = 1'b1;
        i_soft_rst = 1'b0;
        i_valid    = 1'b0;
        i_seed     = $random;
        error_mask = 16'd0; 
        
        repeat(3) @(posedge clk); 
        reset      = 1'b0;
        repeat(2) @(posedge clk); 
    end
endtask

task test_normal;
    begin
        $display("[%0t] TEST 1: Sincronizacion Normal", $time);
        i_valid    = 1'b1; 
        error_mask = 16'd0;
        
        repeat(25) @(posedge clk); 

        // --- ASSERTION ---
        // Esperamos que el estado obtenido sea 1 (LOCKED)
        assert (checker_status == 1'b1) 
            else $error("[%0t] ASSERTION FAIL: El Checker esperaba estar en LOCKED (1) y obtuvo %0b", $time, checker_status);
        
        if (checker_status == 1'b1)
            $display("   -> [EXITO] Assertion Pass: El Checker alcanzo el estado LOCKED.");
    end
endtask

task test_forzar_error;
    begin
        $display("[%0t] TEST 2: Inyeccion de Error Fatal (Perdida de Lock)", $time);
        i_valid = 1'b1; 
        
        wait(checker_status == 1'b1);
        repeat(2) @(posedge clk);
        
        $display("[%0t] Inyectando mascara de error total...", $time);
        error_mask = 16'hFFFF; 
        
        repeat(3) @(posedge clk); 
        error_mask = 16'd0; 
        
        @(posedge clk); 

        // --- ASSERTION ---
        // Esperamos que el error prolongado rompa el lock (esperado = 0 / UNLOCKED)
        assert (checker_status == 1'b0) 
            else $error("[%0t] ASSERTION FAIL: El Checker debio pasar a UNLOCKED (0) por error fatal, pero se mantuvo en %0b", $time, checker_status);

        if (checker_status == 1'b0)
            $display("   -> [EXITO] Assertion Pass: El Checker detecto los errores y volvio a UNLOCKED.");
    end
endtask

task test_seed_random;
    begin
        $display("[%0t] TEST 3: Semilla Random con Soft Reset", $time);
        
        @(posedge clk);
        i_soft_rst = 1'b1;
        i_seed     = $random;
        @(posedge clk);
        i_soft_rst = 1'b0;

        i_valid = 1'b1;
        repeat(10) @(posedge clk); 

        // --- ASSERTION ---
        assert (checker_status == 1'b1) 
            else $error("[%0t] ASSERTION FAIL: El Checker fallo al sincronizar con la nueva semilla random. Estado actual: %0b", $time, checker_status);

        if (checker_status == 1'b1)
            $display("   -> [EXITO] Assertion Pass: Sincronizo perfecto con la nueva semilla.");

        i_valid  = 1'b0; 
    end
endtask

task test_frontera_4v_1i;
    begin
        $display("[%0t] TEST 4: Frontera (4 validos, 1 error antes del Lock)", $time);
        aplicar_reset; 
        
        i_valid = 1'b1;
        repeat(4) @(posedge clk); 
        
        $display("[%0t] Inyectando 1 error justo antes del umbral...", $time);
        error_mask = 16'h0001; 
        @(posedge clk);
        error_mask = 16'd0;    
        
        @(posedge clk);

        // --- ASSERTION ---
        // Esperamos que siga en UNLOCKED (0) porque el error arruinó la racha de 5
        assert (checker_status == 1'b0) 
            else $error("[%0t] ASSERTION FAIL: El Checker se lockeo (1) prematuramente a pesar del error de frontera.", $time);

        if (checker_status == 1'b0)
            $display("   -> [EXITO] Assertion Pass: Checker rechazo el lock falso (Se mantuvo UNLOCKED).");
            
        i_valid = 1'b0;
    end
endtask

task test_reset_aleatorio;
    integer tiempo_random;
    begin
        $display("[%0t] TEST 5: Reset en momento aleatorio", $time);
        i_valid = 1'b1;
        
        wait(checker_status == 1'b1);
        $display("[%0t] Sistema LOCKED detectado.", $time);
        
        tiempo_random = ($urandom % 10) + 2;
        repeat(tiempo_random) @(posedge clk);
        
        $display("[%0t] Disparando Reset sorpresa", $time);
        reset = 1'b1;
        repeat(2) @(posedge clk);
        reset = 1'b0;
        
        repeat(10) @(posedge clk);

        // --- ASSERTION ---
        assert (checker_status == 1'b1) 
            else $error("[%0t] ASSERTION FAIL: El Checker no pudo recuperarse del reset sorpresa. Estado: %0b", $time, checker_status);

        if (checker_status == 1'b1)
            $display("   -> [EXITO] Assertion Pass: El Checker se recupero del reset sorpresa.");
            
        i_valid = 1'b0;
    end
endtask

task test_histeresis_tolerancia;
    begin
        $display("[%0t] TEST 6: Tolerancia a fallos (2 errores, 1 acierto)", $time);
        i_valid = 1'b1;
        
        wait(checker_status == 1'b1);
        repeat(2) @(posedge clk);
        
        $display("[%0t] Inyectando 2 errores consecutivos (Tolerancia maxima)...", $time);
        error_mask = 16'hFFFF; 
        repeat(2) @(posedge clk);
        
        error_mask = 16'd0; 
        $display("[%0t] Enviando dato correcto (deberia limpiar los fallos)...", $time);
        @(posedge clk); 

        // --- ASSERTION ---
        // Gracias a la histéresis, el sistema DEBE mantenerse en LOCKED (1)
        assert (checker_status == 1'b1) 
            else $error("[%0t] ASSERTION FAIL: La histéresis fallo. El Checker perdio el lock con solo 2 errores.", $time);
        
        if (checker_status == 1'b1)
            $display("   -> [EXITO] Assertion Pass: El Checker aplico histéresis y mantuvo el candado.");
    end
endtask

task test_error_como_semilla;
    begin
        $display("[%0t] TEST 7: Inyectar error y usarlo como nueva semilla (Soft Reset)", $time);
        i_valid = 1'b1;
        wait(checker_status == 1'b1);
        repeat(2) @(posedge clk);
        
        error_mask = 16'h1010; 
        @(posedge clk);
        
        $display("[%0t] Bus corrompido capturado: %h", $time, lfsr_data_corrupted);
        
        i_seed     = lfsr_data_corrupted; 
        i_soft_rst = 1'b1;
        
        @(posedge clk);
        i_soft_rst = 1'b0;
        error_mask = 16'd0; 
        
        repeat(10) @(posedge clk);

        // --- ASSERTION ---
        // Esperamos que se resincronice exitosamente con la semilla parásita
        assert (checker_status == 1'b1) 
            else $error("[%0t] ASSERTION FAIL: El sistema fallo al resincronizarse con la semilla derivada del error.", $time);
        
        if (checker_status == 1'b1)
            $display("   -> [EXITO] Assertion Pass: El sistema adopto la nueva semilla y se resincronizo.");
            
        i_valid = 1'b0;
    end
endtask