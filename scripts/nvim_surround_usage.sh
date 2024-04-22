#!/bin/bash
cat <<EOF
Vim Surround Keymaps

The three "core" operations of add/delete/change with the Vim Surround plugin can be done using the keymaps ys{motion}{char}, ds{char}, and cs{target}{replacement}, respectively.

Here are some examples where * denotes the cursor position:

| Old Text                  | Command       | New Text                  |
|---------------------------|---------------|---------------------------|
| surr*ound_words           | ysiw)         | (surround_words)          |
| *make strings             | ys$"          | "make strings"            |
| [delete ar*ound me!]      | ds]           | delete around me!         |
| remove <b>HTML t*ags</b>  | dst           | remove HTML tags          |
| 'change quot*es'          | cs'"          | "change quotes"           |
| <b>or tag* types</b>      | csth1<CR>     | <h1>or tag types</h1>     |
| delete(functi*on calls)   | dsf           | function calls            |
EOF
