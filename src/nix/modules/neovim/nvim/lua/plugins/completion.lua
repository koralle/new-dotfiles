return {
  -- https://github.com/saghen/blink.cmp
  'saghen/blink.cmp',
  dependencies = {
    'saghen/blink.lib',
    'rafamadriz/friendly-snippets',

    -- https://github.com/xzbdmw/colorful-menu.nvim
    'xzbdmw/colorful-menu.nvim'
  },
  build = function()
    -- build the fuzzy matcher, optionally add a timeout to `pwait(timeout_ms)`
    -- you can use `gb` in `:Lazy` to rebuild the plugin as needed
    require('blink.cmp').build():pwait()
  end,
  config = function() 
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    local blink_opts = {
      -- https://main.cmp.saghen.dev/configuration/keymap.html
      keymap = {
        preset = 'default',
        ['<C-l>'] = { 'show_documentation', 'hide_documentation' },
        ['<C-j>'] = { 'select_next' },
        ['<C-k>'] = { 'select_prev' },
        ['<C-x><C-o>'] = { 'show', 'fallback' },
        ['<C-i>'] = { 'accept', 'snippet_forward', 'fallback' },
      },
      completion = {
        documentation = {
          auto_show = true,
          window = {
            border = 'single'
          }
        },
        menu = {
          border = 'single',
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 }
            },
            components = {
              label = {
                text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          }
        }
      },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = "rust" },

      cmdline = {
        keymap = { preset = 'inherit' },
        completion = { menu = { auto_show = true } },
      },

      signature = { 
        enabled = true,
        window = {
          border = 'single'
        }
      }
    }

    require('blink.cmp').setup(blink_opts)
  end
}
