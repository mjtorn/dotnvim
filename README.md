# https://github.com/mjtorn/dotnvim

mjt's `.config/nvim/` stuff

See also `https://github.com/mjtorn/dotvim`

## Installation

```shell
git clone git://github.com/mjtorn/dotnvim.git .config/nvim/

cd .config/nvim/

git submodule init
git submodule update --recursive --merge

mkdir undo
```

### NeoVim 0.5 neophilia

Your undo will be broken, run `rm -rf ~/.config/nvim/undo/*`

Make sure you install from eg.

```
deb http://ppa.launchpad.net/neovim-ppa/unstable/ubuntu bionic main
```

`sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD`

Most of the stuff should just work, but this is a WIP
branch for now, so maybe not everything does.

Most likely broken are:

  * C
  * C++
  * Java

and Rust is slow as balls, but that's probably Rust being Rust.

#### OmniSharp/mono

Create `/etc/apt/sources.list.d/mono-official-stable.list`

```
deb https://download.mono-project.com/repo/debian stable-buster main
```

`sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF`

This may be the time to run `:OmniSharpInstall`, create the symlink

```
ln -s ${HOME}/.cache/omnisharp-vim/omnisharp-roslyn/OmniSharp.exe ${HOME}/.local/bin/
```

and restart. The symlink doesn't work, lol, but it would be nice if it did!

#### Rust

```
curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip > ~/.local/bin/rust-analyzer
chmod +x !$  # yolo
```

## Protips

These go in your working root's `.local.vim` file

### Java

Only install python-neovim, add something to the search path (if needed)

```vim
let g:venv_reqs = ['neovim']
let g:JavaComplete_LibsPath = './lib/Scribejava_core_3_2_0/'
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

Should work pretty much out of the box as-is, remember to `:PythonSupportInitPython3`.

### Rust

Make sure to `source ~/.cargo/env` and maybe even export `RUST_SRC_PATH` to be
sure you have all of that in order. This depends on [racer](https://github.com/racer-rust/racer)
which currently works only with "nightly" so you must have everything set up
for 0d releases.

Configure at least the racer path in `.local.vim`, and if you don't export `RUST_SRC_PATH`
you must set it as well.

```vim
let g:deoplete#sources#rust#racer_binary='/home/mjt/.cargo/bin/racer'
" let g:deoplete#sources#rust#rust_source_path='/home/mjt/src/git_checkouts/rust/src'
```

Also [install rust-analyzer](https://rust-analyzer.github.io/manual.html#rust-analyzer-language-server-binary)

## Bonuses

Some flake8 conf for use with syntastic: https://gist.github.com/mjtorn/9870434

