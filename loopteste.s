.text
MAIN:
    # 1. Testa os efeitos sonoros com pausas entre eles
    jal SFX_TIRO
    li a0, 500
    li a7, 32
    ecall

    jal SFX_DANO
    li a0, 500
    li a7, 32
    ecall

    jal SFX_BOMBA
    li a0, 800
    li a7, 32
    ecall

    # 2. Simula o game loop por ~5 segundos para testar a musica
    li s0, 500
LOOP_TESTE:
    jal ATUALIZAR_MUSICA
    li a0, 10                  # simula 10 ms por frame
    li a7, 32
    ecall
    addi s0, s0, -1
    bnez s0, LOOP_TESTE

    li a0, 1500
    li a7, 32
    ecall

    # 3. Testa o som de Game Over e encerra
   jal SFX_GAMEOVER
    li a7, 10
    ecall

# IMPORTANTE: o .include fica no FINAL para o RARS comecar em MAIN
.include "audio.s"