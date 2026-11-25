.eqv STEP     2				# pixels por quadro enquanto o personagem anda
.eqv TIMEOUT  8				# quadros que ele continua andando apos o ultimo evento de tecla
.eqv FRAME_MS 16			# espera por quadro (~60 quadros por segundo)
.eqv MAX_X    288			# 320 - largura do sprite (32)
.eqv MAX_Y    196			# 240 - altura do sprite (44)
.eqv HB_X     4				# caixa dos pes: deslocamento x dentro do sprite (largura 24)
.eqv HB_Y     28			# caixa dos pes: deslocamento y dentro do sprite (altura 16)
.eqv COR_PAREDE 7			# pixel vermelho puro do mapa = parede (BGR332)
 
.data
.align 2
CHAR_POS:	.half 144,98			# x, y atuais do personagem (centro da tela)
LAST_POS:	.half 144,98, 144,98		# ultima posicao desenhada em cada frame: (x,y) frame 0, (x,y) frame 1
DIR_X:		.byte 0				# direcao em x: -1, 0 ou 1
DIR_Y:		.byte 0				# direcao em y: -1, 0 ou 1
TIMER_X:	.byte 0				# quadros restantes andando em x
TIMER_Y:	.byte 0				# quadros restantes andando em y
SPRITE_DIR:	.byte 0				# 0 = de frente (char_frente), 1 = de costas (char_verso)
.align 2
 
.text
		li s0,0				# frame inicial
 
		li a3,0
		call DRAW_MAP			# fundo (mapa) no frame 0
		li a3,1
		call DRAW_MAP			# fundo (mapa) no frame 1
 
GAME_LOOP:	call KEY2			# le o teclado: so define direcao e timers
		call MOVE			# anda STEP pixels nos eixos que ainda tem timer
 
		xori s0,s0,1			# inverte o frame onde vamos desenhar
 
		la t0,LAST_POS
		slli t1,s0,2			# s0 * 4 (cada frame ocupa 4 bytes em LAST_POS)
		add s1,t0,t1			# s1 = endereco da ultima posicao desenhada NESTE frame
 
		# apaga o personagem antigo deste frame (restaura o fundo do mapa)
		la a0,char_frente		# so usa largura/altura (os 2 sprites tem o mesmo tamanho)
		lh a1,0(s1)
		lh a2,2(s1)
		mv a3,s0
		call CLEAR
 
		# escolhe o sprite conforme a direcao
		la a0,char_frente
		la t0,SPRITE_DIR
		lbu t1,0(t0)
		beq t1,zero,DESENHA		# 0 -> frente
		la a0,char_verso		# 1 -> costas
 
DESENHA:	la t0,CHAR_POS
		lh a1,0(t0)
		lh a2,2(t0)
		mv a3,s0
		call PRINT
 
		# guarda a posicao que acabou de ser desenhada neste frame
		la t0,CHAR_POS
		lw t1,0(t0)			# x e y juntos
		sw t1,0(s1)
 
		li t0,0xFF200604		# endereco de troca de frame
		sw s0,0(t0)			# mostra o frame pronto
 
		li a0,FRAME_MS			# controle de tempo: espera FRAME_MS ms
		li a7,32			# ecall sleep
		ecall
 
		j GAME_LOOP
 
#################################################
#	TECLADO: nao move o personagem, so	#
#	grava a direcao e reinicia o timer	#
#################################################
KEY2:		li t1,0xFF200000		# controle do KDMMIO
		lw t0,0(t1)
		andi t0,t0,0x0001
		beq t0,zero,FIM			# sem tecla -> retorna
		lw t2,4(t1)			# codigo da tecla
 
		li t0,'w'
		beq t2,t0,TECLA_CIMA
		li t0,'a'
		beq t2,t0,TECLA_ESQ
		li t0,'s'
		beq t2,t0,TECLA_BAIXO
		li t0,'d'
		beq t2,t0,TECLA_DIR
 
FIM:		ret
 
TECLA_ESQ:	li t0,-1
		la t1,DIR_X
		sb t0,0(t1)
		li t0,TIMEOUT
		la t1,TIMER_X
		sb t0,0(t1)
		ret
 
TECLA_DIR:	li t0,1
		la t1,DIR_X
		sb t0,0(t1)
		li t0,TIMEOUT
		la t1,TIMER_X
		sb t0,0(t1)
		ret
 
TECLA_CIMA:	li t0,-1
		la t1,DIR_Y
		sb t0,0(t1)
		li t0,TIMEOUT
		la t1,TIMER_Y
		sb t0,0(t1)
		li t0,1
		la t1,SPRITE_DIR
		sb t0,0(t1)			# de costas
		ret
 
TECLA_BAIXO:	li t0,1
		la t1,DIR_Y
		sb t0,0(t1)
		li t0,TIMEOUT
		la t1,TIMER_Y
		sb t0,0(t1)
		la t1,SPRITE_DIR
		sb zero,0(t1)			# de frente
		ret
 
#################################################
#	MOVE: roda todo quadro. Para cada eixo	#
#	com timer > 0, calcula a nova posicao,	#
#	limita a tela e SO anda se a caixa dos	#
#	pes nao encostar em parede.		#
#	(um eixo por vez: assim ele desliza	#
#	ao longo da parede)			#
#	s2 = ra salvo, s3 = &CHAR_POS,		#
#	s4 = novo valor candidato		#
#################################################
MOVE:		mv s2,ra			# MOVE chama BLOQUEADO, entao guarda o ra
		la s3,CHAR_POS
 
		# ---- eixo X ----
		la t1,TIMER_X
		lbu t2,0(t1)
		beq t2,zero,MOVE_Y		# timer zerado: nao anda em x
		addi t2,t2,-1
		sb t2,0(t1)			# gasta um quadro do timer
		la t1,DIR_X
		lb t2,0(t1)			# -1 ou 1 (lb: com sinal)
		li t3,STEP
		mul t2,t2,t3			# deslocamento = direcao * STEP
		lh t3,0(s3)
		add s4,t3,t2			# novo x
		bge s4,zero,MX_MAX
		mv s4,zero			# passou da esquerda: x = 0
MX_MAX:		li t4,MAX_X
		ble s4,t4,MX_TESTA
		mv s4,t4			# passou da direita: x = MAX_X
MX_TESTA:	mv a1,s4			# testa a caixa dos pes no novo x (y atual)
		lh a2,2(s3)
		call BLOQUEADO
		bne a0,zero,MOVE_Y		# parede: nao anda em x
		sh s4,0(s3)
 
		# ---- eixo Y ----
MOVE_Y:		la t1,TIMER_Y
		lbu t2,0(t1)
		beq t2,zero,MOVE_FIM		# timer zerado: nao anda em y
		addi t2,t2,-1
		sb t2,0(t1)
		la t1,DIR_Y
		lb t2,0(t1)
		li t3,STEP
		mul t2,t2,t3
		lh t3,2(s3)
		add s4,t3,t2			# novo y
		bge s4,zero,MY_MAX
		mv s4,zero			# passou do topo: y = 0
MY_MAX:		li t4,MAX_Y
		ble s4,t4,MY_TESTA
		mv s4,t4			# passou da base: y = MAX_Y
MY_TESTA:	lh a1,0(s3)			# testa a caixa dos pes no novo y (x atual)
		mv a2,s4
		call BLOQUEADO
		bne a0,zero,MOVE_FIM		# parede: nao anda em y
		sh s4,2(s3)
 
MOVE_FIM:	mv ra,s2
		ret
 
#################################################
#	BLOQUEADO: testa a caixa dos pes (24x16)#
#	do personagem contra o mapa		#
#	a1 = x do sprite, a2 = y do sprite	#
#	retorna a0 = 1 se algum dos 4 cantos	#
#	da caixa estiver sobre pixel de parede	#
#	(COR_PAREDE), 0 caso contrario		#
#################################################
BLOQUEADO:	la t0,mapa
		addi t0,t0,8			# pula o cabecalho
		addi a1,a1,HB_X			# x da caixa dos pes
		addi a2,a2,HB_Y			# y da caixa dos pes
		li t1,320
		mul t1,t1,a2
		add t0,t0,t1
		add t0,t0,a1			# t0 = pixel do canto superior esquerdo
		li t2,COR_PAREDE
 
		lbu t3,0(t0)			# superior esquerdo
		beq t3,t2,BLOQ_SIM
		lbu t3,23(t0)			# superior direito (largura 24 - 1)
		beq t3,t2,BLOQ_SIM
 
		li t1,4800			# 15 linhas * 320 (altura 16 - 1)
		add t0,t0,t1
		lbu t3,0(t0)			# inferior esquerdo
		beq t3,t2,BLOQ_SIM
		lbu t3,23(t0)			# inferior direito
		beq t3,t2,BLOQ_SIM
 
		mv a0,zero			# livre
		ret
BLOQ_SIM:	li a0,1				# bloqueado
		ret
 
#################################################
#	DRAW_MAP: copia a imagem 'mapa' inteira	#
#	para um frame do bitmap display		#
#	a3 = frame (0 ou 1)			#
#################################################
DRAW_MAP:	li t0,0xFF0
		add t0,t0,a3
		slli t0,t0,20			# endereco base do frame
		la t1,mapa
		addi t1,t1,8			# pula o cabecalho
		li t2,19200			# 320*240 / 4 palavras
DRAW_MAP_LOOP:	lw t3,0(t1)
		sw t3,0(t0)
		addi t0,t0,4
		addi t1,t1,4
		addi t2,t2,-1
		bne t2,zero,DRAW_MAP_LOOP
		ret
 
#################################################
#	PRINT: desenha a imagem (byte a byte,	#
#	pulando pixels com a cor 199)		#
#	a0 = endereco imagem			#
#	a1 = x					#
#	a2 = y					#
#	a3 = frame (0 ou 1)			#
#################################################
#	t0 = endereco no bitmap display		#
#	t1 = endereco do pixel na imagem	#
#	t2 = contador de linha			#
#	t3 = contador de coluna			#
#	t4 = largura   t5 = altura		#
#	t6 = pixel atual   a4 = cor 199		#
#################################################
PRINT:		li t0,0xFF0
		add t0,t0,a3			# 0xFF0 ou 0xFF1
		slli t0,t0,20			# 0xFF000000 ou 0xFF100000
		add t0,t0,a1			# + x
		li t1,320
		mul t1,t1,a2
		add t0,t0,t1			# + 320*y
 
		lw t4,0(a0)			# largura
		lw t5,4(a0)			# altura
		addi t1,a0,8			# pula o cabecalho
		li a4,199			# cor transparente
		mv t2,zero
 
PRINT_LINHA:	mv t3,zero
PRINT_COLUNA:	lbu t6,0(t1)			# 1 pixel (lbu: sem sinal!)
		beq t6,a4,PRINT_PROX		# transparente: nao desenha
		sb t6,0(t0)
PRINT_PROX:	addi t0,t0,1
		addi t1,t1,1
		addi t3,t3,1
		blt t3,t4,PRINT_COLUNA
 
		addi t0,t0,320
		sub t0,t0,t4			# vai para o inicio da proxima linha
		addi t2,t2,1
		blt t2,t5,PRINT_LINHA
		ret
 
#################################################
#	CLEAR: restaura o fundo (mapa) num	#
#	retangulo do tamanho da imagem em a0	#
#	a0 = imagem (so usa largura/altura)	#
#	a1 = x, a2 = y, a3 = frame		#
#################################################
CLEAR:		li t0,0xFF0
		add t0,t0,a3
		slli t0,t0,20
		add t0,t0,a1
		li t1,320
		mul t1,t1,a2			# 320 * y
		add t0,t0,t1			# t0 = endereco no frame
 
		la t6,mapa
		addi t6,t6,8
		add t6,t6,a1
		add t6,t6,t1			# t6 = mesma posicao dentro do mapa
 
		lw t4,0(a0)			# largura
		lw t5,4(a0)			# altura
		mv t2,zero
 
CLEAR_LINHA:	mv t3,zero
CLEAR_COLUNA:	lbu a4,0(t6)			# pixel do mapa
		sb a4,0(t0)			# restaura no frame
		addi t0,t0,1
		addi t6,t6,1
		addi t3,t3,1
		blt t3,t4,CLEAR_COLUNA
 
		addi t0,t0,320
		sub t0,t0,t4
		addi t6,t6,320
		sub t6,t6,t4
		addi t2,t2,1
		blt t2,t5,CLEAR_LINHA
		ret
 
.data
.include "char.s"
.include "mapa.s"