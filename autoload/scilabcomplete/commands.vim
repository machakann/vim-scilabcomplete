" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 22-Dec-2013.

" TODO: scilabのエラーメッセージをいろいろ出して対応する
" TODO: エラーと警告の扱いについて

" Pasing error message of scilab.
function! s:parse_error(msg_list)   "{{{
    let idx        = 0
    let error_list = []
    let error_dict = {}

    while 1
        let line = get(a:msg_list, idx, '')
        if line == ''
            break
        endif

        let nr  = matchstr(line, '\s*!--error\s*\zs\d\+\ze')
        let col = printf("%s", stridx(line, "!"))

        if match(line, '^Warning :.*') == 0
            let error_dict.filename = b:scilabcomplete_script_path
            let error_dict.nr   = ''
            let error_dict.lnum = ''
            let error_dict.col  = ''
            let error_dict.text = matchstr(line, '^Warning :\zs.*')
            let error_dict.type = 'W'
            let error_list += [error_dict]
        elseif nr != ''
            let error_dict.nr   = nr
            let error_dict.col  = col
            let error_dict.type = 'E'
            let error_dict.text = get(a:msg_list, idx+1, '')

            let idx += 2

            while 1
                let line = get(a:msg_list, idx, '')
                let filename = matchstr(line, '^exec("\zs\f\+\ze", -1)$')
                let lnum     = matchstr(line, 'at line\s*\zs\d\+\ze of exec file called by :')

                if lnum != ''
                    let error_dict.lnum     = lnum
                elseif filename != ''
                    let error_dict.filename = (filename == b:scilabcomplete_tmpfile ? b:scilabcomplete_script_path : filename)
                    let error_list += [error_dict]
                    break
                endif
                let idx += 1
            endwhile
        endif

        let idx += 1
    endwhile

    return error_list
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
    let msg         = 'exec("' . script_path . '", -1)'
    let success     = scilabcomplete#run_command(name, msg, prompts)
    let error_list  = []

    if success == len(prompts)
        let output   = scilabcomplete#read_out(name, prompts)
        let msg_list = filter(filter(split(output[0], '\r*\n'), 'v:val != " "'), 'v:val != ""')
        if !empty(msg_list)
            let error_list = s:parse_error(msg_list)
        endif
    endif
    return error_list
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
    let error_list = s:run_script(b:scilabcomplete_tmpfile)
    if !empty(error_list)
        if a:bang == '!'
            call setqflist(error_list)
        else
            echohl WarningMsg
            for error_dict in error_list
                if !empty(error_dict)
                    let error_msg = 'scilabcomplete : |lnum ' . error_dict.lnum . '| ' . error_dict.text
                else
                    let error_msg = 'scilabcomplete : ' . error_dict.text
                endif

                echomsg error_msg
            endfor
            echohl NONE
        endif
    else
        echo 'scilabcomplete : The workspace is updated!'
    endif
endfunction
"}}}
