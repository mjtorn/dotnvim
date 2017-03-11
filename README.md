# https://github.com/mjtorn/dotnvim

mjt's .condig/nvim/ stuff

See also `https://github.com/mjtorn/dotvim`

## Installation

    git clone git://github.com/mjtorn/dotnvim.git .config/nvim/

    cd .config/nvim/

    git submodule update --init

    mkdir undo

## Protips

These go in your working root's `.local.vim` file

### Java

Only install python-neovim, add something to the search path (if needed)
and have ctrlp ignore compiled files:

```vim
let g:venv_reqs = ['neovim']
let g:JavaComplete_LibsPath = './lib/Scribejava_core_3_2_0/'
let g:ctrlp_custom_ignore = {
\  'file': '\v\.class$',
\ }
```

See more at [vim-javacomplete2](https://github.com/artur-shaik/vim-javacomplete2)

### C/C++

The [clang_complete](https://github.com/Rip-Rip/clang_complete) plugin has its own
file `.clang_complete` for compiler flags/options, like this:

```
-I/home/foo/src/libfoo-qt5/
-Isrc/
-isystem /usr/include/x86_64-linux-gnu/qt5
-isystem /usr/include/x86_64-linux-gnu/qt5/QtNetwork
-isystem /usr/include/x86_64-linux-gnu/qt5/QtCore
-std=c++11
-fPIC
```

ALE gets helped by

```vim
let g:ale_cpp_clang_options = '-I/home/foo/src/libfoo-qt5/ -Isrc/ -isystem /usr/include/x86_64-linux-gnu/qt5 -isystem /usr/include/x86_64-linux-gnu/qt5/QtNetwork -isystem /usr/include/x86_64-linux-gnu/qt5/QtCore -std=c++11 -fPIC'
```

### Python

Should work pretty much out of the box as-is.

## Bonuses

Some flake8 conf for use with syntastic: https://gist.github.com/mjtorn/9870434

