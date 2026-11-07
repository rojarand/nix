return {
  {
    'stevearc/oil.nvim',
    opts = { view_options = { show_hidden = true } },
    keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File Browser' } },
  },
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    init = function()
      -- snacks.nvim resolves the ripgrep binary by the bare name "rg", which
      -- only works when nvim already inherited a PATH containing Nix's profile.
      -- GUI launches on macOS and login shells on Linux often do not, which
      -- makes the grep picker fail with "Failed to spawn rg". Point it at an
      -- absolute path so searching works regardless of how nvim was started.
      local rg = vim.fn.exepath('rg')
      if rg == '' then
        local profile = vim.fn.expand('~/.nix-profile/bin/rg')
        if vim.uv.fs_stat(profile) then
          rg = profile
        end
      end
      if rg ~= '' then
        -- Prepend the directory so any bare-name spawn (`rg` included) resolves.
        vim.env.PATH = vim.fs.dirname(rg) .. ':' .. vim.env.PATH
      end
    end,
    opts = {
      picker = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
    },
    keys = {
      { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },
      { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    },
  },
}
