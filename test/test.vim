" vim:set foldmethod=marker:
" vim:set commentstring="%s:
" Last Change: 18-Nov-2013.

" ‚È‚ºnormal!‚Å‚Í‚È‚­ƒ}ƒNƒ‚ðŽg‚Á‚½‚Ì‚©‚Æ‚¢‚¤‚Æ‚»‚Á‚¿‚Ì•û‚ª‚¿‚ç‚¿‚ç‚µ‚ÄD‚«‚¾
" ‚©‚ç‚Å‚·I
"
" TODO: s:run_testmacro, s:copy_result, s:judge‚ð‚Ü‚Æ‚ß‚½ƒ‰ƒbƒvŠÖ”‚ðì‚é
" TODO: search‚ªŽ¸”s‚µ‚½ê‡‚ÉŒx‚Å‚«‚é‚æ‚¤‚É‚µ‚Ä‚­‚ê
" TODO: test_info‚Éon/off—p‚ÌƒvƒƒpƒeƒB‚ð’Ç‰Á
" TODO: touch_quit_info‚ÌŽd—l‚ª‹C‚É“ü‚ç‚È‚¢...
" TODO: ƒfƒoƒbƒO—p‚É‚àƒƒO“f‚­êŠ‚ª‚ ‚é‚Æ‚¢‚¢‚È‚ ‚Á‚Ä
" TODO: s:minimum_header_width‚Ìˆµ‚¢‚É‚Â‚¢‚ÄBa:pos =~# '\d\+-\d\+'‚Ì•Ó‚è
" TODO: ªƒ[ƒJƒ‹‚È’l‚É‚µ‚æ‚¤‚©‚È
" TODO: s:insert_header_template(dict, pos)‚ÌƒL[‘¶ÝŠm”F‚ÍÁ‚·

" Test information"{{{
" Test 1
let test_info   = {}
let test_info.general = { 'commentstring' : '^\s*// ', 'header_test' : 'Test', 'header_result' : 'Result', 'header_expectation' : 'Expectation', 'minimum_header_width' : 15 }
let test_info.pre     = { 'breaking' : 1 }
let test_info.0       = {
    \   "pre"  : { 'breaking' : 0 },
    \   "1"    : { 'header' : 'environment', 'result' : 's:check_environment()', 'expectation' : '0', 'macro' : '', 'breaking' : 0, 'abort' : 1, 'pre' : {}, 'post' : {} },
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   "post" : { 'breaking' : 1}
    \   }
let test_info.1       = {
    \   "pre"  : { 'breaking' : 0 },
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   "1"    : { 'header' : 'functions',   'result' : 'getline(".")', 'expectation' : 'functions = getversion();', 'macro' : 'A();'        , 'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "2"    : { 'header' : 'variables',   'result' : 'getline(".")', 'expectation' : 'variables = SCIHOME;',      'macro' : 'A;'          , 'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "3"    : { 'header' : 'macros',      'result' : 'getline(".")', 'expectation' : 'macros = sind(90);',        'macro' : 'A(90);', 'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "4"    : { 'header' : 'commands',    'result' : 'getline(".")', 'expectation' : 'clear',                     'macro' : 'A'         , 'breaking' : 0, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "post" : { 'breaking' : 6 },
    \   }
let test_info.2       = {
    \   "pre"  : { 'breaking' : 0 , 'commands' : 'UpdateWorkspace'},
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   "1"    : { 'header' : 'number',         'result' : 'getline(".")', 'expectation' : 'Sodium    = Hydrogen.',                 'macro' : '3xA',     'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "2"    : { 'header' : 'matrix',         'result' : 'getline(".")', 'expectation' : 'Sodium    = Halogen(1, 1).',            'macro' : '3xA',     'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "3"    : { 'header' : 'cell variables', 'result' : 'getline(".")', 'expectation' : 'Sodium    = AlkaliMetal(1, 1).entries', 'macro' : '3xA',   'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "4"    : { 'header' : 'cell variables', 'result' : 'getline(".")', 'expectation' : 'Potassium = AlkaliMetal(1, 2).entries', 'macro' : '3xA',     'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "5"    : { 'header' : 'struct',         'result' : 'getline(".")', 'expectation' : 'Helium    = RareGas.Ar',                'macro' : '3xA', 'breaking' : 0, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "post" : { 'breaking' : 4 },
    \   }
let test_info.3        = {
    \   "pre"  : { 'breaking' : 0 },
    \   "line" : { 'char' : '-', 'width' : 50 },
    \   "1"    : { 'header' : 'graphic properties', 'result' : 'getline(".")', 'expectation' : 'graphic_handle.UID',            'macro' : '3xA', 'breaking' : 1, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "2"    : { 'header' : 'graphic properties', 'result' : 'getline(".")', 'expectation' : 'graphic_handle.polyline_style', 'macro' : '3xA', 'breaking' : 0, 'abort' : 0, 'pre' : {}, 'post' : {} },
    \   "post" : { 'breaking' : 1 },
    \   }
let test_info.post     = { 'breaking' : 0 }
"}}}

" define Required functions"{{{
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
    let s:header_test          = 'Test'
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
    hi! link ScilabCompleteTestAbort      DiffChange
    hi! link ScilabCompleteTestBad        SpellBad
    hi! link ScilabCompleteTestCap        SpellCap
    return 0
endfunction
"}}}
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
function! s:generate_header(draft)  "{{{
    let draft_width = len(a:draft)
    let spacing = s:minimum_header_width - draft_width

    if spacing > 0
        let header = a:draft
        let idx = 0
        while idx < spacing
            let header = header . " "
            let idx += 1
        endwhile
    elseif spacing < 0
        let header = a:draft[:spacing]
    endif
    let header = header . ": "

    return header
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
        let header = s:generate_header(s:header_result)
        execute "normal! o" . header

        let header = s:generate_header(s:header_expectation)
        execute "normal! o" . header . a:dict.expectation
        if  has_key(a:dict, 'breaking')
            if type(a:dict.breaking) == type(0) && a:dict.breaking > 0
                execute "normal! " . a:dict.breaking . "o"
            endif
        endif
    elseif a:pos =~# '\d\+'
        execute "normal! o" . s:header_test . ' ' . a:pos
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
    call matchadd("ScilabCompleteTestComment",    '^\d\+-\d\+\ .*\ze:')
    call matchadd("ScilabCompleteTestUnderlined", '^' . s:header_result)
    call matchadd("ScilabCompleteTestUnderlined", '^' . s:header_expectation)

    normal! i   *** The result ***
    call s:insert_header_template(a:test_info, 'pre')

    let test_nrs    = s:S.sort(filter(keys(a:test_info), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
    for nr in test_nrs
        call s:insert_header_template(a:test_info.general, nr)
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
function! s:run_testmacro(header, macro)    "{{{
    execute s:scilab_script_nr . 'wincmd w'
    normal! gg

    call search(s:commentstring . a:header)
    normal! j0
    call setreg('q', a:macro)
    normal! @q
endfunction
"}}}
function! s:copy_result(header, result, quit_flag)   "{{{
    if a:quit_flag == 0
        execute s:scilab_script_nr . 'wincmd w'
        normal! gg

        call search(s:commentstring . a:header)
        normal! j0
        let final_result = eval(a:result)
        execute s:result_nr . 'wincmd w'
        normal! gg
        call search('^' . a:header)
        execute "normal! jA" . final_result
    endif
endfunction
"}}}
function! s:judge(header, quit_flag) "{{{
    let failed = [1]
    execute s:result_nr . 'wincmd w'
    normal! gg

    let matched_line       = search('^' . a:header)
    let result             = matchstr(getline(matched_line + 1), '^' . s:generate_header(s:header_result) . '\zs.*')
    let expectation        = matchstr(getline(matched_line + 2), '^' . s:generate_header(s:header_expectation) . '\zs.*')
    if a:quit_flag > 0
        normal! AAbort
        call matchadd("ScilabCompleteTestAbort", a:header . ' *: \zs.*')
    elseif result ==# expectation
        let failed = [0]
        normal! APassed
        call matchadd("ScilabCompleteTestPassed", a:header . ' *: \zs.*')
    else
        normal! AFailed
        call matchadd("ScilabCompleteTestFailed", a:header . ' *: \zs.*')
        let pos = 0
        while pos <= len(result)
            let c_res = result[pos]
            let c_exp = expectation[pos]
            if c_res !=# c_exp
                break
            endif
            let pos += 1
        endwhile
        call matchadd("ScilabCompleteTestBad", '\%' . printf("%s", matched_line + 1) . 'l\%' . printf("%s", pos + len(s:header_result) + 1) . 'c\zs.*')
        call matchadd("ScilabCompleteTestCap", '\%' . printf("%s", matched_line + 2) . 'l\%' . printf("%s", pos + len(s:header_expectation) + 1) . 'c\zs.*')
    endif

    return failed
endfunction
"}}}
function! s:disassemble_test_info(dict, nr, sub_nr)    "{{{
    let header = a:nr . '-' . a:sub_nr . ' ' . a:dict.header
    let result = a:dict.result
    let macro  = a:dict.macro
    let abort  = a:dict.abort

    return [header, result, macro, abort]
endfunction
"}}}
function! s:run_command_in_test(dict)   "{{{
    execute s:scilab_script_nr . 'wincmd w'

    let failed = []
    if has_key(a:dict, 'commands')
        if type(a:dict.commands) == type('')
            if a:dict.commands[0] == ":"
                let command = a:dict.commands
            else
                let command = ":" . a:dict.commands
            endif

            if exists(command)
                execute a:dict.commands
                call add(failed, 0)
            else
                call add(failed, 1)
            endif
        elseif type(a:dict.commands) == type([])
            let failed = []
            for command in a:dict.commands
                if command[0] != ":"
                    let command = ":" . command
                endif

                if exists(command)
                    execute a:dict.commands
                    call add(failed, 0)
                else
                    call add(failed, 1)
                endif
            endfor
        endif
    endif
    return failed
endfunction
"}}}
function! s:touch_quit_info(quit_info, failed, pos, abort)  "{{{
    let quit_info = deepcopy(a:quit_info)

    if a:quit_info.flag == 0
        if a:pos ==# 'pre' || a:pos ==# 'post'
            if !empty(filter(a:failed, 'v:val != 0'))
                let quit_info.failed   = a:failed
                let quit_info.position = a:pos
                let quit_info.flag     = 1
            endif
        elseif a:pos ==# 'test'
            if and(a:abort, a:failed[0])
                let quit_info.failed   = a:failed
                let quit_info.position = a:pos
                let quit_info.flag     = 1
            endif
        endif
    endif
    return quit_info
endfunction
"}}}
function! s:test_main_func(test_info)   "{{{
    let quit_info = { 'flag' : 0,  'nr' : -1, 'sub_nr' : -1, 'failed' : [], 'position' : ''}
    let failed = []

    let failed    = s:run_command_in_test(a:test_info.pre)
    let quit_info = s:touch_quit_info(quit_info, failed, 'pre', 1)

    if quit_info.flag == 0
        let nrs    = s:S.sort(filter(keys(a:test_info), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
        for nr in nrs
            let quit_info.nr = nr
            let failed       = s:run_command_in_test(a:test_info[nr].pre)
            let quit_info    = s:touch_quit_info(quit_info, failed, 'pre', 1)

            let sub_nrs = s:S.sort(filter(keys(a:test_info[nr]), 'v:val =~ ''\d\+'''), 'str2nr(a:a) - str2nr(a:b)')
            for sub_nr in sub_nrs
                let quit_info.sub_nr = sub_nr
                let failed    = s:run_command_in_test(a:test_info[nr][sub_nr].pre)
                let quit_info = s:touch_quit_info(quit_info, failed, 'pre', 1)

                let info   = s:disassemble_test_info(a:test_info[nr][sub_nr], nr, sub_nr)
                let header = info[0]
                let result = info[1]
                let macro  = info[2]
                let abort  = info[3]
                unlet info

                call s:run_testmacro(header, macro)
                call s:copy_result(header, result, quit_info.flag)
                let failed    = s:judge(header, quit_info.flag)
                let quit_info = s:touch_quit_info(quit_info, failed, 'test', abort)

                let failed    = s:run_command_in_test(a:test_info[nr][sub_nr].post)
                let quit_info = s:touch_quit_info(quit_info, failed, 'post', 1)
            endfor

            let quit_info.sub_nr = -1
            let failed    = s:run_command_in_test(a:test_info[nr].post)
            let quit_info = s:touch_quit_info(quit_info, failed, 'post', 1)
        endfor

        let quit_info.nr = -1
        let failed    = s:run_command_in_test(a:test_info.post)
        let quit_info = s:touch_quit_info(quit_info, failed, 'post', 1)
    endif
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
