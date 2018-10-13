" Set the 'cpoptions' option to its Vim default value and restore it later.
" This is to enable line-continuation within this script.
" Refer to :help use-cpo-save.
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Align the specified pattern in target lines by inserting spaces.
nmap <leader>ali <Plug>AlignAlign
xmap <leader>ali <Plug>AlignAlign
nnoremap <script> <Plug>AlignAlign <SID>Align
xnoremap <script> <Plug>AlignAlign <SID>Align
nnoremap <SID>Align :<C-U>call <SID>Ask(mode(), 'a', v:count)<CR>
xnoremap <SID>Align :<C-U>call <SID>Ask(visualmode(), 'a', v:count)<CR>

" Reversing aligning operation, removing leading spaces.
nmap <leader>ALI <Plug>AlignUnalign
xmap <leader>ALI <Plug>AlignUnalign
nnoremap <script> <Plug>AlignUnalign <SID>Unalign
xnoremap <script> <Plug>AlignUnalign <SID>Unalign
nnoremap <SID>Unalign :<C-U>call <SID>Ask(mode(), 'u', v:count)<CR>
xnoremap <SID>Unalign :<C-U>call <SID>Ask(visualmode(), 'u', v:count)<CR>

function! s:Ask(mode, flag, count) abort "{{{
  let l:pat = input('Step 1/2: enter the pattern to (un)align: ')
  if l:pat =~ '^\s*$'
    let l:pat = s:CursorChar() =~ '\s'
        \ ? '=' : '\V' . escape(s:CursorChar(), '\')
  endif
  let l:realPat = a:flag == 'a' ? l:pat : s:LTrim(l:pat)
  " ToDo: handle negative match count.
  let l:matchCountsStr =
      \ input('Step 2/2: enter the match count(s) (comma-separated): ')
  if l:matchCountsStr ==# 'g'
    let l:range = s:Range(a:mode, a:count, l:realPat, 1)
    let l:maxMatchCount = s:RangeMaxMatchCount(l:range, l:realPat)
    let l:matchCounts = range(1, max([l:maxMatchCount, 1]))
  else
    let l:matchCounts = l:matchCountsStr =~ '^\s*$'
        \ ? [1] : map(split(l:matchCountsStr, ','), 'str2nr(v:val)')
    let l:range = s:Range(a:mode, a:count, l:realPat, l:matchCounts[0])
  endif
  for l:matchCount in l:matchCounts
    if l:matchCount < 1
      echoerr 'The count should be a positive integer.'
      return
    endif
    if a:flag == 'a'
      call s:AlignProcess(l:range, l:pat, l:matchCount)
    else
      call s:UnalignProcess(l:range, l:pat, l:matchCount)
    endif
  endfor
  redraw
  echo 'Processed' l:range[1] - l:range[0] + 1 'lines.'
endfunction "}}}

function! s:CursorChar() "{{{
" Get the character under the cursor.
  return nr2char(strgetchar(getline('.')[col('.') - 1:], 0))
endfunction "}}}

function! s:LTrim(str) "{{{
  return strpart(a:str, match(a:str, '\S'))
endfunction! "}}}

function! s:Range(mode, count, pat, matchCount) "{{{
  if a:mode ==? visualmode()
    return [line("'<"), line("'>")]
  elseif a:count > 1
    return [line('.'), min([line('$'), line('.') + a:count - 1])]
  endif
  let l:lnum = line('.')
  while l:lnum <= line('$')
      \ && match(getline(l:lnum), a:pat, 0, a:matchCount) >= 0
    let l:lnum += 1
  endwhile
  return [line('.'), l:lnum - 1]
endfunction "}}}

function! s:RangeMaxMatchCount(range, pat) "{{{
  let l:max = 0
  let l:lnum = a:range[0]
  while l:lnum <= a:range[1]
    let l:lstr = getline(l:lnum)
    let l:matchCount = l:max + 1
    while l:matchCount <= strlen(l:lstr) && match(l:lstr, a:pat) >= 0
      let l:matchCount += 1
    endwhile
    let l:max = l:matchCount - 1
    let l:lnum += 1
  endwhile
  return l:max
endfunction "}}}

function! s:AlignProcess(range, pat, matchCount) abort "{{{

  " Find the align position.
  let l:lnum = a:range[0]
  let l:aliIdx = 0
  while l:lnum <= a:range[1]

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
    let l:matchIdx = match(l:lstr, a:pat, 0, a:matchCount)
    if l:matchIdx >= 0
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
  let l:lnum = a:range[0]
  while l:lnum <= a:range[1]
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, a:pat, 0, a:matchCount)
    if l:matchIdx >= 0
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

endfunction "}}}

function! s:UnalignProcess(range, pat, matchCount) abort "{{{

  " The prefixed spaces in input will be preserved and not be interpreted as
  " part of the pattern.
  let l:preSpNum = match(a:pat, '\S')
  let l:trim = strpart(a:pat, l:preSpNum)

  let l:lnum = a:range[0]
  while l:lnum <= a:range[1]
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, l:trim, 0, a:matchCount)
    if l:matchIdx >= 0
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

endfunction "}}}

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
