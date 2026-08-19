module top

  #(
    
    parameter NB_COUNTER    = 32 ,
    parameter NB_SWITCH     = 4  ,
    parameter NB_BTN        = 4  ,
    parameter NB_LEDS       = 4  ,
    parameter N_COLOR       = 3  

    )
   (
    output [NB_LEDS     - 1 : 0] o_led   ,  
    output [NB_LEDS     - 1 : 0] o_led_r ,
    output [NB_LEDS     - 1 : 0] o_led_b ,
    output [NB_LEDS     - 1 : 0] o_led_g ,

    input  [NB_SWITCH   - 1 : 0] i_sw    ,
    input  [NB_BTN  - 1 : 0]     i_btn   ,
    input                        i_reset ,
    input                        clock
    );


   //  Colores de LEDS
   localparam RED  =  3'b001;        
   localparam GREEN = 3'b010;
   localparam BLUE  = 3'b100;

   // Vars
   wire                    connect_count_to_mode   ;   //  Pulso desde contador
   wire [NB_LEDS  - 1 : 0]  sr_leds                ;   //  Salida shiftregister  
   wire [NB_LEDS  - 1 : 0]  fs_leds                ;   //  Salida Flash
   reg  [NB_BTN  - 1 : 0 ]  btn_previous           ;   //  Estado anterior de los botones
   reg  [NB_BTN  - 1 : 0 ]  btn_rise               ;   //  Flanco de subida de los botones
   reg                      select_mode            ;   //  Modo de operación 0 = SR, 1 = FS
   reg  [NB_BTN  - 1 : 0 ]  btn_status             ;   //  Estado de los botones de color
   reg  [N_COLOR - 1 : 0 ]  color_selected         ;   //  Color seleccionado

   // VIO E ILA
     
   wire [NB_BTN  - 1 : 0    ]  btn_w                  ;
   wire [NB_BTN      - 1 : 0]  btn_from_vio           ;
   wire [NB_SWITCH   - 1 : 0]  sw_w                   ;
   wire [NB_SWITCH   - 1 : 0]  sw_from_vio            ;
   wire                        reset_select           ; //VIO o HW
   wire                        i_reset_from_vio       ;
   wire                        sel_vioOrHw            ; //0 HardW  -1 VIO



   //Control por VIO
   assign btn_w =        (sel_vioOrHw) ? btn_from_vio      : i_btn   ;
   assign sw_w  =        (sel_vioOrHw) ? sw_from_vio       : i_sw    ;
   assign reset_select = (sel_vioOrHw) ? ~i_reset_from_vio : ~i_reset;

   
   always@(posedge clock or posedge reset_select) begin
      if (reset_select)
      begin
        btn_status             <= {N_COLOR{1'b0} };
        color_selected         <= {N_COLOR{1'b0}};
        btn_previous           <= {NB_BTN{1'b0} };
        btn_rise               <= {NB_BTN{1'b0} };
        select_mode            <= 1'b0; // Modo SR por defecto
      end

      else begin
         // Se verifica que botón se precionó. Si se preciona mas de una vez,
         // no hay cambios
         btn_previous    <= btn_w;                         // Guardar el estado anterior de los pulsadores
         btn_rise        <= btn_w & ~btn_previous;         // Calcular el flanco de subida

         // Cambiar el color según el pulsador presionado
         case (btn_rise)
            4'b0010: color_selected         <= RED;         // Si se presiona el botón 1, cambiar a RED
            4'b0100: color_selected         <= GREEN;       // Si se presiona el botón 2, cambiar a GREEN
            4'b1000: color_selected         <= BLUE;        // Si se presiona el botón 3, cambiar a BLUE
            default: 
                     color_selected         <= color_selected;       // Si no se presiona ningún botón, mantener igual
         endcase
         //Actualizo registro visible
       btn_status[3:1] <=color_selected;

        //Cambia el modo (SR o FS) si se presiona i_btn[0]
         if (btn_rise[0]) begin
          select_mode <= ~select_mode; 
          btn_status[0] <= ~select_mode;
         end

      end

      

   end


   count
   #(
      .NB_SWITCH        (NB_SWITCH - 1        ),
      .NB_COUNTER       (NB_COUNTER           )
   )
   u_count
   (
      .o_valid          (connect_count_to_mode),  
      .i_switch         (i_sw[2:0]            ),
      .i_reset          (reset_select          ),
      .clock            (clock                )
   );

   shiftregister
   #(
      .NB_LEDS          (NB_LEDS              )
   )
   u_shiftregister
   (
      .o_shift          (sr_leds              ),
      .i_valid          (connect_count_to_mode),
      .i_dir            (i_sw[3]              ),
      .i_reset          (reset_select          ),
      .clock            (clock                )
   );

   flash 
   #(
      .NB_LEDS          (NB_LEDS              )
   )
   u_flash
   (
      .o_flash          (fs_leds              ),
      .i_valid          (connect_count_to_mode),
      .i_reset          (reset_select          ),
      .clock            (clock                )
   );


   

   ila
   u_ila
   (
      .clk_0    (clock   ),
      .probe0_0 (o_led   ),
      .probe1_0 (o_led_r ),
      .probe2_0 (o_led_g ),
      .probe3_0 (o_led_b )
    );
    
    
    vio
    u_vio
    (
      .clk_0        (clock           ),        //1 bit
      .probe_in0_0  (o_led           ),        //4 bits
      .probe_in1_0  (o_led_r         ),        //4 bits
      .probe_in2_0  (o_led_g         ),        //4 bits
      .probe_in3_0  (o_led_b         ),        //4 bits
      .probe_out0_0 (sel_vioOrHw     ),        //1 bit
      .probe_out1_0 (i_reset_from_vio),        //1 bit
      .probe_out2_0 (sw_from_vio     ),        //4 bits
      .probe_out3_0 (btn_from_vio    )         //4 bits

    );


   


    
    
   // Asignar el color a los LED RGB
    assign o_led_r = (color_selected == RED)   ? ((select_mode==1'b0)? sr_leds : fs_leds) : {NB_LEDS{1'b0}};
    assign o_led_g = (color_selected == GREEN) ? ((select_mode==1'b0)? sr_leds : fs_leds) : {NB_LEDS{1'b0}};
    assign o_led_b = (color_selected == BLUE)  ? ((select_mode==1'b0)? sr_leds : fs_leds) : {NB_LEDS{1'b0}};

   // Encender los leds de botones
    assign o_led = btn_status;


endmodule 