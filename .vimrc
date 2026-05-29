" Vim @ Linux conf

set nocompatible
filetype on
syntax on
filetype plugin indent on
set nobackup
set noswapfile
set number relativenumber
set colorcolumn=80,88
set ruler
set nowrap
set smarttab
set showmatch
set cursorline
set hlsearch
set incsearch
set ignorecase nosmartcase
set expandtab
set shiftwidth=4
set softtabstop=4
set history=200
set encoding=utf-8
set wrap linebreak

vnoremap . :norm.<CR>
inoremap jk <ESC>

nnoremap <leader>n :NERDTreeToggle<CR>
" add comment in Perl, Ruby, Python
nnoremap <leader>c I# <Esc>
" remove commment
nnoremap <leader>u ^xx

call plug#begin()
Plug 'morhetz/gruvbox'
Plug 'kien/ctrlp.vim'
Plug 'mhinz/vim-signify'
Plug 'dense-analysis/ale'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
call plug#end()

"colorscheme dracula
"colorscheme gruvbox
set background=dark

" Signify conf
let g:signify_line_highlight=0
set updatetime=100

"Ale settings
let g:ale_completion_enabled = 1
nmap <silent> <leader>aj :ALENext<cr>
nmap <silent> <leader>ak :ALEPrevious<cr>
nmap <silent> <leader>ax :ALEDisable<cr>

"Airline
let g:airline_theme='dark'
