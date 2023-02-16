# floating-input.nvim
Super simple Neovim floating input.

![screenshot](https://user-images.githubusercontent.com/1334962/219470205-7412c323-abd0-4074-9c61-da9a45432d47.jpg)

## Why

You use Telescope or Fzf-Lua to get a nice `vim.ui.select`, and want a nice `vim.ui.input` too?

[Dressing](https://github.com/stevearc/dressing.nvim) works, but most of its code deals with
`ui.select`, which seems slightly overkill here.

This plugin is a simple floating window to take input, with less than 50 less of code.
You can either use it or just copy it to your configs.

## How

Add `liangxianzhe/floating-input` to your plugin manager. Then `require('floating-input').setup()`.

Default is to put floating window at the center. If you like it near the cursor, override with: 

```lua
vim.ui.input = function(opts, on_confirm)
	require("floating-input").input(opts, on_confirm, { relative = 'cursor', row = 1, col = 0 })
end
```
