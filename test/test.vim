" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 17-Nov-2013.



" Test information"{{{
" Test 1
let test_info   = {}
let test_info.pre = { 'breaking' : 1 }
let test_info.0   = {
    \   "1"    : { 'header' : 'environment', 'result' : 's:check_environment()', 'expectation' : '0', 'macro' : '', 'breaking' : 0},
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   "post" : { 'breaking' : 1}
    \   }
let test_info.1   = {
    \   "1"    : { 'header' : 'functions',   'result' : 'getline(search(s:commentstring . idx_header) + 1)', 'expectation' : 'functions = getversion();', 'macro' : 'A();'         , 'breaking' : 1 },
    \   "2"    : { 'header' : 'variables',   'result' : 'getline(search(s:commentstring . idx_header) + 1)', 'expectation' : 'variables = SCIHOME;',      'macro' : 'A;'           , 'breaking' : 1 },
    \   "3"    : { 'header' : 'macros',      'result' : 'getline(search(s:commentstring . idx_header) + 1)', 'expectation' : 'macros = sind(90);',        'macro' : 'A(90);' , 'breaking' : 1 },
    \   "4"    : { 'header' : 'commands',    'result' : 'getline(search(s:commentstring . idx_header) + 1)', 'expectation' : 'clear',                     'macro' : 'A'          , 'breaking' : 0 },
    \   "pre"  : { 'breaking' : 0 },
    \   "post" : { 'breaking' : 1 },
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   }
"}}}

" define Required functions"{{{
function! s:lock_autocomplete_plugin()  "{{{
    let locked_plugin = []
    if exists(':NeoCompleteLock')
        NeoCompleteLock
        call add(locked_plugin, "neocomplete")
    endif

    if exists(':NeoComplCacheLock')
        NeoComplCacheLock
        call add(locked_plugin, "neocomplcache")
    endif

    if exists(':AcpLock')
        AcpLock
        call add(locked_plugin, "AutoComplPop")
    endif
    return locked_plugin
endfunction
"}}}
function! s:buffer_configuration()  "{{{
    if expand("%") == ""
        if filereadable("test.sci")
            setlocal noswapfile
            lcd %:p:h
            edit test.sci
        else
            return 1
        endif
    elseif expand("%:t") == "test.sci"
        lcd %:h
    else
        return 1
    endif
    let s:completeopt = &completeopt
    set completeopt=menuone
    setlocal ft=scilab
    setlocal omnifunc=scilabcomplete#Complete
    setlocal nohlsearch
    setlocal nowrapscan
    setlocal scrollbind
    let s:scilab_script_nr     = winnr()
    let s:commentstring        = '^\s*// '
    let s:header_result        = 'Result'
    let s:header_expectation   = 'Expectation'
    let s:minimum_header_width = 15
    if s:minimum_header_width < max([len(s:header_result), len(s:header_expectation)])
        s:minimum_header_width = max([len(s:header_result), len(s:header_expectation)]) + 1
    endif
    let s:header_test_nr       = 'Test'
    " save the containts of registers
    let s:reg_q     = getreg('q')
    let s:reg_slash = getreg("/")
    " Preparing ProcessManager module from vital.vim
    if !exists('s:V')
        let s:V  = vital#of('scilabcomplete')
        let s:PM = s:V.import('ProcessManager')
        let s:S  = s:V.import("Data.List")
    endif
    let s:locked_plugin = s:lock_autocomplete_plugin()
    " Highlighting settings
    hi! link ScilabCompleteTestComment    Comment
    hi! link ScilabCompleteTestUnderlined Underlined
    hi! link ScilabCompleteTestPassed     Diffadd
    hi! link ScilabCompleteTestFailed     DiffDelete
    hi! link ScilabCompleteTestBad        SpellBad
    hi! link ScilabCompleteTestCap        SpellCap
    return 0
endfunction
"}}}
function! s:disassemble_test_info(test_info)    "{{{
    let headers = []
    let results = []
    let macros  = []
    let test_nrs    = s:S.sort(filter(keys(a:test_info), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
    for nr in test_nrs
        let test_sub_nrs = s:S.sort(filter(keys(a:test_info[nr]), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
        for sub_nr in test_sub_nrs
            call add(headers, nr . '-' . sub_nr . ' ' . a:test_info[nr][sub_nr]['header'])
            call add(results, a:test_info[nr][sub_nr]['result'])
            call add( macros, a:test_info[nr][sub_nr]['macro'])
        endfor
    endfor
    return [headers, results, macros]
endfunction
"}}}
function! s:insert_header_template(dict, pos) "{{{
    if a:pos ==# 'pre'
        if has_key(a:dict, 'pre')
            if has_key(a:dict.pre, 'header')
                if has_key(a:dict.pre, 'header')
                    if type(a:dict.pre.header) == type('')
                        execute "normal! o" . a:dict.pre.header
                        call matchadd("ScilabCompleteTestComment", '\%' . line('.') . 'l')
                    elseif type(a:dict.pre.header) == type([])
"                         don't know why, but it didn't works
"                         call append(line('.'), a:dict.pre.header)
                        for line in a:dict.pre.header
                            execute "normal! o" . line
                            call matchadd("ScilabCompleteTestComment", '\%' . line('.') . 'l')
                        endfor
                    endif
                endif
            endif
            if has_key(a:dict.pre, 'breaking')
                if a:dict.pre.breaking > 0
                    if type(a:dict.pre.breaking) == type(0) && a:dict.pre.breaking > 0
                        execute "normal! " . a:dict.pre.breaking . "o"
                    endif
                endif
            endif
        endif
    elseif a:pos ==# 'post'
        if has_key(a:dict, 'post')
            if has_key(a:dict.post, 'header')
                if has_key(a:dict.post, 'header')
                    if type(a:dict.post.header) == type('')
                        execute "normal! o" . a:dict.post.header
                        call matchadd("ScilabCompleteTestComment", '\%' . line('.') . 'l')
                    elseif type(a:dict.post.header) == type([])
                        for line in a:dict.post.header
                            execute "normal! o" . line
                            call matchadd("ScilabCompleteTestComment", '\%' . line('.') . 'l')
                        endfor
                    endif
                endif
            endif
            if  has_key(a:dict.post, 'breaking')
                if type(a:dict.post.breaking) == type(0) && a:dict.post.breaking > 0
                    execute "normal! " . a:dict.post.breaking . "o"
                endif
            endif
        endif
    elseif a:pos ==# 'line'
        normal! o
        execute "normal! " . printf("%s", a:dict.line.width) . "i" . printf("%s", a:dict.line.char)
        call matchadd("ScilabCompleteTestComment", '^' . a:dict.line.char . '\{' . a:dict.line.width . '}')
    elseif a:pos =~# '\d\+-\d\+'
        let header_width = len(a:pos . " " . a:dict.header)
        execute "normal! o" . a:pos . " " . a:dict.header
        if header_width < s:minimum_header_width
            let spacing = s:minimum_header_width - header_width
            execute "normal! " . spacing . "a "
        endif
        normal! a: 
    elseif a:pos ==# 'res_exp'
        execute "normal! o" . s:header_result
        let header_width = len(s:header_result)
        let spacing = s:minimum_header_width - header_width
        execute "normal! " . spacing . "a "
        normal! a: 
        execute "normal! o" . s:header_expectation
        let header_width = len(s:header_expectation)
        let spacing = s:minimum_header_width - header_width
        execute "normal! " . spacing . "a "
        execute "normal! a: " . a:dict.expectation
        if  has_key(a:dict, 'breaking')
            if type(a:dict.breaking) == type(0) && a:dict.breaking > 0
                execute "normal! " . a:dict.breaking . "o"
            endif
        endif
    elseif a:pos =~# '\d\+'
        execute "normal! o" . s:header_test_nr . ' ' . a:pos
        call matchadd("ScilabCompleteTestComment", '\%' . line('.') . 'l')
    endif
endfunction
"}}}
function! s:expand_result_buffer_template(test_info)    "{{{
    execute s:scilab_script_nr . 'wincmd w'
    normal! gg
    vert new
    setlocal scrollbind
    setlocal noautoindent
    setlocal nosmartindent
    setlocal nocindent
    let s:result_nr = winnr()
    call matchadd("ScilabCompleteTestComment",    '\%1l')
    call matchadd("ScilabCompleteTestComment",    '^\d\+-\d\+\ \w*\ze')
    call matchadd("ScilabCompleteTestUnderlined", '^' . s:header_result)
    call matchadd("ScilabCompleteTestUnderlined", '^' . s:header_expectation)

    normal! i   *** The result ***
    call s:insert_header_template(a:test_info, 'pre')

    let test_nrs    = s:S.sort(filter(keys(a:test_info), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
    for nr in test_nrs
        call s:insert_header_template(a:test_info[nr], nr)
        call s:insert_header_template(a:test_info[nr], 'pre')
        call s:insert_header_template(a:test_info[nr], 'line')

        let test_sub_nrs = s:S.sort(filter(keys(a:test_info[nr]), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
        for sub_nr in test_sub_nrs
            call s:insert_header_template(a:test_info[nr][sub_nr], nr . '-' . sub_nr)
            call s:insert_header_template(a:test_info[nr][sub_nr], 'res_exp')
        endfor
        call s:insert_header_template(a:test_info[nr], 'line')
        call s:insert_header_template(a:test_info[nr], 'post')
    endfor
    call s:insert_header_template(a:test_info, 'post')
endfunction
"}}}
function! s:check_environment() "{{{
    execute s:scilab_script_nr . 'wincmd w'
    if !s:PM.is_available()
        " If vimproc is not available, then returns 1
        return 1
    else
        return 0
    endif
    " Do I need to check any other things?
    " If I found, then I would add... Maybe...
endfunction
"}}}
function! s:run_testmacro(test_headers, test_macros)    "{{{
    execute s:scilab_script_nr . 'wincmd w'
    normal! gg

    let idx = 0
    for header in a:test_headers
        call search(s:commentstring . header)
        normal! j0
        call setreg('q', a:test_macros[idx])
        normal! @q
        let idx += 1
    endfor
endfunction
"}}}
function! s:copy_result(test_headers, test_results)   "{{{
    execute s:scilab_script_nr . 'wincmd w'
    normal! gg

    let result_list = []
    let idx = 0
    for idx_header in a:test_headers
        call add(result_list, eval(a:test_results[idx]))
        let idx += 1
    endfor
    execute s:result_nr . 'wincmd w'
    normal! gg
    let idx = 0
    for header in a:test_headers
        call search('^' . header)
        execute "normal! jA" . result_list[idx]
        let idx += 1
    endfor
endfunction
"}}}
function! s:judge(test_headers) "{{{
    execute s:result_nr . 'wincmd w'
    normal! gg

    for header in a:test_headers
        let Result_header      = 'Result         : '
        let Expectation_header = 'Expectation    : '
        let matched_line       = search('^' . header)
        let Result             = matchstr(getline(matched_line + 1), '^' . Result_header . '\zs.*')
        let Expectation        = matchstr(getline(matched_line + 2), '^' . Expectation_header . '\zs.*')
        let offset_Res         = len(Result_header)
        let offset_Exp         = len(Expectation_header)
        if Result ==# Expectation
            normal! APassed
            call matchadd("ScilabCompleteTestPassed", header . ' *: \zs.*')
        else
            normal! AFailed
            call matchadd("ScilabCompleteTestFailed", header . ' *: \zs.*')
            let pos = 0
            while pos <= len(Result)
                let c_Res = Result[pos]
                let c_Exp = Expectation[pos]
                if c_Res !=# c_Exp
                    break
                endif
                let pos += 1
            endwhile
            call matchadd("ScilabCompleteTestBad", '\%' . printf("%s", matched_line + 1) . 'l\%' . printf("%s", pos + offset_Res + 1) . 'c\zs.*')
            call matchadd("ScilabCompleteTestCap", '\%' . printf("%s", matched_line + 2) . 'l\%' . printf("%s", pos + offset_Exp + 1) . 'c\zs.*')
        endif
    endfor
endfunction
"}}}
function! s:test_main_func(test_info)   "{{{
    let info = s:disassemble_test_info(a:test_info)
    let test_headers = info[0]
    let test_results = info[1]
    let test_macros  = info[2]
    unlet info

    " Test 0
    if s:check_environment()
        return
    endif

    " Test 1
    call s:run_testmacro(test_headers, test_macros)
    call s:copy_result(test_headers, test_results)
    call s:judge(test_headers)
endfunction
"}}}
function! s:restore_global_settings()   "{{{
    " Restore global options
    let &completeopt = s:completeopt
    " Restore registers
    let reg_q     = setreg('q', s:reg_q)
    let reg_slash = setreg("/", s:reg_slash)
    " Restore plugin settings
    for name in s:locked_plugin
        if name ==# "neocomplete"
            NeoCompleteUnlock
        endif

        if name ==# "neocomplcache"
            NeoComplCacheUnlock
        endif

        if name ==# "Autocomplpop"
            AcpUnlock
        endif
    endfor
endfunction
"}}}
"}}}

" Testing!
" buffer configuration
if !s:buffer_configuration()
    " result buffer
    call s:expand_result_buffer_template(test_info)

    " Start test
    call s:test_main_func(test_info)

    " Finalize
    call s:restore_global_settings()
endif
