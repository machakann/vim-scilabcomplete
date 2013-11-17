augroup scilabcomplete
    autocmd!
augroup END

setlocal makeprg=:

command! -nargs=0 UpdateWorkspace call scilabcomplete#utilities#update_workspace()
autocmd scilabcomplete QuickFixCmdPre  make call scilabcomplete#utilities#pre_make()
autocmd scilabcomplete QuickFixCmdPost make call scilabcomplete#utilities#post_make()
