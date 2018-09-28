# vim-Align

Make occurrences of the specified string pattern on different lines align visually.

## Usage

```viml
<leader>ali    " Align a string pattern.
<leader>ALI    " Unalign, or remove spaces before, a string pattern.
               " Input spaces preceding the pattern to preserve that many of
               " them. Those spaces won't be counted in the pattern to be
               " matched.
```

User will be prompted to input the pattern and its ordinal(s) amoung multiple
occurrences in the same line.

Works in normal mode or visual mode.

In normal mode, it affects all lines.
In visual mode, it affects selected lines.

## Note

To avoid "Too many \(" error, use "\%(\)" instead of "\(\)" in the pattern if
needed.

Known limitation: including '\zs' or '\ze' in the pattern will lead to unwanted
results.
