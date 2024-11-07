.data 0x10007000
    # Display constants
    UNITS_HEIGHT: .word 16
    UNITS_WIDTH: .word 16
    IMAGE_HEIGHT: .word 256
    IMAGE_WIDTH: .word 256	
    IMAGE_HEIGHT_IN_UNITS: .word 0
    IMAGE_WIDTH_IN_UNITS: .word 0
    DISPLAY_ADDRESS: .word 0x10010000
    BORDER_OBST_ARRAY_ADRESS: .word 0
    TOTAL_NUM_OBS: .word 0
    NUM_OBS: .word 5


    # Color constants
    COLOR_BLACK:  .word 0x00000000
    COLOR_RED:    .word 0x00ff0000
    COLOR_GREEN:  .word 0x0000ff00
    COLOR_BLUE:   .word 0x000000ff
    COLOR_YELLOW: .word 0x00ffff00
    
    # Key codes
    KEY_Z: .word 122     # Up
    KEY_S: .word 115     # Down
    KEY_Q: .word 113     # Left
    KEY_D: .word 100     # Right
    
    SNAKE_QUEUE: .word 0     # Will store the address of the snake queue structure
    SNAKE_CURRENT_LENGTH: .word 1  # Start with length 1
    SNAKE_MAX_LENGTH: .word 15    # Maximum possible length increased
    
    # Snake + Food : Settings
    SNAKE_DIRECTION: .word 0  # 0:right, 1:down, 2:left, 3:up
    FOOD_X: .word 0
    FOOD_Y: .word 0
    FOOD_COLOR: .word 0x0000ff00  # Green color
    DELAY: .word 100000      # Delay for snake movement
    CURRENT_DIRECTION: .space 1  # Space to store current direction
    CURRENT_X: .word 8      # Current snake head X position
    CURRENT_Y: .word 8      # Current snake head Y position
    
    MSG_FOOD_EATEN: .string "Bravo !\n"
    MSG_DEAD_SNAKE: .string "Oh non, vous etes mort !\n" 
    MSG_END_GAME: .string "Vous avez gagne !\n"
    MSG_EMPTY: .string "La file est vide\n"
    MSG_FULL: .string "La file est pleine\n"
    MSG_NEWLINE: .string "\n"
    MSG_SPACE: .string " "
    

.text
.globl main

# Fonction principale du jeu
main:
    # Initialize display dimensions
    jal I_largeur
    jal I_hauteur
    
    # Create obstacles array with 10 random internal obstacles
    lw a0, NUM_OBS          
    jal O_creer         
    
    
    lw a0, BORDER_OBST_ARRAY_ADRESS
    lw a1, TOTAL_NUM_OBS # Load total number of obstacles
    jal O_afficher      # Display all obstacles
    

    # Initialize snake
    jal init_snake
    
    # Initialize food
    jal spawn_food
   
    # Wait for the first user-input before starting the game		
    jal wait_input
    
    
    # Main game loop
    j game_loop
    


game_loop:

    # Check for keyboard input
    jal check_input

    # Move snake
    jal move_snake
    
    # Check if snake ate the food
    jal check_food_collision
    
    # Add snake collision check here
    jal check_snake_collision
    
    # Add delay
    jal delay

    j game_loop


game_won:
    la a0, MSG_END_GAME
    li a7, 4
    ecall
    
    li a7, 10
    ecall

game_over:
    li a7, 10
    ecall

            #-------------------------------------------------------------------------------#
                                    # Arena Related Functions


# Cree un tableau d'obstacles incluant les bordures et des obstacles aleatoires
# Arguments: a0 = nombre d'obstacles aleatoires souhaites
# Retour: a0 = adresse du tableau alloue, met a jour TOTAL_NUM_OBS
O_creer:
    # Save registers and number of random obstacles
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)        # for array base
    sw s1, 8(sp)        # for counter
    sw s2, 12(sp)       # for num obstacles
    sw s3, 16(sp)       # for random obstacle count


    # Calculate total size needed
    lw t0, IMAGE_HEIGHT_IN_UNITS  # height
    lw t1, IMAGE_WIDTH_IN_UNITS   # width
    add t2, t0, t0               # 2 * (height) for sides
    add t3, t1, t1               # 2 * (width) for top/bottom
    add t2, t2, t3              # Total perimeter
    add t2, t2, a0              # Add random obstacles
    
    # Store total number of obstacles in TOTAL_NUM_OBS
    la t5, TOTAL_NUM_OBS
    sw t2, 0(t5)
    

    mv s3, a0           # save random obstacle count
    
    # Allocate array
    mv s2, t2           # save total size
    slli a0, t2, 2      
    li a7, 9
    ecall
    
    # Save base address
    la t6, BORDER_OBST_ARRAY_ADRESS
    sw a0, 0(t6)
    mv s0, a0           # save array base
    
    # Add top border
    li s1, 0            # counter
    lw t1, IMAGE_WIDTH_IN_UNITS    # limit x
top_border:
    mv a0, s1           # x coord
    li a1, 0            # y coord = 0
    jal I_coordToAdresse
    sw a0, (s0)         # store address in array
    addi s0, s0, 4
    addi s1, s1, 1
    blt s1, t1, top_border
    
    # Add bottom border
    li s1, 0
    lw t1, IMAGE_WIDTH_IN_UNITS
    
bottom_border:
    lw t0, IMAGE_HEIGHT_IN_UNITS
    addi t0, t0, -1     # y = height - 1
    
    mv a0, s1           # x coord
    mv a1, t0           # y = height - 1
    jal I_coordToAdresse
    sw a0, (s0)
    addi s0, s0, 4
    addi s1, s1, 1
    blt s1, t1, bottom_border
    
    # Add left border 
    li s1, 0            # start at y=0
    lw t1, IMAGE_HEIGHT_IN_UNITS
left_border:
    li a0, 0            # x = 0
    mv a1, s1           # y coord
    jal I_coordToAdresse
    sw a0, (s0)
    addi s0, s0, 4
    addi s1, s1, 1
    blt s1, t1, left_border
   
   
    li s1, 0            
    lw t1, IMAGE_HEIGHT_IN_UNITS
    
right_border:
    lw t0, IMAGE_WIDTH_IN_UNITS
    addi t0, t0, -1     # x = width - 1
    
    mv a0, t0           # x = width - 1
    mv a1, s1           # y coord
    jal I_coordToAdresse
    sw a0, (s0)
    addi s0, s0, 4
    addi s1, s1, 1
    blt s1, t1, right_border

    # Add random obstacles (avoid borders)
    mv s2, s3           # restore number of random obstacles
random_obstacles:
    beqz s2, done_creer       # if no more obstacles to add
    
    # Get random x coordinate (between 1 and width-2)
    lw t3, IMAGE_WIDTH_IN_UNITS
    addi t3, t3, -2     # max x = width - 2
    li a7, 42           
    ecall
    rem a0, a0, t3
    addi a0, a0, 1      # Add 1 to avoid border
    mv t0, a0           # save x
    
    # Get random y coordinate (between 1 and height-2)
    lw t4, IMAGE_HEIGHT_IN_UNITS
    addi t4, t4, -2     # max y = height - 2
    li a7, 42
    ecall
    rem a0, a0, t4
    addi a0, a0, 1      # Add 1 to avoid border
    mv a1, a0           # y coord
    mv a0, t0           # x coord
    
    jal I_coordToAdresse
    sw a0, (s0)         # store in array
    addi s0, s0, 4
    addi s2, s2, -1
    j random_obstacles

done_creer:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret
	
	


# Colorie tous les pixels dans le tableau d'obstacles
# Arguments: a0 = adresse de base du tableau d'obstacles, a1 = nombre d'obstacles
# Retour: Aucun (affiche les pixels a l'ecran)
O_afficher:
    # Save registers
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)    # Save array base address
    sw s1, 8(sp)    # Save counter
    sw s2, 12(sp)   # Save number of elements
    sw s3, 16(sp)   # Save obstacle color

    # Initialize variables
    mv s0, a0       # s0 = array base address
    mv s2, a1       # s2 = number of elements
    li s1, 0        # s1 = counter = 0
    
    lw t0, NUM_OBS
    
    sub t0, s2, t0
    # Load blue color for obstacles
    lw s3, COLOR_BLUE   # Use blue color for obstacles
    
loop_afficher:
    #beq s1, s2, done_afficher    # If counter == number of elements, exit
    beq s1, t0, change_obs_color
    # Load current obstacle coordinates
    lw a0, (s0)                  # Load address from array
    
    mv a2, s3             # Color for the pixel
    call I_plot

    # Increment counter and array pointer
    addi s1, s1, 1               # counter++
    addi s0, s0, 4               # Move to next array element
    j loop_afficher
   
change_obs_color:
	beq s1, s2, done_afficher
	
	lw s3, COLOR_YELLOW
	mv a2, s3
	
	lw a0, (s0)                  # Load address from array
	
	call I_plot
	
	addi s1, s1, 1
	addi s0, s0, 4
	
	j change_obs_color

done_afficher:
    # Restore registers
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret

# Verifie si un pixel donne est present dans le tableau d'obstacles
# Arguments: a0 = adresse du tableau, a1 = nombre d'elements, a2 = pixel a chercher
# Retour: a0 = 1 si trouve, 0 sinon
O_contient:
    # Save return address
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)    # Save array base address
    sw s1, 8(sp)    # Save counter
    sw s2, 12(sp)   # Save pixel to find
    sw s3, 16(sp)   # Save return value
    sw s4, 20(sp)   # Save current pixel address

    
    # Load arguments into saved registers
    mv s0, a0      # s0 = array base address
    li s1, 0       # s1 = counter
    mv s2, a2      # s2 = pixel to find
    mv s3, a1      # s3 = number of elements

loop_contient:    
    lw s4, (s0)            # Load current pixel address
    beq s2, s4, pixel_found    # If match found, jump to found
    beq s1, s3, not_found      # If reached end of array, jump to not found
    
    addi s0, s0, 4        # Move to next array element
    addi s1, s1, 1        # Increment counter
    j loop_contient
    
pixel_found:
    li a0, 1              # Return 1 (found)
    j end_contient
    
not_found:
    li a0, 0              # Return 0 (not found)
    
end_contient:
    # Restore return address
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    ret

            #-------------------------------------------------------------------------------#
                                    # User-Input Related Functions

wait_input:
	addi sp, sp, -4
	sw ra, 	0(sp)
	
	lw t0, 0xffff0000
	beqz t0, wait_input
	
	lw t1, 0xffff0004
	
	# Compare with ZQSD keys and update direction
    	la t2, KEY_Z
    	lw t0, 0(t2)
    	beq t1, t0, set_first_up
    	la t2, KEY_S
    	lw t0, 0(t2)
    	beq t1, t0, set_first_down
    	la t2, KEY_Q
    	lw t0, 0(t2)
    	beq t1, t0, set_first_left
    	la t2, KEY_D
    	lw t0, 0(t2)
    	beq t1, t0, set_first_right

set_first_up:
    li t0, 3
    j set_first_direction
    
set_first_down:
    li t0, 1
    j set_first_direction
    
set_first_left:
    li t0, 2
    j set_first_direction
    
set_first_right:
    li t0, 0
    j set_first_direction

set_first_direction:
    la t1, CURRENT_DIRECTION
    sw t0, 0(t1)

wait_input_end:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
    
    
# Verifie les entrees clavier (Z,Q,S,D)
check_input:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Check if key is pressed
    lw t0, 0xffff0000
    beqz t0, check_input_end
    
    # Read the key
    lw t1, 0xffff0004
    
    # Compare with ZQSD keys and update direction
    la t2, KEY_Z
    lw t0, 0(t2)
    beq t1, t0, set_up
    la t2, KEY_S
    lw t0, 0(t2)
    beq t1, t0, set_down
    la t2, KEY_Q
    lw t0, 0(t2)
    beq t1, t0, set_left
    la t2, KEY_D
    lw t0, 0(t2)
    beq t1, t0, set_right
    j check_input_end

set_up:
    li t0, 3

    li t1, 1
    lw t2, CURRENT_DIRECTION
    beq t1, t2, check_input_end

    j set_direction
set_down:
    li t0, 1
    li t1, 3
    lw t2, CURRENT_DIRECTION
    beq t1, t2, check_input_end

    j set_direction
set_left:
    li t0, 2

    li t1, 0
    lw t2, CURRENT_DIRECTION
    beq t1, t2, check_input_end

    j set_direction
set_right:
    li t0, 0

    li t1, 2
    lw t2, CURRENT_DIRECTION
    beq t1, t2, check_input_end

    j set_direction

set_direction:
    la t1, CURRENT_DIRECTION
    sw t0, 0(t1)

check_input_end:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


            #-------------------------------------------------------------------------------#
                                    # Snake Related Functions

# Initialise le serpent avec une longueur de 1
init_snake:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Create the snake queue
    jal F_creer
    la t0, SNAKE_QUEUE
    sw a0, 0(t0)        # Store queue address
    
    # Add initial snake position to queue
    la t0, SNAKE_QUEUE
    lw a0, 0(t0)        # Load queue address
    la t1, CURRENT_X
    lw t2, 0(t1)        # Load X
    la t1, CURRENT_Y
    lw t3, 0(t1)        # Load Y
    
    # Convert coordinates to display address
    mv a0, t2
    mv a1, t3
    jal I_coordToAdresse
    
    # Store in queue (a0 now contains the display address)
    la t0, SNAKE_QUEUE
    lw t1, 0(t0)
    mv t2, a0           # Save display address
    mv a0, t1           # Queue address
    mv a1, t2           # Display address as queue element
    jal F_enfiler
    
    # Draw initial snake position
    jal draw_snake
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Deplace le serpent dans la direction actuelle
move_snake:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Clear current position
    jal clear_snake
    
    # Update position based on direction
    la t1, CURRENT_DIRECTION
    lw t0, 0(t1)
    
    la t1, CURRENT_X
    la t2, CURRENT_Y
    lw t3, 0(t1)  # Load current X
    lw t4, 0(t2)  # Load current Y
    
    beqz t0, move_right
    li t5, 1
    beq t0, t5, move_down
    li t5, 2
    beq t0, t5, move_left
    j move_up
    
move_right:
    addi t3, t3, 1
    j apply_move
move_down:
    addi t4, t4, 1
    j apply_move
move_left:
    addi t3, t3, -1
    j apply_move
move_up:
    addi t4, t4, -1

apply_move:
    # Save new position
    sw t3, 0(t1)  # Save new X
    sw t4, 0(t2)  # Save new Y
    
    # Convert new position to display address
    mv a0, t3
    mv a1, t4
    jal I_coordToAdresse
    
    # Add new position to queue
    la t0, SNAKE_QUEUE
    lw t1, 0(t0)
    mv t2, a0           # Save display address
    mv a0, t1           # Queue address
    mv a1, t2           # Display address as queue element
    jal F_enfiler
    
    # Check if snake is longer than current length
    la t0, SNAKE_QUEUE
    lw a0, 0(t0)
    lw t1, 8(a0)        # Get current queue size
    la t2, SNAKE_CURRENT_LENGTH
    lw t3, 0(t2)        # Get current length
    
    # If current size > current length, remove tail
    ble t1, t3, skip_dequeue
    lw a0, 0(t0)        # Load queue address
    jal F_defiler       # Remove oldest position
    
skip_dequeue:
    # Draw at new position
    jal draw_snake
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Dessine le serpent en rouge sur l'ecran
draw_snake:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Get queue
    la t0, SNAKE_QUEUE
    lw a0, 0(t0)
    
    # Draw all segments
    lw a2, COLOR_RED
    jal F_lister        # F_lister will plot all segments
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Efface le serpent de l'ecran en le coloriant en noir
clear_snake:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    # Get queue
    la t0, SNAKE_QUEUE
    lw s0, 0(t0)
    
    # Save current color
    mv s1, a2
    
    # Set color to black for clearing
    li a2, 0x00000000
    
    # Clear all segments
    mv a0, s0
    jal F_lister
    
    # Restore color
    mv a2, s1
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret


# Ajoute un delai pour contr?ler la vitesse du serpent
delay:
    la t1, DELAY
    lw t0, 0(t1)
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    ret

# Verifie si la tete du serpent va entrer en collision avec son corps
# Utilise F_contient pour verifier si la prochaine position est deja occupee par le corps
check_snake_collision:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    
    # Load current position
    la t0, CURRENT_X
    la t1, CURRENT_Y
    lw t2, 0(t0)       # t2 = current X
    lw t3, 0(t1)       # t3 = current Y
    
    # Calculate next position based on direction
    la t0, CURRENT_DIRECTION
    lb t1, 0(t0)       # t1 = current direction
    
    mv t4, t2          # t4 will be next X
    mv t5, t3          # t5 will be next Y
    
    # Update next position based on direction
    beqz t1, check_right      # if direction = 0 (right)
    li t0, 1
    beq t1, t0, check_down    # if direction = 1 (down)
    li t0, 2
    beq t1, t0, check_left    # if direction = 2 (left)
    j check_up                # if direction = 3 (up)
    
check_right:
    addi t4, t4, 1
    j check_collision
check_down:
    addi t5, t5, 1
    j check_collision
check_left:
    addi t4, t4, -1
    j check_collision
check_up:
    addi t5, t5, -1
    
check_collision:
    # Convert next position to display address
    mv a0, t4
    mv a1, t5
    jal I_coordToAdresse
    
    # Save next position address
    mv s0, a0
    
    
    # Check if this position exists in snake's body
    la t0, SNAKE_QUEUE
    lw a0, 0(t0)        # Load queue address
    mv a1, s0           # Load next position address
    jal F_contient
    
    # If position found in snake's body (a0 = 1), game over
    beqz a0, next_check

    # Print death message
    la a0, MSG_DEAD_SNAKE
    li a7, 4
    ecall
    
    # End game
    j game_over

next_check:

    # Check if this position exists in obsticales array 
    lw a0, BORDER_OBST_ARRAY_ADRESS        # Load queue address
    lw a1, TOTAL_NUM_OBS
    mv a2, s0 
    jal O_contient
    
    # If position found in obsticales array  game over
    beqz a0, no_collision

    
    # Print death message
    la a0, MSG_DEAD_SNAKE
    li a7, 4
    ecall
    
    # End game
    j game_over
    
no_collision:
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

           #-------------------------------------------------------------------------------#
                                    # Food Related Functions


# Gen?re une nouvelle position aleatoire pour la nourriture
spawn_food:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Generate random x coordinate
    li a0, 100     # Upper limit for randomness (can adjust for screen width)
    li a7, 42      # Random syscall
    ecall
    lw t1, IMAGE_WIDTH_IN_UNITS
    addi t1, t1, -2
    rem a0, a0, t1
    addi a0, a0, 1
    la t1, FOOD_X
    sw a0, (t1)

    # Generate random y coordinate
    li a0, 100     # Upper limit for randomness (adjust as needed)
    li a7, 42      # Random syscall
    ecall
    lw t1, IMAGE_HEIGHT_IN_UNITS
    addi t1, t1, -2
    rem a0, a0, t1
    addi a0, a0, 1
    la t1, FOOD_Y
    sw a0, (t1)

    # Draw the food in green color
    jal draw_food

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


# Dessine la nourriture en vert sur l'ecran
draw_food:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Load food position
    la t0, FOOD_X
    la t1, FOOD_Y
    lw a0, 0(t0)
    lw a1, 0(t1)
    
    # Get the display address for the food position
    jal I_coordToAdresse
    mv a0, a0
    
    # Use green color
    la t2, FOOD_COLOR
    lw a2, 0(t2)
    jal I_plot

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Verifie si le serpent entre en collision avec la nourriture
check_food_collision:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)

    # Load snake's head coordinates
    la t0, CURRENT_X
    la t1, CURRENT_Y
    lw t2, 0(t0)       # t2 = snake head X
    lw t3, 0(t1)       # t3 = snake head Y

    # Load food coordinates
    la t4, FOOD_X
    la t5, FOOD_Y
    lw s2, 0(t4)       # s2 = food X
    lw s3, 0(t5)       # s3 = food Y

    # Check for collision
    bne t2, s2, no_food_collision
    bne t3, s3, no_food_collision
    
    
    la t0, SNAKE_CURRENT_LENGTH
    lw t1, 0(t0)

    # Collision detected: Increase snake length
    addi t1, t1, 1     # Increase length by 1


    # Check for snake length
    la t2, SNAKE_MAX_LENGTH
    lw t3, 0(t2)

    beq t1, t3, game_won

    sw t1, 0(t0)       # Save new length
    lw t1 DELAY
    addi t1, t1, -1000
    la t0, DELAY
    sw t1, (t0)

    la a0, MSG_FOOD_EATEN
    li a7, 4
    ecall
    jal spawn_food     # Spawn new food

no_food_collision:
    lw ra, 0(sp)
    lw s2, 4(sp)
    lw s3, 8(sp)
    addi sp, sp, 12
    ret
    


# Calcule la largeur du terrain de jeu en unites  
I_largeur:
    la t0, UNITS_WIDTH
    lw t1, 0(t0)
    la t2, IMAGE_WIDTH
    lw t3, 0(t2)
    div t4, t3, t1
    la t5, IMAGE_WIDTH_IN_UNITS
    sw t4, 0(t5)
    ret

# Calcule la hauteur du terrain de jeu en unites
I_hauteur:
    la t0, UNITS_HEIGHT
    lw t1, 0(t0)
    la t2, IMAGE_HEIGHT
    lw t3, 0(t2)
    div t4, t3, t1
    la t5, IMAGE_HEIGHT_IN_UNITS
    sw t4, 0(t5)
    ret


# Convertit des coordonnees (x,y) en adresse memoire pour l'affichage
# Arguments : a0 = x, a1 = y
# Retour : a0 = adresse memoire
I_coordToAdresse:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Get width in units
    lw t0, IMAGE_WIDTH_IN_UNITS
    
    # Calculate offset: y * width + x
    mul t2, a1, t0     # y * width
    add t2, t2, a0     # + x
    
    # Ensure alignment by multiplying by 4 (word size)
    slli t2, t2, 2     # Multiply by 4 for word alignment
    
    # Add base display address
    lw t3, DISPLAY_ADDRESS
    add a0, t3, t2
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


# Dessine un pixel a l'adresse specifiee avec la couleur donnee
# Arguments : a0 = adresse memoire, a2 = couleur 
I_plot:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s1, a2          # Save color
    mv s0, a0         
    
    sw s1, 0(s0)       # Store color at address
    
plot_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret


# Ajoute la position de la nourriture a la queue du serpent
# Utilise quand le serpent mange la nourriture
F_enfiler_food:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Calculate food display address
    la t0, FOOD_X
    la t1, FOOD_Y
    lw a0, 0(t0)
    lw a1, 0(t1)
    jal I_coordToAdresse
    
    # Enqueue the food address
    jal F_enfiler

    lw ra, 0(sp)
    addi sp, sp, 4
    ret
    

    
    
# Cree une nouvelle file vide pour stocker les segments du serpent
# Retour : a0 = adresse de la structure de la file
F_creer:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Allouer l'espace pour la structure (12 octets)
    li a0, 12
    li a7, 9
    ecall
    
    # Sauvegarder l'adresse de la structure
    mv t0, a0
    
    # Allouer le tableau pour les pixels
    li a0, 30  # Taille maximale (peut etre ajustee)
    slli a0, a0, 2
    li a7, 9
    ecall
    
    # Initialiser la structure
    sw a0, 0(t0)   # adresse du tableau
    li t1, 120
    sw t1, 4(t0)   # taille maximale
    sw zero, 8(t0)  # nombre d'elements = 0
    
    # Retourner l'adresse de la structure
    mv a0, t0
    
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Ajoute un element ? la fin de la file
# Arguments : a0 = adresse de la file, a1 = element ? ajouter
F_enfiler:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s0, a0    # s0 = adresse de la file
    mv s1, a1    # s1 = pixel e ajouter
    
    # Verifier si la file est pleine
    lw t0, 8(s0)  # nombre d'elements
    lw t1, 4(s0)  # taille maximale
    beq t0, t1, fifo_full
    
    # Calculer l'adresse oe ajouter le pixel
    lw t1, 0(s0)   # adresse du tableau
    slli t2, t0, 2  # t2 = nombre_elements * 4
    add t2, t2, t1  # adresse oe stocker le pixel
    sw s1, 0(t2)    # stocker le pixel
    
    # Incrementer le nombre d'elements
    addi t0, t0, 1
    sw t0, 8(s0)
    
    j enfiler_fin
    
fifo_full:
    # Afficher message d'erreur
    la a0, MSG_FULL
    li a7, 4
    ecall
    
enfiler_fin:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret


# Retire le premier element de la file
# Arguments : a0 = adresse de la file
F_defiler:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s0, a0
    
    # Verifier si la file est vide
    lw t0, 8(s0)  # nombre d'elements
    beqz t0, fifo_empty
    
    # Decaler tous les elements vers la gauche (O(n))
    lw t1, 0(s0)   # adresse du tableau
    li t2, 0       # index de boucle
    
defiler_loop:
    addi t3, t0, -1     # nombre d'elements - 1
    beq t2, t3, defiler_end_loop
    
    # Decaler l'element
    slli t4, t2, 2      # t4 = index * 4
    add t4, t4, t1      # adresse de l'element actuel
    lw t5, 4(t4)        # charger l'element suivant
    sw t5, 0(t4)        # sauvegarder dans la position actuelle
    
    addi t2, t2, 1      # incrementer l'index
    j defiler_loop
    
defiler_end_loop:
    # Decrementer le nombre d'elements
    addi t0, t0, -1
    sw t0, 8(s0)
    
    j defiler_fin
    
fifo_empty:
    # Afficher message d'erreur
    la a0, MSG_EMPTY
    li a7, 4
    ecall
    
defiler_fin:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret


# Retourne la valeur a l'index specifie dans la file
# Arguments : a0 = adresse de la file, a1 = index
# Retour : a0 = valeur a l'index demande
F_valeurIndice:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    
    mv s0, a0
    
    # Verifier si l'index est valide
    lw t0, 8(s0)  # nombre d'elements
    bge a1, t0, index_invalid
    bltz a1, index_invalid
    
    # Recuperer la valeur
    lw t1, 0(s0)   # adresse du tableau
    slli t2, a1, 2 # index * 4
    add t2, t2, t1
    lw a0, 0(t2)
    
    j valeurIndice_fin
    
index_invalid:
    li a0, -1
    
valeurIndice_fin:
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

# Arguments:
#   a0 = adresse de la file
#   a1 = pixel a rechercher
# Retour: a0 = 1 si trouve, 0 sinon
F_contient:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    
    mv s0, a0    # s0 = adresse de la file
    mv s1, a1    # s1 = pixel a rechercher
    
    # Parcourir le tableau
    lw t0, 8(s0)     # nombre d'elements
    lw t1, 0(s0)     # adresse du tableau
    li t2, 0         # index
    
contient_loop:
    beq t2, t0, contient_not_found
    
    slli t3, t2, 2  
    add t3, t3, t1
    lw t4, 0(t3)
    beq t4, s1, contient_found
    
    addi t2, t2, 1
    j contient_loop
    
contient_found:
    li a0, 1
    j contient_fin
    
contient_not_found:
    li a0, 0
    
contient_fin:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    addi sp, sp, 16
    ret

# Parcourt et affiche tous les elements de la file
# Arguments : a0 = adresse de la file
F_lister:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s0, a0
    
    # Parcourir et afficher tous les elements
    lw t0, 8(s0)     # nombre d'elements
    lw t1, 0(s0)     # adresse du tableau
    li t2, 0         # index
    
lister_loop:
    beq t2, t0, lister_fin
    
    
    slli t3, t2, 2  
    add t3, t3, t1
    lw a0, 0(t3)
    jal I_plot      # Afficher l'element
    
    addi t2, t2, 1
    j lister_loop
    
lister_fin:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret
    
