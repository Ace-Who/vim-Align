" Set the 'cpoptions' option to its Vim default value and restore it later.
" This is to enable line-continuation within this script.
" Refer to :help use-cpo-save.
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Ask user for a string pattern and the match count(s) in that line, align it
" in every line by inserting spaces. In visual mode, do the same thing only
" for the selected lines.
nmap <leader>ali <Plug>AlignAlign
xmap <leader>ali <Plug>AlignAlign
nnoremap <script> <Plug>AlignAlign <SID>Align
xnoremap <script> <Plug>AlignAlign <SID>Align
nnoremap <SID>Align :call <SID>Align(mode(), 0)<CR>
xnoremap <SID>Align :<C-U>call <SID>Align(visualmode(), 0)<CR>

" ToDo: Align the pattern paragraph by paragraph.

" reversing aligning operation, removing leading spaces
nmap <leader>ALI <Plug>AlignUnalign
xmap <leader>ALI <Plug>AlignUnalign
nnoremap <script> <Plug>AlignUnalign <SID>Unalign
xnoremap <script> <Plug>AlignUnalign <SID>Unalign
nnoremap <SID>Unalign :call <SID>Align(mode(), 1)<CR>
xnoremap <SID>Unalign :<C-U>call <SID>Align(visualmode(), 1)<CR>

function! s:Align(mode, flag) "{{{
  let l:prompt = 'Step 1/2: enter the pattern to (un)align: '
  let l:pat = input(l:prompt)
  if match(l:pat, '\S') == -1
    echoerr 'The pattern must contain a non-blank character.'
    return
  endif
  let l:prompt = 'Step 2/2: enter the match count(s) (comma-separated)'
      \ . ' in the line: '
  let l:counts = split(input(l:prompt, 1), ',')
  " ToDo: handle negative count.
  for l:count in l:counts
    let l:count = str2nr(l:count)
    if l:count < 1
      echoerr 'The count should be a positive integer.'
      return
    endif
    if a:flag == 0
      call s:AlignProcess(a:mode, l:pat, l:count)
    else
      call s:UnalignProcess(a:mode, l:pat, l:count)
    endif
  endfor
endfunction "}}}

function! s:AlignProcess(mode, pat, count) " {{{

  let [l:startLN, l:endLN] = a:mode ==? visualmode()
      \ ? [line("'<"), line("'>")]
      \ : [1, line("$")]

  " Find the align position.
  let l:lnum = l:startLN
  let l:aliIdx = 0
  while l:lnum <= l:endLN

    " A multibyte character such as a Chinese character, when the option
    " 'encoding' is set to utf-8, needs 2 to 4 bytes to store in memory which
    " is not usually equal to its display width, namely 2. Thus the aligning
    " operation will insert a wrong number of, in fact less, spaces if some
    " Chinese characters precede the aligned character.
    " To insure the function match count such a character also as 2 indices
    " (byte offset), one can set 'encoding' to cp936 or gbk before opening
    " the file and performing alignment.
    " Reference: http://littlewhite.us/archives/387

    " Update: No trouble with multibyte characters now!
    " strdisplaywidth(), which exactly, as the name suggests, deals with
    " display width, has taken over responsibility from match().

    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, a:pat, 0, a:count)
    if l:matchIdx != -1
      let l:leadingStr = strpart(l:lstr, 0, l:matchIdx)
      let l:preDisplayWidth = strdisplaywidth(l:leadingStr)
      if l:aliIdx < l:preDisplayWidth
        let l:aliIdx = l:preDisplayWidth
      endif
    endif
    let l:lnum += 1
  endwhile
  if l:aliIdx == 0
    return
  endif

  " Align the specified pattern by adding spaces.
  let l:lnum = l:startLN
  while l:lnum <= l:endLN
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, a:pat, 0, a:count)
    if l:matchIdx != -1
      let l:leadingStr = strpart(l:lstr, 0, l:matchIdx)
      let l:preDisplayWidth = strdisplaywidth(l:leadingStr)
      if l:preDisplayWidth < l:aliIdx
        let l:lstrNew = l:leadingStr
            \ . repeat(' ', l:aliIdx - l:preDisplayWidth)
            \ . strpart(l:lstr, l:matchIdx)
        call setline(l:lnum, l:lstrNew)
      endif
    endif
    let l:lnum += 1
  endwhile

endfunction " }}}

function! s:UnalignProcess(mode, pat, count) "{{{

  let [l:startLN, l:endLN] = a:mode ==? visualmode()
      \ ? [line("'<"), line("'>")]
      \ : [1, line("$")]

  " The prefixed spaces in input will be preserved and not be interpreted as
  " part of the pattern.
  let l:preSpNum = match(a:pat, '\S')
  let l:trim = strpart(a:pat, l:preSpNum)

  let l:lnum = l:startLN
  while l:lnum <= l:endLN
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, l:trim, 0, a:count)
    if l:matchIdx != -1
      let l:leadingStr = strpart(l:lstr, 0, l:matchIdx)
      let l:spIdx = match(l:leadingStr, ' *$')
      if l:preSpNum < l:matchIdx - l:spIdx
        let l:lstrNew = strpart(l:lstr, 0, l:spIdx)
            \ . repeat(' ', l:preSpNum)
            \ . strpart(l:lstr, l:matchIdx)
        call setline(l:lnum, l:lstrNew)
      endif
    endif
    let l:lnum += 1
  endwhile

  nohlsearch

endfunction "}}}

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
