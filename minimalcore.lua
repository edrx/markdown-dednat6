-- This file:
--   http://angg.twu.net/markdown-dednat6/minimalcore.lua.html
--   http://angg.twu.net/markdown-dednat6/minimalcore.lua
--           (find-angg "markdown-dednat6/minimalcore.lua")
-- Author: Eduardo Ochs <eduardoochs@gmail.com>
--
-- This is essentially a copy of:
--   http://angg.twu.net/dednat6/dednat6/minimalcore.lua.html
--   http://angg.twu.net/dednat6/dednat6/minimalcore.lua
--           (find-angg "dednat6/dednat6/minimalcore.lua")

-- This is a single-file implementation of the "core" of dednat6.
-- It only implements one head: "%L".
-- It doesn't depend on edrxlib.lua (that has LOTS of cruft).
-- It desn't change "require" to work more like standard Lua - see 
-- lualoader.lua.








-- Some functions from edrxlib.lua.
-- From: (find-angg "LUA/lua50init.lua")
--
fnamedirectory    = function (fname) return fname:match"^(.*/)[^/]*$"  end
fnamenondirectory = function (fname) return fname:match     "([^/]*)$" end

readfile = function (fname)
    local f = assert(io.open(fname, "r"))
    local bigstr = f:read("*a")
    f:close()
    return bigstr
  end
ee_expand = function (path)
    path = string.gsub(path, "^~$", "$HOME/", 1)
    path = string.gsub(path, "^~/", "$HOME/", 1)
    path = string.gsub(path, "^%$(%w+)", os.getenv, 1)
    return path
  end
ee_readfile  = function (fname) return readfile(ee_expand(fname)) end

split = function (str, pat)
    local arr = {}
    string.gsub(str, pat or "([^%s]+)", function (word)
        table.insert(arr, word)
      end)
    return arr
  end
splitlines = function (bigstr)
    local arr = split(bigstr, "([^\n]*)\n?")
    if _VERSION:sub(5) < "5.3" then
      table.remove(arr)
    end
    return arr
  end

string.len8 = function (str) return str:gsub("[\128-\191]+", ""):len() end
strlen8 = string.len8
untabify_table =
  {"        ", "       ", "      ", "     ", "    ", "   ", "  ", " "}
--{"--------", "-------", "------", "-----", "----", "---", "--", "-"}
untabify8_strtab = function (strbeforetab)
    return strbeforetab ..
      untabify_table[math.fmod(strlen8(strbeforetab), 8) + 1]
  end
untabify8 = function (str)
    return (gsub(str, "([^\t\r\n]*)\t", untabify8_strtab))
  end
untabify = untabify8





-- From: (find-dn6file "eoo.lua")
Class = {
    type   = "Class",
    __call = function (class, o) return setmetatable(o, class) end,
  }
setmetatable(Class, Class)


-- From: (find-dn6file "output.lua")
deletecomments1 = function (line)
    return line:match"^([^%%]*)"
  end
deletecomments = function (bigstr)
    return (bigstr:gsub("([^\n]+)", deletecomments1))
  end
output = function (str)
    tex.print(deletecomments(str))
    print(str)
  end


-- From: (find-dn6file "heads.lua")
heads = {}
registerhead = function (headstr)
    return function (head)
        head.headstr = headstr
        heads[headstr] = head
      end
  end
registerhead "%L" {
  name   = "lua",
  action = function ()
      local i,j,luacode = tf:getblockstr()
      local chunkname = tf.name..":%L:"..i.."-"..j
      assert(loadstring(luacode, chunkname))()
    end,
}



-- From: (find-dn6file "block.lua")
--
TexLines = Class {
  type = "TexLines",
  new  = function (name, lines)
      return TexLines({name=name}):setlines(lines)
    end,
  read = function (fname)
      return TexLines.new(fnamenondirectory(fname), ee_readfile(fname))
    end,
  test = function (str)
      local tr = {["L"]="%L", ["D"]="%D", [":"]="%:", ["p"]="\\pu"}
      local tl = TexLines {name="(test)"}
      for c in str:gmatch"." do table.insert(tl, tr[c] or c) end
      return tl
    end,
  __tostring = function (tl) return tl:tostring() end,
  __index = {
    setlines = function (tl, lines)
        if type(lines) == "string" then lines = splitlines(lines) end
        for i=1,#lines do tl[i] = lines[i] end
        return tl
      end,
    nlines = function (tl) return #tl end,
    line = function (tl, i) return tl[i] end,
    --
    head = function (tl, i)
        local li = tl:line(i)
        local p = function (len)
            local s = li:sub(1, len)
            return heads[s] and s
          end
        return li and (p(3) or p(2) or p(1) or p(0))
      end,
    nohead = function (tl, i)
        return tl:line(i):sub(#tl:head(i) + 2)
      end,
    --
    tostring1 = function (tl, i) return format("%3d: %s", i, tl:line(i)) end,
    tostring  = function (tl, i, j)
        local T = {}
        for k=(i or 1),(j or tl:nlines()) do
          table.insert(T, tl:tostring1(k))
        end
        return table.concat(T, "\n")
      end,
    --
    toblock = function (tl)
        return Block {i=1, j=#tl, nline=1, name=tl.name}
      end,
  },
}

headblocks = {}   -- a "log" of all the head blocks processed so far

Block = Class {
  type    = "Block",
  __tostring = mytostring,
  __index = {
    firstheadblockin = function (bl, i0, j0)
        local i,j
        for i1=i0,j0 do
          if texlines:head(i1) then i=i1; break end 
        end
        if not i then return end
        local head = texlines:head(i)
        for j1=i+1,j0 do
          if texlines:head(j1) ~= head then
            return Block {i=i, j=j1-1, head=head}
          end 
        end
        return Block {i=i, j=bl.j, head=head}
      end,
    --
    processheadblock = function (bl)
        lastheadblock = bl                    -- for ":getblock()"s
        table.insert(headblocks, bl)
        local action = heads[bl.head].action  -- uses "tf:getblock()"
        if action then action() else print("No action for "..bl.head) end
      end,
    processarbitraryblock = function (bl)
        -- print("process arbitrary:", mytostring(bl))
        local i0 = bl.i
        while true do
          local headbl = bl:firstheadblockin(i0, bl.j)
          if not headbl then return end
          headbl:processheadblock()
          i0 = headbl.j + 1
        end
      end,
    process = function (bl)
        -- print("process:", mytostring(bl))
        if bl.head
        then bl:processheadblock(bl)
        else bl:processarbitraryblock(bl)
        end
      end,
    --
    processuntil = function (bl, puline)
        local publock = Block {i=bl.nline, j=puline-1}
        publock:process()
        bl.nline = puline+1
        return bl
      end,
    --
    getblock = function (bl)
        local i,j,head = lastheadblock.i, lastheadblock.j, lastheadblock.head
        local A = {}
        for k=i,j do
            table.insert(A, texlines:line(k):sub(#head+1))
          end
        return i,j,A
      end,
    getblockstr = function (bl)
        local i,j,A = tf:getblock()
        return i,j,table.concat(A, "\n")
      end,
    -- hyperlink = function (bl)
    --     return "Line "..lastheadblock.i
    --   end,
    hyperlink = function (bl)
        return format("In the \"%s\"-block in lines %d--%d",
                      lastheadblock.head, lastheadblock.i, lastheadblock.j)
      end,
  },
}

texfile0 = function (fname)
    texlines = TexLines.read(fname)
    tf = texlines:toblock()
  end
texfile = function (fname)
    texfile0(fname..".tex")
  end

pu = function (puline) tf:processuntil(puline or tex.inputlineno) end






