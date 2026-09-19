setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal expandtab

" Set the keywordprg option to use ansible-doc if it is executable
if executable('ansible-doc')
    setlocal keywordprg=:sp\ term://ansible-doc
endif

" Get the current buffer's file name
let l:fname = expand('%:p')

" Check if the file path contains 'tasks/'
if l:fname =~ 'tasks/'
    " Get the current buffer's path and the derived paths
    let l:current_path = expand('%:p:h')
    let l:files_path = substitute(l:fname, 'tasks/', 'files/', 'g')
    let l:templates_path = substitute(l:fname, 'tasks/', 'templates/', 'g')

    " Set the buffer-local 'path' option with the concatenated paths
    " The `:h` modifier extracts the directory name from the file path
    " The `expand()` function is used to convert the derived paths to their absolute form
    let l:paths = &l:path . ',' . fnamemodify(l:files_path, ':h') . ',' . fnamemodify(l:templates_path, ':h') . ',' . l:current_path
    let &l:path = l:paths
endif

