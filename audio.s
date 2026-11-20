.data
# Controle da musica de fundo (nao-bloqueante)
MUSICA_IDX:     .word 0         # Nota atual
MUSICA_PROX_T:  .word 0         # Horario (ms) da proxima nota
MUSICA_TAM:     .word 16         # Total de notas no loop

# Formato de cada linha (16 bytes):
# .word nota_melodia, nota_baixo, duracao_passo_ms, duracao_baixo_ms
MUSICA_NOTAS:
    # Compasso 1 (Re menor)
    .word 62, 50, 220, 880
    .word 65,  0, 220,   0
    .word 69,  0, 220,   0
    .word 70,  0, 220,   0
    # Compasso 2 (Si bemol)
    .word 69, 46, 220, 880
    .word 65,  0, 220,   0
    .word 64,  0, 220,   0
    .word 62,  0, 220,   0
    # Compasso 3 (Sol menor)
    .word 67, 43, 220, 880
    .word 70,  0, 220,   0
    .word 74,  0, 220,   0
    .word 72,  0, 220,   0
    # Compasso 4 (La / tensao para reiniciar)
    .word 69, 45, 220, 880
    .word 67,  0, 220,   0
    .word 65,  0, 220,   0
    .word 64,  0, 220,   0

.text
ATUALIZAR_MUSICA:
    li a7, 30
    ecall                       # a0 = tempo atual (ms)
    la t0, MUSICA_PROX_T
    lw t1, 0(t0)
    beqz t1, TOCAR_NOTA
    sub t2, a0, t1
    bltz t2, MUSICA_RET

TOCAR_NOTA:
    mv t3, a0
    la t0, MUSICA_IDX
    lw t1, 0(t0)
    slli t2, t1, 4              # offset = indice * 16 bytes (4 words)
    la t4, MUSICA_NOTAS
    add t4, t4, t2

    lw t5, 8(t4)                # duracao do passo (ms)
    add t3, t3, t5
    la t2, MUSICA_PROX_T
    sw t3, 0(t2)

    # 1) Melodia
    lw a0, 0(t4)
    beqz a0, TOCAR_BAIXO
    mv a1, t5
    li a2, 19                   # 19 = Church Organ (teste 81 para estilo 8-bit ou 46 para harpa)
    li a3, 65
    li a7, 31
    ecall

TOCAR_BAIXO:
    # 2) Baixo de acompanhamento
    lw a0, 4(t4)
    beqz a0, AVANCA_IDX
    lw a1, 12(t4)               # duracao longa do baixo (880 ms)
    li a2, 43                   # 43 = Contrabass
    li a3, 55
    li a7, 31
    ecall

AVANCA_IDX:
    addi t1, t1, 1
    la t2, MUSICA_TAM
    lw t2, 0(t2)
    blt t1, t2, SALVA_IDX
    li t1, 0
SALVA_IDX:
    sw t1, 0(t0)
MUSICA_RET:
    ret

# ---------------------------------------------------------
# Efeitos sonoros (todos nao-bloqueantes via ecall 31)
# ---------------------------------------------------------
SFX_TIRO:
    li a0, 76                   # nota aguda
    li a1, 80                   # 80 ms
    li a2, 115                  # Woodblock (som seco de disparo)
    li a3, 110
    li a7, 31
    ecall
    ret

SFX_DANO:
    li a0, 42                   # nota grave
    li a1, 180
    li a2, 55                   # Orchestra Hit
    li a3, 127
    li a7, 31
    ecall
    ret

SFX_BOMBA:
    li a0, 36                   # bem grave
    li a1, 450
    li a2, 127                  # Gunshot / explosao
    li a3, 127
    li a7, 31
    ecall
    ret

# ---------------------------------------------------------
# Som de derrota (bloqueante, para usar na tela de Game Over)
# ---------------------------------------------------------
SFX_GAMEOVER:
    li a0, 50
    li a1, 350
    li a2, 19                   # Church Organ
    li a3, 110
    li a7, 33
    ecall
    li a0, 45
    li a1, 700
    li a7, 33
    ecall
    ret