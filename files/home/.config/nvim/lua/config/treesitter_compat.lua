-- Neovim 0.12 と nvim-treesitter (legacy master) の互換シム
--
-- 0.12 では query の iter_matches が返す captures が
--   旧: table<integer, TSNode>     (単一ノード)
--   新: table<integer, TSNode[]>  (ノード配列)
-- に変わった。nvim-treesitter のカスタム predicate/directive は
-- 旧API前提のため match[capture_id] を配列のまま TSNode として
-- 使ってしまい、`attempt to call method 'range'` でクラッシュする。
-- （例: markdown の ```bash コードブロック -> README を開くとエラー）
--
-- ここでは配列をアンラップして再登録することで互換性を確保する。

local M = {}

local function unwrap(v)
  if type(v) == "table" then
    return v[1]
  end
  return v
end

local function first_node(match, capture_id)
  local v = match[capture_id]
  if type(v) == "table" then
    return v[1]
  end
  return v
end

local html_script_type_languages = {
  ["importmap"] = "json",
  ["module"] = "javascript",
  ["application/ecmascript"] = "javascript",
  ["text/ecmascript"] = "javascript",
}

local non_filetype_match_injection_language_aliases = {
  ex = "elixir",
  pl = "perl",
  sh = "bash",
  uxn = "uxntal",
  ts = "typescript",
}

local function get_parser_from_markdown_info_string(injection_alias)
  local match = vim.filetype.match({ filename = "a." .. injection_alias })
  return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
end

local opts = { force = true, all = false }

function M.apply()
  -- nvim-treesitter 側の（旧APIの）登録を確実に済ませてから上書きする
  require("nvim-treesitter")
  local query = require("vim.treesitter.query")

  -- ▼ predicates ----------------------------------------------------------

  query.add_predicate("nth?", function(captures, _, _, pred)
    local node = first_node(captures, pred[2])
    local n = tonumber(pred[3])
    if node and node:parent() and node:parent():named_child_count() > n then
      return node:parent():named_child(n) == node
    end
    return false
  end, opts)

  query.add_predicate("is?", function(captures, _, source, pred)
    local locals = require("nvim-treesitter.locals")
    local node = first_node(captures, pred[2])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end
    local _, _, kind = locals.find_definition(node, source)
    return vim.tbl_contains(types, kind)
  end, opts)

  query.add_predicate("kind-eq?", function(captures, _, _, pred)
    local node = first_node(captures, pred[2])
    local types = { unpack(pred, 3) }
    if not node then
      return true
    end
    return vim.tbl_contains(types, node:type())
  end, opts)

  -- ▼ directives ----------------------------------------------------------

  query.add_directive("set-lang-from-mimetype!", function(captures, _, source, pred, metadata)
    local node = first_node(captures, pred[2])
    if not node then
      return
    end
    local type_attr_value = vim.treesitter.get_node_text(node, source)
    local configured = html_script_type_languages[type_attr_value]
    if configured then
      metadata["injection.language"] = configured
    else
      local parts = vim.split(type_attr_value, "/", {})
      metadata["injection.language"] = parts[#parts]
    end
  end, opts)

  query.add_directive("set-lang-from-info-string!", function(captures, _, source, pred, metadata)
    local node = first_node(captures, pred[2])
    if not node then
      return
    end
    local injection_alias = vim.treesitter.get_node_text(node, source):lower()
    metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
  end, opts)

  query.add_directive("make-range!", function() end, opts)

  query.add_directive("downcase!", function(captures, _, source, pred, metadata)
    local id = pred[2]
    local node = first_node(captures, id)
    if not node then
      return
    end
    local text = vim.treesitter.get_node_text(node, source, { metadata = metadata[id] }) or ""
    if not metadata[id] then
      metadata[id] = {}
    end
    metadata[id].text = string.lower(text)
  end, opts)
end

return M
