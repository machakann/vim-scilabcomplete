" buffer configuration
setl noswapfile
lcd %:p:h
edit test.sci
let s:completeopt = &completeopt
set completeopt=menuone
setl ft=scilab
setl omnifunc=scilabcomplete#Complete
let s:scilab_script_nr = winnr()
let reg_q = getreg('q')
let reg_w = getreg('w')
let reg_e = getreg('e')

" lock autocomplete plugin
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

" result buffer
vert new
let s:result_nr = winnr()
normal! i   *** The result ***
syn match ScilabCompleteTestTitle '\%1l'
hi! link ScilabCompleteTestTitle Comment
execute s:scilab_script_nr . 'wincmd w'

" Start test
" Test 1
normal! gg
call setreg('q', '0j$a();j')
call setreg('w', '0j$a;j')
call setreg('e', '0j$a(90);j')
call setreg('r', '0j$aj')
normal! @q@w@e@r
