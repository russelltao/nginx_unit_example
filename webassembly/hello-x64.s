# Copyright (C) F5, Inc.

# Compile with:
#   $ gcc -c -g src/test/nxt_unit_asm_test.s -o src/test/nxt_unit_asm_test.o
#   $ ld -g src/test/nxt_unit_asm_test.o build/libunit.a -lpthread -lc \
#        --dynamic-linker=/lib64/ld-linux-x86-64.so.2 -o build/unit_asm_test


    .global _start


# Linux x64 syscall codes
sys_write = 1
sys_exit  = 60

NXT_UNIT_OK = 0

.macro prologue
    push    %rbp
    mov     %rsp, %rbp
.endm


.macro epilogue
    mov     %rbp, %rsp
    pop     %rbp
.endm


.text

_start:

init_struct_size = 192                  # sizeof(nxt_unit_init_t)

    mov     $0, %rbp                    # set first frame
    sub     $init_struct_size, %rsp     # stack is already aligned

    lea     (%rsp), %rdi
    mov     $init_struct_size, %rsi
    call    memzero

    lea     request_handler(%rip), %rax
    mov     %rax, 0x20(%rsp)            # init.callbacks.request_handler
    lea     (%rsp), %rdi
    call    nxt_unit_init

    test    %rax, %rax                  # ctx == NULL
    jz      .init_failed

    mov     %rax, %rbx
    mov     %rbx, %rdi
    call    nxt_unit_run

    test    %rax, %rax
    jnz     .run_failed

    mov     %rbx, %rdi
    call    nxt_unit_done

    mov     $1, %rdi
    call    exit

.init_failed:
    mov     $init_error, %rdi
    call    puts

    jmp     .error

.run_failed:
    mov     $run_error, %rdi
    call    puts

    jmp     .error

.error:
    mov     $1, %rdi
    call    exit

    # unreachable

puts:
    prologue
    sub     $0x10, %rsp

    mov     %rdi, -0x10(%rbp)

    call    strlen

    mov     %rax, %rdx
    mov     -0x10(%rbp), %rsi
    mov     $1, %rdi
    mov     $sys_write, %rax
    syscall

    add     $0x10, %rsp
    epilogue

    ret

strlen:
    prologue

    mov     $-1, %rcx
    xor     %rax, %rax
    repne   scasb
    not     %rcx
    dec     %rcx
    mov     %rcx, %rax

    epilogue

    ret

exit:
    prologue

    mov     $sys_exit, %rax
    syscall

    epilogue

    ret

memzero:
    prologue

    mov     %rsi, %rcx
.again:
    add     $1, %rdi
    movb    $0, (%rdi)
    loop    .again

    epilogue

    ret

request_handler:
    prologue

    sub     $0x10, %rsp                     # req + rc

    mov     %rdi, -0x10(%rbp)
    mov     $200, %rsi                      # 200 OK
    mov     $1, %rdx                        # 1 header
    mov     $req_total_len, %rcx
    call    nxt_unit_response_init

    mov     %eax, -0x8(%rbp)
    cmpl    $NXT_UNIT_OK, -0x8(%rbp)
    jne     .response_init_failed

    mov     -0x10(%rbp), %rdi
    mov     $req_cont_type, %rsi
    mov     $req_cont_type_len, %rdx
    mov     $req_text_plain, %rcx
    mov     $req_text_plain_len, %r8
    call    nxt_unit_response_add_field

    mov     %eax, -0x8(%rbp)
    cmpl    $NXT_UNIT_OK, -0x8(%rbp)
    jne     .response_add_field_failed

    mov     $req_body, %rsi
    mov     $req_body_len, %rdx
    mov     -0x10(%rbp), %rdi
    call    nxt_unit_response_add_content

    mov     %eax, -0x8(%rbp)
    cmpl    $NXT_UNIT_OK, -0x8(%rbp)
    jne     .response_add_content_failed

    mov     -0x10(%rbp), %rdi
    call    nxt_unit_response_send

    mov     %eax, -0x8(%rbp)
    cmpl    $NXT_UNIT_OK, -0x8(%rbp)
    jne     .request_error

    mov     $0, %rsi
    jmp     .request_ok

.response_init_failed:
    mov     $req_init_failed_msg, %rdi
    call    puts

    jmp     .request_error

.response_add_field_failed:
    mov     $req_add_field_failed_msg, %rdi
    call    puts

    jmp     .request_error

.response_add_content_failed:
    mov     $req_add_content_failed_msg, %rdi
    call    puts

    jmp     .request_error

.request_error:
    mov     $1, %rsi

.request_ok:
    mov     -0x10(%rbp), %rdi
    call    nxt_unit_request_done

.request_handler_end:
    add     $0x10, %rsp

    epilogue

    ret


.data

init_error:
    .asciz  "Failed to initialize\n"

run_error:
    .asciz  "Run failed\n"

# Request strings

req_init_failed_msg:
    .asciz  "Failed to initialize request"

req_add_field_failed_msg:
    .asciz  "Failed to add field to request"

req_add_content_failed_msg:
    .asciz  "Failed to add content to request"

req_cont_type:
    .asciz  "Content-Type"
req_cont_type_end = .

req_text_plain:
    .asciz  "text/plain"
req_text_plain_end = .

req_body:
    .asciz  "Hello from x64 assembly\n"
req_body_end = .

req_cont_type_len    = req_cont_type_end - req_cont_type - 1
req_text_plain_len   = req_text_plain_end - req_text_plain - 1
req_body_len         = req_body_end - req_body - 1
req_total_len        = req_cont_type_len + req_text_plain_len + req_body_len
