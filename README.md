# vim-Align

Align the specified match(es) of the specified string pattern on different lines visually.

## Usage

```viml
<leader>ali    " Align a string pattern.
<leader>ALI    " Unalign, or remove spaces before, a string pattern.
               " Input spaces preceding the pattern to preserve that many of
               " them. Those spaces won't be counted in the pattern to be
               " matched.
```

User will be prompted to input the pattern and the match count(s) in the line.

In Normal mode, if `[count]` is given and greater than 1, it operates on
`[count]` lines from the current line. Otherwise, it operates on the lines
matched in succession from the current line by the pattern with the first
match count specified by the user.  
In Visual modes, it operates on selected lines.  
