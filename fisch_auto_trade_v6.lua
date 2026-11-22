--[[
    Fisch - Auto Select Ikan untuk Trade (Rod Set Preset)  v6
    Perubahan dari v5:
    - FIX: item dengan nama+mutasi sama tapi TIDAK di-stack (mis. 2x Spirit Sea Mine
      sebagai 2 slot terpisah) sekarang bisa dipilih semua. Dulu slot ke-2 ikut
      ke-block karena key block = nama+mutasi.
    - FIX: setelah add sukses, jumlah di offer benar-benar dihitung ulang.
    - SET BARU (Lens): Seasonal, Deep, Moonlit, Experimental, Stellar
    - v6.2: FIX log terlihat macet (auto-scroll telat), tombol jadi STOP saat jalan,
      log "→ nama item" tiap mulai item baru
    - v6.1: log jelas kalau item tidak ada / stok habis / metode klik diganti
      (dulu diam saja sehingga terlihat "stuck")
    Perubahan v5 dari v4:
    - FIX: count ulang stack setelah tiap add (bukan asal +1)
    - FIX: guard "blocked" pakai key nama+mutasi (tahan re-render list)
    - FIX: deteksi sukses dicek dulu sebelum coba metode klik (anti false-gagal)
    - FIX: reset workingMethod setelah 3 gagal beruntun
    - SET BARU: Abaia & Terro

    Cara pakai:
      1. Buka trade dengan player lain.
      2. Execute script ini.
      3. Pilih preset di kiri -> "CEK STOK" -> "AUTO SELECT".
]]

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
local CONFIG = {
    ClickDelay    = 0.3,   -- jeda setelah klik (detik)
    WaitConfirm   = 1.5,   -- max tunggu konfirmasi per metode klik (detik)
    PreferPlain   = true,  -- utamakan ikan dengan mutasi tambahan paling sedikit
    MethodRetries = 3,     -- gagal beruntun sebanyak ini -> reset metode hafalan
}

-- Kata ukuran (size) -> DIABAIKAN saat membaca nama ikan
local SIZE_WORDS = { "tiny", "small", "big", "giant", "huge", "massive", "colossal" }

--[[
  Format item preset:
    name     = "Nama Ikan"  atau  {"Nama A", "Nama B"}  (salah satu boleh)
    qty      = jumlah (default 1)
    mutation = nil                    -> mutasi tambahan apa saja (yang paling polos diutamakan)
             = "none"                 -> HARUS tanpa mutasi tambahan
             = "Shiny"                -> harus ada Shiny
             = {"Shiny","Sparkling"}  -> harus ada keduanya
    exact    = true                   -> mutasi tambahan harus PERSIS yang ditulis
    exclude  = {"Awakened"}           -> jangan pilih ikan dengan mutasi ini
    contains = {"king"}               -> nama lengkap harus mengandung teks ini (bebas posisi)

  Tips: mutasi utama (Lunar, Midas, Aurora, dll) cukup ditulis di name,
  contoh name = "Lunar Clownfish". Shiny / Sparkling selalu tampil paling depan,
  jadi tulis di mutation.
]]
local PRESETS = {
    { "Requiem", {
        { name = "Omnithal",              qty = 1 },
        { name = "Fallen Flying Gurnard", qty = 1 },
        { name = "Awakened Omnithal",     qty = 2 },
        { name = "Fossilized Plesiosaur", qty = 1 },
    }},
    { "Tranquility", {
        { name = "Lunar Clownfish",               qty = 3 },
        { name = "Mythical Clownfish",            qty = 1 },
        { name = "Lost Blue Tang",                qty = 3 },
        { name = "Exploded Great White Shark",    qty = 1 },
        { name = "Silver Great Hammerhead Shark", qty = 1 },
        { name = "Abyssal Shortfin Mako Shark",   qty = 3 },
        { name = "Aurora Dumbo Octopus",          qty = 1 },
        { name = "Butterflyfish",                 qty = 3, mutation = "Sparkling" },
        { name = "Midas Golden Seahorse",         qty = 1 },
        { name = "Mythical Treble Bass",          qty = 1 },
        { name = "Heavenly Trumpetfish",          qty = 2 },
        { name = "Aurora Pufferflute",            qty = 1 },
        { name = "Lunar Stringed Grouper",        qty = 1 },
        { name = "Midas Spotted Drum",            qty = 2 },
        { name = "Heavenly Siren Singer",         qty = 2 },
        { name = "Mythical Hidden Pipefish",      qty = 1 },
    }},
    { "Spirit Binder", {
        { name = "Spirit Speed Core", qty = 3 },
        { name = "Spirit Sea Mine",   qty = 2 },
    }},
    { "Plaguereaver", {
        { name = "Decayed Venom Maw", qty = 1 },
        { name = "Blight Idol",       qty = 1 },
        { name = "Noxious Rotbloom",  qty = 1 },
    }},
    { "Wind Elemental", {
        { name = "Pufferfish",          qty = 1, mutation = {"Shiny", "Sparkling"}, contains = {"king"} },
        { name = "Blessed Whale Shark", qty = 1, mutation = "Shiny" },
    }},
    { "Tidemourner", {
        { name = "Iron Chunk",        qty = 5 },
        { name = "Mourned Moonstone", qty = 1 },
    }},
    { "Onirifalx", {
        { name = "Charred Boot",  qty = 1 },
        { name = "Wrath Scylla",  qty = 1 },
        { name = "Wrath Floppy",  qty = 1, mutation = {"Shiny", "Sparkling"} },
    }},
    { "Dreambreaker", {
        { name = "Lucid Enchant Relic", qty = 1 },
        { name = "Lucid Speed Core",  qty = 1 },
        { name = "Lucid Cathulid",    qty = 1 },
        { name = "Phantom Cathulith", qty = 1 },
        { name = { "Profane Leviathan", "Lucid Leviathan" }, qty = 1 },
    }},
    { "Mossriper", {
        { name = "Shrouded Golden Sea Pearl", qty = 1 },
        { name = "Elder Mossjaw",             qty = 1 },
    }},
    { "Toxin Burst", {
        { name = "Blight Pufferfish", qty = 1 },  -- "Giant" dianggap size
        { name = "Toxic Widow Bloom", qty = 1 },
        { name = "Decayed Venom Maw", qty = 1 },
        { name = "Toxic Jellymass",   qty = 1 },
    }},
    { "Tidefall", {
        { name = "Omnithal",   qty = 1, exclude = {"Awakened"} },
        { name = "Goldwraith", qty = 1 },
        { name = "Reef Titan", qty = 1 },
        { name = "Pliosaur",   qty = 1 },
        { name = "Dripstone",  qty = 1, mutation = "Sparkling" },
    }},
    { "Roteo", {
        { name = "Hexed Enchant Relic",        qty = 1 },
        { name = "Crystalized Enchant Relic", qty = 1 },
        { name = "Greedy Enchant Relic",       qty = 1 },
        { name = "Fossilized Enchant Relic",   qty = 1 },
        { name = "Mosaic Enchant Relic",       qty = 1 },
        { name = "Translucent Enchant Relic",  qty = 1 },
        { name = "Atlantean Enchant Relic",    qty = 1 },
    }},
    { "Thalassar", {
        { name = "Sunken Enchant Relic", qty = 1 },
        { name = "Cosmic Relic",         qty = 2 },
        { name = "Exalted Relic",        qty = 3 },
    }},
    { "Merlin Staff", {
        { name = "Anomalous Log", qty = 1 },
        { name = "Iron Chunk",    qty = 1 },
    }},
    { "Translator", {
        { name = "Device Display",        qty = 1 },
        { name = "Translator Core",       qty = 1 },
        { name = "Communication Circuit", qty = 1 },
    }},
    { "Abaia", {
        { name = "Squalled Abaia",           qty = 1 },
        { name = "Ancestral Abaia",          qty = 1 },
        { name = "Petrified Empyrean Relic", qty = 1 },
    }},
    { "Terro", {
        { name = "Photic Terrosunder",       qty = 1 },
        { name = "Marrow Terrosunder Skull", qty = 1 },
        { name = "Fossilized Opal",          qty = 1 },
    }},

    -- ===================== LENS SET =====================
    { "Seasonal Lens", {
        { name = "Seasonal Glass",        qty = 1 },
        { name = "Rotting Glass Diamond", qty = 1 },
        -- salah satu dari 3 varian Sturgeon ini boleh
        { name = { "Seasonal Floraseer Sturgeon", "Seasonal Umbraleaf Sturgeon", "Seasonal Glaciaseer Sturgeon" }, qty = 1 },
    }},
    { "Deep Lens", {
        { name = "Hardened Glass",      qty = 1 },
        { name = "Abyssal Comb Jelly",  qty = 1 },
        { name = "Abyssal Resin",       qty = 1 },
    }},
    { "Moonlit Lens", {
        { name = "Frozen Glass",             qty = 1 },
        { name = "Aurora Boreal Man o' War", qty = 1 },
        { name = "Frozen Resin",             qty = 1 },
    }},
    { "Experimental Lens", {
        { name = "Quartz Glass",         qty = 1 },
        { name = "Chaotic Golden Trout", qty = 1 },
        { name = "Fallen Resin",         qty = 1 },
    }},
    { "Stellar Lens", {
        { name = "Starfall Glass",       qty = 1 },
        { name = "Celestial Aurora Gar", qty = 1 },
        { name = "Nova Resin",           qty = 1 },
    }},
}

------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------
local Players    = game:GetService("Players")
local VIM        = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- UTIL TEKS
------------------------------------------------------------------
local SIZE = {}
for _, w in ipairs(SIZE_WORDS) do SIZE[w] = true end

local function plain(s)
    s = tostring(s or "")
    s = (s:gsub("<[^>]->", ""))
    s = (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&"))
    s = (s:gsub("%s+", " "))
    return (s:match("^%s*(.-)%s*$")):lower()
end

local function endsWithWord(full, name)
    if full == name then return true end
    local suffix = " " .. name
    return #full > #suffix and full:sub(-#suffix) == suffix
end

local function hasWord(str, word)
    return (" " .. str .. " "):find(" " .. word .. " ", 1, true) ~= nil
end

local function removeSizeWords(s)
    local out = {}
    for w in s:gmatch("%S+") do
        if not SIZE[w] then table.insert(out, w) end
    end
    return table.concat(out, " ")
end

local SKIP = { _add = true, _rem = true, ItemTemplate = true }
local function isItem(b)
    return b:IsA("GuiObject") and not SKIP[b.Name]
        and (b:FindFirstChild("ItemName") ~= nil or b:IsA("GuiButton"))
end

local function stackOf(b)
    local st = b:FindFirstChild("Stack")
    if st and st:IsA("TextLabel") and st.Text ~= "" then
        return tonumber(st.Text:match("%d+")) or 1
    end
    return 1
end

-- core = nama lengkap TANPA size, contoh "shiny sparkling captain's goldfish"
local function itemCore(b)
    local lbl = b:FindFirstChild("ItemName")
    local full = lbl and plain(lbl.Text) or plain(b.Name)
    local base = plain(b.Name)
    if base ~= "" and endsWithWord(full, base) then
        local prefix = full:sub(1, #full - #base)
        prefix = removeSizeWords(prefix)
        return (prefix ~= "" and (prefix .. " ") or "") .. base
    end
    return removeSizeWords(full)
end

local function titleCase(s)
    return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end

local function toList(v)
    if v == nil then return nil end
    if type(v) == "string" then return { v } end
    return v
end

local function specLabel(spec)
    local n = table.concat(toList(spec.name), " / ")
    local mut = toList(spec.mutation)
    if mut then n = table.concat(mut, " ") .. " " .. n end
    return n
end

------------------------------------------------------------------
-- KLIK
------------------------------------------------------------------
local function fireConns(btn, sig)
    if not getconnections then return false end
    local ok, conns = pcall(getconnections, btn[sig])
    if not (ok and conns and #conns > 0) then return false end
    for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
    return true
end

local function scrollIntoView(btn)
    local sf = btn:FindFirstAncestorWhichIsA("ScrollingFrame")
    if not sf then return end
    local relY = btn.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
    sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X,
        math.max(0, relY - sf.AbsoluteSize.Y / 2 + btn.AbsoluteSize.Y / 2))
    task.wait(0.15)
end

local function virtualClick(btn)
    scrollIntoView(btn)
    local sg = btn:FindFirstAncestorWhichIsA("ScreenGui")
    local inset = (sg and sg.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
    local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2 + inset
    VIM:SendMouseMoveEvent(pos.X, pos.Y, game)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
    task.wait(0.06)
    VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    return true
end

local CLICK_METHODS = {
    { name = "Activated",         fn = function(b) return fireConns(b, "Activated") end },
    { name = "MouseButton1Click", fn = function(b) return fireConns(b, "MouseButton1Click") end },
    { name = "Down+Up", fn = function(b)
        local a = fireConns(b, "MouseButton1Down")
        task.wait(0.05)
        local c = fireConns(b, "MouseButton1Up")
        return a or c
    end },
    { name = "firesignal", fn = function(b)
        if not firesignal then return false end
        return (pcall(firesignal, b.MouseButton1Click))
    end },
    { name = "VirtualClick", fn = virtualClick },
}
local workingMethod = nil
local failStreak = 0
local cancelled = false   -- v6.2: diset true saat tombol STOP ditekan

local function clickButton(btn)
    if fireConns(btn, "MouseButton1Click") or fireConns(btn, "Activated") then return true end
    return virtualClick(btn)
end

------------------------------------------------------------------
-- UI TRADE
------------------------------------------------------------------
local function getUI()
    local hud  = PGui:FindFirstChild("hud")
    local safe = hud and hud:FindFirstChild("safezone")
    local root = safe and safe:FindFirstChild("Trade")
    if not root then return nil, "Frame Trade tidak ditemukan" end
    if not root.Visible then return nil, "Trade belum dibuka" end
    local po   = root:FindFirstChild("PlayerOffer")
    local list = po and po:FindFirstChild("List")
    local ui = {
        root       = root,
        offerList  = list and list:FindFirstChild("ScrollingFrame"),
        offerables = list and list:FindFirstChild("Offerables"),
        tabs       = root:FindFirstChild("Tabs"),
    }
    if not (ui.offerList and ui.offerables) then return nil, "Struktur UI trade berubah" end
    ui.addBtn = ui.offerList:FindFirstChild("_add")
    return ui
end

local function openOfferables(ui)
    if ui.offerables.Visible then return end
    if ui.addBtn then clickButton(ui.addBtn) end
    for _ = 1, 20 do
        if ui.offerables.Visible then break end
        task.wait(0.05)
    end
    local fishTab = ui.tabs and ui.tabs:FindFirstChild("Fish")
    if fishTab then clickButton(fishTab) task.wait(0.3) end
end

local function offerTotal(ui)
    local t = 0
    for _, b in ipairs(ui.offerList:GetChildren()) do
        if isItem(b) and b.Visible then t += stackOf(b) end
    end
    return t
end

------------------------------------------------------------------
-- MATCHER (nama + mutasi)
------------------------------------------------------------------
local function buildMatcher(spec, preset)
    local names = {}
    for _, n in ipairs(toList(spec.name)) do table.insert(names, plain(n)) end

    -- nama lebih panjang di preset yang sama (mis. "awakened omnithal" vs "omnithal")
    local longer = {}
    for _, other in ipairs(preset) do
        for _, on in ipairs(toList(other.name)) do
            on = plain(on)
            for _, n in ipairs(names) do
                if on ~= n and endsWithWord(on, n) then table.insert(longer, on) end
            end
        end
    end

    local mutList = toList(spec.mutation)
    local wantNone = mutList and #mutList == 1 and plain(mutList[1]) == "none"
    local need = {}
    if mutList and not wantNone then
        for _, m in ipairs(mutList) do table.insert(need, plain(m)) end
    end
    local excl, cont = {}, {}
    for _, k in ipairs(spec.exclude or {}) do table.insert(excl, plain(k)) end
    for _, k in ipairs(spec.contains or {}) do table.insert(cont, plain(k)) end

    -- return: cocok?, mutasiTambahan
    return function(b)
        local core = itemCore(b)
        for _, l in ipairs(longer) do
            if endsWithWord(core, l) then return false end
        end
        local hit
        for _, n in ipairs(names) do
            if endsWithWord(core, n) then hit = n break end
        end
        if not hit then return false end

        local mut = core:sub(1, #core - #hit):match("^%s*(.-)%s*$")

        for _, k in ipairs(excl) do if hasWord(mut, k) then return false end end
        for _, k in ipairs(cont) do if not core:find(k, 1, true) then return false end end

        if wantNone then
            if mut ~= "" then return false end
        elseif #need > 0 then
            for _, k in ipairs(need) do
                if not hasWord(mut, k) then return false end
            end
            if spec.exact then
                local rest = " " .. mut .. " "
                for _, k in ipairs(need) do
                    rest = rest:gsub(" " .. k:gsub("%p", "%%%0") .. " ", " ")
                end
                if rest:match("%S") then return false end
            end
        end
        return true, mut
    end
end

local function countIn(container, matcher)
    local total = 0
    for _, b in ipairs(container:GetChildren()) do
        if isItem(b) and b.Visible and matcher(b) then total += stackOf(b) end
    end
    return total
end

------------------------------------------------------------------
-- CORE
------------------------------------------------------------------
local function checkStock(preset, log)
    local ui, err = getUI()
    if not ui then log(err) return end
    openOfferables(ui)
    local okAll = true
    for _, spec in ipairs(preset) do
        local m = buildMatcher(spec, preset)
        local groups, total = {}, 0
        for _, b in ipairs(ui.offerables:GetChildren()) do
            if isItem(b) and b.Visible then
                local ok, mut = m(b)
                if ok then
                    local key = mut == "" and "polos" or titleCase(mut)
                    groups[key] = (groups[key] or 0) + stackOf(b)
                    total += stackOf(b)
                end
            end
        end
        local qty = spec.qty or 1
        if total < qty then okAll = false end
        local parts = {}
        for k, v in pairs(groups) do table.insert(parts, k .. " x" .. v) end
        table.sort(parts)
        log(("%s %s: %d/%d %s"):format(total >= qty and "✔" or "✘", specLabel(spec), total, qty,
            #parts > 0 and ("(" .. table.concat(parts, ", ") .. ")") or ""))
    end
    log(okAll and "Stok LENGKAP." or "Stok BELUM lengkap.")
end

local function tryAdd(ui, btn, log)
    -- FIX #4: kalau item tiba-tiba hilang, kemungkinan klik sebelumnya BERHASIL
    -- (konfirmasi terlambat) -> jangan langsung dianggap gagal.
    if not (btn.Parent and btn.Visible) then
        return true
    end

    local methods = {}
    if workingMethod then table.insert(methods, workingMethod) end
    for _, mt in ipairs(CLICK_METHODS) do
        if mt ~= workingMethod then table.insert(methods, mt) end
    end

    for i, mt in ipairs(methods) do
        if cancelled then return false end
        if i > 1 then log("  … klik belum masuk, coba metode: " .. mt.name) end
        if not ui.offerables.Visible then openOfferables(ui) end
        if not (btn.Parent and btn.Visible) then
            -- hilang saat metode berganti -> kemungkinan besar sudah masuk offer
            return true
        end

        local beforeOffer = offerTotal(ui)
        local beforeStack = stackOf(btn)

        if mt.fn(btn) then
            task.wait(CONFIG.ClickDelay)
            local t = 0
            while t < CONFIG.WaitConfirm do
                local gone    = (btn.Parent ~= ui.offerables) or not btn.Visible
                local lessStk = btn.Parent and stackOf(btn) < beforeStack
                local more    = offerTotal(ui) > beforeOffer
                if gone or lessStk or more then
                    if workingMethod ~= mt then
                        workingMethod = mt
                        log("Metode klik: " .. mt.name)
                    end
                    failStreak = 0
                    return true
                end
                task.wait(0.1) t += 0.1
            end
        end
    end

    -- FIX: reset metode hafalan setelah gagal beruntun
    failStreak += 1
    if failStreak >= CONFIG.MethodRetries then
        workingMethod = nil
        failStreak = 0
        log("Reset metode klik (gagal beruntun).")
    end
    return false
end

-- hitung berapa item yang benar-benar sudah masuk offer (untuk verifikasi akhir)
local function recountHave(ui, m, timeout)
    local t = 0
    local last
    while t < (timeout or 1) do
        last = countIn(ui.offerList, m)
        task.wait(0.1) t += 0.1
    end
    return last or countIn(ui.offerList, m)
end

local function autoSelect(preset, log)
    local ui, err = getUI()
    if not ui then log(err) return end

    local missing = {}
    for _, spec in ipairs(preset) do
        local qty = spec.qty or 1
        local m = buildMatcher(spec, preset)
        -- FIX #1: hitung berdasarkan stack yang benar-benar ada di offer
        local have = countIn(ui.offerList, m)
        -- v6: block per-INSTANCE (slot tertentu), bukan per nama+mutasi,
        -- supaya slot lain dengan nama sama tetap bisa dipilih.
        local blocked = {}     -- [button] = true
        local failByKey = {}   -- ["core|mutasi"] = jumlah gagal (tahan re-render)
        local MAX_KEY_FAIL = 2
        local guard = 0

        if cancelled then log("⏹ Dihentikan.") return end
        log("→ " .. specLabel(spec) .. " ...")
        while have < qty and guard < qty * 3 + 3 and not cancelled do
            guard += 1
            openOfferables(ui)

            local cands = {}
            for _, b in ipairs(ui.offerables:GetChildren()) do
                if isItem(b) and b.Visible then
                    local ok, mut = m(b)
                    local key = ok and (itemCore(b) .. "|" .. mut)
                    if ok and not blocked[b] and (failByKey[key] or 0) < MAX_KEY_FAIL then
                        local nMut = 0
                        for _ in mut:gmatch("%S+") do nMut += 1 end
                        table.insert(cands, { b = b, mut = mut, n = stackOf(b), nMut = nMut })
                    end
                end
            end
            if #cands == 0 then
                -- v6.1: jangan diam saja, kasih tahu kenapa berhenti
                if have == 0 then
                    log("✘ " .. specLabel(spec) .. ": tidak ditemukan di inventory")
                else
                    log(("✘ %s: stok habis (%d/%d)"):format(specLabel(spec), have, qty))
                end
                break
            end

            table.sort(cands, function(a, b)
                if CONFIG.PreferPlain and a.nMut ~= b.nMut then return a.nMut < b.nMut end
                if (a.n > 1) ~= (b.n > 1) then return a.n == 1 end
                return false
            end)

            local c = cands[1]
            local label = specLabel(spec) .. (c.mut ~= "" and (" [" .. titleCase(c.mut) .. "]") or "")
            local key = itemCore(c.b) .. "|" .. c.mut
            local prevHave = have
            if tryAdd(ui, c.b, log) then
                -- hitung ulang isi offer (tunggu sebentar kalau UI telat update)
                local actual = prevHave
                for _ = 1, 10 do
                    actual = countIn(ui.offerList, m)
                    if actual > prevHave then break end
                    task.wait(0.1)
                end
                have = math.max(actual, prevHave + 1)
                log(("✔ %s (%d/%d)"):format(label, have, qty))
                -- slot ini habis -> jangan diklik lagi (slot lain nama sama tetap boleh)
                if c.n <= 1 then blocked[c.b] = true end
            else
                blocked[c.b] = true
                failByKey[key] = (failByKey[key] or 0) + 1
                log("✘ gagal add: " .. label)
            end
        end

        if have < qty then
            -- verifikasi akhir: hitung ulang offer yang benar-benar masuk
            -- (menangani klik yang terlambat terkonfirmasi / terlewat)
            local actual = recountHave(ui, m, have > 0 and 1 or 0.3)
            if actual > have then
                have = actual
                log(("%s: terkoreksi jadi %d/%d"):format(specLabel(spec), have, qty))
            end
        end
        if have < qty then
            table.insert(missing, ("%s x%d"):format(specLabel(spec), qty - have))
        end
    end

    if #missing == 0 then
        log("SELESAI! Set lengkap. Cek offer lalu klik Ready.")
    else
        log("KURANG: " .. table.concat(missing, ", "))
    end
end

------------------------------------------------------------------
-- GUI
------------------------------------------------------------------
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local old = guiParent:FindFirstChild("FischAutoTrade")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "FischAutoTrade"
sg.ResetOnSpawn = false
sg.Parent = guiParent

local C_BG    = Color3.fromRGB(25, 28, 38)
local C_PANEL = Color3.fromRGB(15, 17, 24)
local C_BTN   = Color3.fromRGB(45, 50, 70)
local C_SEL   = Color3.fromRGB(80, 110, 200)
local WHITE   = Color3.new(1, 1, 1)

local function new(class, parent, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    if class == "TextButton" or class == "ScrollingFrame" then
        Instance.new("UICorner", o).CornerRadius = UDim.new(0, 6)
    end
    return o
end

local main = new("Frame", sg, {
    Size = UDim2.fromOffset(520, 400), Position = UDim2.new(0, 20, 0.5, -200),
    BackgroundColor3 = C_BG, Active = true, Draggable = true,
})
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

new("TextLabel", main, {
    Size = UDim2.new(1, -70, 0, 30), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Text = "🎣 Fisch Auto Trade Select v6",
    TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local closeBtn = new("TextButton", main, {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0, 4),
    BackgroundColor3 = Color3.fromRGB(170, 60, 60), Text = "X",
    TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12,
})
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local minBtn = new("TextButton", main, {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -54, 0, 4),
    BackgroundColor3 = C_BTN, Text = "–",
    TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
})

local body = new("Frame", main, {
    Size = UDim2.new(1, 0, 1, -32), Position = UDim2.fromOffset(0, 32),
    BackgroundTransparency = 1,
})
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(520, 30) or UDim2.fromOffset(520, 400)
end)

-- kiri: daftar preset
local presetList = new("ScrollingFrame", body, {
    Size = UDim2.new(0, 150, 1, -10), Position = UDim2.fromOffset(10, 0),
    BackgroundColor3 = C_PANEL, BorderSizePixel = 0, ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
})
local pl = Instance.new("UIListLayout", presetList)
pl.Padding = UDim.new(0, 4)
pl.SortOrder = Enum.SortOrder.LayoutOrder
local pp = Instance.new("UIPadding", presetList)
pp.PaddingTop, pp.PaddingLeft, pp.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 8)

-- kanan atas: isi preset
local itemBox = new("ScrollingFrame", body, {
    Size = UDim2.new(1, -180, 0, 140), Position = UDim2.fromOffset(170, 0),
    BackgroundColor3 = C_PANEL, BorderSizePixel = 0, ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
})
local itemLbl = new("TextLabel", itemBox, {
    Size = UDim2.new(1, -12, 0, 0), Position = UDim2.fromOffset(6, 4),
    AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(190, 200, 220), Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, RichText = true,
})

local stockBtn = new("TextButton", body, {
    Size = UDim2.new(0.5, -95, 0, 30), Position = UDim2.fromOffset(170, 146),
    BackgroundColor3 = Color3.fromRGB(60, 100, 170), Text = "CEK STOK",
    TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13,
})
local goBtn = new("TextButton", body, {
    Size = UDim2.new(0.5, -95, 0, 30), Position = UDim2.new(0.5, 85, 0, 146),
    BackgroundColor3 = Color3.fromRGB(60, 160, 90), Text = "AUTO SELECT",
    TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13,
})

-- kanan bawah: log
local logBox = new("ScrollingFrame", body, {
    Size = UDim2.new(1, -180, 1, -192), Position = UDim2.fromOffset(170, 182),
    BackgroundColor3 = C_PANEL, BorderSizePixel = 0, ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
})
local logLbl = new("TextLabel", logBox, {
    Size = UDim2.new(1, -12, 0, 0), Position = UDim2.fromOffset(6, 4),
    AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(150, 230, 160), Font = Enum.Font.Code, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, Text = "",
})

-- v6.2: auto-scroll log. Dulu scroll dijalankan SEBELUM ukuran canvas ter-update,
-- jadi baris baru tertulis di bawah area yang terlihat (log kelihatan "macet").
local function scrollLogBottom()
    logBox.CanvasPosition = Vector2.new(0, math.max(0, logBox.AbsoluteCanvasSize.Y - logBox.AbsoluteSize.Y))
end
logBox:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(scrollLogBottom)
logLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(scrollLogBottom)

local logs = {}
local function log(msg)
    table.insert(logs, msg)
    if #logs > 60 then table.remove(logs, 1) end
    logLbl.Text = table.concat(logs, "\n")
    task.delay(0.05, scrollLogBottom)
    print("[AutoTrade] " .. msg)
end

-- preset selection
local selected = 1
local presetBtns = {}
local function refreshPreset()
    for i, b in ipairs(presetBtns) do
        b.BackgroundColor3 = (i == selected) and C_SEL or C_BTN
    end
    local name, items = PRESETS[selected][1], PRESETS[selected][2]
    local lines = { "<b>" .. name .. " set</b>" }
    for _, it in ipairs(items) do
        table.insert(lines, ("• %s  <b>x%d</b>"):format(specLabel(it), it.qty or 1))
    end
    itemLbl.Text = table.concat(lines, "\n")
end

for i, p in ipairs(PRESETS) do
    local b = new("TextButton", presetList, {
        Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i,
        BackgroundColor3 = C_BTN, Text = p[1],
        TextColor3 = WHITE, Font = Enum.Font.Gotham, TextSize = 12,
    })
    presetBtns[i] = b
    b.MouseButton1Click:Connect(function()
        selected = i
        refreshPreset()
    end)
end
refreshPreset()

local busy = false
local function run(btn, label, fn)
    btn.MouseButton1Click:Connect(function()
        if busy then
            -- v6.2: klik lagi saat jalan = STOP
            if not cancelled then
                cancelled = true
                log("⏹ Menghentikan... (tunggu proses klik saat ini selesai)")
            end
            return
        end
        busy = true
        cancelled = false
        btn.Text = "STOP"
        logs = {}
        workingMethod = nil
        failStreak = 0
        log("== " .. PRESETS[selected][1] .. " ==")
        local ok, err = pcall(fn, PRESETS[selected][2], log)
        if not ok then log("Error: " .. tostring(err)) end
        btn.Text = label
        busy = false
    end)
end
run(stockBtn, "CEK STOK", checkStock)
run(goBtn, "AUTO SELECT", autoSelect)

log("Siap. Pilih preset, buka trade, lalu klik AUTO SELECT.")
