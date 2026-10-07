-- lua/plugins/catppuccin.lua
return {
  -- 1. 告诉 LazyVim 默认全局配色为 Catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  -- 2. Catppuccin Mocha 主题配置（catppuccin/nvim，支持真彩色）
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      -- 固定为深色的 Mocha 风格（另有 latte / frappe / macchiato 可选）
      flavour = "mocha",
      -- 透明背景，保持与编辑器底色一致的简洁观感
      transparent_background = true,
      styles = {
        comments = { "italic" },
        keywords = { "italic" },
      },
      integrations = {
        bufferline = true,
        lualine = true,
      },
    },
  },
}
