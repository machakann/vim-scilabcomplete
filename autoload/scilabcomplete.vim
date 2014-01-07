" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 07-Jan-2014.

" 頑張りたいと思う
" TODO: キャッシングできたほうが嬉しい
"       -> キャッシュ前とキャッシュ後で時間差を測る
" TODO: ブランチ切ってvitalの改造

" Completion function
function! scilabcomplete#Complete(findstart, base)  "{{{
    " 1st run
    if a:findstart
        let s:col  = col(".")
        let s:row  = line(".")
        let s:line = getline(".")

        let pos = s:find_completion_starting_pos(s:col, s:line)

        return pos
    endif


    " 2nd run

    " Initialization of miscellaneous variables
    let candidates = []
    let output     = []
    let word       = s:parse_struct_name(a:base, s:line, s:col)

    " If both word and a:base is empty, quit immediately.
    if word == "" && a:base == ""
        return []
    endif

    if !exists("b:scilabcomplete_initialized")
        " Initialization of configuration variables runs only one time.
        call scilabcomplete#initialization()
    endif
    let name    = scilabcomplete#get_user_conf('scilabcomplete_process_name')
    let cmd     = scilabcomplete#get_user_conf('scilabcomplete_startup_command')
    let prompts = scilabcomplete#get_user_conf('scilabcomplete_console_prompts')

    " Communicate with scilab process
    call s:PM.touch(name, cmd)
    if word !=# a:base
        " For the case of struct fields or graphic properties.
        let msg = "scilabcomplete_ans = exists('" . word . "')"
        call scilabcomplete#run_command(name, msg, prompts)
        let output = scilabcomplete#read_out(name, prompts)
        if matchstr(output[0], ' scilabcomplete_ans  =\r\?\n \r\?\n *\zs[01]\ze.')
            let msg     = "scilabcomplete_ans = type(" . word . ")"
            call scilabcomplete#run_command(name, msg, prompts)
            let output = scilabcomplete#read_out(name, prompts)
            let type = matchstr(output[0], ' scilabcomplete_ans  =\r\?\n \r\?\n *\zs\d\+\ze.')

            let fieldnames = []
            if type =~# "17"
                let kind    = "k"
                let msg     = "scilabcomplete_ans = fieldnames(" . word . ")"
                call scilabcomplete#run_command(name, msg, prompts)
                let output = scilabcomplete#read_out(name, prompts)
                let fieldnames = filter(split(substitute(matchstr(output[0], ' scilabcomplete_ans  =\r\?\n \r\?\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val !=# ""')
                if !empty(a:base)
                    let fieldnames = filter(fieldnames, "v:val =~# '^" . a:base . ".*'")
                endif
            elseif type =~# "9"
                let kind    = "g"
                let msg     = "scilabcomplete_gp = completion('" . a:base . "', 'graphic_properties')"
                call scilabcomplete#run_command(name, msg, prompts)
                let output = scilabcomplete#read_out(name, prompts)
                let fieldnames = filter(split(substitute(matchstr(output[0], ' scilabcomplete_gp  =\r\?\n \r\?\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val !=# ""')
            endif

            for key in fieldnames
                call add(candidates, {"word" : key, "kind" : kind})
            endfor
        endif
    else
        " keyword completion
        let msg     = "[scilabcomplete_functions, scilabcomplete_commands, scilabcomplete_variables, scilabcomplete_macros, scilabcomplete_gp, scilabcomplete_files] = completion('" . a:base . "')"
        call scilabcomplete#run_command(name, msg, prompts)
        let output = scilabcomplete#read_out(name, prompts)

        " Parsing the output
        let scilabcomplete_files              = filter(split(substitute(matchstr(output[0],           ' scilabcomplete_files  =\r\?\n \r\?\n *\zs.*\ze scilabcomplete_gp  ='),            '[! ]\(\f*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_graphic_properties = filter(split(substitute(matchstr(output[0],          ' scilabcomplete_gp  =\r\?\n \r\?\n *\zs.*\ze scilabcomplete_macros  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_macros             = filter(split(substitute(matchstr(output[0],   ' scilabcomplete_macros  =\r\?\n \r\?\n *\zs.*\ze scilabcomplete_variables  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_variables          = filter(split(substitute(matchstr(output[0], ' scilabcomplete_variables  =\r\?\n \r\?\n *\zs.*\ze scilabcomplete_commands  ='), '[! ]\([a-za-z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_commands           = filter(split(substitute(matchstr(output[0], ' scilabcomplete_commands  =\r\?\n \r\?\n *\zs.*\ze scilabcomplete_functions  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_functions          = filter(split(substitute(matchstr(output[0],                               ' scilabcomplete_functions  =\r\?\n \r\?\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r\?', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')

        let context              = s:recognize_context(a:base, s:row, s:col, s:line)
        let candidate_priorities = s:priorities_dict_gen(scilabcomplete#get_user_conf('scilabcomplete_candidate_priorities'), context)
        let priorities_list      = values(candidate_priorities)
        while !empty(priorities_list)
            let key = s:matched_key(candidate_priorities, max(priorities_list))
            execute "let list = scilabcomplete_" . key
            if key == "files"
                let kind = "F"
            else
                let kind = key[0]
            endif

            for candidate in list
                call add(candidates, {"word" : candidate, "kind" : kind})
            endfor

            call remove(priorities_list, match(priorities_list, max(priorities_list)))
        endwhile
    endif

    unlet s:line
    unlet s:row
    unlet s:col
    return candidates
endfunction
"}}}

" Return the position to start completion.
function! s:find_completion_starting_pos(pos, line)   "{{{
    let pos  = a:pos
    while pos > 0
        let pos -= 1
        let c = a:line[pos-1]
        if c =~# '\k'
            " match with keyword character
            continue
        elseif c =~ '\.'
            " match with dot
            break
        else
            " others
            if pos == col(".") - 1
                let pos = -1
            else
            endif
            break
        endif
    endwhile

    return pos
endfunction
"}}}

" If a:base is a field of struct, this function returns the name of struct,
" otherwise returns the word same as a:base.
function! s:parse_struct_name(base, line, cursor)   "{{{
    let len = 0
    let pos = a:cursor
    let nest_level  = 0
    let string_literal_flag = 0
    let word_end_fixed_flag = 0

    if empty(a:base)
        " In the case 1st run is terminated by dot just in front of the cursor, ignore it.
        let pos -= 1
    endif

    while pos > 0
        let pos -= 1
        let len += 1
        let c = a:line[pos-1]

        if nest_level > 0
            if string_literal_flag == 1
                " in a string literal
                if c =~ "'"
                    if a:line[pos-2] =~ "'"
                        " ' in a string
                        let pos -= 1
                    else
                        " end of string literal
                        let string_literal_flag = 0
                    end
                endif
            elseif c =~ "'"
                " beginning of the string literal
                let string_literal_flag = 1
            elseif c =~ '('
                " decrease nest_level
                let nest_level -= 1
                if nest_level == 0 && word_end_fixed_flag == 0
                    let word_end_fixed_flag = 1
                    let len = 0
                endif
            elseif c =~ ')'
                " increase nest_level
                let nest_level += 1
            endif
            continue
        else
            if c =~# '\k'
                " match with keyword character
                continue
            elseif c =~ '\.'
                " match with dot
                if word_end_fixed_flag == 0
                    if a:line[pos-2] =~ ')'
                        " If ) comes in front of a dot, ignore the part of parenthesis.
                        let pos -= 1
                        let nest_level += 1
                        continue
                    else
                        let word_end_fixed_flag = 1
                        let len = 0
                        continue
                    endif
                endif
                continue
            elseif c =~ ')'
                " increase nest_level
                let nest_level += 1
                continue
            else
                " others
                break
            endif
        endif
    endwhile
    return strpart(a:line, pos, len-1)
endfunction
"}}}

" Return the first key which its value matched with argument value.
function! s:matched_key(dict, value)    "{{{
    let dict_value_list = values(a:dict)
    let dict_key_list   = keys(a:dict)
    let idx = match(dict_value_list, a:value)
    return dict_key_list[idx]
endfunction
"}}}

" Return the dictionary including the information of priorities of candidates.
function! s:priorities_dict_gen(arg, context)    "{{{
    let candidate_priorities = {}

    if type(a:arg) == type({})
        execute 'let candidate_priorities = a:arg.' . a:context
        execute 'let default_priorities = s:default_priorities.' . a:context
        call extend(candidate_priorities, default_priorities, 'keep')
        let candidate_priorities = filter(candidate_priorities, 'v:val >= 0')
    else
        execute 'let candidate_priorities = s:default_priorities.' . a:context
    endif

    return candidate_priorities
endfunction
"}}}

" Initialization of required buffer local variables.
function! scilabcomplete#initialization()   "{{{
    " Process name for use of process manager
    let g:scilabcomplete_process_name = get(g:, "scilabcomplete_process_name", "scilab")
    " Command to start scilab
    if has("win32") || has("win64")
        let g:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilex"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    else
        let g:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilab"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    endif
    " Prompt of Scilab console
    let g:scilabcomplete_console_prompts = get(g:, "scilabcomplete_scilab_prompt", ['-->'])
    " The way to determine the priorities of each kinds of candidates
    let s:default_priorities = {}
    let s:default_priorities.line_head = {'functions' :  4, 'commands' :  6, 'variables' :  5, 'macros' :  3, 'graphic_properties' : -1, 'files' : -1}
    let s:default_priorities.argument  = {'functions' :  5, 'commands' : -1, 'variables' :  6, 'macros' :  4, 'graphic_properties' : -1, 'files' : -1}
    let s:default_priorities.lhs       = {'functions' :  5, 'commands' : -1, 'variables' :  6, 'macros' :  4, 'graphic_properties' : -1, 'files' : -1}
    let s:default_priorities.rhs       = {'functions' :  6, 'commands' :  3, 'variables' :  4, 'macros' :  5, 'graphic_properties' : -1, 'files' : -1}
    let s:default_priorities.li_lhs    = {'functions' :  5, 'commands' : -1, 'variables' :  6, 'macros' :  4, 'graphic_properties' : -1, 'files' : -1}
    let s:default_priorities.li_rhs    = {'functions' :  6, 'commands' : -1, 'variables' :  4, 'macros' :  5, 'graphic_properties' : -1, 'files' : -1}

    let g:scilabcomplete_candidate_priorities = get(g:, "scilabcomplete_candidate_priorities", s:default_priorities)

    " Preparing ProcessManager module from vital.vim
    let s:V  = vital#of('scilabcomplete')
    let s:PM = s:V.import('ProcessManager')
    if !s:PM.is_available()
        " If vimproc is not available, then quit immediately.
        echohl WarningMsg
        echo 'scilabcomplete : vimproc is not available!'
        echohl NONE
        return
    endif

    " Path to temporary file to use as a alias of script.
    let g:scilabcomplete_tmpfile     = get(g:, "scilabcomplete_tmpfile", tempname())

    let b:scilabcomplete_initialized = 1
endfunction
"}}}

" Serch for the user configuration from g: scope and b:scope.
function! scilabcomplete#get_user_conf(name)    "{{{
    if exists('g:' . a:name)
        execute "let user_conf = g:" . a:name
    endif

    if exists('w:' . a:name)
        execute "let user_conf = w:" . a:name
    endif

    if exists('b:' . a:name)
        execute "let user_conf = b:" . a:name
    endif

    return user_conf
endfunction
"}}}

" Execute Scilab command to return the number of prompts which succeeded to sending.
function! scilabcomplete#run_command(name, msg, prompts)  "{{{
    call s:PM.writeln(a:name, a:msg)
    for prompt in a:prompts
        call s:PM.writeln(a:name, "mfprintf(6, '" . prompt . "')")
    endfor
endfunction
"}}}

" Read out the output from scilab console.
function! scilabcomplete#read_out(name, prompts)    "{{{
    let output  = ['', '', '']
    let l:count = 0
    while l:count < 100
        let output = s:PM.read(a:name, a:prompts)
        if output[2] =~# "matched"
            break
        endif

        let l:count += 1
        sleep 10m
    endwhile
    return output
endfunction
"}}}

" Context recognition
function! s:recognize_context(base, row, col, line)   "{{{
    let base         = a:base
    let cursor_row   = a:row
    let cursor_col   = a:col - 2
    let whole_line   = a:line
    let until_cursor = whole_line[0:cursor_col]

    " for continuation lines
    let increment = 1
    while 1
        let previous_line = matchstr(getline(cursor_row-increment), '^.*\ze\.\.\s*$')
        if previous_line != ''
            let until_cursor = previous_line . until_cursor
            let whole_line   = previous_line . whole_line
        else
            break
        endif

        let increment += 1
    endwhile

    let increment = 1
    while 1
        if match(whole_line, '\s*\.\.\s*$') >= 0
            let next_line  = matchstr(getline(cursor_row+increment), '^.*\ze\.\.\s*')
            let whole_line = whole_line . next_line
        else
            break
        endif

        let increment += 1
    endwhile
    unlet increment

    echomsg until_cursor

    if match(until_cursor, '^\s*\k*$') >= 0
        " line head or lhs
        echomsg 'line head or lhs'
        return 'line_head'
    endif

    let paren_start = match(until_cursor, '\k\+\zs(\%([^()]*([^()]*)\)*[^()]*' . base . '$')
    if paren_start > 0
        let paren_inside = matchstr(whole_line[paren_start :], '^(\%([^()]*([^()]*)\)*[^()]*' . base . '[^()]*\%(([^()]*)[^()]*\)*)')

        " take into account logical index
        let operator_pos  = match(paren_inside, '^(\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')
        let operator_pos += paren_start

        if operator_pos < paren_start
            " argument
            echomsg 'argument'
            return 'argument'
        elseif cursor_col < operator_pos
            " logical index lhs
            echomsg 'logical index lhs'
            return 'li_lhs'
        else
            " logical index rhs
            echomsg 'logical index rhs'
            return 'li_rhs'
        endif
        return
    endif

    let operator_pos = match(whole_line, '^\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')
    if operator_pos < 0
        " take into account lhs after '||', '&&'
        let operator_pos = match(whole_line, '\%(||\|&&\)\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')
    endif

    if operator_pos < 0 || cursor_col < operator_pos
        " lhs
        echomsg 'lhs'
        return 'lhs'
    else
        " rhs
        echomsg 'rhs'
        return 'rhs'
    endif
endfunction
"}}}

" Return vital object.
function! scilabcomplete#vital_module(arg) "{{{
    if a:arg == ''
        return [s:V, s:PM]
    elseif a:arg == 'V'
        return s:V
    elseif a:arg == 'PM'
        return s:PM
    endif
endfunction
"}}}

