" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 25-Dec-2013.

" 頑張りたいと思う
" TODO: キャッシングできたほうが嬉しい
"       -> キャッシュ前とキャッシュ後で時間差を測る
" TODO: ブランチ切ってvitalの改造

" Completion function
function! scilabcomplete#Complete(findstart, base)  "{{{
    " 1st run   "{{{
    if a:findstart
        let s:col  = col(".")
        let s:row  = line(".")
        let s:line = getline(".")
        let pos = s:col

        while pos > 0
            let pos -= 1
            let c = s:line[pos-1]
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

        let s:pos = pos
        return pos
    endif
    "}}}
    " 2nd run   "{{{

    " Initialization of miscellaneous variables
    let candidates = []
    let output     = []
    let word       = s:parse_struct_name(a:base, s:line, s:col)
    let s:base     = a:base

    " If both word and a:base is empty, quit immediately.
    if word == "" && a:base == ""
        return []
    endif

    if !exists("b:scilabcomplete_initialized")
        " Initialization of configuration variables runs only one time.
        call scilabcomplete#Initialization()
    endif
    let name    = b:scilabcomplete_process_name
    let cmd     = b:scilabcomplete_startup_command
    let prompts = b:scilabcomplete_console_prompts

    " Communicate with scilab process
    call s:PM.touch(name, cmd)
    if word !=# a:base
        let msg = "scilabcomplete_ans = exists('" . word . "')"
        let success = scilabcomplete#run_command(name, msg, prompts)
        if success == len(prompts)
            let output = scilabcomplete#read_out(name, prompts)
            if matchstr(output[0], ' scilabcomplete_ans  =\r\n \r\n *\zs[01]\ze.')
                let msg     = "scilabcomplete_ans = type(" . word . ")"
                let success = scilabcomplete#run_command(name, msg, prompts)
                if success == len(prompts)
                    let output = scilabcomplete#read_out(name, prompts)
                    let type = matchstr(output[0], ' scilabcomplete_ans  =\r\n \r\n *\zs\d\+\ze.')
                    let fieldnames = []
                    if type =~# "17"
                        let kind    = "k"
                        let msg     = "scilabcomplete_ans = fieldnames(" . word . ")"
                        let success = scilabcomplete#run_command(name, msg, prompts)
                        if success == len(prompts)
                            let output = scilabcomplete#read_out(name, prompts)
                            let fieldnames = filter(split(substitute(matchstr(output[0], ' scilabcomplete_ans  =\r\n \r\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val !=# ""')
                            if !empty(a:base)
                                let fieldnames = filter(fieldnames, "v:val =~# '^" . a:base . ".*'")
                            endif
                        endif
                    elseif type =~# "9"
                        let kind    = "g"
                        let msg     = "scilabcomplete_gp = completion('" . a:base . "', 'graphic_properties')"
                        let success = scilabcomplete#run_command(name, msg, prompts)
                        if success == len(prompts)
                            let output = scilabcomplete#read_out(name, prompts)
                            let fieldnames = filter(split(substitute(matchstr(output[0], ' scilabcomplete_gp  =\r\n \r\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val !=# ""')
                        endif
                    endif
                    for key in fieldnames
                        call add(candidates, {"word" : key, "kind" : kind})
                    endfor
                endif
            endif
        endif
    else
        let msg     = "[scilabcomplete_functions, scilabcomplete_commands, scilabcomplete_variables, scilabcomplete_macros, scilabcomplete_gp, scilabcomplete_files] = completion('" . a:base . "')"
        let success = scilabcomplete#run_command(name, msg, prompts)
        if success == len(prompts)
            let output = scilabcomplete#read_out(name, prompts)

            " Parsing the output
            let s:scilabcomplete_files              = filter(split(substitute(matchstr(output[0],           ' scilabcomplete_files  =\r\n \r\n *\zs.*\ze scilabcomplete_gp  ='),            '[! ]\(\f*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let s:scilabcomplete_graphic_properties = filter(split(substitute(matchstr(output[0],          ' scilabcomplete_gp  =\r\n \r\n *\zs.*\ze scilabcomplete_macros  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let s:scilabcomplete_macros             = filter(split(substitute(matchstr(output[0],   ' scilabcomplete_macros  =\r\n \r\n *\zs.*\ze scilabcomplete_variables  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let s:scilabcomplete_variables          = filter(split(substitute(matchstr(output[0], ' scilabcomplete_variables  =\r\n \r\n *\zs.*\ze scilabcomplete_commands  ='), '[! ]\([a-za-z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let s:scilabcomplete_commands           = filter(split(substitute(matchstr(output[0], ' scilabcomplete_commands  =\r\n \r\n *\zs.*\ze scilabcomplete_functions  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let s:scilabcomplete_functions          = filter(split(substitute(matchstr(output[0],                               ' scilabcomplete_functions  =\r\n \r\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')

            let candidate_priorities = s:priorities_dict_gen(b:Scilabcomplete_candidate_priorities)
            let priorities_list = filter(values(candidate_priorities), 'v:val >= 0')
            while !empty(priorities_list)
                let key = s:matched_key(candidate_priorities, max(priorities_list))
                execute "let list = s:scilabcomplete_" . key
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
    endif

    return candidates
    "}}}
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
function! s:priorities_dict_gen(arg)    "{{{
    let candidate_priorities = {}

    if type(a:arg) == type({})
        let prototype = filter(a:arg, 'v:key =~# "functions" || v:key =~# "commands" || v:key =~# "variables" || v:key =~# "macros" || v:key =~# "graphic_properties" || v:key =~# "files"')
        let key_list = keys(prototype)

        for key in key_list
            let type = type(prototype[key])
            if type != type(0)
                let candidate_priorities[key] = 0
            else
                let candidate_priorities[key] = prototype[key]
            endif
        endfor

        let candidate_priorities = filter(candidate_priorities, 'v:val > 0')
    elseif type(a:arg) == type(function("tr"))
        let candidate_priorities = call(a:arg, [])
    endif

    return candidate_priorities
endfunction
"}}}

" Initialization of required buffer local variables.
function! scilabcomplete#Initialization()   "{{{
    " Process name for use of process manager
    let g:scilabcomplete_process_name = get(g:, "scilabcomplete_process_name", "scilab")
    let b:scilabcomplete_process_name = g:scilabcomplete_process_name
    " Command to start scilab
    if has("win32") || has("win64")
        let g:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilex"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    else
        let g:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilab"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    endif
    let b:scilabcomplete_startup_command = g:scilabcomplete_startup_command
    " Prompt of Scilab console
    let g:scilabcomplete_console_prompts = get(g:, "scilabcomplete_scilab_prompt", ['-->'])
    let b:scilabcomplete_console_prompts = g:scilabcomplete_console_prompts
    " The way to determine the priorities of each kinds of candidates
    let g:Scilabcomplete_candidate_priorities = get(g:, "scilabcomplete_candidate_priorities", function("scilabcomplete#default_priorities"))
    let b:Scilabcomplete_candidate_priorities = g:Scilabcomplete_candidate_priorities

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

    " Full path of the script.
    let b:scilabcomplete_script_path = expand("%:p")
    " Path to temporary file to use as a alias of script.
    let g:scilabcomplete_tmpfile     = get(g:, "scilabcomplete_tmpfile", tempname())
    let b:scilabcomplete_tmpfile     = g:scilabcomplete_tmpfile

    let b:scilabcomplete_initialized = 1
endfunction
"}}}

" Execute Scilab command to return the number of prompts which succeeded to sending.
function! scilabcomplete#run_command(name, msg, prompts)  "{{{
    let success = 0
    if s:PM.writeln(a:name, a:msg) =~# 'active'
        let success = 0
        for prompt in a:prompts
            if s:PM.writeln(a:name, "mfprintf(6, '" . prompt . "')") =~# 'active'
                let success = success + 1
            endif
        endfor
    endif
    return success
endfunction
"}}}

" Read out the output from scilab console.
function! scilabcomplete#read_out(name, prompts)    "{{{
    while 1
        " 安全策を入れる、エラー処理勉強して
        let output = s:PM.read(a:name, a:prompts)
        if output[2] =~# "matched"
            break
        endif
        sleep 10m
    endwhile
    return output
endfunction
"}}}

" Default priorities
function! scilabcomplete#default_priorities()   "{{{
    let base         = scilabcomplete#base()
    let cursor_row   = scilabcomplete#row()
    let cursor_col   = scilabcomplete#col() - 2
    let whole_line   = scilabcomplete#getline()
    let until_cursor = whole_line[0:cursor_col]
    let files        = scilabcomplete#candidates_files()

    " for continuation lines
    let increment = 1
    while 1
        let previous_line = getline(cursor_row-increment)
        if match(previous_line, '\s*\.\.\s*$') >= 0
            let previous_line = matchstr(previous_line, '^.*\ze\.\.\s*$')
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
        return {'functions' : 4, 'commands' : 6, 'variables' : 5, 'macros' : 3, 'graphic_properties' : -1, 'files' : -1}
    endif

    let paren_start = match(until_cursor, '\k\+\zs(\%([^()]*([^()]*)\)*[^()]*' . base . '$')
    if paren_start > 0
        let paren_inside = matchstr(whole_line[paren_start :], '^(\%([^()]*([^()]*)\)*[^()]*' . base . '[^()]*\%(([^()]*)[^()]*\)*)')

        " take into account logical index
        let operator_pos  = match(paren_inside, '^(\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')
        let operator_pos += paren_start

        if operator_pos < paren_start
            let base_len = len(base) - 1
            if base_len > 1
                for candidate in files
                    if base == candidate[0:base_len]
                        echomsg base
                        echomsg candidate[0:base_len]

                        " files
                        echomsg 'files'
                        return {'functions' : -1, 'commands' : -1, 'variables' : -1, 'macros' : -1, 'graphic_properties' : -1, 'files' : 6}
                    endif
                endfor
            endif

            " argument
            echomsg 'argument'
            return {'functions' : 5, 'commands' : -1, 'variables' : 6, 'macros' : 4, 'graphic_properties' : -1, 'files' : -1}
        elseif cursor_col < operator_pos
            " logical index lhs
            echomsg 'logical index lhs'
            return {'functions' : 5, 'commands' : -1, 'variables' : 6, 'macros' : 4, 'graphic_properties' : -1, 'files' : -1}
        else
            " logical index rhs
            echomsg 'logical index rhs'
            return {'functions' : 6, 'commands' : 3, 'variables' : 4, 'macros' : 5, 'graphic_properties' : -1, 'files' : -1}
        endif
        return
    endif

    let operator_pos = match(whole_line, '^\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')

    if operator_pos < 0
        " take into account lhs after '||', '&&'
        let operator_pos = match(whole_line, '\%(||\|&&\)\%([^'']*''[^'']*''\)*[^''~=<>]*\zs\%(\~=\|<>\|<=\|>=\|=\|<\|>\)')
    endif

    if operator_pos < 0 || s:col < operator_pos
        " lhs
        echomsg 'lhs'
        return {'functions' : 5, 'commands' : -1, 'variables' : 6, 'macros' : 4, 'graphic_properties' : -1, 'files' : -1}
    else
        " rhs
        echomsg 'rhs'
        return {'functions' : 6, 'commands' : -1, 'variables' : 4, 'macros' : 5, 'graphic_properties' : -1, 'files' : -1}
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

" Return the whole cursor line.
function! scilabcomplete#getline()  "{{{
    return s:line
endfunction
"}}}

" Return the present cursor row.
function! scilabcomplete#row()  "{{{
    return s:row
endfunction
"}}}

" Return the present cursor column.
function! scilabcomplete#col()  "{{{
    return s:col
endfunction
"}}}

" Return the position to start completion.
function! scilabcomplete#start_complete_pos()   "{{{
    return s:pos
endfunction
"}}}

" Return the base string of completion.
function! scilabcomplete#base() "{{{
    return s:base
endfunction
"}}}

" Return candidates list of files
function! scilabcomplete#candidates_files() "{{{
    return s:scilabcomplete_files
endfunction
"}}}

" Return candidates list of graphic properties
function! scilabcomplete#candidates_graphic_properties() "{{{
    return s:scilabcomplete_graphic_properties
endfunction
"}}}

" Return candidates list of macros
function! scilabcomplete#candidates_macros() "{{{
    return s:scilabcomplete_macros
endfunction
"}}}

" Return candidates list of variables
function! scilabcomplete#candidates_variables() "{{{
    return s:scilabcomplete_variables
endfunction
"}}}

" Return candidates list of commands
function! scilabcomplete#candidates_commands() "{{{
    return s:scilabcomplete_commands
endfunction
"}}}

" Return candidates list of functions
function! scilabcomplete#candidates_functions() "{{{
    return s:scilabcomplete_functions
endfunction
"}}}

