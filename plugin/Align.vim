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
  let l:prompt = 'Step 1/2: enter the pattern to (un)align: '
  let l:pat = input(l:prompt)
  if match(l:pat, '\S') == -1
    if match(s:CursorChar(), '\S') == -1
      echoerr 'The pattern must contain a non-blank character.'
      return
    endif
    let l:pat = '\V' . escape(s:CursorChar(), '\')
  endif
  let l:prompt = 'Step 2/2: enter the match count(s) (comma-separated)'
      \ . ' in the line: '
  " ToDo: handle negative match count.
  let l:matchCountsStr = input(l:prompt)
  if match(l:matchCountsStr, '\S') == -1
    let l:matchCountsStr = '1'
  endif
  let l:matchCounts = s:CsvToNumList(l:matchCountsStr)
  let l:range = a:flag == 'a'
      \ ? s:Range(a:mode, a:count, l:pat, l:matchCounts[0])
      \ : s:Range(a:mode, a:count, s:LTrim(l:pat), l:matchCounts[0])
  for l:matchCount in l:matchCounts
    let l:matchCount = str2nr(l:matchCount)
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

function! s:CsvToNumList(csv) "{{{
  let l:list = []
  for l:str in split(a:csv, ',')
    call add(l:list, str2nr(l:str))
  endfor
  return l:list
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
    let l:lstr = getline(l:lnum)
    if match(l:lstr, a:pat, 0, a:matchCount) == -1
      break
    endif
    let l:lnum += 1
  endwhile
  return [line('.'), l:lnum - 1]
endfunction "}}}

function! s:AlignProcess(range, pat, matchCount) abort " {{{

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
  let l:lnum = a:range[0]
  while l:lnum <= a:range[1]
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, a:pat, 0, a:matchCount)
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

function! s:UnalignProcess(range, pat, matchCount) abort "{{{

  " The prefixed spaces in input will be preserved and not be interpreted as
  " part of the pattern.
  let l:preSpNum = match(a:pat, '\S')
  let l:trim = strpart(a:pat, l:preSpNum)

  let l:lnum = a:range[0]
  while l:lnum <= a:range[1]
    let l:lstr = getline(l:lnum)
    let l:matchIdx = match(l:lstr, l:trim, 0, a:matchCount)
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

endfunction "}}}

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
