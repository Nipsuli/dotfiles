-- Override Cosmic configuration options

-- You can require null-ls if needed
-- local null_ls = require('null-ls')

local config = {
  -- See :h nvim_open_win for possible border options
  border = 'rounded',
  -- LSP settings
  lsp = {
    -- True/false or table of filetypes {'.ts', '.js',}
    format_on_save = true,
    -- Time in MS before format timeout
    format_timeout = 3000,
    -- Set to false to disable rename notification
    rename_notification = true,
    -- Enable non-default servers, use default lsp config
    -- Check here for configs that will be used by default: https://github.com/williamboman/nvim-lsp-installer/tree/main/lua/nvim-lsp-installer/servers

    -- lsp servers that should be installed
    ensure_installed = {
      'rust_analyzer',
    },

    -- lsp servers that should be enabled
    servers = {
      -- Enable rust_analyzer
      rust_analyzer = true,

      -- Enable tsserver w/custom settings
      tsserver = {},
      -- See Cosmic defaults lsp/providers/null_ls.lua and https://github.com/jose-elias-alvarez/null-ls.nvim/
      -- If adding additional sources, be sure to also copy the defaults that you would like to preserve from lsp/providers/null_ls.lua
      null_ls = {
        -- Disable default list of sources provided by CosmicNvim
        default_cosmic_sources = false,
        --disable formatting
        format = false,
        -- Add additional sources here
        get_sources = function()
          local null_ls = require('null-ls')
          return {
            null_ls.builtins.diagnostics.shellcheck,
            null_ls.builtins.diagnostics.actionlint.with({
              condition = function()
                local cwd = vim.fn.expand('%:p:.')
                return cwd:find('.github/workflows')
              end,
            }),
          }
        end,
      },
    },
    -- See Cosmic defaults lua/plugins/nvim-lsp-ts-utils/setup.lua
    ts_utils = {},
  },

  -- adjust default plugin settings
  plugins = {
    -- See https://github.com/rmagatti/auto-session#%EF%B8%8F-configuration
    auto_session = {},
    -- https://github.com/numToStr/Comment.nvim#configuration-optional
    comment_nvim = {},
    -- See https://github.com/CosmicNvim/cosmic-ui#%EF%B8%8F-configuration
    cosmic_ui = {},
    -- See :h vim.diagnostic.config for all diagnostic configuration options
    diagnostic = {},
    -- See :h gitsigns-usage
    gitsigns = {},
    -- See https://git.sr.ht/~whynothugo/lsp_lines.nvim
    lsp_lines = {
      -- additional flag only for CosmicNvim
      -- true - loads plugin and is enabled at start
      -- false - loads plugin but is not enabled at start
      -- you may use <leader>ld to toggle
      enable_on_start = true,
    },
    -- See https://github.com/ray-x/lsp_signature.nvim#full-configuration-with-default-values
    lsp_signature = {},
    -- See https://github.com/nvim-lualine/lualine.nvim#default-configuration
    lualine = {},
    -- See https://github.com/L3MON4D3/LuaSnip/blob/577045e9adf325e58f690f4d4b4a293f3dcec1b3/README.md#config
    luasnip = {},
    -- See :h telescope.setup
    telescope = {},
    -- See https://github.com/folke/todo-comments.nvim#%EF%B8%8F-configuration
    todo_comments = {},
    -- See :h nvim-treesitter-quickstart
    treesitter = {},
    -- See :h cmp-usage
    nvim_cmp = {},
    -- See :h nvim-tree.setup
    nvim_tree = {},
    dbtpal = {},
  },

  -- Disable plugins default enabled by CosmicNvim
  disable_builtin_plugins = {
    --[[
    'auto-session',
    'colorizer',
    'comment-nvim',
    'dashboard',
    'fugitive',
    'gitsigns',
    'lualine',
    'noice',
    'nvim-cmp',
    'nvim-tree',
    'telescope',
    'terminal',
    'theme',
    'todo-comments',
    'treesitter',
    ]]
  },

  -- Add additional plugins (lazy.nvim)
  add_plugins = {
    { 'github/copilot.vim', lazy = false },
    { 'fabi1cazenave/termopen.vim', lazy = false },
    -- 'ggandor/lightspeed.nvim',
    -- {
    --  'romgrk/barbar.nvim',
    --   dependencies = { 'kyazdani42/nvim-web-devicons' },
    -- },
    {
      'PedramNavid/dbtpal',
      lazy = false,
      -- keys = {}
      config = function()
        local dbt = require('dbtpal')
        dbt.setup({
          -- Path to the dbt executable
          path_to_dbt = 'dbt',

          -- Path to the dbt project, if blank, will auto-detect
          -- using currently open buffer for all sql,yml, and md files
          path_to_dbt_project = '',

          -- Path to dbt profiles directory
          path_to_dbt_profiles_dir = vim.fn.expand('~/.dbt'),

          -- Search for ref/source files in macros and models folders
          extended_path_search = true,

          -- Prevent modifying sql files in target/(compiled|run) folders
          protect_compiled_files = true,
        })

        -- Setup key mappings
        vim.keymap.set('n', '<leader>drp', dbt.run_all)
        vim.keymap.set('n', '<leader>dtf', dbt.test)
        vim.keymap.set('n', '<leader>dm', require('dbtpal.telescope').dbt_picker)

        -- Enable Telescope Extension
        require('telescope').load_extension('dbtpal')
      end,
      requires = { { 'nvim-lua/plenary.nvim' }, { 'nvim-telescope/telescope.nvim' } },
    },
  },
}

return config
