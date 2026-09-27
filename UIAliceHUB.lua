--[[
    AliceHUB UI - AnimeDice Native Renderer
    Reusable UI-only build extracted from the AliceHUB AnimeDice interface.

    Basic usage:

    local AliceUI = loadstring(readfile("AliceHUB_UI_AnimeDice.lua"))()
    local Library, Window = AliceUI:Create("My Game")

    local Main = Window:AddTab("Main", "home")
    local Farm = Main:AddLeftGroupbox("Automation")

    Farm:AddToggle("AutoFarm", {Text = "Auto Farm", Default = false})
        :OnChanged(function(value)
            print("Auto Farm:", value)
        end)

    Farm:AddDropdown("Mode", {
        Text = "Mode",
        Values = {"Normal", "Fast", "Safe"},
        Default = "Normal",
    })

    Farm:AddInput("Amount", {Text = "Amount", Default = "100"})
    Farm:AddSlider("Speed", {Text = "Speed", Min = 1, Max = 100, Default = 25, Rounding = 0})
    Farm:AddButton({Text = "Run", Func = function() print("Run") end})

    Library:Notify({Title = "AliceHUB", Description = "Ready", Time = 2.5})

    Public API:
      AliceUI:Create(gameName, options) -> Library, Window
      AliceUI:NewLibrary(options)       -> Library
      AliceUI:SetLogo(asset)
      AliceUI:Destroy()

    Library:
      :CreateWindow(config), :Notify(config), :Toggle([bool]), :Unload()
      .Toggles[id], .Options[id], .ScreenGui

    Window:
      :AddTab(name, icon), :Show(), :Hide(), :SetVisible(bool)

    Tab:
      :AddLeftGroupbox(title), :AddRightGroupbox(title)

    Groupbox:
      :AddLabel(text, wrap)
      :AddButton({Text=..., Func=function() end})
      :AddToggle(id, {Text=..., Default=...})
      :AddInput(id, {Text=..., Default=..., Placeholder=...})
      :AddSlider(id, {Text=..., Min=..., Max=..., Default=..., Rounding=..., Suffix=...})
      :AddDropdown(id, {Text=..., Values={...}, Default=..., Multi=...})
]]

local AliceHUBUI = {
    Version = "AnimeDice-Native-1.0",
    Logo = "rbxassetid://71638246809611",
}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local ALICE_HEADER_LOGO_ASSET = AliceHUBUI.Logo
local __aliceLogoTargets = {}

local function __aliceApplyLogoTarget(imageObject, fallbackObject)
    local asset = ALICE_HEADER_LOGO_ASSET
    if imageObject and imageObject.Parent then
        pcall(function()
            imageObject.Image = asset or ""
            imageObject.ImageTransparency = asset and 0 or 1
        end)
    end
    if fallbackObject and fallbackObject.Parent then
        pcall(function()
            fallbackObject.Visible = asset == nil or asset == ""
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

local function buildAliceNativeLibrary(config)
    config = config or {}
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
    local resolvedGuiName = tostring(config.GuiName or "AliceHUB_NativeUI")
    local old = root:FindFirstChild(resolvedGuiName)
    if old then pcall(function() old:Destroy() end) end

    local screen = Instance.new("ScreenGui")
    screen.Name = resolvedGuiName
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
        local windowLogo = cfg.Icon or config.Icon or ALICE_HEADER_LOGO_ASSET
        icon.Image = windowLogo or ""
        icon.ImageTransparency = windowLogo and 0 or 1
        icon.ScaleType = Enum.ScaleType.Crop
        icon.Parent = iconHolder
        __aliceRegisterLogoTarget(icon, iconFallback)
        corner(icon, 8)
        iconFallback.Visible = not (windowLogo ~= nil)
        if windowLogo then
            icon.ImageTransparency = 0
            iconFallback.Visible = false
        end

        local title = newText(top, (cfg.Title or "AliceHUB") .. " ", 18, true)
        title.Name = "AliceHUBMainTitle"
        title.Position = UDim2.fromOffset(56, 6)
        title.Size = UDim2.new(1, -118, 0, 23)
        title.TextColor3 = L.Scheme.FontColor

        local subtitle = newText(top, tostring(cfg.Subtitle or config.GameName or "AliceHUB"), 11, false)
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
            task.delay(0.12, function() hideBusy = false end)
        end
        hide.Activated:Connect(hideNow)
        hide.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                hideNow()
            end
        end)

        local tabRail = Instance.new("Frame")
        tabRail.Position = UDim2.fromOffset(0, 52)
        tabRail.Size = UDim2.new(0, 142, 1, -82)
        tabRail.BackgroundColor3 = Color3.fromRGB(15, 11, 13)
        tabRail.BorderSizePixel = 0
        tabRail.Parent = main
        padding(tabRail, 8, 8, 10, 8)
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Padding = UDim.new(0, 6)
        tabLayout.Parent = tabRail

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
        local footerText = cfg.FooterText or ("AliceHUB   |   " .. tostring(cfg.Subtitle or config.GameName or "Script"))
        local footText = newText(footer, footerText, 11, false)
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
            left.AutomaticCanvasSize = Enum.AutomaticSize.Y
            left.CanvasSize = UDim2.new()
            left.Parent = content
            padding(left, 0, 4, 0, 4)
            local ll = Instance.new("UIListLayout")
            ll.Padding = UDim.new(0, 8)
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = left

            local right = Instance.new("ScrollingFrame")
            right.Position = UDim2.new(0.5, 4, 0, 9)
            right.Size = UDim2.new(0.5, -13, 1, -18)
            right.BackgroundTransparency = 1
            right.BorderSizePixel = 0
            right.ScrollBarThickness = 3
            right.ScrollBarImageColor3 = L.Scheme.AccentColor
            right.AutomaticCanvasSize = Enum.AutomaticSize.Y
            right.CanvasSize = UDim2.new()
            right.Parent = content
            padding(right, 4, 0, 0, 4)
            local rl = Instance.new("UIListLayout")
            rl.Padding = UDim.new(0, 8)
            rl.SortOrder = Enum.SortOrder.LayoutOrder
            rl.Parent = right

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

local active = {
    Library = nil,
    Window = nil,
    ToggleGui = nil,
}

local function getGuiRoot()
    if type(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then return root end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function destroyToggleGui()
    if active.ToggleGui and active.ToggleGui.Parent then
        pcall(function() active.ToggleGui:Destroy() end)
    end
    active.ToggleGui = nil
end

local function createFloatingToggle(Library, Window, options)
    options = options or {}
    destroyToggleGui()

    local root = getGuiRoot()
    local gui = Instance.new("ScreenGui")
    gui.Name = tostring(options.ToggleGuiName or "AliceHUB_FloatingToggle")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = root

    local button = Instance.new("TextButton")
    button.Name = "AliceHUBToggleButton"
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = options.TogglePosition or UDim2.new(1, -18, 0.5, 0)
    button.Size = options.ToggleSize or UDim2.fromOffset(48, 48)
    button.BackgroundColor3 = Color3.fromRGB(24, 15, 19)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(181, 48, 83)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.08
    stroke.Parent = button

    local fallback = Instance.new("TextLabel")
    fallback.BackgroundTransparency = 1
    fallback.Size = UDim2.fromScale(1, 1)
    fallback.Text = "A"
    fallback.Font = Enum.Font.Code
    fallback.TextSize = 22
    fallback.TextColor3 = Color3.fromRGB(181, 48, 83)
    fallback.Parent = button

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Position = UDim2.fromOffset(5, 5)
    image.Size = UDim2.new(1, -10, 1, -10)
    image.Image = ALICE_HEADER_LOGO_ASSET or ""
    image.ImageTransparency = ALICE_HEADER_LOGO_ASSET and 0 or 1
    image.ScaleType = Enum.ScaleType.Crop
    image.Parent = button

    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 9)
    imageCorner.Parent = image
    __aliceRegisterLogoTarget(image, fallback)

    local dragging = false
    local dragged = false
    local dragInput
    local dragStart
    local startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragged = false
            dragStart = input.Position
            startPos = button.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos and button.Parent then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
                dragged = true
            end
            button.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    button.Activated:Connect(function()
        if dragged then
            dragged = false
            return
        end
        if Window and type(Window.SetVisible) == "function" then
            local visible = true
            if Window._main then visible = Window._main.Visible end
            Window:SetVisible(not visible)
        elseif Library and type(Library.Toggle) == "function" then
            Library:Toggle()
        end
    end)

    active.ToggleGui = gui
    return gui, button
end

function AliceHUBUI:SetLogo(asset)
    if asset == nil or asset == "" then
        ALICE_HEADER_LOGO_ASSET = nil
    else
        ALICE_HEADER_LOGO_ASSET = tostring(asset)
    end
    self.Logo = ALICE_HEADER_LOGO_ASSET

    for i = #__aliceLogoTargets, 1, -1 do
        local target = __aliceLogoTargets[i]
        if not target.image or not target.image.Parent then
            table.remove(__aliceLogoTargets, i)
        else
            __aliceApplyLogoTarget(target.image, target.fallback)
        end
    end
end

function AliceHUBUI:NewLibrary(options)
    options = options or {}
    if options.Icon ~= nil then self:SetLogo(options.Icon) end
    return buildAliceNativeLibrary({
        GuiName = options.GuiName or "AliceHUB_NativeUI",
        GameName = options.GameName or "AliceHUB",
        Icon = options.Icon or ALICE_HEADER_LOGO_ASSET,
    })
end

function AliceHUBUI:Create(gameName, options)
    options = options or {}
    gameName = tostring(gameName or options.GameName or "Game")

    self:Destroy()

    if options.Icon ~= nil then self:SetLogo(options.Icon) end

    local Library = buildAliceNativeLibrary({
        GuiName = options.GuiName or ("AliceHUB_" .. gameName:gsub("%W+", "") .. "_NativeUI"),
        GameName = gameName,
        Icon = options.Icon or ALICE_HEADER_LOGO_ASSET,
    })

    local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    local compact = viewport.X <= 1700 and viewport.Y <= 900
    local targetWidth = tonumber(options.Width) or (compact and 700 or 900)
    local targetHeight = tonumber(options.Height) or (compact and 500 or 620)
    targetWidth = math.min(targetWidth, math.max(560, viewport.X - 80))
    targetHeight = math.min(targetHeight, math.max(400, viewport.Y - 70))

    local Window = Library:CreateWindow({
        Title = tostring(options.Title or "AliceHUB"),
        Subtitle = tostring(options.Subtitle or gameName),
        FooterText = tostring(options.FooterText or ("AliceHUB   |   " .. gameName)),
        Icon = options.Icon or ALICE_HEADER_LOGO_ASSET,
        CornerRadius = tonumber(options.CornerRadius) or 4,
        Size = options.Size or UDim2.fromOffset(targetWidth, targetHeight),
    })

    active.Library = Library
    active.Window = Window

    if options.FloatingToggle ~= false then
        createFloatingToggle(Library, Window, options)
    end

    return Library, Window
end

function AliceHUBUI:GetActive()
    return active.Library, active.Window
end

function AliceHUBUI:Destroy()
    destroyToggleGui()
    if active.Library and type(active.Library.Unload) == "function" then
        pcall(function() active.Library:Unload() end)
    end
    active.Library = nil
    active.Window = nil
end

return AliceHUBUI
