" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 17-Nov-2013.

" TODO: scilabのエラーメッセージをいろいろ出して対応する

" Pasing error message of scilab.
function! s:parse_error(script_path, msg_list)   "{{{
    let error_info = {}

    let error_info.file = a:script_path
    let error_info.nr   = matchstr(a:msg_list[1], '\s*!--error\s*\zs\d\+\ze')
    let error_info.line = matchstr(a:msg_list[3], 'at line\s*\zs\d\+\ze of exec file called by :')
    let error_info.col  = printf("%s", stridx(a:msg_list[1], "!"))
    let error_info.msg  = a:msg_list[2]
    return error_info
endfunction
"}}}

" Redirecting to file.
function! s:redir_file(filename, msg)   "{{{
    execute "redir! > " . a:filename
    echo a:msg
    redir END
endfunction
"}}}

" Running script.
function! s:run_script(path)    "{{{
    " Initialization of miscellaneous variables
    if !exists("b:scilabcomplete_initialized")
        " Initialization of configuration variables runs only one time.
        call scilabcomplete#Initialization()
        let b:scilabcomplete_initialized = 1
    endif
    let name    = b:scilabcomplete_process_name
    let cmd     = b:scilabcomplete_startup_command
    let prompts = b:scilabcomplete_console_prompts

    " Communicate with scilab process
    call b:PM.touch(name, cmd)
    let script_path = a:path
    let msg = 'exec("' . script_path . '", -1)'
    let success = scilabcomplete#run_command(name, msg, prompts)
    let error_info = {}
    if success == len(prompts)
        let output     = scilabcomplete#read_out(name, prompts)
        let msg_list   = filter(split(output[0], '\r*\n'), 'v:val != " "')
        if !empty(msg_list)
            let error_info = s:parse_error(script_path, msg_list)
        endif
    endif
    return error_info
endfunction
"}}}

" The function for the command ":UpdateWorkspace".
function! scilabcomplete#utilities#update_workspace()   "{{{
    execute "write! " . b:scilabcomplete_tmpfile
    let error_info = s:run_script(b:scilabcomplete_tmpfile)
    if !empty(error_info)
        let error_msg = 'scilabcomplete : |line ' . error_info.line . '| ' . error_info.msg
        echohl WarningMsg
        echomsg error_msg
        echohl NONE
    else
        echo 'scilabcomplete : The workspace is updated!'
    endif
endfunction
"}}}

" The function running before the :make command
function! scilabcomplete#utilities#pre_make()   "{{{
    " Run script
    execute "write! " . b:scilabcomplete_tmpfile
    let error_info = s:run_script(b:scilabcomplete_tmpfile)
    if !empty(error_info)
        " If there is some error, writing error message to temp file.
        let errorfile_contains = error_info.nr . "|" . error_info.line . "|" . error_info.col . "|" . error_info.msg . "|" . error_info.file
        silent call s:redir_file(b:scilabcomplete_errorfile, errorfile_contains)
        " Save the default makeef option and change it temporary.
        " This will set back after :make command.
        let s:makeef  = &makeef
        let s:makeprg = &makeprg
        let s:errorformat = &errorformat
        execute "set makeef=" . b:scilabcomplete_errorfile
        setlocal errorformat=%n|%l|%c|%m|%f
    endif
endfunction
"}}}

" The function running before the :make command
function! scilabcomplete#utilities#post_make()   "{{{
    execute "set makeef=" . s:makeef
    execute "setlocal errorformat=" . s:errorformat
endfunction
"}}}

