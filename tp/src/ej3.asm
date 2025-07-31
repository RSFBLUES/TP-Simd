section .rodata
%define NULO 0x80

primera_parte   : db 0x00,NULO,NULO,NULO,0x01,NULO,NULO,NULO,0x02,NULO,NULO,NULO,0x03,NULO,NULO,NULO
segunda_parte   : db 0x04,NULO,NULO,NULO,0x05,NULO,NULO,NULO,0x06,NULO,NULO,NULO,0x07,NULO,NULO,NULO
tercera_parte   : db 0x08,NULO,NULO,NULO,0x09,NULO,NULO,NULO,0x0A,NULO,NULO,NULO,0x0B,NULO,NULO,NULO
cuarta_parte    : db 0x0C,NULO,NULO,NULO,0x0D,NULO,NULO,NULO,0x0E,NULO,NULO,NULO,0x0F,NULO,NULO,NULO
trasladar_valor : db 0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03,0x00,0x01,0x02,0x03

section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 3A como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej3a
global EJERCICIO_3A_HECHO
EJERCICIO_3A_HECHO: db TRUE; Cambiar por `TRUE` para correr los tests.

; Dada una imagen origen escribe en el destino `scale * px + offset` por cada
; píxel en la imagen.
;
; Parámetros:
;   - dst_depth: La imagen destino (mapa de profundidad). Está en escala de
;                grises a 32 bits con signo por canal.
;   - src_depth: La imagen origen (mapa de profundidad). Está en escala de
;                grises a 8 bits sin signo por canal.
;   - scale:     El factor de escala. Es un entero con signo de 32 bits.
;                Multiplica a cada pixel de la entrada.
;   - offset:    El factor de corrimiento. Es un entero con signo de 32 bits.
;                Se suma a todos los píxeles luego de escalarlos.
;   - width:     El ancho en píxeles de `src_depth` y `dst_depth`.
;   - height:    El alto en píxeles de `src_depth` y `dst_depth`.
global ej3a
ej3a:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits.
	;
	; r/m64 = int32_t* dst_depth [RDI]
	; r/m64 = uint8_t* src_depth [RSI]
	; r/m32 = int32_t  scale     [RDX]
	; r/m32 = int32_t  offset    [RCX]
	; r/m32 = int      width     [R8]
	; r/m32 = int      height    [R9]
	push RBP
	mov RBP, RSP

	; Escala y Offset repetidos 4 veces, de 32 bits,
	; en los registros XMM:
	; XMM9 = escala
	; XMM10 = offset

	movd XMM9, EDX
	movd XMM10, ECX

	movdqu XMM0, [trasladar_valor]

	pshufb XMM9, XMM0
	pshufb XMM10, XMM0

	; Cargo constantes.
	movdqu XMM5, [primera_parte]
	movdqu XMM6, [segunda_parte]
	movdqu XMM7, [tercera_parte]
	movdqu XMM8, [cuarta_parte]
	
	; R8 = cantidad_de_pixeles
	imul R8, R9

	.ciclo:
	cmp R8, 0
	je .final

	; Los registros XMM (1,2,3 y 4) tienen los mismos 
	; 16 números de 8 bits sin signo los divido en 4 
	; partes para trabajar en 32 bits.
	movdqu XMM1, [RSI]
	movdqu XMM2, [RSI]
	movdqu XMM3, [RSI]
	movdqu XMM4, [RSI]

	pshufb XMM1, XMM5
	pshufb XMM2, XMM6
	pshufb XMM3, XMM7
	pshufb XMM4, XMM8
	
	; Múltiplico por la escala.
	pmulld XMM1, XMM9
	pmulld XMM2, XMM9
	pmulld XMM3, XMM9
	pmulld XMM4, XMM9
	
	; Sumo el offset.
	paddd XMM1, XMM10
	paddd XMM2, XMM10
	paddd XMM3, XMM10
	paddd XMM4, XMM10
	
	movdqa [RDI], XMM1
	movdqa [RDI + 16], XMM2
	movdqa [RDI + 32], XMM3
	movdqa [RDI + 48], XMM4
	
	add RDI, 64
	add RSI, 16
	sub R8, 16
	jmp .ciclo

	.final:
	pop RBP
	ret

; Marca el ejercicio 3B como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej3b
global EJERCICIO_3B_HECHO
EJERCICIO_3B_HECHO: db TRUE ; Cambiar por `TRUE` para correr los tests.

; Dadas dos imágenes de origen (`a` y `b`) en conjunto con sus mapas de
; profundidad escribe en el destino el pixel de menor profundidad por cada
; píxel de la imagen. En caso de empate se escribe el píxel de `b`.
;
; Parámetros:
;   - dst:     La imagen destino. Está a color (RGBA) en 8 bits sin signo por
;              canal.
;   - a:       La imagen origen A. Está a color (RGBA) en 8 bits sin signo por
;              canal.
;   - depth_a: El mapa de profundidad de A. Está en escala de grises a 32 bits
;              con signo por canal.
;   - b:       La imagen origen B. Está a color (RGBA) en 8 bits sin signo por
;              can.
;   - depth_b: El mapa de profundidad de B. Está en escala de grises a 32 bits
;              con signo por canal.
;   - width:  El ancho en píxeles de todas las imágenes parámetro.
;   - height: El alto en píxeles de todas las imágenes parámetro.
global ej3b
ej3b:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits.
	;
	; r/m64 = rgba_t*  dst     [RDI]
	; r/m64 = rgba_t*  a       [RSI]
	; r/m64 = int32_t* depth_a [RDX]
	; r/m64 = rgba_t*  b       [RCX]
	; r/m64 = int32_t* depth_b [R8]
	; r/m32 = int      width   [R9]
	; r/m32 = int      height  [Pila]
	push RBP
	mov RBP, RSP

	; R9 = cantidad de píxeles
	mov R10, [RBP + 16] 
	imul R9, R10
	
	.ciclo:
	cmp R9, 0
	je .final

	; Comparo depth_a con depth_b, para 
	; obtener una máscara y una copia.
	movdqa XMM0, [R8]
	movdqa XMM1, [RDX]
	pcmpgtd XMM0, XMM1
	
	movdqa XMM1, XMM0

	; Utilizo pand para obtener los píxeles de a
	; y pandn los de b.
	movdqa XMM2, [RSI]
	movdqa XMM3, [RCX]
	pand XMM2, XMM0
	pandn XMM1, XMM3

	; Obtengo los píxeles a guardar ya comparados.
	paddd XMM2, XMM1
	movdqa [RDI], XMM2

	add RDI, 16
	add RSI, 16
	add RDX, 16
	add RCX, 16
	add R8, 16
	sub R9, 4

	jmp .ciclo

	.final:
	pop RBP
	ret
