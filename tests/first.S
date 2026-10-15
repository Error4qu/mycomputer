.section .data
.align 2
counter: .word 0
sum: .word 0

.section .text
.global _start
_start:
la t0 , sum
la t1, counter
loop:
addi t4 , zero , 10
lw t5 , 0(t1)
bge t5,t4, done
addi t5 , t5 ,1
lw t6 , 0(t0)
add t6 , t6 , t5
sw t6 , 0(t0)
sw t5 , 0(t1)
jal zero , loop
done:
lw t6 , 0(t0)
slli t6 , t6 , 1
ori t6,t6,1
la t5 , tohost
sw t6 , 0(t5)
sw zero , 4(t5)
halt:
jal zero , halt
.section .tohost, "aw"
.align 3
.global tohost
tohost: .dword 0
.global fromhost
fromhost: .dword 0
	
