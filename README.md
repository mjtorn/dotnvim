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

### Obsession
All you need is to kick off `:Obsession` when you're
doing things to create `Session.vim`.

Currently if no files (unfortunately this applies to
other `argv()` too) are given, and the file exists,
it's sourced automatically.

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

Nothing here now, look into
[Eclipse LSP integration](https://zignar.net/2020/10/17/setup-neovim-for-java-development-2/)

### C/C++

Nothing here now, look into
[ccls integration](https://jdhao.github.io/2020/11/29/neovim_cpp_dev_setup/) when Debian Bullseye
is out or I need it or whatever.

ALE gets helped by

```vim
let g:ale_cpp_clang_options = '-I/home/foo/src/libfoo-qt5/ -Isrc/ -isystem /usr/include/x86_64-linux-gnu/qt5 -isystem /usr/include/x86_64-linux-gnu/qt5/QtNetwork -isystem /usr/include/x86_64-linux-gnu/qt5/QtCore -std=c++11 -fPIC'
```

### Python

Ever since [python-support](https://github.com/roxma/python-support.nvim) was deprecated,
things got different.

Create a virtualenv `${HOME}/.virtualenvs/nvim-runtime` and use things from there.

Note that you may want to use `ruff-lsp`, in which case you may not want
to use flake8, in which case you can skip installing all flake8 packages.
It pulls in pycodestyle, and the best way to disable it is to never install
it.

Or an even better thing might be to `pip install python-lsp-ruff` to use
the ruff plugin for the Python lsp.

**NVIM-CMP OR UPGRADE WARNING:**

The below is fine and all

```shell
  python3 -m venv ~/.virtualenvs/nvim-runtime
  workon nvim-runtime
  # pip install neovim python-lsp-server flake8 isort flake8-isort pyyaml
  pip install neovim python-lsp-server python-lsp-ruff
  pip install pyls-flake8 pyls-isort  # and whtever else
```

but basically you want the language servers in the venv you're working on.

Something like deoplete-lsp would've been smarter in using these from
the provider's venv, or maybe it's changed in later NeoVims. I don't know
nor do I care right now.

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

