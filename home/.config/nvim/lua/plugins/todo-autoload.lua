return {
  dir = vim.fn.stdpath("config"),
  name = "todo-autoload",
  config = function()
    require("todo-autoload").setup()
  end,
}

