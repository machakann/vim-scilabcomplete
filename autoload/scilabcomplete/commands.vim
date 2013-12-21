" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 22-Dec-2013.

" TODO: scilabのエラーメッセージをいろいろ出して対応する
" TODO: エラーと警告の扱いについて

" Pasing error message of scilab.
function! s:parse_error(msg_list)   "{{{
    let error_info = {}

    if match(a:msg_list[0], '^Warning :.*') == 0
        let error_info.filename = b:scilabcomplete_script_path
        let error_info.nr       = ''
        let error_info.lnum     = ''
        let error_info.col      = ''
        let error_info.text     = a:msg_list[0]
        let error_info.type     = 'W'
    else
        let filename = matchstr(a:msg_list[4], '^exec("\zs\f\+\ze", -1)$')
        let error_info.filename = (filename == b:scilabcomplete_tmpfile ? b:scilabcomplete_script_path : filename)
        let error_info.nr       = matchstr(a:msg_list[1], '\s*!--error\s*\zs\d\+\ze')
        let error_info.lnum     = matchstr(a:msg_list[3], 'at line\s*\zs\d\+\ze of exec file called by :')
        let error_info.col      = printf("%s", stridx(a:msg_list[1], "!"))
        let error_info.text     = a:msg_list[2]
        let error_info.type     = 'E'
    endif
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
    let name    = b:scilabcomplete_process_name
    let cmd     = b:scilabcomplete_startup_command
    let prompts = b:scilabcomplete_console_prompts

    " Communicate with scilab process
    call s:PM.touch(name, cmd)
    let script_path = a:path
    let msg = 'exec("' . script_path . '", -1)'
    let success = scilabcomplete#run_command(name, msg, prompts)
    let error_info = {}
    if success == len(prompts)
        let output     = scilabcomplete#read_out(name, prompts)
        let msg_list   = filter(split(output[0], '\r*\n'), 'v:val != " "')
        if !empty(msg_list)
            let error_info = s:parse_error(msg_list)
        endif
    endif
    return error_info
endfunction
"}}}

" The function for the command ':UpdateWorkspace'.
function! scilabcomplete#commands#update_workspace(bang)   "{{{
    if !exists("b:scilabcomplete_initialized")
        " Initialization of configuration variables runs only one time.
        call scilabcomplete#Initialization()
    endif
    let s:PM = scilabcomplete#vital_of('PM')

    execute "write! " . b:scilabcomplete_tmpfile
    let error_info = s:run_script(b:scilabcomplete_tmpfile)
    if !empty(error_info)
        if !empty(error_info.lnum)
            let error_msg = 'scilabcomplete : |lnum ' . error_info.lnum . '| ' . error_info.text
        else
            let error_msg = 'scilabcomplete : ' . error_info.text
        endif

        if a:bang == '!'
            call setqflist([error_info])
        else
            echohl WarningMsg
            echomsg error_msg
            echohl NONE
        endif
    else
        echo 'scilabcomplete : The workspace is updated!'
    endif
endfunction
"}}}
