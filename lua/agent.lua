-- Minimal Ollama coding agent for Neovim
-- ~150 lines. You can read every one.

local M = {}

M.config = {
  model = "glm-5.1:cloud",
  ollama_url = "http://localhost:11434",
  prompt_prefix = "Write only the code, no explanation, no markdown fences. Language: %s\n",
  prompt_prefix_context = "Write only the code, no explanation, no markdown fences. Language: %s\n\n--- Context ---\n%s\n\n--- Instruction ---\n",
  prompt_prefix_question = "Answer the following question concisely. Language: %s\n\n",
  prompt_prefix_question_context = "Answer the following question concisely, using the provided context. Language: %s\n\n--- Context ---\n%s\n\n--- Question ---\n",
  timeout = 120,
}

M._tmpfile = nil

------------------------------------------------------------------------
-- UTILS
------------------------------------------------------------------------

local function get_comment_prefix()
  local cms = vim.bo.commentstring
  if cms == "" then return "//" end
  local prefix = cms:match("^(.-)%%s")
  if prefix then
    return prefix:gsub("%s+$", "")
  end
  return cms:gsub("%%s", ""):gsub("%s+", "")
end

local function extract_prompt()
  local line = vim.api.nvim_get_current_line()
  local prefix = get_comment_prefix()
  local suffix = vim.bo.commentstring:match("%%s(.+)$")
  if suffix then
    suffix = suffix:gsub("^%s+", "")
  end

  local prompt
  local start = line:find(vim.pesc(prefix), 1, true)
  if start then
    prompt = line:sub(start + #prefix):gsub("^%s+", "")
    if suffix then
      prompt = prompt:gsub("%s*" .. vim.pesc(suffix) .. "%s*$", "")
    end
  else
    prompt = line:gsub("^%s*", "")
  end

  if prompt == "" then
    vim.notify("agent: current line is not a comment or is empty", vim.log.levels.WARN)
    return nil, nil
  end

  local is_question = false
  if prompt:sub(1, 1) == "?" then
    is_question = true
    prompt = prompt:sub(2):gsub("^%s+", "")
  end

  if prompt == "" then
    vim.notify("agent: current line is not a comment or is empty", vim.log.levels.WARN)
    return nil, nil
  end
  return prompt, is_question
end

local function get_filetype()
  return vim.bo.filetype or "unknown"
end

local function get_context_file()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

------------------------------------------------------------------------
-- STRIP MODEL VERBIAGE
------------------------------------------------------------------------

local function clean_response(raw)
  -- Models love markdown fences. Strip them.
  -- Handles ```javascript ... ``` and variants
  local code = raw

  -- Remove opening ```lang fence
  code = code:gsub("^.-```%w*\n", "")
  -- Remove closing ```
  code = code:gsub("\n```.-$", "")
  -- If the whole thing is wrapped in fences on one block
  code = code:gsub("```%w*\n", "")
  code = code:gsub("```", "")

  -- Trim leading/trailing blank lines
  code = code:gsub("^\n+", "")
  code = code:gsub("\n+$", "")

  return code
end

------------------------------------------------------------------------
-- RE-INDENT PASTED CODE
------------------------------------------------------------------------

local function get_current_indent()
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^(%s*)") or ""
  return indent
end

local function re_indent(lines, base_indent)
  if base_indent == "" then return lines end

  -- Find minimum indent of pasted code
  local min_indent = nil
  for _, l in ipairs(lines) do
    if l:match("%S") then -- non-blank line
      local ind = l:match("^(%s*)") or ""
      local count = #ind
      if min_indent == nil or count < min_indent then
        min_indent = count
      end
    end
  end

  if min_indent == nil or min_indent == 0 then
    -- Just prepend base_indent to each line
    local result = {}
    for _, l in ipairs(lines) do
      if l:match("%S") then
        table.insert(result, base_indent .. l)
      else
        table.insert(result, "")
      end
    end
    return result
  end

  -- Strip existing min_indent, add base_indent
  local result = {}
  for _, l in ipairs(lines) do
    if l:match("%S") then
      table.insert(result, base_indent .. l:sub(min_indent + 1))
    else
      table.insert(result, "")
    end
  end
  return result
end

------------------------------------------------------------------------
-- INSERT RESULT
------------------------------------------------------------------------

local function insert_below_cursor(text)
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local base_indent = get_current_indent()
  local lines = vim.split(text, "\n")
  lines = re_indent(lines, base_indent)

  vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
end

local function insert_as_comments(text)
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local prefix = get_comment_prefix()
  local base_indent = get_current_indent()

  local lines = vim.split(text, "\n")
  lines = re_indent(lines, base_indent)

  local commented = {}
  for _, l in ipairs(lines) do
    if l:match("%S") then
      table.insert(commented, prefix .. " " .. l)
    else
      table.insert(commented, prefix)
    end
  end

  vim.api.nvim_buf_set_lines(buf, row, row, false, commented)
end

------------------------------------------------------------------------
-- CALL OLLAMA (async via vim.fn.jobstart)
------------------------------------------------------------------------

local active_job = nil

local function do_assist(context)
  if active_job then
    vim.notify("agent: request already in progress", vim.log.levels.WARN)
    return
  end

  local prompt, is_question = extract_prompt()
  if not prompt then return end

  local ft = get_filetype()
  local full_prompt
  if is_question then
    if context then
      full_prompt = string.format(M.config.prompt_prefix_question_context, ft, context) .. prompt
    else
      full_prompt = string.format(M.config.prompt_prefix_question, ft) .. prompt
    end
  else
    if context then
      full_prompt = string.format(M.config.prompt_prefix_context, ft, context) .. prompt
    else
      full_prompt = string.format(M.config.prompt_prefix, ft) .. prompt
    end
  end

  -- Build request body
  local body = vim.json.encode({
    model = M.config.model,
    prompt = full_prompt,
    stream = false,
  })

  -- Write body to temp file (avoids shell escaping nightmares)
  local tmp = os.tmpname()
  local f, err = io.open(tmp, "w")
  if not f then
    vim.notify("agent: failed to create temp file: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end
  f:write(body)
  f:close()
  M._tmpfile = tmp

  local url = M.config.ollama_url .. "/api/generate"
  local output_chunks = {}

  vim.notify("agent: asking " .. M.config.model .. "...", vim.log.levels.INFO)

  active_job = vim.fn.jobstart({
    "curl", "-s", "--max-time", tostring(M.config.timeout),
    "-d", "@" .. tmp,
    "-H", "Content-Type: application/json",
    url,
  }, {
    on_stdout = function(_, data, _)
      for _, chunk in ipairs(data) do
        table.insert(output_chunks, chunk)
      end
    end,
    on_exit = function(_, exit_code, _)
      active_job = nil
      os.remove(tmp)
      M._tmpfile = nil

      if exit_code ~= 0 then
        vim.notify("agent: curl failed (exit " .. exit_code .. ")", vim.log.levels.ERROR)
        return
      end

      local raw = table.concat(output_chunks, "\n")

      -- Ollama returns JSON with a "response" field
      local ok, decoded = pcall(vim.json.decode, raw)
      if not ok or not decoded or not decoded.response then
        vim.notify("agent: failed to parse Ollama response", vim.log.levels.ERROR)
        return
      end

      local cleaned = clean_response(decoded.response)
      if cleaned == "" then
        vim.notify("agent: model returned empty response", vim.log.levels.WARN)
        return
      end

      if is_question then
        insert_as_comments(cleaned)
      else
        insert_below_cursor(cleaned)
      end
      vim.notify("agent: done", vim.log.levels.INFO)
    end,
  })

  if active_job <= 0 then
    active_job = nil
    os.remove(tmp)
    M._tmpfile = nil
    vim.notify("agent: failed to start curl", vim.log.levels.ERROR)
    return
  end
end

function M.assist()
  do_assist(nil)
end

function M.assist_file()
  do_assist(get_context_file())
end

------------------------------------------------------------------------
-- SETUP (optional, for overriding defaults)
------------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M._tmpfile then
        os.remove(M._tmpfile)
        M._tmpfile = nil
      end
    end,
  })
end

return M
