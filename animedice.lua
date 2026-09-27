-- AliceHUB Anime Dice UPD5 Fuse Native-Aligned Fix
-- AliceHUB · Anime Dice · UPD 5 Fuse Filter + Put Back/Home Recovery
-- Based on latest V2 Full Rarity + current game data (2026-09-13)
-- Refactor only: late top-level helpers moved into existing C namespace
-- to stay below Arceus/Luau local-register limit.
-- Game logic intentionally unchanged.

-- AliceHUB Anime Dice · Auto Sell Rarity Fix
--[[
    AliceHUB · Anime Dice
]]

-- Tunggu game selesai dimuat.
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ENV = getgenv and getgenv() or _G
local C = {} -- runtime state

-- Bersihkan instance lama.
if type(ENV.AliceHUB_AnimeDice_Cleanup) == "function" then
    pcall(ENV.AliceHUB_AnimeDice_Cleanup)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    return
end

-- ============================================================
-- EARLY VISIBLE BOOT SHELL
-- Tampilkan indikator awal sebelum menu utama.

-- ============================================================
local __AliceBootGui = nil
local __AliceBootStatus = nil

local function __aliceBootRoot()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then
        pcall(function() pg = LocalPlayer:WaitForChild("PlayerGui", 8) end)
    end
    if pg then return pg end
    if type(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then return root end
    end
    return CoreGui
end

local function __aliceBootSet(text)
    if __AliceBootStatus and __AliceBootStatus.Parent then
        __AliceBootStatus.Text = tostring(text or "Loading...")
    end
end

local function __aliceBootDestroy()
    if __AliceBootGui and __AliceBootGui.Parent then
        pcall(function() __AliceBootGui:Destroy() end)
    end
    __AliceBootGui = nil
    __AliceBootStatus = nil
end

do
    pcall(function()
        local root = __aliceBootRoot()
        if not root then return end
        local old = root:FindFirstChild("AliceHUB_AnimeDice_Boot")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "AliceHUB_AnimeDice_Boot"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 2147483001
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = root
        __AliceBootGui = gui

        local box = Instance.new("Frame")
        box.AnchorPoint = Vector2.new(0.5, 0.5)
        box.Position = UDim2.fromScale(0.5, 0.5)
        box.Size = UDim2.fromOffset(330, 126)
        box.BackgroundColor3 = Color3.fromRGB(11, 9, 11)
        box.BorderSizePixel = 0
        box.Parent = gui
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 7)
        c.Parent = box
        local st = Instance.new("UIStroke")
        st.Color = Color3.fromRGB(181, 48, 83)
        st.Thickness = 1.5
        st.Transparency = 0.08
        st.Parent = box

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(16, 14)
        title.Size = UDim2.new(1, -32, 0, 30)
        title.Font = Enum.Font.Code
        title.Text = "AliceHUB"
        title.TextColor3 = Color3.fromRGB(242, 236, 239)
        title.TextSize = 21
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = box

        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.Position = UDim2.fromOffset(16, 43)
        sub.Size = UDim2.new(1, -32, 0, 22)
        sub.Font = Enum.Font.Code
        sub.Text = "Anime Dice"
        sub.TextColor3 = Color3.fromRGB(180, 126, 143)
        sub.TextSize = 13
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = box

        local status = Instance.new("TextLabel")
        status.BackgroundTransparency = 1
        status.Position = UDim2.fromOffset(16, 78)
        status.Size = UDim2.new(1, -32, 0, 30)
        status.Font = Enum.Font.Code
        status.Text = "AliceHUB siap · memuat UI..."
        status.TextColor3 = Color3.fromRGB(215, 204, 208)
        status.TextSize = 12
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextWrapped = true
        status.Parent = box
        __AliceBootStatus = status
    end)
end

local Runtime = {
    alive = true,
    startedAt = os.clock(),
    connections = {},
    loopTokens = {},
    lastAction = "Ready",
}

local function rememberConnection(connection)
    if connection then
        Runtime.connections[#Runtime.connections + 1] = connection
    end
    return connection
end

local function setLastAction(text)
    Runtime.lastAction = tostring(text or "")
end

local function findPath(root, ...)
    local current = root
    for index = 1, select("#", ...) do
        if not current then return nil end

        local childName = select(index, ...)
        current = current:FindFirstChild(childName)
    end
    return current
end

local function safeRequire(module)
    if not module then return nil end
    local ok, result = pcall(require, module)
    if ok then return result end
    return nil
end

local function compactNumber(value)
    local number = tonumber(value)
    if not number then return tostring(value or "0") end
    local absolute = math.abs(number)
    local function fmt(divisor, suffix)
        local result = number / divisor
        if math.abs(result) >= 100 then
            return string.format("%.0f%s", result, suffix)
        elseif math.abs(result) >= 10 then
            return string.format("%.1f%s", result, suffix):gsub("%.0", "")
        end
        return string.format("%.2f%s", result, suffix):gsub("0+$", ""):gsub("%.$", "")
    end
    if absolute >= 1e24 then return fmt(1e24, "Sp") end
    if absolute >= 1e21 then return fmt(1e21, "Sx") end
    if absolute >= 1e18 then return fmt(1e18, "Qi") end
    if absolute >= 1e15 then return fmt(1e15, "Qa") end
    if absolute >= 1e12 then return fmt(1e12, "T") end
    if absolute >= 1e9 then return fmt(1e9, "B") end
    if absolute >= 1e6 then return fmt(1e6, "M") end
    if absolute >= 1e3 then return fmt(1e3, "K") end
    return number % 1 == 0 and string.format("%.0f", number) or tostring(number)
end

local function tableCount(tbl)
    local count = 0
    if type(tbl) == "table" then
        for _ in pairs(tbl) do count += 1 end
    end
    return count
end

-- ============================================================
-- AliceHUB persistent settings
-- ============================================================
local SETTINGS_FOLDER = "AliceHUB"
local SETTINGS_FILE = SETTINGS_FOLDER .. "/AnimeDice.json"

local defaults = {
    AD_FastRoll = false,
    AD_ServerAutoRoll = false,
    AD_RollDelay = 0.25,
    AD_RollBurst = 3,
    AD_AutoBuyDice = false,
    AD_AutoEquipDice = false,
    AD_AutoUpgrade = false,
    AD_AutoRebirth = false,
    AD_StopRebirth = 0,
    AD_AutoEquipUnits = false,
    AD_AutoCollect = false,
    AD_AutoLevelSlots = false,
    AD_RerollDelay = 0.5,
    AD_AutoTrait = false,
    AD_AutoGrade = false,
    AD_SmartSell = false,
    AD_SellMode = "Selected Rarities",
    AD_SellDelay = 4,
    AD_ProtectHugeTitanic = true,
    AD_ProtectPlotTower = true,
    AD_KeepMutation = "None",
    AD_KeepTrait = "None",
    AD_KeepGrade = "None",
    AD_SellRarities = {Common = true, Uncommon = true, Rare = true},

    AD_AutoFavorite = false,
    AD_AutoUnfavorite = false,
    AD_FavoriteScanDelay = 0.50,
    AD_FavoriteMatchMode = "Any",
    AD_FavoriteRarities = {Exclusive = true, ["Secret I"] = true, ["Secret II"] = true},
    AD_FavoriteMinChance = "0",
    AD_FavoriteMinTrait = "None",
    AD_FavoriteMinGrade = "None",
    AD_FavoriteMinMutation = "None",
    AD_FavoriteHugeTitanic = true,
    AD_FavoriteLimited = true,
    AD_FavoritePlotTower = false,
    AD_ProtectFavoriteMatches = true,
    AD_FavoriteSafetyDisableNativeSell = true,
    AD_AutoFuse = false,
    AD_FuseMinChance = "",
    AD_FuseMaxChance = "",
    AD_FuseMaxIncome = "",
    AD_Tower = "Cursed Tower",
    AD_TowerTeamSlot = 1,
    AD_TowerTeamUnit = "Auto / First Unit",
    AD_TowerDelay = 0.8,
    AD_AutoTower = false,
    AD_TowerEquipBest = true,
    AD_TowerRestart = true,
    AD_TowerCycle = false,
    AD_RotationMaps = {
        ["Jujutsu Tower"] = true,
        ["Hidden Leaf Tower"] = true,
        ["Pirate Tower"] = true,
        ["Infinity Tower"] = true,
        ["Dragon Tower"] = true,
        ["Slayer Tower"] = true,
        ["Cursed Tower"] = true,
        ["Fire Tower"] = true,
    },
    AD_RunsPerMap = 1,
    AD_SkipUnavailableMaps = true,
    AD_StopAtFloor = 0,
    AD_AutoDaily = true,
    AD_AutoGroup = true,
    AD_AutoOffline = true,
    AD_AutoQuestClaim = false,
    AD_AutoQuestBuy = false,
    AD_QuestBuyItem = "Trait Reroll",
    AD_AutoUseSpin = false,
    AD_SpinType = "Lucky Spin",
    AD_AutoSpinMode = "Selected",
    AD_WeatherNotify = true,
    AD_WeatherWebhook = false,
    AD_WeatherWebhookTargets = {["Luck Event"] = true, ["Cash Event"] = true, ["Roll Speed Event"] = true},
    AD_AutoSpinWeather = false,
    AD_WeatherSpinTargets = {["Luck Event"] = true},
    AD_AutoUseBoost = false,
    AD_AutoBoostWeather = false,
    AD_WeatherBoostTargets = {["Luck Event"] = true, ["Cash Event"] = true, ["Roll Speed Event"] = true},
    AD_BoostType = "Luck III",
    AD_AutoTutorialAdvance = false,
    AD_ServerAutoSellThreshold = "0",
    AD_RedeemCode = "",
    AD_TradePlayer = "No Player",
    AD_TradeSearch = "",
    AD_TradeKind = "All",
    AD_TradeItem = "No Item",
    AD_TradeAmount = 1,
    AD_InventoryPlotSlot = 1,
    AD_TradeRequestsEnabled = true,
    AD_AutoAcceptTrade = false,
    AD_AutoAcceptOnlySelected = true,
    AD_TradeReceiverMode = false,
    AD_TradeAutoRefresh = true,
    AD_AntiAFK = true,
    AD_AntiAFKInterval = 45,
    AD_WhiteScreen = false,
    AD_WhiteScreenDisable3D = true,
    AD_WhiteScreenHideUI = true,
    AD_WhiteScreenFPSCap = 10,
    AD_BoostFPS = false,
    AD_UltraPerformance = false,
    AD_WebhookEnabled = false,
    AD_WebhookURL = "",
    AD_WebhookInterval = 300,
    AD_InventoryWebhookEnabled = false,
    AD_InventoryWebhookInterval = 600,
    AD_InventoryWebhookUnits = true,
    AD_InventoryWebhookItems = true,
    AD_InventoryWebhookStats = true,
    AD_AutoReconnect = true,
    AD_AutoRejoin = false,
    AD_AutoRejoinMinutes = 30,
}

local State = {}
for key, value in pairs(defaults) do
    if type(value) == "table" then
        local copy = {}
        for k, v in pairs(value) do copy[k] = v end
        State[key] = copy
    else
        State[key] = value
    end
end

local function loadState()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    local okExists, exists = pcall(isfile, SETTINGS_FILE)
    if not okExists or not exists then return end
    local okRead, content = pcall(readfile, SETTINGS_FILE)
    if not okRead or type(content) ~= "string" then return end
    local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    if not okDecode or type(decoded) ~= "table" then return end
    for key, value in pairs(decoded) do
        if defaults[key] ~= nil then State[key] = value end
    end
end

local function saveState()
    if type(writefile) ~= "function" then return end
    pcall(function()
        if type(makefolder) == "function" then
            if type(isfolder) ~= "function" or not isfolder(SETTINGS_FOLDER) then
                makefolder(SETTINGS_FOLDER)
            end
        end
        writefile(SETTINGS_FILE, HttpService:JSONEncode(State))
    end)
end

loadState()

-- ============================================================
-- AliceHUB logo

-- ============================================================
-- ============================================================
-- AliceHUB versioned logo cache
-- Pattern: version endpoint -> versioned local PNG -> getcustomasset.
-- Refresh is background-only so the main UI/game payload never waits for the logo.
local ALICE_LOGO_API = "https://alicehub-api.shirokanaerus.workers.dev"
local ALICE_LOGO_ROOT = "AliceHUB/assets"
local ALICE_LOGO_VERSION_FILE = ALICE_LOGO_ROOT .. "/logo.ver"
local ALICE_LOGO_ASSET = nil
local ALICE_LOGO_FILE = nil
local __aliceLogoTargets = {}

local function __aliceGetCustomAsset()
    return getcustomasset
        or getsynasset
        or (syn and syn.getcustomasset)
        or getcustomassetfunc
end

local function __aliceCleanLogoVersion(value)
    local version = tostring(value or ""):gsub("%s+", "")
    if version == "" or #version > 64 then return nil end
    if not version:match("^[%w%._%-]+$") then return nil end
    return version
end

local function __aliceEnsureFolder(path)
    if type(makefolder) ~= "function" then return end
    local exists = false
    if type(isfolder) == "function" then
        pcall(function() exists = isfolder(path) end)
    end
    if not exists then pcall(makefolder, path) end
end

local function __aliceFileExists(path)
    if type(isfile) ~= "function" then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function __aliceReadFile(path)
    if type(readfile) ~= "function" or not __aliceFileExists(path) then return nil end
    local ok, value = pcall(readfile, path)
    return ok and value or nil
end

local function __aliceLogoPath(version)
    return ALICE_LOGO_ROOT .. "/" .. tostring(version) .. "/logo.png"
end

local function __aliceResolveLocalAsset(path)
    local getAsset = __aliceGetCustomAsset()
    if type(getAsset) ~= "function" or not __aliceFileExists(path) then return nil end
    local ok, asset = pcall(getAsset, path)
    if ok and type(asset) == "string" and asset ~= "" then return asset end
    return nil
end

local function __aliceApplyLogoTarget(imageObject, fallbackObject)
    local asset = ALICE_LOGO_ASSET
    if imageObject and imageObject.Parent then
        pcall(function()
            imageObject.Image = asset or ""
            imageObject.ImageTransparency = asset and 0 or 1
        end)
    end
    if fallbackObject and fallbackObject.Parent then
        pcall(function()
            fallbackObject.Visible = not (asset ~= nil)
        end)
    end
end

local function __aliceRegisterLogoTarget(imageObject, fallbackObject)
    __aliceLogoTargets[#__aliceLogoTargets + 1] = {
        image = imageObject,
        fallback = fallbackObject,
    }
    __aliceApplyLogoTarget(imageObject, fallbackObject)
end

local function __alicePublishLogo(asset, path, version)
    if type(asset) ~= "string" or asset == "" then return end
    ALICE_LOGO_ASSET = asset
    ALICE_LOGO_FILE = path

    local env = (getgenv and getgenv()) or _G
    env.AliceHUBLogoAsset = asset
    env.AliceHUBBrandLogoAsset = asset
    env.AliceHUBLogoPath = path
    env.AliceHUBLogoVersion = version

    for index = #__aliceLogoTargets, 1, -1 do
        local target = __aliceLogoTargets[index]
        if not target.image or not target.image.Parent then
            table.remove(__aliceLogoTargets, index)
        else
            __aliceApplyLogoTarget(target.image, target.fallback)
        end
    end
end

-- Last cached version loads instantly; no HTTP is performed on the startup path.
do
    local localVersion = __aliceCleanLogoVersion(__aliceReadFile(ALICE_LOGO_VERSION_FILE))
    if localVersion then
        local path = __aliceLogoPath(localVersion)
        local asset = __aliceResolveLocalAsset(path)
        if asset then __alicePublishLogo(asset, path, localVersion) end
    end
end

-- Server refresh runs independently. First run uses "A" until the PNG is ready.
task.spawn(function()
    local getAsset = __aliceGetCustomAsset()
    if type(getAsset) ~= "function" or type(writefile) ~= "function" then return end

    __aliceEnsureFolder("AliceHUB")
    __aliceEnsureFolder(ALICE_LOGO_ROOT)

    local okVersion, versionBody = pcall(function()
        return game:HttpGet(ALICE_LOGO_API .. "/alicehub-logo.version?t=" .. tostring(os.time()))
    end)
    if not okVersion then return end

    local version = __aliceCleanLogoVersion(versionBody)
    if not version then return end

    local versionFolder = ALICE_LOGO_ROOT .. "/" .. version
    local logoPath = __aliceLogoPath(version)
    __aliceEnsureFolder(versionFolder)

    if not __aliceFileExists(logoPath) then
        local okLogo, png = pcall(function()
            return game:HttpGet(ALICE_LOGO_API .. "/alicehub-logo.png?v=" .. version)
        end)
        if not okLogo or type(png) ~= "string" or #png < 512 then return end
        if png:sub(1, 4) ~= "\137PNG" then return end
        if not pcall(writefile, logoPath, png) then return end
    end

    local asset = __aliceResolveLocalAsset(logoPath)
    if not asset then return end

    pcall(writefile, ALICE_LOGO_VERSION_FILE, version)
    __alicePublishLogo(asset, logoPath, version)
end)

local function __aliceHubHeaderLogo()
    return ALICE_LOGO_ASSET
end

local ALICE_HEADER_LOGO_ASSET = __aliceHubHeaderLogo()

-- ============================================================
-- Logo awal

-- ============================================================
local MainWindow = nil
local MainWindowVisible = true
local Library = nil

local function getAliceGuiRoot()
    if type(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then return root end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function cleanupLogo()
    local roots = {CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}
    if type(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then table.insert(roots, 1, root) end
    end
    for _, root in ipairs(roots) do
        if root then
            for _, name in ipairs({"AliceHUB_AnimeDice_LogoButton", "AliceHUBLogoButton"}) do
                local old = root:FindFirstChild(name)
                if old then pcall(function() old:Destroy() end) end
            end
        end
    end
end

local function setMainWindowVisible(value)
    local visible = value == true
    MainWindowVisible = visible

    if MainWindow and MainWindow._main then
        pcall(function()
            MainWindow._main.Visible = visible
        end)
    end

    if MainWindow then
        pcall(function()
            if visible then
                if type(MainWindow.Show) == "function" then MainWindow:Show()
                elseif type(MainWindow.SetVisible) == "function" then MainWindow:SetVisible(true) end
            else
                if type(MainWindow.Hide) == "function" then MainWindow:Hide()
                elseif type(MainWindow.SetVisible) == "function" then MainWindow:SetVisible(false) end
            end
        end)
    end

    pcall(function()
        if Library and Library.WindowContainer then
            Library.WindowContainer.Visible = visible
            Library.Toggled = visible
        end
    end)
end

local function toggleMainWindow()
    local actual = MainWindowVisible
    if MainWindow and MainWindow._main then
        pcall(function() actual = MainWindow._main.Visible == true end)
    end
    setMainWindowVisible(not actual)
end

cleanupLogo()
local LogoGui = Instance.new("ScreenGui")
LogoGui.Name = "AliceHUBLogoButton"
LogoGui.ResetOnSpawn = false
LogoGui.IgnoreGuiInset = true
LogoGui.DisplayOrder = 2147483000
LogoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() LogoGui.Parent = getAliceGuiRoot() end)
if not LogoGui.Parent then
    pcall(function() LogoGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

local Logo = Instance.new("ImageButton")
Logo.Name = "AliceHUBLogo"
Logo.Size = UDim2.fromOffset(72, 72)
Logo.Position = UDim2.new(0, 10, 0.5, -36)
Logo.BackgroundColor3 = Color3.fromRGB(20, 12, 16)
Logo.BackgroundTransparency = 0.08
Logo.BorderSizePixel = 0
Logo.AutoButtonColor = false
Logo.Image = ALICE_HEADER_LOGO_ASSET or ""
Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
Logo.ScaleType = Enum.ScaleType.Crop
Logo.ZIndex = 10
Logo.Parent = LogoGui

-- Never show Roblox's broken-image placeholder.
Logo.ImageTransparency = ALICE_HEADER_LOGO_ASSET and 0 or 1
local LogoFallback = Instance.new("TextLabel")
LogoFallback.Name = "Fallback"
LogoFallback.BackgroundTransparency = 1
LogoFallback.Size = UDim2.fromScale(1, 1)
LogoFallback.Font = Enum.Font.Code
LogoFallback.Text = "A"
LogoFallback.TextColor3 = Color3.fromRGB(214, 77, 112)
LogoFallback.TextSize = 32
LogoFallback.TextXAlignment = Enum.TextXAlignment.Center
LogoFallback.TextYAlignment = Enum.TextYAlignment.Center
LogoFallback.ZIndex = 11
LogoFallback.Visible = not (ALICE_HEADER_LOGO_ASSET ~= nil)
LogoFallback.Parent = Logo
__aliceRegisterLogoTarget(Logo, LogoFallback)

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 16)
LogoCorner.Parent = Logo

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Name = "RubyOutline"
LogoStroke.Color = Color3.fromRGB(181, 48, 83)
LogoStroke.Thickness = 2
LogoStroke.Transparency = 0.12
LogoStroke.Parent = Logo

if ALICE_HEADER_LOGO_ASSET then
    Logo.ImageTransparency = 0
    LogoFallback.Visible = false
end

local UserInputService = game:GetService("UserInputService")
local logoDragging = false
local logoDragged = false
local logoDragInput, logoDragStart, logoStartPosition

Logo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoDragged = false
        logoDragStart = input.Position
        logoStartPosition = Logo.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then logoDragging = false end
        end)
    end
end)

Logo.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        logoDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == logoDragInput and logoDragging and logoDragStart and logoStartPosition then
        local delta = input.Position - logoDragStart
        if math.abs(delta.X) > 20 or math.abs(delta.Y) > 20 then logoDragged = true end
        Logo.Position = UDim2.new(
            logoStartPosition.X.Scale, logoStartPosition.X.Offset + delta.X,
            logoStartPosition.Y.Scale, logoStartPosition.Y.Offset + delta.Y
        )
    end
end)

Logo.Activated:Connect(function()
    if logoDragged then logoDragged = false return end
    toggleMainWindow()
end)

-- ============================================================
-- AliceHUB UI
-- ============================================================
-- ============================================================
-- AliceHUB UI library

-- ============================================================
local function buildAliceNativeLibrary()
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local PlayersSvc = game:GetService("Players")
    local LP = PlayersSvc.LocalPlayer

    local L = {
        Toggles = {},
        Options = {},
        Scheme = {
            BackgroundColor = Color3.fromRGB(11, 9, 11),
            MainColor = Color3.fromRGB(24, 15, 19),
            AccentColor = Color3.fromRGB(181, 48, 83),
            OutlineColor = Color3.fromRGB(63, 34, 44),
            FontColor = Color3.fromRGB(242, 236, 239),
            RedColor = Color3.fromRGB(202, 55, 79),
            DestructiveColor = Color3.fromRGB(132, 30, 49),
            DarkColor = Color3.fromRGB(7, 6, 7),
            WhiteColor = Color3.fromRGB(242, 236, 239),
        },
        Toggled = true,
        _native = true,
    }

    -- Menu utama dipasang ke PlayerGui.

    local function rootGui()
        return LP:WaitForChild("PlayerGui")
    end

    local root = rootGui()
    local old = root:FindFirstChild("AliceHUB_AnimeDice_NativeUI")
    if old then pcall(function() old:Destroy() end) end

    local screen = Instance.new("ScreenGui")
    screen.Name = "AliceHUB_AnimeDice_NativeUI"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.Enabled = true
    screen.DisplayOrder = 999999
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local okParent = pcall(function()
        screen.Parent = root
    end)
    if not okParent or not screen.Parent then
        error("AliceHUB: failed to parent native UI into PlayerGui")
    end

    L.ScreenGui = screen

    local function corner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 4)
        c.Parent = parent
        return c
    end

    local function stroke(parent, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or L.Scheme.OutlineColor
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.Parent = parent
        return s
    end

    local function padding(parent, l, r, t, b)
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, l or 0)
        p.PaddingRight = UDim.new(0, r or 0)
        p.PaddingTop = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.Parent = parent
        return p
    end

    local function newText(parent, text, size, bold)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Text = tostring(text or "")
        label.TextColor3 = L.Scheme.FontColor
        label.TextSize = size or 13
        label.Font = bold and Enum.Font.Code or Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.RichText = false
        label.Parent = parent
        return label
    end

    local function mkOption(initial)
        local option = {Value = initial, _callbacks = {}}
        function option:OnChanged(fn)
            if type(fn) == "function" then self._callbacks[#self._callbacks + 1] = fn end
            return self
        end
        function option:_emit()
            for _, fn in ipairs(self._callbacks) do pcall(fn, self.Value) end
        end
        function option:SetValue(value)
            self.Value = value
            if self._render then pcall(self._render, value) end
            self:_emit()
        end
        function option:SetAndFire(value) self:SetValue(value) end
        return option
    end

    local currentPopup
    local currentPopupOwner
    local currentPopupOverlay

    local function closePopup()
        if currentPopup and currentPopup.Parent then
            currentPopup:Destroy()
        end
        if currentPopupOverlay and currentPopupOverlay.Parent then
            currentPopupOverlay:Destroy()
        end
        currentPopup = nil
        currentPopupOwner = nil
        currentPopupOverlay = nil
    end

    function L:Notify(cfg)
        cfg = cfg or {}
        local toast = Instance.new("Frame")
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.Position = UDim2.new(1, -16, 0, 22)
        toast.Size = UDim2.fromOffset(290, 68)
        toast.BackgroundColor3 = L.Scheme.MainColor
        toast.BorderSizePixel = 0
        toast.ZIndex = 1000
        toast.Parent = screen
        corner(toast, 7)
        stroke(toast, L.Scheme.AccentColor, 1.5, 0.15)
        local title = newText(toast, cfg.Title or "AliceHUB", 15, true)
        title.Position = UDim2.fromOffset(12, 7)
        title.Size = UDim2.new(1, -24, 0, 22)
        title.TextColor3 = L.Scheme.AccentColor
        local body = newText(toast, cfg.Description or cfg.Content or cfg.Body or "", 12, false)
        body.Position = UDim2.fromOffset(12, 29)
        body.Size = UDim2.new(1, -24, 0, 32)
        body.TextWrapped = true
        task.delay(tonumber(cfg.Time or cfg.Duration) or 3, function()
            if toast and toast.Parent then pcall(function() toast:Destroy() end) end
        end)
        return toast
    end

    function L:Toggle(force)
        if force == nil then L.Toggled = not L.Toggled else L.Toggled = force == true end
        if L.WindowContainer then L.WindowContainer.Visible = L.Toggled end
    end

    function L:CreateWindow(cfg)
        cfg = cfg or {}
        local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        local target = cfg.Size or UDim2.fromOffset(760, 540)
        local targetW = math.min(target.X.Offset > 0 and target.X.Offset or 760, math.max(560, viewport.X - 70))
        local targetH = math.min(target.Y.Offset > 0 and target.Y.Offset or 540, math.max(400, viewport.Y - 60))

        local main = Instance.new("Frame")
        main.Name = "AliceHUBWindow"
        main.AnchorPoint = Vector2.new(0.5, 0.5)
        main.Position = UDim2.fromScale(0.5, 0.5)
        main.Size = UDim2.fromOffset(targetW, targetH)
        main.BackgroundColor3 = L.Scheme.BackgroundColor
        main.BorderSizePixel = 0
        main.Visible = true
        main.ZIndex = 5
        main.Parent = screen
        corner(main, cfg.CornerRadius or 4)
        stroke(main, L.Scheme.OutlineColor, 1, 0.05)
        L.WindowContainer = main

        local top = Instance.new("Frame")
        top.Name = "Topbar"
        top.Size = UDim2.new(1, 0, 0, 52)
        top.BackgroundColor3 = L.Scheme.MainColor
        top.BorderSizePixel = 0
        top.Parent = main
        corner(top, 4)

        local iconHolder = Instance.new("Frame")
        iconHolder.Position = UDim2.fromOffset(12, 9)
        iconHolder.Size = UDim2.fromOffset(34, 34)
        iconHolder.BackgroundColor3 = Color3.fromRGB(20, 12, 16)
        iconHolder.BorderSizePixel = 0
        iconHolder.Parent = top
        corner(iconHolder, 8)
        stroke(iconHolder, L.Scheme.AccentColor, 1.2, 0.2)

        local iconFallback = newText(iconHolder, "A", 18, true)
        iconFallback.Size = UDim2.fromScale(1, 1)
        iconFallback.TextXAlignment = Enum.TextXAlignment.Center
        iconFallback.TextColor3 = L.Scheme.AccentColor

        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromScale(1, 1)
        icon.Image = ALICE_HEADER_LOGO_ASSET or ""
        icon.ImageTransparency = ALICE_HEADER_LOGO_ASSET and 0 or 1
        icon.ScaleType = Enum.ScaleType.Crop
        icon.Parent = iconHolder
        __aliceRegisterLogoTarget(icon, iconFallback)
        corner(icon, 8)
        iconFallback.Visible = not (ALICE_HEADER_LOGO_ASSET ~= nil)
        if ALICE_HEADER_LOGO_ASSET then
            icon.ImageTransparency = 0
            iconFallback.Visible = false
        end

        local title = newText(top, (cfg.Title or "AliceHUB") .. " ", 18, true)
        title.Name = "AliceHUBMainTitle"
        title.Position = UDim2.fromOffset(56, 6)
        title.Size = UDim2.new(1, -118, 0, 23)
        title.TextColor3 = L.Scheme.FontColor

        local subtitle = newText(top, "Anime Dice", 11, false)
        subtitle.Name = "AliceHUBSubtitle"
        subtitle.Position = UDim2.fromOffset(56, 28)
        subtitle.Size = UDim2.new(1, -118, 0, 17)
        subtitle.TextColor3 = Color3.fromRGB(180, 126, 143)
        subtitle.TextTransparency = 0.08

        local hide = Instance.new("TextButton")
        hide.AnchorPoint = Vector2.new(1, 0.5)
        hide.Position = UDim2.new(1, -12, 0.5, 0)
        hide.Size = UDim2.fromOffset(32, 30)
        hide.BackgroundColor3 = Color3.fromRGB(33, 20, 25)
        hide.BorderSizePixel = 0
        hide.Text = "—"
        hide.TextColor3 = L.Scheme.FontColor
        hide.TextSize = 18
        hide.Font = Enum.Font.Code
        hide.Parent = top
        corner(hide, 5)
        local hideBusy = false
        local function hideNow()
            if hideBusy then return end
            hideBusy = true
            main.Visible = false
            L.Toggled = false
            MainWindowVisible = false
            task.delay(0.12, function() hideBusy = false end)
        end
        hide.Activated:Connect(hideNow)
        hide.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                hideNow()
            end
        end)

        local tabRail = Instance.new("ScrollingFrame")
        tabRail.Position = UDim2.fromOffset(0, 52)
        tabRail.Size = UDim2.new(0, 142, 1, -82)
        tabRail.BackgroundColor3 = Color3.fromRGB(15, 11, 13)
        tabRail.BorderSizePixel = 0
        tabRail.ScrollBarThickness = 3
        tabRail.ScrollBarImageColor3 = L.Scheme.AccentColor
        tabRail.ScrollingDirection = Enum.ScrollingDirection.Y
        tabRail.AutomaticCanvasSize = Enum.AutomaticSize.None
        tabRail.CanvasSize = UDim2.new()
        tabRail.ScrollingEnabled = true
        tabRail.Active = true
        tabRail.Parent = main
        padding(tabRail, 8, 8, 10, 8)
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Padding = UDim.new(0, 6)
        tabLayout.Parent = tabRail

        local function updateTabRailCanvas()
            tabRail.CanvasSize = UDim2.fromOffset(0, math.max(0, tabLayout.AbsoluteContentSize.Y + 18))
        end
        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabRailCanvas)
        task.defer(updateTabRailCanvas)

        local body = Instance.new("Frame")
        body.Position = UDim2.fromOffset(142, 52)
        body.Size = UDim2.new(1, -142, 1, -82)
        body.BackgroundTransparency = 1
        body.Parent = main

        local footer = Instance.new("Frame")
        footer.AnchorPoint = Vector2.new(0, 1)
        footer.Position = UDim2.new(0, 0, 1, 0)
        footer.Size = UDim2.new(1, 0, 0, 30)
        footer.BackgroundColor3 = L.Scheme.MainColor
        footer.BorderSizePixel = 0
        footer.Parent = main
        local footText = newText(footer, "AliceHUB   |   Anime Dice", 11, false)
        footText.Position = UDim2.fromOffset(12, 0)
        footText.Size = UDim2.new(1, -24, 1, 0)
        footText.TextColor3 = Color3.fromRGB(180, 126, 143)

        -- drag window from topbar
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging and dragStart and startPos then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local window = {_main = main, _tabs = {}, _active = nil}
        function window:Show()
            L.Toggled = true
            main.Visible = true
            if L.WindowContainer then L.WindowContainer.Visible = true end
        end
        function window:Hide()
            L.Toggled = false
            main.Visible = false
            if L.WindowContainer then L.WindowContainer.Visible = false end
        end
        function window:SetVisible(v)
            if v then self:Show() else self:Hide() end
        end

        local function activate(tabObj)
            closePopup()
            if window._active == tabObj then return end
            for _, t in ipairs(window._tabs) do
                t._content.Visible = false
                t._button.BackgroundColor3 = Color3.fromRGB(21, 15, 18)
                t._button.TextColor3 = Color3.fromRGB(190, 180, 185)
            end
            tabObj._content.Visible = true
            tabObj._button.BackgroundColor3 = Color3.fromRGB(49, 23, 32)
            tabObj._button.TextColor3 = L.Scheme.FontColor
            window._active = tabObj
        end

        local function makeGroup(column, groupTitle)
            local group = Instance.new("Frame")
            group.Size = UDim2.new(1, -2, 0, 0)
            group.AutomaticSize = Enum.AutomaticSize.Y
            group.BackgroundColor3 = L.Scheme.MainColor
            group.BorderSizePixel = 0
            group.Parent = column
            corner(group, 5)
            stroke(group, L.Scheme.OutlineColor, 1, 0.12)
            padding(group, 9, 9, 8, 9)
            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 6)
            layout.Parent = group

            local header = newText(group, groupTitle or "Section", 13, true)
            header.Size = UDim2.new(1, 0, 0, 22)
            header.TextColor3 = Color3.fromRGB(218, 178, 190)

            local G = {}
            function G:AddLabel(text, wrap)
                local label = newText(group, text, 12, false)
                label.Size = UDim2.new(1, 0, 0, wrap and 38 or 24)
                label.TextWrapped = wrap == true
                label.TextYAlignment = Enum.TextYAlignment.Top
                local wrapper = {_label = label}
                function wrapper:SetText(value)
                    if label and label.Parent then label.Text = tostring(value or "") end
                end
                return wrapper
            end

            function G:AddButton(conf)
                conf = conf or {}
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 30)
                b.BackgroundColor3 = Color3.fromRGB(35, 23, 28)
                b.BorderSizePixel = 0
                b.Text = tostring(conf.Text or conf.Title or "Button")
                b.TextColor3 = L.Scheme.FontColor
                b.TextSize = 12
                b.Font = Enum.Font.Code
                b.Parent = group
                corner(b, 4)
                stroke(b, Color3.fromRGB(78, 41, 53), 1, 0.25)
                b.Activated:Connect(function()
                    local fn = conf.Func or conf.Callback
                    if type(fn) ~= "function" then return end

                    local ok, err = xpcall(fn, function(reason)
                        local message = tostring(reason)
                        pcall(function()
                            if debug and type(debug.traceback) == "function" then
                                message = debug.traceback(message, 2)
                            end
                        end)
                        return message
                    end)

                    if not ok then
                        warn("[AliceHUB/Button] " .. tostring(err))
                        pcall(function()
                            L:Notify({
                                Title = "AliceHUB · Button Error",
                                Description = tostring(err):sub(1, 240),
                                Time = 7,
                            })
                        end)
                    end
                end)
                return b
            end

            function G:AddToggle(id, conf)
                conf = conf or {}
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Text = ""
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 12, false)
                txt.Position = UDim2.fromOffset(8, 0)
                txt.Size = UDim2.new(1, -46, 1, 0)
                local box = Instance.new("Frame")
                box.AnchorPoint = Vector2.new(1, 0.5)
                box.Position = UDim2.new(1, -7, 0.5, 0)
                box.Size = UDim2.fromOffset(22, 18)
                box.BackgroundColor3 = Color3.fromRGB(45, 31, 37)
                box.BorderSizePixel = 0
                box.Parent = row
                corner(box, 9)
                local dot = Instance.new("Frame")
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Size = UDim2.fromOffset(12, 12)
                dot.BorderSizePixel = 0
                dot.Parent = box
                corner(dot, 6)
                local opt = mkOption(conf.Default == true)
                local function render(v)
                    box.BackgroundColor3 = v and Color3.fromRGB(91, 28, 48) or Color3.fromRGB(45, 31, 37)
                    dot.BackgroundColor3 = v and L.Scheme.AccentColor or Color3.fromRGB(118, 103, 110)
                    dot.Position = v and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
                end
                opt._render = render; render(opt.Value)
                L.Toggles[id] = opt
                row.Activated:Connect(function() opt:SetValue(not opt.Value) end)
                return opt
            end

            function G:AddInput(id, conf)
                conf = conf or {}

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 52)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Parent = group
                corner(row, 4)

                local txt = newText(row, conf.Text or id, 11, false)
                txt.Position = UDim2.fromOffset(8, 2)
                txt.Size = UDim2.new(1, -16, 0, 20)

                local box = Instance.new("TextBox")
                box.Position = UDim2.fromOffset(8, 25)
                box.Size = UDim2.new(1, -16, 0, 21)
                box.BackgroundColor3 = Color3.fromRGB(35, 23, 28)
                box.BorderSizePixel = 0
                box.TextColor3 = L.Scheme.FontColor
                box.PlaceholderColor3 = Color3.fromRGB(128, 108, 116)
                box.PlaceholderText = tostring(conf.Placeholder or "")
                box.Text = tostring(conf.Default or "")
                box.TextSize = 11
                box.Font = Enum.Font.Code
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = row
                corner(box, 3)
                padding(box, 6, 6, 0, 0)

                local opt = mkOption(tostring(conf.Default or ""))
                local syncingText = false

                local function render(v)
                    local value = tostring(v or "")
                    if box.Text ~= value then
                        syncingText = true
                        box.Text = value
                        syncingText = false
                    end
                end

                opt._render = render
                render(opt.Value)
                L.Options[id] = opt

                -- Keep option/state synced immediately while typing or pasting.
                -- This fixes mobile where "Send Test" could run before FocusLost.
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    if syncingText then return end
                    opt:SetValue(box.Text)
                end)

                box.FocusLost:Connect(function()
                    opt:SetValue(box.Text)
                end)

                return opt
            end

            function G:AddSlider(id, conf)
                conf = conf or {}
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 48)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 12, false)
                txt.Position = UDim2.fromOffset(8, 2)
                txt.Size = UDim2.new(0.62, 0, 0, 21)
                local valueText = newText(row, "", 11, false)
                valueText.AnchorPoint = Vector2.new(1, 0)
                valueText.Position = UDim2.new(1, -8, 0, 2)
                valueText.Size = UDim2.new(0.35, 0, 0, 21)
                valueText.TextXAlignment = Enum.TextXAlignment.Right
                local bar = Instance.new("TextButton")
                bar.Position = UDim2.fromOffset(8, 29)
                bar.Size = UDim2.new(1, -16, 0, 9)
                bar.BackgroundColor3 = Color3.fromRGB(52, 34, 41)
                bar.BorderSizePixel = 0
                bar.Text = ""
                bar.Parent = row
                corner(bar, 5)
                local fill = Instance.new("Frame")
                fill.Size = UDim2.fromScale(0, 1)
                fill.BackgroundColor3 = L.Scheme.AccentColor
                fill.BorderSizePixel = 0
                fill.Parent = bar
                corner(fill, 5)
                local minV, maxV = tonumber(conf.Min) or 0, tonumber(conf.Max) or 100
                local rounding = tonumber(conf.Rounding) or 0
                local suffix = tostring(conf.Suffix or "")
                local opt = mkOption(tonumber(conf.Default) or minV)
                local function normalize(v)
                    v = math.clamp(tonumber(v) or minV, minV, maxV)
                    local p = 10 ^ rounding
                    return math.floor(v * p + 0.5) / p
                end
                local function render(v)
                    v = normalize(v)
                    local alpha = maxV == minV and 0 or (v - minV) / (maxV - minV)
                    fill.Size = UDim2.fromScale(alpha, 1)
                    valueText.Text = tostring(v) .. suffix
                end
                local oldSet = opt.SetValue
                function opt:SetValue(v) oldSet(self, normalize(v)) end
                opt._render = render; render(opt.Value)
                L.Options[id] = opt
                local function setFromX(x)
                    local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                    opt:SetValue(minV + (maxV - minV) * alpha)
                end
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
                end)
                bar.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input.UserInputType == Enum.UserInputType.Touch then setFromX(input.Position.X) end
                    end
                end)
                return opt
            end

            function G:AddDropdown(id, conf)
                conf = conf or {}
                local values = conf.Values or {}
                local multi = conf.Multi == true
                local initial = conf.Default
                if multi and type(initial) ~= "table" then initial = {} end
                if not multi and initial == nil then initial = values[1] end
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, 0, 0, 34)
                row.BackgroundColor3 = Color3.fromRGB(27, 18, 22)
                row.BorderSizePixel = 0
                row.Text = ""
                row.Parent = group
                corner(row, 4)
                local txt = newText(row, conf.Text or id, 11, false)
                txt.Position = UDim2.fromOffset(8, 0)
                txt.Size = UDim2.new(0.43, -4, 1, 0)
                local selected = newText(row, "", 11, false)
                selected.Position = UDim2.new(0.43, 2, 0, 0)
                selected.Size = UDim2.new(0.57, -28, 1, 0)
                selected.TextXAlignment = Enum.TextXAlignment.Right
                selected.TextColor3 = Color3.fromRGB(218, 178, 190)
                local arrow = newText(row, "v", 11, true)
                arrow.AnchorPoint = Vector2.new(1, 0)
                arrow.Position = UDim2.new(1, -8, 0, 0)
                arrow.Size = UDim2.fromOffset(16, 34)
                arrow.TextXAlignment = Enum.TextXAlignment.Center
                local opt = mkOption(initial)
                opt.Values = values
                local function summary(v)
                    if multi then
                        local names = {}
                        for _, name in ipairs(opt.Values or {}) do if type(v) == "table" and v[name] == true then names[#names+1] = name end end
                        return #names == 0 and "None" or (#names <= 2 and table.concat(names, ", ") or tostring(#names) .. " selected")
                    end
                    return tostring(v or "None")
                end
                local function render(v) selected.Text = summary(v) end
                opt._render = render; render(opt.Value)
                function opt:SetValues(newValues)
                    self.Values = newValues or {}
                    if not multi and self.Value ~= nil then
                        local ok = false
                        for _, v in ipairs(self.Values) do if v == self.Value then ok = true break end end
                        if not ok and self.Values[1] then self:SetValue(self.Values[1]) end
                    end
                    render(self.Value)
                end
                L.Options[id] = opt
                row.Activated:Connect(function()
                    -- Tapping the same dropdown again now closes it.
                    if currentPopup and currentPopupOwner == row then
                        closePopup()
                        return
                    end

                    closePopup()

                    -- Transparent click-catcher behind the popup.
                    local overlay = Instance.new("TextButton")
                    overlay.Name = "AliceHUBPopupDismiss"
                    overlay.Size = UDim2.fromScale(1, 1)
                    overlay.BackgroundTransparency = 1
                    overlay.Text = ""
                    overlay.ZIndex = 898
                    overlay.Parent = screen
                    overlay.Activated:Connect(closePopup)

                    local popup = Instance.new("Frame")
                    popup.BackgroundColor3 = Color3.fromRGB(20, 14, 17)
                    popup.BorderSizePixel = 0
                    popup.ZIndex = 900
                    popup.Parent = screen
                    corner(popup, 5)
                    stroke(popup, L.Scheme.AccentColor, 1, 0.25)

                    local count = math.min(#(opt.Values or {}), 8)
                    local popupHeight = math.max(70, count * 30 + 42)
                    popup.Size = UDim2.fromOffset(
                        math.max(190, row.AbsoluteSize.X),
                        popupHeight
                    )

                    local abs = row.AbsolutePosition
                    local y = abs.Y + row.AbsoluteSize.Y + 2
                    if y + popupHeight > viewport.Y - 20 then
                        y = math.max(20, abs.Y - popupHeight - 2)
                    end
                    popup.Position = UDim2.fromOffset(abs.X, y)

                    local header = Instance.new("Frame")
                    header.Size = UDim2.new(1, 0, 0, 32)
                    header.BackgroundColor3 = Color3.fromRGB(31, 19, 24)
                    header.BorderSizePixel = 0
                    header.ZIndex = 903
                    header.Parent = popup
                    corner(header, 5)

                    local headerText = newText(header, tostring(conf.Text or "Select"), 11, true)
                    headerText.Position = UDim2.fromOffset(8, 0)
                    headerText.Size = UDim2.new(1, -44, 1, 0)
                    headerText.ZIndex = 904
                    headerText.TextColor3 = Color3.fromRGB(218, 178, 190)

                    local closeBtn = Instance.new("TextButton")
                    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
                    closeBtn.Position = UDim2.new(1, -6, 0.5, 0)
                    closeBtn.Size = UDim2.fromOffset(26, 24)
                    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 28, 44)
                    closeBtn.BorderSizePixel = 0
                    closeBtn.Text = "×"
                    closeBtn.TextColor3 = Color3.fromRGB(255, 238, 243)
                    closeBtn.TextSize = 17
                    closeBtn.Font = Enum.Font.Code
                    closeBtn.ZIndex = 905
                    closeBtn.Parent = header
                    corner(closeBtn, 4)
                    closeBtn.Activated:Connect(closePopup)

                    local scroll = Instance.new("ScrollingFrame")
                    scroll.Position = UDim2.fromOffset(5, 37)
                    scroll.Size = UDim2.new(1, -10, 1, -42)
                    scroll.BackgroundTransparency = 1
                    scroll.BorderSizePixel = 0
                    scroll.ScrollBarThickness = 3
                    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    scroll.CanvasSize = UDim2.new()
                    scroll.ZIndex = 901
                    scroll.Parent = popup

                    local lay = Instance.new("UIListLayout")
                    lay.Padding = UDim.new(0, 3)
                    lay.Parent = scroll

                    for _, name in ipairs(opt.Values or {}) do
                        local item = Instance.new("TextButton")
                        item.Size = UDim2.new(1, -2, 0, 27)
                        item.BorderSizePixel = 0
                        item.TextSize = 11
                        item.Font = Enum.Font.Code
                        item.ZIndex = 902
                        item.Parent = scroll
                        corner(item, 3)

                        local itemStroke = Instance.new("UIStroke")
                        itemStroke.Thickness = 1
                        itemStroke.Parent = item

                        local function itemIsSelected()
                            if multi then
                                return type(opt.Value) == "table" and opt.Value[name] == true
                            end
                            return opt.Value == name
                        end

                        local function renderItem()
                            local chosen = itemIsSelected()

                            item.BackgroundColor3 = chosen
                                and Color3.fromRGB(79, 27, 45)
                                or Color3.fromRGB(33, 22, 27)

                            item.TextColor3 = chosen
                                and Color3.fromRGB(255, 242, 247)
                                or Color3.fromRGB(205, 194, 199)

                            item.Text = (chosen and "✓  " or "   ") .. tostring(name)

                            itemStroke.Color = chosen
                                and L.Scheme.AccentColor
                                or L.Scheme.OutlineColor

                            itemStroke.Transparency = chosen and 0.05 or 0.55
                        end

                        renderItem()

                        item.Activated:Connect(function()
                            if multi then
                                local nextMap = {}
                                if type(opt.Value) == "table" then
                                    for k, v in pairs(opt.Value) do nextMap[k] = v end
                                end
                                nextMap[name] = not (nextMap[name] == true)
                                opt:SetValue(nextMap)
                                renderItem()
                            else
                                opt:SetValue(name)
                                closePopup()
                            end
                        end)
                    end

                    currentPopup = popup
                    currentPopupOwner = row
                    currentPopupOverlay = overlay
                end)
                return opt
            end
            return G
        end

        function window:AddTab(name, iconName)
            local tabButton = Instance.new("TextButton")
            tabButton.Size = UDim2.new(1, 0, 0, 36)
            tabButton.BackgroundColor3 = Color3.fromRGB(21, 15, 18)
            tabButton.BorderSizePixel = 0
            tabButton.Text = "  " .. tostring(name)
            tabButton.TextColor3 = Color3.fromRGB(190, 180, 185)
            tabButton.TextSize = 12
            tabButton.Font = Enum.Font.Code
            tabButton.TextXAlignment = Enum.TextXAlignment.Left
            tabButton.Parent = tabRail
            corner(tabButton, 4)

            local content = Instance.new("Frame")
            content.Size = UDim2.fromScale(1, 1)
            content.BackgroundTransparency = 1
            content.Visible = false
            content.Parent = body

            local left = Instance.new("ScrollingFrame")
            left.Position = UDim2.fromOffset(9, 9)
            left.Size = UDim2.new(0.5, -13, 1, -18)
            left.BackgroundTransparency = 1
            left.BorderSizePixel = 0
            left.ScrollBarThickness = 3
            left.ScrollBarImageColor3 = L.Scheme.AccentColor
            left.AutomaticCanvasSize = Enum.AutomaticSize.None
            left.CanvasSize = UDim2.new()
            left.ScrollingDirection = Enum.ScrollingDirection.Y
            left.ScrollingEnabled = true
            left.Active = true
            left.Parent = content
            padding(left, 0, 4, 0, 4)
            local ll = Instance.new("UIListLayout")
            ll.Padding = UDim.new(0, 8)
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = left
            local function updateLeftCanvas()
                left.CanvasSize = UDim2.fromOffset(0, math.max(0, ll.AbsoluteContentSize.Y + 12))
            end
            ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateLeftCanvas)
            task.defer(updateLeftCanvas)

            local right = Instance.new("ScrollingFrame")
            right.Position = UDim2.new(0.5, 4, 0, 9)
            right.Size = UDim2.new(0.5, -13, 1, -18)
            right.BackgroundTransparency = 1
            right.BorderSizePixel = 0
            right.ScrollBarThickness = 3
            right.ScrollBarImageColor3 = L.Scheme.AccentColor
            right.AutomaticCanvasSize = Enum.AutomaticSize.None
            right.CanvasSize = UDim2.new()
            right.ScrollingDirection = Enum.ScrollingDirection.Y
            right.ScrollingEnabled = true
            right.Active = true
            right.Parent = content
            padding(right, 4, 0, 0, 4)
            local rl = Instance.new("UIListLayout")
            rl.Padding = UDim.new(0, 8)
            rl.SortOrder = Enum.SortOrder.LayoutOrder
            rl.Parent = right
            local function updateRightCanvas()
                right.CanvasSize = UDim2.fromOffset(0, math.max(0, rl.AbsoluteContentSize.Y + 12))
            end
            rl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateRightCanvas)
            task.defer(updateRightCanvas)

            local tab = {_button = tabButton, _content = content}
            function tab:AddLeftGroupbox(titleText) return makeGroup(left, titleText) end
            function tab:AddRightGroupbox(titleText) return makeGroup(right, titleText) end
            tabButton.Activated:Connect(function() activate(tab) end)
            window._tabs[#window._tabs + 1] = tab
            if #window._tabs == 1 then activate(tab) end
            return tab
        end

        return window
    end

    function L:Unload()
        closePopup()
        if screen and screen.Parent then pcall(function() screen:Destroy() end) end
        L.Unloaded = true
    end

    return L
end

__aliceBootSet("Memuat AliceHUB...")

-- Gunakan UI bawaan AliceHUB.

local nativeOk
nativeOk, Library = pcall(buildAliceNativeLibrary)
if not nativeOk or type(Library) ~= "table" then
    local reason = tostring(Library)

    -- Panel error UI.
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local oldErr = pg:FindFirstChild("AliceHUB_AnimeDice_UIError")
    if oldErr then pcall(function() oldErr:Destroy() end) end

    local errGui = Instance.new("ScreenGui")
    errGui.Name = "AliceHUB_AnimeDice_UIError"
    errGui.ResetOnSpawn = false
    errGui.IgnoreGuiInset = true
    errGui.DisplayOrder = 1000000
    errGui.Parent = pg

    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.Size = UDim2.fromOffset(520, 180)
    box.BackgroundColor3 = Color3.fromRGB(18, 11, 14)
    box.BorderSizePixel = 0
    box.Parent = errGui

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = box

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(181, 48, 83)
    s.Thickness = 2
    s.Parent = box

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(16, 10)
    title.Size = UDim2.new(1, -32, 0, 28)
    title.Font = Enum.Font.Code
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(242, 236, 239)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "AliceHUB  ·  Anime Dice"
    title.Parent = box

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency = 1
    msg.Position = UDim2.fromOffset(16, 45)
    msg.Size = UDim2.new(1, -32, 1, -58)
    msg.Font = Enum.Font.Code
    msg.TextSize = 12
    msg.TextColor3 = Color3.fromRGB(218, 178, 190)
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.Text = "UI gagal dimuat:\n" .. reason
    msg.Parent = box

    __aliceBootSet("UI gagal dimuat: " .. reason:sub(1, 110))
    warn("[AliceHUB/AnimeDice/UI] " .. reason)
    return
end

ENV.AliceHUB_AnimeDice_Library = Library
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.NotifySide = "Right"
Library.ShowCustomCursor = false
if type(Library.Scheme) == "table" then
    Library.Scheme.BackgroundColor = Color3.fromRGB(11, 9, 11)
    Library.Scheme.MainColor = Color3.fromRGB(24, 15, 19)
    Library.Scheme.AccentColor = Color3.fromRGB(181, 48, 83)
    Library.Scheme.OutlineColor = Color3.fromRGB(63, 34, 44)
    Library.Scheme.FontColor = Color3.fromRGB(242, 236, 239)
    pcall(function() Library.Scheme.Font = Font.fromEnum(Enum.Font.Code) end)
    Library.Scheme.RedColor = Color3.fromRGB(202, 55, 79)
    Library.Scheme.DestructiveColor = Color3.fromRGB(132, 30, 49)
    Library.Scheme.DarkColor = Color3.fromRGB(7, 6, 7)
    Library.Scheme.WhiteColor = Color3.fromRGB(242, 236, 239)
end

local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local compact = viewport.X <= 1700 and viewport.Y <= 900
local targetWidth = compact and 700 or 900
local targetHeight = compact and 500 or 620
targetWidth = math.min(targetWidth, math.max(560, viewport.X - 80))
targetHeight = math.min(targetHeight, math.max(400, viewport.Y - 70))

local createWindowOk, Window = pcall(function()
    return Library:CreateWindow({
        Title = "AliceHUB",
        Icon = ALICE_HEADER_LOGO_ASSET or "",
        IconSize = UDim2.fromOffset(28, 28),
        Font = Enum.Font.Code,
        Footer = {{Text = "AliceHUB", Copyable = false}, "|", "Anime Dice"},
        NotifySide = "Right",
        ShowMobileButtons = false,
        ShowCustomCursor = false,
        CornerRadius = 4,
        Size = UDim2.fromOffset(targetWidth, targetHeight),
    })
end)
if not createWindowOk or type(Window) ~= "table" then
    local reason = tostring(Window)
    __aliceBootSet("CreateWindow error: " .. reason:sub(1, 110))
    warn("[AliceHUB/AnimeDice/CreateWindow] " .. reason)
    return
end
MainWindow = Window
MainWindowVisible = true
setLastAction("UI Ready")
__aliceBootSet("UI Ready")
task.delay(0.35, __aliceBootDestroy)
pcall(function()
    if Library.ScreenGui then
        Library.ScreenGui.Enabled = true
    end
    if Window._main then
        Window._main.Visible = true
        Window._main.Position = UDim2.fromScale(0.5, 0.5)
    end
    if type(Window.Show) == "function" then
        Window:Show()
    end
end)
pcall(function()
    Library:Notify({
        Title = "AliceHUB",
        Description = "Siap",
        Time = 2.5,
    })
end)

-- Header AliceHUB.
task.defer(function()
    pcall(function()
        local screen = Library.ScreenGui
        if not screen then return end
        for _, object in ipairs(screen:GetDescendants()) do
            if object:IsA("TextLabel") and object.Text == "AliceHUB" and object.TextSize >= 18 then
                local holder = object.Parent
                if holder and holder:IsA("GuiObject") then
                    local oldStack = holder:FindFirstChild("AliceHUBTitleStack")
                    if oldStack then oldStack:Destroy() end
                    object.Visible = false

                    local stack = Instance.new("Frame")
                    stack.Name = "AliceHUBTitleStack"
                    stack.BackgroundTransparency = 1
                    stack.Size = UDim2.fromOffset(150, 40)
                    stack.LayoutOrder = object.LayoutOrder
                    stack.Parent = holder

                    local mainTitle = Instance.new("TextLabel")
                    mainTitle.Name = "MainTitle"
                    mainTitle.BackgroundTransparency = 1
                    mainTitle.Position = UDim2.fromOffset(0, 1)
                    mainTitle.Size = UDim2.new(1, 0, 0, 22)
                    mainTitle.Font = Enum.Font.Code
                    mainTitle.Text = "AliceHUB"
                    mainTitle.TextColor3 = (Library.Scheme and Library.Scheme.FontColor) or Color3.fromRGB(242, 238, 241)
                    mainTitle.TextSize = 18
                    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
                    mainTitle.Parent = stack

                    local subtitle = Instance.new("TextLabel")
                    subtitle.Name = "Subtitle"
                    subtitle.BackgroundTransparency = 1
                    subtitle.Position = UDim2.fromOffset(0, 21)
                    subtitle.Size = UDim2.new(1, 0, 0, 16)
                    subtitle.Font = Enum.Font.Code
                    subtitle.Text = "Anime Dice"
                    subtitle.TextColor3 = Color3.fromRGB(180, 126, 143)
                    subtitle.TextTransparency = 0.12
                    subtitle.TextSize = 11
                    subtitle.TextXAlignment = Enum.TextXAlignment.Left
                    subtitle.Parent = stack
                    break
                end
            end
        end
    end)
end)

-- ============================================================
-- Data + config modules
-- ============================================================
C.DataController = nil
local function resolveDataController()
    if type(C.DataController) == "table" then return C.DataController end
    if type(getloadedmodules) ~= "function" then return nil end
    local ok, modules = pcall(getloadedmodules)
    if not ok or type(modules) ~= "table" then return nil end
    for _, module in ipairs(modules) do
        if typeof(module) == "Instance"
            and module:IsA("ModuleScript")
            and module:GetFullName() == "ReplicatedStorage.Framework.Features.Data.DataController"
        then
            local loaded = safeRequire(module)
            if type(loaded) == "table" then
                C.DataController = loaded
                return loaded
            end
        end
    end
    return nil
end

local function getData()
    local controller = resolveDataController()
    if type(controller) ~= "table" then return nil end
    local data = rawget(controller, "___X")
    return type(data) == "table" and data or nil
end

C.DiceModule = nil
C.UpgradesModule = nil
C.UnitConfig = nil
C.MutationsModule = nil
C.TraitsModule = nil
C.GradesModule = nil
C.RebirthsModule = nil
C.TowersModule = nil
C.EntryRegistry = nil
C.QuestConfig = nil
C.BoostConfig = nil
C.SpinConfig = nil
C.MonetizationConfig = nil
C.LimitedStockProperty = nil
C.BuffCacheProperty = nil
C.EquippedUnitProperty = nil
C.PlotIdProperty = nil
C.ActiveWeatherProperty = nil
C.ActiveWeatherRemote = nil
C.ActiveWeatherCache = nil

-- Data dasar saat module belum tersedia.
C.DiceDefinitions = {
    Basic={luck=1}, Normal={luck=2,price=1}, Fire={luck=5,price=2500}, Water={luck=10,price=10000},
    Nature={luck=20,price=75000}, Lightning={luck=42.5,price=500000}, Ice={luck=100,price=4000000},
    Magma={luck=200,price=30000000}, Storm={luck=400,price=200000000}, Shadow={luck=750,price=1500000000},
    Light={luck=1500,price=12000000000}, ["Blood Moon"]={luck=3000,price=100000000000},
    Void={luck=6000,price=750000000000}, Solar={luck=12500,price=5000000000000},
    Lunar={luck=25000,price=37500000000000}, Galaxy={luck=50000,price=150000000000000},
    ["Black Hole"]={luck=100000,price=1000000000000000}, Dragon={luck=200000,price=8500000000000000},
    Royal={luck=400000,price=100000000000000000}, Prismatic={luck=1000000,price=1000000000000000000},
    Arcane={luck=2000000,price=12500000000000000000}, Corrupted={luck=5000000,price=150000000000000000000},
    Titan={luck=10000000,price=1000000000000000000000}, Chrono={luck=25000000,price=15000000000000000000000},
    Cyber={luck=62500000,price=100000000000000000000000}, Toxic={luck=150000000,price=750000000000000000000000},
}

local function getDiceDefinitions()
    if type(C.DiceModule) ~= "table" or type(C.DiceModule.GetAll) ~= "function" then return C.DiceDefinitions end
    local ok, result = pcall(C.DiceModule.GetAll)
    return ok and type(result) == "table" and result or C.DiceDefinitions
end

local function getTowerDefinitions()
    if type(C.TowersModule) ~= "table" or type(C.TowersModule.GetAll) ~= "function" then return nil end
    local ok, result = pcall(C.TowersModule.GetAll)
    return ok and type(result) == "table" and result or nil
end

-- ============================================================
-- Remotes
-- ============================================================
C.Network = ReplicatedStorage:FindFirstChild("Network")

C.RollRF = C.Network and findPath(C.Network, "RollService", "RF", "RollDice") or nil
C.SetAutoRollRE = findPath(C.Network, "RollService", "RE", "SetAutoRoll")
C.BuyDiceRE = findPath(C.Network, "DiceShopService", "RE", "BuyDice")
C.EquipDiceRE = findPath(C.Network, "DiceShopService", "RE", "EquipDice")
C.BuyUpgradeRE = findPath(C.Network, "RE", "BuyUpgrade")
C.RebirthRE = findPath(C.Network, "RebirthService", "RE", "Rebirth")
C.PlotEquipBestRE = findPath(C.Network, "PlotService", "RE", "EquipBest")
C.CollectBalanceRE = findPath(C.Network, "PlotService", "RE", "CollectBalance")
C.InteractSlotRE = findPath(C.Network, "PlotService", "RE", "InteractSlot")
C.LevelUpSlotRE = findPath(C.Network, "PlotService", "RE", "LevelUpSlot")
C.LevelUpSuccessRE = findPath(C.Network, "PlotService", "RE", "LevelUpSuccess")
C.TextNotificationRE = findPath(C.Network, "NotificationService", "RE", "TextNotification")
C.DropNotificationRE = findPath(C.Network, "NotificationService", "RE", "DropNotification")
C.TraitRollRE = findPath(C.Network, "TraitService", "RE", "Roll")
C.GradeRollRE = findPath(C.Network, "GradeService", "RE", "Roll")
C.SellInventoryRF = findPath(C.Network, "SellService", "RF", "SellInventory")
C.SellEquippedRF = findPath(C.Network, "SellService", "RF", "SellEquipped")
C.RollMessageRE = findPath(C.Network, "RollService", "RE", "RollMessage")
C.PlayTowerRF = findPath(C.Network, "Towers", "RF", "PlayTower")
C.CompleteTowerFloorRF = findPath(C.Network, "Towers", "RF", "CompleteTowerFloor")
C.CancelTowerRF = findPath(C.Network, "Towers", "RF", "CancelTower")
C.EquipBestTowerTeamRE = findPath(C.Network, "Towers", "RE", "EquipBestTowerTeam")
C.UpdateTowerTeamRE = findPath(C.Network, "Towers", "RE", "UpdateTowerTeam")
C.DailyClaimRE = findPath(C.Network, "DailyRewardService", "RE", "Claim")
C.GroupClaimRE = findPath(C.Network, "GroupRewardService", "RE", "Claim")
C.OfflineClaimRE = findPath(C.Network, "OfflineEarningsService", "RE", "Claim")
C.UpdateAutoSellRE = findPath(C.Network, "SellService", "RE", "UpdateAutoSell")
C.UnitSetLockedRE = findPath(C.Network, "UnitService", "RE", "SetLocked")
C.UnitEquipRF = findPath(C.Network, "UnitService", "RF", "Equip")
C.UnitUnequipRF = findPath(C.Network, "UnitService", "RF", "Unequip")
C.QuestClaimRE = findPath(C.Network, "QuestService", "RE", "Claim")
C.QuestBuyRE = findPath(C.Network, "QuestService", "RE", "Buy")
C.SpinUseRE = findPath(C.Network, "SpinService", "RE", "Use")
C.ActiveWeatherRemote = findPath(C.Network, "WeatherService", "RP", "ActiveWeather")
C.BoostUseRE = findPath(C.Network, "BoostService", "RE", "Use")
C.RedeemCodeRE = findPath(C.Network, "MonetizationService", "RE", "RedeemCode")
C.OnboardingAdvanceRE = findPath(C.Network, "OnboardingService", "RE", "Advance")
C.TradeRequestRE = findPath(C.Network, "TradeService", "RE", "RequestTrade")
C.TradeRespondRE = findPath(C.Network, "TradeService", "RE", "RespondToRequest")
C.TradeChangeOfferRE = findPath(C.Network, "TradeService", "RE", "ChangeOffer")
C.TradeAdvanceRE = findPath(C.Network, "TradeService", "RE", "AdvanceTrade")
C.TradeCancelRE = findPath(C.Network, "TradeService", "RE", "CancelTrade")
C.TradeRequestsEnabledRE = findPath(C.Network, "TradeService", "RE", "SetTradeRequestsEnabled")
C.TradeEventRE = findPath(C.Network, "TradeService", "RE", "TradeEvent")
-- 2026-09-20 dump compatibility. These are detected only; AliceHUB does not
-- guess SetSetting payloads or force TradingEnabled state.
C.SetGameSettingRE = findPath(C.Network, "SettingsService", "RE", "SetSetting")
C.TradingEnabledRP = findPath(C.Network, "TradeService", "RP", "TradingEnabled")
C.FuseRE = findPath(C.Network, "FusingService", "RE", "Fuse")
C.FuseResultRE = findPath(C.Network, "FusingService", "RE", "Result")

local function refreshRemotes()
    C.Network = ReplicatedStorage:FindFirstChild("Network") or C.Network
    if not C.Network then return false end
    C.RollRF = findPath(C.Network, "RollService", "RF", "RollDice")
    C.SetAutoRollRE = findPath(C.Network, "RollService", "RE", "SetAutoRoll")
    C.BuyDiceRE = findPath(C.Network, "DiceShopService", "RE", "BuyDice")
    C.EquipDiceRE = findPath(C.Network, "DiceShopService", "RE", "EquipDice")
    C.BuyUpgradeRE = findPath(C.Network, "RE", "BuyUpgrade")
    C.RebirthRE = findPath(C.Network, "RebirthService", "RE", "Rebirth")
    C.PlotEquipBestRE = findPath(C.Network, "PlotService", "RE", "EquipBest")
    C.CollectBalanceRE = findPath(C.Network, "PlotService", "RE", "CollectBalance")
    C.InteractSlotRE = findPath(C.Network, "PlotService", "RE", "InteractSlot")
    C.LevelUpSlotRE = findPath(C.Network, "PlotService", "RE", "LevelUpSlot")
    C.LevelUpSuccessRE = findPath(C.Network, "PlotService", "RE", "LevelUpSuccess")
    C.TextNotificationRE = findPath(C.Network, "NotificationService", "RE", "TextNotification")
    C.DropNotificationRE = findPath(C.Network, "NotificationService", "RE", "DropNotification")
    C.TraitRollRE = findPath(C.Network, "TraitService", "RE", "Roll")
    C.GradeRollRE = findPath(C.Network, "GradeService", "RE", "Roll")
    C.SellInventoryRF = findPath(C.Network, "SellService", "RF", "SellInventory")
    C.SellEquippedRF = findPath(C.Network, "SellService", "RF", "SellEquipped")
    C.RollMessageRE = findPath(C.Network, "RollService", "RE", "RollMessage")
    C.PlayTowerRF = findPath(C.Network, "Towers", "RF", "PlayTower")
    C.CompleteTowerFloorRF = findPath(C.Network, "Towers", "RF", "CompleteTowerFloor")
    C.CancelTowerRF = findPath(C.Network, "Towers", "RF", "CancelTower")
    C.EquipBestTowerTeamRE = findPath(C.Network, "Towers", "RE", "EquipBestTowerTeam")
    C.UpdateTowerTeamRE = findPath(C.Network, "Towers", "RE", "UpdateTowerTeam")
    C.DailyClaimRE = findPath(C.Network, "DailyRewardService", "RE", "Claim")
    C.GroupClaimRE = findPath(C.Network, "GroupRewardService", "RE", "Claim")
    C.OfflineClaimRE = findPath(C.Network, "OfflineEarningsService", "RE", "Claim")
    C.UpdateAutoSellRE = findPath(C.Network, "SellService", "RE", "UpdateAutoSell")
    C.UnitSetLockedRE = findPath(C.Network, "UnitService", "RE", "SetLocked")
    C.UnitEquipRF = findPath(C.Network, "UnitService", "RF", "Equip")
    C.UnitUnequipRF = findPath(C.Network, "UnitService", "RF", "Unequip")
    C.QuestClaimRE = findPath(C.Network, "QuestService", "RE", "Claim")
    C.QuestBuyRE = findPath(C.Network, "QuestService", "RE", "Buy")
    C.SpinUseRE = findPath(C.Network, "SpinService", "RE", "Use")
    C.ActiveWeatherRemote = findPath(C.Network, "WeatherService", "RP", "ActiveWeather")
    C.BoostUseRE = findPath(C.Network, "BoostService", "RE", "Use")
    C.RedeemCodeRE = findPath(C.Network, "MonetizationService", "RE", "RedeemCode")
    C.OnboardingAdvanceRE = findPath(C.Network, "OnboardingService", "RE", "Advance")
    C.TradeRequestRE = findPath(C.Network, "TradeService", "RE", "RequestTrade")
    C.TradeRespondRE = findPath(C.Network, "TradeService", "RE", "RespondToRequest")
    C.TradeChangeOfferRE = findPath(C.Network, "TradeService", "RE", "ChangeOffer")
    C.TradeAdvanceRE = findPath(C.Network, "TradeService", "RE", "AdvanceTrade")
    C.TradeCancelRE = findPath(C.Network, "TradeService", "RE", "CancelTrade")
    C.TradeRequestsEnabledRE = findPath(C.Network, "TradeService", "RE", "SetTradeRequestsEnabled")
    C.TradeEventRE = findPath(C.Network, "TradeService", "RE", "TradeEvent")
    C.SetGameSettingRE = findPath(C.Network, "SettingsService", "RE", "SetSetting")
    C.TradingEnabledRP = findPath(C.Network, "TradeService", "RP", "TradingEnabled")
    C.FuseRE = findPath(C.Network, "FusingService", "RE", "Fuse")
    C.FuseResultRE = findPath(C.Network, "FusingService", "RE", "Result")
    return true
end

refreshRemotes()

local function fire(remote, ...)
    if not remote then return false, "missing remote" end
    local args = table.pack(...)
    local ok, err = pcall(function()
        remote:FireServer(table.unpack(args, 1, args.n))
    end)
    return ok, err
end

local function invoke(remote, ...)
    if not remote then return false, "missing remote" end
    local args = table.pack(...)
    local ok, result = pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
    return ok, result
end

local function shortResult(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    local t = typeof(value)

    if t == "nil" then return "nil" end
    if t == "string" or t == "number" or t == "boolean" then
        return tostring(value)
    end
    if t == "Instance" then
        return "<" .. value.ClassName .. ":" .. value.Name .. ">"
    end
    if t ~= "table" then
        return "<" .. t .. ">"
    end
    if seen[value] then return "<cycle>" end
    if depth >= 2 then return "{...}" end

    seen[value] = true
    local parts, count = {}, 0
    for k, v in pairs(value) do
        count += 1
        if count > 8 then
            parts[#parts + 1] = "..."
            break
        end
        parts[#parts + 1] = tostring(k) .. "=" .. shortResult(v, depth + 1, seen)
    end
    seen[value] = nil
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function remoteAccepted(ok, result)
    if not ok then return false end
    if result == false then return false end
    if type(result) == "table" then
        if result.ok == false or result.success == false then return false end
        if result.error ~= nil and result.ok ~= true and result.success ~= true then return false end
    end
    -- nil is often a valid RemoteFunction success result.
    return true
end

-- ============================================================
-- Unit helpers
-- ============================================================
local function isUUID(value)
    return type(value) == "string"
        and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

local function baseUnitName(name)
    name = tostring(name or "")
    name = name:gsub("^Huge%s+", "")
    name = name:gsub("^Titanic%s+", "")
    name = name:gsub("^Titan%s+", "")
    return name
end

local function unitSizePrefix(name)
    name = tostring(name or "")
    if name:match("^Huge%s+") then
        return "H"
    end
    if name:match("^Titanic%s+") or name:match("^Titan%s+") then
        return "T"
    end
    return nil
end

local RARITY_CANON = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    mythic = "Mythical",
    mythical = "Mythical",
    divine = "Divine",
    celestial = "Celestial",
    exotic = "Exotic",
    exclusive = "Exclusive",
    ["secret i"] = "Secret I",
    ["secret 1"] = "Secret I",
    secreti = "Secret I",
    secret1 = "Secret I",
    ["secret ii"] = "Secret II",
    ["secret 2"] = "Secret II",
    secretii = "Secret II",
    secret2 = "Secret II",
}

local function normalizeRarity(value)
    local raw = tostring(value or ""):gsub("_", " "):gsub("%-", " "):gsub("%s+", " ")
    raw = raw:match("^%s*(.-)%s*$") or raw
    if raw == "" then return nil end
    return RARITY_CANON[raw:lower()] or raw
end

local function rarityFromDefinition(definition)
    if type(definition) ~= "table" then return nil end
    return normalizeRarity(
        definition.rarity or definition.Rarity
        or definition.rarityName or definition.RarityName
        or definition.tier or definition.Tier
    )
end

local function getUnitRarity(item)
    if type(item) ~= "table" then return "Unknown" end

    -- Prefer live inventory fields when the game exposes them.
    local attr = type(item.attributes) == "table" and item.attributes or {}
    local direct = normalizeRarity(
        item.rarity or item.Rarity or item.rarityName or item.RarityName
        or attr.rarity or attr.Rarity or attr.rarityName or attr.RarityName
    )
    if direct then return direct end

    local name = tostring(item.name or "")
    local baseName = baseUnitName(name)

    -- UnitConfig is loaded in the background in this script. Load it lazily here too so
    -- Auto Sell does not temporarily classify every unit as Unknown during startup.
    if type(C.UnitConfig) ~= "table" then
        local module = findPath(ReplicatedStorage, "Framework", "Features", "Inventory", "Kinds", "Unit", "UnitConfig")
        local value = module and safeRequire(module) or nil
        if type(value) == "table" then C.UnitConfig = value end
    end

    local entries = type(C.UnitConfig) == "table" and (C.UnitConfig.entries or C.UnitConfig) or nil
    if type(entries) == "table" then
        local rarity = rarityFromDefinition(entries[name] or entries[baseName])
        if rarity then return rarity end
    end

    -- Fallback to EntryRegistry, which is what the inventory/trade UI already uses.
    if type(C.EntryRegistry) ~= "table" then
        local module = findPath(ReplicatedStorage, "Framework", "Features", "Inventory", "EntryRegistry")
        local value = module and safeRequire(module) or nil
        if type(value) == "table" then C.EntryRegistry = value end
    end

    if type(C.EntryRegistry) == "table" and type(C.EntryRegistry.getEntryConfig) == "function" then
        local ok, config = pcall(C.EntryRegistry.getEntryConfig, name)
        if ok then
            local rarity = rarityFromDefinition(config)
            if rarity then return rarity end
        end
        if baseName ~= name then
            ok, config = pcall(C.EntryRegistry.getEntryConfig, baseName)
            if ok then
                local rarity = rarityFromDefinition(config)
                if rarity then return rarity end
            end
        end
    end

    return "Unknown"
end

local traitOrder = {
    ["Money I"]=1,["Money II"]=2,["Money III"]=3,
    ["Damage I"]=4,["Damage II"]=5,["Damage III"]=6,
    ["Health I"]=7,["Health II"]=8,["Health III"]=9,
    Samurai=10,Shogun=11,Monarch=12,Transcendent=13,Eternal=14,
}

local gradeOrder = {D=1,C=2,B=3,A=4,["A+"]=5,S=6,["S+"]=7,Z=8,["Z+"]=9,["神"]=10}

local mutationRank = {
    Silver = 1,
    Gold = 2,
    Emerald = 3,
    Diamond = 4,
    Ruby = 5,
    Rainbow = 6,
}

local function buildOrderedNames(module, fallback)
    local list = {}
    if type(module) == "table" then
        for name, definition in pairs(module) do
            if type(name) == "string" and type(definition) == "table" then
                list[#list + 1] = {name = name, order = tonumber(definition.order) or 999}
            end
        end
        table.sort(list, function(a, b)
            if a.order == b.order then return a.name < b.name end
            return a.order < b.order
        end)
    end
    local out = {}
    for _, entry in ipairs(list) do out[#out + 1] = entry.name end
    if #out == 0 then
        for _, name in ipairs(fallback or {}) do out[#out + 1] = name end
    end
    return out
end

C.TraitNames = buildOrderedNames(C.TraitsModule, {
    "Money I", "Money II", "Money III", "Damage I", "Damage II", "Damage III",
    "Health I", "Health II", "Health III", "Samurai", "Shogun", "Monarch", "Transcendent", "Eternal",
})

C.GradeNames = buildOrderedNames(C.GradesModule, {"D", "C", "B", "A", "A+", "S", "S+", "Z", "Z+", "神"})

-- Data player dimuat di background.
C.UnitLabelToUUID = {}
local function buildUnitLabels()
    C.UnitLabelToUUID = {}

    local rows = {}
    local data = getData()
    if type(data) == "table" and type(data.Inventory) == "table" then
        for uuid, item in pairs(data.Inventory) do
            if isUUID(uuid) and type(item) == "table" then
                local attr = type(item.attributes) == "table" and item.attributes or {}
                local rawName = tostring(item.name or "Unit")
                local displayName = baseUnitName(rawName)
                if displayName == "" then displayName = "Unit" end

                local level = tonumber(
                    attr.level or attr.Level
                    or item.level or item.Level
                ) or 0

                local rarity = getUnitRarity(item)
                local prefix = unitSizePrefix(rawName)

                local pieces = {}
                if prefix then pieces[#pieces + 1] = prefix end
                pieces[#pieces + 1] = displayName
                pieces[#pieces + 1] = "Lv." .. tostring(math.floor(level))

                -- Buyer-facing list stays compact, but always shows the full rarity.
                if rarity and rarity ~= "" and rarity ~= "Unknown" then
                    pieces[#pieces + 1] = tostring(rarity)
                end

                rows[#rows + 1] = {
                    uuid = uuid,
                    level = level,
                    rarity = rarity,
                    prefix = prefix,
                    name = displayName,
                    baseLabel = table.concat(pieces, " • "),
                }
            end
        end
    end

    local rarityRank = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5,
        ["Mythical"] = 6,
        ["Divine"] = 7,
        ["Celestial"] = 8,
        ["Exotic"] = 9,
        ["Exclusive"] = 10,
        ["Secret I"] = 11,
        ["Secret II"] = 12,
    }

    table.sort(rows, function(a, b)
        -- Highest level first, as requested.
        if a.level ~= b.level then
            return a.level > b.level
        end

        -- At the same level, keep the special rarity near the top.
        local ar = rarityRank[a.rarity] or 0
        local br = rarityRank[b.rarity] or 0
        if ar ~= br then
            return ar > br
        end

        -- Huge / Titan only affect tie-breaking; display stays H / T.
        local ap = a.prefix == "T" and 2 or (a.prefix == "H" and 1 or 0)
        local bp = b.prefix == "T" and 2 or (b.prefix == "H" and 1 or 0)
        if ap ~= bp then
            return ap > bp
        end

        if a.name ~= b.name then
            return a.name < b.name
        end
        return tostring(a.uuid) < tostring(b.uuid)
    end)

    local totals = {}
    for _, row in ipairs(rows) do
        totals[row.baseLabel] = (totals[row.baseLabel] or 0) + 1
    end

    local seen = {}
    local labels = {}
    for _, row in ipairs(rows) do
        local label = row.baseLabel
        if (totals[label] or 0) > 1 then
            seen[label] = (seen[label] or 0) + 1
            -- Only identical duplicates get a tiny human-readable index.
            label = label .. " (" .. tostring(seen[label]) .. ")"
        end
        C.UnitLabelToUUID[label] = row.uuid
        labels[#labels + 1] = label
    end

    if #labels == 0 then labels[1] = "No Unit Found" end
    return labels
end

C.UnitLabels = {"Auto / First Unit"}
if State.AD_TargetUnit == nil then
    State.AD_TargetUnit = C.UnitLabels[1]
end
-- Trait / Grade targets are multi-select. Migrate old single-value configs automatically.
if State.AD_TargetTrait == nil then
    State.AD_TargetTrait = {[C.TraitNames[#C.TraitNames] or "Eternal"] = true}
elseif type(State.AD_TargetTrait) == "string" then
    State.AD_TargetTrait = {[State.AD_TargetTrait] = true}
end
if State.AD_TargetGrade == nil then
    State.AD_TargetGrade = {S = true}
elseif type(State.AD_TargetGrade) == "string" then
    State.AD_TargetGrade = {[State.AD_TargetGrade] = true}
end

local function multiTargetHas(selected, current)
    current = tostring(current or "")
    if current == "" then return false end
    if type(selected) == "string" then return selected == current end
    if type(selected) ~= "table" then return false end
    if selected[current] == true then return true end
    -- Fallback for array-style multi dropdown implementations.
    for key, value in pairs(selected) do
        if type(key) == "number" and tostring(value) == current then return true end
        if tostring(key) == current and value ~= false and value ~= nil then return true end
    end
    return false
end

local function multiTargetCount(selected)
    if type(selected) == "string" then return selected ~= "" and 1 or 0 end
    if type(selected) ~= "table" then return 0 end
    local count = 0
    for key, value in pairs(selected) do
        if type(key) == "number" then
            if value ~= nil and tostring(value) ~= "" then count += 1 end
        elseif value == true then
            count += 1
        end
    end
    return count
end

local function selectedUnitUUID()
    local selected = C.UnitLabelToUUID[State.AD_TargetUnit]
    if selected then return selected end
    local data = getData()
    if data and type(data.Inventory) == "table" then
        for uuid in pairs(data.Inventory) do
            if isUUID(uuid) then return uuid end
        end
    end
    return nil
end

local function getInventoryAmount(name)
    local data = getData()
    local entry = data and data.Inventory and data.Inventory[name]
    return type(entry) == "table" and tonumber(entry.amount) or 0
end

local function parseCompactInput(value)
    local raw = tostring(value or "0"):lower():gsub(",", ""):gsub("%s+", "")
    local number, suffix = raw:match("^([%+%-]?[%d%.]+)([a-z]*)$")
    number = tonumber(number)
    if not number then return nil end
    local mul = {
        k=1e3, m=1e6, b=1e9, t=1e12,
        qa=1e15, qi=1e18, sx=1e21, sp=1e24,
    }
    if suffix ~= "" then
        local factor = mul[suffix]
        if not factor then return nil end
        number = number * factor
    end
    if number < 0 or number > 1e18 then return nil end
    return math.floor(number)
end

local function entryConfigFor(item)
    if type(item) ~= "table" then return nil end
    if type(C.EntryRegistry) ~= "table" then
        C.EntryRegistry = safeRequire(findPath(ReplicatedStorage, "Framework", "Features", "Inventory", "EntryRegistry"))
    end
    if type(C.EntryRegistry) ~= "table" then return nil end
    local fn = C.EntryRegistry.getEntryConfig
    if type(fn) ~= "function" then return nil end
    local ok, config = pcall(fn, item.name)
    return ok and type(config) == "table" and config or nil
end

local function inventoryKeyByName(name)
    local data = getData()
    if not data or type(data.Inventory) ~= "table" then return nil end
    for key, item in pairs(data.Inventory) do
        if type(item) == "table" and tostring(item.name) == tostring(name) then
            return key
        end
    end
    return nil
end

local function activeEntry(name)
    local data = getData()
    local entry = data and data.ActiveEntries and data.ActiveEntries[name]
    return type(entry) == "table" and entry or nil
end

local function claimReadyQuestsOnce()
    local data = getData()
    if type(C.QuestConfig) ~= "table" then
        C.QuestConfig = safeRequire(findPath(ReplicatedStorage, "Framework", "Features", "Quests", "QuestConfig"))
    end
    if type(data) ~= "table" or type(data.Quests) ~= "table" or type(C.QuestConfig) ~= "table" then
        return 0
    end
    local periods = type(C.QuestConfig.Periods) == "table" and C.QuestConfig.Periods or {}
    local claimed = 0
    for periodName, periodConfig in pairs(periods) do
        local live = data.Quests[periodName]
        if type(live) == "table" and type(periodConfig) == "table" and type(periodConfig.quests) == "table" then
            for _, quest in ipairs(periodConfig.quests) do
                local progress = tonumber(live.progress and live.progress[quest.id]) or 0
                local already = live.claimed and live.claimed[quest.id] == true
                if not already and progress >= (tonumber(quest.target) or math.huge) then
                    fire(C.QuestClaimRE, periodName, quest.id, live.expiresAt)
                    claimed += 1
                    task.wait(0.22)
                end
            end
        end
    end
    return claimed
end

local function questSummary()
    local data = getData()
    if type(C.QuestConfig) ~= "table" then
        C.QuestConfig = safeRequire(findPath(ReplicatedStorage, "Framework", "Features", "Quests", "QuestConfig"))
    end
    local parts = {}
    if type(data) == "table" and type(data.Quests) == "table" and type(C.QuestConfig) == "table" then
        for _, periodName in ipairs({"Daily", "Weekly"}) do
            local cfg = C.QuestConfig.Periods and C.QuestConfig.Periods[periodName]
            local live = data.Quests[periodName]
            if type(cfg) == "table" and type(cfg.quests) == "table" and type(live) == "table" then
                local ready, done, total = 0, 0, #cfg.quests
                for _, quest in ipairs(cfg.quests) do
                    local already = live.claimed and live.claimed[quest.id] == true
                    local progress = tonumber(live.progress and live.progress[quest.id]) or 0
                    if already then done += 1
                    elseif progress >= (tonumber(quest.target) or math.huge) then ready += 1 end
                end
                parts[#parts + 1] = string.format("%s %d/%d · ready %d", periodName, done, total, ready)
            end
        end
    end
    return #parts > 0 and table.concat(parts, "\n") or "Quest data loading..."
end

local function indexProgressSummary()
    if type(C.EntryRegistry) ~= "table" then
        C.EntryRegistry = safeRequire(findPath(ReplicatedStorage, "Framework", "Features", "Inventory", "EntryRegistry"))
    end
    local data = getData()
    if type(C.EntryRegistry) ~= "table" or type(C.EntryRegistry.entriesOfKind) ~= "function"
        or type(data) ~= "table" or type(data.DiscoveredUnits) ~= "table" then
        return "Index data loading..."
    end
    local ok, units = pcall(C.EntryRegistry.entriesOfKind, "Unit")
    if not ok or type(units) ~= "table" then return "Index registry unavailable" end
    local total, discovered, mutationDiscoveries = 0, 0, 0
    for name, config in pairs(units) do
        if type(config) == "table" and not config.limited and config.chance then
            total += 1
            local live = data.DiscoveredUnits[name]
            if type(live) == "table" then
                discovered += 1
                if type(live.mutations) == "table" then
                    for _, seen in pairs(live.mutations) do
                        if seen == true then mutationDiscoveries += 1 end
                    end
                end
            end
        end
    end
    local pct = total > 0 and (discovered / total * 100) or 0
    return string.format("Base index: %d/%d (%.1f%%)\nMutation discoveries: %d", discovered, total, pct, mutationDiscoveries)
end

local function onboardingSummary()
    local data = getData()
    if type(data) ~= "table" then return "Tutorial data loading..." end
    local step = tonumber(data.OnboardingStep) or 0
    if step > 13 then return "Tutorial: completed" end
    return string.format("Tutorial step: %d/13", step)
end

-- Trade / inventory scanner state.
C.TradeLabelToKey = {}
C.TradePlayerLabelToPlayer = {}
C.TradeRuntime = {
    incoming = nil,
    partner = nil,
    status = "Idle",
    phase = "None",
    ownOffer = {},
    otherOffer = {},
    ownReady = false,
    otherReady = false,
    ownAccepted = false,
    otherAccepted = false,
    countdownEndsAt = nil,
    lastAutoAdvanceAt = 0,
}

local function tradeEntryKind(key, item)
    local config = entryConfigFor(item)
    if config and config.kind then return tostring(config.kind) end
    if isUUID(key) then return "Unit" end
    return "Other"
end

local function buildTradeInventoryLabels()
    C.TradeLabelToKey = {}
    local data = getData()
    local labels = {}
    local search = tostring(State.AD_TradeSearch or ""):lower()
    local kindFilter = tostring(State.AD_TradeKind or "All")
    if type(data) == "table" and type(data.Inventory) == "table" then
        for key, item in pairs(data.Inventory) do
            if type(item) == "table" and tonumber(item.amount or 0) > 0 then
                local kind = tradeEntryKind(key, item)
                if kindFilter == "All" or kind == kindFilter then
                    local attr = type(item.attributes) == "table" and item.attributes or {}
                    local pieces = {"[" .. kind .. "]", tostring(item.name or key)}
                    if tostring(item.name) == "Tickets" then pieces[#pieces + 1] = "NO-TRADE" end
                    if kind == "Unit" then
                        local rarity = getUnitRarity(item)
                        if rarity and rarity ~= "Unknown" then pieces[#pieces + 1] = rarity end
                        if attr.mutation then pieces[#pieces + 1] = "M:" .. tostring(attr.mutation) end
                        if attr.trait then pieces[#pieces + 1] = "T:" .. tostring(attr.trait) end
                        if attr.grade then pieces[#pieces + 1] = "G:" .. tostring(attr.grade) end
                        if attr.level then pieces[#pieces + 1] = "Lv" .. tostring(attr.level) end
                        if attr.locked == true then pieces[#pieces + 1] = "LOCKED" end
                        pieces[#pieces + 1] = "#" .. tostring(key):sub(1, 8)
                    else
                        pieces[#pieces + 1] = "x" .. tostring(item.amount or 1)
                    end
                    local label = table.concat(pieces, " | ")
                    if search == "" or label:lower():find(search, 1, true) then
                        C.TradeLabelToKey[label] = key
                        labels[#labels + 1] = label
                    end
                end
            end
        end
    end
    table.sort(labels)
    if #labels == 0 then labels[1] = "No Item" end
    return labels
end

local function selectedTradeKey()
    return C.TradeLabelToKey[State.AD_TradeItem]
end

local function selectedTradeItem()
    local key = selectedTradeKey()
    local data = getData()
    return key, data and data.Inventory and data.Inventory[key] or nil
end

-- ============================================================
-- Core automation helpers
-- ============================================================
local function bestOwnedDice()
    local data = getData()
    if not data or type(data.OwnedDice) ~= "table" then return nil end
    local bestName, bestLuck = nil, -math.huge
    for key, definition in pairs(C.DiceDefinitions) do
        local name = type(key) == "string" and key or (type(definition) == "table" and definition.name)
        if name and data.OwnedDice[name] == true then
            local luck = type(definition) == "table" and tonumber(definition.luck) or 0
            if luck and luck > bestLuck then
                bestLuck, bestName = luck, name
            end
        end
    end
    return bestName, bestLuck
end

local function bestAffordableUnownedDice()
    local data = getData()
    if not data or type(data.OwnedDice) ~= "table" then return nil end
    local money = tonumber(data.Money) or 0
    local candidate, candidateLuck = nil, -math.huge
    for key, definition in pairs(C.DiceDefinitions) do
        if type(definition) == "table" then
            local name = type(key) == "string" and key or definition.name
            local price = tonumber(definition.price)
            local luck = tonumber(definition.luck) or 0
            if name and price and price > 0 and price <= money and data.OwnedDice[name] ~= true then
                if luck > candidateLuck then
                    candidate, candidateLuck = name, luck
                end
            end
        end
    end
    return candidate
end

local function selectedUpgradeCategories()
    local selected = State.AD_UpgradeCategories
    if type(selected) ~= "table" then return {} end
    return selected
end

local function upgradeCategory(name)
    if name == "Start" then return "Start" end
    return tostring(name):match("^(.-)%s+[IVXLCDM]+$") or tostring(name)
end

local function nextAffordableUpgrade()
    local data = getData()
    if not data or type(C.UpgradesModule) ~= "table" then return nil end
    local money = tonumber(data.Money) or 0
    local owned = type(data.Upgrades) == "table" and data.Upgrades or {}
    local selected = selectedUpgradeCategories()
    local candidate, cheapest = nil, math.huge
    for name, definition in pairs(C.UpgradesModule) do
        if type(definition) == "table" and owned[name] ~= true then
            local category = upgradeCategory(name)
            local enabled = next(selected) == nil or selected[category] == true
            local price = tonumber(definition.price)
            if enabled and price and price <= money and price < cheapest then
                candidate, cheapest = name, price
            end
        end
    end
    return candidate
end

local REBIRTH_COSTS = {
    [1]=50000,[2]=5000000,[3]=500000000,[4]=50000000000,[5]=5000000000000,
    [6]=500000000000000,[7]=10000000000000000,[8]=1000000000000000000,
    [9]=100000000000000000000,[10]=1e22,[11]=1e24,
}
local function nextRebirthInfo()
    local data = getData()
    if not data then return nil end
    local current = tonumber(data.Rebirth) or 0
    if type(C.RebirthsModule) == "table" and type(C.RebirthsModule.GetNext) == "function" then
        local ok, info = pcall(C.RebirthsModule.GetNext, current)
        if ok and type(info) == "table" then return info end
    end
    local cost = REBIRTH_COSTS[current + 1]
    return cost and {cost=cost} or nil
end

local function plotAndTowerProtectedUUIDs()
    local data = getData()
    local protected = {}
    if not data then return protected end
    if type(data.TowerTeam) == "table" then
        for _, uuid in pairs(data.TowerTeam) do
            if type(uuid) == "string" then protected[uuid] = true end
        end
    end
    if type(data.Slots) == "table" then
        for _, slot in pairs(data.Slots) do
            if type(slot) == "table" and type(slot.unitId) == "string" then
                protected[slot.unitId] = true
            end
        end
    end
    return protected
end

-- Favorite / Lock helpers ---------------------------------------------------
C.FavoriteRuntimeLocks = {}

local function parseFlexibleNumber(raw)
    raw = tostring(raw or "0"):gsub("%s+", ""):lower()
    if raw == "" then return 0 end
    local direct = tonumber(raw)
    if direct then return math.max(0, direct) end
    local number, suffix = raw:match("^([%+%-]?[%d%.]+)([a-z]+)$")
    number = tonumber(number)
    if not number then return nil end
    local mul = {
        k=1e3, m=1e6, b=1e9, t=1e12, qa=1e15, qi=1e18, sx=1e21, sp=1e24,
        oc=1e27, no=1e30, dc=1e33, ud=1e36, dd=1e39, td=1e42, qd=1e45,
        qid=1e48, sxd=1e51, spd=1e54,
    }
    local factor = mul[suffix]
    if not factor then return nil end
    return math.max(0, number * factor)
end

local function unitChanceValue(item)
    local config = entryConfigFor(item)
    local attr = type(item) == "table" and type(item.attributes) == "table" and item.attributes or {}
    if type(config) == "table" and type(config.chance) == "function" then
        local ok, value = pcall(config.chance, attr)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

local function selectionHasTrue(tbl)
    if type(tbl) ~= "table" then return false end
    for _, enabled in pairs(tbl) do
        if enabled == true then return true end
    end
    return false
end

local function propertyValue(property)
    if property and type(property.Get) == "function" then
        local ok, value = pcall(property.Get, property)
        if ok then return value end
    end
    return nil
end

local function unitMatchesFavorite(uuid, item, protectedRefs)
    if type(item) ~= "table" or not isUUID(uuid) then return false end
    local attr = type(item.attributes) == "table" and item.attributes or {}
    local config = entryConfigFor(item)
    local name = tostring(item.name or "")
    local rarity = getUnitRarity(item)
    protectedRefs = protectedRefs or plotAndTowerProtectedUUIDs()

    local checks = {}
    local function addCriterion(enabled, matched)
        if enabled then checks[#checks + 1] = matched == true end
    end

    local selectedRarities = type(State.AD_FavoriteRarities) == "table" and State.AD_FavoriteRarities or {}
    addCriterion(selectionHasTrue(selectedRarities), selectedRarities[rarity] == true)

    local chanceThreshold = parseFlexibleNumber(State.AD_FavoriteMinChance) or 0
    addCriterion(chanceThreshold > 0, unitChanceValue(item) >= chanceThreshold)

    local traitThreshold = tostring(State.AD_FavoriteMinTrait or "None")
    addCriterion(traitThreshold ~= "None",
        (traitOrder[attr.trait] or 0) >= (traitOrder[traitThreshold] or math.huge))

    local gradeThreshold = tostring(State.AD_FavoriteMinGrade or "None")
    addCriterion(gradeThreshold ~= "None",
        (gradeOrder[attr.grade] or 0) >= (gradeOrder[gradeThreshold] or math.huge))

    local mutationThreshold = tostring(State.AD_FavoriteMinMutation or "None")
    addCriterion(mutationThreshold ~= "None",
        (mutationRank[attr.mutation] or 0) >= (mutationRank[mutationThreshold] or math.huge))

    addCriterion(State.AD_FavoriteHugeTitanic == true,
        name:match("^Huge%s") ~= nil or name:match("^Titanic%s") ~= nil)
    addCriterion(State.AD_FavoriteLimited == true,
        type(config) == "table" and config.limited == true)
    addCriterion(State.AD_FavoritePlotTower == true, protectedRefs[uuid] == true)

    if #checks == 0 then return false end
    if tostring(State.AD_FavoriteMatchMode or "Any") == "All" then
        for _, matched in ipairs(checks) do if not matched then return false end end
        return true
    end
    for _, matched in ipairs(checks) do if matched then return true end end
    return false
end

local function collectFavoriteMatches()
    local data = getData()
    local matches = {}
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then return matches end
    local protectedRefs = plotAndTowerProtectedUUIDs()
    for uuid, item in pairs(data.Inventory) do
        if isUUID(uuid) and unitMatchesFavorite(uuid, item, protectedRefs) then
            matches[#matches + 1] = uuid
        end
    end
    table.sort(matches)
    return matches
end

local function runFavoritePass()
    local data = getData()
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then return 0, 0 end
    local protectedRefs = plotAndTowerProtectedUUIDs()
    local lockMap = {}
    local lockCount, unlockCount = 0, 0

    for uuid, item in pairs(data.Inventory) do
        if isUUID(uuid) and type(item) == "table" then
            local attr = type(item.attributes) == "table" and item.attributes or {}
            local matches = unitMatchesFavorite(uuid, item, protectedRefs)
            if State.AD_AutoFavorite == true and matches and attr.locked ~= true then
                lockMap[uuid] = true
                lockCount += 1
            elseif State.AD_AutoUnfavorite == true and not matches
                and C.FavoriteRuntimeLocks[uuid] == true and attr.locked == true then
                lockMap[uuid] = false
                unlockCount += 1
            end
        end
    end

    for uuid in pairs(C.FavoriteRuntimeLocks) do
        if data.Inventory[uuid] == nil then C.FavoriteRuntimeLocks[uuid] = nil end
    end

    if next(lockMap) then
        local ok = fire(C.UnitSetLockedRE, lockMap)
        if ok then
            for uuid, locked in pairs(lockMap) do
                if locked then C.FavoriteRuntimeLocks[uuid] = true else C.FavoriteRuntimeLocks[uuid] = nil end
            end
        end
    end
    return lockCount, unlockCount
end

local function favoriteInventorySummaryText()
    local data = getData()
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then return "Inventory: memuat..." end
    local units, locked, matching, hugeTitanic, limited = 0, 0, 0, 0, 0
    local rarestName, rarestChance = "-", 0
    local protectedRefs = plotAndTowerProtectedUUIDs()
    for uuid, item in pairs(data.Inventory) do
        if isUUID(uuid) and type(item) == "table" then
            units += 1
            local attr = type(item.attributes) == "table" and item.attributes or {}
            if attr.locked == true then locked += 1 end
            if unitMatchesFavorite(uuid, item, protectedRefs) then matching += 1 end
            local name = tostring(item.name or "")
            if name:match("^Huge%s") or name:match("^Titanic%s") then hugeTitanic += 1 end
            local config = entryConfigFor(item)
            if type(config) == "table" and config.limited == true then limited += 1 end
            local chance = unitChanceValue(item)
            if chance > rarestChance then rarestChance, rarestName = chance, name end
        end
    end
    local buffCache = propertyValue(C.BuffCacheProperty)
    local storage = type(buffCache) == "table" and tonumber(buffCache["Unit Storage"]) or nil
    local equipped = propertyValue(C.EquippedUnitProperty)
    local plotId = propertyValue(C.PlotIdProperty)
    return string.format(
        "Units: %d%s | Locked: %d | Fav matches: %d\nHuge/Titanic: %d | Limited: %d\nRarest: %s · 1 in %s\nHeld: %s | Plot: %s",
        units, storage and ("/" .. compactNumber(storage)) or "", locked, matching,
        hugeTitanic, limited, rarestName, compactNumber(rarestChance),
        equipped and tostring(equipped):sub(1, 12) or "-", tostring(plotId or "-")
    )
end

local function shouldProtectUnit(uuid, item, protectedRefs)
    if type(item) ~= "table" then return true end
    local attr = type(item.attributes) == "table" and item.attributes or {}
    local name = tostring(item.name or "")

    -- Standard safety only: locked/favorited, equipped plot/tower units, Huge/Titanic.
    if attr.locked == true then return true end
    if State.AD_ProtectFavoriteMatches == true and unitMatchesFavorite(uuid, item, protectedRefs) then return true end
    if State.AD_ProtectPlotTower == true and protectedRefs[uuid] then return true end
    if State.AD_ProtectHugeTitanic == true and (name:match("^Huge%s") or name:match("^Titanic%s")) then return true end
    return false
end

local function selectedRarityEnabled(selected, rarity)
    rarity = normalizeRarity(rarity)
    if not rarity or type(selected) ~= "table" then return false end
    if selected[rarity] == true then return true end
    for key, value in pairs(selected) do
        if type(key) == "number" then
            if normalizeRarity(value) == rarity then return true end
        elseif value == true and normalizeRarity(key) == rarity then
            return true
        end
    end
    return false
end

local function collectSellUUIDs()
    local data = getData()
    if not data or type(data.Inventory) ~= "table" then return {}, 0 end
    local selectedRarities = type(State.AD_SellRarities) == "table" and State.AD_SellRarities or {}
    local protectedRefs = plotAndTowerProtectedUUIDs()
    local sellAll = tostring(State.AD_SellMode or "Selected Rarities") == "Sell All"
    local result = {}
    local unknown = 0

    for uuid, item in pairs(data.Inventory) do
        if isUUID(uuid) and type(item) == "table" and not shouldProtectUnit(uuid, item, protectedRefs) then
            if sellAll then
                result[#result + 1] = uuid
                if #result >= 100 then break end
            else
                local rarity = getUnitRarity(item)
                if rarity == "Unknown" then
                    unknown += 1
                elseif selectedRarityEnabled(selectedRarities, rarity) then
                    result[#result + 1] = uuid
                    if #result >= 100 then break end
                end
            end
        end
    end

    return result, unknown
end

local function startLoop(id, body, delayProvider)
    Runtime.loopTokens[id] = (Runtime.loopTokens[id] or 0) + 1
    local token = Runtime.loopTokens[id]
    task.spawn(function()
        while Runtime.alive and Runtime.loopTokens[id] == token do
            local enabled = State[id] == true
            if not enabled then break end
            local ok, err = pcall(body)
            if not ok then
                setLastAction(id .. " error")
                warn("[AliceHUB/AnimeDice] " .. id .. ": " .. tostring(err))
            end
            local delay = type(delayProvider) == "function" and tonumber(delayProvider()) or tonumber(delayProvider)
            task.wait(math.max(0.03, delay or 0.5))
        end
    end)
end

local function stopLoop(id)
    Runtime.loopTokens[id] = (Runtime.loopTokens[id] or 0) + 1
end

local Toggles = Library.Toggles
local Options = Library.Options

local function notify(text, duration)
    pcall(function()
        Library:Notify({Title = "AliceHUB", Description = tostring(text), Time = duration or 3})
    end)
end

local function setState(key, value)
    State[key] = value
    saveState()
end

local function addToggle(group, id, text, default, tooltip, callback)
    group:AddToggle(id, {
        Text = text,
        Default = State[id] ~= nil and State[id] or default,
        Tooltip = tooltip,
    })
    local option = Toggles[id]
    if option and type(option.OnChanged) == "function" then
        option:OnChanged(function()
            local value = option.Value == true
            setState(id, value)
            if callback then callback(value) end
        end)
    end
    return option
end

local function addSlider(group, id, text, min, max, default, rounding, suffix, callback)
    group:AddSlider(id, {
        Text = text,
        Default = tonumber(State[id]) or default,
        Min = min,
        Max = max,
        Rounding = rounding or 0,
        Suffix = suffix or "",
    })
    local option = Options[id]
    if option and type(option.OnChanged) == "function" then
        option:OnChanged(function()
            setState(id, option.Value)
            if callback then callback(option.Value) end
        end)
    end
    return option
end

local function addInput(group, id, text, default, placeholder, callback)
    local configured = State[id]
    if configured == nil then configured = default or "" end

    group:AddInput(id, {
        Text = text,
        Default = tostring(configured or ""),
        Placeholder = placeholder or "",
    })

    local option = Options[id]
    if option and type(option.OnChanged) == "function" then
        option:OnChanged(function()
            local value = tostring(option.Value or "")
            setState(id, value)
            if callback then callback(value) end
        end)
    end
    return option
end

local function addDropdown(group, id, text, values, default, multi, callback)
    local configured = State[id]
    if configured == nil then configured = default end
    group:AddDropdown(id, {
        Values = values,
        Multi = multi == true,
        Searchable = true,
        AllowNull = false,
        Text = text,
        Default = configured,
    })
    local option = Options[id]
    if option and type(option.OnChanged) == "function" then
        option:OnChanged(function()
            setState(id, option.Value)
            if callback then callback(option.Value) end
        end)
    end
    return option
end

C.Tabs = {
    Main = Window:AddTab("Main", "home"),
    Units = Window:AddTab("Units", "users"),
    Trade = Window:AddTab("Trade", "handshake"),
    Tower = Window:AddTab("Tower", "castle"),
    Rewards = Window:AddTab("Rewards", "gift"),
    Weather = Window:AddTab("Weather", "cloud-sun"),
    Extras = Window:AddTab("Extras", "sparkles"),
    Webhook = Window:AddTab("Webhook", "webhook"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- Module game dimuat setelah UI siap.
task.spawn(function()
    local paths = {
        {"Dice", {"Framework","Features","Rolling","Dice"}},
        {"Upgrades", {"Framework","Features","Upgrades","Upgrades"}},
        {"UnitConfig", {"Framework","Features","Inventory","Kinds","Unit","UnitConfig"}},
        {"Mutations", {"Framework","Features","Inventory","Kinds","Unit","Mutations"}},
        {"Traits", {"Framework","Features","Traits","Traits"}},
        {"Grades", {"Framework","Features","Grades","Grades"}},
        {"Rebirths", {"Framework","Features","Rebirth","Rebirths"}},
        {"Towers", {"Framework","Features","Towers","Towers"}},
        {"EntryRegistry", {"Framework","Features","Inventory","EntryRegistry"}},
        {"QuestConfig", {"Framework","Features","Quests","QuestConfig"}},
        {"BoostConfig", {"Framework","Features","Inventory","Kinds","Boost","BoostConfig"}},
        {"SpinConfig", {"Framework","Features","Inventory","Kinds","Spin","SpinConfig"}},
        {"MonetizationConfig", {"Framework","Features","Monetization","MonetizationConfig"}},
    }
    for _, entry in ipairs(paths) do
        task.spawn(function()
            local module = findPath(ReplicatedStorage, table.unpack(entry[2]))
            if not module then return end
            local value = safeRequire(module)
            if entry[1] == "Dice" and type(value)=="table" then C.DiceModule=value; C.DiceDefinitions=getDiceDefinitions() end
            if entry[1] == "Upgrades" and type(value)=="table" then C.UpgradesModule=value end
            if entry[1] == "UnitConfig" and type(value)=="table" then C.UnitConfig=value end
            if entry[1] == "Mutations" and type(value)=="table" then C.MutationsModule=value end
            if entry[1] == "Traits" and type(value)=="table" then C.TraitsModule=value end
            if entry[1] == "Grades" and type(value)=="table" then C.GradesModule=value end
            if entry[1] == "Rebirths" and type(value)=="table" then C.RebirthsModule=value end
            if entry[1] == "Towers" and type(value)=="table" then C.TowersModule=value end
            if entry[1] == "EntryRegistry" and type(value)=="table" then C.EntryRegistry=value end
            if entry[1] == "QuestConfig" and type(value)=="table" then C.QuestConfig=value end
            if entry[1] == "BoostConfig" and type(value)=="table" then C.BoostConfig=value end
            if entry[1] == "SpinConfig" and type(value)=="table" then C.SpinConfig=value end
            if entry[1] == "MonetizationConfig" and type(value)=="table" then C.MonetizationConfig=value end
        end)
    end
    task.spawn(function()
        if not C.Network then C.Network = ReplicatedStorage:WaitForChild("Network", 30) end
        refreshRemotes()
        task.spawn(function()
            local networkPackage = safeRequire(findPath(ReplicatedStorage, "Packages", "Network"))
            if type(networkPackage) == "table" and networkPackage.ClientComm and C.Network then
                local ClientComm = networkPackage.ClientComm
                local function getProperty(serviceName, propertyName)
                    local ok, property = pcall(function()
                        return ClientComm.new(C.Network, false, serviceName):GetProperty(propertyName)
                    end)
                    return ok and property or nil
                end
                C.LimitedStockProperty = getProperty("LimitedUnitService", "Stock") or C.LimitedStockProperty
                C.BuffCacheProperty = getProperty("BuffService", "Cache") or C.BuffCacheProperty
                C.EquippedUnitProperty = getProperty("UnitService", "EquippedUnit") or C.EquippedUnitProperty
                C.PlotIdProperty = getProperty("PlotService", "PlotId") or C.PlotIdProperty
                C.ActiveWeatherProperty = getProperty("WeatherService", "ActiveWeather") or C.ActiveWeatherProperty
            end
        end)
    end)
end)

-- ============================================================
-- Main tab
-- ============================================================
C.MainAutomation = C.Tabs.Main:AddLeftGroupbox("Roll & Progression")
C.MainStatus = C.Tabs.Main:AddRightGroupbox("Live Status")

C.StatusLabel = C.MainStatus:AddLabel("Loading player data...", true)
C.ActionLabel = C.MainStatus:AddLabel("Action: Ready", true)

C.fastRollInflight = 0
C.fastRollSent = 0
C.fastRollLastRolls = 0
C.fastRollLastCheck = 0

addToggle(C.MainAutomation, "AD_FastRoll", "Fast Auto Roll", false,
    "Manual RollDice scheduler. Normal server auto-roll is disabled so it cannot consume the same roll cooldown.", function(value)

    if value then
        if Toggles.AD_ServerAutoRoll and Toggles.AD_ServerAutoRoll.Value then
            Toggles.AD_ServerAutoRoll:SetValue(false)
        end

        -- Fast Roll memakai loop sendiri.

        fire(C.SetAutoRollRE, false)

        local data = getData()
        C.fastRollLastRolls = data and tonumber(data.Rolls) or 0
        C.fastRollLastCheck = os.clock()
        C.fastRollInflight = 0
        C.fastRollSent = 0

        startLoop("AD_FastRoll", function()
            -- Jalankan request sesuai interval.

            if C.fastRollInflight < 6 then
                C.fastRollInflight += 1
                C.fastRollSent += 1
                task.spawn(function()
                    invoke(C.RollRF)
                    C.fastRollInflight = math.max(0, C.fastRollInflight - 1)
                end)
            end

            local now = os.clock()
            if now - C.fastRollLastCheck >= 2.0 then
                local live = getData()
                local rolls = live and tonumber(live.Rolls) or C.fastRollLastRolls
                local gained = math.max(0, rolls - C.fastRollLastRolls)
                local elapsed = math.max(0.01, now - C.fastRollLastCheck)
                local rps = gained / elapsed

                if gained > 0 then
                    setLastAction(("Fast Roll: +%d | %.2f roll/s | %.2fs"):format(
                        gained,
                        rps,
                        tonumber(State.AD_RollDelay) or 0
                    ))
                else
                    setLastAction(("Fast Roll: server throttled | sent %d"):format(C.fastRollSent))
                end

                C.fastRollLastRolls = rolls
                C.fastRollLastCheck = now
                C.fastRollSent = 0
            end
        end, function()
            return math.max(0.03, tonumber(State.AD_RollDelay) or 0.10)
        end)
    else
        stopLoop("AD_FastRoll")
        fire(C.SetAutoRollRE, false)
        C.fastRollInflight = 0
        setLastAction("Fast Roll: OFF")
    end
end)

addToggle(C.MainAutomation, "AD_ServerAutoRoll", "Server Auto Roll", false,
    "Game's normal server auto-roll. Mutually exclusive with Fast Auto Roll.", function(value)
    if value and Toggles.AD_FastRoll and Toggles.AD_FastRoll.Value then
        Toggles.AD_FastRoll:SetValue(false)
    end
    fire(C.SetAutoRollRE, value)
    setLastAction("Server Auto Roll: " .. tostring(value))
end)

addSlider(C.MainAutomation, "AD_RollDelay", "Fast Roll Delay", 0.03, 1.50, 0.10, 2, "s")
C.MainAutomation:AddLabel("Kecepatan roll mengikuti batas server.", true)

addToggle(C.MainAutomation, "AD_AutoBuyDice", "Auto Buy Best Dice", false, "Membeli dice terbaik yang belum dimiliki dan masih terjangkau.", function(value)
    if value then
        startLoop("AD_AutoBuyDice", function()
            local name = bestAffordableUnownedDice()
            if name then
                setLastAction("Buy Dice: " .. name)
                fire(C.BuyDiceRE, name)
            else
                local data = getData()
                setLastAction("Buy Dice: waiting | $" .. compactNumber(data and data.Money))
            end
        end, 1.3)
    else stopLoop("AD_AutoBuyDice") end
end)

addToggle(C.MainAutomation, "AD_AutoEquipDice", "Auto Equip Best Dice", false, nil, function(value)
    if value then
        startLoop("AD_AutoEquipDice", function()
            local data = getData()
            local name = bestOwnedDice()
            if name and data and data.Dice ~= name then
                setLastAction("Equip Dice: " .. name)
                fire(C.EquipDiceRE, name)
            elseif name then
                setLastAction("Equip Dice: already " .. tostring(name))
            end
        end, 1.6)
    else stopLoop("AD_AutoEquipDice") end
end)

C.upgradeCategories = {"Damage", "Health", "Luck", "Money", "Roll Speed", "Sell", "Unit Storage", "Walkspeed", "Fortune", "Start"}
if type(State.AD_UpgradeCategories) ~= "table" then
    State.AD_UpgradeCategories = {}
    for _, name in ipairs(C.upgradeCategories) do State.AD_UpgradeCategories[name] = true end
end
addDropdown(C.MainAutomation, "AD_UpgradeCategories", "Upgrade Categories", C.upgradeCategories, State.AD_UpgradeCategories, true)

addToggle(C.MainAutomation, "AD_AutoUpgrade", "Auto Upgrade", false, "Upgrade otomatis selama saldo mencukupi.", function(value)
    if value then
        startLoop("AD_AutoUpgrade", function()
            local upgrade = nextAffordableUpgrade()
            if upgrade then
                setLastAction("Upgrade: " .. upgrade)
                fire(C.BuyUpgradeRE, upgrade)
            end
        end, 0.55)
    else stopLoop("AD_AutoUpgrade") end
end)

addToggle(C.MainAutomation, "AD_AutoRebirth", "Auto Rebirth", false, nil, function(value)
    if value then
        startLoop("AD_AutoRebirth", function()
            local data = getData()
            if not data then return end
            local current = tonumber(data.Rebirth) or 0
            local stopAt = tonumber(State.AD_StopRebirth) or 0
            if stopAt > 0 and current >= stopAt then
                if Toggles.AD_AutoRebirth then Toggles.AD_AutoRebirth:SetValue(false) end
                notify("Auto Rebirth selesai di " .. tostring(current))
                return
            end
            local info = nextRebirthInfo()
            local cost = info and tonumber(info.cost)
            if cost and (tonumber(data.Money) or 0) >= cost then
                setLastAction("Rebirth " .. tostring(current + 1))
                fire(C.RebirthRE)
            elseif cost then
                setLastAction(("Rebirth waiting: %s / %s"):format(
                    compactNumber(tonumber(data.Money) or 0),
                    compactNumber(cost)
                ))
            else
                setLastAction("Rebirth: no next config")
            end
        end, 1.0)
    else stopLoop("AD_AutoRebirth") end
end)

addSlider(C.MainAutomation, "AD_StopRebirth", "Stop At Rebirth (0 = ∞)", 0, 50, 0, 0, "")

-- ============================================================
-- Units tab
-- ============================================================
C.UnitAutomation = C.Tabs.Units:AddLeftGroupbox("Units")
C.ServerSell = C.Tabs.Units:AddLeftGroupbox("Server Auto Sell")
C.UnitFavorite = C.Tabs.Units:AddLeftGroupbox("Favorite / Lock")
C.UnitFuseFilter = C.Tabs.Units:AddLeftGroupbox("Fuse Filter")
C.UnitFuseAuto = C.Tabs.Units:AddLeftGroupbox("Auto Fuse")
C.UnitReroll = C.Tabs.Units:AddRightGroupbox("Trait & Grade")
C.UnitSell = C.Tabs.Units:AddRightGroupbox("Smart Sell")
C.UnitInventory = C.Tabs.Units:AddRightGroupbox("Inventory Manager")

addInput(C.ServerSell, "AD_ServerAutoSellThreshold", "Sell Below 1 In N", "0", "e.g. 1K / 1M / 100000", function(value)
    -- Tekan Apply untuk menyimpan batas.
end)
C.ServerSell:AddButton({Text = "Apply Server Auto Sell", Func = function()
    if State.AD_AutoFavorite == true and State.AD_FavoriteSafetyDisableNativeSell == true then
        notify("Matikan Favorite Safety sebelum memakai Server Auto Sell.", 6)
        return
    end
    local threshold = parseCompactInput(State.AD_ServerAutoSellThreshold)
    if threshold == nil then
        notify("Invalid threshold. Example: 1K, 1M, 100000", 5)
        return
    end
    fire(C.UpdateAutoSellRE, threshold)
    setLastAction("Server Auto Sell: < 1 in " .. compactNumber(threshold))
    notify(threshold > 0 and ("Server Auto Sell set: below 1 in " .. compactNumber(threshold)) or "Server Auto Sell disabled", 5)
end})
C.ServerSell:AddButton({Text = "Disable Server Auto Sell", Func = function()
    fire(C.UpdateAutoSellRE, 0)
    setState("AD_ServerAutoSellThreshold", "0")
    if Options.AD_ServerAutoSellThreshold and type(Options.AD_ServerAutoSellThreshold.SetValue) == "function" then
        pcall(Options.AD_ServerAutoSellThreshold.SetValue, Options.AD_ServerAutoSellThreshold, "0")
    end
    notify("Server Auto Sell disabled")
end})
C.ServerSell:AddLabel("Unit di bawah batas 1-in-N akan langsung terjual setelah roll.", true)

C.UnitAutomation:AddButton({Text = "Equip Best Units", Func = function()
    setLastAction("Equip Best Units")
    fire(C.PlotEquipBestRE)
end})

addToggle(C.UnitAutomation, "AD_AutoEquipUnits", "Auto Equip Best Units", false, nil, function(value)
    if value then
        startLoop("AD_AutoEquipUnits", function()
            setLastAction("Equip Best Units")
            fire(C.PlotEquipBestRE)
        end, 6)
    else stopLoop("AD_AutoEquipUnits") end
end)

C.UnitAutomation:AddButton({Text = "Collect All Plot Slots", Func = function()
    local data = getData()
    if data and type(data.Slots) == "table" then
        for slot in pairs(data.Slots) do fire(C.CollectBalanceRE, tonumber(slot) or slot) end
    else
        for slot = 1, 13 do fire(C.CollectBalanceRE, slot) end
    end
    setLastAction("Collect All")
end})

addToggle(C.UnitAutomation, "AD_AutoCollect", "Auto Collect All", false, nil, function(value)
    if value then
        startLoop("AD_AutoCollect", function()
            local data = getData()
            if data and type(data.Slots) == "table" then
                for slot in pairs(data.Slots) do fire(C.CollectBalanceRE, tonumber(slot) or slot) end
            end
            setLastAction("Auto Collect")
        end, 3)
    else stopLoop("AD_AutoCollect") end
end)

addToggle(C.UnitAutomation, "AD_AutoLevelSlots", "Auto Level Plot Slots", false, "Upgrade berjalan jika saldo mencukupi.", function(value)
    if value then
        startLoop("AD_AutoLevelSlots", function()
            local data = getData()
            if data and type(data.Slots) == "table" then
                for slot in pairs(data.Slots) do
                    fire(C.LevelUpSlotRE, tonumber(slot) or slot)
                    task.wait(0.05)
                end
            end
            setLastAction("Level Plot Slots")
        end, 1.5)
    else stopLoop("AD_AutoLevelSlots") end
end)

addDropdown(C.UnitReroll, "AD_TargetUnit", "Target Unit", C.UnitLabels, C.UnitLabels[1], false)
C.UnitReroll:AddButton({Text = "Refresh Unit List", Func = function()
    local values = buildUnitLabels()
    C.UnitLabels = values
    local option = Options.AD_TargetUnit
    local refreshed = false
    if option and type(option.SetValues) == "function" then
        refreshed = pcall(option.SetValues, option, values)
    end
    if refreshed then
        local first = values[1]
        if C.UnitLabelToUUID[first] and type(option.SetValue) == "function" then option:SetValue(first) end
        notify("Unit list refreshed")
    else
        notify("List rebuilt. Re-execute UI kalau dropdown belum berubah.", 4)
    end
end})

addDropdown(C.UnitReroll, "AD_TargetTrait", "Target Traits", C.TraitNames, State.AD_TargetTrait, true)
addDropdown(C.UnitReroll, "AD_TargetGrade", "Target Grades", C.GradeNames, State.AD_TargetGrade, true)
C.UnitReroll:AddLabel("Bisa pilih banyak. Auto reroll berhenti saat mendapat salah satu Trait / Grade yang dipilih.", true)
addSlider(C.UnitReroll, "AD_RerollDelay", "Reroll Delay", 0.20, 2.00, 0.50, 2, "s")

addToggle(C.UnitReroll, "AD_AutoTrait", "Auto Trait", false, "Berhenti saat trait target didapat.", function(value)
    if value then
        startLoop("AD_AutoTrait", function()
            local uuid = selectedUnitUUID()
            local data = getData()
            local item = uuid and data and data.Inventory and data.Inventory[uuid]
            if not item then return end
            local attr = type(item.attributes) == "table" and item.attributes or {}
            if multiTargetCount(State.AD_TargetTrait) <= 0 then
                if Toggles.AD_AutoTrait then Toggles.AD_AutoTrait:SetValue(false) end
                notify("Pilih minimal 1 Target Trait", 5)
                return
            end
            local currentTrait = tostring(attr.trait or "")
            if multiTargetHas(State.AD_TargetTrait, currentTrait) then
                if Toggles.AD_AutoTrait then Toggles.AD_AutoTrait:SetValue(false) end
                notify("Trait target didapat: " .. currentTrait)
                return
            end
            if getInventoryAmount("Trait Reroll") <= 0 then
                if Toggles.AD_AutoTrait then Toggles.AD_AutoTrait:SetValue(false) end
                notify("Trait Reroll habis")
                return
            end
            setLastAction("Trait Roll: " .. tostring(item.name))
            fire(C.TraitRollRE, uuid, true)
        end, function() return State.AD_RerollDelay end)
    else stopLoop("AD_AutoTrait") end
end)

addToggle(C.UnitReroll, "AD_AutoGrade", "Auto Grade", false, "Berhenti saat grade target didapat.", function(value)
    if value then
        startLoop("AD_AutoGrade", function()
            local uuid = selectedUnitUUID()
            local data = getData()
            local item = uuid and data and data.Inventory and data.Inventory[uuid]
            if not item then return end
            local attr = type(item.attributes) == "table" and item.attributes or {}
            if multiTargetCount(State.AD_TargetGrade) <= 0 then
                if Toggles.AD_AutoGrade then Toggles.AD_AutoGrade:SetValue(false) end
                notify("Pilih minimal 1 Target Grade", 5)
                return
            end
            local currentGrade = tostring(attr.grade or "")
            if multiTargetHas(State.AD_TargetGrade, currentGrade) then
                if Toggles.AD_AutoGrade then Toggles.AD_AutoGrade:SetValue(false) end
                notify("Grade target didapat: " .. currentGrade)
                return
            end
            setLastAction("Grade Roll: " .. tostring(item.name))
            fire(C.GradeRollRE, uuid, true)
        end, function() return State.AD_RerollDelay end)
    else stopLoop("AD_AutoGrade") end
end)

C.rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Celestial", "Exotic", "Exclusive", "Secret I", "Secret II"}
addDropdown(C.UnitSell, "AD_SellMode", "Auto Sell Mode", {"Selected Rarities", "Sell All"}, "Selected Rarities", false)
addDropdown(C.UnitSell, "AD_SellRarities", "Sell Rarities", C.rarities, State.AD_SellRarities, true)
addToggle(C.UnitSell, "AD_ProtectHugeTitanic", "Protect Huge / Titanic", true)
addToggle(C.UnitSell, "AD_ProtectPlotTower", "Protect Plot / Tower Team", true)
addSlider(C.UnitSell, "AD_SellDelay", "Sell Interval", 1, 15, 4, 1, "s")
C.UnitSell:AddLabel("Selected Rarities = jual rarity pilihan. Sell All = jual semua unit yang tidak dilindungi.", true)
C.UnitSell:AddLabel("Locked, Plot/Tower, dan Huge/Titanic tetap aman selama protection ON.", true)

C.UnitSell:AddButton({Text = "Preview Sell Count", Func = function()
    local ids, unknown = collectSellUUIDs()
    local text = "Sell candidate: " .. tostring(#ids) .. " unit"
    if unknown > 0 then text ..= " · waiting rarity " .. tostring(unknown) end
    notify(text)
end})

addToggle(C.UnitSell, "AD_SmartSell", "Auto Sell", false, "Menjual unit sesuai Auto Sell Mode yang dipilih.", function(value)
    if value then
        startLoop("AD_SmartSell", function()
            local ids = collectSellUUIDs()
            if #ids > 0 then
                setLastAction("Auto Sell: " .. tostring(#ids))
                local ok = invoke(C.SellInventoryRF, ids)
                if not ok then
                    refreshRemotes()
                    task.wait(0.20)
                    invoke(C.SellInventoryRF, ids)
                end
            end
        end, function() return State.AD_SellDelay end)
    else stopLoop("AD_SmartSell") end
end)

-- ============================================================
-- Favorite / Lock + Inventory Manager
-- ============================================================
C.FavoriteSummaryLabel = C.UnitFavorite:AddLabel("Favorite: memuat...", true)
C.InventoryManagerLabel = C.UnitInventory:AddLabel("Inventory: memuat...", true)

local function disableNativeAutoSellForFavorite(message)
    fire(C.UpdateAutoSellRE, 0)
    setState("AD_ServerAutoSellThreshold", "0")
    local option = Options.AD_ServerAutoSellThreshold
    if option and type(option.SetValue) == "function" then
        pcall(option.SetValue, option, "0")
    end
    if message then notify(message, 6) end
end

local function updateFavoriteSummary()
    local matches = collectFavoriteMatches()
    local aliceLocked = tableCount(C.FavoriteRuntimeLocks)
    if C.FavoriteSummaryLabel and type(C.FavoriteSummaryLabel.SetText) == "function" then
        C.FavoriteSummaryLabel:SetText(string.format(
            "Matches: %d | Alice auto-locks: %d\nMode: %s | Native sell safety: %s",
            #matches, aliceLocked, tostring(State.AD_FavoriteMatchMode or "Any"),
            State.AD_FavoriteSafetyDisableNativeSell and "ON" or "OFF"
        ))
    end
end

local function updateInventoryManagerSummary()
    if C.InventoryManagerLabel and type(C.InventoryManagerLabel.SetText) == "function" then
        C.InventoryManagerLabel:SetText(favoriteInventorySummaryText())
    end
end

local function updateFavoriteWorker()
    Runtime.loopTokens.AD_FavoriteWorker = (Runtime.loopTokens.AD_FavoriteWorker or 0) + 1
    local token = Runtime.loopTokens.AD_FavoriteWorker
    if State.AD_AutoFavorite ~= true and State.AD_AutoUnfavorite ~= true then return end
    task.spawn(function()
        while Runtime.alive and Runtime.loopTokens.AD_FavoriteWorker == token
            and (State.AD_AutoFavorite == true or State.AD_AutoUnfavorite == true) do
            local ok, locked, unlocked = pcall(runFavoritePass)
            if ok and ((locked or 0) > 0 or (unlocked or 0) > 0) then
                setLastAction(string.format("Favorite: +%d / -%d", locked or 0, unlocked or 0))
            end
            pcall(updateFavoriteSummary)
            pcall(updateInventoryManagerSummary)
            task.wait(math.max(0.25, tonumber(State.AD_FavoriteScanDelay) or 0.5))
        end
    end)
end

addDropdown(C.UnitFavorite, "AD_FavoriteMatchMode", "Match Mode", {"Any", "All"}, "Any", false)
addDropdown(C.UnitFavorite, "AD_FavoriteRarities", "Favorite Rarities", C.rarities, State.AD_FavoriteRarities, true)
addInput(C.UnitFavorite, "AD_FavoriteMinChance", "Minimum 1 In N", "0", "0 / 1M / 1e12 / 1Qi")
addDropdown(C.UnitFavorite, "AD_FavoriteMinTrait", "Minimum Trait", {"None", "Money I", "Money II", "Money III", "Damage I", "Damage II", "Damage III", "Health I", "Health II", "Health III", "Samurai", "Shogun", "Monarch", "Transcendent", "Eternal"}, "None", false)
addDropdown(C.UnitFavorite, "AD_FavoriteMinGrade", "Minimum Grade", {"None", "D", "C", "B", "A", "A+", "S", "S+", "Z", "Z+", "神"}, "None", false)
addDropdown(C.UnitFavorite, "AD_FavoriteMinMutation", "Minimum Mutation", {"None", "Silver", "Gold", "Emerald", "Diamond", "Ruby", "Rainbow"}, "None", false)
addToggle(C.UnitFavorite, "AD_FavoriteHugeTitanic", "Always Fav Huge / Titanic", true)
addToggle(C.UnitFavorite, "AD_FavoriteLimited", "Always Fav Limited", true)
addToggle(C.UnitFavorite, "AD_FavoritePlotTower", "Fav Plot / Tower Units", false)
addToggle(C.UnitFavorite, "AD_ProtectFavoriteMatches", "Protect Fav Matches From Smart Sell", true,
    "Protection is evaluated before the lock remote lands, so Smart Sell cannot race Auto Favorite.")
addToggle(C.UnitFavorite, "AD_FavoriteSafetyDisableNativeSell", "Disable Native Auto Sell While Auto Fav", true,
    "Native server auto-sell happens before AliceHUB can lock a new roll.", function(value)
        if value and State.AD_AutoFavorite == true then
            disableNativeAutoSellForFavorite("Native Server Auto Sell disabled for Auto Favorite safety")
        end
    end)
addSlider(C.UnitFavorite, "AD_FavoriteScanDelay", "Favorite Scan Interval", 0.25, 3.00, 0.50, 2, "s")
addToggle(C.UnitFavorite, "AD_AutoFavorite", "Auto Favorite / Lock", false,
    "Uses the game's real UnitService.SetLocked flag.", function(value)
        if value and State.AD_FavoriteSafetyDisableNativeSell == true then
            disableNativeAutoSellForFavorite("Auto Favorite ON · native Server Auto Sell forced OFF")
        end
        updateFavoriteWorker()
    end)
addToggle(C.UnitFavorite, "AD_AutoUnfavorite", "Auto Unfavorite Alice Locks", false,
    "Only unlocks units that AliceHUB itself auto-locked and that no longer match.", function()
        updateFavoriteWorker()
    end)

C.UnitFavorite:AddButton({Text = "Preview Favorite", Func = function()
    local matches = collectFavoriteMatches()
    updateFavoriteSummary()
    notify("Favorite cocok: " .. tostring(#matches), 5)
end})
C.UnitFavorite:AddButton({Text = "Lock Semua yang Cocok", Func = function()
    local data = getData()
    local matches = collectFavoriteMatches()
    local map = {}
    if data and type(data.Inventory) == "table" then
        for _, uuid in ipairs(matches) do
            local item = data.Inventory[uuid]
            local attr = type(item) == "table" and type(item.attributes) == "table" and item.attributes or {}
            if attr.locked ~= true then map[uuid] = true end
        end
    end
    local count = tableCount(map)
    if count > 0 then
        local ok = fire(C.UnitSetLockedRE, map)
        if ok then for uuid in pairs(map) do C.FavoriteRuntimeLocks[uuid] = true end end
    end
    task.delay(0.25, updateFavoriteSummary)
    notify("Unit terkunci: " .. tostring(count), 5)
end})
C.UnitFavorite:AddButton({Text = "Unlock Auto Favorite", Func = function()
    local data = getData()
    local map = {}
    if data and type(data.Inventory) == "table" then
        for uuid in pairs(C.FavoriteRuntimeLocks) do
            if data.Inventory[uuid] then map[uuid] = false end
        end
    end
    local count = tableCount(map)
    if count > 0 then fire(C.UnitSetLockedRE, map) end
    table.clear(C.FavoriteRuntimeLocks)
    task.delay(0.25, updateFavoriteSummary)
    notify("Lock dibuka: " .. tostring(count), 5)
end})
C.UnitFavorite:AddLabel("ANY = salah satu filter cocok. ALL = semua filter aktif harus cocok.", true)

C.UnitInventory:AddButton({Text = "Refresh Inventory Summary", Func = function()
    updateInventoryManagerSummary()
    updateFavoriteSummary()
end})
C.UnitInventory:AddButton({Text = "Sell Held / Equipped Unit", Func = function()
    task.spawn(function()
        local ok, result = invoke(C.SellEquippedRF)
        notify(ok and ("Sell held result: " .. shortResult(result)) or ("Sell held failed: " .. tostring(result)), 5)
        task.delay(0.25, updateInventoryManagerSummary)
    end)
end})
C.UnitInventory:AddButton({Text = "Copy Inventory Summary", Func = function()
    local summary = favoriteInventorySummaryText()
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, summary)
    elseif type(toclipboard) == "function" then copied = pcall(toclipboard, summary) end
    notify(copied and "Inventory summary copied" or summary, 5)
end})
C.UnitInventory:AddButton({Text = "Export Inventory JSON", Func = function()
    if type(writefile) ~= "function" then notify("writefile unsupported by executor", 5); return end
    local data = getData()
    if not data or type(data.Inventory) ~= "table" then notify("Inventory unavailable", 5); return end
    local rows = {}
    for key, item in pairs(data.Inventory) do
        if type(item) == "table" then
            rows[#rows + 1] = {key = key, name = item.name, amount = item.amount, attributes = item.attributes}
        end
    end
    table.sort(rows, function(a, b) return tostring(a.name) < tostring(b.name) end)
    local payload = {game = "Anime Dice", user = LocalPlayer.Name, exportedAt = os.time(), inventory = rows}
    local ok, json = pcall(HttpService.JSONEncode, HttpService, payload)
    if not ok then notify("Inventory JSON encode failed", 5); return end
    pcall(function()
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(SETTINGS_FOLDER) then makefolder(SETTINGS_FOLDER) end
    end)
    local path = SETTINGS_FOLDER .. "/AnimeDice_Inventory.json"
    local wrote, err = pcall(writefile, path, json)
    notify(wrote and ("Inventory exported: " .. path) or ("Export failed: " .. tostring(err)), 6)
end})
C.UnitInventory:AddLabel("Unit locked atau yang sedang dipakai tidak akan ikut terjual.", true)

-- ============================================================
-- UPD 5 Fusing
-- Native-flow automation: AliceHUB deliberately does NOT guess the Fuse
-- RemoteEvent payload. It drives the game's own FusingController buttons,
-- so the native controller remains responsible for validation and FireServer.
-- ============================================================
C.FuseRuntime = {
    busy = false,
    lastResult = nil,
    lastResultAt = 0,
    status = "Idle",
    roundRobinCursor = 1,
}

C.setFuseStatus = function(text)
    C.FuseRuntime.status = tostring(text or "Idle")
    if C.FuseStatusLabel and type(C.FuseStatusLabel.SetText) == "function" then
        C.FuseStatusLabel:SetText("Fuse: " .. C.FuseRuntime.status)
    end
end

C.guiTreeVisible = function(instance)
    local current = instance
    while current and current ~= game do
        if current:IsA("GuiObject") and current.Visible == false then return false end
        if current:IsA("ScreenGui") and current.Enabled == false then return false end
        current = current.Parent
    end
    return true
end

C.activateNativeButton = function(button)
    if not (button and button:IsA("GuiButton")) then return false end

    -- Prefer one signal only. Firing both Activated and MouseButton1Click can
    -- execute the same native callback twice on some UI frameworks.
    local orderedSignals = {button.Activated, button.MouseButton1Click}
    if type(getconnections) == "function" then
        for _, signal in ipairs(orderedSignals) do
            local ok, connections = pcall(getconnections, signal)
            if ok and type(connections) == "table" and #connections > 0 then
                if type(firesignal) == "function" then
                    local fired = pcall(firesignal, signal)
                    if fired then return true end
                end
                for _, connection in ipairs(connections) do
                    local fn = connection and connection.Function
                    if type(fn) == "function" and pcall(fn) then return true end
                    if connection and type(connection.Fire) == "function" and pcall(connection.Fire, connection) then return true end
                end
            end
        end
    end

    if type(firesignal) == "function" then
        return pcall(firesignal, button.Activated)
    end
    return false
end

C.valueContainsFuseTarget = function(value, uuid, name, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 7 then return false end

    local kind = typeof(value)
    if kind == "string" then
        local lower = value:lower()
        return value == uuid or (name ~= "" and lower == name)
    end

    if kind == "Instance" then
        if seen[value] then return false end
        seen[value] = true

        local okName, instanceName = pcall(function() return tostring(value.Name or "") end)
        if okName and (instanceName == uuid or (name ~= "" and instanceName:lower() == name)) then
            return true
        end

        local okAttr, attributes = pcall(value.GetAttributes, value)
        if okAttr and type(attributes) == "table"
            and C.valueContainsFuseTarget(attributes, uuid, name, depth + 1, seen) then
            return true
        end

        if value:IsA("StringValue") then
            local okValue, stringValue = pcall(function() return tostring(value.Value or "") end)
            if okValue and (stringValue == uuid or (name ~= "" and stringValue:lower() == name)) then
                return true
            end
        end
        return false
    end

    if kind == "function" then
        if seen[value] then return false end
        seen[value] = true

        local getUps = debug and debug.getupvalues
        if type(getUps) ~= "function" and type(getupvalues) == "function" then
            getUps = getupvalues
        end
        if type(getUps) == "function" then
            local okUp, upvalues = pcall(getUps, value)
            if okUp and type(upvalues) == "table"
                and C.valueContainsFuseTarget(upvalues, uuid, name, depth + 1, seen) then
                return true
            end
        end

        local getConsts = debug and debug.getconstants
        if type(getConsts) ~= "function" and type(getconstants) == "function" then
            getConsts = getconstants
        end
        if type(getConsts) == "function" then
            local okConst, constants = pcall(getConsts, value)
            if okConst and type(constants) == "table"
                and C.valueContainsFuseTarget(constants, uuid, name, depth + 1, seen) then
                return true
            end
        end
        return false
    end

    if kind ~= "table" then return false end
    if seen[value] then return false end
    seen[value] = true
    for k, v in pairs(value) do
        if C.valueContainsFuseTarget(k, uuid, name, depth + 1, seen)
            or C.valueContainsFuseTarget(v, uuid, name, depth + 1, seen) then
            return true
        end
    end
    return false
end

C.buttonCapturesFuseTarget = function(button, target)
    local uuid = tostring(target and target.uuid or "")
    local name = tostring(target and target.name or ""):lower()

    -- Some UPD 5 cards keep the backing unit on the card/descendant attributes.
    if C.valueContainsFuseTarget(button, uuid, name, 0, {}) then return true end
    for _, child in ipairs(button:GetDescendants()) do
        if C.valueContainsFuseTarget(child, uuid, name, 0, {}) then return true end
    end

    if type(getconnections) ~= "function" then return false end
    for _, signal in ipairs({button.Activated, button.MouseButton1Click}) do
        local ok, connections = pcall(getconnections, signal)
        if ok and type(connections) == "table" then
            for _, connection in ipairs(connections) do
                local fn = connection and connection.Function
                if type(fn) == "function"
                    and C.valueContainsFuseTarget(fn, uuid, name, 0, {}) then
                    return true
                end
            end
        end
    end
    return false
end

C.fuseTargetIncome = function(target)
    if type(target) ~= "table" or type(target.item) ~= "table" then return nil end
    return C.fuseIncomeValue(target.item)
end

C.cardIncomeTextMatchesTarget = function(button, target)
    local expected = C.fuseTargetIncome(target)
    if not expected then return false end

    local blob = C.textBlob(button):gsub("%s+", "")
    local compact = tostring(compactNumber(expected)):lower()
    if blob:find("$" .. compact .. "/s", 1, true) then return true end

    -- The native formatter may use lower-case suffixes or slightly different
    -- rounding. Parse the displayed $/s value and compare numerically.
    local numberText, suffix = blob:match("%$([%d%.]+)([kmbtqspxi]*)/s")
    local number = tonumber(numberText)
    if not number then return false end
    local multipliers = {
        [""] = 1,
        k = 1e3, m = 1e6, b = 1e9, t = 1e12,
        qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
    }
    local multiplier = multipliers[suffix]
    if not multiplier then return false end
    local shown = number * multiplier
    local tolerance = math.max(1, expected * 0.025)
    return math.abs(shown - expected) <= tolerance
end

C.playerMenus = function()
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local root = gui and gui:FindFirstChild("Root")
    return root and root:FindFirstChild("Menus")
end

C.fusingMenu = function()
    local menus = C.playerMenus()
    return menus and menus:FindFirstChild("Fusing")
end

C.selectUnitMenu = function()
    local menus = C.playerMenus()
    return menus and menus:FindFirstChild("SelectUnit")
end

C.fuseProgressValue = function()
    local menu = C.fusingMenu()
    local portal = menu and menu:FindFirstChild("Portal")
    local label = portal and portal:FindFirstChild("Progress")
    local text = label and label:IsA("TextLabel") and tostring(label.Text or "") or ""
    local value, maxv = text:match("(%d+)%s*/%s*(%d+)")
    return tonumber(value) or 0, tonumber(maxv) or 3, text
end

C.fusingAccessPart = function()
    local zones = workspace:FindFirstChild("Zones")
    local zone = zones and zones:FindFirstChild("Fusing")
    if zone then
        if zone:IsA("BasePart") then return zone end
        local part = zone:FindFirstChildWhichIsA("BasePart", true)
        if part then return part end
    end

    local machine = workspace:FindFirstChild("AuraFuseMachine")
    if machine then
        if machine:IsA("BasePart") then return machine end
        return machine:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

C.enterFusingArea = function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local part = C.fusingAccessPart()
    if not (root and part) then return false end

    if not C.FuseRuntime.returnCFrame then
        C.FuseRuntime.returnCFrame = root.CFrame
    end

    if (root.Position - part.Position).Magnitude > 7 then
        root.CFrame = part.CFrame * CFrame.new(0, 3.5, 0)
        task.wait(0.35)
    end
    return true
end

C.leaveFusingArea = function()
    local returnCFrame = C.FuseRuntime.returnCFrame
    C.FuseRuntime.returnCFrame = nil
    if not returnCFrame then return end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = returnCFrame
        task.wait(0.08)
    end
end

C.openNativeFusingMenu = function()
    local menu = C.fusingMenu()
    if menu and C.guiTreeVisible(menu) then return true end

    -- The native controller only responds while the player is inside/near the
    -- Fusing zone. Enter it automatically so Fuse works from anywhere.
    C.enterFusingArea()

    local machine = workspace:FindFirstChild("AuraFuseMachine")
    local attachment = machine and machine:FindFirstChild("Attachment")
    local billboard = attachment and attachment:FindFirstChildOfClass("BillboardGui")
    local frame = billboard and billboard:FindFirstChild("Frame")
    local button = frame and frame:FindFirstChild("Name")

    local deadline = os.clock() + 2.5
    repeat
        if button and button:IsA("GuiButton") then
            C.activateNativeButton(button)
        end
        task.wait(0.10)
        menu = C.fusingMenu()
        if menu and C.guiTreeVisible(menu) then return true end
    until os.clock() >= deadline

    return menu ~= nil and C.guiTreeVisible(menu)
end

C.closeNativeFusingMenu = function()
    local menu = C.fusingMenu()
    local design = menu and menu:FindFirstChild("Design")
    local banner = design and design:FindFirstChild("Banner")
    local exit = banner and banner:FindFirstChild("ExitButton")
    if exit and exit:IsA("GuiButton") then
        C.activateNativeButton(exit)
        task.wait(0.08)
        return true
    end
    return false
end

C.parseFuseFilters = function()
    local function parseOptional(label, raw)
        local cleaned = tostring(raw or ""):gsub("%s+", "")
        if cleaned == "" then return nil, nil end
        local value = parseFlexibleNumber(cleaned)
        if value == nil then
            return nil, label .. " is invalid. Use values like 100, 1k, 1m, 500b, 1t or 1qd."
        end
        return value, nil
    end

    local minChance, err = parseOptional("Minimum 1 in X", State.AD_FuseMinChance)
    if err then return nil, err end
    local maxChance
    maxChance, err = parseOptional("Maximum 1 in X", State.AD_FuseMaxChance)
    if err then return nil, err end
    local maxIncome
    maxIncome, err = parseOptional("Maximum Income", State.AD_FuseMaxIncome)
    if err then return nil, err end

    if minChance ~= nil and maxChance ~= nil and minChance > maxChance then
        return nil, "Minimum 1 in X cannot be higher than Maximum 1 in X."
    end

    return {
        minChance = minChance,
        maxChance = maxChance,
        maxIncome = maxIncome,
    }
end

C.fuseIncomeValue = function(item)
    if type(item) ~= "table" then return nil end
    local config = entryConfigFor(item)
    local attributes = type(item.attributes) == "table" and item.attributes or {}
    if type(config) == "table" and type(config.income) == "function" then
        local ok, value = pcall(config.income, attributes)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return nil
end

C.fuseAlwaysProtected = function(uuid, item, protectedRefs)
    if type(item) ~= "table" then return true end
    local attr = type(item.attributes) == "table" and item.attributes or {}
    local config = entryConfigFor(item)

    -- Filter mode is backpack-only. Anything locked, actively used, placed on
    -- plot/tower, equipped/held, or Limited is never consumed automatically.
    if attr.locked == true then return true end
    if protectedRefs[uuid] == true then return true end
    if type(config) == "table" and config.limited == true then return true end

    local held = propertyValue(C.EquippedUnitProperty)
    if type(held) == "string" and held == uuid then return true end
    return false
end

C.fuseMatchesFilters = function(item, filters)
    if type(item) ~= "table" or type(filters) ~= "table" then return false end

    local chance = tonumber(unitChanceValue(item)) or 0
    local income = C.fuseIncomeValue(item)

    if filters.minChance ~= nil then
        if chance <= 0 or chance < filters.minChance then return false end
    end
    if filters.maxChance ~= nil then
        if chance <= 0 or chance > filters.maxChance then return false end
    end
    if filters.maxIncome ~= nil then
        if income == nil or income > filters.maxIncome then return false end
    end

    return true, chance, income
end

C.collectFuseCandidates = function()
    local filters, filterErr = C.parseFuseFilters()
    if not filters then return {}, filterErr end

    local data = getData()
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then
        return {}, "Inventory unavailable"
    end

    local protectedRefs = plotAndTowerProtectedUUIDs()
    local candidates = {}
    local stats = {
        units = 0,
        eligible = 0,
        filtered = 0,
        protected = 0,
    }

    for uuid, item in pairs(data.Inventory) do
        if isUUID(uuid) and type(item) == "table" then
            local config = entryConfigFor(item)
            local kind = type(config) == "table" and tostring(config.kind or "Unit") or "Unit"
            if kind == "Unit" or kind == "" then
                stats.units += 1
                if C.fuseAlwaysProtected(uuid, item, protectedRefs) then
                    stats.protected += 1
                else
                    local matches, chance, income = C.fuseMatchesFilters(item, filters)
                    if matches then
                        stats.eligible += 1
                        candidates[#candidates + 1] = {
                            uuid = uuid,
                            item = item,
                            name = tostring(item.name or "") ~= "" and tostring(item.name) or "Unit",
                            chance = tonumber(chance) or 0,
                            income = tonumber(income),
                        }
                    else
                        stats.filtered += 1
                    end
                end
            end
        end
    end

    -- Common/low-value matches are consumed first. The active filters remain
    -- the hard boundary, so rare/high-income units outside the range never enter.
    table.sort(candidates, function(a, b)
        local ac, bc = tonumber(a.chance) or 0, tonumber(b.chance) or 0
        if ac ~= bc then
            if ac <= 0 then return false end
            if bc <= 0 then return true end
            return ac < bc
        end
        local ai, bi = tonumber(a.income), tonumber(b.income)
        if ai ~= bi then
            if ai == nil then return false end
            if bi == nil then return true end
            return ai < bi
        end
        if a.name ~= b.name then return a.name:lower() < b.name:lower() end
        return tostring(a.uuid) < tostring(b.uuid)
    end)

    return candidates, nil, stats, filters
end

C.fuseFilterSummary = function(filters)
    filters = filters or {}
    local parts = {}
    if filters.minChance ~= nil then parts[#parts + 1] = "min 1 in " .. compactNumber(filters.minChance) end
    if filters.maxChance ~= nil then parts[#parts + 1] = "max 1 in " .. compactNumber(filters.maxChance) end
    if filters.maxIncome ~= nil then parts[#parts + 1] = "income ≤ " .. compactNumber(filters.maxIncome) end
    if #parts == 0 then return "no limits" end
    return table.concat(parts, " · ")
end

C.refreshFuseInfo = function(silent)
    local candidates, reason, stats, filters = C.collectFuseCandidates()
    if reason then
        C.setFuseStatus(reason)
        if C.FuseInfoLabel and type(C.FuseInfoLabel.SetText) == "function" then
            C.FuseInfoLabel:SetText("Filter: " .. tostring(reason))
        end
        if not silent then notify("Fuse: " .. tostring(reason), 5) end
        return candidates, reason
    end

    stats = stats or {units = 0, eligible = #candidates, filtered = 0, protected = 0}
    local info = ("Eligible: %d / %d backpack units\nFiltered: %d · Protected: %d\n%s")
        :format(stats.eligible or #candidates, stats.units or 0, stats.filtered or 0, stats.protected or 0, C.fuseFilterSummary(filters))
    if C.FuseInfoLabel and type(C.FuseInfoLabel.SetText) == "function" then
        C.FuseInfoLabel:SetText(info)
    end
    if not silent then notify(("Fuse eligible: %d unit(s)"):format(#candidates), 4) end
    return candidates
end

C.chooseFuseTriplet = function()
    local candidates, reason = C.collectFuseCandidates()
    if #candidates < 3 then
        return nil, reason or ("Need 3 eligible backpack units · found %d"):format(#candidates)
    end
    return {candidates[1], candidates[2], candidates[3]}
end

C.textBlob = function(root)
    local parts = {}
    if root:IsA("TextLabel") or root:IsA("TextButton") then parts[#parts + 1] = tostring(root.Text or "") end
    for _, child in ipairs(root:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local t = tostring(child.Text or "")
            if t ~= "" then parts[#parts + 1] = t end
        end
    end
    return table.concat(parts, " "):lower()
end

-- UPD5 accuracy pass: never treat a shared callback/upvalue table as proof that
-- a card is the requested unit. In the native picker every card can close over
-- the same inventory/list table, which made ALL cards look like a UUID/name
-- match and caused the first visible card to be selected.
C.visibleFuseCards = function(scrolling)
    local raw = {}
    for _, obj in ipairs(scrolling:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Active ~= false then
            local blob = C.textBlob(obj):gsub("%s+", "")
            if blob:find("$/s", 1, true) or blob:match("%$[%d%.]+[%a]*/s") then
                raw[#raw + 1] = obj
            end
        end
    end

    -- Keep only the outer card when a card contains another GuiButton.
    local cards = {}
    for _, button in ipairs(raw) do
        local ancestor = button.Parent
        local nested = false
        while ancestor and ancestor ~= scrolling do
            if ancestor:IsA("GuiButton") then
                for _, other in ipairs(raw) do
                    if other == ancestor then nested = true break end
                end
                if nested then break end
            end
            ancestor = ancestor.Parent
        end
        if not nested then cards[#cards + 1] = button end
    end

    table.sort(cards, function(a, b)
        return a.AbsolutePosition.Y < b.AbsolutePosition.Y
            or (a.AbsolutePosition.Y == b.AbsolutePosition.Y and a.AbsolutePosition.X < b.AbsolutePosition.X)
    end)
    return cards
end

C.directFuseCardMetadataMatches = function(button, target)
    local uuid = tostring(target and target.uuid or "")
    local name = tostring(target and target.name or ""):lower()
    if uuid == "" and name == "" then return false end

    local function scalarMatches(value)
        if typeof(value) ~= "string" then return false end
        local lower = value:lower()
        return (uuid ~= "" and value == uuid) or (name ~= "" and lower == name)
    end

    local nodes = {button}
    for _, child in ipairs(button:GetDescendants()) do nodes[#nodes + 1] = child end
    for _, node in ipairs(nodes) do
        if scalarMatches(node.Name) then return true end
        local okAttr, attrs = pcall(node.GetAttributes, node)
        if okAttr and type(attrs) == "table" then
            for _, value in pairs(attrs) do
                if scalarMatches(value) then return true end
            end
        end
        if node:IsA("StringValue") and scalarMatches(node.Value) then return true end
    end
    return false
end

C.selectNativeFuseUnit = function(target)
    local menu = C.selectUnitMenu()
    if not menu then return false, "SelectUnit menu missing" end
    local content = menu:FindFirstChild("Content")
    local scrolling = content and content:FindFirstChild("ScrollingFrame")
    if not scrolling then return false, "SelectUnit list missing" end

    local targetName = tostring(target and target.name or ""):lower()
    if targetName == "" then return false, "Target name missing" end

    local deadline = os.clock() + 5.0
    repeat
        local cards = C.visibleFuseCards(scrolling)
        if #cards > 0 then
            local metadataMatches, nameMatches, incomeMatches, callbackMatches = {}, {}, {}, {}

            for _, card in ipairs(cards) do
                if C.directFuseCardMetadataMatches(card, target) then
                    metadataMatches[#metadataMatches + 1] = card
                end

                local blob = C.textBlob(card)
                if blob:find(targetName, 1, true) then
                    nameMatches[#nameMatches + 1] = card
                end

                if C.cardIncomeTextMatchesTarget(card, target) then
                    incomeMatches[#incomeMatches + 1] = card
                end

                -- Callback evidence is deliberately collected separately. It is
                -- trusted ONLY when exactly one visible card matches. Shared
                -- controller state can otherwise make every card return true.
                if C.buttonCapturesFuseTarget(card, target) then
                    callbackMatches[#callbackMatches + 1] = card
                end
            end

            local chosen = nil
            local reason = nil

            if #metadataMatches == 1 then
                chosen, reason = metadataMatches[1], "metadata"
            elseif #nameMatches == 1 then
                chosen, reason = nameMatches[1], "name"
            elseif #incomeMatches == 1 then
                chosen, reason = incomeMatches[1], "income"
            elseif #incomeMatches > 1 and #callbackMatches > 0 then
                local intersection = {}
                for _, incomeCard in ipairs(incomeMatches) do
                    for _, callbackCard in ipairs(callbackMatches) do
                        if incomeCard == callbackCard then intersection[#intersection + 1] = incomeCard break end
                    end
                end
                if #intersection == 1 then
                    chosen, reason = intersection[1], "income+callback"
                end
            elseif #callbackMatches == 1 then
                chosen, reason = callbackMatches[1], "unique callback"
            end

            if chosen then
                C.setFuseStatus(("Matched %s · %s"):format(tostring(target.name), tostring(reason)))
                task.wait(0.30) -- intentionally slow: allow native picker state to settle
                if C.activateNativeButton(chosen) then
                    task.wait(0.45)
                    return true
                end
            elseif #incomeMatches > 1 then
                -- Duplicate cards are expected when the player owns multiple
                -- copies of the same selected unit. Do not stop: pick exactly
                -- one visible card for this target, then the round-robin plan
                -- moves to the next selected name/slot. Native Fusing removes
                -- or disables the committed copy before the next picker opens.
                local duplicate = incomeMatches[1]
                C.setFuseStatus(("Using %s · 1/%d"):format(
                    tostring(target.name), #incomeMatches
                ))
                task.wait(0.35)
                if C.activateNativeButton(duplicate) then
                    task.wait(0.50)
                    return true
                end
            end
        end

        task.wait(0.15)
    until os.clock() >= deadline

    return false, "Exact unit card not found: " .. tostring(target.name)
end

C.selectUnitMenuVisible = function()
    local selectMenu = C.selectUnitMenu()
    return selectMenu ~= nil and C.guiTreeVisible(selectMenu)
end

C.fireSpecificButtonSignal = function(button, signalName)
    if not (button and button:IsA("GuiButton")) then return false end
    local signal = button[signalName]
    if not signal then return false end

    local attempted = false
    if type(getconnections) == "function" then
        local okConnections, connections = pcall(getconnections, signal)
        if okConnections and type(connections) == "table" then
            for _, connection in ipairs(connections) do
                if connection then
                    if type(connection.Fire) == "function" then
                        attempted = pcall(connection.Fire, connection) or attempted
                    end
                    local fn = connection.Function
                    if type(fn) == "function" then
                        attempted = pcall(fn) or attempted
                    end
                end
            end
        end
    end

    if type(firesignal) == "function" then
        attempted = pcall(firesignal, signal) or attempted
    end
    return attempted
end

C.physicalGuiClick = function(button)
    if not (button and button:IsA("GuiButton") and C.guiTreeVisible(button)) then return false end
    local position = button.AbsolutePosition
    local size = button.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return false end
    local x = math.floor(position.X + size.X * 0.5)
    local y = math.floor(position.Y + size.Y * 0.5)

    -- Last-resort native input. This is only used when firing the RBX signals
    -- did not actually open SelectUnit (Delta/mobile can behave this way).
    local okVim, vim = pcall(game.GetService, game, "VirtualInputManager")
    if okVim and vim then
        local down = pcall(vim.SendMouseButtonEvent, vim, x, y, 0, true, game, 0)
        task.wait(0.035)
        local up = pcall(vim.SendMouseButtonEvent, vim, x, y, 0, false, game, 0)
        if down and up then return true end
    end

    local okVu, vu = pcall(game.GetService, game, "VirtualUser")
    if okVu and vu then
        local point = Vector2.new(x, y)
        local camera = workspace.CurrentCamera
        local cf = camera and camera.CFrame or CFrame.new()
        local down = pcall(vu.Button1Down, vu, point, cf)
        task.wait(0.035)
        local up = pcall(vu.Button1Up, vu, point, cf)
        return down and up
    end
    return false
end

C.openNativeFuseSlot = function(slot)
    if C.selectUnitMenuVisible() then return true end
    if not (slot and slot:IsA("GuiButton")) then return false end

    -- The visible + can be handled by a nested button on some UPD5 layouts.
    -- Try descendants first, then the UnitN container itself.
    local candidates = {}
    for _, obj in ipairs(slot:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Active ~= false then
            candidates[#candidates + 1] = obj
        end
    end
    candidates[#candidates + 1] = slot

    for _, button in ipairs(candidates) do
        -- A real tap emits MouseButton1Click and Activated. Try both and verify
        -- the EFFECT rather than treating pcall/firesignal success as a click.
        C.fireSpecificButtonSignal(button, "MouseButton1Click")
        task.wait(0.06)
        if C.selectUnitMenuVisible() then return true end

        C.fireSpecificButtonSignal(button, "Activated")
        task.wait(0.06)
        if C.selectUnitMenuVisible() then return true end
    end

    -- Delta/mobile fallback: physically press the centre of the visible +.
    for _, button in ipairs(candidates) do
        C.physicalGuiClick(button)
        local deadline = os.clock() + 0.55
        repeat
            task.wait(0.05)
            if C.selectUnitMenuVisible() then return true end
        until os.clock() >= deadline
    end

    return false
end

C.fillNativeFuseSlot = function(slotIndex, target)
    local menu = C.fusingMenu()
    local slot = menu and menu:FindFirstChild("Unit" .. tostring(slotIndex))
    if not (slot and slot:IsA("GuiButton")) then return false, "Fuse slot missing" end

    local before = select(1, C.fuseProgressValue())
    if not C.openNativeFuseSlot(slot) then
        return false, "Cannot open unit picker " .. tostring(slotIndex) .. "/3"
    end

    -- Wait for the native list to populate AFTER the picker is really visible.
    local populatedDeadline = os.clock() + 2.5
    repeat
        local selectMenu = C.selectUnitMenu()
        local content = selectMenu and selectMenu:FindFirstChild("Content")
        local scrolling = content and content:FindFirstChild("ScrollingFrame")
        if scrolling then
            for _, obj in ipairs(scrolling:GetDescendants()) do
                if obj:IsA("GuiButton") and obj.Visible then
                    populatedDeadline = 0
                    break
                end
            end
        end
        if populatedDeadline == 0 then break end
        task.wait(0.05)
    until os.clock() >= populatedDeadline

    local ok, err = C.selectNativeFuseUnit(target)
    if not ok then return false, err end

    local confirmDeadline = os.clock() + 2.5
    repeat
        task.wait(0.05)
        local now = select(1, C.fuseProgressValue())
        if now > before then return true end
    until os.clock() >= confirmDeadline

    return false, "Selection did not register"
end

-- Post-fuse native recovery.
-- UPD 5 leaves the fused result on AuraFuseMachine. The native machine must
-- receive "Put Back" before another fuse can begin. After that, use the game's
-- own Home button so the Fusing proximity/UI state is rebuilt cleanly.
C.nativeButtonSearchText = function(button)
    if not (button and button:IsA("GuiButton")) then return "" end
    local values = {tostring(button.Name or "")}
    if button:IsA("TextButton") then
        values[#values + 1] = tostring(button.Text or "")
    end
    for _, obj in ipairs(button:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible ~= false then
            values[#values + 1] = tostring(obj.Text or "")
        end
    end
    return table.concat(values, " | ")
end

C.nativeTextKey = function(value)
    return tostring(value or ""):lower():gsub("[^%w]", "")
end

C.nativeButtonVisible = function(button)
    if not (button and button:IsA("GuiButton") and button.Visible ~= false) then return false end
    local current = button
    while current and current ~= game do
        if current:IsA("GuiObject") and current.Visible == false then return false end
        if current:IsA("LayerCollector") and current.Enabled == false then return false end
        current = current.Parent
    end
    return true
end

C.findNativeTextButton = function(roots, target)
    local wanted = C.nativeTextKey(target)
    local best, bestScore = nil, -1
    for _, rootObject in ipairs(roots or {}) do
        if rootObject then
            local scan = {rootObject}
            for _, obj in ipairs(rootObject:GetDescendants()) do
                scan[#scan + 1] = obj
            end
            for _, button in ipairs(scan) do
                if button:IsA("GuiButton") and C.nativeButtonVisible(button) then
                    -- Never mistake AliceHUB's own controls for a native game button.
                    local aliceGui = button:FindFirstAncestor("AliceHUB_AnimeDice_NativeUI")
                    if not aliceGui then
                        local score = 0
                        local nameKey = C.nativeTextKey(button.Name)
                        if nameKey == wanted then score = math.max(score, 90) end
                        if nameKey == wanted .. "button" or nameKey == "button" .. wanted then
                            score = math.max(score, 82)
                        end
                        if button:IsA("TextButton") then
                            local textKey = C.nativeTextKey(button.Text)
                            if textKey == wanted then score = math.max(score, 100) end
                        end
                        for _, child in ipairs(button:GetDescendants()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") then
                                local textKey = C.nativeTextKey(child.Text)
                                if textKey == wanted then score = math.max(score, 96) end
                            end
                        end
                        -- Safe fallback for names such as PutBackButton.
                        if score == 0 and #wanted >= 4 and nameKey:find(wanted, 1, true) then
                            score = 60
                        end
                        if score > bestScore then
                            best, bestScore = button, score
                        end
                    end
                end
            end
        end
    end
    if bestScore <= 0 then return nil end
    return best
end

C.clickNativeButtonVerified = function(button, verifyFn)
    if not (button and button:IsA("GuiButton")) then return false end

    local attempted = C.activateNativeButton(button)
    local deadline = os.clock() + 0.85
    repeat
        task.wait(0.05)
        if type(verifyFn) == "function" then
            local ok, verified = pcall(verifyFn)
            if ok and verified == true then return true end
        elseif attempted then
            return true
        end
    until os.clock() >= deadline

    -- Delta/mobile sometimes exposes the signals but the controller does not
    -- advance. Fall back to a real screen tap only when the effect was absent.
    local physicallyClicked = false
    if type(C.physicalGuiClick) == "function" and C.nativeButtonVisible(button) then
        physicallyClicked = C.physicalGuiClick(button)
    end
    if not physicallyClicked and attempted and type(verifyFn) ~= "function" then return true end

    deadline = os.clock() + 1.25
    repeat
        task.wait(0.05)
        if type(verifyFn) == "function" then
            local ok, verified = pcall(verifyFn)
            if ok and verified == true then return true end
        elseif physicallyClicked then
            return true
        end
    until os.clock() >= deadline

    return false
end

C.putBackFuseResult = function(timeout)
    local deadline = os.clock() + (tonumber(timeout) or 6)
    repeat
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local nativeRoot = pg and pg:FindFirstChild("Root")
        local machine = workspace:FindFirstChild("AuraFuseMachine")
        local button = C.findNativeTextButton({machine, nativeRoot}, "Put Back")
        if button then
            C.setFuseStatus("Putting fused unit back")
            local original = button
            local ok = C.clickNativeButtonVerified(button, function()
                if not original.Parent or not C.nativeButtonVisible(original) then return true end
                local again = C.findNativeTextButton({machine, nativeRoot}, "Put Back")
                return again == nil
            end)
            if ok then
                task.wait(0.25)
                return true
            end
        end
        task.wait(0.10)
    until os.clock() >= deadline
    return false
end

C.returnHomeAfterFuse = function(timeout)
    local deadline = os.clock() + (tonumber(timeout) or 4)
    repeat
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local nativeRoot = pg and pg:FindFirstChild("Root")
        local button = C.findNativeTextButton({nativeRoot}, "Home")
        if button then
            C.setFuseStatus("Returning Home")
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            local before = rootPart and rootPart.Position
            local fusePart = C.fusingAccessPart()
            local ok = C.clickNativeButtonVerified(button, function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                if before and (hrp.Position - before).Magnitude >= 8 then return true end
                if fusePart and (hrp.Position - fusePart.Position).Magnitude >= 18 then return true end
                return false
            end)
            if ok then
                -- Home owns the final position now; never teleport back to the
                -- pre-fuse CFrame after the native Home action succeeds.
                C.FuseRuntime.returnCFrame = nil
                task.wait(0.35)
                return true
            end
        end
        task.wait(0.10)
    until os.clock() >= deadline
    return false
end

C.finishNativeFuseCycle = function()
    -- Result can arrive before the machine finishes its short reveal animation,
    -- therefore Put Back gets its own wait window.
    local putBack = C.putBackFuseResult(6)
    local home = C.returnHomeAfterFuse(4)

    if not home then
        -- If the native Home control is temporarily unavailable, at least leave
        -- the Fusing zone using the position saved before entering it.
        C.leaveFusingArea()
    end

    return putBack, home
end

C.runNativeFuseOnce = function()
    if C.FuseRuntime.busy then return false, "Fuse busy" end
    C.FuseRuntime.busy = true

    local ok, result, extra = pcall(function()
        refreshRemotes()
        if not (C.FuseRE and C.FuseResultRE) then return false, "FusingService missing" end

        local triplet, why = C.chooseFuseTriplet()
        if not triplet then return false, why end

        if not C.openNativeFusingMenu() then return false, "Cannot open native Fusing menu" end
        task.wait(0.45)

        local progress = select(1, C.fuseProgressValue())
        if progress ~= 0 then
            C.closeNativeFusingMenu()
            task.wait(0.12)
            if not C.openNativeFusingMenu() then return false, "Cannot reset native Fusing menu" end
            progress = select(1, C.fuseProgressValue())
            if progress ~= 0 then return false, "Fusing menu already has selected units" end
        end

        for index = 1, 3 do
            C.setFuseStatus("Selecting " .. tostring(index) .. "/3 · " .. tostring(triplet[index].name))
            local selected, err = C.fillNativeFuseSlot(index, triplet[index])
            if not selected then return false, err end
            task.wait(0.55) -- accuracy > speed; let native state fully commit before next slot
        end

        local count = select(1, C.fuseProgressValue())
        if count ~= 3 then return false, "Native progress is not 3/3" end

        local menu = C.fusingMenu()
        local roll = menu and menu:FindFirstChild("Roll")
        if not (roll and roll:IsA("GuiButton")) then return false, "Fuse button missing" end

        C.FuseRuntime.lastResult = nil
        C.FuseRuntime.lastResultAt = 0
        C.setFuseStatus("Fusing 3/3")
        if not C.activateNativeButton(roll) then return false, "Native Fuse button could not be activated" end

        local deadline = os.clock() + 12
        repeat
            task.wait(0.10)
            if C.FuseRuntime.lastResultAt > 0 then
                return true, C.FuseRuntime.lastResult or "Completed"
            end
            local current = select(1, C.fuseProgressValue())
            if current == 0 then return true, "Completed" end
        until os.clock() >= deadline

        return false, "No Result yet (possibly waiting for cash / animation)"
    end)

    local postSummary = nil
    if ok and result == true then
        local postOk, putBackOk, homeOk = pcall(C.finishNativeFuseCycle)
        if postOk then
            local parts = {}
            parts[#parts + 1] = putBackOk and "Put Back" or "Put Back not found"
            parts[#parts + 1] = homeOk and "Home" or "Home fallback"
            postSummary = table.concat(parts, " · ")
        else
            postSummary = "post-fuse recovery error"
            -- Recovery must never strand the player at the machine.
            C.leaveFusingArea()
        end
    end

    C.FuseRuntime.busy = false

    -- Do not leave a dead native menu floating after a failed selection/fuse.
    if not ok or result ~= true then
        pcall(C.closeNativeFusingMenu)
        task.wait(0.06)
        C.leaveFusingArea()
    end

    if not ok then return false, tostring(result) end
    if result == true and postSummary then
        return true, tostring(extra or "Completed") .. " · " .. postSummary
    end
    return result, extra
end

if C.FuseResultRE and C.FuseResultRE:IsA("RemoteEvent") then
    rememberConnection(C.FuseResultRE.OnClientEvent:Connect(function(...)
        local args = table.pack(...)
        C.FuseRuntime.lastResultAt = os.clock()
        C.FuseRuntime.lastResult = args.n > 0 and shortResult(args[1]) or "Result received"
        C.setFuseStatus("Result: " .. tostring(C.FuseRuntime.lastResult))
        task.delay(0.4, function()
            pcall(updateInventoryManagerSummary)
            pcall(C.refreshFuseInfo, true)
        end)
    end))
end

addInput(C.UnitFuseFilter, "AD_FuseMinChance", "Minimum 1 in X", "", "e.g. 100, 1k, 1m (empty = no min)", function()
    pcall(C.refreshFuseInfo, true)
end)
addInput(C.UnitFuseFilter, "AD_FuseMaxChance", "Maximum 1 in X", "", "e.g. 1t, 1qd (empty = no max)", function()
    pcall(C.refreshFuseInfo, true)
end)
addInput(C.UnitFuseFilter, "AD_FuseMaxIncome", "Maximum Income", "", "e.g. 1t, 500b (empty = no max)", function()
    pcall(C.refreshFuseInfo, true)
end)
C.FuseInfoLabel = C.UnitFuseFilter:AddLabel("Eligible: loading...", true)

C.FuseStatusLabel = C.UnitFuseAuto:AddLabel("Fuse: Idle", true)
addToggle(C.UnitFuseAuto, "AD_AutoFuse", "Auto Fuse", false,
    "Automatically fuses backpack units that match every active Fuse Filter.",
    function(enabled)
        if enabled then
            startLoop("AD_AutoFuse", function()
                local ok, reason = C.runNativeFuseOnce()
                if ok then
                    C.setFuseStatus("Completed · waiting next cycle")
                    pcall(C.refreshFuseInfo, true)
                else
                    C.setFuseStatus(reason or "Waiting")
                end
            end, 8)
        else
            stopLoop("AD_AutoFuse")
            C.setFuseStatus("Disabled")
        end
    end)
C.UnitFuseAuto:AddButton({Text = "Fuse Once", Func = function()
    task.spawn(function()
        local ok, reason = C.runNativeFuseOnce()
        C.setFuseStatus(ok and ("Completed · " .. tostring(reason or "OK")) or tostring(reason or "Failed"))
        pcall(C.refreshFuseInfo, true)
        notify(ok and "Fuse completed" or ("Fuse: " .. tostring(reason)), 5)
    end)
end})
C.UnitFuseAuto:AddButton({Text = "Refresh Info", Func = function()
    C.refreshFuseInfo(false)
end})
C.UnitFuseAuto:AddLabel("All active filters are combined. Empty fields do not limit that stat. Locked, equipped, plot/tower and Limited units stay protected.", true)

task.defer(function() pcall(C.refreshFuseInfo, true) end)
if State.AD_AutoFuse == true then
    task.defer(function()
        startLoop("AD_AutoFuse", function()
            local ok, reason = C.runNativeFuseOnce()
            if ok then
                C.setFuseStatus("Completed · waiting next cycle")
                pcall(C.refreshFuseInfo, true)
            else
                C.setFuseStatus(reason or "Waiting")
            end
        end, 8)
    end)
end

-- ============================================================
-- Trade
-- ============================================================
C.TradePlayers = C.Tabs.Trade:AddLeftGroupbox("Players")
C.TradeInventory = C.Tabs.Trade:AddLeftGroupbox("Inventory Scanner")
C.TradeActions = C.Tabs.Trade:AddRightGroupbox("Trade Actions")
C.TradeLive = C.Tabs.Trade:AddRightGroupbox("Live Trade")

C.TradeStatusLabel = C.TradeLive:AddLabel("Trade: Idle", true)
C.TradeSelectionLabel = C.TradeInventory:AddLabel("Selected: none", true)

local function updateTradeStatusLabel()
    local partner = C.TradeRuntime.partner and (C.TradeRuntime.partner.DisplayName .. " (@" .. C.TradeRuntime.partner.Name .. ")") or "-"
    local incoming = C.TradeRuntime.incoming and (C.TradeRuntime.incoming.DisplayName .. " (@" .. C.TradeRuntime.incoming.Name .. ")") or "-"
    local ownCount = tableCount(C.TradeRuntime.ownOffer)
    local otherCount = type(C.TradeRuntime.otherOffer) == "table" and #C.TradeRuntime.otherOffer or 0
    local countdown = ""
    if C.TradeRuntime.phase == "Countdown" and tonumber(C.TradeRuntime.countdownEndsAt) then
        countdown = string.format("\nCountdown: %.1fs", math.max(0, C.TradeRuntime.countdownEndsAt - workspace:GetServerTimeNow()))
    end
    local text = string.format(
        "Status: %s\nPartner: %s\nIncoming: %s\nPhase: %s\nOffer: you %d | them %d\nReady: %s / %s | Confirm: %s / %s%s",
        tostring(C.TradeRuntime.status), partner, incoming, tostring(C.TradeRuntime.phase), ownCount, otherCount,
        C.TradeRuntime.ownReady and "YES" or "NO", C.TradeRuntime.otherReady and "YES" or "NO",
        C.TradeRuntime.ownAccepted and "YES" or "NO", C.TradeRuntime.otherAccepted and "YES" or "NO",
        countdown
    )
    if C.TradeStatusLabel and type(C.TradeStatusLabel.SetText) == "function" then
        pcall(C.TradeStatusLabel.SetText, C.TradeStatusLabel, text)
    end
end

local function updateTradeSelectionLabel()
    local key, item = selectedTradeItem()
    if not key or type(item) ~= "table" then
        pcall(function() C.TradeSelectionLabel:SetText("Selected: none") end)
        return
    end
    local attr = type(item.attributes) == "table" and item.attributes or {}
    local config = entryConfigFor(item)
    local kind = config and config.kind or (isUUID(key) and "Unit" or "Other")
    local details = {
        "Selected: " .. tostring(item.name),
        "Kind: " .. tostring(kind) .. " | Amount: " .. tostring(item.amount or 1),
        "Key: " .. tostring(key),
    }
    if kind == "Unit" then
        details[#details + 1] = "Rarity: " .. tostring(getUnitRarity(item))
        details[#details + 1] = ("Mutation: %s | Trait: %s | Grade: %s | Level: %s"):format(
            tostring(attr.mutation or "-"), tostring(attr.trait or "-"), tostring(attr.grade or "-"), tostring(attr.level or 1)
        )
        details[#details + 1] = "Locked: " .. tostring(attr.locked == true)
        if type(config) == "table" then
            local stats = {}
            if type(config.chance) == "function" then
                local ok, value = pcall(config.chance, attr)
                if ok and tonumber(value) then stats[#stats + 1] = "1 in " .. compactNumber(value) end
            end
            if type(config.income) == "function" then
                local ok, value = pcall(config.income, attr)
                if ok and tonumber(value) then stats[#stats + 1] = "$" .. compactNumber(value) .. "/s" end
            end
            if type(config.damage) == "function" then
                local ok, value = pcall(config.damage, attr)
                if ok and tonumber(value) then stats[#stats + 1] = "DMG " .. compactNumber(value) end
            end
            if #stats > 0 then details[#details + 1] = table.concat(stats, " | ") end
        end
    end
    pcall(function() C.TradeSelectionLabel:SetText(table.concat(details, "\n")) end)
end

local function refreshTradePlayers()
    C.TradePlayerLabelToPlayer = {}
    local values = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local label = player.DisplayName .. " (@" .. player.Name .. ")"
            C.TradePlayerLabelToPlayer[label] = player
            values[#values + 1] = label
        end
    end
    table.sort(values)
    if #values == 0 then values[1] = "No Player" end
    local option = Options.AD_TradePlayer
    if option and type(option.SetValues) == "function" then
        pcall(option.SetValues, option, values)
    end
    if not C.TradePlayerLabelToPlayer[State.AD_TradePlayer] then
        local first = values[1]
        State.AD_TradePlayer = first
        if option and type(option.SetValue) == "function" then pcall(option.SetValue, option, first) end
    end
end

local function refreshTradeInventory()
    local values = buildTradeInventoryLabels()
    local option = Options.AD_TradeItem
    if option and type(option.SetValues) == "function" then
        pcall(option.SetValues, option, values)
    end
    if not C.TradeLabelToKey[State.AD_TradeItem] then
        local first = values[1]
        State.AD_TradeItem = first
        if option and type(option.SetValue) == "function" then pcall(option.SetValue, option, first) end
    end
    updateTradeSelectionLabel()
end

addDropdown(C.TradePlayers, "AD_TradePlayer", "Target Player", {"No Player"}, "No Player", false)
C.TradePlayers:AddButton({Text = "Refresh Players", Func = refreshTradePlayers})
C.TradePlayers:AddLabel("Trade terbuka setelah 1.000 roll dan umur akun 14 hari.", true)
C.TradePlayers:AddButton({Text = "Send Trade Request", Func = function()
    local player = C.TradePlayerLabelToPlayer[State.AD_TradePlayer]
    if not player or player.Parent ~= Players then
        notify("Select a player first", 4)
        refreshTradePlayers()
        return
    end
    C.TradeRuntime.status = "Requesting " .. player.Name
    updateTradeStatusLabel()
    fire(C.TradeRequestRE, player)
end})
addToggle(C.TradePlayers, "AD_TradeRequestsEnabled", "Receive Trade Requests", true, nil, function(value)
    fire(C.TradeRequestsEnabledRE, value)
end)
addToggle(C.TradePlayers, "AD_AutoAcceptTrade", "Auto Accept Incoming Request", false,
    "Hanya menerima request. Ready dan Confirm tetap manual.")
addToggle(C.TradePlayers, "AD_AutoAcceptOnlySelected", "Auto Accept Only Selected Player", true,
    "Jika aktif, auto trade hanya menerima player yang dipilih.")
addToggle(C.TradePlayers, "AD_TradeReceiverMode", "Auto Receiver", false,
    "Akun penerima: terima request, Ready saat offer lawan sudah berisi item, lalu Confirm otomatis.", function(value)
    if value then
        fire(C.TradeRequestsEnabledRE, true)
    end
end)
C.TradePlayers:AddLabel("Auto Receiver cocok untuk akun penerima. Pilih akun pengirim jika Only Selected aktif.", true)
C.TradePlayers:AddButton({Text = "Accept Incoming", Func = function()
    if C.TradeRuntime.incoming then fire(C.TradeRespondRE, true) else notify("No incoming request") end
end})
C.TradePlayers:AddButton({Text = "Decline Incoming", Func = function()
    if C.TradeRuntime.incoming then fire(C.TradeRespondRE, false) else notify("No incoming request") end
end})

addInput(C.TradeInventory, "AD_TradeSearch", "Search", "", "name / trait / grade / mutation", function()
    task.defer(refreshTradeInventory)
end)
addToggle(C.TradeInventory, "AD_TradeAutoRefresh", "Auto Refresh Inventory", true,
    "Refresh otomatis saat inventory berubah.")
addDropdown(C.TradeInventory, "AD_TradeKind", "Kind", {"All", "Unit", "Boost", "Spin", "Token", "Other"}, "All", false, function()
    task.defer(refreshTradeInventory)
end)
addDropdown(C.TradeInventory, "AD_TradeItem", "Inventory Item", {"No Item"}, "No Item", false, function()
    task.defer(updateTradeSelectionLabel)
end)

local function visibleTradeInventoryKeys(unitOnly)
    local labels = buildTradeInventoryLabels()
    local result, seen = {}, {}
    local data = getData()
    for _, label in ipairs(labels) do
        local key = C.TradeLabelToKey[label]
        local item = key and data and data.Inventory and data.Inventory[key] or nil
        if key and item and not seen[key] and (not unitOnly or isUUID(key)) then
            seen[key] = true
            result[#result + 1] = key
        end
    end
    return result
end

C.TradeInventory:AddButton({Text = "Refresh Inventory", Func = refreshTradeInventory})
C.TradeInventory:AddButton({Text = "Copy Key / UUID", Func = function()
    local key = selectedTradeKey()
    if not key then notify("No item selected"); return end
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, tostring(key))
    elseif type(toclipboard) == "function" then copied = pcall(toclipboard, tostring(key)) end
    notify(copied and "Key copied" or tostring(key), 4)
end})
C.TradeInventory:AddButton({Text = "Lock Selected Unit", Func = function()
    local key = selectedTradeKey()
    if not key or not isUUID(key) then notify("Select a unit first"); return end
    fire(C.UnitSetLockedRE, {[key] = true})
    task.delay(0.25, refreshTradeInventory)
end})
C.TradeInventory:AddButton({Text = "Unlock Selected Unit", Func = function()
    local key = selectedTradeKey()
    if not key or not isUUID(key) then notify("Select a unit first"); return end
    fire(C.UnitSetLockedRE, {[key] = false})
    task.delay(0.25, refreshTradeInventory)
end})
C.TradeInventory:AddButton({Text = "Carry / Equip Selected Unit", Func = function()
    local key = selectedTradeKey()
    if not key or not isUUID(key) then notify("Select a unit first"); return end
    task.spawn(function()
        local ok, result = invoke(C.UnitEquipRF, key)
        setLastAction("Carry Unit: " .. tostring(ok and result == true))
        notify(ok and result == true and "Selected unit equipped" or ("Equip rejected: " .. shortResult(result)), 4)
    end)
end})
C.TradeInventory:AddButton({Text = "Unequip Held Unit", Func = function()
    task.spawn(function()
        local ok, result = invoke(C.UnitUnequipRF)
        notify(ok and result == true and "Held unit unequipped" or ("Unequip: " .. shortResult(result)), 4)
    end)
end})
addSlider(C.TradeInventory, "AD_InventoryPlotSlot", "Plot Slot", 1, 13, 1, 0, "")
C.TradeInventory:AddButton({Text = "Interact Selected Plot Slot", Func = function()
    local slot = math.max(1, math.floor(tonumber(State.AD_InventoryPlotSlot) or 1))
    fire(C.InteractSlotRE, slot)
    setLastAction("Plot Interact Slot " .. tostring(slot))
end})
C.TradeInventory:AddLabel("Pilih unit, Equip, lalu pilih Plot Slot untuk memasangnya.", true)
C.TradeInventory:AddButton({Text = "Lock Visible Units", Func = function()
    local data = getData()
    local map = {}
    for _, key in ipairs(visibleTradeInventoryKeys(true)) do
        local item = data and data.Inventory and data.Inventory[key]
        local attr = type(item) == "table" and type(item.attributes) == "table" and item.attributes or {}
        if attr.locked ~= true then map[key] = true end
    end
    local count = tableCount(map)
    if count > 0 then fire(C.UnitSetLockedRE, map) end
    notify("Visible units locked: " .. tostring(count), 5)
    task.delay(0.25, refreshTradeInventory)
end})
C.TradeInventory:AddButton({Text = "Unlock Visible Units", Func = function()
    local data = getData()
    local map = {}
    for _, key in ipairs(visibleTradeInventoryKeys(true)) do
        local item = data and data.Inventory and data.Inventory[key]
        local attr = type(item) == "table" and type(item.attributes) == "table" and item.attributes or {}
        if attr.locked == true then map[key] = false end
    end
    local count = tableCount(map)
    if count > 0 then fire(C.UnitSetLockedRE, map) end
    for key in pairs(map) do C.FavoriteRuntimeLocks[key] = nil end
    notify("Visible units unlocked: " .. tostring(count), 5)
    task.delay(0.25, refreshTradeInventory)
end})
C.TradeInventory:AddButton({Text = "Sell Visible Units", Func = function()
    if tostring(State.AD_TradeKind or "All") ~= "Unit" then
        notify("Pilih Kind = Unit sebelum menjual banyak unit.", 6)
        return
    end
    local ids = visibleTradeInventoryKeys(true)
    if #ids == 0 then notify("No visible units to sell", 4); return end
    task.spawn(function()
        local ok, result = invoke(C.SellInventoryRF, ids)
        notify(ok and ("Sell visible: " .. shortResult(result)) or ("Sell failed: " .. tostring(result)), 6)
        task.delay(0.3, refreshTradeInventory)
    end)
end})
C.TradeInventory:AddLabel("Bulk mengikuti Search + Kind. Unit locked atau terpasang tetap aman.", true)

addInput(C.TradeActions, "AD_TradeAmount", "Offer Amount", "1", "Type amount 1 - 100000", function(value)
    local n = tonumber(value)
    if n then
        n = math.clamp(math.floor(n), 1, 100000)
        setState("AD_TradeAmount", tostring(n))
    end
end)
local function currentOwnOfferAmount(key)
    local offer = type(C.TradeRuntime.ownOffer) == "table" and C.TradeRuntime.ownOffer or nil
    return offer and (tonumber(offer[key]) or 0) or 0
end

C.tradeOfferMoved = function(before, after, direction)
    if direction > 0 then
        return math.max(0, (tonumber(after) or 0) - (tonumber(before) or 0))
    end
    return math.max(0, (tonumber(before) or 0) - (tonumber(after) or 0))
end

C.sendTradeChunks = function(key, direction, requestedAmount)
    local amount = math.clamp(math.floor(tonumber(requestedAmount) or 1), 1, 100000)
    local remaining = amount
    local chunks = {1000, 100, 10, 1}

    for _, chunk in ipairs(chunks) do
        local unsupported = false
        while Runtime.alive and remaining >= chunk and not unsupported do
            local before = currentOwnOfferAmount(key)
            fire(C.TradeChangeOfferRE, key, direction * chunk)

            local deadline = os.clock() + (chunk == 1 and 0.30 or 0.45)
            local after = before
            repeat
                task.wait(0.03)
                after = currentOwnOfferAmount(key)
            until not Runtime.alive or after ~= before or os.clock() >= deadline
            if not Runtime.alive then return amount - remaining, remaining end

            local moved = C.tradeOfferMoved(before, after, direction)
            if moved <= 0 then
                -- This chunk size is not accepted on the current server; try the next size.
                unsupported = true
            else
                remaining = math.max(0, remaining - math.min(remaining, moved))
                -- If a large chunk was clamped (for example 1000 -> 1), drop down
                -- instead of hammering the same unsupported size repeatedly.
                if chunk > 1 and moved < chunk then unsupported = true end
                task.wait(chunk == 1 and 0.105 or 0.045)
            end
        end
    end

    return amount - remaining, remaining
end

local function changeTradeOffer(delta)
    local key, item = selectedTradeItem()
    if not key or type(item) ~= "table" then notify("Select inventory item first"); return end
    if delta > 0 and tostring(item.name) == "Tickets" then
        notify("Tickets are server-marked untradeable", 5)
        return
    end

    local amount = math.clamp(math.floor(tonumber(State.AD_TradeAmount) or 1), 1, 100000)
    if isUUID(key) then amount = 1 end

    task.spawn(function()
        local moved, remaining = C.sendTradeChunks(key, delta, amount)
        if remaining <= 0 then
            notify((delta > 0 and "Added " or "Removed ") .. tostring(moved) .. " via 1000/100/10/1 chunks", 4)
        else
            notify("Trade moved " .. tostring(moved) .. " / " .. tostring(amount) .. " · server limited remainder " .. tostring(remaining), 5)
        end
    end)
end
C.TradeActions:AddButton({Text = "+ Add Selected", Func = function() changeTradeOffer(1) end})
C.TradeActions:AddButton({Text = "- Remove Selected", Func = function() changeTradeOffer(-1) end})
C.TradeActions:AddButton({Text = "Bulk Add Visible (1 each)", Func = function()
    if C.TradeRuntime.phase ~= "Offer" then notify("Bulk add hanya bisa saat fase Offer", 5); return end
    local current = tableCount(C.TradeRuntime.ownOffer)
    local room = math.max(0, 20 - current)
    if room <= 0 then notify("Trade already has 20 unique entries", 5); return end
    local data = getData()
    local added = 0
    task.spawn(function()
        for _, key in ipairs(visibleTradeInventoryKeys(false)) do
            if added >= room or not Runtime.alive then break end
            local item = data and data.Inventory and data.Inventory[key]
            if item and tostring(item.name) ~= "Tickets" and not C.TradeRuntime.ownOffer[key] then
                fire(C.TradeChangeOfferRE, key, 1)
                added += 1
                task.wait(0.12)
            end
        end
        notify("Bulk trade entries added: " .. tostring(added), 5)
    end)
end})
C.TradeActions:AddButton({Text = "Clear My Offer", Func = function()
    if type(C.TradeRuntime.ownOffer) ~= "table" or next(C.TradeRuntime.ownOffer) == nil then notify("Your offer is empty", 4); return end
    local snapshot = {}
    for key, amount in pairs(C.TradeRuntime.ownOffer) do snapshot[key] = tonumber(amount) or 0 end
    task.spawn(function()
        local removed = 0
        for key, amount in pairs(snapshot) do
            if not Runtime.alive then return end
            local target = math.min(math.max(0, math.floor(amount)), 100000)
            local moved = C.sendTradeChunks(key, -1, target)
            removed += tonumber(moved) or 0
        end
        notify("Offer removed: " .. tostring(removed) .. " via chunks", 5)
    end)
end})
C.TradeActions:AddButton({Text = "Ready / Accept", Func = function() fire(C.TradeAdvanceRE) end})
C.TradeActions:AddButton({Text = "Cancel Trade", Func = function() fire(C.TradeCancelRE) end})
C.TradeActions:AddLabel("Maksimal 20 jenis item per trade.", true)

C.TradeEventConnection = nil

local function tradeAutoPartnerAllowed(player)
    if State.AD_AutoAcceptOnlySelected ~= true then return true end
    local selected = C.TradePlayerLabelToPlayer[State.AD_TradePlayer]
    return selected ~= nil and player == selected
end

local function tradeHasIncomingItems()
    return type(C.TradeRuntime.otherOffer) == "table" and next(C.TradeRuntime.otherOffer) ~= nil
end

local function runReceiverStep()
    if State.AD_TradeReceiverMode ~= true then return end
    if not tradeAutoPartnerAllowed(C.TradeRuntime.partner) then return end

    local now = os.clock()
    if now - (tonumber(C.TradeRuntime.lastAutoAdvanceAt) or 0) < 0.45 then return end

    local phase = tostring(C.TradeRuntime.phase or ""):lower()
    local shouldAdvance = false

    if phase:find("offer", 1, true) then
        shouldAdvance = tradeHasIncomingItems() and C.TradeRuntime.ownReady ~= true
    elseif phase:find("confirm", 1, true) or phase:find("accept", 1, true) then
        shouldAdvance = C.TradeRuntime.ownAccepted ~= true
    end

    if not shouldAdvance then return end

    C.TradeRuntime.lastAutoAdvanceAt = now
    task.delay(0.12, function()
        if Runtime.alive and State.AD_TradeReceiverMode == true then
            fire(C.TradeAdvanceRE)
        end
    end)
end

local function connectTradeEvent()
    if C.TradeEventConnection then return true end
    refreshRemotes()
    if not C.TradeEventRE or not C.TradeEventRE:IsA("RemoteEvent") then return false end
    C.TradeEventConnection = rememberConnection(C.TradeEventRE.OnClientEvent:Connect(function(eventName, payload)
        payload = type(payload) == "table" and payload or {}
        if eventName == "RequestReceived" then
            C.TradeRuntime.incoming = payload.player
            C.TradeRuntime.status = "Incoming request"
            if State.AD_AutoAcceptTrade == true or State.AD_TradeReceiverMode == true then
                if tradeAutoPartnerAllowed(payload.player) then
                    task.defer(function() fire(C.TradeRespondRE, true) end)
                end
            end
        elseif eventName == "RequestSent" then
            C.TradeRuntime.status = "Request sent"
        elseif eventName == "RequestClosed" or eventName == "RequestExpired" then
            if C.TradeRuntime.incoming == payload.player then C.TradeRuntime.incoming = nil end
            C.TradeRuntime.status = eventName
        elseif eventName == "Started" then
            C.TradeRuntime.incoming = nil
            C.TradeRuntime.partner = payload.partner
            C.TradeRuntime.status = "Started"
            C.TradeRuntime.phase = "Offer"
            C.TradeRuntime.lastAutoAdvanceAt = 0
            task.delay(0.2, refreshTradeInventory)
        elseif eventName == "Updated" then
            C.TradeRuntime.partner = payload.partner or C.TradeRuntime.partner
            C.TradeRuntime.status = "Active"
            C.TradeRuntime.phase = tostring(payload.phase or "Offer")
            C.TradeRuntime.ownOffer = type(payload.ownOffer) == "table" and payload.ownOffer or {}
            C.TradeRuntime.otherOffer = type(payload.otherOffer) == "table" and payload.otherOffer or {}
            C.TradeRuntime.ownReady = payload.ownReady == true
            C.TradeRuntime.otherReady = payload.otherReady == true
            C.TradeRuntime.ownAccepted = payload.ownAccepted == true
            C.TradeRuntime.otherAccepted = payload.otherAccepted == true
            C.TradeRuntime.countdownEndsAt = payload.countdownEndsAt
            runReceiverStep()
        elseif eventName == "Ended" then
            C.TradeRuntime.status = "Ended: " .. tostring(payload.reason or "Unknown")
            C.TradeRuntime.phase = "None"
            C.TradeRuntime.partner = nil
            C.TradeRuntime.ownOffer = {}
            C.TradeRuntime.otherOffer = {}
            C.TradeRuntime.ownReady = false
            C.TradeRuntime.otherReady = false
            C.TradeRuntime.ownAccepted = false
            C.TradeRuntime.otherAccepted = false
            C.TradeRuntime.countdownEndsAt = nil
            C.TradeRuntime.lastAutoAdvanceAt = 0
            task.delay(0.3, refreshTradeInventory)
        end
        updateTradeStatusLabel()
    end))
    return true
end

task.spawn(function()
    local deadline = os.clock() + 30
    while Runtime.alive and not connectTradeEvent() and os.clock() < deadline do
        task.wait(0.5)
    end
end)

rememberConnection(Players.PlayerAdded:Connect(function() task.defer(refreshTradePlayers) end))
rememberConnection(Players.PlayerRemoving:Connect(function() task.defer(refreshTradePlayers) end))
task.defer(function()
    refreshTradePlayers()
    refreshTradeInventory()
    fire(C.TradeRequestsEnabledRE, State.AD_TradeRequestsEnabled == true)
    updateTradeStatusLabel()
end)

task.spawn(function()
    while Runtime.alive do
        if State.AD_TradeAutoRefresh == true then pcall(refreshTradeInventory) end
        task.wait(2.5)
    end
end)

-- ============================================================
-- Tower tab
-- ============================================================
C.TowerControl = C.Tabs.Tower:AddLeftGroupbox("Tower Control")
C.TowerTeam = C.Tabs.Tower:AddLeftGroupbox("Tower Team")
C.TowerAuto = C.Tabs.Tower:AddRightGroupbox("Auto Tower")
C.TowerLive = C.Tabs.Tower:AddRightGroupbox("Live Tower")

C.towerNames = {"Jujutsu Tower", "Hidden Leaf Tower", "Pirate Tower", "Infinity Tower", "Dragon Tower", "Slayer Tower", "Cursed Tower", "Fire Tower"}
C.towerDefs = getTowerDefinitions()
if type(C.towerDefs) == "table" then
    local temp = {}
    for key, definition in pairs(C.towerDefs) do
        local name = type(key) == "string" and key or (type(definition) == "table" and definition.name)
        local order = type(definition) == "table" and tonumber(definition.order) or 999
        if name then temp[#temp + 1] = {name = name, order = order} end
    end
    if #temp > 0 then
        table.sort(temp, function(a, b) return a.order < b.order end)
        C.towerNames = {}
        for _, entry in ipairs(temp) do C.towerNames[#C.towerNames + 1] = entry.name end
    end
end

-- Keep rotation selection explicit and persistent. Existing configs without the
-- picker migrate to all currently known maps.
if type(State.AD_RotationMaps) ~= "table" then State.AD_RotationMaps = {} end
if next(State.AD_RotationMaps) == nil then
    for _, name in ipairs(C.towerNames) do State.AD_RotationMaps[name] = true end
end

C.selectedRotationTowers = function()
    local selected = State.AD_RotationMaps
    local out = {}
    for _, name in ipairs(C.towerNames or {}) do
        if type(selected) == "table" and selected[name] == true then out[#out + 1] = name end
    end
    return out
end

addDropdown(C.TowerControl, "AD_Tower", "Tower", C.towerNames, "Cursed Tower", false)

local function towerCycleIndex(name, names)
    for index, towerName in ipairs(names or C.towerNames or {}) do
        if tostring(towerName) == tostring(name) then
            return index
        end
    end
    return nil
end

local function nextTowerName(current, apply)
    local names = State.AD_TowerCycle == true and C.selectedRotationTowers() or (C.towerNames or {})
    if #names == 0 then return tostring(current or "") end

    local index = towerCycleIndex(current, names) or 0
    local nextIndex = (index % #names) + 1
    local nextName = tostring(names[nextIndex])

    if apply == true then
        State.AD_Tower = nextName
        saveState()

        local option = Options.AD_Tower
        if option and type(option.SetValue) == "function" then
            pcall(option.SetValue, option, nextName)
        end
    end

    return nextName
end

local function towerTeamSummaryText()
    local data = getData()
    local team = data and data.TowerTeam
    if type(team) ~= "table" then return "Tower Team: loading..." end
    local inv = type(data.Inventory) == "table" and data.Inventory or {}
    local rows = {}
    for slot = 1, 4 do
        local uuid = team[slot]
        local item = uuid and inv[uuid]
        local name = type(item) == "table" and tostring(item.name or "Unit") or (uuid and "Unknown Unit" or "Empty")
        rows[#rows + 1] = string.format("%d. %s%s", slot, name, uuid and (" · " .. tostring(uuid):sub(1, 8)) or "")
    end
    return "Tower Team\n" .. table.concat(rows, "\n")
end

C.TowerTeamStatusLabel = C.TowerTeam:AddLabel(towerTeamSummaryText(), true)
addDropdown(C.TowerTeam, "AD_TowerTeamUnit", "Unit", C.UnitLabels, C.UnitLabels[1] or "Auto / First Unit", false)
addSlider(C.TowerTeam, "AD_TowerTeamSlot", "Team Slot", 1, 4, 1, 0, "")
C.TowerTeam:AddButton({Text = "Refresh Unit + Team", Func = function()
    local values = buildUnitLabels()
    C.UnitLabels = values
    local option = Options.AD_TowerTeamUnit
    if option and type(option.SetValues) == "function" then pcall(option.SetValues, option, values) end
    local current = State.AD_TowerTeamUnit
    if not C.UnitLabelToUUID[current] then
        local first = values[1] or "Auto / First Unit"
        State.AD_TowerTeamUnit = first
        if option and type(option.SetValue) == "function" then pcall(option.SetValue, option, first) end
    end
    if C.TowerTeamStatusLabel then C.TowerTeamStatusLabel:SetText(towerTeamSummaryText()) end
end})
C.TowerTeam:AddButton({Text = "Assign Selected Unit", Func = function()
    local label = State.AD_TowerTeamUnit
    local uuid = C.UnitLabelToUUID[label]
    if not uuid then
        local values = buildUnitLabels()
        C.UnitLabels = values
        uuid = C.UnitLabelToUUID[State.AD_TowerTeamUnit]
    end
    if not uuid then notify("Select a real inventory unit first", 4); return end
    local slot = math.clamp(math.floor(tonumber(State.AD_TowerTeamSlot) or 1), 1, 4)
    fire(C.UpdateTowerTeamRE, slot, uuid)
    setLastAction(("Tower Team slot %d <- %s"):format(slot, tostring(label)))
    task.delay(0.35, function()
        if C.TowerTeamStatusLabel then pcall(function() C.TowerTeamStatusLabel:SetText(towerTeamSummaryText()) end) end
    end)
end})
C.TowerTeam:AddButton({Text = "Equip Best Tower Team", Func = function()
    fire(C.EquipBestTowerTeamRE)
    setLastAction("Equip Best Tower Team")
    task.delay(0.35, function()
        if C.TowerTeamStatusLabel then pcall(function() C.TowerTeamStatusLabel:SetText(towerTeamSummaryText()) end) end
    end)
end})
C.TowerTeam:AddLabel("Tower Team memiliki 4 slot. Unit yang sama tidak bisa dipasang dua kali.", true)

C.LastTowerStart = nil
C.LastTowerFloor = nil

C.TowerRuntime = {
    started = false,
    lastProgressAt = 0,
    floorStarts = 0,
    completedSignals = 0,
    lastActions = {},
    ended = false,
    lastFloorStarted = 0,
    lastFloorCompleted = 0,
    serverWait = 0.80,
    runTowerName = nil,
    counterTower = nil,
    runsOnMap = 0,
}

local function towerLiveText()
    local status = C.TowerRuntime.started and "Running" or (C.TowerRuntime.ended and "Ended" or "Idle")
    local lastAction = "-"
    if type(C.TowerRuntime.lastActions) == "table" and #C.TowerRuntime.lastActions > 0 then
        lastAction = tostring(C.TowerRuntime.lastActions[#C.TowerRuntime.lastActions])
    end

    local since = 0
    if tonumber(C.TowerRuntime.lastProgressAt) and C.TowerRuntime.lastProgressAt > 0 then
        since = math.max(0, os.clock() - C.TowerRuntime.lastProgressAt)
    end

    local nextTower = State.AD_TowerCycle == true
        and nextTowerName(State.AD_Tower, false)
        or tostring(State.AD_Tower or "-")

    return string.format(
        "Tower: %s\nStatus: %s\nFloor: %s | Cleared: %s\nRuns: %s / %s | Stop Floor: %s\nLast: %s\nNext Tower: %s\nNext Delay: %.2fs\nUpdate: %.1fs ago",
        tostring(State.AD_Tower or "-"),
        status,
        tostring(C.TowerRuntime.lastFloorStarted or 0),
        tostring(C.TowerRuntime.lastFloorCompleted or 0),
        tostring(C.TowerRuntime.runsOnMap or 0),
        tostring(math.max(1, math.floor(tonumber(State.AD_RunsPerMap) or 1))),
        tostring(math.max(0, math.floor(tonumber(State.AD_StopAtFloor) or 0))),
        lastAction,
        nextTower,
        tonumber(C.TowerRuntime.serverWait) or 0,
        since
    )
end

C.TowerLiveStatusLabel = C.TowerLive:AddLabel(towerLiveText(), true)
C.TowerLive:AddButton({Text = "Refresh Status", Func = function()
    if C.TowerLiveStatusLabel then
        C.TowerLiveStatusLabel:SetText(towerLiveText())
    end
end})

task.spawn(function()
    while Runtime.alive do
        if C.TowerLiveStatusLabel then
            pcall(function()
                C.TowerLiveStatusLabel:SetText(towerLiveText())
            end)
        end
        task.wait(0.5)
    end
end)

local function collectTowerActions(value, out, seen, depth)
    out = out or {}
    seen = seen or {}
    depth = depth or 0
    if depth > 5 or type(value) ~= "table" or seen[value] then return out end
    seen[value] = true

    local action = rawget(value, "action")
    if action ~= nil then out[#out + 1] = tostring(action) end

    for _, child in pairs(value) do
        if type(child) == "table" then
            collectTowerActions(child, out, seen, depth + 1)
        end
    end
    return out
end

local function towerSequenceWait(actions)
    -- Tower timing.

    local waits = {
        damagePlayer = 0.62,
        damageEnemy = 0.62,
        floorCompleted = 0.24,
        memberDefeated = 0.32,
        ended = 0,
    }
    local floorWait = {initial = 0.76, transition = 0.38, repeated = 0}
    local total = 0
    for i, row in ipairs(type(actions) == "table" and actions or {}) do
        if type(row) == "table" then
            local action = tostring(row.action or "")
            if action == "floorStarted" then
                local previous = actions[i - 1]
                if i == 1 then
                    total += (tonumber(row.floor) == 1) and floorWait.initial or floorWait.transition
                elseif type(previous) == "table" and tostring(previous.action) == "memberDefeated" then
                    total += floorWait.transition
                else
                    total += floorWait.repeated
                end
            else
                total += tonumber(waits[action]) or 0
            end
        end
    end
    return math.max(0.05, total)
end

local function towerActionSummary(result)
    if result == nil then return "waiting" end
    if result == false then return "rejected" end
    if type(result) ~= "table" then return shortResult(result) end

    local actions = collectTowerActions(result)
    if #actions == 0 then return shortResult(result) end

    C.TowerRuntime.lastActions = actions
    C.TowerRuntime.lastProgressAt = os.clock()
    C.TowerRuntime.serverWait = towerSequenceWait(result)
    C.TowerRuntime.ended = false

    for _, row in ipairs(result) do
        if type(row) == "table" then
            local action = tostring(row.action or "")
            if action == "floorStarted" then
                C.TowerRuntime.floorStarts += 1
                C.TowerRuntime.lastFloorStarted = tonumber(row.floor) or C.TowerRuntime.lastFloorStarted
            elseif action == "floorCompleted" then
                C.TowerRuntime.completedSignals += 1
                C.TowerRuntime.lastFloorCompleted = tonumber(row.floor) or C.TowerRuntime.lastFloorCompleted
            elseif action == "ended" then
                C.TowerRuntime.ended = true
            end
        end
    end

    return table.concat(actions, " > ")
end

local function startTowerOnce()
    refreshRemotes()

    if State.AD_TowerEquipBest then
        fire(C.EquipBestTowerTeamRE)
        task.wait(0.25)
    end

    local towerName = tostring(State.AD_Tower or "Cursed Tower")
    C.TowerRuntime.runTowerName = towerName
    setLastAction("Tower: starting " .. towerName)
    local ok, result = invoke(C.PlayTowerRF, towerName)

    C.LastTowerStart = {ok = ok, result = result, time = os.clock()}
    getgenv().AliceHUB_AnimeDice_LastTowerStart = C.LastTowerStart

    if not ok or result == false
        or (type(result) == "table" and (result.ok == false or result.success == false)) then
        C.TowerRuntime.started = false
        setLastAction("Tower start rejected | " .. shortResult(result))
        return false, ok, result
    end

    -- Konfirmasi sesi Tower dibaca dari respons floor.

    C.TowerRuntime.started = true
    C.TowerRuntime.ended = false
    C.TowerRuntime.lastProgressAt = os.clock()
    C.TowerRuntime.serverWait = 0.40
    setLastAction("Tower: session opened")
    return true, ok, result
end

C.startTowerWithSkip = function()
    local rotation = C.selectedRotationTowers()
    local maxAttempts = 1
    if State.AD_TowerCycle == true and State.AD_SkipUnavailableMaps == true then
        maxAttempts = math.max(1, #rotation)
    end

    local lastOk, lastResult = false, nil
    for attempt = 1, maxAttempts do
        local accepted, ok, result = startTowerOnce()
        lastOk, lastResult = ok, result
        if accepted then return true, ok, result end

        if attempt < maxAttempts then
            local failedTower = tostring(State.AD_Tower or "-")
            local nextName = nextTowerName(failedTower, true)
            if nextName == failedTower then break end
            setLastAction(("Tower unavailable: %s -> %s"):format(failedTower, nextName))
            notify(("Skip unavailable: %s -> %s"):format(failedTower, nextName), 4)
            task.wait(0.35)
        end
    end

    return false, lastOk, lastResult
end

local function completeTowerOnce()
    refreshRemotes()

    local ok, result = invoke(C.CompleteTowerFloorRF)
    C.LastTowerFloor = {ok = ok, result = result, time = os.clock()}
    getgenv().AliceHUB_AnimeDice_LastTowerFloor = C.LastTowerFloor

    if not ok or result == false
        or (type(result) == "table" and (result.ok == false or result.success == false)) then
        setLastAction("Tower floor rejected | " .. shortResult(result))
        return "rejected", ok, result
    end

    if result == nil then
        -- Tidak ada event baru saat floor masih berjalan.

        return "waiting", ok, result
    end

    local summary = towerActionSummary(result)
    setLastAction(("Tower: %s | floor-starts %d"):format(
        summary,
        C.TowerRuntime.floorStarts
    ))
    return "progress", ok, result
end

C.finishTowerRun = function(reason)
    local finishedTower = tostring(C.TowerRuntime.runTowerName or State.AD_Tower or "-")
    if C.TowerRuntime.counterTower ~= finishedTower then
        C.TowerRuntime.counterTower = finishedTower
        C.TowerRuntime.runsOnMap = 0
    end
    C.TowerRuntime.runsOnMap = (tonumber(C.TowerRuntime.runsOnMap) or 0) + 1

    local runsPerMap = math.max(1, math.floor(tonumber(State.AD_RunsPerMap) or 1))
    local rotating = State.AD_TowerCycle == true
    local floorTarget = tostring(reason or ""):find("floor target", 1, true) ~= nil
    local shouldRotate = rotating and (floorTarget or C.TowerRuntime.runsOnMap >= runsPerMap)
    local shouldContinue = floorTarget and rotating or (not floorTarget and (rotating or State.AD_TowerRestart == true))

    if not shouldContinue then
        setLastAction("Tower stopped: " .. tostring(reason or "complete"))
        if Toggles.AD_AutoTower then Toggles.AD_AutoTower:SetValue(false) end
        return false
    end

    if shouldRotate then
        local nextName = nextTowerName(finishedTower, true)
        setLastAction(("Tower rotate: %s -> %s"):format(finishedTower, nextName))
        notify(("Tower %s · %s run(s) | Next: %s"):format(finishedTower, tostring(C.TowerRuntime.runsOnMap), nextName), 4)
        C.TowerRuntime.counterTower = nextName
        C.TowerRuntime.runsOnMap = 0
    else
        -- Rotation is enabled but this map still needs more runs, or Restart is ON.
        State.AD_Tower = finishedTower
    end

    task.wait(0.8)
    local restarted, _, restartResult = C.startTowerWithSkip()
    if not restarted then
        notify("Tower next/restart rejected: " .. shortResult(restartResult), 6)
        if Toggles.AD_AutoTower then Toggles.AD_AutoTower:SetValue(false) end
        return false
    end
    return true
end

C.TowerControl:AddButton({Text = "Start Selected Tower", Func = function()
    task.spawn(function()
        local accepted, _, startResult = startTowerOnce()
        if not accepted then
            notify("PlayTower rejected: " .. shortResult(startResult), 5)
            return
        end

        task.wait(0.35)
        local state, _, floorResult = completeTowerOnce()
        notify(("Tower: %s | %s"):format(state, towerActionSummary(floorResult)), 5)
    end)
end})

C.TowerControl:AddButton({Text = "Complete / Poll Floor", Func = function()
    local state, _, result = completeTowerOnce()
    notify(("Tower poll: %s | %s"):format(state, towerActionSummary(result)), 5)
end})

C.TowerControl:AddButton({Text = "Equip Best Tower Team", Func = function()
    setLastAction("Equip Best Tower Team")
    fire(C.EquipBestTowerTeamRE)
end})
C.TowerControl:AddButton({Text = "Cancel Tower", Func = function()
    local ok, result = invoke(C.CancelTowerRF)
    C.TowerRuntime.started = false
    setLastAction("Cancel Tower | " .. shortResult(result))
end})

addToggle(C.TowerAuto, "AD_TowerEquipBest", "Equip Best Before Start", true)
addToggle(C.TowerAuto, "AD_TowerRestart", "Auto Restart Same Tower", true, "Dipakai saat Auto Rotate Maps OFF. Saat rotation ON, Runs Per Map yang menentukan kapan pindah.")
addToggle(C.TowerAuto, "AD_TowerCycle", "Auto Rotate Maps", false,
    "Rotate hanya di map yang dipilih. Setelah map terakhir, kembali ke map pertama.")
addDropdown(C.TowerAuto, "AD_RotationMaps", "Rotation Maps", C.towerNames, State.AD_RotationMaps, true)
addInput(C.TowerAuto, "AD_RunsPerMap", "Runs Per Map", "1", "1 - 999", function(value)
    local n = math.clamp(math.floor(tonumber(value) or 1), 1, 999)
    setState("AD_RunsPerMap", tostring(n))
end)
addToggle(C.TowerAuto, "AD_SkipUnavailableMaps", "Skip Unavailable Maps", true,
    "Jika PlayTower ditolak, coba map rotation berikutnya sebelum mematikan Auto Tower.")
addInput(C.TowerAuto, "AD_StopAtFloor", "Stop At Floor", "0", "0 = disabled", function(value)
    local n = math.clamp(math.floor(tonumber(value) or 0), 0, 9999)
    setState("AD_StopAtFloor", tostring(n))
end)
addSlider(C.TowerAuto, "AD_TowerDelay", "Floor Delay", 0.20, 3.00, 0.80, 2, "s")
C.TowerAuto:AddLabel("Stop At Floor rotates to the next selected map when rotation is ON.", true)

C.towerFailures = 0
C.towerLastWaitNotice = 0

addToggle(C.TowerAuto, "AD_AutoTower", "Auto Tower", false,
    "Menjalankan Tower otomatis dan mengikuti jeda tiap floor.", function(value)

    if value then
        C.towerFailures = 0
        C.towerLastWaitNotice = 0
        C.TowerRuntime.started = false

        task.spawn(function()
            local accepted, _, startResult = C.startTowerWithSkip()
            if not State.AD_AutoTower then return end

            if not accepted then
                notify("Auto Tower gagal start: " .. shortResult(startResult), 6)
                if Toggles.AD_AutoTower then Toggles.AD_AutoTower:SetValue(false) end
                return
            end

            task.wait(0.40)

            startLoop("AD_AutoTower", function()
                if not C.TowerRuntime.started then return end

                local state, _, result = completeTowerOnce()

                if state == "progress" then
                    C.towerFailures = 0

                    local stopAtFloor = math.max(0, math.floor(tonumber(State.AD_StopAtFloor) or 0))
                    if stopAtFloor > 0
                        and not C.TowerRuntime.ended
                        and (tonumber(C.TowerRuntime.lastFloorCompleted) or 0) >= stopAtFloor then
                        invoke(C.CancelTowerRF)
                        C.TowerRuntime.started = false
                        setLastAction(("Tower floor target reached: %s"):format(tostring(stopAtFloor)))
                        C.finishTowerRun("floor target " .. tostring(stopAtFloor))
                        return
                    end

                    -- action="ended" menutup sesi Tower.
                    if C.TowerRuntime.ended then
                        C.TowerRuntime.started = false
                        setLastAction(("Tower ended | floor %s | last cleared %s"):format(
                            tostring(C.TowerRuntime.lastFloorStarted or 0),
                            tostring(C.TowerRuntime.lastFloorCompleted or 0)
                        ))
                        C.finishTowerRun("completed")
                    end

                elseif state == "waiting" then
                    if os.clock() - C.towerLastWaitNotice >= 3 then
                        C.towerLastWaitNotice = os.clock()
                        local last = C.TowerRuntime.lastActions and C.TowerRuntime.lastActions[#C.TowerRuntime.lastActions]
                        setLastAction("Tower waiting" .. (last and (" after " .. tostring(last)) or ""))
                    end

                else
                    C.towerFailures += 1
                    if C.towerFailures >= 3 then
                        C.TowerRuntime.started = false
                        setLastAction("Auto Tower stopped: server rejected 3x")
                        notify("Auto Tower dihentikan: server reject 3x.", 6)
                        if Toggles.AD_AutoTower then Toggles.AD_AutoTower:SetValue(false) end
                    end
                end
            end, function()
                -- Ikuti jeda action Tower.

                return math.max(
                    0.25,
                    tonumber(State.AD_TowerDelay) or 0.80,
                    tonumber(C.TowerRuntime.serverWait) or 0
                )
            end)
        end)
    else
        C.TowerRuntime.started = false
        stopLoop("AD_AutoTower")
    end
end)

-- ============================================================
-- Rewards tab
-- ============================================================
C.RewardAuto = C.Tabs.Rewards:AddLeftGroupbox("Auto Claim")
C.RewardManual = C.Tabs.Rewards:AddRightGroupbox("Manual")

local function rewardLoop(id, remote, label)
    if State[id] then
        startLoop(id, function()
            setLastAction(label)
            fire(remote)
        end, 60)
    else stopLoop(id) end
end

addToggle(C.RewardAuto, "AD_AutoDaily", "Auto Claim Daily Reward", true, nil, function(value)
    if value then rewardLoop("AD_AutoDaily", C.DailyClaimRE, "Claim Daily") else stopLoop("AD_AutoDaily") end
end)
addToggle(C.RewardAuto, "AD_AutoGroup", "Auto Claim Group Reward", true, nil, function(value)
    if value then rewardLoop("AD_AutoGroup", C.GroupClaimRE, "Claim Group") else stopLoop("AD_AutoGroup") end
end)
addToggle(C.RewardAuto, "AD_AutoOffline", "Auto Claim Offline Earnings", true, nil, function(value)
    if value then rewardLoop("AD_AutoOffline", C.OfflineClaimRE, "Claim Offline") else stopLoop("AD_AutoOffline") end
end)

C.RewardManual:AddButton({Text = "Claim Daily", Func = function() fire(C.DailyClaimRE) end})
C.RewardManual:AddButton({Text = "Claim Group", Func = function() fire(C.GroupClaimRE) end})
C.RewardManual:AddButton({Text = "Claim Offline Earnings", Func = function() fire(C.OfflineClaimRE) end})
C.RewardManual:AddButton({Text = "Claim Everything Now", Func = function()
    fire(C.DailyClaimRE)
    fire(C.GroupClaimRE)
    fire(C.OfflineClaimRE)
    task.spawn(function()
        local claimed = claimReadyQuestsOnce()
        notify("Reward sweep sent · ready quests: " .. tostring(claimed), 5)
    end)
end})
C.RewardManual:AddLabel("Daily Reward tersedia setiap 23 jam.", true)

C.QuestAuto = C.Tabs.Rewards:AddLeftGroupbox("Daily / Weekly Quests")
C.QuestShop = C.Tabs.Rewards:AddRightGroupbox("Ticket Shop")
C.QuestStatusLabel = C.QuestAuto:AddLabel("Quest data loading...", true)

addToggle(C.QuestAuto, "AD_AutoQuestClaim", "Auto Claim Ready Quests", false, nil, function(value)
    if value then
        startLoop("AD_AutoQuestClaim", function()
            local count = claimReadyQuestsOnce()
            if count > 0 then setLastAction("Quest Claim: " .. tostring(count)) end
        end, 2.0)
    else stopLoop("AD_AutoQuestClaim") end
end)
C.QuestAuto:AddButton({Text = "Claim All Ready Now", Func = function()
    task.spawn(function()
        local count = claimReadyQuestsOnce()
        notify("Ready quest claims sent: " .. tostring(count), 4)
    end)
end})
C.QuestAuto:AddLabel("Quest: Playtime, Rolls, Towers, dan Units Sold.", true)

C.questShopFallback = {"Lucky Spin", "Trait Reroll", "Gems", "Luck", "Ultra Luck", "More Cash", "Roll Speed"}
addDropdown(C.QuestShop, "AD_QuestBuyItem", "Shop Item", C.questShopFallback, "Trait Reroll", false)
C.QuestShop:AddButton({Text = "Buy Selected Once", Func = function()
    fire(C.QuestBuyRE, tostring(State.AD_QuestBuyItem or "Trait Reroll"))
end})
addToggle(C.QuestShop, "AD_AutoQuestBuy", "Auto Buy Selected", false, "Membeli item pilihan saat Ticket mencukupi.", function(value)
    if value then
        startLoop("AD_AutoQuestBuy", function()
            local selected = tostring(State.AD_QuestBuyItem or "")
            if selected == "" or type(C.QuestConfig) ~= "table" or type(C.QuestConfig.Shop) ~= "table" then return end
            local tickets = getInventoryAmount("Tickets")
            for _, shop in ipairs(C.QuestConfig.Shop) do
                if shop.name == selected and tickets >= (tonumber(shop.tickets) or math.huge) then
                    fire(C.QuestBuyRE, selected)
                    setLastAction("Quest Shop: " .. selected)
                    return
                end
            end
        end, 1.0)
    else stopLoop("AD_AutoQuestBuy") end
end)
C.QuestShop:AddLabel("Ticket tidak bisa ditrade. Simpan di bawah 1.000 untuk menghindari reset saldo.", true)

-- ============================================================
-- Weather + Extras
-- ============================================================
C.ExtraCodes = C.Tabs.Extras:AddLeftGroupbox("Codes")
C.ExtraLimited = C.Tabs.Extras:AddRightGroupbox("Limited Units")
C.ExtraProgress = C.Tabs.Extras:AddLeftGroupbox("Index & Tutorial")
C.ExtraBuffStats = C.Tabs.Extras:AddRightGroupbox("Effective Buffs")

C.WeatherStatus = C.Tabs.Weather:AddLeftGroupbox("Weather Status")
C.WeatherSpin = C.Tabs.Weather:AddLeftGroupbox("Weather Spin")
C.WeatherBoost = C.Tabs.Weather:AddRightGroupbox("Weather Boosts")
C.WeatherAlerts = C.Tabs.Weather:AddRightGroupbox("Weather Alerts")

C.LimitedStatusLabel = C.ExtraLimited:AddLabel("Loading limited stock...", true)
C.IndexStatusLabel = C.ExtraProgress:AddLabel("Index data loading...", true)
C.TutorialStatusLabel = C.ExtraProgress:AddLabel("Tutorial data loading...", true)
C.BuffStatusLabel = C.ExtraBuffStats:AddLabel("Effective buffs: loading...", true)
C.WeatherStatusLabel = C.WeatherStatus:AddLabel("Weather: loading...", true)


local function effectiveBuffText()
    local cache = propertyValue(C.BuffCacheProperty)
    if type(cache) ~= "table" then
        return "Effective buff cache loading...\nFriend Boost: " .. tostring(LocalPlayer:GetAttribute("FriendBoost") or 0)
    end
    local order = {"Luck", "Money Multiplier", "Damage Multiplier", "Sell Multiplier", "Health Multiplier", "Unit Storage", "Roll Duration", "Rolls", "Walkspeed"}
    local rows = {}
    for _, name in ipairs(order) do
        local value = cache[name]
        if value ~= nil then
            local rendered
            if name:find("Multiplier", 1, true) or name == "Luck" then rendered = "x" .. compactNumber(value)
            elseif name == "Roll Duration" then rendered = compactNumber(value) .. "s"
            else rendered = compactNumber(value) end
            rows[#rows + 1] = name .. ": " .. rendered
        end
    end
    rows[#rows + 1] = "Friend Boost: " .. compactNumber(LocalPlayer:GetAttribute("FriendBoost") or 0)
    return table.concat(rows, "\n")
end
C.ExtraBuffStats:AddButton({Text = "Refresh Effective Buffs", Func = function()
    if C.BuffStatusLabel then C.BuffStatusLabel:SetText(effectiveBuffText()) end
end})
C.ExtraBuffStats:AddLabel("Nilai buff aktif setelah upgrade, rebirth, boost, gamepass, dan friend boost.", true)

-- Weather is read from the game's replicated ActiveWeather property only.
-- No fake/force-weather remote is used here.
C.weatherKnownEffects = {
    ["Luck Event"] = "Luck x2.5",
    ["Cash Event"] = "Cash x2.5",
    ["Roll Speed Event"] = "Roll Duration x0.5",
}
C.weatherNameFromValue = function(value)
    if type(value) == "string" and value ~= "" then return value, value end
    if type(value) ~= "table" then return "None", tostring(value or "none") end

    local direct = value.name or value.Name or value.weather or value.Weather or value.type or value.Type or value.id or value.Id
    if type(direct) == "string" and direct ~= "" then return direct, direct end
    if type(value[1]) == "string" and value[1] ~= "" then return value[1], value[1] end

    for _, known in ipairs({"Luck Event", "Cash Event", "Roll Speed Event"}) do
        if value[known] ~= nil and value[known] ~= false then return known, known end
    end
    for key, entry in pairs(value) do
        if type(key) == "string" and (type(entry) == "table" or entry == true) then
            local lower = string.lower(key)
            if lower:find("event", 1, true) or lower:find("weather", 1, true) then return key, key end
        end
    end
    return "None", "table"
end
C.weatherRemainingText = function(value)
    if type(value) ~= "table" then return nil end
    local remaining = tonumber(value.remaining or value.timeLeft or value.TimeLeft or value.remainingTime)
    if remaining then
        remaining = math.max(0, math.floor(remaining))
    else
        local finish = tonumber(value.expiresAt or value.endsAt or value.endAt or value.endTime or value.untilTime)
        if finish then
            local now
            if finish > 1000000000 then
                now = os.time()
            else
                local ok, serverNow = pcall(workspace.GetServerTimeNow, workspace)
                now = ok and tonumber(serverNow) or os.clock()
            end
            remaining = math.max(0, math.floor(finish - (tonumber(now) or 0)))
        end
    end
    if not remaining then return nil end
    return string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
end
C.weatherSnapshot = function()
    local value = propertyValue(C.ActiveWeatherProperty)
    if value == nil then value = C.ActiveWeatherCache end
    local name, key = C.weatherNameFromValue(value)
    local effect = C.weatherKnownEffects[name] or "Server event"
    local remaining = C.weatherRemainingText(value)
    local text = "Weather: " .. tostring(name) .. "\nEffect: " .. tostring(effect)
    if remaining then text = text .. "\nRemaining: " .. remaining end
    if name == "None" then text = "Weather: None\nWaiting for next server event..." end
    return {name = name, key = tostring(key or name), effect = effect, remaining = remaining, text = text, raw = value}
end
C.weatherTargetSelected = function(targets, weatherName)
    if type(targets) == "string" then return targets == weatherName end
    return type(targets) == "table" and targets[weatherName] == true
end

C.lastWeatherKey = nil
C.updateWeatherStatus = function(forceNotify)
    local snap = C.weatherSnapshot()
    if C.WeatherStatusLabel and type(C.WeatherStatusLabel.SetText) == "function" then
        pcall(function() C.WeatherStatusLabel:SetText(snap.text) end)
    end
    if C.lastWeatherKey ~= snap.key then
        local previous = C.lastWeatherKey
        C.lastWeatherKey = snap.key
        if previous ~= nil and State.AD_WeatherNotify == true then
            local message = snap.name == "None" and "Weather ended" or (snap.name .. " · " .. snap.effect)
            notify(message, 5)
        elseif forceNotify == true and snap.name ~= "None" then
            notify(snap.name .. " · " .. snap.effect, 5)
        end
        if snap.name ~= "None"
            and State.AD_WeatherWebhook == true
            and C.weatherTargetSelected(State.AD_WeatherWebhookTargets, snap.name) then
            if type(C.SendWebhookNow) == "function" then
                task.spawn(function() pcall(C.SendWebhookNow, false) end)
            else
                C.PendingWeatherWebhook = snap
            end
        end
    end
    return snap
end
C.WeatherStatus:AddButton({Text = "Refresh Weather", Func = function()
    C.updateWeatherStatus(true)
end})
C.weatherOptions = {"Luck Event", "Cash Event", "Roll Speed Event"}
addToggle(C.WeatherAlerts, "AD_WeatherNotify", "Weather Notifications", true)
addToggle(C.WeatherAlerts, "AD_WeatherWebhook", "Send Weather To Webhook", false)
addDropdown(C.WeatherAlerts, "AD_WeatherWebhookTargets", "Webhook Weather", C.weatherOptions, State.AD_WeatherWebhookTargets, true)
addDropdown(C.WeatherSpin, "AD_WeatherSpinTargets", "Spin During Weather", C.weatherOptions, State.AD_WeatherSpinTargets, true)
addDropdown(C.WeatherBoost, "AD_WeatherBoostTargets", "Boost During Weather", C.weatherOptions, State.AD_WeatherBoostTargets, true)

task.spawn(function()
    local deadline = os.clock() + 30
    while Runtime.alive and os.clock() < deadline do
        refreshRemotes()
        if C.ActiveWeatherRemote and C.ActiveWeatherRemote:IsA("RemoteEvent") then
            rememberConnection(C.ActiveWeatherRemote.OnClientEvent:Connect(function(...)
                local args = table.pack(...)
                C.ActiveWeatherCache = args.n == 1 and args[1] or args
                task.defer(C.updateWeatherStatus)
            end))
            break
        end
        task.wait(0.5)
    end
end)

C.spinFallback = {"Lucky Spin", "Jackpot Spin"}
C.spinChoices = function()
    local values, seen = {}, {}
    local function add(name)
        name = tostring(name or "")
        if name ~= "" and name:lower():find("spin", 1, true) and not seen[name] then
            seen[name] = true
            values[#values + 1] = name
        end
    end
    for _, name in ipairs(C.spinFallback) do add(name) end
    if type(C.SpinConfig) == "table" then
        for key, config in pairs(C.SpinConfig) do
            if type(config) == "table" then add(config.name or config.Name or key) else add(key) end
        end
    end
    local data = getData()
    if type(data) == "table" and type(data.Inventory) == "table" then
        for _, item in pairs(data.Inventory) do
            if type(item) == "table" then add(item.name) end
        end
    end
    table.sort(values, function(a, b) return a:lower() < b:lower() end)
    return #values > 0 and values or C.spinFallback
end
C.refreshSpinOptions = function()
    local values = C.spinChoices()
    local option = Options.AD_SpinType
    if option and type(option.SetValues) == "function" then pcall(option.SetValues, option, values) end
    local current = tostring(State.AD_SpinType or "")
    local valid = false
    for _, name in ipairs(values) do if name == current then valid = true break end end
    if not valid then
        State.AD_SpinType = values[1] or "Lucky Spin"
        if option and type(option.SetValue) == "function" then pcall(option.SetValue, option, State.AD_SpinType) end
    end
end
C.autoSpinName = function()
    if tostring(State.AD_AutoSpinMode or "Selected") == "Best Owned" then
        for _, name in ipairs({"Jackpot Spin", "Lucky Spin"}) do
            if getInventoryAmount(name) > 0 then return name end
        end
        for _, name in ipairs(C.spinChoices()) do
            if getInventoryAmount(name) > 0 then return name end
        end
    end
    return tostring(State.AD_SpinType or "Lucky Spin")
end

addDropdown(C.WeatherSpin, "AD_SpinType", "Spin", C.spinFallback, "Lucky Spin", false)
addDropdown(C.WeatherSpin, "AD_AutoSpinMode", "Spin Mode", {"Selected", "Best Owned"}, "Selected", false)
C.WeatherSpin:AddButton({Text = "Refresh Spins", Func = C.refreshSpinOptions})
C.WeatherSpin:AddButton({Text = "Use Selected Spin", Func = function()
    local key = inventoryKeyByName(State.AD_SpinType)
    if not key then notify("You do not own " .. tostring(State.AD_SpinType)); return end
    fire(C.SpinUseRE, key)
end})
addToggle(C.WeatherSpin, "AD_AutoUseSpin", "Auto Spin Always", false,
    nil, function(value)
    if value then
        startLoop("AD_AutoUseSpin", function()
            if type(C.queueAutoSpinOnce) == "function" then C.queueAutoSpinOnce() end
        end, 0.6)
    else stopLoop("AD_AutoUseSpin") end
end)

C.queueAutoSpinOnce = function()
    local selected = C.autoSpinName()
    local queued = activeEntry(selected)
    local queuedAmount = queued and tonumber(queued.amount or 1) or 0
    if queuedAmount <= 0 then
        local key = inventoryKeyByName(selected)
        if key then
            fire(C.SpinUseRE, key)
            setLastAction("Auto Spin: " .. selected)
            return true
        end
    end
    return false
end

addToggle(C.WeatherSpin, "AD_AutoSpinWeather", "Auto Spin During Weather", false, nil, function(value)
    if value then
        startLoop("AD_AutoSpinWeather", function()
            local snap = C.weatherSnapshot()
            if snap.name ~= "None" and C.weatherTargetSelected(State.AD_WeatherSpinTargets, snap.name) then
                C.queueAutoSpinOnce()
            end
        end, 0.6)
    else
        stopLoop("AD_AutoSpinWeather")
    end
end)

task.delay(1.5, function() if Runtime.alive then pcall(C.refreshSpinOptions) end end)

C.boostFallback = {
    "Luck I", "Luck II", "Luck III", "Luck IV",
    "Damage I", "Damage II", "Damage III", "Damage IV",
    "Income I", "Income II", "Income III", "Income IV",
    "Dragon Luck I", "Dragon Luck II", "Dragon Luck III",
    "Dragon Income I", "Dragon Income II", "Dragon Income III",
    "Dragon Damage I", "Dragon Damage II", "Dragon Damage III",
    "Cursed Luck I", "Cursed Luck II", "Cursed Luck III",
    "Cursed Damage I", "Cursed Damage II", "Cursed Damage III",
    "Cursed Income I", "Cursed Income II", "Cursed Income III",
    "Pirate Luck I", "Pirate Luck II", "Pirate Luck III",
    "Pirate Damage I", "Pirate Damage II", "Pirate Damage III",
    "Pirate Income I", "Pirate Income II", "Pirate Income III",
    "Leaf Luck I", "Leaf Luck II", "Leaf Luck III",
    "Leaf Damage I", "Leaf Damage II", "Leaf Damage III",
    "Leaf Income I", "Leaf Income II", "Leaf Income III",
    "Slayer Luck I", "Slayer Luck II", "Slayer Luck III",
    "Slayer Damage I", "Slayer Damage II", "Slayer Damage III",
    "Slayer Income I", "Slayer Income II", "Slayer Income III"
}

-- UPD 5 keeps adding themed boosts. Prefer the live BoostConfig/inventory
-- whenever available; the fallback only guarantees useful values during early load.
C.currentBoostCatalog = function()
    local live, liveSeen = {}, {}
    local fallbackOrder = {}
    for index, name in ipairs(C.boostFallback) do fallbackOrder[name] = index end

    local function looksLikeBoostName(name)
        return type(name) == "string" and (
            name:match("Luck%s+[IVXLCDM]+$")
            or name:match("Damage%s+[IVXLCDM]+$")
            or name:match("Income%s+[IVXLCDM]+$")
        ) ~= nil
    end

    local function addLive(name)
        if not looksLikeBoostName(name) or liveSeen[name] then return end
        liveSeen[name] = true
        live[#live + 1] = name
    end

    local function scan(value, depth, visited)
        if depth > 4 or type(value) ~= "table" then return end
        visited = visited or {}
        if visited[value] then return end
        visited[value] = true
        for key, child in pairs(value) do
            if type(key) == "string" then addLive(key) end
            if type(child) == "table" then
                addLive(child.name)
                addLive(child.Name)
                scan(child, depth + 1, visited)
            elseif type(child) == "string" then
                addLive(child)
            end
        end
    end

    if type(C.BoostConfig) == "table" then
        local cfg = C.BoostConfig
        if type(cfg.GetAll) == "function" then
            local ok, all = pcall(cfg.GetAll)
            if ok and type(all) == "table" then scan(all, 0, {}) end
        end
        scan(cfg, 0, {})
    end

    local data = getData()
    if type(data) == "table" and type(data.Inventory) == "table" then
        for key, item in pairs(data.Inventory) do
            if type(item) == "table" and tradeEntryKind(key, item) == "Boost" then
                addLive(item.name)
            end
        end
    end

    if #live == 0 then
        local fallback = {}
        for _, name in ipairs(C.boostFallback) do fallback[#fallback + 1] = name end
        return fallback
    end

    table.sort(live, function(a, b)
        local ai, bi = fallbackOrder[a], fallbackOrder[b]
        if ai and bi then return ai < bi end
        if ai then return true end
        if bi then return false end
        return a < b
    end)
    return live
end
if type(State.AD_BoostType) == "string" then
    State.AD_BoostType = State.AD_BoostType ~= "" and {[State.AD_BoostType] = true} or {}
elseif type(State.AD_BoostType) ~= "table" then
    State.AD_BoostType = {["Luck III"] = true}
end

local function selectedBoostNames()
    local selected = State.AD_BoostType
    local names = {}
    local catalog = C.currentBoostCatalog()
    if type(selected) == "string" then
        if selected ~= "" then names[1] = selected end
        return names
    end
    if type(selected) ~= "table" then return names end
    for _, name in ipairs(catalog) do
        if selected[name] == true then names[#names + 1] = name end
    end
    -- Keep custom/runtime boost names that are not in fallback.
    for key, value in pairs(selected) do
        if type(key) == "string" and value == true then
            local exists = false
            for _, name in ipairs(names) do
                if name == key then exists = true break end
            end
            if not exists then names[#names + 1] = key end
        end
    end
    return names
end

addDropdown(C.WeatherBoost, "AD_BoostType", "Boosts", C.currentBoostCatalog(), State.AD_BoostType, true)
C.refreshBoostCatalog = function()
    local values = C.currentBoostCatalog()
    if Options.AD_BoostType and type(Options.AD_BoostType.SetValues) == "function" then
        pcall(Options.AD_BoostType.SetValues, Options.AD_BoostType, values)
    end
    return values
end
task.delay(2.0, function() if Runtime.alive then pcall(C.refreshBoostCatalog) end end)
C.WeatherBoost:AddButton({Text = "Use Selected Boosts", Func = function()
    local selected = selectedBoostNames()
    if #selected == 0 then notify("Select at least 1 boost"); return end
    local used = 0
    for _, name in ipairs(selected) do
        local key = inventoryKeyByName(name)
        if key then
            fire(C.BoostUseRE, key)
            used += 1
        end
    end
    notify(used > 0 and ("Used selected boosts: " .. tostring(used)) or "You do not own the selected boosts", 4)
end})
addToggle(C.WeatherBoost, "AD_AutoUseBoost", "Auto Boost Always", false,
    nil, function(value)
    if value then
        startLoop("AD_AutoUseBoost", function()
            local selected = selectedBoostNames()
            if #selected == 0 then
                if Toggles.AD_AutoUseBoost then Toggles.AD_AutoUseBoost:SetValue(false) end
                notify("Select at least 1 boost", 4)
                return
            end
            if type(C.useSelectedBoostsOnce) == "function" then C.useSelectedBoostsOnce("always") end
        end, 2.0)
    else stopLoop("AD_AutoUseBoost") end
end)

C.useSelectedBoostsOnce = function(source)
    if source == "always" and State.AD_AutoUseBoost ~= true then return false end
    if source == "weather" and State.AD_AutoBoostWeather ~= true then return false end
    local selected = selectedBoostNames()
    if #selected == 0 then return false end
    local used = false
    for _, name in ipairs(selected) do
        if not activeEntry(name) then
            local key = inventoryKeyByName(name)
            if key then
                fire(C.BoostUseRE, key)
                setLastAction("Use Boost: " .. name)
                used = true
                task.wait(0.08)
            end
        end
    end
    return used
end

addToggle(C.WeatherBoost, "AD_AutoBoostWeather", "Auto Boost During Weather", false, nil, function(value)
    if value then
        startLoop("AD_AutoBoostWeather", function()
            local snap = C.weatherSnapshot()
            if snap.name ~= "None" and C.weatherTargetSelected(State.AD_WeatherBoostTargets, snap.name) then
                C.useSelectedBoostsOnce("weather")
            end
        end, 2.0)
    else
        stopLoop("AD_AutoBoostWeather")
    end
end)

C.WeatherBoost:AddButton({Text = "Refresh Spins & Boosts", Func = function()
    local spins, boosts = {}, {}
    local data = getData()
    if data and type(data.Inventory) == "table" then
        for key, item in pairs(data.Inventory) do
            if type(item) == "table" and tonumber(item.amount or 0) > 0 then
                local kind = tradeEntryKind(key, item)
                if kind == "Spin" then spins[#spins + 1] = tostring(item.name)
                elseif kind == "Boost" then boosts[#boosts + 1] = tostring(item.name) end
            end
        end
    end
    table.sort(spins); table.sort(boosts)
    if #spins == 0 then spins = C.spinFallback end
    if #boosts == 0 then boosts = C.currentBoostCatalog() end
    if Options.AD_SpinType and type(Options.AD_SpinType.SetValues) == "function" then pcall(Options.AD_SpinType.SetValues, Options.AD_SpinType, spins) end
    if Options.AD_BoostType and type(Options.AD_BoostType.SetValues) == "function" then pcall(Options.AD_BoostType.SetValues, Options.AD_BoostType, boosts) end
    notify("Consumable list refreshed")
end})

addInput(C.ExtraCodes, "AD_RedeemCode", "Code", "", "RELEASE / UPDATE4 / ...")
C.ExtraCodes:AddButton({Text = "Redeem Code", Func = function()
    local code = tostring(State.AD_RedeemCode or "")
    if code == "" then notify("Enter a code first"); return end
    fire(C.RedeemCodeRE, code)
end})
C.knownCodes = {"RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4", "1KCCU", "5KCCU", "10KCCU", "20KCCU"}
C.brokenKnownCodes = {"SORRY!"} -- Current dev config spells Tickets as "Ticekts"; keep manual only.
C.ExtraCodes:AddButton({Text = "Redeem All Known Codes", Func = function()
    task.spawn(function()
        for _, code in ipairs(C.knownCodes) do
            fire(C.RedeemCodeRE, code)
            task.wait(0.55)
        end
        notify("Known code requests sent", 4)
    end)
end})
C.ExtraCodes:AddLabel("Kode SORRY! dilewati dari Redeem All karena reward Ticket sedang bermasalah.", true)

local function limitedStockText()
    if type(C.MonetizationConfig) ~= "table" then
        C.MonetizationConfig = safeRequire(findPath(ReplicatedStorage, "Framework", "Features", "Monetization", "MonetizationConfig"))
    end
    local config = C.MonetizationConfig
    local limiteds = type(config) == "table" and config.LimitedUnits or nil
    if type(limiteds) ~= "table" then return "Limited config loading..." end
    local live = nil
    if C.LimitedStockProperty and type(C.LimitedStockProperty.Get) == "function" then
        local ok, value = pcall(C.LimitedStockProperty.Get, C.LimitedStockProperty)
        if ok and type(value) == "table" then live = value end
    end
    local rows = {}
    for name, info in pairs(limiteds) do
        local amount = live and live[name] or info.stock
        rows[#rows + 1] = string.format("%s: %s / %s left · %s R$", tostring(name), compactNumber(amount), compactNumber(info.stock), compactNumber(info.price))
    end
    table.sort(rows)
    return #rows > 0 and table.concat(rows, "\n") or "No limited units in config"
end
C.ExtraLimited:AddButton({Text = "Refresh Limited Stock", Func = function()
    pcall(function() C.LimitedStatusLabel:SetText(limitedStockText()) end)
end})
C.ExtraLimited:AddLabel("Pembelian Limited Unit tetap melalui menu Roblox.", true)

C.ExtraProgress:AddButton({Text = "Refresh Index Progress", Func = function()
    pcall(function() C.IndexStatusLabel:SetText(indexProgressSummary()) end)
    pcall(function() C.TutorialStatusLabel:SetText(onboardingSummary()) end)
end})
C.ExtraProgress:AddButton({Text = "Advance Tutorial Step", Func = function()
    fire(C.OnboardingAdvanceRE)
    task.delay(0.25, function()
        pcall(function() C.TutorialStatusLabel:SetText(onboardingSummary()) end)
    end)
end})
addToggle(C.ExtraProgress, "AD_AutoTutorialAdvance", "Auto Advance Tutorial", false,
    "Only advances steps the server says are complete; click-only tutorial steps are skipped automatically.", function(value)
    if value then
        startLoop("AD_AutoTutorialAdvance", function()
            local data = getData()
            local step = data and tonumber(data.OnboardingStep) or 0
            if step > 13 then
                if Toggles.AD_AutoTutorialAdvance then Toggles.AD_AutoTutorialAdvance:SetValue(false) end
                return
            end
            fire(C.OnboardingAdvanceRE)
        end, 0.45)
    else stopLoop("AD_AutoTutorialAdvance") end
end)
C.ExtraProgress:AddLabel("Index hanya mencatat discovery. Tidak ada claim Index pada versi game saat ini.", true)

-- ============================================================
-- Webhook · Discord status monitor
-- ============================================================
C.WebhookSetup = C.Tabs.Webhook:AddLeftGroupbox("Discord Webhook")
C.WebhookActions = C.Tabs.Webhook:AddRightGroupbox("Status")
C.InventoryWebhook = C.Tabs.Webhook:AddLeftGroupbox("Inventory Webhook")

C.WebhookStatusLabel = C.WebhookActions:AddLabel("Status: Idle", true)
C.InventoryWebhookStatusLabel = C.InventoryWebhook:AddLabel("Inventory: Idle", true)

local function setWebhookStatus(text)
    local msg = "Status: " .. tostring(text or "Idle")
    if C.WebhookStatusLabel and type(C.WebhookStatusLabel.SetText) == "function" then
        C.WebhookStatusLabel:SetText(msg)
    end
end

C.setInventoryWebhookStatus = function(text)
    local msg = "Inventory: " .. tostring(text or "Idle")
    if C.InventoryWebhookStatusLabel and type(C.InventoryWebhookStatusLabel.SetText) == "function" then
        C.InventoryWebhookStatusLabel:SetText(msg)
    end
end

local function getExecutorRequest()
    if type(request) == "function" then
        return request, "request"
    end

    if type(http_request) == "function" then
        return http_request, "http_request"
    end

    local fn = nil
    pcall(function()
        if http and type(http.request) == "function" then
            fn = http.request
        end
    end)
    if fn then return fn, "http.request" end

    pcall(function()
        if syn and type(syn.request) == "function" then
            fn = syn.request
        end
    end)
    if fn then return fn, "syn.request" end

    pcall(function()
        if fluxus and type(fluxus.request) == "function" then
            fn = fluxus.request
        end
    end)
    if fn then return fn, "fluxus.request" end

    return nil, "none"
end

local function cleanWebhookURL(value)
    local url = tostring(value or "")
    url = url:gsub("^%s+", ""):gsub("%s+$", "")
    url = url:gsub("^<", ""):gsub(">$", "")
    url = url:gsub("^`+", ""):gsub("`+$", "")
    return url
end

local function withWebhookWait(url)
    url = cleanWebhookURL(url)
    if url == "" then return url end

    if url:find("?", 1, true) then
        if not url:find("wait=", 1, true) then
            return url .. "&wait=true"
        end
        return url
    end

    return url .. "?wait=true"
end

C.trimDiscordField = function(value, limit)
    local text = tostring(value or "-")
    limit = tonumber(limit) or 1000
    if #text <= limit then return text end
    return text:sub(1, math.max(1, limit - 18)) .. "\n… truncated"
end

C.inventoryWebhookSnapshot = function()
    local data = getData() or {}
    local inventory = type(data.Inventory) == "table" and data.Inventory or {}
    local unitGroups, itemGroups = {}, {}
    local unitCount, itemCount, itemTypes = 0, 0, 0

    for key, item in pairs(inventory) do
        if type(item) == "table" then
            local kind = tradeEntryKind(key, item)
            if kind == "Unit" or isUUID(key) then
                unitCount += 1
                local rarity = getUnitRarity(item) or "Unknown"
                local group = tostring(item.name or "Unit") .. " [" .. tostring(rarity) .. "]"
                unitGroups[group] = (unitGroups[group] or 0) + 1
            else
                local name = tostring(item.name or key or "Item")
                local amount = math.max(0, tonumber(item.amount) or 1)
                if itemGroups[name] == nil then itemTypes += 1 end
                itemGroups[name] = (itemGroups[name] or 0) + amount
                itemCount += amount
            end
        end
    end

    C.inventoryMapLines = function(map, suffixFirst)
        local rows = {}
        for name, amount in pairs(map) do
            rows[#rows + 1] = {name=tostring(name), amount=tonumber(amount) or 0}
        end
        table.sort(rows, function(a, b)
            if a.amount ~= b.amount then return a.amount > b.amount end
            return a.name < b.name
        end)
        local out = {}
        for _, row in ipairs(rows) do
            if suffixFirst then
                out[#out + 1] = tostring(row.amount) .. "x " .. row.name
            else
                out[#out + 1] = row.name .. " x" .. compactNumber(row.amount)
            end
        end
        return out
    end

    return {
        data = data,
        unitCount = unitCount,
        itemCount = itemCount,
        itemTypes = itemTypes,
        unitLines = C.inventoryMapLines(unitGroups, true),
        itemLines = C.inventoryMapLines(itemGroups, false),
    }
end

C.postInventoryWebhookPayload = function(payload)
    local url = cleanWebhookURL(State.AD_WebhookURL)
    if url == "" then C.setInventoryWebhookStatus("Webhook URL empty"); return false, "Webhook URL empty" end
    if not url:find("discord.com/api/webhooks/", 1, true) and not url:find("discordapp.com/api/webhooks/", 1, true) then
        C.setInventoryWebhookStatus("Invalid Discord webhook URL")
        return false, "Invalid Discord webhook URL"
    end

    local req, reqName = getExecutorRequest()
    if type(req) ~= "function" then C.setInventoryWebhookStatus("No request API"); return false, "request API unavailable" end

    local okEncode, body = pcall(HttpService.JSONEncode, HttpService, payload)
    if not okEncode then C.setInventoryWebhookStatus("JSON error"); return false, body end

    local targetUrl = withWebhookWait(url)
    C.setInventoryWebhookStatus("Sending via " .. tostring(reqName) .. "...")

    local function run(urlKey)
        local requestData = {
            Method = "POST",
            Headers = {["Content-Type"]="application/json", ["Accept"]="application/json", ["User-Agent"]="AliceHUB-AnimeDice"},
            Body = body,
        }
        requestData[urlKey] = targetUrl
        return pcall(req, requestData)
    end

    local ok, response = run("Url")
    if not ok or response == nil then
        local ok2, response2 = run("URL")
        if ok2 or response == nil then ok, response = ok2, response2 end
    end
    if not ok then C.setInventoryWebhookStatus("Request error"); return false, response end

    local code = type(response) == "table" and tonumber(response.StatusCode or response.Status or response.status_code or response.status or response.Code) or nil
    local success = type(response) == "table" and (response.Success == true or response.success == true) or false
    if (code and code >= 200 and code < 300) or (code == nil and success) then
        C.setInventoryWebhookStatus(code and ("Sent · HTTP " .. tostring(code)) or "Sent")
        return true, response
    end

    C.setInventoryWebhookStatus(code and ("Failed · HTTP " .. tostring(code)) or "Unknown response")
    return false, response
end

C.sendInventoryWebhook = function(isManual)
    local snap = C.inventoryWebhookSnapshot()
    local fields = {}

    if State.AD_InventoryWebhookStats == true then
        fields[#fields + 1] = {
            name = "Stats",
            value = C.trimDiscordField((
                "Money: %s\nRolls: %s\nRebirth: %s\nDice: %s\nUnits: %s\nItems: %s across %s types"
            ):format(
                compactNumber(snap.data.Money or 0),
                compactNumber(snap.data.Rolls or 0),
                compactNumber(snap.data.Rebirth or 0),
                tostring(snap.data.Dice or "N/A"),
                compactNumber(snap.unitCount),
                compactNumber(snap.itemCount),
                compactNumber(snap.itemTypes)
            ), 1000),
            inline = false,
        }
    end

    if State.AD_InventoryWebhookUnits == true then
        fields[#fields + 1] = {
            name = "Units",
            value = C.trimDiscordField(#snap.unitLines > 0 and table.concat(snap.unitLines, "\n") or "No units", 1000),
            inline = false,
        }
    end

    if State.AD_InventoryWebhookItems == true then
        fields[#fields + 1] = {
            name = "Items",
            value = C.trimDiscordField(#snap.itemLines > 0 and table.concat(snap.itemLines, "\n") or "No items", 1000),
            inline = false,
        }
    end

    if #fields == 0 then
        C.setInventoryWebhookStatus("Select Units, Items or Stats")
        return false, "No inventory sections selected"
    end

    local payload = {
        username = "AliceHUB",
        embeds = {{
            title = "AliceHUB · Anime Dice · Inventory",
            description = isManual and "Manual inventory snapshot" or "Scheduled inventory snapshot",
            color = 11874387,
            fields = fields,
            footer = {text = "AliceHUB · Anime Dice"},
            timestamp = (function()
                local ok, value = pcall(function() return DateTime.now():ToIsoDate() end)
                return ok and value or nil
            end)(),
        }},
    }
    return C.postInventoryWebhookPayload(payload)
end

C.AliceSessionStats = {
    startAt = os.clock(),
    baseline = nil,
}

local function ensureAliceSessionBaseline()
    if C.AliceSessionStats.baseline then
        return C.AliceSessionStats.baseline
    end

    local data = getData()
    if type(data) ~= "table" then
        return nil
    end

    C.AliceSessionStats.baseline = {
        Money = tonumber(data.Money) or 0,
        Rolls = tonumber(data.Rolls) or 0,
        Rebirth = tonumber(data.Rebirth) or 0,
    }
    return C.AliceSessionStats.baseline
end

local function signedCompact(value)
    local number = tonumber(value) or 0
    local prefix = number >= 0 and "+" or "-"
    return prefix .. compactNumber(math.abs(number))
end

local function getSessionDeltas(data)
    data = type(data) == "table" and data or {}
    local base = ensureAliceSessionBaseline()

    if not base then
        return 0, 0, 0
    end

    return
        (tonumber(data.Money) or 0) - base.Money,
        (tonumber(data.Rolls) or 0) - base.Rolls,
        (tonumber(data.Rebirth) or 0) - base.Rebirth
end

local function webhookActiveAutomationText()
    local active = {}
    local pairsList = {
        {"AD_FastRoll", "Roll"},
        {"AD_ServerAutoRoll", "Server Roll"},
        {"AD_AutoBuyDice", "Dice"},
        {"AD_AutoEquipDice", "Equip Dice"},
        {"AD_AutoUpgrade", "Upgrade"},
        {"AD_AutoRebirth", "Rebirth"},
        {"AD_AutoCollect", "Collect"},
        {"AD_AutoLevelSlots", "Level"},
        {"AD_AutoTrait", "Trait"},
        {"AD_AutoGrade", "Grade"},
        {"AD_AutoFavorite", "Favorite"},
        {"AD_AutoUnfavorite", "Unfavorite"},
        {"AD_SmartSell", "Sell"},
        {"AD_AutoTower", "Tower"},
        {"AD_AutoDaily", "Daily"},
        {"AD_AutoGroup", "Group"},
        {"AD_AutoOffline", "Offline"},
        {"AD_AutoQuestClaim", "Quests"},
        {"AD_AutoQuestBuy", "Ticket Shop"},
        {"AD_AutoUseSpin", "Spin"},
        {"AD_AutoSpinWeather", "Weather Spin"},
        {"AD_AutoUseBoost", "Boost"},
        {"AD_AutoBoostWeather", "Weather Boost"},
        {"AD_AutoTutorialAdvance", "Tutorial"},
    }

    for _, entry in ipairs(pairsList) do
        if State[entry[1]] == true then
            active[#active + 1] = entry[2]
        end
    end

    return #active > 0 and table.concat(active, " | ") or "Idle"
end

local function webhookTimestamp()
    local ok, value = pcall(function()
        return DateTime.now():ToIsoDate()
    end)
    return ok and value or nil
end

local function currentLicenseText()
    local info = ENV.AliceHUB_LicenseInfo or ENV.AliceHUB_License
    if type(info) == "table" then
        local status = info.status or info.state or info.Status
        if status ~= nil then return tostring(status) end
    end

    local status = ENV.AliceHUB_LicenseStatus or ENV.AliceHUB_LicenseState
    if status ~= nil and tostring(status) ~= "" then
        return tostring(status)
    end

    return "Standalone / loader belum terhubung"
end

local function sendAnimeDiceWebhook(isTest)
    local rawUrl = tostring(State.AD_WebhookURL or "")
    local url = cleanWebhookURL(rawUrl)

    setWebhookStatus("Preparing...")

    if url == "" then
        setWebhookStatus("Webhook URL kosong")
        return false, "Webhook URL kosong"
    end

    if not url:find("discord.com/api/webhooks/", 1, true)
        and not url:find("discordapp.com/api/webhooks/", 1, true) then
        setWebhookStatus("URL bukan Discord webhook")
        return false, "URL harus berupa Discord webhook"
    end

    local req, reqName = getExecutorRequest()
    if type(req) ~= "function" then
        setWebhookStatus("No request API · executor unsupported")
        return false, "request API unavailable"
    end

    local data = getData() or {}
    local moneyDelta, rollsDelta, rebirthDelta = getSessionDeltas(data)
    local weather = type(C.weatherSnapshot) == "function" and C.weatherSnapshot() or {name="None", effect="N/A", remaining=nil}

    local payload = {
        username = "AliceHUB",
        embeds = {{
            title = isTest and "AliceHUB · Anime Dice · Test" or "AliceHUB · Anime Dice",
            description = "Automation status update",
            color = 11874387,
            fields = {
                {name = "Username", value = tostring(LocalPlayer.Name), inline = true},
                {
                    name = "Money",
                    value = ("%s (%s)"):format(
                        compactNumber(data.Money),
                        signedCompact(moneyDelta)
                    ),
                    inline = true
                },
                {
                    name = "Rolls",
                    value = ("%s (%s)"):format(
                        compactNumber(data.Rolls),
                        signedCompact(rollsDelta)
                    ),
                    inline = true
                },
                {
                    name = "Rebirth",
                    value = ("%s (%s)"):format(
                        compactNumber(data.Rebirth),
                        signedCompact(rebirthDelta)
                    ),
                    inline = true
                },
                {name = "Dice", value = tostring(data.Dice or "N/A"), inline = true},
                {name = "Weather", value = tostring(weather.name or "None"), inline = true},
                {name = "Weather Effect", value = tostring(weather.effect or "N/A") .. (weather.remaining and (" · " .. tostring(weather.remaining)) or ""), inline = true},
                {name = "Active", value = tostring(webhookActiveAutomationText()), inline = false},
                {name = "License", value = currentLicenseText(), inline = false},
            },
            footer = {text = "AliceHUB · Anime Dice"},
            timestamp = webhookTimestamp(),
        }}
    }

    local okEncode, body = pcall(HttpService.JSONEncode, HttpService, payload)
    if not okEncode then
        setWebhookStatus("JSON error: " .. tostring(body):sub(1, 70))
        return false, body
    end

    local targetUrl = withWebhookWait(url)
    setWebhookStatus("Sending via " .. tostring(reqName) .. "...")

    local function runRequest(urlKey)
        local requestData = {
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "AliceHUB-AnimeDice",
            },
            Body = body,
        }
        requestData[urlKey] = targetUrl
        return pcall(req, requestData)
    end

    local ok, response = runRequest("Url")

    -- Retry URL jika wrapper request mengembalikan respons kosong.

    if not ok or response == nil then
        local ok2, response2 = runRequest("URL")
        if ok2 or response == nil then
            ok, response = ok2, response2
        end
    end

    if not ok then
        local err = tostring(response)
        setWebhookStatus(("Request error via %s · %s"):format(
            tostring(reqName),
            err:sub(1, 90)
        ))
        return false, err
    end

    local code = nil
    local successField = nil
    local responseBody = ""

    if type(response) == "table" then
        code = tonumber(
            response.StatusCode
            or response.Status
            or response.status_code
            or response.status
            or response.Code
        )

        if response.Success ~= nil then
            successField = response.Success == true
        elseif response.success ~= nil then
            successField = response.success == true
        end

        responseBody = tostring(
            response.Body
            or response.ResponseBody
            or response.body
            or response.Message
            or ""
        )
    else
        responseBody = tostring(response or "")
    end

    if code and code >= 200 and code < 300 then
        setWebhookStatus(("Sent · HTTP %d · %s"):format(code, tostring(reqName)))
        return true, response
    end

    if code == nil and successField == true then
        setWebhookStatus("Sent · " .. tostring(reqName) .. " success=true")
        return true, response
    end

    if code == nil then
        local preview = responseBody:gsub("%s+", " "):sub(1, 100)
        if preview == "" then preview = "<empty response>" end

        setWebhookStatus(("Unknown response · %s · %s"):format(
            tostring(reqName),
            preview
        ))
        return false, "No HTTP status: " .. preview
    end

    local detail = responseBody:gsub("%s+", " "):sub(1, 100)
    local status = ("Failed · HTTP %d · %s"):format(code, tostring(reqName))
    if detail ~= "" then
        status = status .. " · " .. detail
    end

    setWebhookStatus(status)
    return false, status
end

C.SendWebhookNow = sendAnimeDiceWebhook
if C.PendingWeatherWebhook and State.AD_WeatherWebhook == true then
    task.defer(function()
        C.PendingWeatherWebhook = nil
        pcall(C.SendWebhookNow, false)
    end)
end

C.WebhookGeneration = 0

local function updateWebhookLoop(enabled)
    C.WebhookGeneration += 1
    local generation = C.WebhookGeneration

    if enabled ~= true then
        setWebhookStatus("Disabled")
        return
    end

    task.spawn(function()
        while Runtime.alive
            and State.AD_WebhookEnabled == true
            and C.WebhookGeneration == generation do

            local url = cleanWebhookURL(State.AD_WebhookURL)
            if url == "" then
                setWebhookStatus("Enabled · waiting for URL")
            else
                sendAnimeDiceWebhook(false)
            end

            local remaining = math.max(
                30,
                tonumber(State.AD_WebhookInterval) or 300
            )

            while remaining > 0
                and Runtime.alive
                and State.AD_WebhookEnabled == true
                and C.WebhookGeneration == generation do
                task.wait(1)
                remaining -= 1
            end
        end
    end)
end

addInput(
    C.WebhookSetup,
    "AD_WebhookURL",
    "Discord Webhook URL",
    "",
    "https://discord.com/api/webhooks/...",
    function()
        setWebhookStatus(State.AD_WebhookEnabled and "URL updated" or "Idle")
    end
)

addSlider(C.WebhookSetup, "AD_WebhookInterval", "Send Interval", 30, 1800, 300, 0, "s")
addToggle(
    C.WebhookSetup,
    "AD_WebhookEnabled",
    "Enable Webhook",
    false,
    "Sends AliceHUB Anime Dice status to your Discord webhook.",
    updateWebhookLoop
)

C.WebhookActions:AddButton({Text = "Send Test Webhook", Func = function()
    setWebhookStatus("Test clicked...")
    task.spawn(function()
        local okCall, ok, result = xpcall(function()
            local success, response = sendAnimeDiceWebhook(true)
            return success, response
        end, function(reason)
            local message = tostring(reason)
            pcall(function()
                if debug and type(debug.traceback) == "function" then
                    message = debug.traceback(message, 2)
                end
            end)
            return message
        end)

        if not okCall then
            setWebhookStatus("Lua error · " .. tostring(ok):sub(1, 100))
            notify("Webhook Lua error: " .. tostring(ok):sub(1, 160), 7)
            return
        end

        notify(ok and "Webhook test sent" or ("Webhook failed: " .. tostring(result)), 6)
    end)
end})
C.WebhookActions:AddButton({Text = "Check Webhook", Func = function()
    local req, reqName = getExecutorRequest()
    local url = cleanWebhookURL(State.AD_WebhookURL)
    local urlState = url == "" and "empty"
        or (url:find("/api/webhooks/", 1, true) and "looks valid" or "invalid format")

    setWebhookStatus(("Check · request=%s · URL=%s · len=%d"):format(
        tostring(reqName),
        urlState,
        #url
    ))
end})

C.WebhookActions:AddLabel("Money, Rolls, dan Rebirth menampilkan perubahan selama sesi. Check Webhook hanya mengecek dukungan request executor.", true)

C.InventoryWebhookGeneration = 0
C.updateInventoryWebhookLoop = function(enabled)
    C.InventoryWebhookGeneration += 1
    local generation = C.InventoryWebhookGeneration
    if enabled ~= true then C.setInventoryWebhookStatus("Disabled"); return end

    task.spawn(function()
        while Runtime.alive
            and State.AD_InventoryWebhookEnabled == true
            and C.InventoryWebhookGeneration == generation do
            C.sendInventoryWebhook(false)
            local remaining = math.max(30, tonumber(State.AD_InventoryWebhookInterval) or 600)
            while remaining > 0
                and Runtime.alive
                and State.AD_InventoryWebhookEnabled == true
                and C.InventoryWebhookGeneration == generation do
                task.wait(1)
                remaining -= 1
            end
        end
    end)
end

addToggle(C.InventoryWebhook, "AD_InventoryWebhookEnabled", "Enable Inventory Webhook", false,
    "Sends selected inventory sections on its own interval.", C.updateInventoryWebhookLoop)
addSlider(C.InventoryWebhook, "AD_InventoryWebhookInterval", "Inventory Interval", 30, 3600, 600, 0, "s")
addToggle(C.InventoryWebhook, "AD_InventoryWebhookUnits", "Include Units", true)
addToggle(C.InventoryWebhook, "AD_InventoryWebhookItems", "Include Items", true)
addToggle(C.InventoryWebhook, "AD_InventoryWebhookStats", "Include Stats", true)
C.InventoryWebhook:AddButton({Text = "Send Inventory Now", Func = function()
    task.spawn(function()
        local ok, result = C.sendInventoryWebhook(true)
        notify(ok and "Inventory webhook sent" or ("Inventory webhook failed: " .. tostring(result)), 6)
    end)
end})

if State.AD_WebhookEnabled == true then
    task.defer(function()
        updateWebhookLoop(true)
    end)
end
if State.AD_InventoryWebhookEnabled == true then
    task.defer(function()
        C.updateInventoryWebhookLoop(true)
    end)
end

-- ============================================================
-- White Screen

-- ============================================================
C.AliceWhiteScreen = {
    enabled = false,
    generation = 0,
    gui = nil,
    startAt = os.clock(),
    savedFPSCap = nil,
    savedMainVisible = true,
    disabled3D = false,
}

C.cleanupAliceWhiteScreenGui = function()
    local roots = {LocalPlayer:FindFirstChildOfClass("PlayerGui"), CoreGui}
    if type(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then table.insert(roots, 2, root) end
    end
    for _, root in ipairs(roots) do
        if root then
            local old = root:FindFirstChild("AliceHUB_AnimeDice_WhiteScreen")
            if old then pcall(function() old:Destroy() end) end
        end
    end
end

C.getPing = function()
    local value = 0
    pcall(function()
        value = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return value
end

C.activeAutomationText = function()
    return webhookActiveAutomationText()
end

C.stopAliceWhiteScreen = function()
    local wasEnabled = C.AliceWhiteScreen.enabled
    C.AliceWhiteScreen.enabled = false
    C.AliceWhiteScreen.generation += 1

    if C.AliceWhiteScreen.disabled3D then
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
    end
    C.AliceWhiteScreen.disabled3D = false

    if C.AliceWhiteScreen.savedFPSCap ~= nil and type(setfpscap) == "function" then
        pcall(setfpscap, C.AliceWhiteScreen.savedFPSCap)
    end
    C.AliceWhiteScreen.savedFPSCap = nil

    C.cleanupAliceWhiteScreenGui()
    C.AliceWhiteScreen.gui = nil

    if wasEnabled and State.AD_WhiteScreenHideUI == true then
        setMainWindowVisible(C.AliceWhiteScreen.savedMainVisible ~= false)
    end
end

C.whiteScreenCapText = function()
    if type(getfpscap) == "function" then
        local ok, cap = pcall(getfpscap)
        if ok and tonumber(cap) then return tostring(math.floor(tonumber(cap))) end
    end
    return tostring(math.floor(tonumber(State.AD_WhiteScreenFPSCap) or 10))
end

C.applyWhiteScreenFpsCap = function()
    local cap = math.clamp(math.floor(tonumber(State.AD_WhiteScreenFPSCap) or 10), 5, 30)
    -- Simpan FPS cap sebelum diubah.
    if type(setfpscap) == "function" and type(getfpscap) == "function" then
        if C.AliceWhiteScreen.savedFPSCap == nil then
            local ok, old = pcall(getfpscap)
            if ok and tonumber(old) then C.AliceWhiteScreen.savedFPSCap = tonumber(old) end
        end
        pcall(setfpscap, cap)
        return true
    end
    return false
end

C.startAliceWhiteScreen = function()
    if C.AliceWhiteScreen.enabled then return end
    C.stopAliceWhiteScreen()
    C.AliceWhiteScreen.enabled = true
    ensureAliceSessionBaseline()
    C.AliceWhiteScreen.startAt = C.AliceSessionStats.startAt
    C.AliceWhiteScreen.generation += 1
    local generation = C.AliceWhiteScreen.generation

    C.AliceWhiteScreen.savedMainVisible = MainWindowVisible ~= false
    if State.AD_WhiteScreenHideUI == true then
        setMainWindowVisible(false)
    end

    if State.AD_WhiteScreenDisable3D == true then
        local ok = pcall(function() RunService:Set3dRenderingEnabled(false) end)
        C.AliceWhiteScreen.disabled3D = ok == true
    end
    C.applyWhiteScreenFpsCap()

    C.cleanupAliceWhiteScreenGui()

    local screen = Instance.new("ScreenGui")
    screen.Name = "AliceHUB_AnimeDice_WhiteScreen"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 2147483647
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Prioritaskan PlayerGui.
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    pcall(function() screen.Parent = pg end)
    if not screen.Parent and type(gethui) == "function" then
        pcall(function() screen.Parent = gethui() end)
    end
    if not screen.Parent then pcall(function() screen.Parent = CoreGui end) end
    C.AliceWhiteScreen.gui = screen

    local background = Instance.new("Frame")
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = screen

    local currentViewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 600)
    local buttonH = math.clamp(math.floor(math.min(currentViewport.X, currentViewport.Y) * 0.062), 34, 48)
    local exit = Instance.new("TextButton")
    exit.Name = "ExitWhiteScreen"
    exit.AnchorPoint = Vector2.new(1, 0)
    exit.Position = UDim2.new(1, -12, 0, 12)
    exit.Size = UDim2.fromOffset(math.max(126, buttonH * 3), buttonH)
    exit.BackgroundColor3 = Color3.fromRGB(132, 30, 49)
    exit.BorderSizePixel = 0
    exit.Text = "EXIT WHITE SCREEN"
    exit.Font = Enum.Font.Code
    exit.TextColor3 = Color3.fromRGB(255, 255, 255)
    exit.TextSize = math.clamp(math.floor(buttonH * 0.34), 11, 15)
    exit.ZIndex = 20
    exit.Parent = screen
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 7)
    exitCorner.Parent = exit
    exit.Activated:Connect(function()
        local toggle = Toggles.AD_WhiteScreen
        if toggle and type(toggle.SetValue) == "function" then
            toggle:SetValue(false)
        else
            C.stopAliceWhiteScreen()
        end
    end)

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.new(0.94, 0, 0.78, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = background

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = holder

    local baseSize = math.clamp(math.floor(math.min(currentViewport.X, currentViewport.Y) * 0.038), 13, 28)
    local labels = {}
    for index = 1, 11 do
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, math.floor(baseSize * 1.45))
        label.Font = Enum.Font.Code
        label.TextSize = index == 1 and math.floor(baseSize * 1.38) or baseSize
        label.TextColor3 = index == 1 and Color3.fromRGB(214, 77, 112) or Color3.fromRGB(240, 240, 240)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextWrapped = true
        label.LayoutOrder = index
        label.Parent = holder
        labels[index] = label
    end

    task.spawn(function()
        while Runtime.alive and C.AliceWhiteScreen.enabled and C.AliceWhiteScreen.generation == generation and screen.Parent do
            local data = getData() or {}
            local inventoryUnits = 0
            if type(data.Inventory) == "table" then
                for uuid in pairs(data.Inventory) do if isUUID(uuid) then inventoryUnits += 1 end end
            end

            local uptime = math.max(0, math.floor(os.clock() - C.AliceWhiteScreen.startAt))
            local hours = math.floor(uptime / 3600)
            local minutes = math.floor((uptime % 3600) / 60)
            local seconds = uptime % 60
            local moneyDelta, rollsDelta, rebirthDelta = getSessionDeltas(data)

            local rows = {
                "ALICEHUB",
                "Anime Dice  ·  White Screen V2",
                "User: " .. tostring(LocalPlayer.Name),
                string.format("Uptime: %02d:%02d:%02d   Ping: %dms   Players: %d", hours, minutes, seconds, C.getPing(), #Players:GetPlayers()),
                string.format("Money: %s  (%s)", compactNumber(data.Money), signedCompact(moneyDelta)),
                string.format("Rolls: %s (%s)   Rebirth: %s (%s)", compactNumber(data.Rolls), signedCompact(rollsDelta), compactNumber(data.Rebirth), signedCompact(rebirthDelta)),
                string.format("Dice: %s   Units: %d", tostring(data.Dice or "N/A"), inventoryUnits),
                "Auto: " .. C.activeAutomationText(),
                string.format("3D: %s   FPS Cap: %s", C.AliceWhiteScreen.disabled3D and "OFF" or "ON", C.whiteScreenCapText()),
                string.format("Boost FPS: %s   Ultra Performance: %s", State.AD_BoostFPS and "ON" or "OFF", State.AD_UltraPerformance and "ON" or "OFF"),
                "Tap EXIT WHITE SCREEN to return to AliceHUB",
            }
            for index, text in ipairs(rows) do
                if labels[index] then labels[index].Text = text end
            end
            task.wait(1.0)
        end
    end)
end

C.setAliceWhiteScreen = function(value)
    if value then C.startAliceWhiteScreen() else C.stopAliceWhiteScreen() end
end

-- ============================================================
-- Performance

-- ============================================================
C.Lighting = game:GetService("Lighting")
C.SoundService = game:GetService("SoundService")
C.Terrain = workspace:FindFirstChildOfClass("Terrain")

C.BoostFPSRestore = nil
C.UltraPerfGeneration = 0
C.UltraPerfConnections = {}

C.disconnectUltraPerfConnections = function()
    for _, connection in ipairs(C.UltraPerfConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    C.UltraPerfConnections = {}
end

C.isAliceHUBInstance = function(instance)
    if not instance then return false end
    local name = string.lower(tostring(instance.Name or ""))
    if string.find(name, "alicehub", 1, true) or string.find(name, "obsidian", 1, true) then
        return true
    end
    local ok, fullName = pcall(function()
        return string.lower(instance:GetFullName())
    end)
    return ok and (string.find(fullName, "alicehub", 1, true) ~= nil or string.find(fullName, "obsidian", 1, true) ~= nil)
end

C.setBoostFpsEnabled = function(enabled)
    enabled = enabled == true
    if enabled then
        if not C.BoostFPSRestore then
            C.BoostFPSRestore = {}
            pcall(function() C.BoostFPSRestore.quality = settings().Rendering.QualityLevel end)
            pcall(function() C.BoostFPSRestore.userQuality = UserSettings():GetService("UserGameSettings").SavedQualityLevel end)
            pcall(function() C.BoostFPSRestore.globalShadows = C.Lighting.GlobalShadows end)
            pcall(function() C.BoostFPSRestore.fogEnd = C.Lighting.FogEnd end)
            pcall(function() C.BoostFPSRestore.brightness = C.Lighting.Brightness end)
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end)
        pcall(function()
            C.Lighting.GlobalShadows = false
            C.Lighting.FogEnd = 1000000
        end)
        setLastAction("Boost FPS enabled")
    else
        pcall(function()
            settings().Rendering.QualityLevel = (C.BoostFPSRestore and C.BoostFPSRestore.quality) or Enum.QualityLevel.Automatic
        end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = (C.BoostFPSRestore and C.BoostFPSRestore.userQuality) or Enum.SavedQualitySetting.Automatic
        end)
        if C.BoostFPSRestore then
            pcall(function() C.Lighting.GlobalShadows = C.BoostFPSRestore.globalShadows end)
            pcall(function() C.Lighting.FogEnd = C.BoostFPSRestore.fogEnd end)
            pcall(function() C.Lighting.Brightness = C.BoostFPSRestore.brightness end)
        end
        C.BoostFPSRestore = nil
        setLastAction("Boost FPS disabled")
    end
end

C.isProtectedUltraInstance = function(instance)
    if not instance then return true end
    if C.isAliceHUBInstance(instance) then return true end
    local character = LocalPlayer.Character
    if character and (instance == character or instance:IsDescendantOf(character)) then
        return true
    end
    return false
end

C.optimizeUltraInstance = function(instance)
    if not instance or not instance.Parent or C.isProtectedUltraInstance(instance) then return end

    if instance:IsA("BasePart") then
        pcall(function()
            instance.CastShadow = false
            instance.Reflectance = 0
            if not instance:IsA("Terrain") then
                instance.Material = Enum.Material.SmoothPlastic
            end
        end)
        if instance:IsA("MeshPart") then
            pcall(function() instance.TextureID = "" end)
        end
        return
    end

    if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
        or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
        pcall(function() instance.Enabled = false end)
        return
    end

    if instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
        pcall(function() instance.Enabled = false end)
        return
    end

    if instance:IsA("Decal") or instance:IsA("Texture") then
        pcall(function() instance.Transparency = 1 end)
        return
    end

    if instance:IsA("SurfaceAppearance") then
        pcall(function() instance:Destroy() end)
        return
    end

    if instance:IsA("Sound") then
        pcall(function()
            instance.Volume = 0
            instance:Stop()
        end)
        return
    end

    if instance:IsA("PostEffect") then
        pcall(function() instance.Enabled = false end)
        return
    end

    if instance:IsA("Atmosphere") then
        pcall(function()
            instance.Density = 0
            instance.Haze = 0
            instance.Glare = 0
        end)
        return
    end

    if instance:IsA("Clouds") then
        pcall(function()
            instance.Cover = 0
            instance.Density = 0
        end)
        return
    end
end

C.runUltraPerformancePass = function(generation)
    local function active()
        return Runtime.alive and State.AD_UltraPerformance == true and C.UltraPerfGeneration == generation
    end

    C.setBoostFpsEnabled(true)

    pcall(function()
        if C.Terrain then
            C.Terrain.WaterWaveSize = 0
            C.Terrain.WaterWaveSpeed = 0
            C.Terrain.WaterReflectance = 0
            C.Terrain.WaterTransparency = 1
            C.Terrain.Decoration = false
        end
    end)

    pcall(function()
        C.SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    end)

    pcall(function()
        for _, child in ipairs(C.Lighting:GetChildren()) do
            C.optimizeUltraInstance(child)
        end
    end)

    task.spawn(function()
        local descendants = workspace:GetDescendants()
        local index = 1
        while active() and index <= #descendants do
            local processed = 0
            while active() and index <= #descendants and processed < 350 do
                local instance = descendants[index]
                if instance and instance.Parent then
                    pcall(C.optimizeUltraInstance, instance)
                end
                index = index + 1
                processed = processed + 1
            end
            RunService.Heartbeat:Wait()
        end
        if active() then
            setLastAction("Ultra Performance active")
            notify("Ultra Performance active · full visual restore needs rejoin", 5)
        end
    end)

    C.UltraPerfConnections[#C.UltraPerfConnections + 1] = workspace.DescendantAdded:Connect(function(instance)
        if active() then
            task.defer(function()
                pcall(C.optimizeUltraInstance, instance)
            end)
        end
    end)

    C.UltraPerfConnections[#C.UltraPerfConnections + 1] = C.Lighting.ChildAdded:Connect(function(instance)
        if active() then
            task.defer(function()
                pcall(C.optimizeUltraInstance, instance)
            end)
        end
    end)
end

C.setUltraPerformanceEnabled = function(enabled)
    C.disconnectUltraPerfConnections()
    C.UltraPerfGeneration = C.UltraPerfGeneration + 1
    if enabled ~= true then
        setLastAction("Ultra Performance stopped · rejoin to restore visuals")
        return
    end
    local generation = C.UltraPerfGeneration
    task.spawn(function()
        task.wait(0.1)
        if Runtime.alive and State.AD_UltraPerformance == true and C.UltraPerfGeneration == generation then
            C.runUltraPerformancePass(generation)
        end
    end)
end

-- ============================================================
-- Settings tab
-- ============================================================
C.Utility = C.Tabs.Settings:AddLeftGroupbox("Utility")
C.Performance = C.Tabs.Settings:AddLeftGroupbox("Performance")
C.UISettings = C.Tabs.Settings:AddRightGroupbox("AliceHUB")
C.Community = C.Tabs.Settings:AddRightGroupbox("Community & License")
C.GameCompatibility = C.Tabs.Settings:AddRightGroupbox("Game Compatibility")

addToggle(C.Utility, "AD_AntiAFK", "Anti AFK", true, "Pulse berkala + fallback Idled.")
addSlider(C.Utility, "AD_AntiAFKInterval", "Anti AFK Pulse", 20, 120, 45, 0, "s")
addToggle(C.Utility, "AD_WhiteScreen", "White Screen V2", false, "Layar AFK dengan opsi matikan 3D dan batas FPS.", C.setAliceWhiteScreen)
addToggle(C.Utility, "AD_WhiteScreenDisable3D", "White Screen · Disable 3D", true, "Mematikan render 3D selama White Screen aktif.")
addToggle(C.Utility, "AD_WhiteScreenHideUI", "White Screen · Hide Main UI", true, "Menyembunyikan menu AliceHUB saat White Screen aktif.")
addSlider(C.Utility, "AD_WhiteScreenFPSCap", "White Screen · FPS Cap", 5, 30, 10, 0, " FPS", function(value)
    if C.AliceWhiteScreen.enabled then
        State.AD_WhiteScreenFPSCap = value
        C.applyWhiteScreenFpsCap()
    end
end)
addToggle(C.Utility, "AD_AutoReconnect", "Auto Reconnect", true, "Reconnect saat Roblox terputus.")
addToggle(C.Utility, "AD_AutoRejoin", "Scheduled Auto Rejoin", false, "Rejoin berkala untuk sesi AFK panjang.")
addSlider(C.Utility, "AD_AutoRejoinMinutes", "Rejoin Every", 5, 120, 30, 0, "m")

addToggle(C.Performance, "AD_BoostFPS", "Boost FPS + Low Graphics", false, "Mengurangi efek visual untuk menaikkan FPS.", C.setBoostFpsEnabled)
addToggle(C.Performance, "AD_UltraPerformance", "Ultra Performance", false, "Mengurangi visual lebih agresif. Rejoin untuk restore penuh.", C.setUltraPerformanceEnabled)

C.UISettings:AddLabel("Theme: AliceHUB UI", true)
C.UISettings:AddLabel("Subtitle: Anime Dice", true)
C.UISettings:AddButton({Text = "Hide / Show UI", Func = function()
    toggleMainWindow()
end})
C.UISettings:AddButton({Text = "Save Settings", Func = function()
    saveState()
    notify("Settings saved")
end})
C.UISettings:AddButton({Text = "Reset Settings", Func = function()
    if type(delfile) == "function" then pcall(delfile, SETTINGS_FILE) end
    notify("Config reset. Re-execute AliceHUB.", 4)
end})

C.ALICEHUB_DISCORD = "https://discord.gg/teUcVxmTd"

C.LicenseStatusLabel = C.Community:AddLabel("License: " .. currentLicenseText(), true)

C.Community:AddButton({Text = "Copy Discord Link", Func = function()
    local copied = false
    if type(setclipboard) == "function" then
        copied = pcall(setclipboard, C.ALICEHUB_DISCORD)
    elseif type(toclipboard) == "function" then
        copied = pcall(toclipboard, C.ALICEHUB_DISCORD)
    end

    notify(copied and "Discord link copied" or ("Discord: " .. C.ALICEHUB_DISCORD), 5)
end})

C.Community:AddLabel("Discord: " .. C.ALICEHUB_DISCORD, true)

C.Community:AddButton({Text = "Refresh License Status", Func = function()
    if C.LicenseStatusLabel and type(C.LicenseStatusLabel.SetText) == "function" then
        C.LicenseStatusLabel:SetText("License: " .. currentLicenseText())
    end
    notify("License status refreshed")
end})

C.Community:AddLabel("Status license mengikuti data dari AliceHUB Loader.", true)

local function compatibilityText()
    refreshRemotes()
    local settingsStatus = C.SetGameSettingRE and "Detected" or "Missing"
    local tradeStatus = C.TradingEnabledRP and "Detected" or "Missing"
    local fuseStatus = (C.FuseRE and C.FuseResultRE) and "Detected" or "Missing"
    return ("SettingsService: %s\nTrading state: %s\nFusingService: %s"):format(settingsStatus, tradeStatus, fuseStatus)
end

C.GameCompatibility:AddLabel(compatibilityText(), true)
C.GameCompatibility:AddButton({Text = "Refresh Game Compatibility", Func = function()
    notify(compatibilityText(), 5)
end})
C.GameCompatibility:AddLabel("Native Settings detected without guessing SetSetting arguments.", true)

-- Floating AliceHUB logo.

C.remoteHealthText = function()
    local remotes = {
        {"RollDice", C.RollRF}, {"RollMessage", C.RollMessageRE}, {"SetAutoRoll", C.SetAutoRollRE},
        {"BuyDice", C.BuyDiceRE}, {"EquipDice", C.EquipDiceRE}, {"BuyUpgrade", C.BuyUpgradeRE},
        {"Rebirth", C.RebirthRE}, {"PlotEquipBest", C.PlotEquipBestRE}, {"CollectBalance", C.CollectBalanceRE},
        {"InteractSlot", C.InteractSlotRE}, {"LevelUpSlot", C.LevelUpSlotRE}, {"LevelUpSuccess", C.LevelUpSuccessRE},
        {"TextNotification", C.TextNotificationRE}, {"DropNotification", C.DropNotificationRE}, {"TraitRoll", C.TraitRollRE},
        {"GradeRoll", C.GradeRollRE}, {"SellInventory", C.SellInventoryRF}, {"SellEquipped", C.SellEquippedRF},
        {"UnitSetLocked", C.UnitSetLockedRE}, {"UnitEquip", C.UnitEquipRF}, {"UnitUnequip", C.UnitUnequipRF},
        {"Fuse", C.FuseRE}, {"FuseResult", C.FuseResultRE},
        {"PlayTower", C.PlayTowerRF}, {"CompleteTower", C.CompleteTowerFloorRF}, {"CancelTower", C.CancelTowerRF},
        {"TowerEquipBest", C.EquipBestTowerTeamRE}, {"TowerUpdateTeam", C.UpdateTowerTeamRE},
        {"Daily", C.DailyClaimRE}, {"Group", C.GroupClaimRE}, {"Offline", C.OfflineClaimRE},
        {"QuestClaim", C.QuestClaimRE}, {"QuestBuy", C.QuestBuyRE}, {"SpinUse", C.SpinUseRE},
        {"Weather", C.ActiveWeatherRemote}, {"BoostUse", C.BoostUseRE}, {"RedeemCode", C.RedeemCodeRE}, {"Tutorial", C.OnboardingAdvanceRE},
        {"TradeRequest", C.TradeRequestRE}, {"TradeOffer", C.TradeChangeOfferRE}, {"TradeAdvance", C.TradeAdvanceRE},
        {"SettingsService", C.SetGameSettingRE}, {"TradingEnabled", C.TradingEnabledRP},
    }
    local found, missing, missingNames = 0, 0, {}
    for _, row in ipairs(remotes) do
        if row[2] then found += 1 else missing += 1; missingNames[#missingNames + 1] = row[1] end
    end
    local props = string.format("Props: Buff=%s | Equipped=%s | Plot=%s | Limited=%s | Weather=%s",
        C.BuffCacheProperty and "OK" or "...", C.EquippedUnitProperty and "OK" or "...",
        C.PlotIdProperty and "OK" or "...", C.LimitedStockProperty and "OK" or "...",
        C.ActiveWeatherProperty and "OK" or (C.ActiveWeatherRemote and "RP" or "..."))
    return string.format("Remote status · %d OK / %d missing\n%s%s",
        found, missing, props, #missingNames > 0 and ("\nMissing: " .. table.concat(missingNames, ", ")) or "")
end

-- ============================================================
-- Anti-AFK + reconnect
-- ============================================================
C.antiAfkPulse = function()
    if State.AD_AntiAFK ~= true or not Runtime.alive then return end

    -- Pulse Anti AFK.
    pcall(function()
        local camera = workspace.CurrentCamera
        VirtualUser:CaptureController()
        if camera then
            VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
            task.wait(0.04)
            VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
        else
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)

    -- Fallback input untuk executor mobile.

    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
        end)
    end
end

rememberConnection(LocalPlayer.Idled:Connect(function()
    task.spawn(C.antiAfkPulse)
end))

task.spawn(function()
    while Runtime.alive do
        task.wait(math.max(20, tonumber(State.AD_AntiAFKInterval) or 45))
        if Runtime.alive and State.AD_AntiAFK == true then
            C.antiAfkPulse()
        end
    end
end)

C.reconnectBusy = false
C.promptOverlay = findPath(CoreGui, "RobloxPromptGui", "promptOverlay")
if C.promptOverlay then
    rememberConnection(C.promptOverlay.ChildAdded:Connect(function(child)
        if State.AD_AutoReconnect ~= true or C.reconnectBusy then return end
        if not child:IsA("Frame") or child.Name ~= "ErrorPrompt" then return end
        C.reconnectBusy = true
        task.delay(2.5, function()
            if not Runtime.alive then return end
            local queue = queue_on_teleport or queueonteleport
            local source = ENV.AliceHUB_AnimeDice_ReexecuteSource or ENV.AliceHUB_ReexecuteSource
            if type(queue) == "function" and type(source) == "string" and source ~= "" then
                pcall(queue, source)
            end
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            task.wait(6)
            C.reconnectBusy = false
        end)
    end))
end

-- Rejoin berkala untuk AFK panjang.
C.scheduledRejoinStarted = os.clock()
task.spawn(function()
    while Runtime.alive do
        if State.AD_AutoRejoin == true then
            local target = math.max(5, tonumber(State.AD_AutoRejoinMinutes) or 30) * 60
            if os.clock() - C.scheduledRejoinStarted >= target then
                C.scheduledRejoinStarted = os.clock()
                setLastAction("Scheduled rejoin")
                local queue = queue_on_teleport or queueonteleport
                local source = ENV.AliceHUB_AnimeDice_ReexecuteSource or ENV.AliceHUB_ReexecuteSource
                if type(queue) == "function" and type(source) == "string" and source ~= "" then pcall(queue, source) end
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                task.wait(8)
            end
        else
            C.scheduledRejoinStarted = os.clock()
        end
        task.wait(1)
    end
end)

-- ============================================================
-- Live status worker
-- ============================================================
C.didInitialUnitRefresh = false
task.spawn(function()
    while Runtime.alive do
        local data = getData()
        if data then
            if not C.didInitialUnitRefresh then
                C.didInitialUnitRefresh = true
                local values = buildUnitLabels()
                C.UnitLabels = values
                local option = Options.AD_TargetUnit
                if option and type(option.SetValues) == "function" then
                    pcall(option.SetValues, option, values)
                    local first = values[1]
                    if C.UnitLabelToUUID[first] and type(option.SetValue) == "function" then pcall(option.SetValue, option, first) end
                end
            end
            local units = 0
            if type(data.Inventory) == "table" then
                for uuid in pairs(data.Inventory) do if isUUID(uuid) then units += 1 end end
            end
            local text = string.format(
                "User: %s\nMoney: %s\nRolls: %s\nRebirth: %s\nDice: %s\nUnits: %d\nTrait Reroll: %s\nPing: %dms",
                LocalPlayer.Name,
                compactNumber(data.Money),
                compactNumber(data.Rolls),
                compactNumber(data.Rebirth),
                tostring(data.Dice or "N/A"),
                units,
                compactNumber(getInventoryAmount("Trait Reroll")),
                C.getPing()
            )
            pcall(function() C.StatusLabel:SetText(text) end)
        else
            pcall(function() C.StatusLabel:SetText("Waiting for DataController...") end)
        end
        pcall(function() C.ActionLabel:SetText("Action: " .. Runtime.lastAction) end)
        pcall(function()
            if C.QuestStatusLabel then C.QuestStatusLabel:SetText(questSummary() .. "\nTickets: " .. compactNumber(getInventoryAmount("Tickets"))) end
        end)
        pcall(function()
            if C.ConsumableStatusLabel then
                local lucky = getInventoryAmount("Lucky Spin")
                local jackpot = getInventoryAmount("Jackpot Spin")
                local queuedLucky = activeEntry("Lucky Spin")
                local queuedJackpot = activeEntry("Jackpot Spin")
                C.ConsumableStatusLabel:SetText(("Lucky Spin: %s | queued %s\nJackpot Spin: %s | queued %s\nTrait Reroll: %s | Gems: %s"):format(
                    compactNumber(lucky), compactNumber(queuedLucky and queuedLucky.amount or 0),
                    compactNumber(jackpot), compactNumber(queuedJackpot and queuedJackpot.amount or 0),
                    compactNumber(getInventoryAmount("Trait Reroll")), compactNumber(getInventoryAmount("Gems"))
                ))
            end
        end)
        pcall(function() if C.LimitedStatusLabel then C.LimitedStatusLabel:SetText(limitedStockText()) end end)
        pcall(function() if C.TowerTeamStatusLabel then C.TowerTeamStatusLabel:SetText(towerTeamSummaryText()) end end)
        pcall(function() if C.IndexStatusLabel then C.IndexStatusLabel:SetText(indexProgressSummary()) end end)
        pcall(function() if C.TutorialStatusLabel then C.TutorialStatusLabel:SetText(onboardingSummary()) end end)
        pcall(function() if C.BuffStatusLabel then C.BuffStatusLabel:SetText(effectiveBuffText()) end end)
        pcall(C.updateWeatherStatus)
        pcall(updateFavoriteSummary)
        pcall(updateInventoryManagerSummary)
        pcall(function() if C.RemoteHealthLabel then C.RemoteHealthLabel:SetText(C.remoteHealthText()) end end)
        pcall(updateTradeStatusLabel)
        task.wait(0.6)
    end
end)

-- ============================================================
-- Start saved automation states
-- ============================================================
C.kickSavedToggle = function(id)
    local toggle = Toggles[id]
    if toggle and toggle.Value == true and type(toggle.SetValue) == "function" then
        toggle:SetValue(false)
        task.defer(function() toggle:SetValue(true) end)
    end
end

for _, id in ipairs({
    "AD_FastRoll", "AD_ServerAutoRoll", "AD_AutoBuyDice", "AD_AutoEquipDice", "AD_AutoUpgrade",
    "AD_AutoRebirth", "AD_AutoEquipUnits", "AD_AutoCollect", "AD_AutoLevelSlots", "AD_AutoTrait",
    "AD_AutoGrade", "AD_AutoFavorite", "AD_AutoUnfavorite", "AD_SmartSell", "AD_AutoTower", "AD_AutoDaily", "AD_AutoGroup", "AD_AutoOffline",
    "AD_AutoQuestClaim", "AD_AutoQuestBuy", "AD_AutoUseSpin", "AD_AutoUseBoost", "AD_AutoTutorialAdvance",
    "AD_WhiteScreen", "AD_BoostFPS", "AD_UltraPerformance",
}) do
    C.kickSavedToggle(id)
end

-- Coba claim reward saat masuk.
task.defer(function()
    if State.AD_AutoOffline then fire(C.OfflineClaimRE) end
    if State.AD_AutoDaily then fire(C.DailyClaimRE) end
    if State.AD_AutoGroup then fire(C.GroupClaimRE) end
    fire(C.TradeRequestsEnabledRE, State.AD_TradeRequestsEnabled == true)
    local threshold = parseCompactInput(State.AD_ServerAutoSellThreshold)
    if State.AD_AutoFavorite == true and State.AD_FavoriteSafetyDisableNativeSell == true then
        fire(C.UpdateAutoSellRE, 0)
    elseif threshold and threshold > 0 then
        fire(C.UpdateAutoSellRE, threshold)
    end
end)

notify("AliceHUB Anime Dice loaded", 4)
setLastAction("Loaded")

-- ============================================================
-- Cleanup API
-- ============================================================
ENV.AliceHUB_AnimeDice_Cleanup = function()
    Runtime.alive = false
    for id in pairs(Runtime.loopTokens) do stopLoop(id) end
    pcall(function() fire(C.SetAutoRollRE, false) end)
    pcall(C.stopAliceWhiteScreen)
    pcall(function() C.setUltraPerformanceEnabled(false) end)
    pcall(function() C.setBoostFpsEnabled(false) end)
    pcall(cleanupLogo)
    pcall(__aliceBootDestroy)
    for _, connection in ipairs(Runtime.connections) do pcall(function() connection:Disconnect() end) end
    pcall(function() Library:Unload() end)
    if ENV.AliceHUB_AnimeDice_Library == Library then ENV.AliceHUB_AnimeDice_Library = nil end
end
