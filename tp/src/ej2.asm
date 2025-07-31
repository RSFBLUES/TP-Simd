section .rodata
; Poner acá todas las máscaras y coeficientes que necesiten para el filtro
%define NULO 0x80
%define CERO 0x00

rojos         : db 0x00,NULO,NULO,NULO,0x04,NULO,NULO,NULO,0x08,NULO,NULO,NULO,0x0C,NULO,NULO,NULO
verdes        : db 0x01,NULO,NULO,NULO,0x05,NULO,NULO,NULO,0x09,NULO,NULO,NULO,0x0D,NULO,NULO,NULO
azules        : db 0x02,NULO,NULO,NULO,0x06,NULO,NULO,NULO,0x0A,NULO,NULO,NULO,0x0E,NULO,NULO,NULO
transparencia : db CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF

cte_384       : dd 384,384,384,384
cte_255       : dd 255,255,255,255
cte_192       : dd 192,192,192,192
cte_128       : dd 128,128,128,128
cte_64        : dd  64, 64, 64, 64
cte_3_dec     : dd 3.0,3.0,3.0,3.0
cte_0         : dd   0,  0,  0,  0
cte_4_neg     : dd  -4, -4, -4, -4

section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 2 como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej1
global EJERCICIO_2_HECHO
EJERCICIO_2_HECHO: db TRUE; Cambiar por `TRUE` para correr los tests.

; Aplica un efecto de "mapa de calor" sobre una imagen dada (`src`). Escribe la
; imagen resultante en el canvas proporcionado (`dst`).
;
; Para calcular el mapa de calor lo primero que hay que hacer es computar la
; "temperatura" del pixel en cuestión:
; ```
; temperatura = (rojo + verde + azul) / 3
; ```
;
; Cada canal del resultado tiene la siguiente forma:
; ```
; |          ____________________
; |         /                    \
; |        /                      \        Y = intensidad
; | ______/                        \______
; |
; +---------------------------------------
;              X = temperatura
; ```
;
; Para calcular esta función se utiliza la siguiente expresión:
; ```
; f(x) = min(255, max(0, 384 - 4 * |x - 192|))
; ```
;
; Cada canal esta offseteado de distinta forma sobre el eje X, por lo que los
; píxeles resultantes son:
; ```
; temperatura  = (rojo + verde + azul) / 3
; salida.rojo  = f(temperatura)
; salida.verde = f(temperatura + 64)
; salida.azul  = f(temperatura + 128)
; salida.alfa  = 255
; ```
;
; Parámetros:
;   - dst:    La imagen destino. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - src:    La imagen origen A. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - width:  El ancho en píxeles de `src` y `dst`.
;   - height: El alto en píxeles de `src` y `dst`.
global ej2
ej2:
	; Te recomendamos llenar una tablita acá con cada parámetro y su
	; ubicación según la convención de llamada. Prestá atención a qué
	; valores son de 64 bits y qué valores son de 32 bits.
	;
	; r/m64 = rgba_t*  dst    [RDI]
	; r/m64 = rgba_t*  src    [RSI]
	; r/m32 = uint32_t width  [RDX]
	; r/m32 = uint32_t height [RCX]

	push RBP
	mov RBP, RSP
	
	; RDX = cantidad de píxeles
	imul RDX, RCX
	
	; Cargo constantes.
	movdqu XMM4, [rojos]
	movdqu XMM5, [verdes]
	movdqu XMM6, [azules]

	movdqu XMM7, [cte_3_dec]

	movdqu XMM8, [cte_64]
	movdqu XMM9, [cte_128]

	movdqu XMM10, [cte_192]
	
	movdqu XMM11, [cte_4_neg]

	movdqu XMM12, [cte_384]

	movdqu XMM13, [cte_0]

	movdqu XMM14, [cte_255]

	movdqu XMM15, [transparencia]

	.ciclo:
	cmp RDX, 0
	je .final

	;*********************************************
	; Desde aquí cálculo la temperatura de 4 píxeles.
	movdqa XMM1, [RSI]
	movdqa XMM2, [RSI]
	movdqa XMM3, [RSI]

	; Los filtro según su color.

	pshufb XMM1, XMM4
	pshufb XMM2, XMM5
	pshufb XMM3, XMM6

	cvtdq2ps XMM1, XMM1 
	cvtdq2ps XMM2, XMM2 
	cvtdq2ps XMM3, XMM3 

	; Los sumo y divido por 3.
	pxor XMM0, XMM0
	addps XMM0, XMM1
	addps XMM0, XMM2
	addps XMM0, XMM3
	divps XMM0, XMM7

	; Obtengo la temperatura de los 4 píxeles.
	cvtps2dq XMM0, XMM0 

	;*********************************************
	; Desde aquí cálculo la "función de temperatura".
	; XMM1 = temperatura de rojos
	; XMM2 = temperatura de verdes
	; XMM3 = temperatura de azules
	movdqa XMM1, XMM0
	movdqa XMM2, XMM0
	movdqa XMM3, XMM0
	
	; Sumo  64 y 128.
	paddd XMM2, XMM8
	paddd XMM3, XMM9
	
	; Realizo la resta por 192.
	psubd XMM1, XMM10
	psubd XMM2, XMM10
	psubd XMM3, XMM10

	; Aplico el módulo.
	pabsd XMM1, XMM1
	pabsd XMM2, XMM2
	pabsd XMM3, XMM3
	
	; Múltiplico por -4.
	pmulld XMM1, XMM11
	pmulld XMM2, XMM11
	pmulld XMM3, XMM11
	
	; Lo sumo a 384.
	paddd XMM1, XMM12
	paddd XMM2, XMM12
	paddd XMM3, XMM12
	
	;Aplico el máximo y mínimo.
	; XMM13 = [cte_0]
	pmaxsd XMM1, XMM13
	pmaxsd XMM2, XMM13
	pmaxsd XMM3, XMM13

	; XMM14 = [cte_255]
	pminsd XMM1, XMM14
	pminsd XMM2, XMM14
	pminsd XMM3, XMM14
	
	; Como XMM2 = temperatura de verdes
	; XMM3 = temperatura de azules,
	; realizo un shift, para un reordenamiento.
	pslldq XMM2,1
	pslldq XMM3,2
	
	; Reordeno temperaturas y seteo transparencia.
	; XMM15 = [transparencia]
	paddd XMM1, XMM2
	paddd XMM1, XMM3
	paddb XMM1, XMM15

	movdqa [RDI], XMM1
	
	add RDI, 16
	add RSI, 16
	sub RDX, 4
	jmp .ciclo

	.final:
	pop RBP
	ret
