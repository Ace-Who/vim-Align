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

The user will be prompted to input the pattern and the match count(s) in the
line.  
Do not surround the pattern with '/'s.
If the pattern is left as blank, use the character under cursor if it's not a
white space, otherwise use '='.  
The match counts string is supposed to be a comma separated number list.
If it is left as blank, use 1.  
If it is 'g', use numbers from 1 to the largest count making the
pattern matches any target line.

In Normal mode, if `[count]` is given and greater than 1, it operates on
`[count]` lines from the current line. Otherwise, it operates on the lines
matched in succession from the current line by the pattern with the first
match count specified by the user.  
In Visual modes, it operates on selected lines.  

## ToDo

Right Aligh the matched str.
