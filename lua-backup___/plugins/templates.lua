--- Author: satanisticmicrowave

local templates = {
  extension = {},
  filename = {},
  __default__ = function() end,
}

local function add_new_template(name, template_name, is_by_filename)
  is_by_filename = is_by_filename or false

  templates[is_by_filename and "filename" or "extension"][name] = function()
    if vim.fn.exists ":Template" > 0 then
      local wrapped_func = vim.schedule_wrap(function()
        vim.cmd("Template " .. template_name)

        vim.defer_fn(function()
          if vim.bo.modified then vim.cmd "silent write" end
        end, 50)
      end)

      wrapped_func()
    end
  end
end

local function add_new_variable(name, variable)
  require("template").register(
    "{{_" .. name .. "_}}",
    type(variable) == "function" and variable or function() return variable end
  )
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",

  callback = function(args)
    local buf = args.buf
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")

    local line_count = vim.api.nvim_buf_line_count(buf)
    if line_count > 1 then return end

    local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    if first_line ~= "" then return end

    if templates.filename[filename] then
      templates.filename[filename]()
    else
      local ext = filename:match ".*%.(.*)$" or ""

      if templates.extension[ext] then
        templates.extension[ext]()
      else
        templates.__default__()
      end
    end
  end,
})

add_new_template("cpp", "cpp_source")
add_new_template("hpp", "cpp_header")

add_new_template("CMakeLists.txt", "CMakeLists", true)

return {
  {
    "glepnir/template.nvim",
    cmd = { "Template", "TemProject" },
    config = function()
      require("template").setup {
        temp_dir = "~/.config/nvim/templates/",
        author = "satanisticmicrowave",
        email = "satanisticmicrowave@ya.ru",
      }

      add_new_variable("current_date", function() return os.date "%Y-%m-%d %H:%M:%S" end)
      add_new_variable("project_name", function() return vim.fs.basename(vim.fn.getcwd()) end)

      add_new_variable(
        "package",
        function() return vim.api.nvim_buf_get_name(0):gsub(vim.fn.getcwd(), ""):gsub("^/", "") end
      )

      add_new_variable(
        "include_guard",
        function()
          return (vim.fs.basename(vim.fn.getcwd()) .. "_" .. vim.api.nvim_buf_get_name(0):sub(#vim.fn.getcwd() + 2))
            :gsub("[^%w]", "_")
            :upper() .. "_" .. tostring(os.time()):sub(-6)
        end
      )
      
    end,
  },
}
