if vim.g.vscode then
  return
end

--[[ Options ]]

vim.scriptencoding = 'utf-8'
vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = '100'
vim.opt.signcolumn = 'yes'
vim.opt.laststatus = 2

vim.opt.termguicolors = true

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.title = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10
vim.opt.cmdheight = 1

vim.opt.inccommand = 'split'
vim.opt.backspace = { 'start', 'eol', 'indent' }

vim.opt.list = true
vim.opt.listchars = { tab = '» ', leadmultispace = '┊ ', trail = '␣', nbsp = '⍽' }

vim.opt.wildchar = 9 -- ensure <Tab> triggers cmdline completion

vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'indent' -- or 'expr' to use treesitter

vim.opt.shortmess:append('aI')

vim.opt.path:append({'**'})
vim.opt.wildignore:append({'*/node_modules/*'})

vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy', 'preview' }
vim.opt.pumheight = 10

vim.opt.diffopt = {
  'internal',
  'filler',
  'closeoff',
  'vertical',
  'algorithm:histogram',
  'indent-heuristic',
  'linematch:60',
  -- await nvim 0.12
  -- 'inline:char'
}

--[[ Keymaps ]]

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('n', ',wq', '<cmd>bdelete<cr>', { desc = 'Close buffer' })
vim.keymap.set('n', ',qq', '<cmd>bdelete!<cr>', { desc = 'Close buffer (force)' })

-- clipboard register
vim.keymap.set({ 'n', 'x' }, '<leader>\'', '<cmd>let @+=@"<CR>', { desc = '" to +' })
vim.keymap.set({ 'n', 'x' }, '<leader>"', '<cmd>let @"=@+<CR>', { desc = '+ to "' })
vim.keymap.set('n', 'Y', '"+Y')
vim.keymap.set({ 'n', 'x' }, 'y', function ()
  if vim.v.register == '"' then
    return '"+y'
  else
    return '"'.. vim.v.register.. 'y'
  end
end, { expr = true, silent = true, desc = 'Yank to clipboard'})

-- save position
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines' })

-- center screen
vim.keymap.set('n', '<C-Down>', '<C-d>zzzv', { desc = 'Scroll screen down' })
vim.keymap.set('n', '<C-Up>', '<C-u>zzzv', { desc = 'Scroll screen up' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next match' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Prev match' })

-- move lines
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- diagnostics
vim.keymap.set('n', ',,', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>D', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- quickfixlist
vim.keymap.set('n', '<leader>q', vim.cmd.copen, { desc = 'Open quickfix list' })
vim.keymap.set('n', ']q', function()
  return pcall(vim.cmd.cnext) or pcall(vim.cmd.cfirst) or vim.notify('No errors')
end
, { desc = 'Next quickfix item' })
vim.keymap.set('n', '[q', function()
  return pcall(vim.cmd.cprevious) or pcall(vim.cmd.clast) or vim.notify('No errors')
end, { desc = 'Prev quickfix item' })

-- completion
vim.keymap.set('i', '<C-z>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end
  return '<C-x><C-o>'
end, { expr = true, silent = true, desc = 'Toggle completion menu' })

-- terminal
vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { silent = true, desc = 'Exit terminal mode' })

-- macos
vim.keymap.set('i', '<M-BS>', '<C-w>', { silent = true, desc = 'Kill word (mac)'})
vim.keymap.set('c', '<M-BS>', '<C-w>', { desc = 'Kill word (mac)'})

-- folds
vim.keymap.set('n', '[z', function()
  local count = vim.v.count1
  local curLnum = vim.api.nvim_win_get_cursor(0)[1]
  local cnt = 0
  local lnum
  for i = curLnum - 1, 1, -1 do
    if vim.fn.foldclosed(i) == i then
      cnt = cnt + 1
      lnum = i
      if cnt == count then
        break
      end
    end
  end
  if lnum then
    vim.cmd('norm! m`')
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end
end, { desc = 'Prev closed fold' })

vim.keymap.set('n', ']z', function()
  local count = vim.v.count1
  local curLnum = vim.api.nvim_win_get_cursor(0)[1]
  local lineCount = vim.api.nvim_buf_line_count(0)
  local cnt = 0
  local lnum
  for i = curLnum + 1, lineCount do
    if vim.fn.foldclosed(i) == i then
      cnt = cnt + 1
      lnum = i
      if cnt == count then
        break
      end
    end
  end
  if lnum then
    vim.cmd('norm! m`')
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end
end, { desc = 'Next closed fold' })

function vim.getVisualSelection()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})

  text = string.gsub(text, "\n", "")
  if #text > 0 then
    return text
  else
    return ''
  end
end

--[[ Plugins ]]

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  defaults = { lazy = true },
  install = { missing = true },
  ui = {
    border = 'rounded',
  },
  spec = {
    {
      'ellisonleao/gruvbox.nvim',
      -- lazy = false,
      config = function()
        require('gruvbox').setup({
          palette_overrides = {
            dark0 = '#1F1F28',
            dark1 = '#2A2A37',
            -- gruvbox-material
            bright_red = '#EA6962',
            bright_orange = '#E78A4E',
            bright_yellow = '#E9B143',
            bright_green = '#A9B665',
            bright_aqua = '#89B482',
            bright_blue = '#80AA9E',
            bright_purple = '#D3869B',
          },
          overrides = {
            SignColumn = { link = 'Normal' },
            Keyword = { link = 'GruvboxRed' },
            Operator = { link = 'GruvboxFg0' },
            Delimiter = { link = 'GruvboxFg0' },
            Identifier = { link = 'GruvboxFg0' },
            Function = { link = 'GruvboxBlue' },
            Constant = { link = 'Special' },
            Property = { link = 'GruvboxPurple' },
            ['@boolean'] = { link = 'Constant' },
            ['@number'] = { link = 'Constant' },
            ['@type.qualifier'] = { link = 'Special' },
            ['@keyword.conditional'] = { link = 'Conditional' },
            ['@keyword.return'] = { link = 'Conditional' },
            ['@keyword.exception'] = { link = 'Conditional' },
            ['@keyword.repeat'] = { link = 'Conditional' },
            ['@function.builtin'] = { link = 'Function' },
            ['@constant.builtin'] = { link = 'Constant' },
            ['@lsp.type.interface'] = { link = '@type' },
            ['@variable.member'] = { link = 'Property' },
            ['@lsp.type.property'] = { link = 'Property' },
          }
        })
        vim.cmd('colorscheme gruvbox')
      end
    },
    {
      'vague2k/vague.nvim',
      lazy = false,
      config = function()
        require('vague').setup({ transparent = true })
        -- vim.cmd('colorscheme vague')
        -- vim.cmd(':hi statusline guibg=NONE')
      end
    },
    {
      'arkrost/alabaster.nvim',
      dir = '~/Projects/alabaster.nvim',
      lazy = false,
      config = function()
        vim.cmd.colorscheme('alabaster')
      end
    },
    {
      'lukas-reineke/indent-blankline.nvim',
      main = 'ibl',
      opts = {
        scope = {
          enabled = false
        },
        indent = {
          char = '┊',
        }
      },
      event = 'VeryLazy',
      init = function()
        vim.opt.listchars:remove('leadmultispace')
      end,
    },
    {
      'tpope/vim-fugitive',
      lazy = false,
    },
    {
      'tpope/vim-sleuth',
      lazy = false,
    },
    {
      'folke/snacks.nvim',
      lazy = false,
      config = {
        picker = {
          sources = {
            git_log = {
              confirm = function(picker, item)
                if not item then return end
                vim.fn.setreg("+", item.commit)
                vim.notify("Copied " .. item.commit)
                picker:close()
              end,
            },
          }
        }
      }
    },
    {
      'folke/which-key.nvim',
      event = 'VeryLazy',
      init = function()
        vim.opt.timeout = true
        vim.opt.timeoutlen = 300
      end,
      opts = {
        icons = {
          separator = '->',
          breadcrumb = '>>',
        }
      },
      keys = {
        { '?', '<cmd>:WhichKey<cr>', desc = 'Help keys' }
      },
    },
    {
      'nvim-telescope/telescope.nvim',
      lazy = false,
      dependencies = {
        'nvim-lua/plenary.nvim', --required
        'nvim-telescope/telescope-ui-select.nvim',
        'nvim-telescope/telescope-file-browser.nvim',
        'jonarrien/telescope-cmdline.nvim'
      },
      opts = {
        defaults = {
          path_display = {
            shorten = {
              len = 1,
              exclude = { 1, 2, 3, -1 }
            },
          },
        },
        extensions = {
          file_browser = {
            hijack_netrw = true,
            follow_symlinks = true,
          },
          cmdline = {
            mappings = {
              run_input = '<C-CR>',
              run_selection = '<CR>',
            }
          }
        }
      },
      keys = {
        { '<leader>b', function() require('telescope.builtin').buffers() end,            desc = 'Find buffers' },
        { '<leader>d', function() require('telescope.builtin').diagnostics() end,        desc = 'Open diagnostics list' },
        { '<leader>q', function() require('telescope.builtin').quickfix() end,           desc = 'Open quickfix list' },
        { '<leader>/', function() require('telescope.builtin').live_grep() end,          desc = 'Grep files' },
        {
          '<leader>/',
          function()
            require('telescope.builtin').live_grep({ default_text = vim.getVisualSelection() })
          end,
          desc = 'Grep files',
          mode = 'v'
        },
        {
          '<leader>f',
          function()
            local is_git = vim.fn.isdirectory('.git') ~= 0
            if is_git then
              require('telescope.builtin').git_files({ show_untracked = true })
            else
              require('telescope.builtin').find_files({ hidden = true, follow = true })
            end
          end,
          desc = 'Find project files'
        },
      },
      config = function(_, opts)
        require('telescope').setup(opts)
        require('telescope').load_extension('ui-select')
        require('telescope').load_extension('file_browser')
        require('telescope').load_extension('cmdline')
      end,
    },
    {
      'stevearc/oil.nvim',
      opts = {
        view_options = {
          show_hidden = true,
        },
      },
      keys = {
        { '-', '<cmd>Oil<cr>', desc = 'Open oil' }
      }
    },
    {
      'nvim-treesitter/nvim-treesitter',
      dependencies = {
        'windwp/nvim-ts-autotag',
        'nvim-treesitter/nvim-treesitter-textobjects',
        { 'nvim-treesitter/nvim-treesitter-context', opts = {} },
      },
      build = ':TSUpdate',
      event = 'VeryLazy',
      cmd = {
        'TSInstall',
        'TSUninstall',
        'TSUpdate',
        'TSUpdateSync',
        'TSInstallInfo',
        'TSInstallSync',
        'TSInstallFromGrammar',
      },
      main = 'nvim-treesitter.configs',
      init = function()
        vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
      end,
      opts = {
        auto_install = false,
        ensure_installed = {
          'vimdoc',
          'kotlin',
          'java',
          'javascript',
          'typescript',
          'html',
          'json',
          'css',
          'rust',
          'toml',
          'yaml',
          'lua',
          'go',
          'markdown',
          'nix',
          'proto',
          'zig',
          'diff',
          'fish',
        },
        highlight = { enable = true },
        indent = { enable = true },
        autotag = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<leader><cr>',
            node_incremental = '<cr>',
            node_decremental = '<bs>',
            scope_incremental = '<tab>',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
            },
          },
        },
      },
    },
    {
      'lewis6991/gitsigns.nvim',
      event = 'VeryLazy',
      keys = {
        {
          '<leader>g',
          function()
            require('gitsigns').setqflist('all')
          end,
          desc = 'Set all hunks to quickfixlist',
        },
        {
          '<leader>hh',
          function()
            require('gitsigns').setqflist()
          end,
          desc = 'Set buffer hunks to quickfixlist',
        },
      },
      opts = {
        attach_to_untracked = true,
        on_attach = function(bufnr)
          local gs = require('gitsigns')

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          -- visual mode
          map('v', '<leader>hs', function()
            gs.stage_hunk({ vim.fn.line '.', vim.fn.line 'v' })
          end, { desc = 'stage git hunk' })
          map('v', '<leader>hX', function()
            gs.reset_hunk({ vim.fn.line '.', vim.fn.line 'v' })
          end, { desc = 'reset git hunk' })
          -- normal mode
          map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
          map('n', '<leader>hX', gs.reset_hunk, { desc = 'git reset hunk' })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
          map('n', '<leader>hb', function() gs.blame_line({ full = false }) end, { desc = 'git blame line' })
          map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
          map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'git diff against last commit' })
          -- Text object
          map({ 'o', 'x' }, 'ih', gs.select_hunk, { desc = 'select git hunk' })
        end,
      }
    },
    {
      'windwp/nvim-autopairs',
      opts = {},
      event = 'InsertEnter',
    },
    {
      'mbbill/undotree',
      cmd = 'UndotreeToggle',
      keys = {
        { '<leader>u', vim.cmd.UndotreeToggle, desc = 'Undo tree' }
      },
      init = function()
        vim.g.undotree_SetFocusWhenToggle = 1
      end,
    },
        {
      'ThePrimeagen/harpoon',
      dependencies = {
        'nvim-lua/plenary.nvim',
      },
      event = 'BufRead',
      keys = {
        { '<leader>ma',   function() require('harpoon.mark').add_file() end,        desc = 'Mark file' },
        { '<leader>mm',   function() require('harpoon.ui').toggle_quick_menu() end, desc = 'View marks' },
        { '<M-1>',        function() require('harpoon.ui').nav_file(1) end,          desc = 'Select 1' },
        { '<M-2>',        function() require('harpoon.ui').nav_file(2) end,          desc = 'Select 2' },
        { '<M-3>',        function() require('harpoon.ui').nav_file(3) end,          desc = 'Select 3' },
        { '<M-4>',        function() require('harpoon.ui').nav_file(4) end,          desc = 'Select 4' },
        { '<M-5>',        function() require('harpoon.ui').nav_file(5) end,          desc = 'Select 5' },
        { '<M-6>',        function() require('harpoon.ui').nav_file(6) end,          desc = 'Select 6' },
        { '<M-7>',        function() require('harpoon.ui').nav_file(7) end,          desc = 'Select 7' },
        { '<M-8>',        function() require('harpoon.ui').nav_file(8) end,          desc = 'Select 8' },
        { '<M-9>',        function() require('harpoon.ui').nav_file(9) end,          desc = 'Select 9' },
        { '<M-0>',        function() require('harpoon.ui').nav_file(0) end,          desc = 'Select 10' },
      },
      opts = {},
    },
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'nvim-telescope/telescope.nvim', -- see on_attach keys
        { 'folke/neodev.nvim', opts = {} },
        {
          'j-hui/fidget.nvim',
          opts = {
            notification = {
              window = { winblend = 0 },
            }
          }
        },
      },
      event = { 'BufReadPre', 'BufNewFile' },
      config = function()
        local on_attach = function(client, bufnr)
          local nmap = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end

          nmap(',.', vim.lsp.buf.code_action, 'Code Action')

          nmap('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')
          nmap('gr', require('telescope.builtin').lsp_references, 'Goto References')

          -- See `:help K` for why this keymap
          nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
          nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

          -- `:Format` command
          vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
            vim.lsp.buf.format()
          end, { desc = 'Format current buffer with LSP' })

          -- `:Rename` command
          vim.api.nvim_buf_create_user_command(bufnr, 'Rename', function(_)
            vim.lsp.buf.rename()
          end, { desc = 'Rename symbol with LSP' })

          -- `:ToggleInlayHints` command
          vim.api.nvim_buf_create_user_command(bufnr, 'ToggleInlayHints', function(_)
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, { desc = 'Toggle inlay hints' })

          if client.supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
          end
        end

        local capabilities = vim.lsp.protocol.make_client_capabilities()

        local servers = {
          rust_analyzer = {
            settings = {
              ['rust-analyzer'] = {
                checkOnSave = {
                  command = 'clippy'
                }
              }
            }
          },
          lua_ls = {
            settings = {
              Lua = {
                telemetry = { enable = false },
                diagnostics = {
                  globals = { 'vim' },
                },
              }
            }
          },
          gopls = {
            settings = {
              gopls = {
                completeUnimported = true,
                usePlaceholders = true,
                analyses = {
                  unusedparams = true,
                },
              }
            }
          },
          zls = {},
          marksman = {},
          ts_ls = {}
        }

        for server, config in pairs(servers) do
          vim.lsp.config(server, {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = config.settings,
            filetypes = config.filetypes,
          })
          vim.lsp.enable(server)
        end
      end
    },
  },
})
