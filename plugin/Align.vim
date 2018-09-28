" Set the 'cpoptions' option to its Vim default value and restore it later.
" This is to enable line-continuation within this script.
" Refer to :help use-cpo-save.
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" Known limitation: including '\zs' or '\ze' in the pattern will lead to
" unwanted results.

" Aligning  {{{

" Ask user for a string pattern and its ordinal in that line, align it in
" every line by inserting spaces. In visual mode, do the same thing only for
" the selected lines.
nmap <leader>ali <Plug>AlignAlign
xmap <leader>ali <Plug>AlignAlign
nnoremap <script> <Plug>AlignAlign <SID>Align
xnoremap <script> <Plug>AlignAlign <SID>Align
nnoremap <SID>Align :call <SID>Align(mode())<CR>
xnoremap <SID>Align :<C-U>call <SID>Align(visualmode())<CR>

" ToDo: Align the pattern paragraph by paragraph.

function! s:Align(mode) "{{{
  let l:prompt = 'Step 1/2: enter the pattern to align (''\V'' is assumed): '
  let l:pat = input(l:prompt)
  if match(l:pat, '\S') == -1
    echoerr 'The pattern must contain a non-blank character.'
    return
  endif
  let l:prompt = 'Step 2/2: enter its ordinal(s) (comma-separated)'
      \ . ' in the line: '
  let l:ordinals = split(input(l:prompt, 1), ',')
  " ToDo: handle negative ordinal.
  for l:ordinal in l:ordinals
    let l:ordinal = str2nr(l:ordinal)
    if l:ordinal < 1
      echoerr 'The ordinal should be a positive integer.'
      return
    endif
    call s:AlignProcess(a:mode, l:pat, l:ordinal)
  endfor
  redraw
  echom "Aligned '" . l:pat . "'s."
endfunction "}}}

function! s:AlignProcess(mode, pat, ordinal) " {{{

  let [l:startLN, l:endLN] = a:mode ==? visualmode()
      \ ? [line("'<"), line("'>")]
      \ : [1, line("$")]

  let l:assert = '\V'
      \ . '\(' . repeat(a:pat . '\V\.\*', a:ordinal) . '\)\@<='
      \ . '\(' . repeat(a:pat . '\V\.\*', a:ordinal + 1) . '\)\@<!'

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
    let l:matchIdx = match(l:lstr, '\V' . a:pat . l:assert)
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
    let l:aStrIdx = match(l:lstr, '\V' . a:pat . l:assert)
    if l:aStrIdx != -1
      let l:matchIdx = match(l:lstr, '\V' . a:pat . l:assert)
      let l:leadingStr = strpart(l:lstr, 0, l:matchIdx)
      let l:preDisplayWidth = strdisplaywidth(l:leadingStr)
      if l:preDisplayWidth < l:aliIdx
        call setline(l:lnum, substitute(
            \ l:lstr, 
            \ '\ze\V' . a:pat . l:assert,
            \ repeat(' ', l:aliIdx - l:preDisplayWidth),
            \ ''
        \))
      endif
    endif
    let l:lnum += 1
  endwhile

endfunction " }}}

" }}}

" unaligning, or compressing {{{

" reversing aligning operation, removing leading spaces
nmap <leader>ALI <Plug>AlignUnalign
xmap <leader>ALI <Plug>AlignUnalign
nnoremap <script> <Plug>AlignUnalign <SID>Unalign
xnoremap <script> <Plug>AlignUnalign <SID>Unalign
nnoremap <SID>Unalign :call <SID>Unalign(mode())<CR>
xnoremap <SID>Unalign :<C-U>call <SID>Unalign(visualmode())<CR>

function! s:Unalign(mode) "{{{
  " The prefixed spaces in input will be preserved and not be interpreted as
  " part of the pattern.
  let l:prompt = 'Step 1/2: enter the pattern to trim leading spaces: '
  let l:pat = input(l:prompt)
  if match(l:pat, '\S') == -1
    echoerr 'The pattern must contain a non-blank character.'
    return
  endif
  let l:prompt = 'Step 2/2: enter its ordinal(s) (comma-separated)'
      \ . ' in the line: '
  let l:ordinals = split(input(l:prompt, 1), ',')
  " ToDo: handle negative ordinal.
  for l:ordinal in l:ordinals
    let l:ordinal = str2nr(l:ordinal)
    if l:ordinal < 1
      echoerr 'The ordinal should be a positive integer.'
      return
    endif
    call s:UnalignProcess(a:mode, l:pat, l:ordinal)
  endfor
endfunction "}}}

function! s:UnalignProcess(mode, pat, ordinal) "{{{

  let [l:startLN, l:endLN] = a:mode ==? visualmode()
      \ ? [line("'<"), line("'>")]
      \ : [1, line("$")]

  let l:preSpNum = match(a:pat, '\S')
  let l:pat = escape(strpart(a:pat, l:preSpNum), '/')
  let l:assert = '\V'
      \ . '\(' . repeat(l:pat . '\V\.\*', a:ordinal) . '\)\@<='
      \ . '\(' . repeat(l:pat . '\V\.\*', a:ordinal + 1) . '\)\@<!'

  redraw
  execute l:startLN . ',' . l:endLN
      \ . 's/\(^\|\S\)\zs \{-}\ze \{,' . l:preSpNum . '}\V' . l:pat . l:assert
      \ . '//e'
  nohlsearch

endfunction "}}}

" }}}

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions
