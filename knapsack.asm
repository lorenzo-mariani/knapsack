.data

arr_weights:        .space 1024
arr_values:         .space 1024
arr_tmp_values:     .space 1024
arr_tmp_positions:  .space 1024

msg_backpack:       .asciiz "Enter the weight the backpack can bear: "
msg_items:          .asciiz "\nItem "
msg_weights:        .asciiz "\nEnter the weight of the item (enter 0 to exit): "
msg_values:         .asciiz "Enter the value of the item: "

res_items:          .asciiz "\nItems brought: "
res_weights:        .asciiz "\nTotal weight: "
res_values:         .asciiz "\nTotal value: "
res_empty:          .asciiz "no item"

err_backpack:       .asciiz "Error! The entered value must be greater than 0\n"
err_weights:        .asciiz "Error! The weight must be 0 (to exit) or a positive number"
err_values:         .asciiz "Error! The value must be between 1 and 10!\n"

space:              .asciiz " "

.text

# initialize the registers to prepare to start requesting data from the user
init_to_start:
    la $s2, arr_weights
    la $s3, arr_values
    la $s4, arr_tmp_values
    la $s5, arr_tmp_positions
    move $t2, $s2
    move $t3, $s3
    move $t4, $s4
    move $t5, $s5

# ask the user for the capacity of the backpack
set_backpack:
    li $v0, 4
    la $a0, msg_backpack
    syscall
    li $v0, 5
    syscall
    blez $v0, print_err_backpack
    move $s0, $v0
    move $t0, $s0
    move $t1, $zero

# print the number of the item whose weight and value must then be specified
get_item:		
    addiu $t1, $t1, 1
    li $v0, 4
    la $a0, msg_items
    syscall
    li $v0, 1
    move $a0, $t1
    syscall

# ask the user for the weight of the item
set_weight:
    li $v0, 4
    la $a0, msg_weights
    syscall
    li $v0, 5
    syscall
    beqz $v0, fix_counter
    bltz $v0, print_err_weights
    sw $v0, 0($t2)
    addiu $t2, $t2, 4

# ask the user for the value of the item
set_value:
    li $v0, 4
    la $a0, msg_values
    syscall
    li $v0, 5
    syscall
    blez $v0, print_err_values
    bgtu $v0, 10, print_err_values
    sw $v0, 0($t3)
    sw $v0, 0($t4)
    addiu $t3, $t3, 4
    addiu $t4, $t4, 4
    j get_item

# when here, the item counter indicates one unit more than the number
# of items actually inserted (this is because the last "item" was
# used to finish the inputs). As a result, you adjust the counter to
# the correct value
fix_counter:
    subu $t1, $t1, 1
    move $s1, $t1
    beqz $s1, init_to_print
    subu $t1, $t1, 1
    mul $t1, $t1, 4
    move $s6, $t1
    move $t9, $zero

# initialize the registers to start the main program
init_to_main:	
    move $t1, $zero
    move $t2, $zero
    move $t3, $zero
    move $t6, $zero
    move $t4, $s4
    move $t7, $zero
    move $t8, $zero
    lw $t2, 0($t4)
    addu $t8, $t8, $t2

# search the item having the max value. If an item having value = 10
# (i.e., the maximum possible) is found, then go directly to "evaluate",
# otherwise go to "evaluate" once all the items have been evaluated
# (i.e., $t7 = 0)
search_max_value:	
    beq $t2, 10, check_weight
    sltu $t7, $t6, $s6
    beqz $t7, check_weight
    addiu $t4, $t4, 4
    addiu $t6, $t6, 4
    lw $t1, 0($t4)
    addu $t8, $t8, $t1
    bgtu $t1, $t2, update_max
    j search_max_value

# evaluate if the weight associated with the item having the max value
# is less than the remaining capacity of the backpack (i.e., evaluate if
# the item can fit in the backpack)
check_weight:		
    beqz $t8, init_sort
    move $t7, $zero
    addu $t7, $s2, $t3
    lw $t1, 0($t7)
    bgtu $t1, $t0, reset
    sw $t3, 0($t5)
    addiu $t5, $t5, 4
    addiu $t9, $t9, 1
    subu $t0, $t0, $t1
    beqz $t0, init_sort

# set the value of the item just considered to 0
reset:		
    addu $t4, $s4, $t3
    sw $zero, 0($t4)
    j init_to_main

# initialize the registers to start sorting the items
init_sort:
    move $s7, $t0
    move $t0, $zero
    move $t1, $zero
    move $t2, $zero

# start sorting the items in the backpack, so that the final print is
# ordered (e.g., if in the backpack I have items 3-1-2-5-4 (inserted
# in this order because of their values), then I reorder the items in
# such a way as to have 1-2-3-4-5)
start_sort:
    beq $t2, $t9, init_to_print
    move $t3, $t2
    move $t4, $t2
    mul $t2, $t2, 4
    addu $t5, $s5, $t2
    lw $t0, 0($t5)

# search the item with the min id
search_min_item_id:
    addiu $t4, $t4, 1
    beq $t4, $t9, save_sort
    addiu $t5, $t5, 4
    lw $t1, 0($t5)
    bltu $t1, $t0, update_min
    j search_min_item_id

# save the sorted result
save_sort:
    beq $t2, $t3, update_cycle
    addu $t5, $s5, $t2
    lw $t6, 0($t5)
    sw $t0, 0($t5)
    mul $t3, $t3, 4	
    addu $t5, $s5, $t3
    sw $t6, 0($t5)

# update the cycle
update_cycle:
    div $t2, $t2, 4
    addiu $t2, $t2, 1
    j start_sort

# update the min value
update_min:	
    move $t0, $t1
    move $t3, $t4
    j search_min_item_id

# initialize the registers to prepare for printing the results
init_to_print:	
    move $t0, $zero
    move $t1, $zero
    move $t4, $zero
    move $t5, $s5
    move $t6, $zero
    move $t7, $zero
    li $v0, 4
    la $a0, res_items
    syscall
    beqz $t9, print_empty

# print of the items in the backpack
print_item:	
    beq $t6, $t9, print_weight_value
    move $t2, $s2
    move $t3, $s3
    lw $t4, 0($t5)
    addu $t2, $t2, $t4
    lw $t7, 0($t2)
    addu $t0, $t0, $t7
    addu $t3, $t3, $t4
    lw $t7, 0($t3)
    addu $t1, $t1, $t7
    addiu $t4, $t4, 4
    addiu $t5, $t5, 4
    addiu $t6, $t6, 1
    li $v0, 1
    move $a0, $t4
    divu $a0, $a0, 4
    syscall
    li $v0, 4
    la $a0, space
    syscall
    j print_item

# if there are no items in the backpack, print that the backpack is empty
print_empty:
    li $v0, 4
    la $a0, res_empty
    syscall

# print the weights and values of the items in the backpack
print_weight_value:
    li $v0, 4
    la $a0, res_weights
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, res_values
    syscall
    li $v0, 1
    move $a0, $t1
    syscall

# exit the program
exit:
    j exit

# print an error message when an invalid backpack capacity is entered
print_err_backpack:	
    li $v0, 4
    la $a0, err_backpack
    syscall
    j set_backpack

# print an error message when an invalid item value is entered
print_err_weights:
    li $v0, 4
    la $a0, err_weights
    syscall
    j set_weight

# print an error message when an invalid item value is entered
print_err_values:
    li $v0, 4
    la $a0, err_values
    syscall
    j set_value

# update the max value
update_max:	
    move $t2, $t1
    move $t3, $t6
    j search_max_value