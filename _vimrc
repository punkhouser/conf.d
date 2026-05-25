" VIM configuration file @ Windows

set nobackup
set nowritebackup
set noswapfile
set nocompatible
set encoding=utf-8
language messages en
if has("gui_running")
    set columns=82
    set lines=35
    winpos 1048 121
"    set uioptions-=r
endif

syntax on
set number relativenumber
"set relativenumber
set cursorline
set showcmd
set showmode
set ruler
set wrap
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent
set smartindent

set ignorecase
set smartcase
set incsearch
set hlsearch

set wildmenu
set backspace=indent,eol,start
filetype plugin indent on
