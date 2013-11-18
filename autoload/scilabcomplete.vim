" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 17-Nov-2013.

" 頑張りたいと思う
" TODO: キャッシングできたほうが嬉しい
"       -> キャッシュ前とキャッシュ後で時間差を測る
" TODO: :UpdateWorkSpaceコマンドの追加
" TODO: テストを書く
" TODO: prioritiesの生成関数
" TODO: ユーティリティ関数の追加
" TODO: 表示形式の改良
" TODO: ブランチ切ってvitalの改造

" Completion function
function! scilabcomplete#Complete(findstart, base)  "{{{
    " 1st run   "{{{
    if a:findstart
        let s:cursor  = col(".")
        let s:line = getline(".")
        let pos = s:cursor

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
                    let pos = -3
                else
                endif
                break
            endif
        endwhile
        return pos
    endif
    "}}}
    " 2nd run   "{{{

    " Initialization of miscellaneous variables
    let candidates = []
    let output     = []
    let word       = s:parse_struct_name(a:base, s:line, s:cursor)
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
            let scilabcomplete_files              = filter(split(substitute(matchstr(output[0],           ' scilabcomplete_files  =\r\n \r\n *\zs.*\ze scilabcomplete_gp  ='),            '[! ]\(\f*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let scilabcomplete_graphic_properties = filter(split(substitute(matchstr(output[0],          ' scilabcomplete_gp  =\r\n \r\n *\zs.*\ze scilabcomplete_macros  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let scilabcomplete_macros             = filter(split(substitute(matchstr(output[0],   ' scilabcomplete_macros  =\r\n \r\n *\zs.*\ze scilabcomplete_variables  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let scilabcomplete_variables          = filter(split(substitute(matchstr(output[0], ' scilabcomplete_variables  =\r\n \r\n *\zs.*\ze scilabcomplete_commands  ='), '[! ]\([a-za-z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let scilabcomplete_commands           = filter(split(substitute(matchstr(output[0], ' scilabcomplete_commands  =\r\n \r\n *\zs.*\ze scilabcomplete_functions  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
            let scilabcomplete_functions          = filter(split(substitute(matchstr(output[0],                               ' scilabcomplete_functions  =\r\n \r\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')

            let candidate_priorities = s:priorities_dict_gen(b:scilabcomplete_candidate_priorities)
            let priorities_list = values(candidate_priorities)
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

" Initialization of required buffer local variables.
function! scilabcomplete#Initialization()   "{{{
    " Process name for use of process manager
    let b:scilabcomplete_process_name = get(g:, "scilabcomplete_process_name", "scilab")
    " Command to start scilab
    if has("win32") || has("win64")
        let b:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilex"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    else
        let b:scilabcomplete_startup_command = printf("%s %s", get(g:, "scilabcomplete_scilab_command", "scilab"), get(g:, "scilabcomplete_scilab_cmdopt", "-nb -nw -l en"))
    endif
    " Prompt of Scilab console
    let b:scilabcomplete_console_prompts = get(g:, "scilabcomplete_scilab_prompt", ['-->'])
    " The way to determine the priorities of each kinds of candidates
    let b:scilabcomplete_candidate_priorities = get(g:, "scilabcomplete_candidate_priorities", {'functions' : 5, 'commands' : 4, 'variables' : 3, 'macros' : 2, 'graphic_properties' : 1, 'files' : 6})

    " Preparing ProcessManager module from vital.vim
    let b:V  = vital#of('scilabcomplete')
    let b:PM = b:V.import('ProcessManager')
    if !b:PM.is_available()
        " If vimproc is not available, then quit immediately.
        echohl WarningMsg
        echo 'scilabcomplete : vimproc is not available!'
        echohl NONE
        return
    endif

    " Full path of the script.
    let b:scilabcomplete_script_path = expand("%:p")
    " Path to temporary file to use as a alias of script.
    let b:scilabcomplete_tmpfile     = get(b:, "scilabcomplete_tmpfile", tempname())
    " Path to temporary file storing the error message.
    let b:scilabcomplete_errorfile   = get(b:, "scilabcomplete_errorfile", tempname())
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
                if type == type(function("tr"))
                    let candidate_priorities[key] = prototype[key]()
                else
                    let candidate_priorities[key] = 0
                endif
            else
                let candidate_priorities[key] = prototype[key]
            endif
        endfor

        let candidate_priorities = filter(candidate_priorities, 'v:val > 0')
    elseif type(a:arg) == type(function("tr"))
        let candidate_priorities = a:arg()
    endif

    return candidate_priorities
endfunction
"}}}

" Execute Scilab command to return the number of prompts which succeeded to sending.
function! scilabcomplete#run_command(name, msg, prompts)  "{{{
    let success = 0
    if b:PM.writeln(a:name, a:msg) =~# 'active'
        let success = 0
        for prompt in a:prompts
            if b:PM.writeln(a:name, "mfprintf(6, '" . prompt . "')") =~# 'active'
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
        let output = b:PM.read(a:name, a:prompts)
        if output[2] =~# "matched"
            break
        endif
        sleep 10m
    endwhile
    return output
endfunction
"}}}

" Keyword dictionary creation.
function! s:dictionary_creation(name, prompts)  "{{{
    let candidates = []
    let msg     = "[scilabcomplete_functions, scilabcomplete_commands, scilabcomplete_variables, scilabcomplete_macros, scilabcomplete_gp, scilabcomplete_files] = completion('')"
    let success = scilabcomplete#run_command(a:name, msg, a:prompts)
    if success == len(a:prompts)
        let output = scilabcomplete#read_out(a:name, a:prompts)

        " Parsing the output
        let scilabcomplete_files              = filter(split(substitute(matchstr(output[0],           ' scilabcomplete_files  =\r\n \r\n *\zs.*\ze scilabcomplete_gp  ='),            '[! ]\(\f*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_graphic_properties = filter(split(substitute(matchstr(output[0],          ' scilabcomplete_gp  =\r\n \r\n *\zs.*\ze scilabcomplete_macros  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_macros             = filter(split(substitute(matchstr(output[0],   ' scilabcomplete_macros  =\r\n \r\n *\zs.*\ze scilabcomplete_variables  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_variables          = filter(split(substitute(matchstr(output[0], ' scilabcomplete_variables  =\r\n \r\n *\zs.*\ze scilabcomplete_commands  ='), '[! ]\([a-za-z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_commands           = filter(split(substitute(matchstr(output[0], ' scilabcomplete_commands  =\r\n \r\n *\zs.*\ze scilabcomplete_functions  ='), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')
        let scilabcomplete_functions          = filter(split(substitute(matchstr(output[0],                               ' scilabcomplete_functions  =\r\n \r\n *\zs.*'), '[! ]\([a-zA-Z0-9_%]*\) *!\?\r', '\1', "g"), '\n'), 'v:val =~# ''[a-zA-Z0-9_%]\+''')

        let key_list = ['functions', 'commands', 'variables', 'macros', 'graphic_properties', 'files']
        for key in key_list
            execute "let list = scilabcomplete_" . key
            if key == "files"
                let kind = "F"
            else
                let kind = key[0]
            endif

            for candidate in list
                call add(candidates, {"word" : candidate, "kind" : kind})
            endfor
        endfor

        return candidates
    else
        return 0
    endif
endfunction
"}}}
