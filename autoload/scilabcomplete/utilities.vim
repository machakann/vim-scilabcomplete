" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 17-Nov-2013.

" Pasing error message of scilab.
function! s:parse_error(script_path, raw_msg)   "{{{
    let msg_list   = split(a:raw_msg, '\r*\n')
    let error_info = {}

    let error_info.file = a:script_path
    let error_info.nr   = stridx(msg_list[1], "!")
    let error_info.line = msg_list[0]
    let error_info.col  = matchstr(msg_list[3], 'at line\s*\zs\d\+\ze of exec file called by :')
    let error_info.msg  = msg_list[2]
    let error_info.raw  = a:raw_msg
    return error_info
endfunction
"}}}

" Writing to file.
function! s:redir_file(filename, msg)   "{{{
    execute "redir! > " . a:filename
    echo a:msg
    redir END
endfunction
"}}}

" Running script.
function! s:run_script()    "{{{
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
    let script_path = eval("%:p")
    let msg = 'exec("' . script_path . '", -1)'
    let success = scilabcomplete#run_command(name, msg, prompts)
    if success = len(prompts)
        let output     = scilabcomplete#read_out(name, prompts)
        let error_info = s:parse_error(script_path, output[0])
    else
        let error_info = {}
    endif
    return error_info
endfunction
"}}}

" The function for the command ":UpdateWorkspace".
function! scilabcomplete#utilities#update_workspace()   "{{{
    let error_info = s:run_script()
    if !empty(error_info)
        let error_msg = 'scilabcomplete : |line ' . error_info.line . '| ' . error_info.msg
        echoerr error_msg
    else
        echo 'scilabcomplete : The workspace is updated!'
    endif
endfunction
"}}}

" The function running before the :make command
function! scilabcomplete#utilities#pre_make()   "{{{
    " Run script
    let error_info = s:run_script()
    if !empty(error_info)
        " If there is some error, writing error message to temp file.
        let s:tmpfile = get(s:, "tmpfile", tempname())
        silent call s:redir_file(s:tmpfile, error_info.raw)
        " Save the default makeef option and change it temporary.
        " This will set back after :make command.
        let s:makeef  = &makeef
        let s:makeprg = &makeprg
        let s:errorformat = &errorformat
        execute "set makeef=" . s:tmpfile
        setlocal errorformat=%A,%C%p!--error%n\ ,%C%m,%Cat line\ %l\ of\ exec\ file\ called\ by\ :\ \ \ \ ,%Zexec('%f')
    endif
endfunction
"}}}

" The function running before the :make command
function! scilabcomplete#utilities#post_make()   "{{{
    execute "set makeef=" . s:makeef
    execute "setlocal errorformat=" . s:errorformat
endfunction
"}}}

