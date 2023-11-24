# RISC-V assembly program.

# .org 0
# Provide program starting address to linker
.global _start

/* newlib system calls */
.set SYSEXIT,  93
.set SYSWRITE, 64

.data 
    test1:    .dword 0x1122334455007700
    test2:    .dword 0x0123456789abcdef
    test3:    .dword 0x1100220033445566
    str1:     .string "The Leftmost 0-byte is "
              .set str1_size, .-str1
    endl:     .string "\n\n"
              .set endl_size, .-endl

    str2:     .string "Cycle count: 0x"
              .set str2_size, .-str2

    str3:     .string "Instructions retired: 0x"
              .set str3_size, .-str3

    digitstr: .string "0123456789ABCDEF"

.text
_start:
    addi sp, sp, -4         # create space for buffer of print function
    la   s4, test1          # s4 points to the first test case
    li   s5, 3              # number of test cases
    li   s7, 0x4            # base memory address to store the result

loop:

    # # get the cycle/instret before the task
    # jal get_cycles
    # mv  s0, a0             # s0: start cycle count: lower bytes
    # mv  s1, a1             # s1: start cycle count: higher bytes

    # jal get_instret
    # mv  s2, a0             # s2: start inst retired: lower bytes
    # mv  s3, a1             # s3: start inst retired: higher bytes

    # find the leftmost zero byte
    lw   a0, 0(s4)         # a0:test_half_right
    lw   a1, 4(s4)         # a1:test_half_left
    jal  zbytel
    mv   s6, a0            # save the result to s6

    # # get the cycle/instret after the task, and substract with the number get before the task
    # jal get_cycles
    # sub s0, a0, s0         # 
    # sltu t0, a0, s0        # t0 is now the borrow bit
    # sub  s1, s1, a1        # 
    # sub  s1, s1, t0

    # jal get_instret
    # sub s2, a0, s2         # 
    # sltu t0, a0, s2        # t0 is now the borrow bit
    # sub  s3, s3, a1        # 
    # sub  s3, s3, t0

    # print find leftmost zero byte result
    li   a0, 1              # 1 = standard output (stdout)
    la   a1, str1           # load address of str1
    la   a2, str1_size      # length of str1
    li   a7, SYSWRITE       # "write" syscall
    ecall

    addi s6, s6, 48         # change number to ascii digit
    sw   s6, 0(sp)          # push the result onto the stack
    li   a0, 1              # 1 = standard output (stdout)
    mv   a1, sp             # pass the stack address to a1
    li   a2, 1              # length of value digit
    li   a7, SYSWRITE       # "write" syscall
    ecall
    
    li   a0, 1              # 1 = standard output (stdout)
    la   a1, endl           # load address of endl
    li   a2, 1              # number of \n we want to print
    li   a7, SYSWRITE       # "write" syscall
    ecall

    # store the result in memory
    addi t0, s5, -1         # t0 = counter - 1
    slli t0, t0, 2
    add  t0, t0, s7         # t0 is now the address to store the result
    addi s6, s6, -48        # change from ascii digit back to number
    sw   s6, 0(t0)          # store the result into address t0

    # # print metrics
    # li   a0, 1              # 1 = standard output (stdout)
    # la   a1, str2           # load address of str1
    # la   a2, str2_size      # length of str1
    # li   a7, SYSWRITE       # "write" syscall
    # ecall

    # mv   a0, s0
    # mv   a1, s1
    # jal  printhex

    # li   a0, 1              # 1 = standard output (stdout)
    # la   a1, endl           # load address of endl
    # li   a2, 1              # number of \n we want to print
    # li   a7, SYSWRITE       # "write" syscall
    # ecall

    # li   a0, 1              # 1 = standard output (stdout)
    # la   a1, str3           # load address of str1
    # la   a2, str3_size      # length of str1
    # li   a7, SYSWRITE       # "write" syscall
    # ecall

    # mv   a0, s2
    # mv   a1, s3
    # jal  printhex

    # li   a0, 1              # 1 = standard output (stdout)
    # la   a1, endl           # load address of endl
    # li   a2, 2              # number of \n we want to print
    # li   a7, SYSWRITE       # "write" syscall
    # ecall

    # check if the loop should break
    addi s4, s4, 8           # move to the next test case
    addi s5, s5, -1          # test case counter--
    bne  s5, x0, loop        # counter=0,break

    # end of the program
    addi sp, sp, 4
    add  a0, x0, 0           # Use 0 as the return code
    li   a7, SYSEXIT         # "exit" syscall
    ecall

            
zbytel:
    addi  sp,sp,-4             #push
    sw    ra,0(sp)
    
    #y = (x & 0x7F7F7F7F7F7F7F7F)+ 0x7F7F7F7F7F7F7F7F
    li    t0,0x7f7f7f7f
    and   t2,a0,t0          
    add   t2,t2,t0
    
    #y = ~(y | x |0x7F7F7F7F7F7F7F7F)
    or    t2,t2,a0
    or    t2,t2,t0
    xori  t2,t2,-1          #t2:y_half_right
    
    and  t3,a1,t0       
    add  t3,t3,t0        
    or   t3,t3,a0
    or    t3,t3,t0
    xori  t3,t3,-1          #t3:y_half_left
    
    mv    a0,t2          
    mv    a1,t3                

# start of clz

    #x |= (x >> 1)
    andi  t1,a1,0x1
    srli  t4,a1,1
    srli  t5,a0,1
    slli  t1,t1,31
    or    t5,t5,t1
    or    a1,t4,a1
    or    a0,t5,a0
    
    #x |= (x >> 2)
    andi  t1,a1,0x3
    srli  t4,a1,2
    srli  t5,a0,2
    slli  t1,t1,30
    or    t5,t5,t1
    or    a1,t4,a1
    or    a0,t5,a0
    
    #x |= (x >> 4)
    andi  t1,a1,0xf
    srli  t4,a1,4
    srli  t5,a0,4
    slli  t1,t1,28
    or    t5,t5,t1
    or    a1,t4,a1
    or    a0,t5,a0
    
    #x |= (x >> 8)
    andi  t1,a1,0xff
    srli  t4,a1,8
    srli  t5,a0,8
    slli  t1,t1,24
    or    t5,t5,t1
    or    a1,t4,a1
    or    a0,t5,a0
   
    #x |= (x >> 16)
    li    t1,0xffff
    and   t1,a1,t1
    srli  t4,a1,16
    srli  t5,a0,16
    slli  t1,t1,16
    or    t5,t5,t1
    or    a1,t4,a1
    or    a0,t5,a0
    
    #x |= (x >> 32)
    mv    t5,a1
    and   t4,a1,x0
    or    a1,t4,a1
    or    a0,t5,a0
    
    # x -= ((x >> 1) & 0x5555555555555555)
    andi  t1,a1,0x1
    srli  t4,a1,1
    srli  t5,a0,1
    slli  t1,t1,31
    or    t5,t5,t1
    li    t1,0x55555555
    and   t4,t4,t1
    and   t5,t5,t1
    sub   a1,a1,t4
    sub   a0,a0,t5
    
    #x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333)
    andi  t1,a1,0x3
    srli  t4,a1,2
    srli  t5,a0,2
    slli  t1,t1,30
    or    t5,t5,t1
    li    t1,0x33333333
    and   t4,t4,t1        
    and   t5,t5,t1        
    and   a1,a1,t1
    and   a0,a0,t1
    add   a1,a1,t4
    add   a0,a0,t5
    
    #x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    andi  t1,a1,0xf
    srli  t4,a1,4
    srli  t5,a0,4
    slli  t1,t1,28
    or    t5,t5,t1
    add   t4,t4,a1
    add   t5,t5,a0
    li    t1,0x0f0f0f0f
    and   a1,t4,t1
    and   a0,t5,t1
    
    #x += (x >> 8)
    andi  t1,a1,0xff
    srli  t4,a1,8
    srli  t5,a0,8
    slli  t1,t1,24
    or    t5,t5,t1
    add   a1,a1,t4
    add   a0,a0,t5
    
    #x += (x >> 16)
    li    t1,0xffff
    and   t1,t1,a1
    srli  t4,a1,16
    srli  t5,a0,16
    slli  t1,t1,16
    or    t5,t5,t1
    add   a1,a1,t4
    add   a0,a0,t5
    
    #x += (x >> 32)
    mv    t5,a1
    and   t4,a1,x0
    add   a1,a1,t4
    add   a0,a0,t5
    
    #64 - (x & 0x7f)
    andi  a0,a0,0x7f
    li    t1,64
    sub   a0,t1,a0

# end of clz

    lw    ra,0(sp)
    addi  sp,sp,4           #pop 
    srli  a0,a0,3           #clz(y)>>3
    jr   ra

printhex:
    addi  sp, sp, -12       # push
    sw    ra, 0(sp)
    sw    s0, 4(sp)
    sw    s1, 8(sp)

    mv    s0, a0            # s0 is now the lower half of the number to print
    mv    s1, a1            # s1 is now the higher half of the number to print

    la    t0, digitstr      # t0 now points to "0123456789ABCDEF"
    li    t2, 16            # t2 is the counter
    
printhex_loop:
    # find the leftmost hex digit
    li    t3, 0xf0000000    # t3 is now the mask
    and   t1, s1, t3        # take the leftmost hex digit using the mask
    srli  t1, t1, 28        # t1 is now the offset when accessing digitstr
    add   t1, t0, t1        # t2 is the absolute address of char selected

    # print out the digit
    li    a0, 1             # 1 = standard output (stdout)
    mv    a1, t1            # load address of str1
    li    a2, 1             # length of str1
    li    a7, SYSWRITE      # "write" syscall
    ecall

    # shift left 4 bits
    slli  s1, s1, 4
    srli  t3, s0, 28
    or    s1, s1, t3
    slli  s0, s0, 4

    # check if loop should break
    addi  t2, t2, -1
    bne   t2, x0, printhex_loop

printhex_end:
    lw    ra, 0(sp)
    lw    s0, 4(sp)
    lw    s1, 8(sp)
    addi  sp, sp, 12        # pop 
    jr    ra
