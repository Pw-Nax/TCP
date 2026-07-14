
# Sintaxis y Fundamentos de Verilog 
---

## 1. Estructura y Declaración de Módulos (Estándar Verilog-2001)
El módulo es la unidad de diseño fundamental. Define la interfaz de entradas y salidas (I/O).

```verilog
module nombre_modulo #(
    parameter ANCHO = 8 // Parámetros configurables (opcional)
) (
    input  wire             clk,      // Entrada de 1 bit
    input  wire [ANCHO-1:0] dato_in,  // Entrada parametrizada (vector)
    output reg              valido,   // Salida procedural (tipo reg)
    output wire [ANCHO-1:0] dato_out  // Salida combinacional (tipo wire)
);

    // [Cuerpo del módulo: lógica combinacional y/o secuencial]

endmodule
```



## 3. Tipos de Datos y Variables
Verilog tiene dos familias principales de tipos de datos que determinan cómo se modela el almacenamiento físico.

| Tipo de Dato | Capacidad de Almacenamiento | Uso principal | Método de asignación |
| :--- | :--- | :--- | :--- |
| **`wire`** (Net) | **No almacena valor** (es un cable). | Conexiones combinacionales, buses, salidas de lógica de compuertas. | Bloques `assign` o instanciación de puertos. |
| **`reg`** (Register) | **Almacena valor** temporalmente en simulación. | Modelado de registros físicos (Flip-Flops/Latches) o lógica combinacional compleja. | Bloques procedurales (`always`, `initial`). |
| **`integer`** | Almacena enteros de 32 bits con signo. | Índices de bucles, variables auxiliares en testbenches. | Bloques procedurales. |

### Vectores (Buses)
*   **Declaración:** `wire [MSB:LSB] nombre;` (Generalmente `[N-1:0]`).
*   **Indexación:** `bus[2]` (Bit individual), `bus[7:4]` (Sub-rango/Slicing).

### Constantes Numéricas
Sintaxis: `<Tamaño>'<Base><Valor>`
*   `8'hFF` -> 8 bits con valor hexadecimal FF (11111111).
*   `4'b1010` -> 4 bits con valor binario 1010.
*   `1'b0` -> Constante de 1 bit con valor lógico 0.

---

## 4. Asignaciones: Combinacional vs Procedural

### A. Asignación Continua (`assign`)
*   Se aplica exclusivamente sobre redes tipo **`wire`**.
*   Modela lógica combinacional pura.
*   Es **concurrente** (el orden de escritura no altera el hardware generado).
```verilog
assign y = a & b; // y se actualiza inmediatamente cuando cambia a o b.
```

### B. Asignación Procedural (Dentro de bloques `always` o `initial`)
*   Se aplica exclusivamente sobre variables tipo **`reg`** o **`integer`**.
*   **Bloque `always`:** Ejecuta su contenido cíclicamente según su **lista de sensibilidad**.
    *   *Sensibilidad por nivel (Lógica Combinacional):*
        ```verilog
        always @(a or b or sel) begin // O alternativamente: always @(*)
            if (sel) y = b;
            else     y = a;
        end
        ```
    *   *Sensibilidad por flanco (Lógica Secuencial/Síncrona):*
        ```verilog
        always @(posedge clk or negedge reset_n) begin
            if (!reset_n)
                q <= 1'b0; // Asignación no-bloqueante (<=) para flip-flops
            else
                q <= d;
        ```

---

## 5. Operadores en Verilog (Precedencia de mayor a menor)

| Categoría | Operador | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- |
| **Unarios** | `+`, `-` | Signo positivo/negativo. | `a = -b;` |
| **Lógicos Unarios (NOT)** | `!` | Negación lógica (retorna 1 bit: 0, 1 o x). | `valido = !error;` |
| **Aritméticos** | `*`, `/`, `%`, `+`, `-` | Multiplicación, división, módulo, suma, resta. | `suma = a + b;` |
| **Desplazamiento** | `<<`, `>>` | Desplazamiento lógico izquierda y derecha (rellena con 0). | `bus_out = bus_in << 2;` |
| **Relacionales** | `<`, `>`, `<=`, `>=` | Comparaciones de magnitud (retornan 1 bit: 0 o 1). | `mayor = a > b;` |
| **Igualdad lógica** | `==`, `!=` | Igualdad/Desigualdad lógica (compara bits 0 y 1; x/z retornan x). | `igual = (a == b);` |
| **Igualdad de caso** | `===`, `!==` | Compara idénticamente incluyendo bits `x` y `z`. | `check = (a === 2'b1z);` |
| **Bit a Bit (Bitwise)** | `~`, `&`, `\|`, `^`, `~^` | NOT, AND, OR, XOR, XNOR aplicados bit a bit. | `y = a ^ b;` |
| **Reducción** | `&`, `~&`, `\|`, `~\|`, `^`, `~^` | Aplica la operación entre todos los bits del mismo vector. | `todo_unos = &bus_datos;` |
| **Lógicos Binarios** | `&&`, `\|\|` | AND y OR lógicos (operan sobre valores de verdad). | `activar = habilitado && listo;` |
| **Condicional (Ternario)** | `? :` | Evaluación condicional en una sola línea. | `salida = (sel) ? b : a;` |
| **Concatenación** | `{ }` | Agrupa múltiples señales o vectores en un solo bus. | `bus_completo = {acarreo, suma};` |
| **Replicación** | `{n{ }}` | Replica una señal o vector $n$ veces consecutivas. | `sign_ext = {{4{signo}}, bus_4bit};` |
```

``` 

---
