#!/bin/bash

# Define color codes
CYAN='\033[0;36m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

# Output the content with color
echo -e "${CYAN}============================== Vim Surround Keymaps ===============================${NC}

The three core operations of adding, deleting, and changing with the Vim Surround plugin are:

  - ${GREEN}ys{motion}{char}${NC}: Add surrounding delimiters
  - ${RED}ds{char}${NC}: Delete surrounding delimiters
  - ${YELLOW}cs{target}{replacement}${NC}: Change one delimiter to another

${CYAN}--------------------------------------------------------------------------------${NC}
Here are some examples where * denotes the cursor position:
${CYAN}--------------------------------------------------------------------------------${NC}

| Old Text                   | Command       | New Text                  |
|----------------------------|---------------|---------------------------|
| surr*ound_words            | ys iw)        | (surround_words)          |
| *make strings              | ys\$\"          | \"make strings\"            |
| [delete ar*ound me!]       | ds]           | delete around me!         |
| remove <b>HTML t*ags</b>   | dst           | remove HTML tags          |
| 'change quot*es'           | cs'\"          | \"change quotes\"           |
| <b>or tag* types</b>       | csth1<CR>     | <h1>or tag types</h1>     |
| delete(functi*on calls)    | dsf           | function calls            |

${CYAN}================================================================================${NC}

${BLUE}nvim-surround Plugin: Quick Overview${NC}
============================================
- A plugin for manipulating surrounding delimiters such as parentheses, quotes, tags.
- Author: Kyle Chui (https://www.github.com/kylechui)
- License: MIT

Usage Sections:
1. Introduction .................................. |nvim-surround.introduction   |
2. Basic Operations .............................. |nvim-surround.basics         |
3. More Key Mappings ............................. |nvim-surround.more_mappings  |
4. Default Surround Pairs ........................ |nvim-surround.default_pairs  |
5. Configuration & Customization ................. |nvim-surround.configuration  |
6. Resources ..................................... |nvim-surround.resources      |

${CYAN}======================== nvim-surround: Basic Commands ==========================${NC}

1. ${GREEN}Adding a Delimiter Pair:${NC}
   - Normal Mode: ${BLUE}ys{motion}{char}${NC}
   - Visual Mode: ${BLUE}S${NC} or ${BLUE}<C-g>s${NC} (Insert Mode)
   Example: 
     Old:   local str = H*ello
     Command: ysiw\"
     New:   local str = \"Hello\"

2. ${RED}Deleting a Delimiter Pair:${NC}
   - Normal Mode: ${RED}ds{char}${NC}
   Example:
     Old:   See ':h h*elp'
     Command: ds\'
     New:   See :h help

3. ${YELLOW}Changing a Delimiter Pair:${NC}
   - Normal Mode: ${YELLOW}cs{target}{replacement}${NC}
   Example:
     Old:   '*some string*'
     Command: cs\'\"
     New:   \"some string\"

${CYAN}==================== Additional Keymaps and Configurations ====================${NC}

1. Use ${GREEN}yss${NC} for surrounding the entire line, ignoring whitespace.
2. Use ${BLUE}<C-g>S${NC} in Insert Mode to add delimiter pairs on new lines.
3. Change specific surroundings such as function calls using ${RED}csf${NC}.

${CYAN}=========================== Default Surround Pairs ===========================${NC}

1. Parentheses: ()
2. Braces: {}
3. Brackets: []
4. HTML tags: <tag> </tag>
5. Function calls: function_name(arguments)

${CYAN}Happy Coding!${NC}"
