section .rodata
; Poner acá todas las máscaras y coeficientes que necesiten para el filtro
%define CERO 0x00

rojos         : db 0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO
verdes        : db CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO
azules        : db CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO
transparencia : db CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF,CERO,CERO,CERO,0xFF
reordeno      : db 0x00,0x00,0x00,0x03,0x04,0x04,0x04,0x07,0x08,0x08,0x08,0x0B,0x0C,0x0C,0x0C,0x0F

cte_rojo  : dd 0.2126, 0.2126, 0.2126, 0.2126 
cte_verde : dd 0.7152, 0.7152, 0.7152, 0.7152 
cte_azul  : dd 0.0722, 0.0722, 0.0722, 0.0722 
 
section .text

; Marca un ejercicio como aún no completado (esto hace que no corran sus tests)
FALSE EQU 0
; Marca un ejercicio como hecho
TRUE  EQU 1

; Marca el ejercicio 1 como hecho (`true`) o pendiente (`false`).
;
; Funciones a implementar:
;   - ej1
global EJERCICIO_1_HECHO
EJERCICIO_1_HECHO: db TRUE; Cambiar por `TRUE` para correr los tests.

; Convierte una imagen dada (`src`) a escala de grises y la escribe en el
; canvas proporcionado (`dst`).
;
; Para convertir un píxel a escala de grises alcanza con realizar el siguiente
; cálculo:
; ```
; luminosidad = 0.2126 * rojo + 0.7152 * verde + 0.0722 * azul 
; ```
;
; Como los píxeles de las imágenes son RGB entonces el píxel destino será
; ```
; rojo  = luminosidad
; verde = luminosidad
; azul  = luminosidad
; alfa  = 255
; ```
;
; Parámetros:
;   - dst:    La imagen destino. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - src:    La imagen origen A. Está a color (RGBA) en 8 bits sin signo por
;             canal.
;   - width:  El ancho en píxeles de `src` y `dst`.
;   - height: El alto en píxeles de `src` y `dst`.
global ej1
ej1:
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

	;R8 = cantidad de píxeles
	imul RDX, RCX

	.ciclo:
	cmp RDX, 0
	je .final

	;Cálculo la luminosidad.
	movdqa XMM1, [RSI]
	movdqa XMM2, [RSI]
	movdqa XMM3, [RSI]
	
	movups XMM4, [rojos]
	movups XMM5, [verdes]
	movups XMM6, [azules]
	
	pand XMM1, XMM4 
	pand XMM2, XMM5 
	pand XMM3, XMM6 
	
	;Shifteo para ordenar los píxeles verdes y azules.
	psrldq XMM2, 1
	psrldq XMM3, 2
	
	cvtdq2ps XMM1,	XMM1
	cvtdq2ps XMM2,	XMM2
	cvtdq2ps XMM3,	XMM3

	movups XMM4, [cte_rojo]
	movups XMM5, [cte_verde]
	movups XMM6, [cte_azul]

	mulps XMM1, XMM4 
	mulps XMM2, XMM5 
	mulps XMM3, XMM6 
	
	;XMM7 = luminosidades de los 4 píxeles
	pxor XMM7, XMM7
	addps XMM7, XMM1
	addps XMM7, XMM2
	addps XMM7, XMM3

	cvtps2dq XMM7, XMM7
	
	;Seteo la luminosidades en r, g y b de los 4 píxeles.
	movups XMM0, [reordeno]
	pshufb XMM7, XMM0

	;Seteo la transparencia de los píxeles.
	movups XMM0, [transparencia]
	paddd XMM7, XMM0

	movdqa [RDI], XMM7
	
	add RDI, 16
	add RSI, 16
	sub RDX, 4
	jmp .ciclo

	.final:
	pop RBP
	ret
