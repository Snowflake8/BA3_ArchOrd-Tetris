;; game state memory location
.equ T_X, 0x1000                  ; falling tetrominoe position on x
.equ T_Y, 0x1004                  ; falling tetrominoe position on y
.equ T_type, 0x1008               ; falling tetrominoe type
.equ T_orientation, 0x100C        ; falling tetrominoe orientation
.equ SCORE,  0x1010               ; score
.equ GSA, 0x1014                  ; Game State Array starting address
.equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
.equ LEDS, 0x2000                 ; LED address
.equ RANDOM_NUM, 0x2010           ; Random number generator address
.equ BUTTONS, 0x2030              ; Buttons addresses

;; type enumeration
.equ C, 0x00
.equ B, 0x01
.equ T, 0x02
.equ S, 0x03
.equ L, 0x04

;; GSA type
.equ NOTHING, 0x0
.equ PLACED, 0x1
.equ FALLING, 0x2

;; orientation enumeration
.equ N, 0
.equ E, 1
.equ So, 2
.equ W, 3
.equ ORIENTATION_END, 4

;; collision boundaries
.equ COL_X, 4
.equ COL_Y, 3

;; Rotation enumeration
.equ CLOCKWISE, 0
.equ COUNTERCLOCKWISE, 1

;; Button enumeration
.equ moveL, 0x01
.equ rotL, 0x02
.equ reset, 0x04
.equ rotR, 0x08
.equ moveR, 0x10
.equ moveD, 0x20

;; Collision return ENUM
.equ W_COL, 0
.equ E_COL, 1
.equ So_COL, 2
.equ OVERLAP, 3
.equ NONE, 4

;; start location
.equ START_X, 6
.equ START_Y, 1

;; game rate of tetrominoe falling down (in terms of game loop iteration)
.equ RATE, 5

;; standard limits
.equ X_LIMIT, 12
.equ Y_LIMIT, 8


; BEGIN:helper
.equ SP_START,0x11FC
; END:helper

; BEGIN:main
main:

	addi sp,zero,SP_START		#NOT SURE HOW TO DO THIS

	call clear_leds
	addi a0,zero,3
	addi a1,zero,3
	call set_pixel
	addi a0,zero,7
	addi a1,zero,3
	call set_pixel

	addi a0,zero,7
	addi a1,zero,3
	call in_gsa
	add s0,zero,v0			#should be 0

	addi a0,zero,12
	addi a1,zero,3
	call in_gsa
	add s1,zero,v0			#should be 1

	addi a0,zero,7
	addi a1,zero,-1
	call in_gsa
	add s2,zero,v0			#should be 1

	addi a0,zero,2
	addi a1,zero,2
	addi a2,zero, FALLING
	call set_gsa

	addi a0,zero,7
	addi a1,zero,3
	call get_gsa
	add s3,zero,v0			#should de 2

	addi a0,zero,5
	addi a1,zero,5
	addi a2,zero, FALLING
	call set_gsa

	addi t0,zero,S
	addi t1,zero,N
	addi t2,zero,8
	addi t3,zero,5
	stw t0,T_type(zero)
	stw t1,T_orientation(zero)
	stw t2,T_X(zero)
	stw t3,T_Y(zero)

	addi a0,zero,FALLING
	call draw_tetromino
	

	call draw_gsa	
	jmpi end
; END:main

; BEGIN:clear_leds
clear_leds:					#Mets tout les leds a 0
	stw zero,LEDS(zero)
	addi t0,zero,4
	stw zero,LEDS(t0)
	addi t0,t0,4
	stw zero,LEDS(t0)

	ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	srli t0,a0,2			#which LED word we are interested in
	slli t0,t0,2
	ldw t6,LEDS(t0)

	andi a0,a0,0b11			#mask
	slli a0,a0,3			#mult by 8
	add t1,a0,a1			#which bit interests us
		
	addi t2,zero,1			
	sll t2,t2,t1			#one hot encodind of the led
	or t6,t6,t2
	
	stw t6,LEDS(t0)	

	ret
; END:set_pixel

; BEGIN:wait
wait:
	addi t0, zero, 1
	slli t0, t0, 19

	wait_loop : 			#loop for 0.2s
		addi t0, t0, -1
		bne t0, zero, wait_loop

	ret
; END:wait

; BEGIN:in_gsa
in_gsa:
	cmplti t0, a0,0			#x-coord has to be 0 <= x (= a0) <= 11
	cmpgei t1,a0,X_LIMIT
	or v0,t1,t0

	cmplti t0,a1,0			#y-coord has to be 0 <= y (= a0) <= 7
	cmpgei t1,a1,Y_LIMIT
	or v0,v0,t0
	or v0,v0,t1				#return 1 if this is not respected

	ret							
; END:in_gsa

; BEGIN:get_gsa
get_gsa:
	slli a0,a0,3			#get the correct value
	add a0,a0,a1

	slli a0,a0,2			#retrieve from memory
	ldw v0,GSA(a0)	
			
	ret
; END:get_gsa

; BEGIN:set_gsa
set_gsa:
	slli a0,a0,3			#get the correct value
	add a0,a0,a1

	slli a0,a0,2			#set to memory
	stw a2,GSA(a0)
	
	ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	addi sp,sp,12			#stack ra,s0,s1
	stw ra,-8(sp)
	stw s0,-4(sp)
	stw s1,0(sp)

	call clear_leds			#put all leds to 0		
	addi s0,zero,0			#put x to 0 

	draw_x_loop:
		addi s1,zero,0		#put y to 0 
	
		draw_y_loop:

			add a0,zero,s0		#get the gsa
			add a1,zero,s1
			call get_gsa
			add v1,zero,v0
					
			beq v1,zero,pixel_is_unlit
				
				add a0,zero,s0		#light the pixel
				add a1,zero,s1
				call set_pixel

			pixel_is_unlit:
			addi t7,zero,Y_LIMIT
			addi s1,s1,1
			blt s1,t7,draw_y_loop	#iterate over all y

		addi t6,zero,X_LIMIT
		addi s0,s0,1
		blt s0,t6,draw_x_loop	#iterate over all x

	ldw s1,	0(sp)			#desatck
	ldw s0,-4(sp)
	ldw ra,-8(sp)
	addi sp,sp,-12	

	ret
; END:draw_gsa

; BEGIN:draw_tetromino
draw_tetromino:
	addi sp,sp,12			#stack ra,s0,s1
	stw ra,-8(sp)
	stw s0,-4(sp)
	stw s1,0(sp)

	add a2, zero,a0				#a2 is the arg for set_gsa
	
	ldw a0,T_X(zero)			#set the anchor in gsa correctly
	ldw a1,T_Y(zero)
	call set_gsa

	ldw t0,T_type(zero)			#create the base address
	slli t0,t0,2				#each type is four different directions
	ldw t1,T_orientation(zero)		
	add s1,t0,t1
	slli s1,s1,2				#word aligned
	ldw s1,DRAW_Ax(s1)			#s1 is the base adress,that is the adress where the first X non-anchor offset is stored
								#draw_Ax stores adresses and not values
	
	addi s0,zero,0
	draw_tetromino_loop:
		slli t0,s0,2				#word aligned
		addi t1,t0,0xC				#0xC further for y(first the 3 X then the 3 Y)
		add t1,t1,s1				#create the exact adresses
		add t0,t0,s1

		ldw	t0,0(t0)				#load the offsets
		ldw	t1,0(t1)

		ldw a0,T_X(zero)			#calculate x and y by adding the offsets
		ldw a1,T_Y(zero)
		add a0,a0,t0
		add a1,a1,t1
			
		call set_gsa

		addi s0,s0,1
		addi t7,zero,3

		bne s0,t7,draw_tetromino_loop 	#iterate over the 3 non-achor points
		
	ldw s1,	0(sp)			#destack
	ldw s0,-4(sp)
	ldw ra,-8(sp)
	addi sp,sp,-12	

	ret
; END:draw_tetromino


; BEGIN:generate_tetromino
generate_tetromino:
	ldw t0,RANDOM_NUM(zero)			#read the random int
	andi t0,t0,0b111				#take its last 3 bits
	cmplti t1,t0,5					
	beq t1,zero,generate_tetromino	#try again if its more or equal to 5
	
	stw t0,T_type(zero)				#store all the values
	stw zero,T_orientation(zero)	#N is zero
	addi t0,zero,START_X
	stw t0,T_X(zero)
	addi t0,zero,START_Y
	stw t0,T_Y(zero)

	ret
; END:generate_tetromino


; BEGIN:detect_collision
detect_collision:

	addi sp, sp, 20								# stack ra, s0, s1, s2, s3, s4
	stw ra, -20(sp)
	stw s0, -16(sp)
	stw s1, -12(sp)
	stw s2, -8(sp)
	stw s3, -4(sp)
	stw s4, 0(sp)

	add s2, zero, a0							# store parameter a0

	ldw a0, T_X(zero)							# load the position of the falling piece's anchor
	ldw a1, T_Y(zero)

	# branch to correct simulation
	# in case of OVERLAP, goes through directly to check_collision
	addi t0, zero, W_COL
	beq s2, t0, detect_collision_case_w_col
	addi t0, zero, E_COL
	beq s2, t0, detect_collision_case_e_col
	addi t0, zero, So_COL
	beq s2, t0, detect_collision_case_so_col

	# creates a simulation of the falling piece where we are checking it for collision
	detect_collision_case_w_col:
		addi a0, a0, -1
		jmpi check_collision
	detect_collision_case_e_col:
		addi a0, a0, 1
		jmpi check_collision
	detect_collision_case_so_col:
		addi a1, a1, 1
		jmpi check_collision


	check_collision:
		# compute base address of the falling piece
		ldw t0, T_type(zero)
		slli t0, t0, 2							# each type has four different directions
		ldw t1, T_orientation(zero)
		add s3, t0, t1
		slli s3, s3, 2							# word aligned
		# sth else ?


		add s4, zero, zero						# counter (to loop over 4 parts of the piece)
		detect_collision_loop:

			add t0, zero, s4
			slli t0, t0, 2
			add t0, t0, s3						# t0 = 4 * s4 + baseAddress(s3)
			addi t1, t0, 0xC
			add t1, t1, s3						# t1 = t0 + 12 + baseAddress(s3) 

			ldw t0, 0(t0)						# x offset
			ldw t1, 0(t1)						# y offset

			# calculating x and y based on offsets
			ldw a0, T_X(zero)
			ldw a1, T_Y(zero)
			add a0, a0, t0
			add a1, a1, t1

			add s0, zero, a0					# saving x coord of simulated piece part
			add s1, zero, a1					# saving y coord of simulated piece part


			# check if the simulated piece is still in the grid
			call in_gsa
			bne v0, zero, detect_collision_colliding	# error if not in gsa anymore


			# check if the simulated piece doesn't collide with another
			add a0, zero, s0
			add a1, zero, s1
			call get_gsa

			addi t0, zero, PLACED
			beq v0, t0, detect_collision_colliding		# error if colliding with terrain


			# iterate over the 3 non-achor piece parts
			addi s4, s4, 1
			addi t7, zero, 3

			bne s4, t7, detect_collision_loop	# loop over 4 piece parts

			# no collision detected
			addi t0, zero, NONE
			add v0, zero, t0					# returns NONE since no collision
			jmpi detect_collision_end


	# collision detected
	detect_collision_colliding:
		add v0, zero, s2						# returns input value since collision detected

	detect_collision_end:
		ldw s4, 0(sp)							# destack s4, s3, s2, s1, s0, ra
		ldw s3, -4(sp)
		ldw s2, -8(sp)
		ldw s1, -12(sp)
		ldw s0, -16(sp)
		ldw ra, -20(sp)
		addi sp, sp, -20

	ret
; END:detect_collision


; BEGIN:rotate_tetromino
rotate_tetromino:						#select the direction
	addi t0,zero,rotL
	beq a0,t0,rotate_isRotL

	rotate_isRotR:
		addi t7,zero,1						#rotR is direction 1
		jmpi rotate_start
	rotate_isRotL:
		addi t7,zero,-1						#rotR is direction -1

rotate_start:
	ldw t0,T_orientation(zero)			#change the orientation
	add t0,t0,t7
	andi t0,t0,0b11
	stw t0,T_orientation(zero)

	ret
; END:rotate_tetromino


; BEGIN:helper
towards_center:
	addi t0,zero,6
	bge a0,t0,center_negative
	addi v0,zero,1
	ret
center_negative:
	addi v0,zero,-1
	ret
; END:helper

; BEGIN:act
act:
	addi sp,sp,8			#stack ra,s0,s1
	stw ra,-4(sp)
	stw s0,0(sp)

	add s0,zero,a0			#our argument

	addi t0,zero,moveL		#do different things depending on input
	beq a0,t0,act_moveL
	addi t0,zero,moveR
	beq a0,t0,act_moveR
	addi t0,zero,moveD
	beq a0,t0,act_moveD

	addi t0,zero,rotL
	beq a0,t0,act_rot
	addi t0,zero,rotR
	beq a0,t0,act_rot

	act_reset:
		call reset_game		
		jmpi act_end

	act_moveL:
		add a0,zero,s0
		call detect_collision
		bne v0,s0,act_fail			#if collision we do nothing to t_x

		ldw t0,T_X(zero)			#else -1 to t_x
		addi t0,t0,-1
		stw t0,T_X(zero)
	
		addi v0,zero,0
		jmpi act_end

	act_moveR:
		add a0,zero,s0
		call detect_collision
		bne v0,s0,act_fail			#if collision we do nothing to t_x

		ldw t0,T_X(zero)			#else +1 to t_x
		addi t0,t0,1
		stw t0,T_X(zero)

		addi v0,zero,0
		jmpi act_end
	
	act_moveD:	
		add a0,zero,s0
		call detect_collision
		bne v0,s0,act_fail			#if collision we do nothing to t_y
	
		ldw t0,T_Y(zero)			#else +1 to t_y
		addi t0,t0,1
		stw t0,T_Y(zero)

		addi v0,zero,0
		jmpi act_end
	
	act_rot:
		#stack gsa and all
		
		addi sp,sp,16			#stack x,y and orientation
		stw s1,-12(sp)
		ldw t0,T_X(zero)
		stw t0,-8(sp)
		ldw t0,T_Y(zero)
		stw t0,-4(sp)
		ldw t0,T_orientation(zero)
		stw t0,0(sp)
	
		add a0,zero,s0
		call rotate_tetromino
		
		addi s1,zero,0
	
		addi a0,zero,OVERLAP
		call detect_collision

		addi t0,zero,OVERLAP
		beq t0,v0,act_rot_loop
		addi sp,sp,-16			#directly sucessful
		addi v0,zero,0
		jmpi act_end
			
		act_rot_loop:

			addi s1,zero,1
			addi t0,zero,3
			beq s1,t0,act_rot_end_fail
			ldw a0,T_X(zero)
			call towards_center
			ldw t0,T_X(zero)
			add t0,v0,t0
			stw t0,T_X(zero)	
	
			addi a0,zero,OVERLAP
			call detect_collision			

			addi t0,zero,OVERLAP
			beq t0,v0,act_rot_loop
	
		addi sp,sp,-16			#sucessful within 2 towards center
		addi v0,zero,0
		jmpi act_end
	act_rot_end_fail:
		addi sp,sp,-16			#destack ra,s0,s1
	
		ldw t0,16(sp)
		stw t0,T_orientation(zero)
		ldw t0,12(sp)
		stw t0,T_Y(zero)
		ldw t0,8(sp)
		stw t0,T_X(zero)
		ldw s1,4(zero)
		#destack gsa and all
act_fail:
	addi v0,zero,1
act_end:
	ldw s0,0(sp)			#destack
	ldw ra,-4(sp)
	addi sp,sp,-8
	ret
; END:act


; BEGIN:helper
clear_gsa:
	addi sp,sp,12			#stack ra,s0,s1
	stw ra,-8(sp)
	stw s0,-4(sp)
	stw s1,0(sp)

	addi s0,zero,0			#put x to 0 

	clear_gsa_x_loop:

		addi s1,zero,0		#put y to 0 	
		clear_gsa_y_loop:
			add a0,zero,s0		#light the pixel
			add a1,zero,s1
			addi a2,zero,NOTHING
			call set_pixel

			addi t7,zero,Y_LIMIT
			addi s1,s1,1
			blt s1,t7,clear_gsa_y_loop	#iterate over all y

		addi t6,zero,X_LIMIT
		addi s0,s0,1
		blt s0,t6,clear_gsa_x_loop	#iterate over all x

	ldw s1,	0(sp)			#destack
	ldw s0,-4(sp)
	ldw ra,-8(sp)
	addi sp,sp,-12
	ret
; END:helper

; BEGIN:reset_game
reset_game:#TODO put score to 0
	addi sp,sp,4			#stack ra,s0,s1
	stw ra,0(sp)
	call clear_gsa
	
	call generate_tetromino
	call draw_tetromino
	call draw_gsa
	ldw ra,0(sp)
	addi sp,sp,-4			#stack ra,s0,s1
	ret
; END:reset_game


; BEGIN:end
end:
	break
; END:end

font_data:
  .word 0xFC  ; 0
  .word 0x60  ; 1
  .word 0xDA  ; 2
  .word 0xF2  ; 3
  .word 0x66  ; 4
  .word 0xB6  ; 5
  .word 0xBE  ; 6
  .word 0xE0  ; 7
  .word 0xFE  ; 8
  .word 0xF6  ; 9

C_N_X:
.word 0x00
.word 0xFFFFFFFF
.word 0xFFFFFFFF

C_N_Y:
.word 0xFFFFFFFF
.word 0x00
.word 0xFFFFFFFF

C_E_X:
.word 0x01
.word 0x00
.word 0x01

C_E_Y:
.word 0x00
.word 0xFFFFFFFF
.word 0xFFFFFFFF

C_So_X:
.word 0x01
.word 0x00
.word 0x01

C_So_Y:
.word 0x00
.word 0x01
.word 0x01

C_W_X:
.word 0xFFFFFFFF
.word 0x00
.word 0xFFFFFFFF

C_W_Y:
.word 0x00
.word 0x01
.word 0x01

B_N_X:
.word 0xFFFFFFFF
.word 0x01
.word 0x02

B_N_Y:
.word 0x00
.word 0x00
.word 0x00

B_E_X:
.word 0x00
.word 0x00
.word 0x00

B_E_Y:
.word 0xFFFFFFFF
.word 0x01
.word 0x02

B_So_X:
.word 0xFFFFFFFE
.word 0xFFFFFFFF
.word 0x01

B_So_Y:
.word 0x00
.word 0x00
.word 0x00

B_W_X:
.word 0x00
.word 0x00
.word 0x00

B_W_Y:
.word 0xFFFFFFFE
.word 0xFFFFFFFF
.word 0x01

T_N_X:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

T_N_Y:
.word 0x00
.word 0xFFFFFFFF
.word 0x00

T_E_X:
.word 0x00
.word 0x01
.word 0x00

T_E_Y:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

T_So_X:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

T_So_Y:
.word 0x00
.word 0x01
.word 0x00

T_W_X:
.word 0x00
.word 0xFFFFFFFF
.word 0x00

T_W_Y:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

S_N_X:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

S_N_Y:
.word 0x00
.word 0xFFFFFFFF
.word 0xFFFFFFFF

S_E_X:
.word 0x00
.word 0x01
.word 0x01

S_E_Y:
.word 0xFFFFFFFF
.word 0x00
.word 0x01

S_So_X:
.word 0x01
.word 0x00
.word 0xFFFFFFFF

S_So_Y:
.word 0x00
.word 0x01
.word 0x01

S_W_X:
.word 0x00
.word 0xFFFFFFFF
.word 0xFFFFFFFF

S_W_Y:
.word 0x01
.word 0x00
.word 0xFFFFFFFF

L_N_X:
.word 0xFFFFFFFF
.word 0x01
.word 0x01

L_N_Y:
.word 0x00
.word 0x00
.word 0xFFFFFFFF

L_E_X:
.word 0x00
.word 0x00
.word 0x01

L_E_Y:
.word 0xFFFFFFFF
.word 0x01
.word 0x01

L_So_X:
.word 0xFFFFFFFF
.word 0x01
.word 0xFFFFFFFF

L_So_Y:
.word 0x00
.word 0x00
.word 0x01

L_W_X:
.word 0x00
.word 0x00
.word 0xFFFFFFFF

L_W_Y:
.word 0x01
.word 0xFFFFFFFF
.word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
  .word C_N_X
  .word C_E_X
  .word C_So_X
  .word C_W_X
  .word B_N_X
  .word B_E_X
  .word B_So_X
  .word B_W_X
  .word T_N_X
  .word T_E_X
  .word T_So_X
  .word T_W_X
  .word S_N_X
  .word S_E_X
  .word S_So_X
  .word S_W_X
  .word L_N_X
  .word L_E_X
  .word L_So_X
  .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
  .word C_N_Y
  .word C_E_Y
  .word C_So_Y
  .word C_W_Y
  .word B_N_Y
  .word B_E_Y
  .word B_So_Y
  .word B_W_Y
  .word T_N_Y
  .word T_E_Y
  .word T_So_Y
  .word T_W_Y
  .word S_N_Y
  .word S_E_Y
  .word S_So_Y
  .word S_W_Y
  .word L_N_Y
  .word L_E_Y
  .word L_So_Y
  .word L_W_Y

