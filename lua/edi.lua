-- lua/edi.lua  (pretty-toggle + indent-aware hover; codes only from JSON)
-- EDI helper for Neovim (X12 + EDIFACT)
-- - :EdiPretty           toggle pretty view IN PLACE (no file edits)
-- - :EdiFetchEdifactAll  fetch all UNECE UNCL JSON-LD -> plain JSON maps
-- - :EdiFetchStatus      progress/status while fetching
-- - :EdiReloadData       reload JSON dictionaries
-- - Hover on K           works in both normal & pretty views
--
-- External dependency: curl (for the fetcher). No jq needed.

local M = {}
local state = {
  float_win = nil, float_buf = nil, float_pos = nil, augroup = nil,
  cfg = {
    data_dir = vim.fn.stdpath('config') .. '/edi-data',
    dict_overrides = {},
    hover = {
      max_width = 96,
      close_events = {
        "CursorMoved","CursorMovedI","InsertEnter","BufLeave","WinLeave",
        "WinScrolled","ModeChanged","TermEnter",
      },
    },
  },
  data = { x12 = { segments = {}, codes = {} }, edifact = { segments = {}, codes = {} } },
}

-- ========== utils ==========
local function buf_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function esc_lua_pattern(ch) return (ch:gsub("([^%w])", "%%%1")) end
local function merge_tables(dst, src)
  for k,v in pairs(src or {}) do
    if type(v) == "table" and type(dst[k]) == "table" then merge_tables(dst[k], v) else dst[k] = v end
  end
end
local function ensure_dir(path)
  local sep = package.config:sub(1,1)
  local parts = {}
  for part in path:gmatch("[^"..esc_lua_pattern(sep).."]+") do table.insert(parts, part) end
  local acc = (path:sub(1,1) == sep) and sep or ""
  for _, p in ipairs(parts) do
    acc = (acc == "" and p) or (acc..sep..p)
    vim.loop.fs_mkdir(acc, 493) -- 0755
  end
end
local function write_json_atomically(path, tbl)
  local data = vim.fn.json_encode(tbl); if not data or #data == 0 then return false end
  local dir = path:match("^(.*)/[^/]+$"); if dir then ensure_dir(dir) end
  local tmp = path .. ".tmp_" .. tostring(vim.loop.hrtime())
  local fd = vim.loop.fs_open(tmp, "w", 420); if not fd then return false end
  local ok1 = vim.loop.fs_write(fd, data, 0); vim.loop.fs_close(fd)
  if not ok1 then pcall(vim.loop.fs_unlink, tmp); return false end
  pcall(vim.loop.fs_rename, tmp, path); return true
end

-- ========== built-ins (segments only; NO code lists) ==========
local BUILTIN = {
  x12 = {
    segments = {
      ISA = { title="Interchange Control Header", elements = {
        { name="Authorization Info Qualifier", id="I01" },
        { name="Authorization Information", id="I02" },
        { name="Security Info Qualifier", id="I03" },
        { name="Security Information", id="I04" },
        { name="Interchange ID Qualifier (Sender)", id="I05" },
        { name="Interchange Sender ID", id="I06" },
        { name="Interchange ID Qualifier (Receiver)", id="I07" },
        { name="Interchange Receiver ID", id="I08" },
        { name="Interchange Date (YYMMDD)", id="I09" },
        { name="Interchange Time (HHMM)", id="I10" },
        { name="Standards Identifier / Repetition Sep", id="I11" },
        { name="Interchange Control Version", id="I12" },
        { name="Interchange Control Number", id="I13" },
        { name="Acknowledgment Requested", id="I14" },
        { name="Usage Indicator (T/P)", id="I15", codeset="I15" },
        { name="Component Element Separator", id="I16" },
      }},
      GS = { title="Functional Group Header", elements = {
        { name="Functional Identifier Code", id="479" },
        { name="Application Sender's Code", id="142" },
        { name="Application Receiver's Code", id="124" },
        { name="Date", id="373" },
        { name="Time", id="337" },
        { name="Group Control Number", id="28" },
        { name="Responsible Agency Code", id="455" },
        { name="Version / Release / Industry ID", id="480" },
      }},
      ST = { title="Transaction Set Header", elements = {
        { name="Transaction Set ID", id="143" }, { name="Control Number", id="329" },
      }},
      BEG = { title="Beginning Segment for PO", elements = {
        { name="Transaction Set Purpose Code", id="353", codeset="353" },
        { name="Purchase Order Type Code", id="92" },
        { name="Purchase Order Number", id="324" },
        { name="Release Number", id="328" },
        { name="Date", id="373" },
      }},
      REF = { title="Reference Identification", elements = {
        { name="Reference Qualifier", id="128", codeset="128" },
        { name="Reference Identification", id="127" },
        { name="Description", id="352" },
      }},
      DTM = { title="Date/Time Reference", elements = {
        { name="Qualifier", id="374", codeset="374" }, { name="Date", id="373" }, { name="Time", id="337" },
      }},
      N1  = { title="Name", elements = {
        { name="Entity Identifier Code", id="98", codeset="98" }, { name="Name", id="93" },
        { name="ID Code Qualifier", id="66" }, { name="ID Code", id="67" },
      }},
      PO1 = { title="Baseline Item Data", elements = {
        { name="Assigned ID", id="350" }, { name="Qty", id="330" },
        { name="UOM", id="355", codeset="355" }, { name="Unit Price", id="212" },
        { name="Basis of Unit Price", id="639" }, { name="Prod/Serv ID Qualifier", id="235" }, { name="Prod/Serv ID", id="234" },
      }},
      CTT = { title="Transaction Totals", elements = {
        { name="Line Count", id="354" }, { name="Hash Total", id="347" },
      }},
      SE = { title="Transaction Set Trailer", elements = {
        { name="Segment Count", id="96" }, { name="Control Number", id="329" },
      }},
      GE = { title="Functional Group Trailer", elements = {
        { name="# of Transaction Sets", id="97" }, { name="Group Control Number", id="28" },
      }},
      IEA = { title="Interchange Control Trailer", elements = {
        { name="# of Included Groups", id="I16N" }, { name="Interchange Control Number", id="I13" },
      }},
    },
    codes = {}, -- no built-in codes; rely on JSON
  },
  edifact = {
    segments = {
      UNB = { title="Interchange Header", elements = {
        { name="S001 Syntax identifier" },
        { name="S002 Interchange sender" },
        { name="S003 Interchange recipient" },
        { name="S004 Date/time of preparation" },
        { name="0020 Interchange control reference", id="0020" },
        { name="S005 Recipient's reference/password" },
        { name="0026 Application reference", id="0026" },
        { name="0029 Processing priority code", id="0029" },
        { name="0031 Acknowledgement request", id="0031" },
        { name="0032 Interchange agreement identifier", id="0032" },
        { name="0035 Test indicator", id="0035" },
      }},
      UNH = { title="Message Header", elements = {
        { name="0062 Message reference number", id="0062" },
        { name="S009 Message identifier", components = {
          { name="0065 Message type", id="0065" },
          { name="0052 Version", id="0052" },
          { name="0054 Release", id="0054" },
          { name="0051 Agency", id="0051" },
          { name="0057 Association code", id="0057" },
        }},
        { name="0068 Common access reference", id="0068" },
        { name="S010 Status of transfer" },
      }},
      BGM = { title="Beginning of message", elements = {
        { name="C002 Document/message name", components = {
          { name="1001 Document name code", id="1001", codeset="1001" },
          { name="1131 Code list ID", id="1131" },
          { name="3055 Code list agency", id="3055" },
          { name="1000 Document name", id="1000" },
        }},
        { name="C106 Document message ID" },
        { name="1225 Message function, coded", id="1225", codeset="1225" },
        { name="4343 Response type, coded", id="4343" },
      }},
      DTM = { title="Date/time/period", elements = {
        { name="C507 Date/time/period", components = {
          { name="2005 Qualifier", id="2005", codeset="2005" },
          { name="2380 Date/time/period", id="2380" },
          { name="2379 Format qualifier", id="2379" },
        }},
      }},
      RFF = { title="Reference", elements = {
        { name="C506 Reference", components = {
          { name="1153 Reference qualifier", id="1153", codeset="1153" },
          { name="1154 Reference number", id="1154" },
          { name="1156 Line number", id="1156" },
          { name="4000 Reference version", id="4000" },
        }},
      }},
      NAD = { title="Name and address", elements = {
        { name="3035 Party qualifier", id="3035", codeset="3035" },
        { name="C082 Party identification" },
        { name="C058 Name and address" },
        { name="C080 Party name" },
        { name="C059 Street" },
        { name="3164 City", id="3164" },
        { name="3251 Postcode", id="3251" },
        { name="3207 Country", id="3207" },
      }},
      LIN = { title="Line item", elements = {
        { name="1082 Line item number", id="1082" },
        { name="1229 Action code", id="1229" },
        { name="C212 Item number identification" },
      }},
      QTY = { title="Quantity", elements = {
        { name="C186 Quantity details", components = {
          { name="6063 Quantity qualifier", id="6063" },
          { name="6060 Quantity", id="6060" },
          { name="6411 Unit", id="6411" },
        }},
      }},
      PRI = { title="Price details", elements = {
        { name="C509 Price information", components = {
          { name="5125 Price qualifier", id="5125" },
          { name="5118 Price", id="5118" },
          { name="5375 Price type", id="5375" },
          { name="5387 Price type qualifier", id="5387" },
          { name="5284 Unit price basis", id="5284" },
          { name="6411 Unit", id="6411" },
        }},
      }},
      MOA = { title="Monetary amount", elements = {
        { name="C516 Monetary amount", components = {
          { name="5025 Function qualifier", id="5025" },
          { name="5004 Amount", id="5004" },
          { name="6345 Currency", id="6345" },
        }},
      }},
      UNT = { title="Message Trailer", elements = {
        { name="0074 Number of segments", id="0074" },
        { name="0062 Message ref number", id="0062" },
      }},
      UNZ = { title="Interchange Trailer", elements = {
        { name="0036 Interchange count", id="0036" },
        { name="0020 Interchange control ref", id="0020" },
      }},
    },
    codes = {}, -- no built-in codes; rely on JSON
  },
}

-- ========== JSON load ==========
local function load_json(path)
  local ok, fd = pcall(vim.loop.fs_open, path, "r", 438)
  if not ok or not fd then return nil end
  local stat = vim.loop.fs_fstat(fd); if not stat then vim.loop.fs_close(fd); return nil end
  local data = vim.loop.fs_read(fd, stat.size, 0); vim.loop.fs_close(fd)
  if not data or data == "" then return nil end
  local ok2, decoded = pcall(vim.fn.json_decode, data)
  if not ok2 then return nil end
  return decoded
end

local function try_load_data_dir()
  local base = state.cfg.data_dir
  -- x12
  local x12_seg = load_json(base .. "/x12/segments.json")
  if x12_seg and type(x12_seg)=="table" then state.data.x12.segments = x12_seg end
  local x12_codes_dir = base .. "/x12/codes"
  local h = vim.loop.fs_scandir(x12_codes_dir)
  if h then
    while true do
      local name, typ = vim.loop.fs_scandir_next(h); if not name then break end
      if typ=="file" and name:match("%.json$") then
        local id = name:gsub("%.json$","")
        local obj = load_json(x12_codes_dir .. "/" .. name)
        if obj and type(obj)=="table" then state.data.x12.codes[id] = obj end
      end
    end
  end
  -- edifact
  local edifact_seg = load_json(base .. "/edifact/segments.json")
  if edifact_seg and type(edifact_seg)=="table" then state.data.edifact.segments = edifact_seg end
  local edifact_codes_dir = base .. "/edifact/codes"
  h = vim.loop.fs_scandir(edifact_codes_dir)
  if h then
    while true do
      local name, typ = vim.loop.fs_scandir_next(h); if not name then break end
      if typ=="file" and name:match("%.json$") then
        local id = name:gsub("%.json$","")
        local obj = load_json(edifact_codes_dir .. "/" .. name)
        if obj and type(obj)=="table" then state.data.edifact.codes[id] = obj end
      end
    end
  end
end

-- ========== flavor detection & splitting ==========
local function detect_edi(bufnr)
  local src = buf_text(bufnr)
  local head = src:sub(1, 4000)
  local has_ISA = head:find("ISA", 1, true)
  local has_UNB = head:find("UNB", 1, true)
  local guess = "x12"
  if has_UNB and not has_ISA then
    guess = "edifact"
  elseif has_ISA and not has_UNB then
    guess = "x12"
  elseif (head:find("UNH", 1, true) or head:find("UNT", 1, true)) and head:find("'%s*U") then
    guess = "edifact"
  end
  if guess == "edifact" then
    return { flavor="edifact", seg="'", elem="+", comp=":", repeat_sep=nil, release="?" }
  end
  local seg = "~"
  if head:find("~", 1, true) then seg="~"
  elseif head:find("\r\n", 1, true) then seg="\r\n"
  elseif head:find("\n", 1, true) then seg="\n" end
  local elem="*"
  do
    local isa_at = head:find("ISA", 1, true)
    if isa_at then
      local after = head:sub(isa_at+3, isa_at+12)
      local c = after:match("[^%w]"); if c and #c==1 then elem=c end
    end
  end
  return { flavor="x12", seg=seg, elem=elem, comp=":", repeat_sep="^", release=nil }
end

local function split_segments(s, term, release)
  local segs, cur = {}, {}
  local function flush()
    local piece = table.concat(cur); piece = trim(piece)
    if #piece > 0 then table.insert(segs, piece) end; cur = {}
  end
  local i, n = 1, #s
  while i <= n do
    local ch = s:sub(i,i)
    if release and ch == release then
      local nxt = (i<n) and s:sub(i+1,i+1) or ""
      table.insert(cur, ch); if nxt~="" then table.insert(cur, nxt) end
      i = i + ((nxt~="") and 2 or 1)
    elseif ch == term then
      flush(); i = i + 1
    else
      if term == "\r\n" and ch == "\r" and s:sub(i+1,i+1)=="\n" then flush(); i=i+2
      else table.insert(cur, ch); i=i+1 end
    end
  end
  flush(); return segs
end

local function seg_tag(segment, elem_sep)
  local tag = segment:match("^%s*([^"..esc_lua_pattern(elem_sep).."%s]+)")
  return tag or segment:sub(1, math.min(10, #segment))
end

-- ========== pretty & syntax ==========
local X12_PUSH = { ISA=true, GS=true, ST=true }
local X12_POP  = { IEA=true, GE=true, SE=true }
local EDI_PUSH = { UNB=true, UNG=true, UNH=true }
local EDI_POP  = { UNZ=true, UNE=true, UNT=true }

local function compute_indent(tag, flavor, depth)
  local d = depth
  if flavor == "x12" then if X12_POP[tag] then d = math.max(0, d-1) end; return d, (X12_PUSH[tag] and 1 or 0)
  else if EDI_POP[tag] then d = math.max(0, d-1) end; return d, (EDI_PUSH[tag] and 1 or 0) end
end

local function pretty_text(src, cfg)
  local segs = split_segments(src, cfg.seg, cfg.release)
  local depth, out = 0, {}
  for _, raw in ipairs(segs) do
    local s = trim(raw); if s == "" then goto continue end
    local tag = seg_tag(s, cfg.elem)
    local cur_depth, push = compute_indent(tag, cfg.flavor, depth)
    table.insert(out, string.rep("  ", cur_depth) .. s)
    depth = cur_depth + (push or 0)
    ::continue::
  end
  return table.concat(out, "\n")
end

local function apply_syntax(bufnr, cfg)
  vim.api.nvim_set_hl(0, "EdiSegmentTag", { link = "Label" })
  vim.api.nvim_set_hl(0, "EdiSep",        { link = "Delimiter" })
  vim.api.nvim_set_hl(0, "EdiCompSep",    { link = "Delimiter" })
  vim.api.nvim_set_hl(0, "EdiRelease",    { link = "SpecialChar" })
  vim.api.nvim_set_hl(0, "EdiNum",        { link = "Number" })
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("syntax enable")
    vim.cmd("silent! syntax clear EdiSegmentTag EdiSep EdiCompSep EdiRelease EdiNum")
    vim.cmd([[syntax match EdiSegmentTag "^\s*\zs[A-Z][A-Z0-9]\{1,5\}\ze\>"]])
    vim.cmd("execute 'syntax match EdiSep /" .. esc_lua_pattern(cfg.elem) .. "/'")
    if cfg.comp and #cfg.comp > 0 then
      vim.cmd("execute 'syntax match EdiCompSep /" .. esc_lua_pattern(cfg.comp) .. "/'")
    end
    if cfg.release and #cfg.release > 0 then
      vim.cmd("execute 'syntax match EdiRelease /" .. esc_lua_pattern(cfg.release) .. "/'")
    end
    vim.cmd([[syntax match EdiNum "\v(^|[^A-Z0-9])\zs\d+(\.\d+)?\ze([^A-Z0-9]|$)"]])
  end)
  vim.api.nvim_buf_set_option(bufnr, "filetype", (cfg.flavor == "x12") and "x12" or "edifact")
end

-- ========== pretty toggle (in-place) ==========
local function edi_pretty_toggle()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_buf(win)
  local st = vim.w.edi_pretty_state

  -- if currently on pretty buffer for this window -> restore source
  if st and vim.api.nvim_buf_is_valid(st.source) and vim.api.nvim_buf_is_valid(st.pretty)
     and cur == st.pretty then
    vim.api.nvim_win_set_buf(win, st.source)
    pcall(vim.api.nvim_buf_delete, st.pretty, { force = true })
    vim.w.edi_pretty_state = nil
    return
  end

  -- build pretty text from current buffer and swap it in
  local cfg = detect_edi(cur)
  local text = buf_text(cur)
  local pretty = pretty_text(text, cfg)
  local pbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, vim.split(pretty, "\n", { plain = true }))
  vim.api.nvim_buf_set_option(pbuf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(pbuf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(pbuf, "swapfile", false)
  vim.api.nvim_buf_set_option(pbuf, "modifiable", false)
  vim.api.nvim_buf_set_name(pbuf, "[EDI Pretty] " .. (vim.api.nvim_buf_get_name(cur):match("[^/]+$") or ""))

  apply_syntax(pbuf, cfg)
  vim.api.nvim_win_set_buf(win, pbuf)

  -- buffer-local 'q' to toggle back
  vim.keymap.set("n", "q", function()
    local w = vim.api.nvim_get_current_win()
    local s = vim.w.edi_pretty_state
    if s and vim.api.nvim_buf_is_valid(s.source) then
      vim.api.nvim_win_set_buf(w, s.source)
    end
    if s and vim.api.nvim_buf_is_valid(s.pretty) then
      pcall(vim.api.nvim_buf_delete, s.pretty, { force = true })
    end
    vim.w.edi_pretty_state = nil
  end, { buffer = pbuf, nowait = true, silent = true })

  vim.w.edi_pretty_state = { source = cur, pretty = pbuf }
end

-- ========== hover (indent-aware so it works in pretty buffer) ==========
local function split_with_ranges(s, sep, release)
  if not sep or sep == "" then return { { text = s, s = 0, e = #s - 1 } } end
  local parts, cur, start = {}, {}, 0
  local i, n = 1, #s
  while i <= n do
    local ch = s:sub(i,i)
    if release and ch == release then
      local nxt = (i<n) and s:sub(i+1,i+1) or ""
      table.insert(cur, ch); if nxt~="" then table.insert(cur, nxt) end
      i = i + ((nxt~="") and 2 or 1)
    elseif ch == sep then
      local piece = table.concat(cur)
      table.insert(parts, { text = piece, s = start, e = i - 2 })
      cur, start = {}, i; i = i + 1
    else
      table.insert(cur, ch); i = i + 1
    end
  end
  local piece = table.concat(cur)
  table.insert(parts, { text = piece, s = start, e = n - 1 })
  return parts
end

local function current_segment_at_cursor(cfg)
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- If the actual segment terminator for this flavor is on the line, use delimiter-based detection
  if (cfg.seg == "\r\n" and line:find("\r\n", 1, true))
     or (cfg.seg ~= "\r\n" and cfg.seg ~= "\n" and line:find(esc_lua_pattern(cfg.seg))) then
    local segs = split_with_ranges(line, cfg.seg, cfg.release)
    for _, p in ipairs(segs) do
      if col >= p.s and col <= p.e then
        return trim(p.text), p.s, p.e
      end
    end
    return trim(line), 0, #line - 1
  end

  -- Otherwise (pretty view: one segment per line with indent) -> be indent-aware
  local first_non_ws = line:find("%S")
  local indent_col = first_non_ws and (first_non_ws - 1) or #line
  local seg = line:sub(indent_col + 1)
  return trim(seg), indent_col, #line - 1
end

local function deep_copy(x) return vim.deepcopy(x) end
local function get_dict(flavor)
  local dict = deep_copy(BUILTIN[flavor] or {})
  merge_tables(dict.segments or {}, state.data[flavor].segments or {})
  merge_tables(dict.codes or {}, state.data[flavor].codes or {}) -- only JSON contributes codes now
  if state.cfg.dict_overrides and state.cfg.dict_overrides[flavor] then merge_tables(dict, state.cfg.dict_overrides[flavor]) end
  return dict
end

local function resolve_element_info(flavor, tag, elem_idx, comp_idx)
  local dict = get_dict(flavor)
  local sdef = dict.segments and dict.segments[tag]
  if not sdef then return nil end
  local edef = sdef.elements and sdef.elements[elem_idx]
  if not edef then return { seg=sdef, elem=nil } end
  if comp_idx and comp_idx > 0 and edef.components then
    local cdef = edef.components[comp_idx]
    return { seg=sdef, elem=edef, comp=cdef, codeset=(cdef and cdef.codeset) or (edef and edef.codeset) }
  end
  return { seg=sdef, elem=edef, comp=nil, codeset=edef.codeset }
end

local function codelist_lookup(flavor, codeset_id, code)
  if not codeset_id or not code then return nil end
  local dict = get_dict(flavor)
  local codes = dict.codes and dict.codes[codeset_id]
  if not codes then return nil end
  return codes[code] or codes[tostring(code)] or codes[tonumber(code) or code]
end

local function build_doc(cfg, seg, seg_s, _seg_e)
  local elem_parts = split_with_ranges(seg, cfg.elem, cfg.release)
  local tag = (elem_parts[1] and elem_parts[1].text) and elem_parts[1].text:gsub("^%s+",""):gsub("%s+$","") or seg
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local rel_col = col - seg_s
  local elem_idx, comp_idx = 0, 0
  local elem_val, comp_val
  for i = 2, #elem_parts do
    local p = elem_parts[i]
    if rel_col >= p.s and rel_col <= p.e then
      elem_idx = i - 1; elem_val = p.text
      if cfg.comp and #cfg.comp > 0 and p.text:find(esc_lua_pattern(cfg.comp), 1, false) then
        local comps = split_with_ranges(p.text, cfg.comp, cfg.release)
        local rel_in_elem = rel_col - p.s
        for j, c in ipairs(comps) do
          if rel_in_elem >= c.s and rel_in_elem <= c.e then comp_idx = j; comp_val = c.text; break end
        end
      end
      break
    end
  end
  local info = resolve_element_info(cfg.flavor, tag, elem_idx, comp_idx)
  local seg_title = info and info.seg and info.seg.title or "Segment"
  local elem_name = info and info.elem and info.elem.name or nil
  local comp_name = info and info.comp and info.comp.name or nil
  local codeset  = info and info.codeset or nil

  local code_value = comp_val or elem_val
  local code_meaning = codelist_lookup(cfg.flavor, codeset, code_value)

  local lines = {}
  table.insert(lines, string.format("%s — %s%s", cfg.flavor:upper(), tag, seg_title and ("  ("..seg_title..")") or ""))
  if elem_idx == 0 then
    table.insert(lines, "Position: segment ID (before first element)")
  else
    table.insert(lines, string.format("Element: %d%s", elem_idx, elem_name and (" — "..elem_name) or ""))
    if comp_idx > 0 then table.insert(lines, string.format("Component: %d%s", comp_idx, comp_name and (" — "..comp_name) or "")) end
  end
  if code_value and code_meaning then table.insert(lines, string.format("Code: %s — %s", code_value, code_meaning)) end
  if comp_val then table.insert(lines, "Value: " .. comp_val)
  elseif elem_val then table.insert(lines, "Value: " .. elem_val)
  else table.insert(lines, "Segment: " .. seg) end
  local path = (elem_idx == 0) and (tag)
            or (comp_idx > 0 and string.format("%s[%d].%d", tag, elem_idx, comp_idx)
                              or string.format("%s[%d]", tag, elem_idx))
  table.insert(lines, "Path: " .. path)
  local sepbits = { "seg='"..cfg.seg.."'", "elem='"..cfg.elem.."'" }
  if cfg.comp and #cfg.comp > 0 then table.insert(sepbits, "comp='"..cfg.comp.."'") end
  if cfg.repeat_sep then table.insert(sepbits, "rep='"..cfg.repeat_sep.."'" ) end
  if cfg.release then table.insert(sepbits, "release='"..cfg.release.."'" ) end
  if codeset then table.insert(sepbits, "codeset='"..tostring(codeset).."'" ) end
  table.insert(lines, "Delimiters: " .. table.concat(sepbits, "  "))
  return lines
end

-- float lifecycle (no stacking)
local function close_float()
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then pcall(vim.api.nvim_win_close, state.float_win, true) end
  if state.float_buf and vim.api.nvim_buf_is_valid(state.float_buf) then pcall(vim.api.nvim_buf_delete, state.float_buf, { force = true }) end
  state.float_win, state.float_buf, state.float_pos = nil, nil, nil
  if state.augroup then pcall(vim.api.nvim_del_augroup_by_id, state.augroup); state.augroup = nil end
end
local function show_float(lines)
  close_float()
  local maxw = 0; for _, l in ipairs(lines) do if #l > maxw then maxw = #l end end
  local width  = math.min(state.cfg.hover.max_width or 96, math.max(30, maxw + 2))
  local height = math.min(20, #lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  local win = vim.api.nvim_open_win(buf, false, { relative="cursor", row=1, col=1, width=width, height=height, style="minimal", border="rounded", noautocmd=true })
  state.float_win, state.float_buf = win, buf
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)); state.float_pos = { row=row, col=col }
  state.augroup = vim.api.nvim_create_augroup("edi-hover-" .. tostring(win), { clear = true })
  for _, ev in ipairs(state.cfg.hover.close_events or {}) do vim.api.nvim_create_autocmd(ev, { group = state.augroup, callback = close_float }) end
  vim.keymap.set("n", "<Esc>", close_float, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<CR>",  close_float, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q",     close_float, { buffer = buf, nowait = true, silent = true })
end

function M.hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local cfg = detect_edi(bufnr)
  local seg, seg_s, seg_e = current_segment_at_cursor(cfg)
  if not seg or seg == "" then return end
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) and state.float_pos then
    local r,c = unpack(vim.api.nvim_win_get_cursor(0))
    if state.float_pos.row == r and state.float_pos.col == c then close_float(); return end
  end
  local lines = build_doc(cfg, seg, seg_s, seg_e)
  show_float(lines)
end

-- ========== fetcher (unchanged from last working version) ==========
-- Robust JSON-LD parser for UNCL; logs saved IDs and progress.
local fetcher = {
  running = false, pool = 4, active = 0, next_id = 1, max_id = 9999,
  done = 0, saved = 0, last_saved = nil, last_url = nil, last_count = 0,
}
local function parse_textish(obj)
  if type(obj) == "string" then return obj end
  if type(obj) ~= "table" then return nil end
  if obj[1] ~= nil then
    for _, v in ipairs(obj) do
      if type(v)=="table" and ((v["@language"]=="en") or (v["language"]=="en")) and (v["@value"] or v["value"]) then
        return v["@value"] or v["value"]
      end
      if type(v)=="string" then return v end
    end
    local v = obj[1]
    if type(v)=="table" then return v["@value"] or v["value"] or v["@id"] or v["id"] end
    return nil
  end
  return obj["@value"] or obj["value"] or obj["@id"] or obj["id"] or nil
end
local function parse_code(obj)
  if type(obj) == "string" or type(obj) == "number" then return tostring(obj) end
  if type(obj) ~= "table" then return nil end
  if obj[1] ~= nil then
    local v = obj[1]
    if type(v)=="string" or type(v)=="number" then return tostring(v) end
    if type(v)=="table" then return v["@value"] or v["value"] or v["@id"] or v["id"] end
  end
  return obj["@value"] or obj["value"] or obj["@id"] or obj["id"] or nil
end
local function collect_codes_from_node(node, out)
  if type(node) ~= "table" then return end
  local code = node["rdf:value"] or node["value"] or node["rdf:Value"]
               or node["notation"] or node["skos:notation"]
  local desc = node["rdfs:comment"] or node["comment"] or node["skos:definition"]
               or node["prefLabel"] or node["skos:prefLabel"] or node["rdfs:label"] or node["label"]
  if code and desc then
    local k = parse_code(code); local v = parse_textish(desc)
    if k and v and out[k] == nil then out[k] = v end
  end
  for _, v in pairs(node) do if type(v) == "table" then collect_codes_from_node(v, out) end end
end
local function jsonld_to_map(txt)
  local ok, obj = pcall(vim.fn.json_decode, txt)
  if not ok or not obj then return nil end
  local out = {}; collect_codes_from_node(obj, out)
  if not next(out) and type(obj)=="table" and obj["@graph"] and type(obj["@graph"])=="table" then
    for _, n in ipairs(obj["@graph"]) do collect_codes_from_node(n, out) end
  end
  return next(out) and out or nil
end
local function fetch_url(url, cb)
  local stdout = {}
  local job = vim.fn.jobstart({ "curl", "-fsSL", url }, {
    stdout_buffered = true,
    on_stdout = function(_, data, _) if data then table.insert(stdout, table.concat(data, "\n")) end end,
    on_stderr = function() end,
    on_exit = function(_, code) cb(code == 0, table.concat(stdout, "")) end,
  })
  if job <= 0 then cb(false, nil) end
end
local function save_map(id, base_dir, map)
  local path = string.format("%s/edifact/codes/%d.json", base_dir, id)
  return write_json_atomically(path, map)
end
local function fetch_one(id, base_dir, on_done)
  local url = string.format("https://service.unece.org/trade/uncefact/vocabulary/uncl%04d.jsonld", id)
  fetch_url(url, function(ok, body)
    if ok and body and #body > 0 then
      local map = jsonld_to_map(body)
      if map and next(map) then
        if save_map(id, base_dir, map) then
          fetcher.saved = fetcher.saved + 1
          fetcher.last_saved = id; fetcher.last_url = url
          fetcher.last_count = 0; for _ in pairs(map) do fetcher.last_count = fetcher.last_count + 1 end
          vim.schedule(function()
            vim.notify(string.format("edi: saved UNCL %04d (%d entries) -> edifact/codes/%d.json", id, fetcher.last_count, id), vim.log.levels.INFO)
          end)
          on_done(true); return
        end
      end
    end
    on_done(false)
  end)
end
local timer = nil
local function pump_queue()
  if not fetcher.running then return end
  while fetcher.active < fetcher.pool and fetcher.next_id <= fetcher.max_id do
    local id = fetcher.next_id; fetcher.next_id = id + 1; fetcher.active = fetcher.active + 1
    fetch_one(id, state.cfg.data_dir, function(_saved)
      fetcher.done = fetcher.done + 1; fetcher.active = fetcher.active - 1
      if fetcher.done % 50 == 0 then
        vim.schedule(function()
          local msg = string.format("edi: progress %d/%d, saved %d%s",
            fetcher.done, fetcher.max_id, fetcher.saved,
            fetcher.last_saved and (", last="..string.format("%04d", fetcher.last_saved)) or "")
          vim.notify(msg, vim.log.levels.INFO)
        end)
      end
      if fetcher.done >= fetcher.max_id and fetcher.active == 0 then
        fetcher.running = false
        if timer then timer:stop(); timer:close(); timer = nil end
        vim.schedule(function()
          vim.notify(string.format("edi: EDIFACT fetch complete. Saved %d code lists.", fetcher.saved), vim.log.levels.INFO)
          state.data = { x12={segments={},codes={}}, edifact={segments={},codes={}} }
          pcall(try_load_data_dir)
          vim.notify("edi: data reloaded", vim.log.levels.INFO)
        end)
      end
    end)
  end
end
local function start_fetch_all()
  if fetcher.running then vim.notify("edi: fetch already running", vim.log.levels.WARN); return end
  fetcher.running, fetcher.active = true, 0
  fetcher.next_id, fetcher.max_id, fetcher.done, fetcher.saved = 1, 9999, 0, 0
  fetcher.last_saved, fetcher.last_url, fetcher.last_count = nil, nil, 0
  ensure_dir(state.cfg.data_dir .. "/edifact/codes")
  vim.notify("edi: starting EDIFACT UNCL fetch (0001..9999)", vim.log.levels.INFO)
  if timer then timer:stop(); timer:close(); timer = nil end
  timer = vim.loop.new_timer()
  timer:start(0, 150, function() vim.schedule(pump_queue) end)
end

-- ========== filetype & autocmds ==========
local function maybe_set_ft()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr):lower()
  local cfg = detect_edi(bufnr)
  if name:match("%.x12$") or name:match("%.edifact$") or name:match("%.edi$") then
    apply_syntax(bufnr, cfg)
  else
    local src = buf_text(bufnr)
    if src:find("^%s*ISA") or src:find("^%s*UNB") then apply_syntax(bufnr, cfg) end
  end
end

-- ========== public API ==========
function M.setup(opts)
  if opts and type(opts)=="table" then merge_tables(state.cfg, opts) end
  pcall(try_load_data_dir)

  -- Toggle pretty in place
  vim.api.nvim_create_user_command("EdiPretty", edi_pretty_toggle, { desc="Toggle pretty view (in place)" })

  vim.api.nvim_create_user_command("EdiReloadData", function()
    state.data = { x12={segments={},codes={}}, edifact={segments={},codes={}} }
    pcall(try_load_data_dir)
    vim.notify("edi: data reloaded from " .. state.cfg.data_dir, vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("EdiFetchEdifactAll", function() start_fetch_all() end,
    { desc = "Download ALL UNECE UNCL (0001..9999) into data_dir/edifact/codes" })
  vim.api.nvim_create_user_command("EdiFetchStatus", function()
    local msg = string.format("running=%s pool=%d active=%d next=%d done=%d saved=%d last=%s(%d) url=%s",
      tostring(fetcher.running), fetcher.pool, fetcher.active, fetcher.next_id, fetcher.done, fetcher.saved,
      fetcher.last_saved and string.format("%04d", fetcher.last_saved) or "none",
      fetcher.last_count or 0,
      fetcher.last_url or "n/a")
    vim.notify("edi: " .. msg, vim.log.levels.INFO)
  end, { desc = "Show status of EdiFetchEdifactAll" })

  local grp = vim.api.nvim_create_augroup("edi-core", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, { group = grp, callback = maybe_set_ft })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp, pattern = { "x12", "edifact" },
    callback = function(args)
      vim.keymap.set("n", "K", function() require("edi").hover() end,
        { buffer = args.buf, desc = "EDI: hover segment/element/component" })
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = grp, callback = function()
    -- close float & clean any pretty buffers
    if vim.w.edi_pretty_state and vim.api.nvim_buf_is_valid(vim.w.edi_pretty_state.pretty) then
      pcall(vim.api.nvim_buf_delete, vim.w.edi_pretty_state.pretty, { force = true })
    end
  end })
end

return M

