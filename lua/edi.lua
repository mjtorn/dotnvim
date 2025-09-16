-- lua/edi.lua — EDIFACT/X12 helper for Neovim
-- Features
--   :EdiPretty            toggle logical-lines view IN PLACE (q to return)
--   Hover on K            segment/element/component + code meaning (from JSON)
--   Jumps                 ]m/[m  ]g/[g  ]i/[i   (message/group/interchange)
--   Text-objects          im/am  ig/ag  ii/ai  (pretty view)
--   SG annotations        from JSON schema (case-insensitive; groups/segment_groups)
--   :EdiSgWhich           show which SG schema matched (or the best candidate)
--   :EdiSgDump            dump normalized SG tree the annotator sees
--   :EdiFetchEdifactAll   fetch UNCL 0001..9999 code lists (JSON-LD → flat map)
--   :EdiFetchStatus, :EdiReloadData

local M = {}

-- ---------------------------------------------------------------------------
-- State & configuration
-- ---------------------------------------------------------------------------
local state = {
  float_win = nil,
  float_buf = nil,
  float_pos = nil,
  augroup = nil,
  cfg = {
    data_dir = vim.fn.stdpath("config") .. "/edi-data",
    dict_overrides = {},
    hover = {
      max_width = 96,
      close_events = {
        "CursorMoved",
        "CursorMovedI",
        "InsertEnter",
        "BufLeave",
        "WinLeave",
        "WinScrolled",
        "ModeChanged",
        "TermEnter"
      }
    },
    annotate = true
  },
  data = {x12 = {segments = {}, codes = {}}, edifact = {segments = {}, codes = {}}},
  schema_cache = {} -- key "TYPE:REL:AGY:ASSOC" → schema or false
}

-- ---------------------------------------------------------------------------
-- Utils
-- ---------------------------------------------------------------------------
local function buf_text(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
end
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
local function esc(s)
  return (s:gsub("([^%w])", "%%%1"))
end
local function merge(dst, src)
  for k, v in pairs(src or {}) do
    if type(v) == "table" and type(dst[k]) == "table" then
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end
end
local function ensure_dir(path)
  local sep = package.config:sub(1, 1)
  local acc = (path:sub(1, 1) == sep) and sep or ""
  for part in path:gmatch("[^" .. esc(sep) .. "]+") do
    acc = (acc == "" and part) or (acc .. sep .. part)
    vim.loop.fs_mkdir(acc, 493) -- 0755
  end
end
local function write_json_atomically(path, tbl)
  local data = vim.fn.json_encode(tbl)
  if not data or #data == 0 then
    return false
  end
  local dir = path:match("^(.*)/[^/]+$")
  if dir then
    ensure_dir(dir)
  end
  local tmp = path .. ".tmp_" .. vim.loop.hrtime()
  local fd = vim.loop.fs_open(tmp, "w", 420)
  if not fd then
    return false
  end
  local ok = vim.loop.fs_write(fd, data, 0)
  vim.loop.fs_close(fd)
  if not ok then
    pcall(vim.loop.fs_unlink, tmp)
    return false
  end
  pcall(vim.loop.fs_rename, tmp, path)
  return true
end
local function load_json(path)
  local ok, fd = pcall(vim.loop.fs_open, path, "r", 438)
  if not ok or not fd then
    return nil
  end
  local st = vim.loop.fs_fstat(fd)
  if not st then
    vim.loop.fs_close(fd)
    return nil
  end
  local data = vim.loop.fs_read(fd, st.size, 0)
  vim.loop.fs_close(fd)
  if not data or #data == 0 then
    return nil
  end
  local ok2, dec = pcall(vim.fn.json_decode, data)
  if not ok2 then
    return nil
  end
  return dec
end

-- ---------------------------------------------------------------------------
-- Data loading (segments & code lists). Segment titles have a small builtin
-- to have something even without external JSON; code meanings come only from
-- JSON under data_dir/{edifact|x12}/codes/<id>.json
-- ---------------------------------------------------------------------------
local BUILTIN = {
  edifact = {
    segments = {
      UNB = {
        title = "Interchange Header",
        elements = {
          {name = "S001 Syntax identifier"},
          {name = "S002 Interchange sender"},
          {name = "S003 Interchange recipient"},
          {name = "S004 Date/time of preparation"},
          {name = "0020 Interchange control reference", id = "0020"},
          {name = "S005 Recipient's reference/password"},
          {name = "0026 Application reference", id = "0026"},
          {name = "0029 Processing priority code", id = "0029"},
          {name = "0031 Acknowledgement request", id = "0031"},
          {name = "0032 Interchange agreement identifier", id = "0032"},
          {name = "0035 Test indicator", id = "0035"}
        }
      },
      UNH = {
        title = "Message Header",
        elements = {
          {name = "0062 Message reference number", id = "0062"},
          {
            name = "S009 Message identifier",
            components = {
              {name = "0065 Message type", id = "0065"},
              {name = "0052 Version", id = "0052"},
              {name = "0054 Release", id = "0054"},
              {name = "0051 Agency", id = "0051"},
              {name = "0057 Association code", id = "0057"}
            }
          },
          {name = "0068 Common access reference", id = "0068"},
          {name = "S010 Status of transfer"}
        }
      },
      BGM = {
        title = "Beginning of message",
        elements = {
          {
            name = "C002 Document/message name",
            components = {
              {name = "1001 Document name code", id = "1001"},
              {name = "1131 Code list ID", id = "1131"},
              {name = "3055 Code list agency", id = "3055"},
              {name = "1000 Document name", id = "1000"}
            }
          },
          {name = "C106 Document message ID"},
          {name = "1225 Message function, coded", id = "1225"},
          {name = "4343 Response type, coded", id = "4343"}
        }
      },
      DTM = {
        title = "Date/time/period",
        elements = {
          {
            name = "C507 Date/time/period",
            components = {
              {name = "2005 Qualifier", id = "2005"},
              {name = "2380 Date/time/period", id = "2380"},
              {name = "2379 Format qualifier", id = "2379"}
            }
          }
        }
      },
      RFF = {
        title = "Reference",
        elements = {
          {
            name = "C506 Reference",
            components = {
              {name = "1153 Reference qualifier", id = "1153"},
              {name = "1154 Reference number", id = "1154"},
              {name = "1156 Line number", id = "1156"},
              {name = "4000 Reference version", id = "4000"}
            }
          }
        }
      },
      NAD = {
        title = "Name and address",
        elements = {
          {name = "3035 Party qualifier", id = "3035"},
          {name = "C082 Party identification"},
          {name = "C058 Name and address"},
          {name = "C080 Party name"},
          {name = "C059 Street"},
          {name = "3164 City", id = "3164"},
          {name = "3251 Postcode", id = "3251"},
          {name = "3207 Country", id = "3207"}
        }
      },
      ERC = {
        title = "Application Error Information",
        elements = {
          {
            name = "C901 Application error detail",
            components = {
              {name = "9321 Application error identification", id = "9321"},
              {name = "1131 Code list ID", id = "1131"},
              {name = "3055 Agency", id = "3055"}
            }
          }
        }
      },
      FTX = {title = "Free text"},
      LIN = {title = "Line item"},
      QTY = {title = "Quantity"},
      PRI = {title = "Price details"},
      MOA = {title = "Monetary amount"},
      UNT = {title = "Message Trailer"},
      UNZ = {title = "Interchange Trailer"}
    }
  },
  x12 = {
    segments = {
      ISA = {title = "Interchange Control Header"},
      GS = {title = "Functional Group Header"},
      ST = {title = "Transaction Set Header"},
      SE = {title = "Transaction Set Trailer"},
      GE = {title = "Functional Group Trailer"},
      IEA = {title = "Interchange Control Trailer"}
    }
  }
}

local function try_load_data_dir()
  local base = state.cfg.data_dir
  state.data = {x12 = {segments = {}, codes = {}}, edifact = {segments = {}, codes = {}}}

  -- optional extended segment metadata
  local x12_seg = load_json(base .. "/x12/segments.json")
  local edf_seg = load_json(base .. "/edifact/segments.json")
  state.data.x12.segments = x12_seg or {}
  state.data.edifact.segments = edf_seg or {}

  -- code lists
  for _, fl in ipairs({"x12", "edifact"}) do
    local dir = base .. "/" .. fl .. "/codes"
    local h = vim.loop.fs_scandir(dir)
    if h then
      while true do
        local name, typ = vim.loop.fs_scandir_next(h)
        if not name then
          break
        end
        if typ == "file" and name:match("%.json$") then
          local id = name:gsub("%.json$", "")
          local obj = load_json(dir .. "/" .. name)
          if obj and type(obj) == "table" then
            state.data[fl].codes[id] = obj
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Detect flavor & split
-- ---------------------------------------------------------------------------
local function detect_edi(bufnr)
  local head = buf_text(bufnr):sub(1, 4000)
  local has_ISA = head:find("ISA", 1, true)
  local has_UNB = head:find("UNB", 1, true)
  local has_UNA = head:find("UNA", 1, true)
  if has_UNB or has_UNA then
    return {flavor = "edifact", seg = "'", elem = "+", comp = ":", release = "?"}
  end
  local seg = "~"
  if head:find("\r\n", 1, true) then
    seg = "\r\n"
  elseif head:find("\n", 1, true) then
    seg = "\n"
  end
  local elem = "*"
  do
    local isa_at = head:find("ISA", 1, true)
    if isa_at then
      local c = head:sub(isa_at + 3, isa_at + 12):match("[^%w]")
      if c then
        elem = c
      end
    end
  end
  return {flavor = "x12", seg = seg, elem = elem, comp = ":", release = nil, repeat_sep = "^"}
end

local function split_segments(s, term, release)
  local segs, cur = {}, {}
  local function flush()
    local piece = table.concat(cur)
    piece = trim(piece)
    if #piece > 0 then
      table.insert(segs, piece)
    end
    cur = {}
  end
  local i, n = 1, #s
  while i <= n do
    local ch = s:sub(i, i)
    if release and ch == release then
      local nxt = (i < n) and s:sub(i + 1, i + 1) or ""
      table.insert(cur, ch)
      if nxt ~= "" then
        table.insert(cur, nxt)
      end
      i = i + ((nxt ~= "") and 2 or 1)
    elseif ch == term then
      flush()
      i = i + 1
    else
      if term == "\r\n" and ch == "\r" and s:sub(i + 1, i + 1) == "\n" then
        flush()
        i = i + 2
      else
        table.insert(cur, ch)
        i = i + 1
      end
    end
  end
  flush()
  return segs
end

local function seg_tag(seg, elem_sep)
  return seg:match("^%s*([^" .. esc(elem_sep) .. "%s]+)") or seg
end

-- ---------------------------------------------------------------------------
-- Pretty printer & syntax
-- ---------------------------------------------------------------------------
local X12_PUSH = {ISA = true, GS = true, ST = true}
local X12_POP = {IEA = true, GE = true, SE = true}
local EDI_PUSH = {UNB = true, UNG = true, UNH = true}
local EDI_POP = {UNZ = true, UNE = true, UNT = true}

local function compute_indent(tag, flavor, depth)
  local d = depth
  if flavor == "x12" then
    if X12_POP[tag] then
      d = math.max(0, d - 1)
    end
    return d, (X12_PUSH[tag] and 1 or 0)
  else
    if EDI_POP[tag] then
      d = math.max(0, d - 1)
    end
    return d, (EDI_PUSH[tag] and 1 or 0)
  end
end

local function pretty_text(src, cfg)
  local segs = split_segments(src, cfg.seg, cfg.release)
  local depth, out = 0, {}
  for _, raw in ipairs(segs) do
    local s = trim(raw)
    if s == "" then
      goto cont
    end
    local tag = seg_tag(s, cfg.elem)
    local cur, push = compute_indent(tag, cfg.flavor, depth)
    table.insert(out, string.rep("  ", cur) .. s)
    depth = cur + (push or 0)
    ::cont::
  end
  return table.concat(out, "\n")
end

local function apply_syntax(buf, cfg)
  vim.api.nvim_set_hl(0, "EdiSegmentTag", {link = "Label"})
  vim.api.nvim_set_hl(0, "EdiSep", {link = "Delimiter"})
  vim.api.nvim_set_hl(0, "EdiCompSep", {link = "Delimiter"})
  vim.api.nvim_set_hl(0, "EdiRelease", {link = "SpecialChar"})
  vim.api.nvim_set_hl(0, "EdiNum", {link = "Number"})
  vim.api.nvim_buf_call(
    buf,
    function()
      vim.cmd("syntax enable")
      vim.cmd("silent! syntax clear EdiSegmentTag EdiSep EdiCompSep EdiRelease EdiNum")
      vim.cmd([[syntax match EdiSegmentTag "^\s*\zs[A-Z][A-Z0-9]\{1,5\}\ze\>"]])
      vim.cmd("execute 'syntax match EdiSep /" .. esc(cfg.elem) .. "/'")
      if cfg.comp and #cfg.comp > 0 then
        vim.cmd("execute 'syntax match EdiCompSep /" .. esc(cfg.comp) .. "/'")
      end
      if cfg.release and #cfg.release > 0 then
        vim.cmd("execute 'syntax match EdiRelease /" .. esc(cfg.release) .. "/'")
      end
      vim.cmd([[syntax match EdiNum "\v(^|[^A-Z0-9])\zs\d+(\.\d+)?\ze([^A-Z0-9]|$)"]])
    end
  )
  vim.api.nvim_buf_set_option(buf, "filetype", (cfg.flavor == "x12") and "x12" or "edifact")
end

-- ---------------------------------------------------------------------------
-- Hover (raw & pretty)
-- ---------------------------------------------------------------------------
-- split_with_ranges: returns tokens with 0-based [s,e] (inclusive).
-- For empty fields (consecutive separators), e < s. That's OK; selection logic
-- relies primarily on token starts (s) and the next token's start.
local function split_with_ranges(s, sep, release)
  if not sep or sep == "" then
    return {{text = s, s = 0, e = #s - 1}}
  end
  local parts, cur, start = {}, {}, 0
  local i, n = 1, #s
  while i <= n do
    local ch = s:sub(i, i)
    if release and ch == release then
      local nxt = (i < n) and s:sub(i + 1, i + 1) or ""
      table.insert(cur, ch)
      if nxt ~= "" then
        table.insert(cur, nxt)
      end
      i = i + ((nxt ~= "") and 2 or 1)
    elseif ch == sep then
      local piece = table.concat(cur)
      table.insert(parts, {text = piece, s = start, e = i - 2})
      cur, start = {}, i -- start is 0-based col for the char AFTER this separator
      i = i + 1
    else
      table.insert(cur, ch)
      i = i + 1
    end
  end
  local piece = table.concat(cur)
  table.insert(parts, {text = piece, s = start, e = n - 1})
  return parts
end

-- Choose the segment under cursor; on the segment separator, prefer the previous segment
local function current_segment_at_cursor(cfg)
  local _, col = unpack(vim.api.nvim_win_get_cursor(0)) -- 0-based col
  local line = vim.api.nvim_get_current_line()

  -- Multi-segment physical line (e.g., EDIFACT using "'")
  if
    (cfg.seg == "\r\n" and line:find("\r\n", 1, true)) or
      (cfg.seg ~= "\r\n" and cfg.seg ~= "\n" and line:find(esc(cfg.seg)))
   then
    local segs = split_with_ranges(line, cfg.seg, cfg.release)
    -- First, try inside a segment (INCLUSIVE at start)
    for _, p in ipairs(segs) do
      if col >= p.s and col <= p.e then
        return trim(p.text), p.s, p.e
      end
    end
    -- Boundary: if we're on a separator, select the previous segment
    for i, p in ipairs(segs) do
      if col < p.s then
        if i > 1 then
          local prev = segs[i - 1]
          return trim(prev.text), prev.s, prev.e
        else
          return trim(p.text), p.s, p.e
        end
      end
    end
    -- Fallback: last segment
    local last = segs[#segs]
    return trim(last.text), last.s, last.e
  end

  -- Pretty view (one segment per line)
  local bol = line:find("%S")
  local indent = (bol and bol - 1) or #line
  local seg = line:sub(indent + 1)
  return trim(seg), indent, #line - 1
end

local function get_dict(flavor)
  local dict = vim.deepcopy(BUILTIN[flavor] or {})

  -- ensure tables exist before merging
  dict.segments = dict.segments or {}
  dict.codes = dict.codes or {}

  -- merge user data loaded from ~/.config/nvim/edi-data
  merge(dict.segments, state.data[flavor].segments or {})
  merge(dict.codes, state.data[flavor].codes or {})

  -- optional overrides
  local ov = state.cfg.dict_overrides and state.cfg.dict_overrides[flavor] or nil
  if ov then
    if ov.segments then
      merge(dict.segments, ov.segments)
    end
    if ov.codes then
      merge(dict.codes, ov.codes)
    end
    merge(dict, ov)
  end
  return dict
end

local function resolve_element_info(flavor, tag, elem_idx, comp_idx)
  local dict = get_dict(flavor)
  local sdef = dict.segments and dict.segments[tag]
  if not sdef then
    return nil
  end
  local edef = sdef.elements and sdef.elements[elem_idx]
  if not edef then
    return {seg = sdef, elem = nil}
  end
  if comp_idx and comp_idx > 0 and edef.components then
    local cdef = edef.components[comp_idx]
    return {seg = sdef, elem = edef, comp = cdef, codeset = (cdef and cdef.codeset) or (edef and edef.codeset)}
  end
  return {seg = sdef, elem = edef, comp = nil, codeset = edef.codeset}
end

local function codelist_lookup(flavor, id, code)
  if not id or not code then
    return nil
  end
  local dict = get_dict(flavor)
  local set = (dict.codes and (dict.codes[id] or dict.codes[tostring(id)] or dict.codes[tonumber(id) or id])) or nil
  if not set then
    return nil
  end
  return set[code] or set[tostring(code)] or set[tonumber(code) or code]
end

local function build_doc(cfg, seg, seg_s, _seg_e)
  local elems = split_with_ranges(seg, cfg.elem, cfg.release)
  local tag = (elems[1] and elems[1].text) and elems[1].text:gsub("^%s+", ""):gsub("%s+$", "") or seg
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local rel_col = col - seg_s

  -- Bias left if cursor is exactly on an element separator so we resolve to the previous element.
  do
    local ch = seg:sub(rel_col + 1, rel_col + 1)
    if ch == cfg.elem then
      rel_col = rel_col - 1
      if rel_col < 0 then rel_col = 0 end
    end
  end

  -- robust element picking; on a '+' separator, prefer the previous element.
  -- indexes: element #1 is elems[2] (elems[1] is the tag)
  local function pick_elem_at_cursor(tokens, rel)
    -- inside current element (INCLUSIVE at start)
    for i = 2, #tokens do
      local p = tokens[i]
      if rel >= p.s and rel <= p.e then
        return i - 1, p
      end
    end
    -- on separator before element i: choose previous (i-1), before first → 0
    for i = 2, #tokens do
      local p = tokens[i]
      if rel < p.s then
        if i == 2 then
          return 0, nil
        end
        return (i - 1) - 1 + 1, tokens[i - 1] -- i-1 index & piece of previous
      end
    end
    -- after last element → last
    if #tokens >= 2 then
      return (#tokens - 1), tokens[#tokens]
    end
    return 0, nil
  end

  local elem_idx, elem_piece = pick_elem_at_cursor(elems, rel_col)
  local elem_val = elem_piece and elem_piece.text or nil

  local comp_idx, comp_val = 0, nil
  if elem_piece and cfg.comp and #cfg.comp > 0 and elem_piece.text:find(esc(cfg.comp), 1, false) then
    local comps = split_with_ranges(elem_piece.text, cfg.comp, cfg.release)
    local rel_comp = rel_col - elem_piece.s

    -- Bias left if cursor is exactly on a component separator so we resolve to the previous component.
    do
      local ch2 = elem_piece.text:sub(rel_comp + 1, rel_comp + 1)
      if ch2 == cfg.comp then
        rel_comp = rel_comp - 1
        if rel_comp < 0 then rel_comp = 0 end
      end
    end

    local function pick_comp_at_cursor(ctokens, rel2)
      -- inside (INCLUSIVE at start)
      for j = 1, #ctokens do
        local c = ctokens[j]
        if rel2 >= c.s and rel2 <= c.e then
          return j, c
        end
      end
      -- on ':' separator before component j → choose previous (j-1), before first → 0
      for j = 1, #ctokens do
        local c = ctokens[j]
        if rel2 < c.s then
          if j == 1 then
            return 0, nil
          end
          return j - 1, ctokens[j - 1]
        end
      end
      -- after last component → last
      return #ctokens, ctokens[#ctokens]
    end
    local comp_piece
    comp_idx, comp_piece = pick_comp_at_cursor(comps, rel_comp)
    comp_val = comp_piece and comp_piece.text or nil
  end

  local info = resolve_element_info(cfg.flavor, tag, elem_idx, comp_idx)
  local seg_title = info and info.seg and info.seg.title or "Segment"
  local elem_name = info and info.elem and info.elem.name or nil
  local comp_name = info and info.comp and info.comp.name or nil
  local codeset = info and info.codeset or nil
  local code_value = comp_val or elem_val
  if code_value then
    code_value = trim(code_value)
  end
  local code_meaning = codelist_lookup(cfg.flavor, codeset, code_value)

  local lines = {}
  table.insert(
    lines,
    string.format("%s — %s%s", cfg.flavor:upper(), tag, seg_title and ("  (" .. seg_title .. ")") or "")
  )
  if elem_idx == 0 then
    table.insert(lines, "Position: segment ID (before first element)")
  else
    table.insert(lines, string.format("Element: %d%s", elem_idx, elem_name and (" — " .. elem_name) or ""))
    if comp_idx > 0 then
      table.insert(lines, string.format("Component: %d%s", comp_idx, comp_name and (" — " .. comp_name) or ""))
    end
  end
  if code_value and code_meaning then
    table.insert(lines, string.format("Code: %s — %s", code_value, code_meaning))
  end
  if comp_val then
    table.insert(lines, "Value: " .. comp_val)
  elseif elem_val then
    table.insert(lines, "Value: " .. elem_val)
  else
    table.insert(lines, "Segment: " .. seg)
  end
  local path =
    (elem_idx == 0) and tag or
    (comp_idx > 0 and string.format("%s[%d].%d", tag, elem_idx, comp_idx) or string.format("%s[%d]", tag, elem_idx))
  table.insert(lines, "Path: " .. path)
  local bits = {"seg='" .. cfg.seg .. "'", "elem='" .. cfg.elem .. "'"}
  if cfg.comp and #cfg.comp > 0 then
    table.insert(bits, "comp='" .. cfg.comp .. "'")
  end
  if cfg.release then
    table.insert(bits, "release='" .. cfg.release .. "'")
  end
  if codeset then
    table.insert(bits, "codeset='" .. tostring(codeset) .. "'")
  end
  table.insert(lines, "Delimiters: " .. table.concat(bits, "  "))
  return lines
end

-- float lifecycle
local function close_float()
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
    pcall(vim.api.nvim_win_close, state.float_win, true)
  end
  if state.float_buf and vim.api.nvim_buf_is_valid(state.float_buf) then
    pcall(vim.api.nvim_buf_delete, state.float_buf, {force = true})
  end
  state.float_win, state.float_buf, state.float_pos = nil, nil, nil
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end
end
local function show_float(lines)
  close_float()
  local maxw = 0
  for _, l in ipairs(lines) do
    if #l > maxw then
      maxw = #l
    end
  end
  local width = math.min(state.cfg.hover.max_width or 96, math.max(30, maxw + 2))
  local height = math.min(20, #lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  local win =
    vim.api.nvim_open_win(
    buf,
    false,
    {
      relative = "cursor",
      row = 1,
      col = 1,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
      noautocmd = true
    }
  )
  state.float_win, state.float_buf = win, buf
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  state.float_pos = {row = row, col = col}
  state.augroup = vim.api.nvim_create_augroup("edi-hover-" .. tostring(win), {clear = true})
  for _, ev in ipairs(state.cfg.hover.close_events or {}) do
    vim.api.nvim_create_autocmd(ev, {group = state.augroup, callback = close_float})
  end
  vim.keymap.set("n", "<Esc>", close_float, {buffer = buf, nowait = true, silent = true})
  vim.keymap.set("n", "q", close_float, {buffer = buf, nowait = true, silent = true})
  vim.keymap.set("n", "<CR>", close_float, {buffer = buf, nowait = true, silent = true})
end

function M.hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = detect_edi(bufnr)
  local seg, s, e = current_segment_at_cursor(cfg)
  if not seg or seg == "" then
    return
  end
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) and state.float_pos then
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    if state.float_pos.row == r and state.float_pos.col == c then
      close_float()
      return
    end
  end
  show_float(build_doc(cfg, seg, s, e))
end

-- ---------------------------------------------------------------------------
-- Pretty annotations: standard scopes + SG from schema
-- ---------------------------------------------------------------------------
vim.api.nvim_set_hl(0, "EdiScopeInterchange", {link = "Title"})
vim.api.nvim_set_hl(0, "EdiScopeGroup", {link = "PreProc"})
vim.api.nvim_set_hl(0, "EdiScopeMessage", {link = "Identifier"})
vim.api.nvim_set_hl(0, "EdiScopeSG", {link = "Type"})

local ns_anno = vim.api.nvim_create_namespace("edi-anno")

-- end-of-line labels
local function put_label(buf, lnum, chunks, prio)
  vim.api.nvim_buf_set_extmark(
    buf,
    ns_anno,
    lnum,
    0,
    {
      virt_text = chunks,
      virt_text_pos = "eol",
      priority = prio or 120
    }
  )
end

-- message signature to printable short string (e.g. "APERAK-04A")
local function msg_sig_label(sig)
  if not sig or not sig.type then
    return nil
  end
  if sig.release and #sig.release > 0 then
    return sig.type .. "-" .. sig.release
  end
  return sig.type
end

local function parse_message_sig(line, cfg)
  local elems = split_with_ranges(line, cfg.elem, cfg.release)
  local s009 = elems[3] and elems[3].text or nil
  if not s009 or not cfg.comp then
    return nil
  end
  local c = split_with_ranges(s009, cfg.comp, cfg.release)
  local mtype = c[1] and trim(c[1].text) or nil
  local ver = c[2] and trim(c[2].text) or nil
  local rel = c[3] and trim(c[3].text) or nil
  local agy = c[4] and trim(c[4].text) or nil
  local assoc = c[5] and trim(c[5].text) or nil
  return {
    type = mtype and mtype:upper() or nil,
    version = ver and ver:upper() or nil,
    release = rel and rel:upper() or nil,
    agency = agy and agy:upper() or nil,
    assoc = assoc and assoc:upper() or nil
  }
end

local function build_tree(buf)
  local cfg = detect_edi(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local stack, nodes = {}, {}
  for i, line in ipairs(lines) do
    local raw = trim(line:gsub("^%s+", ""))
    local tag = raw:match("^([A-Z][A-Z0-9]+)")
    if not tag then
      goto cont
    end
    if tag == "UNB" then
      table.insert(stack, {type = "interchange", s = i, title = "Interchange"})
    end
    if tag == "UNG" then
      table.insert(stack, {type = "group", s = i, title = "Group"})
    end
    if tag == "UNH" then
      local sig = parse_message_sig(raw, cfg)
      local label = "Message"
      local mshort = msg_sig_label(sig)
      if mshort then
        label = "Message " .. mshort
      end
      table.insert(stack, {type = "message", s = i, title = label, sig = sig})
    end
    if tag == "UNZ" then
      for j = #stack, 1, -1 do
        if stack[j].type == "interchange" then
          stack[j].e = i
          table.insert(nodes, stack[j])
          table.remove(stack, j)
          break
        end
      end
    elseif tag == "UNE" then
      for j = #stack, 1, -1 do
        if stack[j].type == "group" then
          stack[j].e = i
          table.insert(nodes, stack[j])
          table.remove(stack, j)
          break
        end
      end
    elseif tag == "UNT" then
      for j = #stack, 1, -1 do
        if stack[j].type == "message" then
          stack[j].e = i
          table.insert(nodes, stack[j])
          table.remove(stack, j)
          break
        end
      end
    end
    ::cont::
  end
  local last = #lines
  for _, n in ipairs(stack) do
    n.e = last
    table.insert(nodes, n)
  end
  table.sort(
    nodes,
    function(a, b)
      return a.s < b.s or (a.s == b.s and (a.e < b.e))
    end
  )
  return nodes, cfg
end

local function clear_annotations(buf)
  pcall(vim.api.nvim_buf_clear_namespace, buf, ns_anno, 0, -1)
end

-- ---------------------------------------------------------------------------
-- Schema normalization (permissive)
-- ---------------------------------------------------------------------------
local function is_array(t)
  if type(t) ~= "table" then
    return false
  end
  local n = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then
      return false
    end
    if k > n then
      n = k
    end
  end
  for i = 1, n do
    if t[i] == nil then
      return false
    end
  end
  return true
end

local function strtoupper_list(lst)
  local out = {}
  for _, v in ipairs(lst or {}) do
    if type(v) == "string" then
      table.insert(out, v:upper())
    end
  end
  return out
end

local function norm_group_obj(g, key_hint)
  if type(g) == "string" then
    return {id = key_hint or g, name = key_hint or g, starts = {g:upper()}, children = {}}
  end
  local o = {}
  o.id = g.id or key_hint
  o.name = g.name or g.title or g.description

  local starts = g.starts or g.start or g.head or g.begin or g.trigger
  if type(starts) == "string" then
    starts = {starts}
  end
  if (not starts) and type(g.segments) == "table" and #g.segments > 0 then
    local first = g.segments[1]
    if type(first) == "string" then
      starts = {first}
    elseif type(first) == "table" and type(first.tag) == "string" then
      starts = {first.tag}
    end
  end
  o.starts = strtoupper_list(starts or {})

  local kids = g.children or g.groups or g.segment_groups or g.subgroups or g.sgs
  if kids then
    if is_array(kids) then
      local arr = {}
      for _, child in ipairs(kids) do
        table.insert(arr, norm_group_obj(child))
      end
      o.children = arr
    else
      local arr = {}
      for k, child in pairs(kids) do
        table.insert(arr, norm_group_obj(child, k))
      end
      table.sort(
        arr,
        function(a, b)
          local na = tonumber((a.id or ""):match("SG(%d+)") or "") or 1e9
          local nb = tonumber((b.id or ""):match("SG(%d+)") or "") or 1e9
          if na == nb then
            return (a.id or "") < (b.id or "")
          end
          return na < nb
        end
      )
      o.children = arr
    end
  else
    o.children = {}
  end
  return o
end

local function normalize_schema(js)
  if not js then
    return nil
  end
  local root = js
  if type(js.message) == "table" then
    root = js.message
  end

  local groups = root.groups or root.segment_groups
  if not groups then
    return nil
  end

  local out = {}
  if is_array(groups) then
    for _, g in ipairs(groups) do
      table.insert(out, norm_group_obj(g))
    end
  else
    for k, g in pairs(groups) do
      table.insert(out, norm_group_obj(g, k))
    end
    table.sort(
      out,
      function(a, b)
        local na = tonumber((a.id or ""):match("SG(%d+)") or "") or 1e9
        local nb = tonumber((b.id or ""):match("SG(%d+)") or "") or 1e9
        if na == nb then
          return (a.id or "") < (b.id or "")
        end
        return na < nb
      end
    )
  end

  return next(out) and {groups = out} or nil
end

local function scan_json_candidates(root, stems)
  local want = {}
  for _, st in ipairs(stems) do
    want[(st .. ".json"):lower()] = true
  end
  local h = vim.loop.fs_scandir(root)
  if not h then
    return nil
  end
  while true do
    local name, typ = vim.loop.fs_scandir_next(h)
    if not name then
      break
    end
    if typ == "file" and name:match("%.json$") then
      if want[name:lower()] then
        return root .. "/" .. name
      end
    end
  end
  return nil
end

local function try_load_schema(sig)
  if not sig or not sig.type then
    return nil
  end
  local base = state.cfg.data_dir .. "/edifact/messages"
  local t = (sig.type or ""):upper()
  local r = (sig.release or ""):upper()
  local a = (sig.agency or ""):upper()
  local x = (sig.assoc or ""):upper()

  local candidates = {}
  if r ~= "" and a ~= "" and x ~= "" then
    table.insert(candidates, string.format("%s-%s-%s-%s", t, r, a, x))
  end
  if r ~= "" and a ~= "" then
    table.insert(candidates, string.format("%s-%s-%s", t, r, a))
  end
  if r ~= "" then
    table.insert(candidates, string.format("%s-%s", t, r))
  end
  table.insert(candidates, t)

  for _, root in ipairs({base, base .. "/" .. t}) do
    local p = scan_json_candidates(root, candidates)
    if p then
      local js = load_json(p)
      js = normalize_schema(js)
      if js and type(js.groups) == "table" then
        return js, p
      end
    end
  end
  return nil
end

-- annotate SGs inside a message node
local function to_set(lst)
  local t = {}
  for _, v in ipairs(lst or {}) do
    t[v] = true
  end
  return t
end
local function build_peer_map(groups)
  local map, all = {}, {}
  for _, g in ipairs(groups or {}) do
    map[g] = to_set(g.starts or {})
    for _, s in ipairs(g.starts or {}) do
      all[s] = true
    end
  end
  return map, all
end

local function annotate_sg_in_message(buf, node, cfg)
  local lines = vim.api.nvim_buf_get_lines(buf, node.s - 1, node.e, false)
  if #lines == 0 then
    return
  end

  local sig = node.sig or parse_message_sig(lines[1] or "", cfg)
  local cache_key =
    table.concat(
    {
      sig and sig.type or "",
      sig and sig.release or "",
      sig and sig.agency or "",
      sig and sig.assoc or ""
    },
    ":"
  )

  local schema = state.schema_cache[cache_key]
  local schema_path = nil
  if schema == nil then
    local js, path = try_load_schema(sig or {})
    if js then
      schema = js
      schema_path = path
    else
      schema = false
    end
    state.schema_cache[cache_key] = schema
  end
  if schema == false or not (schema and schema.groups) then
    return
  end

  local function tag_of(line)
    return (line:gsub("^%s+", ""):match("^([A-Z][A-Z0-9]+)"))
  end

  local function annotate_level(start_idx, end_idx, groups)
    if not groups or #groups == 0 then
      return start_idx
    end
    local peer_map, all_peer_starts = build_peer_map(groups)
    local i = start_idx
    while i <= end_idx do
      local tag = tag_of(lines[i] or "")
      if not tag then
        i = i + 1
        goto continue
      end

      local g_found = nil
      for _, g in ipairs(groups) do
        if peer_map[g][tag] then
          g_found = g
          break
        end
      end
      if not g_found then
        i = i + 1
      else
        local open_lnum = i
        i = i + 1
        if g_found.children and #g_found.children > 0 then
          i = annotate_level(i, end_idx, g_found.children)
        end
        while i <= end_idx do
          local t2 = tag_of(lines[i] or "")
          if t2 == "UNT" or all_peer_starts[t2] then
            break
          end
          if g_found.children and #g_found.children > 0 then
            local _, child_all = build_peer_map(g_found.children)
            if child_all[t2] then
              i = annotate_level(i, end_idx, g_found.children)
              goto loop_cont
            end
          end
          i = i + 1
          ::loop_cont::
        end
        local close_lnum = math.max(open_lnum, i - 1)

        local base
        if g_found.id and g_found.name then
          base = g_found.id .. " " .. g_found.name
        else
          base = g_found.id or g_found.name or "SG"
        end

        local mshort = msg_sig_label(sig)
        local label = mshort and (base .. " — " .. mshort) or base

        put_label(buf, node.s - 2 + open_lnum, {{"⟪ " .. label .. " ⟫", "EdiScopeSG"}})
        put_label(buf, node.s - 2 + close_lnum, {{"⟪ /" .. label .. " ⟫", "EdiScopeSG"}})
      end
      ::continue::
    end
    return i
  end

  annotate_level(1, #lines, schema.groups)

  if schema_path then
    vim.b.edi_schema_match = {
      path = schema_path,
      type = (sig and sig.type) or "?",
      release = (sig and sig.release) or "?"
    }
  end
end

local function annotate_pretty(buf)
  if not state.cfg.annotate then
    return
  end
  clear_annotations(buf)
  local nodes, _ = build_tree(buf)

  -- standard scopes
  for _, n in ipairs(nodes) do
    local hl =
      (n.type == "interchange" and "EdiScopeInterchange") or (n.type == "group" and "EdiScopeGroup") or
      "EdiScopeMessage"
    put_label(buf, n.s - 1, {{"⟪ " .. n.title .. " ⟫", hl}})
    put_label(
      buf,
      n.e - 1,
      {
        {
          "⟪ /" ..
            (n.type == "interchange" and "Interchange" or n.type == "group" and "Group" or "Message") ..
              " ⟫",
          hl
        }
      }
    )
  end
  vim.b.edi_tree = nodes

  -- SG inside messages
  for _, n in ipairs(nodes) do
    if n.type == "message" then
      local cfg = detect_edi(buf)
      annotate_sg_in_message(buf, n, cfg)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Jumps + text-objects (pretty buffer)
-- ---------------------------------------------------------------------------
local function find_node_at(line, kind)
  local nodes = vim.b.edi_tree or {}
  local best = nil
  for _, n in ipairs(nodes) do
    if line >= n.s and line <= n.e and (not kind or n.type == kind) then
      if not best or (n.e - n.s) < (best.e - best.s) then
        best = n
      end
    end
  end
  return best
end

local function jump_to(nextdir, kind)
  local nodes = vim.b.edi_tree or {}
  if #nodes == 0 then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local target = nil
  if nextdir == 1 then
    for _, n in ipairs(nodes) do
      if (not kind or n.type == kind) and n.s > cur then
        target = n.s
        break
      end
    end
  else
    for i = #nodes, 1, -1 do
      local n = nodes[i]
      if (not kind or n.type == kind) and n.e < cur then
        target = n.s
        break
      end
    end
  end
  if target then
    vim.api.nvim_win_set_cursor(0, {target, 0})
  end
end

local function select_node_lines(kind, around)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local node = find_node_at(cur, kind)
  if not node then
    return
  end
  local s = around and node.s or math.min(node.e, node.s + 1)
  local e = around and node.e or math.max(node.s, node.e - 1)
  if e < s then
    s, e = node.s, node.e
  end
  vim.fn.setpos("'<", {0, s, 1, 0})
  vim.fn.setpos("'>", {0, e, 9999, 0})
  vim.cmd("normal! gv")
end

-- ---------------------------------------------------------------------------
-- Pretty toggle (in place)
-- ---------------------------------------------------------------------------
local function edi_pretty_toggle()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_buf(win)
  local st = vim.w.edi_pretty_state

  if st and vim.api.nvim_buf_is_valid(st.source) and vim.api.nvim_buf_is_valid(st.pretty) and cur == st.pretty then
    vim.api.nvim_win_set_buf(win, st.source)
    pcall(vim.api.nvim_buf_delete, st.pretty, {force = true})
    vim.w.edi_pretty_state = nil
    return
  end

  local cfg = detect_edi(cur)
  local pretty = pretty_text(buf_text(cur), cfg)
  local pbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, vim.split(pretty, "\n", {plain = true}))
  vim.api.nvim_buf_set_option(pbuf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(pbuf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(pbuf, "swapfile", false)
  vim.api.nvim_buf_set_option(pbuf, "modifiable", false)
  vim.api.nvim_buf_set_name(pbuf, "[EDI Pretty] " .. (vim.api.nvim_buf_get_name(cur):match("[^/]+$") or ""))

  apply_syntax(pbuf, cfg)
  vim.api.nvim_win_set_buf(win, pbuf)
  annotate_pretty(pbuf)

  -- Jumps
  vim.keymap.set(
    {"n"},
    "]m",
    function()
      jump_to(1, "message")
    end,
    {buffer = pbuf, desc = "next message"}
  )
  vim.keymap.set(
    {"n"},
    "[m",
    function()
      jump_to(-1, "message")
    end,
    {buffer = pbuf, desc = "prev message"}
  )
  vim.keymap.set(
    {"n"},
    "]g",
    function()
      jump_to(1, "group")
    end,
    {buffer = pbuf, desc = "next group"}
  )
  vim.keymap.set(
    {"n"},
    "[g",
    function()
      jump_to(-1, "group")
    end,
    {buffer = pbuf, desc = "prev group"}
  )
  vim.keymap.set(
    {"n"},
    "]i",
    function()
      jump_to(1, "interchange")
    end,
    {buffer = pbuf, desc = "next interchange"}
  )
  vim.keymap.set(
    {"n"},
    "[i",
    function()
      jump_to(-1, "interchange")
    end,
    {buffer = pbuf, desc = "prev interchange"}
  )

  -- Text-objects (visual + operator-pending) — pretty buffer only
  for _, which in ipairs({{"m", "message"}, {"g", "group"}, {"i", "interchange"}}) do
    local key, kind = which[1], which[2]
    vim.keymap.set(
      {"x", "o"},
      "i" .. key,
      function()
        select_node_lines(kind, false)
      end,
      {buffer = pbuf, desc = "inner " .. kind}
    )
    vim.keymap.set(
      {"x", "o"},
      "a" .. key,
      function()
        select_node_lines(kind, true)
      end,
      {buffer = pbuf, desc = "around " .. kind}
    )
  end

  -- 'q' to return
  vim.keymap.set(
    "n",
    "q",
    function()
      local s = vim.w.edi_pretty_state
      if s and vim.api.nvim_buf_is_valid(s.source) then
        vim.api.nvim_win_set_buf(win, s.source)
      end
      if s and vim.api.nvim_buf_is_valid(s.pretty) then
        pcall(vim.api.nvim_buf_delete, s.pretty, {force = true})
      end
      vim.w.edi_pretty_state = nil
    end,
    {buffer = pbuf, nowait = true, silent = true}
  )

  vim.w.edi_pretty_state = {source = cur, pretty = pbuf}
end

-- ---------------------------------------------------------------------------
-- UNCL fetcher (JSON-LD → flat code map)
-- ---------------------------------------------------------------------------
local fetcher = {
  running = false,
  pool = 4,
  active = 0,
  next_id = 1,
  max_id = 9999,
  done = 0,
  saved = 0,
  last_saved = nil,
  last_url = nil,
  last_count = 0
}
local function parse_textish(o)
  if type(o) == "string" then
    return o
  end
  if type(o) ~= "table" then
    return nil
  end
  if o[1] ~= nil then
    for _, v in ipairs(o) do
      if
        type(v) == "table" and ((v["@language"] == "en") or (v["language"] == "en")) and
          (v["@value"] or v["value"])
       then
        return v["@value"] or v["value"]
      end
      if type(v) == "string" then
        return v
      end
    end
    local v = o[1]
    if type(v) == "table" then
      return v["@value"] or v["value"] or v["@id"] or v["id"]
    end
  end
  return o["@value"] or o["value"] or o["@id"] or o["id"] or nil
end
local function parse_code(o)
  if type(o) == "string" or type(o) == "number" then
    return tostring(o)
  end
  if type(o) ~= "table" then
    return nil
  end
  if o[1] ~= nil then
    local v = o[1]
    if type(v) == "string" or type(v) == "number" then
      return tostring(v)
    end
    if type(v) == "table" then
      return v["@value"] or v["value"] or v["@id"] or v["id"]
    end
  end
  return o["@value"] or o["value"] or o["@id"] or o["id"] or nil
end
local function collect_codes(node, out)
  if type(node) ~= "table" then
    return
  end
  local code = node["rdf:value"] or node["value"] or node["rdf:Value"] or node["notation"] or node["skos:notation"]
  local desc =
    node["rdfs:comment"] or node["comment"] or node["skos:definition"] or node["prefLabel"] or
    node["skos:prefLabel"] or
    node["rdfs:label"] or
    node["label"]
  if code and desc then
    local k = parse_code(code)
    local v = parse_textish(desc)
    if k and v and out[k] == nil then
      out[k] = v
    end
  end
  for _, v in pairs(node) do
    if type(v) == "table" then
      collect_codes(v, out)
    end
  end
end
local function jsonld_to_map(txt)
  local ok, obj = pcall(vim.fn.json_decode, txt)
  if not ok or not obj then
    return nil
  end
  local out = {}
  collect_codes(obj, out)
  if not next(out) and type(obj) == "table" and obj["@graph"] and type(obj["@graph"]) == "table" then
    for _, n in ipairs(obj["@graph"]) do
      collect_codes(n, out)
    end
  end
  return next(out) and out or nil
end
local function fetch_url(url, cb)
  local out = {}
  local job =
    vim.fn.jobstart(
    {"curl", "-fsSL", url},
    {
      stdout_buffered = true,
      on_stdout = function(_, d, _)
        if d then
          table.insert(out, table.concat(d, "\n"))
        end
      end,
      on_stderr = function()
      end,
      on_exit = function(_, code)
        cb(code == 0, table.concat(out, ""))
      end
    }
  )
  if job <= 0 then
    cb(false, nil)
  end
end
local function save_map(id, base, map)
  return write_json_atomically(string.format("%s/edifact/codes/%d.json", base, id), map)
end
local function fetch_one(id, base, done)
  local url = string.format("https://service.unece.org/trade/uncefact/vocabulary/uncl%04d.jsonld", id)
  fetch_url(
    url,
    function(ok, body)
      if ok and body and #body > 0 then
        local map = jsonld_to_map(body)
        if map and next(map) then
          if save_map(id, base, map) then
            fetcher.saved = fetcher.saved + 1
            fetcher.last_saved = id
            fetcher.last_url = url
            local c = 0
            for _ in pairs(map) do
              c = c + 1
            end
            fetcher.last_count = c
            vim.schedule(
              function()
                vim.notify(string.format("edi: saved UNCL %04d (%d)", id, c), vim.log.levels.INFO)
              end
            )
            done(true)
            return
          end
        end
      end
      done(false)
    end
  )
end
local timer = nil
local function pump()
  if not fetcher.running then
    return
  end
  while fetcher.active < fetcher.pool and fetcher.next_id <= fetcher.max_id do
    local id = fetcher.next_id
    fetcher.next_id = id + 1
    fetcher.active = fetcher.active + 1
    fetch_one(
      id,
      state.cfg.data_dir,
      function()
        fetcher.done = fetcher.done + 1
        fetcher.active = fetcher.active - 1
        if fetcher.done % 50 == 0 then
          vim.schedule(
            function()
              vim.notify(
                string.format(
                  "edi: %d/%d saved %d last=%s",
                  fetcher.done,
                  fetcher.max_id,
                  fetcher.saved,
                  fetcher.last_saved and string.format("%04d", fetcher.last_saved) or "-"
                ),
                vim.log.levels.INFO
              )
            end
          )
        end
        if fetcher.done >= fetcher.max_id and fetcher.active == 0 then
          fetcher.running = false
          if timer then
            timer:stop()
            timer:close()
            timer = nil
          end
          vim.schedule(
            function()
              vim.notify("edi: EDIFACT fetch complete. Saved " .. fetcher.saved, vim.log.levels.INFO)
              try_load_data_dir()
              vim.notify("edi: data reloaded", vim.log.levels.INFO)
            end
          )
        end
      end
    )
  end
end
local function start_fetch_all()
  if fetcher.running then
    vim.notify("edi: fetch already running", vim.log.levels.WARN)
    return
  end
  fetcher.running = true
  fetcher.active = 0
  fetcher.next_id = 1
  fetcher.max_id = 9999
  fetcher.done = 0
  fetcher.saved = 0
  fetcher.last_saved = nil
  fetcher.last_url = nil
  fetcher.last_count = 0
  ensure_dir(state.cfg.data_dir .. "/edifact/codes")
  vim.notify("edi: starting EDIFACT UNCL fetch (0001..9999)", vim.log.levels.INFO)
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  timer = vim.loop.new_timer()
  timer:start(
    0,
    150,
    function()
      vim.schedule(pump)
    end
  )
end

-- ---------------------------------------------------------------------------
-- Filetype hooks & commands
-- ---------------------------------------------------------------------------
local function maybe_set_ft()
  local b = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(b):lower()
  local cfg = detect_edi(b)
  if name:match("%.x12$") or name:match("%.edifact$") or name:match("%.edi$") then
    apply_syntax(b, cfg)
    return
  end
  local src = buf_text(b)
  -- also trigger on UNA so EDIFACT buffers get K mapping immediately
  if src:find("^%s*ISA") or src:find("^%s*UNB") or src:find("^%s*UNA") then
    apply_syntax(b, cfg)
  end
end

-- helper: show which schema matched (or best candidate)
local function cmd_sg_which()
  local m = vim.b.edi_schema_match
  if m and m.path then
    vim.notify(
      ("edi: SG schema %s (type=%s, rel=%s)"):format(m.path, m.type or "?", m.release or "?"),
      vim.log.levels.INFO
    )
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local nodes, cfg = build_tree(buf)
  local sig = nil
  for _, n in ipairs(nodes) do
    if n.type == "message" then
      sig = n.sig or parse_message_sig(vim.api.nvim_buf_get_lines(buf, n.s - 1, n.s, false)[1] or "", cfg)
      break
    end
  end
  if not sig then
    vim.notify("edi: no UNH/S009 signature found", vim.log.levels.WARN)
    return
  end
  local js, path = try_load_schema(sig or {})
  if js and path then
    vim.notify(
      ("edi: candidate SG schema %s (type=%s, rel=%s)"):format(path, sig.type or "?", sig.release or "?"),
      vim.log.levels.INFO
    )
  else
    vim.notify("edi: no SG schema matched for this message", vim.log.levels.WARN)
  end
end

-- dump normalized SGs the annotator sees
local function cmd_sg_dump()
  local buf = vim.api.nvim_get_current_buf()
  local nodes, cfg = build_tree(buf)
  local msg = nil
  for _, n in ipairs(nodes) do
    if n.type == "message" then
      msg = n
      break
    end
  end
  if not msg then
    return vim.notify("edi: no message node found", vim.log.levels.WARN)
  end

  local sig = msg.sig or parse_message_sig((vim.api.nvim_buf_get_lines(buf, msg.s - 1, msg.s, false)[1] or ""), cfg)
  local js, path = try_load_schema(sig or {})
  if not js then
    return vim.notify("edi: no schema found", vim.log.levels.WARN)
  end
  js = normalize_schema(js)
  if not js or not js.groups then
    return vim.notify("edi: schema has no groups after normalization", vim.log.levels.WARN)
  end

  local function rec(gs, d)
    for _, g in ipairs(gs) do
      print(
        string.rep("  ", d) ..
          (g.id or "SG?") .. " starts=[" .. table.concat(g.starts or {}, ",") .. "]  " .. (g.name or "")
      )
      rec(g.children or {}, d + 1)
    end
  end
  print("Schema: " .. (path or "?"))
  rec(js.groups, 0)
end

function M.setup(opts)
  if opts and type(opts) == "table" then
    merge(state.cfg, opts)
  end
  pcall(try_load_data_dir)

  vim.api.nvim_create_user_command(
    "EdiPretty",
    function()
      edi_pretty_toggle()
    end,
    {desc = "Toggle pretty view (in place)"}
  )
  vim.api.nvim_create_user_command(
    "EdiReloadData",
    function()
      try_load_data_dir()
      vim.notify("edi: data reloaded", vim.log.levels.INFO)
    end,
    {}
  )
  vim.api.nvim_create_user_command(
    "EdiFetchEdifactAll",
    function()
      start_fetch_all()
    end,
    {desc = "Fetch all UNCL JSON-LD"}
  )
  vim.api.nvim_create_user_command(
    "EdiFetchStatus",
    function()
      vim.notify(
        string.format(
          "running=%s pool=%d active=%d next=%d done=%d saved=%d last=%s(%d) url=%s",
          tostring(fetcher.running),
          fetcher.pool,
          fetcher.active,
          fetcher.next_id,
          fetcher.done,
          fetcher.saved,
          fetcher.last_saved and string.format("%04d", fetcher.last_saved) or "none",
          fetcher.last_count or 0,
          fetcher.last_url or "n/a"
        ),
        vim.log.levels.INFO
      )
    end,
    {}
  )
  vim.api.nvim_create_user_command("EdiSgWhich", cmd_sg_which, {desc = "Show which SG schema file matched"})
  vim.api.nvim_create_user_command("EdiSgDump", cmd_sg_dump, {desc = "Dump normalized SG tree"})

  local grp = vim.api.nvim_create_augroup("edi-core", {clear = true})
  vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {group = grp, callback = maybe_set_ft})
  vim.api.nvim_create_autocmd(
    "FileType",
    {
      group = grp,
      pattern = {"x12", "edifact"},
      callback = function(args)
        vim.keymap.set(
          "n",
          "K",
          function()
            require("edi").hover()
          end,
          {buffer = args.buf, desc = "EDI hover"}
        )
      end
    }
  )
  vim.api.nvim_create_autocmd(
    "VimLeavePre",
    {
      group = grp,
      callback = function()
        if vim.w.edi_pretty_state and vim.api.nvim_buf_is_valid(vim.w.edi_pretty_state.pretty) then
          pcall(vim.api.nvim_buf_delete, vim.w.edi_pretty_state.pretty, {force = true})
        end
      end
    }
  )
end

return M
