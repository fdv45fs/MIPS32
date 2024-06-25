.eqv MONITOR_SCREEN 0x10040000 #Screen address #making space for circle texture
.eqv KEY_CODE 0xFFFF0004 # ASCII code from keyboard, 1 byte 
.eqv KEY_READY 0xFFFF0000 # =1 if has a new keycode ? 
 # Auto clear after lw 
.eqv DISPLAY_CODE 0xFFFF000C # ASCII code to show, 1 byte 
.eqv DISPLAY_READY 0xFFFF0008 # =1 if the display has already to do 
 # Auto clear after sw 
.data
A: .word 484336, 484340, 484344, 484348, 484352, 484356, 484360, 484364, 484368, 486372, 486376, 486380, 486420, 486424, 486428, 488412, 488416, 488480, 488484, 490452, 490456, 490536, 490540, 492496, 492592, 494540, 494644, 496584, 496696, 498628, 498748, 500672, 500800, 502716, 502852, 504764, 504900, 506808, 506952, 508856, 509000, 510900, 511052, 512948, 513100, 514996, 515148, 517040, 517200, 519088, 519248, 521136, 521296, 523184, 523344, 525232, 525392, 527280, 527440, 529328, 529488, 531376, 531536, 533424, 533584, 535476, 535628, 537524, 537676, 539572, 539724, 541624, 541768, 543672, 543816, 545724, 545860, 547772, 547908, 549824, 549952, 551876, 551996, 553928, 554040, 555980, 556084, 558032, 558128, 560084, 560088, 560168, 560172, 562140, 562144, 562208, 562212, 564196, 564200, 564204, 564244, 564248, 564252, 566256, 566260, 566264, 566268, 566272, 566276, 566280, 566284, 566288
endA: .word 525312 #center

.text 
li $k0, MONITOR_SCREEN # k0: screen address
li $s7, 512 # const, for div
li $t8, 0 # x_velo
li $t9, 0 # y_velo * 512
la $s0, A # address of A
la $s1, endA
li $s2, 4 # speed # 1 pixel/cyle

li $s5, KEY_CODE 
li $s6, KEY_READY 
li $s3, DISPLAY_CODE
li $s4, DISPLAY_READY
whileTrue:
 #if key pressed: trap
 checkForKey: lw $t1, 0($s6) # $t1 = KEY_READY 
 MakeIntR: teqi $t1, 1 # if $t1 = 1 then raise an Interrupt
 
 #clear ball
 li $t0, 0x00000000 # black
 jal renderFunc
 
 add $t1, $0, $s0 # address of A
 calcPos:
  bgt $t1, $s1, eCalcPos # bgt to include center
  lw $t2, 0($t1) # get coordinate in array A
  beq $t8, $0, skipUpdateX # skip if x_velo = 0
   slt $t3, $t8, $0 # x_velo < 0 ?
   beq $t3, $0, posiX #if x_velo is negative
    subu $t8, $0, $s2
    j skipUpdateX
   posiX: #else (x_velo is positive)
    addu $t8, $0, $s2
  skipUpdateX:
  beq $t9, $0, skipUpdateY
   sll $t4, $s2, 9 # speed * 512
   slt $t3, $t9, $0 # y_velo < 0 ?
   beq $t3, $0, posiY
    subu $t9, $0, $t4
    j skipUpdateY
   posiY:
    addu $t9, $0, $t4
  skipUpdateY:
  add $t2, $t2, $t8 # add x_velo to coordinate
  add $t2, $t2, $t9 # add y_velo*512 to coordinate
  sw $t2, 0($t1) # store new coordinate
  addi $t1, $t1, 4
 j calcPos
 eCalcPos:
 
 #direction change
 lw $t2, 0($s1) # get centerX in array A
 srl $t2, $t2, 2 # /4 (size of word)
 div $t2, $s7 # $t2 /512, LO: y, HI: x
 mfhi $t3
 sgt $t4, $t3, 21 #t3 > 21 -> 1
 slti $t5, $t3, 490
 and $t3, $t4, $t5 # $t3: x in range?
 mflo $t4
 sgt $t5, $t4, 21
 slti $t6, $t4, 490
 and $t4, $t5, $t6 # $t4: y in range?
 and $t3, $t3, $t4 # $t3: in rect?
 bne $t3, $0, renderStage
 subu $t8, $0, $t8 #reverse speed
 subu $t9, $0, $t9
 
 renderStage:
 #render ball 
 li $t0, 0x00ffffff # white
 jal renderFunc
 
 li $v0, 32          # Syscall code for sleep
 li $a0, 20        # Load sleep duration in milliseconds
 syscall
 
 j whileTrue
eWhileTrue:

renderFunc: #arg: $t0 color, modify: $t1, $t2
 add $t1, $0, $s0 # address of A
 render:
  beq $t1, $s1, eRender
  lw $t2, 0($t1) # get coordinate in array A
  add $t2, $t2, $k0 # add to base address of display
  sw $t0, 0($t2) # render with the color $t0
  addi $t1, $t1, 4
  j render
 eRender:
jr $ra

.ktext 0x80000180 #trap, keyboard handling
 ReadKey: lw $t1, 0($s5) # $t1 = KEY_CODE
 li $t2, 'd'
 beq $t1, $t2, case_d
 li $t2, 'a'
 beq $t1, $t2, case_a
 li $t2, 'w'
 beq $t1, $t2, case_w 
 li $t2, 's'
 beq $t1, $t2, case_s
 li $t2, 'x'
 beq $t1, $t2, case_x
 li $t2, 'z'
 beq $t1, $t2, case_z
 WaitForDis: lw $t2, 0($s4) # $t2 = DISPLAY_READY 
 beq $t2, $0, WaitForDis # if $t2 == 0 then Polling 
 ShowKey: sw $t1, 0($s3) # show key
 next_pc: mfc0 $at, $14 # $at <= Coproc0.$14 = Coproc0.epc 
 addi $at, $at, 4 # $at = $at + 4 (next instruction) 
 mtc0 $at, $14 # Coproc0.$14 = Coproc0.epc <= $at 
return: eret

case_d:
    # x_velo = ball_speed
    add $t8, $0, $s2
    # y_velo = 0
    li $t9, 0
    j WaitForDis
case_a:
    # x_velo = -ball_speed
    subu $t8, $zero, $s2
    # y_velo = 0
    li $t9, 0
    j WaitForDis
case_w:
    # y_velo = -ball_speed * 512
    sll $t2, $s2, 9
    subu $t9, $zero, $t2
    # x_velo = 0
    li $t8, 0
    j WaitForDis
case_s:
    # y_velo = ball_speed * 512
    sll $t2, $s2, 9
    addu $t9, $zero, $t2
    # x_velo = 0
    li $t8, 0
    j WaitForDis
case_x:
    # ball_speed -= 4
    addi $s2, $s2, -4
    j WaitForDis
case_z:
    # ball_speed += 4
    addi $s2, $s2, 4
    j WaitForDis
