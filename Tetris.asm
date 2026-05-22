#####################################################################
#
# Tetris - MIPS32
#
# Autores:
# - Anatoli Nichei
# 
# Bitmap Display:
# - Unit width in pixels: 16
# - Unit height in pixels: 16 
# - Display width in pixels: 256 
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
#####################################################################

.data
	displayAddress:	.word	0x10008000	# Dirección de memoria de la primera casilla de la matriz de la pantalla
	
	tPiece:		.word 	4, 0, 8, 68	# Las piezas con las diferencias de espacio entre ellas	
	cubePiece:	.word 	4, 0, 64, 68
	iPiece:		.word	4, 0, 8, 12 
	zPiece:		.word 	4, 0, 68, 72
	ziPiece:	.word 	4, 8, 64, 68
	lPiece:		.word	4, 0, 8, 64
	liPiece:	.word	4, 0, 8, 72
	
	piecePos1:	.space 4		# variables para almacenar temporalmente posiciones de las piecas
	piecePos2:	.space 4
	piecePos3:	.space 4
	piecePos4:	.space 4
	
	colorRed:	.word 0xee0000		# Variables declaradas como colores que se usan a lo largo del juego
	colorGreen:	.word 0x00ee00
	colorBlue:	.word 0x0000ee
	colorPurple:	.word 0xee00ee
	colorOrange:	.word 0xeeee00
	colorCyan:	.word 0x00eeee
	colorEmpty:	.word 0x999999
	colorActive: 	.word 0x0000ff
	colorBorder:	.word 0x333333
	colorMenuBg:	.word 0x0341ae
	collisionActive: .word 0		# Variable booleana para comprobar la colisión lateral de la pieza
	endGame: 	.word 0			# Variable booleana para comprobar si se ha acabado el juego
	
	finalScoreLabel: .asciiz "Your final score is: "	# Label para mostrar la puntuación final
	
	gamePoints: 	.word 0			# Variable que almacena la puntuación final del juego
.text 
	lw $t0, displayAddress			# Se establece la primera direccion del bitmap
	
	li $s5, 0				# Se establece el contador de iteraciones a 0
	li $s6, 5				# Se establece la velocidad del juego a 5
	
	
	jal drawMenu				# Se salta a la función de dibujar el menú
	
menuloop:	# Se comienza el loop principal
	
	lw	$t9,0xFFFF0000			# Se comprueba si se ha pulsado algo
	beqz 	$t9, menuloop 			# Si no se ha pulsado se salta la comproboación reiniciando el bucle
	lw	$t9,0xFFFF0004 			# Devuelve el valor presionado
	bne	$t9,32,spaceBarNotPressed	# Si el valor coincide con el código ASCII del espacio se finaliza el loop del menú 
		j endMenuLoop			# Se finaliza el loop del menú
	spaceBarNotPressed:			# De lo contrario
	
	j menuloop				# Se reitera el bucle del menú

endMenuLoop:

	jal drawFirstBg				# Se colorea el fondo del juego
	jal drawLayout				# Se colorean los bordes del juego
	jal getRandomPiece			# Se genera una pieza random
	jal getRandomColor			# Se genera y asocia un color a la pieza
	
gameloop:					# Se Inicializa el bucle de juego
	
	# Update
	
	div $t1, $s5, $s6			# Se divide el valor de iteración entre la velocidad del juego para obtener su resto
	mfhi $t1				# Se obtiene el resto
	bnez $t1, dontUpdatePiece		# Si la iteración es del multiplo de la velocidad se desplaza la pieza hacia abajo
		jal updatePiece			# Se actualiza la pieza
		li $s5, 0			# Se reinicia el contador de iteraciones
		jal draw			# Se dibuja la nueva posición de la pieza
	dontUpdatePiece:			
	
	
	
	# Manejo de Input
	lw	$t9,0xFFFF0000 			# Se comprueba si se ha pulsado algo
	beqz 	$t9, movePieceDownNotPressed 	# Si no se ha pulsado se salta la comproboación de input
	lw	$t9,0xFFFF0004 			# Devuelve el valor presionado y se comprueba si el valor coincide con el ASCII de alguna de las flechas
	bne	$t9,97,movePieceLeftNotPressed 	# Se ha presionado izquierda
		jal movePieceLeft		# Se desplaza la pieza a la izquierda
		jal draw			# Se pinta la nueva posición 
		jal playMoveSound		# Se reproduce el sonido de movimiento
	movePieceLeftNotPressed:		# Así sucesivamente con todas las flechas restantes
	bne	$t9,100,movePieceRightNotPressed
		jal movePieceRight
		jal draw
		jal playMoveSound
	movePieceRightNotPressed:
	bne	$t9,101,rotatePieceRightNotPressed
		jal rotatePieceLeft
		jal draw
		jal playMoveSound
	rotatePieceRightNotPressed:
	bne	$t9,115,movePieceDownNotPressed
		jal movePieceDown
		jal draw
		jal playMoveSound
	movePieceDownNotPressed:
	
	
	# Draw
	jal drawPiece				# Se repinta la pieza en caso de que en ninguna de las condiciones se haya pintado
	
	# Sleep
	li $v0, 32				# Se duerme el proceso para que la tasa de actualizaciones no sea impercibible
	li $a0, 100				# Se establece en $a0 la cantidad a dormir en milisegundos
	syscall
	
	
	jal checkCollision			# Se comprueba la colison con otra pieza
	lw $t2, collisionActive			# Se guarda en $t2 el booleano de la colision
	beqz $t2, dontSpawnNewPiece		# Se comprueba si la pieza va ha colisionar y de ser así se genera otra pieza
		jal checkLines			# Se comprueba si se ha realizado una linea para sumar puntos y restarla
		jal draw			# Se repinta todo 
		jal getRandomPiece		# Se genera una pieza aleatoria nueva
		jal getRandomColor		# Se asocia un color activo nuevo
		li $t2, 0			# Se guarda 0 en $t2
		sw $t2, collisionActive		# Para reestablecer el booleano collisionActive a falso de nuevo
	dontSpawnNewPiece:
	
	lw $t2, endGame				# Se almacena en $t2 el valor del booleano de game over
	beqz $t2, dontEndGameloop		# Se comprueba si el juego tiene que finalizar
		
		j Exit				# Se finaliza el juego
	dontEndGameloop:
	
	addi $s5, $s5, 1			# Se suma una unidad al contador de iteraciones
	
	j gameloop				# Se reinicia el bucle del gameloop
	
Exit:
	addiu $t6, $t0, -4 
	addi $t5,$t0, 2048	#2044
	lw $t7, colorMenuBg
	whileEndBackground: 
	addi $t6,  $t6, 4
    	ble $t5, $t6, endDrawEndBg
    		sw $t7,0($t6)
   		j whileEndBackground
	endDrawEndBg:
		     
   	li  $v0, 56          # service 1 is print integer
   	lw $a1, gamePoints  # load desired value into argument register $a0, using pseudo-op
    	la $a0, finalScoreLabel  # load desired value into argument register $a0, using pseudo-op	
	syscall
    			
	li $v0,10
	syscall

playMoveSound:
	li $v0, 31
	li $a0, 75
	li $a1, 1000  
	li $a2,	45
	li $a3, 100
	syscall
	jr $ra
	
drawMenu:
	addiu $t6, $t0, -4 			# Se guarda en $t6 la primera dirección del bitmap
	addi $t5,$t0, 2048			# Y en $t5 la última dirección del bitmap
	lw $t7, colorMenuBg			# Se establece en $t7 el color con el que se quiera pintar el fondo
	whileMenuBackground: 			# Se itera desde la primera hasta la última dirección del bitmap
		addi $t6,  $t6, 4		# Se añaden 4 a la dirección para pintar el siguiente 
    		ble $t5, $t6, endDrawMenuBg	# Se comprueba si se ha alcanzado la última dirección de memoria

    		sw $t7,0($t6)			# Se pinta la dirección con el color previamente establecido
    		
   		j whileMenuBackground		# Se reitera el bucle
	endDrawMenuBg:				# Al alcanzar la última dirección de memoria
	
	addiu $t6, $t0, -4 			# Se guarda en $t6 la primera dirección del bitmap
	# Dibujamos las piezas como letras:
	lw $t7, colorRed			# Se almacena el color a utilizar
	sw $t7, 224($t6)			# Se colorea en la dirección deseada
	sw $t7, 228($t6)
	sw $t7, 232($t6)
	sw $t7, 292($t6)
	
	lw $t7, colorOrange			# Se repite el proceso con cada pieza
	sw $t7, 488($t6)
	sw $t7, 492($t6)
	sw $t7, 548($t6)
	sw $t7, 552($t6)
	sw $t7, 616($t6)
	sw $t7, 620($t6)
	
	lw $t7, colorRed
	sw $t7, 792($t6)
	sw $t7, 796($t6)
	sw $t7, 800($t6)
	sw $t7, 860($t6)
	
	lw $t7, colorCyan
	sw $t7, 1056($t6)
	sw $t7, 1060($t6)
	sw $t7, 1064($t6)
	sw $t7, 1120($t6)
	
	lw $t7, colorGreen
	sw $t7, 1324($t6)
	sw $t7, 1388($t6)
	sw $t7, 1452($t6)
	sw $t7, 1516($t6)
		
	lw $t7, colorPurple
	sw $t7, 1700($t6)
	sw $t7, 1704($t6)
	sw $t7, 1760($t6)
	sw $t7, 1764($t6)
		
	jr $ra					# Se finaliza la subrutina y se vuelve al hilo principal

drawFirstBg:
	addiu $t6, $t0, -4 			# Se guarda en $t6 la primera dirección del bitmap
	addi $t5,$t0, 1984	#2044		# Y en $t5 la última dirección de la penúltima fila del bitmap
	lw $t7, colorEmpty			# Se establece el color del fondo
	whileFirstBackground: 			# Se itera hasta colorear todo como en "whileMenuBackground"
		addi $t6,  $t6, 4
    		ble $t5, $t6, endDrawFirstBg

    		sw $t7,0($t6)
    		
   		j whileFirstBackground
	endDrawFirstBg:
		jr $ra				# Al finalizar se vuelve de la subrutina


		
draw:
	addiu $t6, $t0, -4 
	addi $t5,$t0, 1984	#2044
	lw $t7, colorEmpty
	lw $t9, colorActive
	whileBackground: 
		addi $t6,  $t6, 4
    		ble $t5, $t6, endDraw

		lw $t4, 0($t6)
		
		seq $t1, $t4, $t7		# comprobar si es fondo vacio
		seq $t2, $t4, $t9  		# comprobar si es pieza activa
		seq $t3, $t4, $zero
		
		or $t8, $t1, $t2
		or $t8, $t8, $t3
		
		beq $t8, 1, reprintSquare
			j whileBackground
		reprintSquare:
    			sw $t7,0($t6)
    		
   		j whileBackground
	endDraw:
		jr $ra
		
drawLayout:
	addiu $t6, $t0, -4 			# Se guarda en $t6 la primera dirección del bitmap
	addi $t5,$t0, 1984			# Y en $t5 la última dirección de la penúltima fila del bitmap
	lw $t9, colorBorder			# Se establece el color del borde

	whileLateralBorders: 			# Se itera hasta llegar a la última dirección del bitmap
		
		addi $t6,  $t6, 4		# Se suman 4
		sub $t1, $t6, $t0		# Se restan las direcciónes para obtener la diferencia entre pos actual y incial
		div $t2, $t1, 64		# Se divide la diferencia entre 64 (el borde izquierdo) y sí el resto es 0
		mfhi $t3			# supone que es módulo de 64 y se pinta el borde izquierdo y derecho
		bnez $t3, whileLateralBorders	# Si el resto no es 0, se sigue sumando
		
    		ble $t5, $t6, endDrawLateralBorders	# Si se alcanza el final se salta a pintar el borde inferior
	
    		sw $t9,0($t6)			# Se pinta el borde izquierdo
    		sw $t9,60($t6)			# Se pinta el borde derecho (el izquierdo desplazado 60 bytes)
    		
   		j whileLateralBorders		# Se repite el bucle
	endDrawLateralBorders:			# Al alcanzar el final:
	addi $t5,$t0, 2048			# Se guarda en $t5 la última dirección del bitmap
	addi $t6,  $t6, -4			# Se le resta 4 a $t6 para apuntar a la primera dirección de la última fila del bitmap
	whileBottomBorder: 			# Se itera hasta pintar el borde inferior
		addi $t6,  $t6, 4
    		ble $t5, $t6, endDrawBottomBorder

    			sw $t9,0($t6)
    		
   		j whileBottomBorder
	endDrawBottomBorder:	
		jr $ra				# Se acaba la subrutina y regresa

updatePiece:
	addi $s1, $s1, 64
	addi $s2, $s2, 64
	addi $s3, $s3, 64
	addi $s4, $s4, 64
	
	#jal checkCollision
	
	jr $ra


#################################################################################################################################
#																#
#	Para mover la pieza lo primero que se realiza es comprobar la posibilidad de moverlo a dicha dirección 			#
#	Para ello, se realiza una comprobación en los 4 puntos de la pieza $s1, $s2, $s3, $s4.					#
#	Se desplazan la cantidad necesaria y se comprueba si el lado al que se pretende mover esta vacio o es la misma pieza	#
# 	De ser así se posibilita el movimiento, por lo contrario la pieza se queda en su sitio sin poder moverse		#
#																#
#################################################################################################################################
	
movePieceLeft:

	lw $t2, colorEmpty			# Se almacena en el registro $t2 el color del fondo
	lw $t9, colorActive			# Se almacena en el registro $t3 el color activo de la pieza
		
	lw $t3, -4($s1)				# Se desplaza la pieza 4 bytes (1 bit del mapa) a la izquierda
	seq $t4, $t3, $t2			# Se comprueba que el valor de $t3 es igual al del color del fondo y se almacena en $t4 si es así
	seq $t5, $t3, $t9  			# Se comprueba que el valor de $t3 es igual al del color activo y se almacena en $t5 si es así

	or $t6, $t5, $t4			# Si alguno de los dos se comprueba $t6 será true o 1 y no habrá detectado colisión
	beqz $t6, collisionLeftDetected		# Si se ha detectado colisión por que $t6 = 0, se salta a collisionLeftDetected
	
	lw $t3, -4($s2)				# Se repite la secuencia con cada bloque de la pieza correspondiente
	seq $t4, $t3, $t2
	
	lw $t3, -4($s2)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionLeftDetected
	
	lw $t3, -4($s3)
	seq $t4, $t3, $t2
	
	lw $t3, -4($s3)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionLeftDetected
	
	lw $t3, -4($s4)
	seq $t4, $t3, $t2
	
	lw $t3, -4($s4)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionLeftDetected
	
	
	subi $s1, $s1, 4			# Si no se ha detectado colisión con ningún bloque se desplazan todos una unidad a la izquierda
	subi $s2, $s2, 4
	subi $s3, $s3, 4
	subi $s4, $s4, 4
	
	collisionLeftDetected:
	jr $ra					# Se regresa al gameloop
	
	
movePieceDown:				# Se repite el mismo proceso 

	lw $t2, colorEmpty
	lw $t9, colorActive
	
	lw $t3, 64($s1)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s1)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDownDetected
	
	lw $t3, 64($s2)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s2)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDownDetected
	
	lw $t3, 64($s3)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s3)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDownDetected
	
	lw $t3, 64($s4)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s4)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDownDetected
	
	addi $s1, $s1, 64
	addi $s2, $s2, 64
	addi $s3, $s3, 64
	addi $s4, $s4, 64
	
	collisionDownDetected:
	
	jr $ra

movePieceRight:

	lw $t2, colorEmpty
	lw $t9, colorActive
	
	lw $t3, 4($s1)
	seq $t4, $t3, $t2
	
	lw $t3, 4($s1)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionRightDetected
	
	lw $t3, 4($s2)
	seq $t4, $t3, $t2
	
	lw $t3, 4($s2)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionRightDetected
	
	lw $t3, 4($s3)
	seq $t4, $t3, $t2
	
	lw $t3, 4($s3)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionRightDetected
	
	lw $t3, 4($s4)
	seq $t4, $t3, $t2
	
	lw $t3, 4($s4)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionRightDetected
	
	addi $s1, $s1, 4
	addi $s2, $s2, 4
	addi $s3, $s3, 4
	addi $s4, $s4, 4
	
	collisionRightDetected:
	
	jr $ra
	

rotatePieceLeft:
	
	la $t1, 0($s1)
	sw $t1, piecePos1
	la $t1, 0($s2)
	sw $t1, piecePos2
	la $t1, 0($s3)
	sw $t1, piecePos3
	la $t1, 0($s4)
	sw $t1, piecePos4
	
	la $t1, 0($s1) 	# posicion 0 de rotacion
	li $t5, 0
	la $t3, 0($s2)	# posicion a comparar
	lw $t9, colorBorder
	
	forRotationSquare: 
	bge $t5, 3, endRotation
	
	sub $t2, $t1, $t3

	bne $t2, 4, nextRot1
		subiu $t3, $t3, 60
	nextRot1:
	
	bne $t2, 8, nextRot2
		subiu $t3, $t3, 120
	nextRot2:
	
	bne $t2, 68, nextRot3
		subiu $t3, $t3, -8
	nextRot3:
	
	bne $t2, 64, nextRot4
		subiu $t3, $t3, -68
	nextRot4:
	
	bne $t2, 128, nextRot5
		subiu $t3, $t3, -136
	nextRot5:
	
	bne $t2, 60, nextRot6
		subiu $t3, $t3, -128
	nextRot6:
	
	bne $t2, -4, nextRot7
		subiu $t3, $t3, -60
	nextRot7:
	
	bne $t2, -8, nextRot8
		subiu $t3, $t3, -120
	nextRot8:
	
	bne $t2, -60, nextRot9
		subiu $t3, $t3, 128
	nextRot9:
	
	bne $t2, -64, nextRot10
		subiu $t3, $t3, 68
	nextRot10:
	
	bne $t2, -68, nextRot11
		subiu $t3, $t3, 8
	nextRot11:
	
	bne $t2, -128, nextRot12
		subiu $t3, $t3, 136
	nextRot12:
	

	lw $t4, 0($t3)
	beq $t4, $t9, collisionDetectedOnRotation
	
	bne $t5, 0, switchIf1
		la $s2, 0($t3)
		la $t3, 0($s3)	# posicion a comparar
	switchIf1:
	bne $t5, 1, switchIf2
		la $s3, 0($t3)
		la $t3, 0($s4)	# posicion a comparar
	switchIf2:
	bne $t5, 2, switchIf3
		la $s4, 0($t3)	# posicion a comparar
	switchIf3:
	
	addi $t5, $t5, 1
	
	j forRotationSquare
	
	collisionDetectedOnRotation:
		lw $s2, piecePos2
		lw $s3, piecePos3
		lw $s4, piecePos4
		j endRotation
	
	
	endRotation:
	jr $ra

checkCollision:
	lw $t2, colorEmpty
	lw $t9, colorActive
	
	lw $t3, 64($s1)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s1)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDetected
	
	lw $t3, 64($s2)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s2)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDetected
	
	lw $t3, 64($s3)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s3)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDetected
	
	lw $t3, 64($s4)
	seq $t4, $t3, $t2
	
	lw $t3, 64($s4)
	seq $t5, $t3, $t9  

	or $t6, $t5, $t4
	beqz $t6, collisionDetected

	j collisionNotDetected
	
	collisionDetected:
		lw $t2, colorActive
		addi $t2, $t2, 1
		sw $t2,0($s1)
		sw $t2,0($s2)
		sw $t2,0($s3)
		sw $t2,0($s4)
		
		lw $t1, 0($s0)
		add $t8, $t0, $t1
		addi $t8, $t8, 88
		
		bne $s1, $t8, dontEndGameActive
			lw $t9, endGame
			li $t9, 1
			sw $t9, endGame
		dontEndGameActive:
		
		lw $t9, collisionActive
		li $t9, 1
		sw $t9, collisionActive
	collisionNotDetected:
		
	
   	ble $t5, $t6, endDraw
	jr $ra

getRandomPiece:

	li  $v0, 42          		# Se llama al syscall 42 que devuelve un numero aleatorio entre 0
    	li $a1, 7  			# y el valor que se establece en $a1 (7 en este caso)
    	syscall	
      	
      	# li $a0, 2 # <-- si se descomenta esta linea solo saldrán piezas con forma de I (usado con razones de testeo)
    	
    	bne $a0, 0, nextPiece1		# Si el numero aleatorio es 0
    		la $s0, tPiece		# Se almacena en $s0 el array de la pieza a generar
    	nextPiece1:
    	
    	bne $a0, 1, nextPiece2		# Así con todas las posibilidades
    		la $s0, cubePiece
    	nextPiece2:
    	
    	bne $a0, 2, nextPiece3
    		la $s0, iPiece
    	nextPiece3:
    	
    	bne $a0, 3, nextPiece4
    		la $s0, zPiece
    	nextPiece4:
    	
    	bne $a0, 4, nextPiece5
    		la $s0, ziPiece
    	nextPiece5:
    	
    	bne $a0, 5, nextPiece6
    		la $s0, lPiece
    	nextPiece6:
    	
    	bne $a0, 6, nextPiece7
    		la $s0, liPiece
    	nextPiece7:
    	
    	addi $t0, $t0, 24		# Se establece el desplazamiento en el bitmap donde se generará la pieza
    	
	lw $t1, 0($s0)			# Se almacena en $t1 el primer valor del array de posiciones de la pieza
	add $s1, $t0, $t1		# Se almacena en $s1, el valor de generación en el bitmap + el desplazamiento de la pieza 
	lw $t2, 4($s0)			# Se almacena en $t2 el segundo valor y se repite el proceso con cada posición de la pieza
	add $s2, $t0, $t2
	lw $t3, 8($s0)
	add $s3, $t0, $t3
	lw $t4, 12($s0)
	add $s4, $t0, $t4

	subi $t0, $t0, 24		# Se reestablece el desplazamiento previamente agregado para que apunte al primer byte del bitmap
	
	jr $ra				# Termina la subrutina y regresa a la llamada

getRandomColor:

	li  $v0, 42          		# Se llama al syscall 42 que devuelve un numero aleatorio entre 0
    	li $a1, 6  			# y el valor que se establece en $a1 (6 en este caso)
    	syscall
      	
    	bne $a0, 0, nextColor1		# Si el numero aleatorio es 0
    		lw $s7, colorBlue	# Se almacena en $s7 el color de la pieza
    	nextColor1:
    	
    	bne $a0, 1, nextColor2		# Así con todas las posibilidades
    		lw $s7, colorGreen
    	nextColor2:
    	
    	bne $a0, 2, nextColor3
    		lw $s7, colorRed
    	nextColor3:
    	
    	bne $a0, 3, nextColor4
    		lw $s7, colorCyan
    	nextColor4:
    	
    	bne $a0, 4, nextColor5
    		lw $s7, colorOrange
    	nextColor5:
    	
    	bne $a0, 5, nextColor6
    		lw $s7, colorPurple
    	nextColor6:
	
	sw $s7, colorActive		# Se establece el color activo que ha salido en el randomizador
	
	jr $ra				# Se finaliza la subrutina y regresa a la llamada

checkLines:
	# While que va de abajo hacia arriba comprobando todas las lineas
	addiu $t6, $t0, 1980	# iterador de direcciones
	addi $t5,$t0, -4	# limite inferior máximo
	la $t7, 0($t6)		# limite de cada línea
	lw $t9, colorEmpty
	li $t2, 0
	whileLinesIterator: 
		la $t6, 0($t7)
		subi $t7, $t7, 64
		addi $t4, $t7, 64
		whileLineDirectionIterator:
			subi $t6,  $t6, 4
			lw $t8, 0($t6)
			
			beq $t8, $t9, whileLinesIterator
			bgt $t6, $t7, whileLineDirectionIterator
			ble $t6, $t5, endCheckLines
			
			la $t1, 0($t6)
			whileDropOneLine:
				lw $t8, 0($t1)	# guardamos el color
				addi $t3,  $t1, 64
				sw $t8, 0($t3)
				subi $t1, $t1, 4
				ble $t1, $t5, endDropOneLine
				ble $t1, $t4, whileDropOneLine
			endDropOneLine:
				
				addi $t2, $t2, 1
				li $v0, 31
				mul $a0, $t2, 1
				addi $a0, $a0, 64
				li $a1, 500 
				li $a2,	45
				li $a3, 100
				syscall
				
				li $v0, 32
				li $a0, 500
				syscall
				
				addi $t7, $t7, 64
				j whileLinesIterator
    	endCheckLines:	
   		lw $t1, gamePoints
   		li $t3, 1000
   		mul $t2, $t2, $t2
   		mul $t3, $t3, $t2
   		add $t1, $t1, $t3
   		sw $t1, gamePoints

		ble $t1, 5000, nextLevelOfSpeed1
			li $s6, 4
			ble $t1, 10000, nextLevelOfSpeed2
				li $s6, 3
				ble $t1, 15000, nextLevelOfSpeed3
					li $s6, 2
					ble $t1, 25000, nextLevelOfSpeed4
						li $s6, 1
					nextLevelOfSpeed4:
				nextLevelOfSpeed3:
			nextLevelOfSpeed2:
		nextLevelOfSpeed1:
		
   		
		jr $ra
	# If comprobando que no hay colores vacios
	# Si hay colores vacios, saltamos a la siguiente linea
	# Si no lo hay, eliminamos la fila y sumamos a todas las direcciones inferiores 64
	

drawPiece:

	lw $t2, colorActive
	sw $t2,0($s1)
	sw $t2,0($s2)
	sw $t2,0($s3)
	sw $t2,0($s4)
	
	jr $ra
    
     
       
