.data
testArray:
    .word 1, 13, 0, -56, 22, -1, 0, 8, 99, -100
    .word 0, 3, -7, 42, 0, 1024, -2048, 55, -66, 0
    .word 12, 34, -45, 56, -67, 78, 0, -89, 90, -101
size:
    .word 30
Pos_num: .word 0
Neg_num: .word 0
Zero_num: .word 0
Total_sum: .word 0
    
.text
main:
    addi sp, sp, -4
    sw ra, 0(sp)

    lui s5, %hi(testArray)
    addi s5, s5, %lo(testArray)

    lui t0, %hi(size)
    lw s6, %lo(size)(t0)

    addi a0, s5, 0
    addi a1, s6, 0
    addi a2, zero, 1
    jal ra, countArray

    lui t0, %hi(Pos_num)
    sw a0, %lo(Pos_num)(t0)

    addi a0, s5, 0
    addi a1, s6, 0
    addi a2, zero, -1
    jal ra, countArray

    lui t0, %hi(Neg_num)
    sw a0, %lo(Neg_num)(t0)

    addi a0, s5, 0
    addi a1, s6, 0
    addi a2, zero, 0
    jal ra, countArray

    lui t0, %hi(Zero_num)
    sw a0, %lo(Zero_num)(t0)

    addi a0, s5, 0
    addi a1, s6, 0
    jal ra, sumArray

    lui t0, %hi(Total_sum)
    sw a0, %lo(Total_sum)(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    
done:
    jal zero, done
    
isPos:
    addi t1, zero, 1
    blt zero, a0, isPos_true
    addi a0, zero, 0
    jalr zero, ra, 0
  isPos_true:
    addi a0, t1, 0
    jalr zero, ra, 0
    
isNeg:
    addi t1, zero, 1
    blt a0, zero, isNeg_true
    addi a0, zero, 0
    jalr zero, ra, 0
  isNeg_true:
    addi a0, t1, 0
    jalr zero, ra, 0
    
isZero:
    addi t1, zero, 1
    beq a0, zero, isZero_true
    addi a0, zero, 0
    jalr zero, ra, 0
  isZero_true:
    addi a0, t1, 0
    jalr zero, ra, 0
    
countArray:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp) # count number
    sw s1, 8(sp) # pointer to current element
    sw s2, 4(sp) # number of elements left
    sw s3, 0(sp) # type of count

    addi s0, zero, 0
    addi s1, a0, 0
    addi s2, a1, 0
    addi s3, a2, 0

  count_loop_start:
    beq s2, zero, count_loop_end

    lw a0, 0(s1) # a0 will be the parameter of sub functions
    
    # cntType == 1
    addi t0, zero, 1 # t0 = 1
    bne s3, t0, cntType_is_neg
    jal ra, isPos
    jal zero, after_call

    cntType_is_neg:
    addi t0, zero, -1 # t0 = -1
    bne s3, t0, cntType_is_zero
    jal ra, isNeg
    jal zero, after_call

    cntType_is_zero:
    jal ra, isZero
    jal zero, after_call

    after_call:
    beq a0, zero, after_after_call
    addi s0, s0, 1
    after_after_call:
    addi s1, s1, 4
    addi s2, s2, -1
    jal zero, count_loop_start

  count_loop_end:
    addi a0, s0, 0

    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    jalr zero, ra, 0
    
sumArray:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    addi s0, zero, 0 # sum
    addi s1, a0, 0 # pointer to current element
    addi s2, a1, 0 # number of elements left

  sum_loop_start:
    beq s2, zero, sum_loop_end

    lw t0, 0(s1)
    add s0, s0, t0

    addi s1, s1, 4
    addi s2, s2, -1
    jal zero, sum_loop_start

  sum_loop_end:
    addi a0, s0, 0

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, ra, 0
    
    

