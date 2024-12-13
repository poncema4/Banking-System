section .data         
    correct_pass dd 0x34, 0x37, 0x36, 0x64, 0x67, 0x66, 26 dup(0)
    correct_otp dd 123456
    
    account_num dd 123456789
    account_holder db "Marco Ponce", 0
    account_type db "Savings", 0
    account_creation_date db "12-13-2024", 0
    
    account_bal dd 1500
 
    recipient_num dd 987654321
    recipient_bal dd 2000
 
    account_b_bal_stack dd 1500, 1800, 2000, 1700, 1400
    acnt_b_pointer dd 4
    
    transaction_stack db 5*5 dup(0) ;; 4 bytes for amount, 1 for type
    transaction_count dd -1
    
section .bss
    username resb 32
    password resb 32
    otp resb 4
    
    
    transaction_index resd 1        
    max_transaction equ 5       
    transaction_stack_size equ 25  
    
%include "io.inc"
 
section .text
    global main
 
;; Contract: -> void
;; Purpose: Present the user with the welcome message and
;; prompt them to select an option to log-in or exit
main:
    mov ebp, esp
    call display_welcome
    jmp user_option
    
;; Contract: -> void
;; Purpose: Displays the welcome screen and basic menu options
;; to the user
display_welcome:
    PRINT_STRING "Welcome screen"
    NEWLINE
    PRINT_STRING "-----------------------------------------"
    NEWLINE
    PRINT_STRING "Welcome to advanced banking system"
    NEWLINE
    PRINT_STRING "-----------------------------------------"
    NEWLINE
    PRINT_STRING "1. Login"
    NEWLINE
    PRINT_STRING "2. Exit"
    NEWLINE
    PRINT_STRING "Choose an option: "
    ret
 
;; Contract: int -> void
;; Purpose: Takes user input fro the menu option and jumps
;; to the option chosen
user_option:
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    cmp eax, 1
    je welcome_auth
    cmp eax, 2
    je welcome_exit
    jne wrong_input
 
;; Contract: -> void
;; Purpose: Handles user authentication, username, password, OTP
welcome_auth:
    PRINT_STRING " ~ User authentication ~ "
    NEWLINE
    call remove_newline
    PRINT_STRING "        Enter username: "
    GET_STRING username, 32
    PRINT_STRING username
    PRINT_STRING "        Enter encrypted password: "
    mov ecx, 0
    GET_HEX 4, eax
    PRINT_STRING "0x"
    PRINT_HEX 4, eax
    PRINT_STRING " "
    mov dword [password + ecx * 4], eax   
    inc ecx
    
;; Contract: -> void
;; Purpose: Loops the hexadecimal password input from the user
get_password_loop:
    xor eax, eax
    GET_CHAR al
    cmp al, byte 10
    je done_getting_password
    xor eax, eax
    GET_HEX 4, eax
    PRINT_STRING "0x"
    PRINT_HEX 4, eax
    PRINT_STRING " "
    mov dword [password + ecx * 4], eax
    inc ecx
    jmp get_password_loop
    
;; Contract: -> void
;; Purpose: Verifies the credentials of the user and determines if all are correct by calling
;; the helper functions, if it is, let them log-in, if not throw the error message for the
;; certain verification they failed
done_getting_password:
    NEWLINE
    PRINT_STRING "        Verifying credentials..."
    NEWLINE
    call compare_hex_array        
    cmp eax, 1              
    jne wrong_password
    PRINT_STRING "OTP verification: "
    PRINT_DEC 4, [correct_otp]
    NEWLINE
    PRINT_STRING "Enter OTP: "
    GET_DEC 4, [otp]
    PRINT_DEC 4, otp
    NEWLINE
    mov eax, [otp]
    mov ebx, [correct_otp]
    cmp eax, ebx
    jne otp_fail                
    PRINT_STRING "Login successful!"
    NEWLINE
    NEWLINE
    jmp display_option_menu
   
;; Contract: -> string
;; Purpose: Message if the user decides to exit and not even log-in
welcome_exit:
    PRINT_STRING "Bye have a good one! :)"
    jmp exit
 
;; Contract: -> string
;; Purpose: If the user did not input a valid option, (not 1 or 2)
wrong_input:
    PRINT_STRING "Please enter a valid option from the menu!"
    jmp exit
    
;; Contract: -> string
;; Purpose: If the hexidecimal password is incorrect and not the same as the stored value
wrong_password:
    PRINT_STRING "Incorrect password! Access denied."
    jmp exit
 
;; Contract: -> string
;; Purpose: If the OTP is incorrect, created for double verification, anti-bot
otp_fail:
    PRINT_STRING "Invalid OTP! Access denied."
    jmp exit
 
;; Contract: -> void
;; Purpose: Exits the program without anything else and provides a certain termination
exit:
    xor eax, eax
    ret
 
;; Contract: -> void
;; Purpose: Removes a newline, so the new value when someone calls a newline is removed internally
;; but it still remained visually for the user
remove_newline:
    GET_CHAR edx        
    cmp dl, 10          
    je done_removing    
    jmp remove_newline
 
;; Contract: -> void
;; Purpose: Done removing the newline and returns
done_removing:
    ret
 
;; Contract: -> void
;; Purpose: Initializes both the user's input and the correct_pass so they are able to
;; begin comparing each byte by byte for verification purposes
compare_hex_array:
    xor eax, eax
    xor ebx, ebx
    mov esi, password
    mov edi, correct_pass
 
;; Contract: -> void
;; Purpose: Compare hex loop which goes and compares double words
compare_hex_loop:
    cmpsd
    jne strings_not_equal
    loop compare_hex_loop
    jmp strings_are_equal
 
;; Contract: -> void
;; Purpose: Initializes and clears the registers of all the meaningful purposes
;; going to be used to compare strings
compare_strings:
    xor eax, eax   
    xor ebx, ebx
    xor ecx, ecx   
 
;; Contract: -> void
;; Purpose: Compare loop for strings which goes byte by byte checking if each one
;; is equal to each other   
compare_loop:
    mov al, [esi + ecx]     
    mov bl, [edi + ecx]    
    cmp bl, 0
    je strings_are_equal
    cmp al, bl              
    jne strings_not_equal   
    inc ecx                    
    jmp compare_loop  
 
;; Contract: -> void
;; Purpose: The eax register becomes 0, resulting in the strings not being equal       
strings_not_equal:
    xor eax, eax            
    ret
  
;; Contract: -> void
;; Purpose: The eax register becomes 1, resulting in the strings being equal
strings_are_equal:
    mov eax, 1              
    ret
 
;; Contract: -> void
;; Purpose: The dsplay menu of options inside the bank after all verifications have passed
;; and the user is allowed to choose out of this, making sure to logout at the end to avoid
;; having their account breached
display_option_menu:
    PRINT_STRING "Main menu:"
    NEWLINE
    PRINT_STRING "-------------------------------"
    NEWLINE
    PRINT_STRING "Banking system menu"
    NEWLINE
    PRINT_STRING "-------------------------------"
    NEWLINE
    PRINT_STRING "1. View account details"
    NEWLINE
    PRINT_STRING "2. Check balance"
    NEWLINE
    PRINT_STRING "3. Deposit funds"
    NEWLINE
    PRINT_STRING "4. Withdraw funds"
    NEWLINE
    PRINT_STRING "5. Transfer money"
    NEWLINE
    PRINT_STRING "6. View transaction history"
    NEWLINE
    PRINT_STRING "7. Balance history (Account B)"
    NEWLINE
    PRINT_STRING "8. Generate mini statement"
    NEWLINE
    PRINT_STRING "9. Change password"
    NEWLINE
    PRINT_STRING "10. Logout"
    NEWLINE
 
;; Contract: int -> void
;; Purpose: The menu option comparing the user's input from 1-10 to jump to their
;; deciding option inside their bank, making sure it is a valid option
menu_loop:
    PRINT_STRING "Choose an option: "
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    cmp eax, 1
    je view_account_details
    cmp eax, 2
    je check_balance
    cmp eax, 3
    je deposit_funds
    cmp eax, 4
    je withdraw_funds
    cmp eax, 5
    je transfer_money
    cmp eax, 6
    je transaction_history
    cmp eax, 7
    je balance_history
    cmp eax, 8
    je mini_statement
    cmp eax, 9
    je change_password
    cmp eax, 10
    je logout
    jne invalid_option
 
;; Contract: -> string
;; Purpose: If the user does not pick a valid option, return back this error message
invalid_option:
    PRINT_STRING "Invalid option, please choose a valid menu option."
    NEWLINE
    jmp menu_loop
    
;; Option 1
;; -----------------------
;; Contract: -> string
;; Purpose: Shows the user their account information num, holder, type, creation date
;; then jumps back to the menu_loop to continue any other possible options the user would
;; like to see
view_account_details:
    PRINT_STRING "1. View account details: "
    NEWLINE
    PRINT_STRING "      Account Number: "
    PRINT_DEC 4, [account_num]
    NEWLINE
    
    PRINT_STRING "      Accout Holder: "
    PRINT_STRING [account_holder]
    NEWLINE
    
    PRINT_STRING "      Account Type: "
    PRINT_STRING [account_type]
    NEWLINE
    
    PRINT_STRING "      Creation Date: "
    PRINT_STRING [account_creation_date]
    NEWLINE
    jmp menu_loop
    
;; Option 2
;; -----------------------
;; Contract: -> string int
;; Purpose: Returns back the user's current account balance, storing the latest balance
;; then jumps back to the menu_loop to continue any other possible options the user would
;; like to see
check_balance:
    PRINT_STRING "2. Check balance: "
    NEWLINE
    PRINT_STRING "      Current account balance: $"
    PRINT_DEC 4, [account_bal]
    NEWLINE
    jmp menu_loop
 
;; Option 3
;; -----------------------
;; Contract: int -> string int
;; Purpose: Allows the user to deposit money into their bank account and returning back their
;; account balance after depositing, as well keeping this stored in the transaction_stack if they
;; were to call the transaction history option
deposit_funds:
    PRINT_STRING "3. Deposit funds: "
    NEWLINE
    PRINT_STRING "      Enter deposit amount: $"
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    
    add [account_bal], eax  
    call pop_oldest_transaction?
    inc dword [transaction_count]
    mov ebx, [transaction_count]  
    mov [transaction_stack + ebx * 5], eax  
    mov byte [transaction_stack + ebx * 5 + 4], '+'
 
;; Contract: -> string
;; Purpose: Once all the depositing is done, the transaction successful message appear,
;; returning back their updated balance then jumps back to the menu_loop to continue any
;; other possible options the user would like to see
deposit_done:
    PRINT_STRING "      Transaction successful!"
    NEWLINE
    PRINT_STRING "      Updated balance: $"
    PRINT_DEC 4, [account_bal]
    NEWLINE
    jmp menu_loop
 
;; Option 4
;; -----------------------
;; Contract: int -> string int
;; Purpose: Withdraw the user's inputted money amount from their current acconut balance
;; and then storing this in the transaction_stack for if they were to call the transaction history
;; option later on, if not jump to the withdraw_done function
withdraw_funds:
    PRINT_STRING "4. Withdraw funds: "
    NEWLINE
    PRINT_STRING "      Enter withdrawal amount: $"
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    cmp eax, [account_bal]    
    ja withdraw_fail
    sub [account_bal], eax
    neg eax
    call pop_oldest_transaction?
    inc dword [transaction_count]
    mov ebx, [transaction_count]  
    mov [transaction_stack + ebx * 5], eax  
    mov byte [transaction_stack + ebx * 5 + 4], '-'  
    
;; Contract: -> void
;; Purpose: Calculate interest based on account type
calculate_interest:
    PRINT_STRING "  Interest calculation:" 
    NEWLINE
    PRINT_STRING "      Account Type: "
    PRINT_STRING [account_type]
    NEWLINE
    mov esi, account_type  
    mov ecx, 0            

;; Contract: -> void
;; Purpose: Checks if the account type is a savings account to apply the 
;; appropiate interest onto the account balance
check_savings_type:
    mov al, [esi + ecx]    
    cmp al, 'S'     
    jne check_fixed_type
    add ecx, 1
    mov al, [esi + ecx]
    cmp al, 'a'
    jne check_fixed_type
    jmp calculate_savings_interest

;; Contract: -> void
;; Purpose: Checks if the account type is a fixed account to apply the 
;; appropiate interest onto the account balance
check_fixed_type:
    mov esi, account_type
    mov ecx, 0
    mov al, [esi + ecx]
    cmp al, 'F'           
    jne invalid_type
    add ecx, 1
    mov al, [esi + ecx]
    cmp al, 'i'
    jne invalid_type
    jmp calculate_fixed_interest

;; Contract: -> int
;; Purpose: Determines the interest based on the account type and then
;; prints it out for the user to see their interest rate
calculate_savings_interest:
    ;; (account_bal * 3) / 100
    mov eax, [account_bal] 
    mov ebx, 3            
    mul ebx               
    mov ebx, 100          
    div ebx              
    PRINT_STRING "      Calculated Interest: $"
    PRINT_DEC 4, eax
    NEWLINE
    jmp withdraw_done

;; Contract -> int
;; Purpose: Determines the interest based on the account type and then
;; prints it out for the user to see their interest rate
calculate_fixed_interest:
    ;; (account_bal * 5) / 100
    mov eax, [account_bal] 
    mov ebx, 5            
    mul ebx            
    mov ebx, 100        
    div ebx        
    PRINT_STRING "      Calculated Interest: $"
    PRINT_DEC 4, eax
    NEWLINE
    jmp withdraw_done

;; Contract: -> string
;; Purpose: If the account type is neither Savings or Fixed, then print out
;; this error message to the user
invalid_type:
    PRINT_STRING "      Error: Invalid account type for interest calculation."
    NEWLINE
    jmp menu_loop
    
;; Contract: -> string
;; Purpose: Once withdrawing the money is done, print out the transaction successful message
;; and then print out their updated balance after taking out money then jumps back to the menu_loop
;; to continue any other possible options the user would like to see
withdraw_done:
    PRINT_STRING "      Transaction successful!"
    NEWLINE
    PRINT_STRING "      Updated balance: $"
    sub [account_bal], eax
    PRINT_DEC 4, [account_bal]
    NEWLINE
    jmp menu_loop
 
;; Contract: -> string
;; Purpose: If the user tries to take more than what they have in their current account balance
;; return this fail message and then jumps back to the menu_loop to continue any other possible
;; options the user would like to see
withdraw_fail:
    PRINT_STRING "      Insufficient funds... transaction failed :("
    NEWLINE
    jmp menu_loop
 
;; Contract: -> stack
;; Purpose: Pops the oldest transaction in the stack and allows the user to always
;; see the 5 most recent transactions deposit, withdraw, transfer
pop_oldest_transaction?:
    mov ecx, [transaction_count]
    cmp ecx, 4
    jl skip
    lea esi, [transaction_stack + 5]  
    lea edi, [transaction_stack]      
    mov ecx, 20                   
    rep movsb                         
    dec dword [transaction_count]     
    ret
    
;; Contract: -> void
;; Purpose: Return the given value    
skip:
    ret
    
;; Option 5
;; -----------------------
;; Contract: int int -> string int
;; Purpose: Compares if the recipient's account number exists and if it does and passes,
;; allow the user to select the amount of money they wish to transfer to the recipient's
;; account
transfer_money:
    PRINT_STRING "5. Transfer money: "
    NEWLINE
    PRINT_STRING "      Enter recipient's account number: "
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    cmp eax, [recipient_num]
    jne transfer_fail1
    PRINT_STRING "      Enter the transfer amount: $"
    GET_DEC 4, eax
    PRINT_DEC 4, eax
    NEWLINE
    cmp eax, [recipient_bal]
    jg transfer_fail2
    cmp eax, 0
    je transfer_done
    sub [account_bal], eax
    add [recipient_bal], eax
    neg eax
    call pop_oldest_transaction?
    inc dword [transaction_count]
    mov ebx, [transaction_count]
    mov [transaction_stack + ebx * 5], eax
    mov byte [transaction_stack + ebx * 5 + 4], 'T'
 
;; Contract: -> string int
;; Purpose: Prints out the user's updated balance after transfering the amount they chose,
;; as well as the recipient's updated balance after the transfer process is done
transfer_done:
    PRINT_STRING "      Transaction successful!"
    NEWLINE
    PRINT_STRING "      Your updated balance: $"
    PRINT_DEC 4, [account_bal]
    NEWLINE
    PRINT_STRING "      Recipient's updated balance: $"
    PRINT_DEC 4, [recipient_bal]
    NEWLINE
    jmp menu_loop
 
;; Contract: -> string
;; Purpose: If the account number does not exist, print out this error message and then
;; jumps back to the menu_loop to continue any other possible options the user would
;; like to see
transfer_fail1:
    PRINT_STRING "      Account number does not exist!"
    NEWLINE
    jmp menu_loop
 
;; Contract:-> string
;; Purpose: If the user is trying to transfer more money than they have, print out this error
;; message then jumps back to the menu_loop to continue any other possible options the
;; user would like to see
transfer_fail2:
    PRINT_STRING "      Insufficient transfer money, you do not have enough money to transfer this amount"
    NEWLINE
    jmp menu_loop
 
;; Option 6
;; -----------------------
;; Contract: -> string
;; Purpose: The heading portion of option 6
transaction_history:
    PRINT_STRING "6. View transaction history:"
    NEWLINE
    
;; Contract: stack -> string
;; Purpose: This is used for option 8 to print this out when calling for a mini_statement
;; just without the heading portiong of option 6 to not be included
option_8_helper:
    mov ecx, [transaction_count]  
    cmp ecx, -1   
    je no_transactions   
    PRINT_STRING "Last 5 transactions:"
    NEWLINE  
    mov ebx, 0                   
 
;; Contract: -> string
;; Purpose: Prints out the transaction list, from the stack in order from transactions
;; in format 1. 2. 3. 4. 5. and with their corresponding type determined if it was a
;; deposit, "+", if not their "-"
print_transaction:
    cmp ecx, -1  
    je done_printing_transaction
    lea esi, [transaction_stack + ecx * 5]
    inc ebx                       
    PRINT_DEC 4, ebx               
    PRINT_STRING ". "
    lodsd     
    dec ecx      
    cmp eax, 0
    jge print_positive_amount
    PRINT_DEC 4, eax      
    jmp print_transaction_type   
    
;; Contract: -> string
;; Purpose: Prints the "+" string infront of the amount for the user to see visually
print_positive_amount:
    PRINT_STRING "+"              
    PRINT_DEC 4, eax             
 
;; Contract: char -> string
;; Purpose: Gets the character and determines the label they should have printed after
;; their transaction amount, then jumps to print_next_transaction which just creates a
;; newline and goes back to print the next transaction in the stack
print_transaction_type:
    lodsb
    PRINT_STRING " ("         
    cmp al, '+'  
    je deposit_label
    cmp al, '-'  
    je withdrawal_label
    cmp al, 'T'  
    je transfer_label
    jmp print_next_transaction
 
;; Contract: -> string
;; Purpose: Prints the deposit label, then goes to the next transaction
deposit_label:
    PRINT_STRING "Deposit)"
    jmp print_next_transaction
 
;; Contract: -> string
;; Purpose: Prints the withdrawal label, then goes to the next transaction
withdrawal_label:
    PRINT_STRING "Withdrawal)"
    jmp print_next_transaction
 
;; Contract: -> string
;; Purpose: Prints the transfer label, then goes to the next transaction
transfer_label:
    PRINT_STRING "Transfer)"
    jmp print_next_transaction
 
;; Contract: -> void
;; Purpose: Just creates a newline to then produce the next transaction up to 5
print_next_transaction:
    NEWLINE                      
    jmp print_transaction     
  
;; Contract: -> string
;; Purpose: Determines if there is no previos transactions, if so print this
;; message to the user, if not store the value in the transaction stack and
;; jump to done_printing_transaction
no_transactions:
    PRINT_STRING "No previous transactions!"
    NEWLINE
    jmp done_printing_transaction
 
;; Contract: -> void
;; Purpose: When done printing all the transactions jumps back to the menu_loop to
;; continue any other possible options the user would like to see
done_printing_transaction:
    jmp menu_loop                        
   
;; Option 7
;; -----------------------
;; Contract: -> string
;; Purpose: Prints out the balance history of account B moving the account pointer to
;; point to the correct one in the stack and loads that into the array showing the
;; 5 latest balance history amounts
balance_history:
    PRINT_STRING "7. Balance history (Account B): "
    NEWLINE
    PRINT_STRING "Balance history of account B: "
    NEWLINE
    mov ecx, [acnt_b_pointer]
 
;; Contract: -> void
;; Purpose: Load the data, per byte into the stack and moves throughout the stack
;; printing the amount and loops until done printing all the updated values
;; started from the top of the stack
print_loop:
    lea esi, [account_b_bal_stack + ecx * 4]
    lodsd
    PRINT_STRING "$"
    PRINT_DEC 4, eax
    dec ecx
    cmp ecx, -1
    je done_print
    PRINT_STRING ", "
    jmp print_loop
    
;; Contract: -> void
;; Purpose: When done printing, jump back to the menu_loop to continue any other possible
;; options the user would like to see
done_print:
    NEWLINE
    jmp menu_loop
 
;; Option 8
;; -----------------------
;; Contract: -> string
;; Purpose: Prints the mini statement for the user with the latest transactions in a
;; special format and call option_8_helper which is option 6 again but without the header
;; then jumps back to the menu_loop to continue any other possible options the user would
;; like to see
mini_statement:
    PRINT_STRING "8. Generate mini statement:"
    NEWLINE
    PRINT_STRING "--------------------------------"
    NEWLINE
    PRINT_STRING "        Mini statement          "
    NEWLINE
    PRINT_STRING "--------------------------------"
    NEWLINE
    PRINT_STRING "Current balance: $"
    PRINT_DEC 4, [account_bal]      
    NEWLINE
    jmp option_8_helper
    jmp menu_loop  
 
;; Option 9
;; -----------------------
;; Contract: hex string -> hex
;; Purpose: Allows the user to change their password and give back their updated password
;; encrypted in hexidecimal and has a max character of 6 for the new password
change_password:
    PRINT_STRING "9. Change password: "
    NEWLINE
    PRINT_STRING "      Enter current password: "
    call remove_newline
    mov ecx, 0
    GET_HEX 4, eax
    PRINT_STRING "0x"
    PRINT_HEX 4, eax
    PRINT_STRING " "
    mov dword [password + ecx * 4], eax   
    inc ecx
 
;; Contract: characters -> void
;; Purpose: Goes byte per byte to get the character of the user, to then convert it into
;; hexidecimal format with 0x initialized infront of each new value until the end of the
;; inputted set of characters (new password)
get_password_loop1:
    xor eax, eax
    GET_CHAR al
    cmp al, byte 10
    je done_getting_password1
    xor eax, eax
    GET_HEX 4, eax
    PRINT_STRING "0x"
    PRINT_HEX 4, eax
    PRINT_STRING " "
    mov dword [password + ecx * 4], eax
    inc ecx
    jmp get_password_loop1
 
;; Contract: -> void
;; Purpose: Once the password is updated, print back the user's inputted password they wish
;; to get encrypted and then return back their password in hexidecimal format
done_getting_password1:
    NEWLINE
    call compare_hex_array       
    cmp eax, 1                   
    jne wrong_password    
    PRINT_STRING "      Enter new password: "
    GET_STRING password, 32
    PRINT_STRING password
    PRINT_STRING "      Your new encrypted password: "
    mov bl, 0x55
    lea esi, password
    cld
    mov ecx, 0
 
;; Contract: characters -> hex
;; Purpose: Encrypts the inputted password and converts this set of characters into
;; hex format which is the process of encrypting
encrypt_password:
    lodsb
    cmp al, byte 10
    je done_encrypt
    xor al, bl
    mov [correct_pass + ecx * 4], al
    PRINT_STRING "0x"
    PRINT_HEX 1, al
    PRINT_STRING " "
    jmp encrypt_password
 
;; Contract: -> void
;; Purpose: Once the whole process of option 9 is done, print out ths message to alert
;; the user that their password has been updated successfully and then jumps back to the
;; menu_loop to continue any other possible options the user would like to see
done_encrypt:
    NEWLINE
    PRINT_STRING "      Password updated successfully!"
    NEWLINE
    jmp menu_loop
 
;; Option 10
;; -----------------------
;; Contract: -> string
;; Purpose: Everytime the user is done using the banking system, the user must logout
;; to avoid any future breaches from other people :), just to terminate the program and
;; the menu_loop and return a goodbye message
logout:
    PRINT_STRING "10. Logout: "
    NEWLINE
    PRINT_STRING "      Thank you for using the advanced banking system."
    NEWLINE
    PRINT_STRING "      Goodbye!"
    ret
