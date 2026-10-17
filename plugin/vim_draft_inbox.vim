" vim-draft-inbox
" Version: 1.0.0
"
" Preserve unnamed startup notes as recoverable drafts.
" Single-file Vim plugin; no autoload directory or required dependency.
"

if exists('g:loaded_vim_draft_inbox')
  finish
endif
let g:loaded_vim_draft_inbox = 1

" ============================================================================
" Defaults
" ============================================================================

if !exists('g:draft_inbox_dir')
  let g:draft_inbox_dir = '~/.vimdrafts'
endif

if !exists('g:draft_inbox_restore_limit')
  let g:draft_inbox_restore_limit = 20
endif

if !exists('g:draft_inbox_extension')
  let g:draft_inbox_extension = 'txt'
endif

" builtin : this plugin autosaves draft buffers.
" external: another plugin such as vim-auto-save handles autosave.
" none    : no autosave.
if !exists('g:draft_inbox_autosave')
  let g:draft_inbox_autosave = 'builtin'
endif

if !exists('g:draft_inbox_autosave_events')
  let g:draft_inbox_autosave_events = [
        \ 'InsertLeave',
        \ 'TextChanged',
        \ 'FocusLost',
        \ 'BufLeave',
        \ 'VimLeavePre',
        \ ]
endif

" ============================================================================
" Internal functions
" ============================================================================

function! s:IsDraft() abort
  return get(b:, 'draft_inbox', 0)
endfunction

function! s:DraftDir() abort
  return expand(g:draft_inbox_dir)
endfunction

function! s:Extension() abort
  return substitute(g:draft_inbox_extension, '^\.+', '', '')
endfunction

function! s:MarkAsDraft(path) abort
  let b:draft_inbox = 1
  let b:draft_inbox_path = simplify(fnamemodify(a:path, ':p'))
endfunction

function! s:UnmarkDraft() abort
  unlet! b:draft_inbox
  unlet! b:draft_inbox_path
endfunction

function! s:GenerateDraftPath() abort
  let l:dir = s:DraftDir()
  call mkdir(l:dir, 'p')

  let l:base = l:dir
        \ . '/'
        \ . strftime('%Y%m%d-%H%M%S')
        \ . '-'
        \ . getpid()

  let l:ext = s:Extension()
  let l:suffix = empty(l:ext) ? '' : '.' . l:ext
  let l:path = l:base . l:suffix
  let l:i = 1

  while filereadable(l:path) || bufexists(l:path)
    let l:path = printf('%s-%02d%s', l:base, l:i, l:suffix)
    let l:i += 1
  endwhile

  return l:path
endfunction

function! s:NewDraft(newtab) abort
  call mkdir(s:DraftDir(), 'p')

  if a:newtab
    silent tabnew
  endif

  let l:path = s:GenerateDraftPath()

  " Suppress the normal :file informational message so the inbox can switch
  " directly to the new buffer without an extra hit-enter prompt.
  silent execute 'file ' . fnameescape(l:path)

  call s:MarkAsDraft(l:path)

  redraw
  echo 'New Draft: ' . l:path
endfunction

function! s:OpenDraft(path, newtab) abort
  if !filereadable(a:path)
    echohl WarningMsg
    echo 'Draft file not found: ' . a:path
    echohl None
    return
  endif

  " Suppress the normal file-status message to avoid a hit-enter prompt after
  " the multi-line inbox prompt.
  if a:newtab
    silent execute 'tabedit ' . fnameescape(a:path)
  else
    silent execute 'edit ' . fnameescape(a:path)
  endif

  call s:MarkAsDraft(a:path)

  redraw
  echo 'Restored Draft: ' . a:path
endfunction

function! s:CompareDraftMtime(a, b) abort
  let l:a = getftime(a:a)
  let l:b = getftime(a:b)

  if l:a > l:b
    return -1
  elseif l:a < l:b
    return 1
  endif

  return 0
endfunction

function! s:GetDraftFiles() abort
  let l:dir = s:DraftDir()
  call mkdir(l:dir, 'p')

  let l:ext = s:Extension()
  let l:pattern = empty(l:ext) ? '*' : '*.' . l:ext
  let l:files = globpath(l:dir, l:pattern, 0, 1)

  call filter(l:files, 'filereadable(v:val)')
  call sort(l:files, function('<SID>CompareDraftMtime'))

  if g:draft_inbox_restore_limit > 0
        \ && len(l:files) > g:draft_inbox_restore_limit
    let l:files = l:files[0 : g:draft_inbox_restore_limit - 1]
  endif

  return l:files
endfunction

function! s:SelectDraft(newtab) abort
  let l:files = s:GetDraftFiles()

  if empty(l:files)
    call s:NewDraft(a:newtab)
    return
  endif

  let l:menu = [
        \ 'Draft Inbox',
        \ '',
        \ '[Enter] New Draft',
        \ 'q       Unnamed buffer / Cancel',
        \ ]

  for l:i in range(0, len(l:files) - 1)
    let l:file = l:files[l:i]
    let l:mtime = strftime('%Y-%m-%d %H:%M:%S', getftime(l:file))

    call add(l:menu, printf(
          \ '%d. %s  [%s]',
          \ l:i + 1,
          \ fnamemodify(l:file, ':t'),
          \ l:mtime))
  endfor

  while 1
    " Use the entire menu as input()'s prompt.  A separate multi-line :echo
    " can fill Vim's message area first and cause an unnecessary hit-enter.
    try
      let l:choice = input(join(l:menu, "\n") . "\nSelect: ")
    catch /^Vim:Interrupt$/
      redraw
      return
    endtry

    " Empty input creates a new draft.
    if empty(l:choice)
      call s:NewDraft(a:newtab)
      return
    endif

    " q leaves the startup inbox without creating a draft.
    " On startup the original unnamed buffer remains active.
    " When called manually, q simply cancels the selection.
    if l:choice =~? '^\s*q\s*$'
      redraw
      return
    endif

    " Open an existing draft by number.
    if l:choice =~# '^\s*\d\+\s*$'
      let l:index = str2nr(l:choice)

      if l:index >= 1 && l:index <= len(l:files)
        call s:OpenDraft(l:files[l:index - 1], a:newtab)
        return
      endif
    endif

    redraw
    echohl WarningMsg
    echo 'Invalid selection. Press Enter for a new Draft, q to cancel, or enter a number.'
    echohl None
  endwhile
endfunction

function! s:SetupStartupDraft() abort
  " Only replace Vim's normal unnamed startup buffer.
  if argc() != 0
    return
  endif

  if bufname('%') !=# '' || &buftype !=# ''
    return
  endif

  call s:SelectDraft(0)
endfunction

function! s:AutoSave() abort
  if g:draft_inbox_autosave !=# 'builtin'
    return
  endif

  if !s:IsDraft()
    return
  endif

  if !&modifiable || &readonly || &buftype !=# ''
    return
  endif

  if !&modified || expand('%') ==# ''
    return
  endif

  silent! update
endfunction

function! s:WriteNormally(args, bang) abort
  let l:cmd = 'write' . (a:bang ? '!' : '')

  if !empty(a:args)
    let l:cmd .= ' ' . a:args
  endif

  execute l:cmd
endfunction

function! s:ArgsWithoutPlusOptions(args) abort
  let l:rest = a:args

  while l:rest =~# '^\s*++\S\+'
    let l:rest = substitute(l:rest, '^\s*++\S\+\s*', '', '')
  endwhile

  return l:rest
endfunction

function! s:DraftWrite(args, bang) abort
  if !s:IsDraft()
    call s:WriteNormally(a:args, a:bang)
    return
  endif

  let l:rest = s:ArgsWithoutPlusOptions(a:args)

  " Plain :w, filter writes and append writes keep Vim's normal semantics.
  if empty(l:rest)
        \ || l:rest =~# '^\s*!'
        \ || l:rest =~# '^\s*>>'
    call s:WriteNormally(a:args, a:bang)
    return
  endif

  let l:oldfile = simplify(fnamemodify(
        \ get(b:, 'draft_inbox_path', expand('%:p')),
        \ ':p'))

  " :w filename on a draft behaves like :saveas filename.
  let l:cmd = 'saveas' . (a:bang ? '!' : '') . ' ' . a:args
  execute l:cmd

  let l:newfile = simplify(expand('%:p'))

  if empty(l:newfile) || l:newfile ==# l:oldfile
    return
  endif

  if filereadable(l:oldfile) && delete(l:oldfile) != 0
    echohl WarningMsg
    echo 'Saved as ' . l:newfile
          \ . ', but the old Draft file could not be deleted: '
          \ . l:oldfile
    echohl None
  else
    echo 'Draft promoted to: ' . l:newfile
  endif

  call s:UnmarkDraft()
endfunction

function! s:RemoveDraft() abort
  if !s:IsDraft()
    echohl WarningMsg
    echo ':rm is available only for Draft buffers.'
    echohl None
    return
  endif

  if !exists('b:draft_inbox_path')
    echohl ErrorMsg
    echo 'Draft path is not defined.'
    echohl None
    return
  endif

  let l:file = simplify(fnamemodify(b:draft_inbox_path, ':p'))
  let l:old_bufnr = bufnr('%')

  let l:choice = confirm(
        \ "Delete this Draft file?\n\n" . l:file,
        \ "&Yes\n&No",
        \ 2)

  if l:choice != 1
    echo 'Draft deletion cancelled.'
    return
  endif

  " Mark unmodified before leaving so an external autosave plugin does not
  " rewrite the draft while it is being removed.
  let l:was_modified = &modified
  setlocal nomodified

  if filereadable(l:file) && delete(l:file) != 0
    if l:was_modified
      setlocal modified
    endif

    echohl ErrorMsg
    echo 'Draft file could not be deleted: ' . l:file
    echohl None
    return
  endif

  keepalt enew

  if bufexists(l:old_bufnr)
    execute 'silent! bwipeout! ' . l:old_bufnr
  endif

  " Return to Draft Inbox.  If none remain, SelectDraft() creates a new one.
  call s:SelectDraft(0)
endfunction

function! s:ParseWriteCommand(cmdline) abort
  let l:match = matchlist(
        \ a:cmdline,
        \ '^\s*\(w\|wr\|wri\|writ\|write\)\(!\)\?\s\+\(.*\)$')

  if empty(l:match)
    return []
  endif

  return [l:match[2], l:match[3]]
endfunction

function! s:CommandLineEnter() abort
  if getcmdtype() !=# ':'
    return "\<CR>"
  endif

  if !s:IsDraft()
    return "\<CR>"
  endif

  let l:cmd = getcmdline()

  " :rm -> :DraftRemove
  if l:cmd =~# '^\s*rm\s*$'
    return "\<C-U>DraftRemove\<CR>"
  endif

  " :w filename -> :DraftWrite filename
  let l:parts = s:ParseWriteCommand(l:cmd)

  if empty(l:parts)
    return "\<CR>"
  endif

  let l:bang = l:parts[0]
  let l:args = l:parts[1]
  let l:rest = s:ArgsWithoutPlusOptions(l:args)

  if empty(l:rest)
        \ || l:rest =~# '^\s*!'
        \ || l:rest =~# '^\s*>>'
    return "\<CR>"
  endif

  return "\<C-U>DraftWrite"
        \ . l:bang
        \ . ' '
        \ . l:args
        \ . "\<CR>"
endfunction

" ============================================================================
" Commands
" ============================================================================

command! -nargs=* -bang -complete=file DraftWrite
      \ call <SID>DraftWrite(<q-args>, <bang>0)

command! DraftRemove
      \ call <SID>RemoveDraft()

command! DraftInbox
      \ call <SID>SelectDraft(1)

command! DraftNew
      \ call <SID>NewDraft(1)

" ============================================================================
" Autocommands
" ============================================================================

augroup VimDraftInbox
  autocmd!

  autocmd VimEnter * call <SID>SetupStartupDraft()

  if g:draft_inbox_autosave ==# 'builtin'
    execute 'autocmd '
          \ . join(g:draft_inbox_autosave_events, ',')
          \ . ' * call <SID>AutoSave()'
  endif
augroup END

" ============================================================================
" Command-line extension
" ============================================================================
"
" While editing a draft buffer only:
"   :w filename -> Save As
"   :rm         -> confirm/delete draft
"
" Do not overwrite an existing command-line <CR> mapping.
"

if empty(maparg('<CR>', 'c'))
  cnoremap <expr> <CR> <SID>CommandLineEnter()
endif
