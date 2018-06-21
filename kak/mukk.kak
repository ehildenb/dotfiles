declare-option -docstring "name of the client in which utilities display information" \
    str toolsclient
declare-option -hidden int mukk_current_line 0

define-command -params .. -file-completion \
    -docstring %{mukk-list [<arguments>]: mukk list utility wrapper
All the optional arguments are forwarded to the mukk list utility} \
    mukk-list %{ %sh{
     output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-mukk.XXXXXXXX)/fifo
     mkfifo ${output}
     ( mukk list "$@" > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null &

     printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
               edit! -fifo ${output} -scroll *mukk*
               set-option buffer filetype mukk
               set-option buffer mukk_current_line 0
               hook -group fifo buffer BufCloseFifo .* %{
                   nop %sh{ rm -r $(dirname ${output}) }
                   remove-hooks buffer fifo
               }
           }"
}}

hook -group grep-highlight global WinSetOption filetype=mukk %{
    add-highlighter window group mukk
    add-highlighter window/mukk regex "^(thread:[0-9a-f]+)([^\n\r]*)$" 1:green 2:default
    add-highlighter window/mukk line %{%opt{mukk_current_line}} default+b
}

hook global WinSetOption filetype=mukk %{
    hook buffer -group mukk-hooks NormalKey r     %{ mukk-list }
    hook buffer -group mukk-hooks NormalKey <c-r> %{ mukk-read }
    hook buffer -group mukk-hooks NormalKey <ret> %{ mukk-jump }
}

hook -group mukk-highlight global WinSetOption filetype=(?!mukk).* %{ remove-highlighter window/mukk }

hook global WinSetOption filetype=(?!mukk).* %{
    remove-hooks buffer mukk-hooks
}

declare-option -docstring "name of the client in which all source code jumps will be executed" \
    str jumpclient

define-command -hidden mukk-jump %{
    %sh{
        output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-mukk.XXXXXXXX)/email-reply
        ( mukk reply "$kak_selection" > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null
        printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
                          edit! ${output}
                          set-option buffer filetype mukk
                          set-option buffer mukk_current_line 0
                          hook -group mukk-hooks buffer BufClose .* %{
                              nop %sh{ rm -r $(dirname ${output}) }
                              remove-hooks buffer mukk-hooks
                          }
                      }"
    }
}

define-command -hidden mukk-read %{
    %sh{
        echo "$kak_selections" | tr ':' '\n' \
            | while read thread_id; do
                thread_id="${thread_id#thread}"
                echo "thread_id: $thread_id" >&2
                mukk read "thread:$thread_id"
              done
    }
}

#define-command grep-next-match -docstring 'Jump to the next grep match' %{
#    evaluate-commands -try-client %opt{jumpclient} %{
#        buffer '*grep*'
#        # First jump to enf of buffer so that if grep_current_line == 0
#        # 0g<a-l> will be a no-op and we'll jump to the first result.
#        # Yeah, thats ugly...
#        execute-keys "ge %opt{grep_current_line}g<a-l> /^[^:]+:\d+:<ret>"
#        grep-jump
#    }
#    try %{ evaluate-commands -client %opt{toolsclient} %{ execute-keys gg %opt{grep_current_line}g } }
#}
#
#define-command grep-previous-match -docstring 'Jump to the previous grep match' %{
#    evaluate-commands -try-client %opt{jumpclient} %{
#        buffer '*grep*'
#        # See comment in grep-next-match
#        execute-keys "ge %opt{grep_current_line}g<a-h> <a-/>^[^:]+:\d+:<ret>"
#        grep-jump
#    }
#    try %{ evaluate-commands -client %opt{toolsclient} %{ execute-keys gg %opt{grep_current_line}g } }
#}
