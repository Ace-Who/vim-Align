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

It operates on all lines in normal mode or selected lines in visual modes.  
