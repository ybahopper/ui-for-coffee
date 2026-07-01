local repo = "https://raw.githubusercontent.com/ybahopper/ui-for-coffee/main/"
local load = function(f) return loadstring(game:HttpGet(repo .. f))() end
local fetch = function(f) return game:HttpGet(repo .. f) end

local cloneref = cloneref or function(inst) return inst end
local gethui = gethui or function() return game:GetService("CoreGui") end
local newcclosure = newcclosure or function(fn) return fn end
local makereadonly = makereadonly or function() end
local setstackhidden = setstackhidden or function() end

local uiParent = cloneref(gethui())

if uiParent:FindFirstChild("lib") then
    uiParent.lib:Destroy()
end

if _G._uiLibConnections then
    for _, conn in ipairs(_G._uiLibConnections) do
        conn:Disconnect()
    end
end
_G._uiLibConnections = {}

local RBXMXParser = load("RBXMXParser.lua")
local _temp = Instance.new("Folder")
local AnimLoggerUI = RBXMXParser.Deserialize(fetch("uilib_5.rbxmx"), _temp)[1]

local main_frame = AnimLoggerUI.main_frame
local content = main_frame.content
local bottom = main_frame.bottom

local nav_tab_template
for _, child in ipairs(bottom.nav_pill:GetChildren()) do
    if child.Name == "nav_tab" and child.LayoutOrder == 1 then
        nav_tab_template = child:Clone()
        break
    end
end

local left_col_template = content.left_column:Clone()
local right_col_template = content.right_column:Clone()

local orig_card = left_col_template.card
local section_header_template = orig_card:FindFirstChild("section_header"):Clone()
local toggle_row_template = orig_card:FindFirstChild("toggle_row_off"):Clone()
local slider_row_template = orig_card:FindFirstChild("slider_row"):Clone()
local dropdown_row_template = orig_card:FindFirstChild("dropdown_row"):Clone()
local dropdown_menu_template = orig_card:FindFirstChild("dropdown_row_open").menu:Clone()
local dropdown_opt_template = dropdown_menu_template:FindFirstChildOfClass("TextButton"):Clone()
for _, child in ipairs(dropdown_menu_template:GetChildren()) do
    if child:IsA("TextButton") then child:Destroy() end
end

local orig_right_card = right_col_template.card
local button_row_template = orig_right_card:FindFirstChild("button_row"):Clone()
local keybind_row_template = orig_right_card:FindFirstChild("keybind_row"):Clone()
local info_row_template = orig_right_card:FindFirstChild("info_row"):Clone()
local input_row_template = orig_right_card:FindFirstChild("input_row"):Clone()

local colorpicker_row_template = orig_card:FindFirstChild("colorpicker_row"):Clone()
local colorpicker_picker_template = orig_card:FindFirstChild("colorpicker_row_open"):FindFirstChild("picker"):Clone()

local accordion_row_template = orig_card:FindFirstChild("accordion_row_open"):Clone()
do
    local accTmpContent = accordion_row_template:FindFirstChild("content")
    if accTmpContent then accTmpContent:Destroy() end
end

local progress_row_template = orig_right_card:FindFirstChild("progress_row"):Clone()
local rating_row_template = orig_right_card:FindFirstChild("rating_row"):Clone()

local data_table_row_template = orig_right_card:FindFirstChild("data_table_row"):Clone()
local data_table_cell_template = data_table_row_template:FindFirstChild("row_template"):Clone()
for _, child in ipairs(data_table_row_template:GetChildren()) do
    if child:IsA("Frame") and child.Name:match("^row_") then child:Destroy() end
end

local stat_card_row_template = orig_right_card:FindFirstChild("stat_card_row"):Clone()
local stat_entry_template = stat_card_row_template:FindFirstChild("stat_template"):Clone()
for _, child in ipairs(stat_card_row_template:GetChildren()) do
    if child:IsA("Frame") and (child.Name:match("^stat_%d") or child.Name == "divider") then child:Destroy() end
end

local timeline_row_template = orig_right_card:FindFirstChild("timeline_row"):Clone()
local timeline_event_template
for _, child in ipairs(timeline_row_template:GetChildren()) do
    if child.Name == "event_1" then timeline_event_template = child:Clone() end
    if child:IsA("Frame") and child.Name:match("^event_") then child:Destroy() end
end

local notif_template = AnimLoggerUI:FindFirstChild("notifications"):FindFirstChild("notif_success"):Clone()

local login_panel_ref = AnimLoggerUI:FindFirstChild("login_panel")
local minimized_bar_ref = AnimLoggerUI:FindFirstChild("minimized_bar")
local notifications_container = AnimLoggerUI:FindFirstChild("notifications")
local modal_frame = main_frame:FindFirstChild("modal")
local modal_backdrop = main_frame:FindFirstChild("modal_backdrop")
local tooltip_frame = main_frame:FindFirstChild("tooltip")

local card_template = orig_card:Clone()
for _, child in ipairs(card_template:GetChildren()) do
    if child:IsA("GuiObject") then child:Destroy() end
end

local _activeDropdownClose = nil

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Players = cloneref(game:GetService("Players"))
local Heartbeat = cloneref(game:GetService("RunService")).Heartbeat
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOGGLE_ON = {
    bg = Color3.fromRGB(194, 137, 92),
    bgTransparency = 0,
    knobPos = UDim2.new(0, 29, 0.5, 0),
    knobTransparency = 0,
    strokeEnabled = false,
}
local TOGGLE_OFF = {
    bg = Color3.fromRGB(255, 255, 255),
    bgTransparency = 0.92,
    knobPos = UDim2.new(0, 9, 0.5, 0),
    knobTransparency = 0.45,
    strokeEnabled = true,
}
local NOTIF_COLORS = {
    success = Color3.fromRGB(160, 180, 120),
    error = Color3.fromRGB(200, 110, 90),
    info = Color3.fromRGB(194, 137, 92),
}
local STAR_ON = Color3.fromRGB(194, 137, 92)
local STAR_OFF = Color3.fromRGB(60, 45, 32)
local ACCENT = Color3.fromRGB(194, 137, 92)
local DIM_TEXT = Color3.fromRGB(155, 143, 128)
local TEXT_COLOR = Color3.fromRGB(221, 211, 198)

for _, child in ipairs(bottom.nav_pill:GetChildren()) do
    if child.Name == "nav_tab" then child:Destroy() end
end
content.left_column:Destroy()
content.right_column:Destroy()

local lib = {}

function lib.new(config)
    config = config or {}
    local title_bar = main_frame.title_bar

    AnimLoggerUI.Parent = uiParent
    main_frame.Visible = false
    if minimized_bar_ref then minimized_bar_ref.Visible = false end
    if login_panel_ref then login_panel_ref.Visible = false end
    if modal_frame then modal_frame.Visible = false end
    if modal_backdrop then modal_backdrop.Visible = false end
    for _, notif in ipairs(notifications_container:GetChildren()) do
        if notif:IsA("Frame") then notif.Visible = false end
    end
    title_bar.brand_name.Text = config.name or "UI Library"

    if config.logo then
        title_bar.logo.Image = "rbxassetid://" .. tostring(config.logo)
        title_bar.logo.Visible = true
    else
        title_bar.logo.Visible = false
    end

    local dragging = false
    local dragOffset = Vector2.new()

    title_bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local framePos = main_frame.AbsolutePosition + main_frame.AbsoluteSize * main_frame.AnchorPoint
            dragOffset = framePos - Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    title_bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local dragConn = UserInputService.InputChanged:Connect(newcclosure(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local target = UDim2.new(
                0, input.Position.X + dragOffset.X,
                0, input.Position.Y + dragOffset.Y
            )
            TweenService:Create(main_frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = target,
            }):Play()
        end
    end))
    table.insert(_G._uiLibConnections, dragConn)

    local tabs = {}
    local activeTab = nil

    local activeColor = Color3.fromRGB(210, 165, 130)
    local inactiveColor = Color3.fromRGB(152, 140, 125)
    local activeIconColor = Color3.fromRGB(194, 137, 92)
    local inactiveIconColor = Color3.fromRGB(152, 140, 125)

    local tabSwitching = false

    local function setActiveTab(target, skipAnim)
        if activeTab == target or tabSwitching then return end

        local prevTab = activeTab
        activeTab = target

        for _, t in ipairs(tabs) do
            local isActive = (t == target)
            local stroke = t._btn:FindFirstChildOfClass("UIStroke")
            if isActive then
                TweenService:Create(t._btn, TWEEN_INFO, { BackgroundTransparency = 0.72 }):Play()
                TweenService:Create(t._btn.label, TWEEN_INFO, { TextColor3 = activeColor }):Play()
                TweenService:Create(t._btn.icon, TWEEN_INFO, { ImageColor3 = activeIconColor }):Play()
                if stroke then stroke.Enabled = true end
            else
                TweenService:Create(t._btn, TWEEN_INFO, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(t._btn.label, TWEEN_INFO, { TextColor3 = inactiveColor }):Play()
                TweenService:Create(t._btn.icon, TWEEN_INFO, { ImageColor3 = inactiveIconColor }):Play()
                if stroke then stroke.Enabled = false end
            end
        end

        if skipAnim or not prevTab then
            for _, t in ipairs(tabs) do
                local isActive = (t == target)
                t._left.Visible = isActive
                t._right.Visible = isActive
            end
            return
        end

        tabSwitching = true
        task.spawn(function()
            local CLOSE_TIME = 0.3
            local OPEN_TIME = 0.35
            local CARD_STAGGER = 0.06
            local FADE_OUT_TIME = 0.15
            local FADE_IN_TIME = 0.25

            local outCardMeta = {}
            for ci, card in ipairs(prevTab._cards) do
                local meta = {
                    bg = card.BackgroundTransparency,
                    stroke = card:FindFirstChildOfClass("UIStroke"),
                    texts = {},
                    images = {},
                }
                if meta.stroke then meta.strokeT = meta.stroke.Transparency end
                for _, desc in ipairs(card:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                        table.insert(meta.texts, { obj = desc, origT = desc.TextTransparency })
                    elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                        table.insert(meta.images, { obj = desc, origT = desc.ImageTransparency })
                    end
                end
                outCardMeta[ci] = meta
            end

            local fadeOutTi = TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            for ci, card in ipairs(prevTab._cards) do
                local m = outCardMeta[ci]
                TweenService:Create(card, fadeOutTi, { BackgroundTransparency = 1 }):Play()
                if m.stroke then
                    TweenService:Create(m.stroke, fadeOutTi, { Transparency = 1 }):Play()
                end
                for _, t in ipairs(m.texts) do
                    TweenService:Create(t.obj, fadeOutTi, { TextTransparency = 1 }):Play()
                end
                for _, img in ipairs(m.images) do
                    TweenService:Create(img.obj, fadeOutTi, { ImageTransparency = 1 }):Play()
                end
            end

            local prevLeftX = prevTab._left.Size.X
            local prevRightX = prevTab._right.Size.X
            local prevLeftH = prevTab._left.AbsoluteSize.Y
            local prevRightH = prevTab._right.AbsoluteSize.Y

            prevTab._left.ClipsDescendants = true
            prevTab._right.ClipsDescendants = true
            prevTab._left.AutomaticSize = Enum.AutomaticSize.None
            prevTab._right.AutomaticSize = Enum.AutomaticSize.None
            prevTab._left.Size = UDim2.new(prevLeftX.Scale, prevLeftX.Offset, 0, prevLeftH)
            prevTab._right.Size = UDim2.new(prevRightX.Scale, prevRightX.Offset, 0, prevRightH)

            local closeTi = TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            TweenService:Create(prevTab._left, closeTi, {
                Size = UDim2.new(prevLeftX.Scale, prevLeftX.Offset, 0, 0),
            }):Play()
            TweenService:Create(prevTab._right, closeTi, {
                Size = UDim2.new(prevRightX.Scale, prevRightX.Offset, 0, 0),
            }):Play()

            local elapsed = 0
            while elapsed < CLOSE_TIME do
                elapsed = elapsed + Heartbeat:Wait()
            end
            Heartbeat:Wait()

            prevTab._left.Visible = false
            prevTab._right.Visible = false
            prevTab._left.AutomaticSize = Enum.AutomaticSize.Y
            prevTab._right.AutomaticSize = Enum.AutomaticSize.Y
            prevTab._left.ClipsDescendants = false
            prevTab._right.ClipsDescendants = false
            for ci, card in ipairs(prevTab._cards) do
                local m = outCardMeta[ci]
                card.BackgroundTransparency = m.bg
                if m.stroke then m.stroke.Transparency = m.strokeT end
                for _, t in ipairs(m.texts) do t.obj.TextTransparency = t.origT end
                for _, img in ipairs(m.images) do img.obj.ImageTransparency = img.origT end
            end

            local inCardMeta = {}
            for ci, card in ipairs(target._cards) do
                local meta = {
                    bg = card.BackgroundTransparency,
                    stroke = card:FindFirstChildOfClass("UIStroke"),
                    texts = {},
                    images = {},
                }
                if meta.stroke then
                    meta.strokeT = meta.stroke.Transparency
                    meta.stroke.Transparency = 1
                end
                card.BackgroundTransparency = 1
                for _, desc in ipairs(card:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                        table.insert(meta.texts, { obj = desc, origT = desc.TextTransparency })
                        desc.TextTransparency = 1
                    elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                        table.insert(meta.images, { obj = desc, origT = desc.ImageTransparency })
                        desc.ImageTransparency = 1
                    end
                end
                inCardMeta[ci] = meta
            end

            local tgtLeftX = target._left.Size.X
            local tgtRightX = target._right.Size.X

            target._left.ClipsDescendants = true
            target._right.ClipsDescendants = true
            target._left.AutomaticSize = Enum.AutomaticSize.None
            target._right.AutomaticSize = Enum.AutomaticSize.None
            target._left.Size = UDim2.new(tgtLeftX.Scale, tgtLeftX.Offset, 0, 0)
            target._right.Size = UDim2.new(tgtRightX.Scale, tgtRightX.Offset, 0, 0)

            target._left.Visible = true
            target._right.Visible = true

            for _ = 1, 5 do Heartbeat:Wait() end

            local leftLayout = target._left:FindFirstChildOfClass("UIListLayout")
            local rightLayout = target._right:FindFirstChildOfClass("UIListLayout")
            local newLeftH = leftLayout and leftLayout.AbsoluteContentSize.Y or 0
            local newRightH = rightLayout and rightLayout.AbsoluteContentSize.Y or 0

            local openTi = TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            TweenService:Create(target._left, openTi, {
                Size = UDim2.new(tgtLeftX.Scale, tgtLeftX.Offset, 0, newLeftH),
            }):Play()
            TweenService:Create(target._right, openTi, {
                Size = UDim2.new(tgtRightX.Scale, tgtRightX.Offset, 0, newRightH),
            }):Play()

            for ci, card in ipairs(target._cards) do
                local m = inCardMeta[ci]
                local d = (ci - 1) * CARD_STAGGER
                local fadeInTi = TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, d)
                TweenService:Create(card, fadeInTi, { BackgroundTransparency = m.bg }):Play()
                if m.stroke then
                    TweenService:Create(m.stroke, fadeInTi, { Transparency = m.strokeT }):Play()
                end
                for _, t in ipairs(m.texts) do
                    TweenService:Create(t.obj, fadeInTi, { TextTransparency = t.origT }):Play()
                end
                for _, img in ipairs(m.images) do
                    TweenService:Create(img.obj, fadeInTi, { ImageTransparency = img.origT }):Play()
                end
            end

            elapsed = 0
            local totalOpen = OPEN_TIME + math.max(0, #target._cards - 1) * CARD_STAGGER
            while elapsed < totalOpen do
                elapsed = elapsed + Heartbeat:Wait()
            end
            Heartbeat:Wait()

            target._left.AutomaticSize = Enum.AutomaticSize.Y
            target._right.AutomaticSize = Enum.AutomaticSize.Y
            target._left.ClipsDescendants = false
            target._right.ClipsDescendants = false

            tabSwitching = false
        end)
    end

    local window = {}

    function window:addTab(tabConfig)
        tabConfig = tabConfig or {}

        local btn = nav_tab_template:Clone()
        btn.LayoutOrder = #tabs + 1
        btn.label.Text = tabConfig.name or "Tab"
        if tabConfig.icon then
            btn.icon.Image = "rbxassetid://" .. tostring(tabConfig.icon)
            btn.icon.Visible = true
        else
            btn.icon.Visible = false
        end
        btn.Parent = bottom.nav_pill

        local left = left_col_template:Clone()
        local right = right_col_template:Clone()

        left.card:Destroy()
        right.card:Destroy()
        left.Visible = false
        right.Visible = false
        left.Parent = content
        right.Parent = content

        local leftCardCount = 0
        local rightCardCount = 0

        local tab = {
            _btn = btn,
            _left = left,
            _right = right,
            _cards = {},
        }

        function tab:addCard(cardConfig)
            cardConfig = cardConfig or {}
            local side = cardConfig.side or "left"
            local column = (side == "right") and right or left

            local card = card_template:Clone()

            if cardConfig.name then
                local header = section_header_template:Clone()
                header.title.Text = cardConfig.name
                header.Visible = true
                header.Parent = card
            end

            if side == "right" then
                rightCardCount = rightCardCount + 1
                card.LayoutOrder = rightCardCount
            else
                leftCardCount = leftCardCount + 1
                card.LayoutOrder = leftCardCount
            end

            card.Visible = true
            card.Parent = column


            table.insert(tab._cards, card)

            local elementCount = 0
            local cardObj = {}

            local function ensureSep(row)
                if not row:FindFirstChild("sep") then
                    local sep = Instance.new("Frame")
                    sep.Name = "sep"
                    sep.Size = UDim2.new(1, 0, 0, 1)
                    sep.Position = UDim2.new(0, 0, 1, -1)
                    sep.BackgroundColor3 = Color3.new(1, 1, 1)
                    sep.BackgroundTransparency = 0.95
                    sep.BorderSizePixel = 0
                    sep.Parent = row
                end
            end

            local function updateSeparators()
                local rows = {}
                for _, child in ipairs(card:GetChildren()) do
                    if child:IsA("GuiObject") and child:FindFirstChild("sep") then
                        table.insert(rows, child)
                    end
                end
                table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
                for i, row in ipairs(rows) do
                    row.sep.Visible = (i < #rows)
                end
            end

            function cardObj:addToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                local state = toggleConfig.default or false

                local row = toggle_row_template:Clone()
                row.label.Text = toggleConfig.name or "Toggle"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local toggle = row.toggle
                local knob = toggle.knob
                local stroke = toggle:FindFirstChildOfClass("UIStroke")

                local knobOrigSize = UDim2.new(0, 12, 0, 12)
                local knobStretchSize = UDim2.new(0, 18, 0, 9)

                local function applyStyle(on, animate)
                    local s = on and TOGGLE_ON or TOGGLE_OFF

                    TweenService:Create(toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = s.bg,
                        BackgroundTransparency = s.bgTransparency,
                    }):Play()

                    if stroke then stroke.Enabled = s.strokeEnabled end

                    if animate then
                        local stretchTween = TweenService:Create(knob, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = knobStretchSize,
                            BackgroundTransparency = s.knobTransparency,
                        })
                        stretchTween:Play()
                        TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.05), {
                            Position = s.knobPos,
                        }):Play()
                        stretchTween.Completed:Connect(function()
                            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                Size = knobOrigSize,
                            }):Play()
                        end)
                    else
                        knob.Position = s.knobPos
                        knob.Size = knobOrigSize
                        knob.BackgroundTransparency = s.knobTransparency
                    end
                end

                applyStyle(state, false)
                row.Parent = card
                updateSeparators()

                local inputBtn = Instance.new("TextButton")
                inputBtn.Text = ""
                inputBtn.BackgroundTransparency = 1
                inputBtn.Size = UDim2.new(1, 0, 1, 0)
                inputBtn.ZIndex = 10
                inputBtn.Parent = row

                inputBtn.MouseButton1Click:Connect(function()
                    state = not state
                    applyStyle(state, true)
                    if toggleConfig.callback then
                        toggleConfig.callback(state)
                    end
                end)

                return {
                    set = function(_, val)
                        state = val
                        applyStyle(state, true)
                    end,
                    get = function()
                        return state
                    end,
                }
            end

            function cardObj:addSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                local min = sliderConfig.min or 0
                local max = sliderConfig.max or 100
                local step = sliderConfig.step or 1
                local value = sliderConfig.default or min
                local suffix = sliderConfig.suffix or ""

                local row = slider_row_template:Clone()
                row.label.Text = sliderConfig.name or "Slider"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local track = row.track
                local fill = track.fill
                local valueLabel = row.value

                local sliderDragging = false

                local function snapToStep(val)
                    return math.clamp(math.round((val - min) / step) * step + min, min, max)
                end

                local function formatValue(val)
                    if step % 1 == 0 then
                        return tostring(math.floor(val)) .. suffix
                    else
                        local decimals = #tostring(step):match("%.(%d+)") or 1
                        return string.format("%." .. decimals .. "f", val) .. suffix
                    end
                end

                local function updateVisual(val, instant)
                    local pct = math.clamp((val - min) / (max - min), 0, 1)
                    if instant then
                        fill.Size = UDim2.new(pct, 0, 1, 0)
                    else
                        TweenService:Create(fill, TWEEN_INFO, {
                            Size = UDim2.new(pct, 0, 1, 0)
                        }):Play()
                    end
                    valueLabel.Text = formatValue(val)
                end

                value = snapToStep(value)
                updateVisual(value)
                row.Parent = card
                updateSeparators()

                local inputBtn = Instance.new("TextButton")
                inputBtn.Text = ""
                inputBtn.BackgroundTransparency = 1
                inputBtn.Size = UDim2.new(1, 0, 1, 0)
                inputBtn.Position = UDim2.new(0, 0, 0, 0)
                inputBtn.ZIndex = 10
                inputBtn.Parent = track

                local function updateFromInput(inputX)
                    local trackPos = track.AbsolutePosition.X
                    local trackWidth = track.AbsoluteSize.X
                    local pct = math.clamp((inputX - trackPos) / trackWidth, 0, 1)
                    value = snapToStep(min + pct * (max - min))
                    updateVisual(value)
                    if sliderConfig.callback then
                        sliderConfig.callback(value)
                    end
                end

                inputBtn.MouseButton1Down:Connect(function()
                    sliderDragging = true
                end)

                local sliderMoveConn = UserInputService.InputChanged:Connect(newcclosure(function(input)
                    if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromInput(input.Position.X)
                    end
                end))

                local sliderEndConn = UserInputService.InputEnded:Connect(newcclosure(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if sliderDragging then
                            sliderDragging = false
                        end
                    end
                end))
                table.insert(_G._uiLibConnections, sliderMoveConn)
                table.insert(_G._uiLibConnections, sliderEndConn)

                inputBtn.MouseButton1Click:Connect(function()
                    local mouse = Players.LocalPlayer:GetMouse()
                    updateFromInput(mouse.X)
                end)

                local valueInput = Instance.new("TextBox")
                valueInput.AnchorPoint = valueLabel.AnchorPoint
                valueInput.Position = valueLabel.Position
                valueInput.Size = valueLabel.Size
                valueInput.FontFace = valueLabel.FontFace
                valueInput.TextSize = valueLabel.TextSize
                valueInput.TextColor3 = valueLabel.TextColor3
                valueInput.BackgroundColor3 = valueLabel.BackgroundColor3
                valueInput.BackgroundTransparency = valueLabel.BackgroundTransparency
                valueInput.TextXAlignment = Enum.TextXAlignment.Center
                valueInput.ClearTextOnFocus = true
                valueInput.Visible = false
                valueInput.ZIndex = valueLabel.ZIndex
                valueInput.Parent = row

                for _, child in ipairs(valueLabel:GetChildren()) do
                    child:Clone().Parent = valueInput
                end

                local function startEditing()
                    valueLabel.Visible = false
                    valueInput.Visible = true
                    valueInput.Text = ""
                    valueInput.PlaceholderText = formatValue(value)
                    valueInput:CaptureFocus()
                end

                local function stopEditing(enterPressed)
                    valueInput.Visible = false
                    valueLabel.Visible = true
                    if enterPressed and valueInput.Text ~= "" then
                        local num = tonumber(valueInput.Text)
                        if num then
                            value = snapToStep(num)
                            updateVisual(value)
                            if sliderConfig.callback then
                                sliderConfig.callback(value)
                            end
                        end
                    end
                end

                local valueLabelBtn = Instance.new("TextButton")
                valueLabelBtn.Text = ""
                valueLabelBtn.BackgroundTransparency = 1
                valueLabelBtn.Size = UDim2.new(1, 0, 1, 0)
                valueLabelBtn.ZIndex = valueLabel.ZIndex + 1
                valueLabelBtn.Parent = valueLabel

                valueLabelBtn.MouseButton1Click:Connect(startEditing)
                valueInput.FocusLost:Connect(stopEditing)

                return {
                    set = function(_, val)
                        value = snapToStep(val)
                        updateVisual(value)
                    end,
                    get = function()
                        return value
                    end,
                }
            end

            function cardObj:addDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}
                local options = dropdownConfig.options or {}
                local selected = dropdownConfig.default or options[1] or ""

                local row = dropdown_row_template:Clone()
                row.label.Text = dropdownConfig.name or "Dropdown"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local btn = row.button
                local chevron = btn.chevron
                local valueLabel = btn.value
                valueLabel.Text = selected

                local menu = dropdown_menu_template:Clone()
                local menuWidth = menu.Size.X
                menu.Visible = false
                menu.AutomaticSize = Enum.AutomaticSize.None
                menu.Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, 0)
                menu.ClipsDescendants = true
                menu.Parent = row

                local function setCardInteractable(enabled)
                    for _, sibling in ipairs(card:GetChildren()) do
                        if sibling:IsA("GuiObject") and sibling ~= row then
                            sibling.Interactable = enabled
                        end
                    end
                end

                local optButtons = {}

                local function updateSelection()
                    for _, ob in ipairs(optButtons) do
                        local target = (ob.opt == selected) and 0.7 or 1
                        TweenService:Create(ob.btn, TWEEN_INFO, {
                            BackgroundTransparency = target
                        }):Play()
                    end
                end

                local isOpen = false
                local OPEN_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                local OPT_STAGGER = 0.03
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                local accentColor = Color3.fromRGB(194, 137, 92)
                local defaultStrokeColor = Color3.fromRGB(255, 255, 255)
                local defaultChevronColor = chevron.TextColor3
                local closeMenu -- forward declare

                for i, opt in ipairs(options) do
                    local optBtn = dropdown_opt_template:Clone()
                    optBtn.LayoutOrder = i
                    optBtn.TextLabel.Text = opt
                    optBtn.Visible = true
                    optBtn.BackgroundTransparency = 1
                    optBtn.TextLabel.TextTransparency = 1
                    optBtn.Parent = menu

                    optButtons[#optButtons + 1] = { btn = optBtn, opt = opt, index = i }

                    optBtn.MouseEnter:Connect(function()
                        if opt ~= selected then
                            TweenService:Create(optBtn, TWEEN_INFO, {
                                BackgroundTransparency = 0.88
                            }):Play()
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        local target = (opt == selected) and 0.7 or 1
                        TweenService:Create(optBtn, TWEEN_INFO, {
                            BackgroundTransparency = target
                        }):Play()
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        valueLabel.Text = opt
                        updateSelection()
                        closeMenu()
                        if dropdownConfig.callback then
                            dropdownConfig.callback(opt)
                        end
                    end)
                end

                updateSelection()

                local menuLayout = menu:FindFirstChildOfClass("UIListLayout")
                local menuPadding = menu:FindFirstChildOfClass("UIPadding")
                local fullHeight = menuLayout.AbsoluteContentSize.Y
                    + (menuPadding and (menuPadding.PaddingTop.Offset + menuPadding.PaddingBottom.Offset) or 0)

                local function animateOptions(opening)
                    for _, ob in ipairs(optButtons) do
                        local delay = (ob.index - 1) * OPT_STAGGER
                        if opening then
                            ob.btn.TextLabel.TextTransparency = 1
                            local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delay)
                            TweenService:Create(ob.btn.TextLabel, tweenInfo, {
                                TextTransparency = 0
                            }):Play()
                        else
                            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In, 0, false, 0)
                            TweenService:Create(ob.btn.TextLabel, tweenInfo, {
                                TextTransparency = 1
                            }):Play()
                        end
                    end
                end

                closeMenu = function()
                    isOpen = false
                    setCardInteractable(true)
                    _activeDropdownClose = nil
                    animateOptions(false)
                    local menuStroke = menu:FindFirstChildOfClass("UIStroke")
                    TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    }):Play()
                    if menuStroke then
                        TweenService:Create(menuStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Transparency = 1
                        }):Play()
                    end
                    local tween = TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, 0)
                    })
                    tween:Play()
                    tween.Completed:Connect(function()
                        if not isOpen then menu.Visible = false end
                    end)
                    TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = 90, TextColor3 = defaultChevronColor,
                    }):Play()
                    if btnStroke then
                        TweenService:Create(btnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Color = defaultStrokeColor, Transparency = 0.88,
                        }):Play()
                    end
                end

                btn.MouseButton1Click:Connect(function()
                    if _activeDropdownClose and _activeDropdownClose ~= closeMenu then
                        _activeDropdownClose()
                    end
                    isOpen = not isOpen
                    if isOpen then
                        setCardInteractable(false)
                        _activeDropdownClose = closeMenu
                        menu.Visible = true
                        menu.BackgroundTransparency = 0
                        local menuStroke = menu:FindFirstChildOfClass("UIStroke")
                        if menuStroke then menuStroke.Transparency = 0.88 end
                        TweenService:Create(menu, OPEN_TWEEN, {
                            Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, fullHeight)
                        }):Play()
                        TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0, TextColor3 = accentColor,
                        }):Play()
                        if btnStroke then
                            TweenService:Create(btnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Color = accentColor, Transparency = 0.3,
                            }):Play()
                        end
                        animateOptions(true)
                    else
                        closeMenu()
                    end
                end)

                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, val)
                        selected = val
                        valueLabel.Text = val
                        updateSelection()
                    end,
                    get = function()
                        return selected
                    end,
                }
            end

            function cardObj:addButton(btnConfig)
                btnConfig = btnConfig or {}
                local row = button_row_template:Clone()
                local btn = row.button
                btn.Text = btnConfig.name or "Button"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                row.Parent = card
                updateSeparators()

                btn.MouseButton1Down:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.65
                    }):Play()
                end)
                btn.MouseButton1Up:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.84
                    }):Play()
                end)
                btn.MouseButton1Click:Connect(function()
                    if btnConfig.callback then btnConfig.callback() end
                end)

                return {}
            end

            function cardObj:addKeybind(kbConfig)
                kbConfig = kbConfig or {}
                local key = kbConfig.default or Enum.KeyCode.F
                local listening = false

                local row = keybind_row_template:Clone()
                row.label.Text = kbConfig.name or "Keybind"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local btn = row.button
                btn.Text = key.Name
                row.Parent = card
                updateSeparators()

                local defaultColor = Color3.fromRGB(221, 211, 198)
                local accentColor = Color3.fromRGB(194, 137, 92)
                local strokeWhite = Color3.fromRGB(255, 255, 255)
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                local btnPadding = btn:FindFirstChildOfClass("UIPadding")

                local function measureBtn(text)
                    local params = Instance.new("GetTextBoundsParams")
                    params.Text = text
                    params.Font = btn.FontFace
                    params.Size = btn.TextSize
                    params.Width = 1000
                    local bounds = TextService:GetTextBoundsAsync(params)
                    local padL = btnPadding and btnPadding.PaddingLeft.Offset or 0
                    local padR = btnPadding and btnPadding.PaddingRight.Offset or 0
                    return UDim2.new(0, bounds.X + padL + padR, btn.Size.Y.Scale, btn.Size.Y.Offset)
                end

                btn.Size = measureBtn(key.Name)

                btn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true

                    local targetSize = measureBtn("Press a key...")

                    btn.Text = "Press a key..."
                    btn.TextTransparency = 1
                    btn.TextColor3 = accentColor

                    TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        Size = targetSize,
                    }):Play()
                    if btnStroke then
                        TweenService:Create(btnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Color = accentColor, Transparency = 0,
                        }):Play()
                    end
                end)

                local kbConn = UserInputService.InputBegan:Connect(newcclosure(function(input, gpe)
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

                    if listening then
                        key = input.KeyCode
                        listening = false

                        local targetSize2 = measureBtn(key.Name)

                        btn.Text = key.Name
                        btn.TextTransparency = 1
                        btn.TextColor3 = defaultColor

                        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            TextTransparency = 0,
                            Size = targetSize2,
                        }):Play()
                        if btnStroke then
                            TweenService:Create(btnStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Color = strokeWhite, Transparency = 0.88,
                            }):Play()
                        end
                        if kbConfig.callback then kbConfig.callback(key) end
                        return
                    end

                    if not gpe and input.KeyCode == key then
                        if kbConfig.onPress then kbConfig.onPress() end
                    end
                end))
                table.insert(_G._uiLibConnections, kbConn)

                return {
                    set = function(_, val)
                        key = val
                        btn.Text = key.Name
                    end,
                    get = function()
                        return key
                    end,
                }
            end

            function cardObj:addInfo(infoConfig)
                infoConfig = infoConfig or {}
                local row = info_row_template:Clone()
                row.label.Text = infoConfig.name or "Info"
                row.value.Text = infoConfig.value or ""
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, val)
                        row.value.Text = tostring(val)
                    end,
                    get = function()
                        return row.value.Text
                    end,
                }
            end

            function cardObj:addInput(inputConfig)
                inputConfig = inputConfig or {}
                local row = input_row_template:Clone()
                row.label.Text = inputConfig.name or "Input"
                local textbox = row.input
                textbox.PlaceholderText = inputConfig.placeholder or "Enter value..."
                textbox.Text = inputConfig.default or ""
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                row.Parent = card
                updateSeparators()

                local inputStroke = textbox:FindFirstChildOfClass("UIStroke")
                local defaultStrokeColor = Color3.fromRGB(255, 255, 255)
                local focusStrokeColor = Color3.fromRGB(194, 137, 92)
                local focusTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                textbox.Focused:Connect(function()
                    if inputStroke then
                        TweenService:Create(inputStroke, focusTween, {
                            Color = focusStrokeColor, Transparency = 0, Thickness = 1.5,
                        }):Play()
                    end
                end)

                textbox.FocusLost:Connect(function(enterPressed)
                    if inputStroke then
                        TweenService:Create(inputStroke, focusTween, {
                            Color = defaultStrokeColor, Transparency = 0.9, Thickness = 1,
                        }):Play()
                    end
                    if enterPressed and inputConfig.callback then
                        inputConfig.callback(textbox.Text)
                    end
                end)

                return {
                    set = function(_, val)
                        textbox.Text = tostring(val)
                    end,
                    get = function()
                        return textbox.Text
                    end,
                }
            end

            function cardObj:addColorPicker(cpConfig)
                cpConfig = cpConfig or {}
                local color = cpConfig.default or Color3.fromRGB(255, 85, 85)

                local row = colorpicker_row_template:Clone()
                row.label.Text = cpConfig.name or "Color Picker"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local swatch = row.swatch
                swatch.BackgroundColor3 = color

                local picker = colorpicker_picker_template:Clone()
                picker.Visible = false
                picker.Parent = row

                local svField = picker.sv_field
                local hueBar = picker.hue_bar
                local hexInput = picker.hex_row.input
                local svCursor = svField.cursor
                local hueCursor = hueBar.cursor

                local h, s, v = Color3.toHSV(color)

                local function hsvToColor(hh, ss, vv)
                    return Color3.fromHSV(hh, ss, vv)
                end

                local function updateVisual()
                    color = hsvToColor(h, s, v)
                    swatch.BackgroundColor3 = color
                    svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueCursor.Position = UDim2.new(0.5, 0, h, 0)
                    hexInput.Text = "#" .. color:ToHex()
                    if cpConfig.callback then cpConfig.callback(color) end
                end

                local svDragging, hueDragging = false, false

                local function handleSV(input)
                    local ax, ay = svField.AbsolutePosition.X, svField.AbsolutePosition.Y
                    local aw, ah = svField.AbsoluteSize.X, svField.AbsoluteSize.Y
                    s = math.clamp((input.Position.X - ax) / aw, 0, 1)
                    v = math.clamp(1 - (input.Position.Y - ay) / ah, 0, 1)
                    updateVisual()
                end

                local function handleHue(input)
                    local ay = hueBar.AbsolutePosition.Y
                    local ah = hueBar.AbsoluteSize.Y
                    h = math.clamp((input.Position.Y - ay) / ah, 0, 1)
                    updateVisual()
                end

                local svBtn = Instance.new("TextButton")
                svBtn.Text = ""
                svBtn.BackgroundTransparency = 1
                svBtn.Size = UDim2.new(1, 0, 1, 0)
                svBtn.ZIndex = 10
                svBtn.Parent = svField

                svBtn.MouseButton1Down:Connect(function() svDragging = true end)

                local hueBtn = Instance.new("TextButton")
                hueBtn.Text = ""
                hueBtn.BackgroundTransparency = 1
                hueBtn.Size = UDim2.new(1, 0, 1, 0)
                hueBtn.ZIndex = 10
                hueBtn.Parent = hueBar

                hueBtn.MouseButton1Down:Connect(function() hueDragging = true end)

                local cpMoveConn = UserInputService.InputChanged:Connect(newcclosure(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                    if svDragging then handleSV(input) end
                    if hueDragging then handleHue(input) end
                end))
                local cpEndConn = UserInputService.InputEnded:Connect(newcclosure(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = false
                        hueDragging = false
                    end
                end))
                table.insert(_G._uiLibConnections, cpMoveConn)
                table.insert(_G._uiLibConnections, cpEndConn)

                svBtn.MouseButton1Click:Connect(function()
                    local mouse = Players.LocalPlayer:GetMouse()
                    local fakeInput = { Position = Vector3.new(mouse.X, mouse.Y, 0) }
                    handleSV(fakeInput)
                end)
                hueBtn.MouseButton1Click:Connect(function()
                    local mouse = Players.LocalPlayer:GetMouse()
                    local fakeInput = { Position = Vector3.new(mouse.X, mouse.Y, 0) }
                    handleHue(fakeInput)
                end)

                hexInput.FocusLost:Connect(function(enter)
                    if enter then
                        local hex = hexInput.Text:gsub("#", "")
                        local ok, c = pcall(function() return Color3.fromHex("#" .. hex) end)
                        if ok then
                            h, s, v = Color3.toHSV(c)
                            updateVisual()
                        end
                    end
                end)

                local pickerOpen = false
                local swatchStroke = swatch:FindFirstChildOfClass("UIStroke")

                swatch.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    if pickerOpen then
                        picker.Visible = true
                        updateVisual()
                        if swatchStroke then
                            TweenService:Create(swatchStroke, TWEEN_INFO, { Color = ACCENT, Transparency = 0 }):Play()
                        end
                    else
                        picker.Visible = false
                        if swatchStroke then
                            TweenService:Create(swatchStroke, TWEEN_INFO, { Color = Color3.fromRGB(255,255,255), Transparency = 0.88 }):Play()
                        end
                    end
                end)

                row.Parent = card
                updateSeparators()
                updateVisual()

                return {
                    set = function(_, val)
                        h, s, v = Color3.toHSV(val)
                        updateVisual()
                    end,
                    get = function()
                        return color
                    end,
                }
            end

            function cardObj:addMultiSelect(msConfig)
                msConfig = msConfig or {}
                local options = msConfig.options or {}
                local selected = {}
                if msConfig.default then
                    for _, v in ipairs(msConfig.default) do selected[v] = true end
                end

                local row = dropdown_row_template:Clone()
                row.label.Text = msConfig.name or "Multi Select"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local btn = row.button
                local chevron = btn.chevron
                local valueLabel = btn.value

                local function countSelected()
                    local n = 0
                    for _ in pairs(selected) do n = n + 1 end
                    return n
                end

                local function updateValueText()
                    local n = countSelected()
                    valueLabel.Text = n > 0 and (n .. " selected") or "None"
                end
                updateValueText()

                local menu = dropdown_menu_template:Clone()
                local menuWidth = menu.Size.X
                menu.Visible = false
                menu.AutomaticSize = Enum.AutomaticSize.None
                menu.Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, 0)
                menu.ClipsDescendants = true
                menu.Parent = row

                local function setCardInteractable(enabled)
                    for _, sibling in ipairs(card:GetChildren()) do
                        if sibling:IsA("GuiObject") and sibling ~= row then
                            sibling.Interactable = enabled
                        end
                    end
                end

                local optButtons = {}

                local function updateOptStyles()
                    for _, ob in ipairs(optButtons) do
                        local isSel = selected[ob.opt]
                        ob.btn.TextLabel.Text = ob.opt
                        TweenService:Create(ob.btn, TWEEN_INFO, {
                            BackgroundTransparency = isSel and 0.7 or 1
                        }):Play()
                    end
                end

                for i, opt in ipairs(options) do
                    local optBtn = dropdown_opt_template:Clone()
                    optBtn.LayoutOrder = i
                    optBtn.TextLabel.Text = opt
                    optBtn.Visible = true
                    optBtn.BackgroundTransparency = selected[opt] and 0.7 or 1
                    optBtn.TextLabel.TextTransparency = 1
                    optBtn.Parent = menu

                    optButtons[#optButtons + 1] = { btn = optBtn, opt = opt, index = i }

                    optBtn.MouseEnter:Connect(function()
                        TweenService:Create(optBtn, TWEEN_INFO, { BackgroundTransparency = 0.8 }):Play()
                    end)
                    optBtn.MouseLeave:Connect(function()
                        local target = selected[opt] and 0.7 or 1
                        TweenService:Create(optBtn, TWEEN_INFO, { BackgroundTransparency = target }):Play()
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected[opt] = not selected[opt] or nil
                        updateOptStyles()
                        updateValueText()
                        if msConfig.callback then
                            local list = {}
                            for _, o in ipairs(options) do
                                if selected[o] then table.insert(list, o) end
                            end
                            msConfig.callback(list)
                        end
                    end)
                end

                local menuLayout = menu:FindFirstChildOfClass("UIListLayout")
                local menuPadding = menu:FindFirstChildOfClass("UIPadding")
                local fullHeight = menuLayout.AbsoluteContentSize.Y
                    + (menuPadding and (menuPadding.PaddingTop.Offset + menuPadding.PaddingBottom.Offset) or 0)

                local isOpen = false
                local OPEN_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                local defaultChevronColor = chevron.TextColor3

                local function closeMenu()
                    isOpen = false
                    setCardInteractable(true)
                    _activeDropdownClose = nil
                    local menuStroke = menu:FindFirstChildOfClass("UIStroke")
                    TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 }):Play()
                    if menuStroke then TweenService:Create(menuStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Transparency = 1 }):Play() end
                    local tween = TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, 0) })
                    tween:Play()
                    tween.Completed:Connect(function() if not isOpen then menu.Visible = false end end)
                    TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = 90, TextColor3 = defaultChevronColor }):Play()
                    if btnStroke then TweenService:Create(btnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Color = Color3.fromRGB(255,255,255), Transparency = 0.88 }):Play() end
                    for _, ob in ipairs(optButtons) do
                        TweenService:Create(ob.btn.TextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { TextTransparency = 1 }):Play()
                    end
                end

                btn.MouseButton1Click:Connect(function()
                    if _activeDropdownClose and _activeDropdownClose ~= closeMenu then
                        _activeDropdownClose()
                    end
                    isOpen = not isOpen
                    if isOpen then
                        setCardInteractable(false)
                        _activeDropdownClose = closeMenu
                        menu.Visible = true
                        menu.BackgroundTransparency = 0
                        local menuStroke = menu:FindFirstChildOfClass("UIStroke")
                        if menuStroke then menuStroke.Transparency = 0.88 end
                        TweenService:Create(menu, OPEN_TWEEN, { Size = UDim2.new(menuWidth.Scale, menuWidth.Offset, 0, fullHeight) }):Play()
                        TweenService:Create(chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = 0, TextColor3 = ACCENT }):Play()
                        if btnStroke then TweenService:Create(btnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Color = ACCENT, Transparency = 0.3 }):Play() end
                        for _, ob in ipairs(optButtons) do
                            local d = (ob.index - 1) * 0.03
                            ob.btn.TextLabel.TextTransparency = 1
                            TweenService:Create(ob.btn.TextLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, d), { TextTransparency = 0 }):Play()
                        end
                    else
                        closeMenu()
                    end
                end)

                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, vals)
                        selected = {}
                        for _, v in ipairs(vals) do selected[v] = true end
                        updateOptStyles()
                        updateValueText()
                    end,
                    get = function()
                        local list = {}
                        for _, o in ipairs(options) do
                            if selected[o] then table.insert(list, o) end
                        end
                        return list
                    end,
                }
            end

            function cardObj:addAccordion(accConfig)
                accConfig = accConfig or {}
                local items = accConfig.items or {}

                local row = accordion_row_template:Clone()
                local header = row:FindFirstChild("header")
                header:FindFirstChild("label").Text = accConfig.name or "Section"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                row.ClipsDescendants = true

                -- Row uses a UIListLayout so header + content stack vertically
                local rowLayout = Instance.new("UIListLayout")
                rowLayout.FillDirection = Enum.FillDirection.Vertical
                rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
                rowLayout.Padding = UDim.new(0, 0)
                rowLayout.Parent = row

                header.LayoutOrder = 1

                -- Content frame sized by its own layout
                local contentFrame = Instance.new("Frame")
                contentFrame.Name = "content"
                contentFrame.Size = UDim2.new(1, 0, 0, 0)
                contentFrame.BackgroundTransparency = 1
                contentFrame.ClipsDescendants = true
                contentFrame.LayoutOrder = 2
                contentFrame.Parent = row

                -- Inner frame holds actual items, auto-sizes so we know the target height
                local inner = Instance.new("Frame")
                inner.Name = "inner"
                inner.Size = UDim2.new(1, -8, 0, 0)
                inner.Position = UDim2.new(0, 8, 0, 0)
                inner.AutomaticSize = Enum.AutomaticSize.Y
                inner.BackgroundTransparency = 1
                inner.Parent = contentFrame

                local innerLayout = Instance.new("UIListLayout")
                innerLayout.FillDirection = Enum.FillDirection.Vertical
                innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                innerLayout.Padding = UDim.new(0, 2)
                innerLayout.Parent = inner

                local innerPadding = Instance.new("UIPadding")
                innerPadding.PaddingTop = UDim.new(0, 4)
                innerPadding.PaddingBottom = UDim.new(0, 4)
                innerPadding.Parent = inner

                local accentBar = Instance.new("Frame")
                accentBar.Size = UDim2.new(0, 2, 1, 0)
                accentBar.BackgroundColor3 = ACCENT
                accentBar.BorderSizePixel = 0
                accentBar.Parent = contentFrame

                local itemLabels, itemValues = {}, {}
                for i, item in ipairs(items) do
                    local itemRow = Instance.new("Frame")
                    itemRow.Size = UDim2.new(1, 0, 0, 16)
                    itemRow.BackgroundTransparency = 1
                    itemRow.LayoutOrder = i
                    itemRow.Parent = inner

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.6, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 4, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = DIM_TEXT
                    lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Text = item.label or ""
                    lbl.Parent = itemRow
                    itemLabels[i] = lbl

                    local val = Instance.new("TextLabel")
                    val.Size = UDim2.new(0.4, -4, 1, 0)
                    val.Position = UDim2.new(0.6, 0, 0, 0)
                    val.BackgroundTransparency = 1
                    val.TextColor3 = TEXT_COLOR
                    val.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
                    val.TextSize = 11
                    val.TextXAlignment = Enum.TextXAlignment.Right
                    val.Text = item.value or ""
                    val.Parent = itemRow
                    itemValues[i] = val
                end

                -- Calculate target height after layout resolves
                local isOpen = false
                local chevron = header:FindFirstChild("chevron")
                local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                -- Set initial collapsed state
                row.Size = UDim2.new(1, 0, 0, header.AbsoluteSize.Y)
                contentFrame.Size = UDim2.new(1, 0, 0, 0)

                header.MouseButton1Click:Connect(function()
                    isOpen = not isOpen

                    TweenService:Create(chevron, tweenInfo, {
                        Rotation = isOpen and 90 or 0,
                        TextColor3 = isOpen and ACCENT or DIM_TEXT,
                    }):Play()

                    local contentHeight = isOpen and inner.AbsoluteSize.Y or 0
                    local headerHeight = header.AbsoluteSize.Y

                    TweenService:Create(contentFrame, tweenInfo, {
                        Size = UDim2.new(1, 0, 0, contentHeight),
                    }):Play()
                    TweenService:Create(row, tweenInfo, {
                        Size = UDim2.new(1, 0, 0, headerHeight + contentHeight),
                    }):Play()
                end)

                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, label, value)
                        for i, lbl in ipairs(itemLabels) do
                            if lbl.Text == label then itemValues[i].Text = tostring(value); break end
                        end
                    end,
                    get = function(_, label)
                        for i, lbl in ipairs(itemLabels) do
                            if lbl.Text == label then return itemValues[i].Text end
                        end
                    end,
                }
            end

            function cardObj:addProgressBar(pbConfig)
                pbConfig = pbConfig or {}
                local value = pbConfig.default or 0

                local row = progress_row_template:Clone()
                row.label.Text = pbConfig.name or "Progress"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local track = row.track
                local fill = track.fill
                local valueLabel = row.value

                local function updateVisual(val)
                    local pct = math.clamp(val / 100, 0, 1)
                    TweenService:Create(fill, TWEEN_INFO, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                    valueLabel.Text = math.floor(val) .. "%"
                end

                updateVisual(value)
                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, val)
                        value = math.clamp(val, 0, 100)
                        updateVisual(value)
                        if pbConfig.callback then pbConfig.callback(value) end
                    end,
                    get = function()
                        return value
                    end,
                }
            end

            function cardObj:addRating(ratingConfig)
                ratingConfig = ratingConfig or {}
                local value = ratingConfig.default or 0
                local maxStars = 5

                local row = rating_row_template:Clone()
                row.label.Text = ratingConfig.name or "Rating"
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true

                local stars = row.stars
                local starBtns = {}
                for i = 1, maxStars do
                    local star = stars:FindFirstChild("star_" .. i)
                    if star then starBtns[i] = star end
                end

                local function updateStars()
                    for i = 1, maxStars do
                        if starBtns[i] then
                            local target = i <= value and STAR_ON or STAR_OFF
                            TweenService:Create(starBtns[i], TWEEN_INFO, { TextColor3 = target }):Play()
                        end
                    end
                end

                for i = 1, maxStars do
                    if starBtns[i] then
                        starBtns[i].MouseButton1Click:Connect(function()
                            value = (value == i) and 0 or i
                            updateStars()
                            if ratingConfig.callback then ratingConfig.callback(value) end
                        end)
                    end
                end

                updateStars()
                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, val)
                        value = math.clamp(val, 0, maxStars)
                        updateStars()
                    end,
                    get = function()
                        return value
                    end,
                }
            end

            function cardObj:addDataTable(dtConfig)
                dtConfig = dtConfig or {}
                local columns = dtConfig.columns or { "Col 1", "Col 2", "Col 3" }
                local rows = dtConfig.rows or {}

                local row = data_table_row_template:Clone()
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                ensureSep(row)

                local header = row:FindFirstChild("header")
                local colNames = { "col_1", "col_2", "col_3" }
                for i, name in ipairs(colNames) do
                    local col = header:FindFirstChild(name)
                    if col then col.Text = columns[i] or "" end
                end

                local rowFrames = {}

                local function addTableRow(data, index)
                    local cell = data_table_cell_template:Clone()
                    cell.Name = "row_" .. index
                    cell.LayoutOrder = index + 1
                    cell.Visible = true

                    local c1 = cell:FindFirstChild("cell_1")
                    local c2 = cell:FindFirstChild("cell_2")
                    local c3 = cell:FindFirstChild("cell_3")

                    if c1 then c1.Text = tostring(data[1] or "") end
                    if c2 then c2.Text = tostring(data[2] or "") end
                    if c3 then
                        local label = c3:FindFirstChild("label")
                        local dot = c3:FindFirstChild("dot")
                        if type(data[3]) == "table" then
                            if label then
                                label.Text = data[3].text or ""
                                label.TextColor3 = data[3].color or TEXT_COLOR
                            end
                            if dot then dot.BackgroundColor3 = data[3].color or ACCENT end
                        else
                            if label then
                                label.Text = tostring(data[3] or "")
                                label.TextColor3 = TEXT_COLOR
                            end
                            if dot then dot.Visible = false end
                        end
                    end

                    cell.Parent = row
                    rowFrames[#rowFrames + 1] = cell
                end

                for i, data in ipairs(rows) do
                    addTableRow(data, i)
                end

                row.Parent = card
                updateSeparators()

                return {
                    addRow = function(_, data)
                        addTableRow(data, #rowFrames + 1)
                    end,
                    clear = function()
                        for _, rf in ipairs(rowFrames) do rf:Destroy() end
                        rowFrames = {}
                    end,
                    get = function()
                        return #rowFrames
                    end,
                }
            end

            function cardObj:addStatCard(scConfig)
                scConfig = scConfig or {}
                local stats = scConfig.stats or {}

                local row = stat_card_row_template:Clone()
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                ensureSep(row)

                local statFrames = {}
                local colWidth = 1 / math.max(#stats, 1)

                for i, stat in ipairs(stats) do
                    local entry = stat_entry_template:Clone()
                    entry.Name = "stat_" .. i
                    entry.Visible = true
                    entry.Size = UDim2.new(colWidth, 0, 1, 0)
                    entry.Position = UDim2.new((i - 1) * colWidth, 0, 0, 0)

                    entry:FindFirstChild("label").Text = stat.label or ""
                    entry:FindFirstChild("value").Text = stat.value or ""
                    local trend = entry:FindFirstChild("trend")
                    if trend then trend.Text = stat.trend or "" end

                    entry.Parent = row
                    statFrames[i] = entry

                    if i < #stats then
                        local div = Instance.new("Frame")
                        div.Name = "divider_" .. i
                        div.Size = UDim2.new(0, 1, 0, 30)
                        div.Position = UDim2.new(i * colWidth, 0, 0.5, 0)
                        div.AnchorPoint = Vector2.new(0.5, 0.5)
                        div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        div.BackgroundTransparency = 0.9
                        div.BorderSizePixel = 0
                        div.Parent = row
                    end
                end

                row.Parent = card
                updateSeparators()

                return {
                    set = function(_, index, key, val)
                        local f = statFrames[index]
                        if f then
                            local child = f:FindFirstChild(key)
                            if child then child.Text = tostring(val) end
                        end
                    end,
                    get = function(_, index)
                        local f = statFrames[index]
                        if not f then return nil end
                        return {
                            label = f:FindFirstChild("label").Text,
                            value = f:FindFirstChild("value").Text,
                            trend = f:FindFirstChild("trend") and f:FindFirstChild("trend").Text or "",
                        }
                    end,
                }
            end

            function cardObj:addTimeline(tlConfig)
                tlConfig = tlConfig or {}
                local events = tlConfig.events or {}

                local row = timeline_row_template:Clone()
                elementCount = elementCount + 1
                row.LayoutOrder = elementCount
                row.Visible = true
                ensureSep(row)

                local eventHeight = 28
                local totalHeight = math.max(#events * eventHeight, eventHeight)
                row.Size = UDim2.new(1, 0, 0, totalHeight)

                local line = row:FindFirstChild("line")
                if line then line.Size = UDim2.new(0, 2, 1, 0) end

                local eventFrames = {}

                for i, ev in ipairs(events) do
                    local evFrame = timeline_event_template:Clone()
                    evFrame.Name = "event_" .. i
                    evFrame.Position = UDim2.new(0, 0, 0, (i - 1) * eventHeight)
                    evFrame.Visible = true

                    evFrame:FindFirstChild("title").Text = ev.title or ""
                    evFrame:FindFirstChild("desc").Text = ev.desc or ""
                    evFrame:FindFirstChild("time").Text = ev.time or ""

                    local dot = evFrame:FindFirstChild("dot")
                    if dot and ev.color then dot.BackgroundColor3 = ev.color end

                    evFrame.Parent = row
                    eventFrames[i] = evFrame
                end

                row.Parent = card
                updateSeparators()

                return {
                    addEvent = function(_, ev)
                        local i = #eventFrames + 1
                        local evFrame = timeline_event_template:Clone()
                        evFrame.Name = "event_" .. i
                        evFrame.Position = UDim2.new(0, 0, 0, (i - 1) * eventHeight)
                        evFrame.Visible = true
                        evFrame:FindFirstChild("title").Text = ev.title or ""
                        evFrame:FindFirstChild("desc").Text = ev.desc or ""
                        evFrame:FindFirstChild("time").Text = ev.time or ""
                        if ev.color then evFrame:FindFirstChild("dot").BackgroundColor3 = ev.color end
                        evFrame.Parent = row
                        eventFrames[i] = evFrame
                        row.Size = UDim2.new(1, 0, 0, i * eventHeight)
                    end,
                    clear = function()
                        for _, ef in ipairs(eventFrames) do ef:Destroy() end
                        eventFrames = {}
                        row.Size = UDim2.new(1, 0, 0, eventHeight)
                    end,
                    get = function()
                        return #eventFrames
                    end,
                }
            end

            return cardObj
        end

        tabs[#tabs + 1] = tab

        if #tabs == 1 then
            setActiveTab(tab, true)
        end

        btn.MouseButton1Click:Connect(function()
            setActiveTab(tab)
        end)

        return tab
    end

    local notifBadge = minimized_bar_ref and minimized_bar_ref:FindFirstChild("notif_badge")
    local notifCount = 0

    local function updateNotifBadge()
        if notifBadge then
            notifBadge.Visible = notifCount > 0
            local countLabel = notifBadge:FindFirstChild("count")
            if countLabel then countLabel.Text = tostring(notifCount) end
        end
    end
    updateNotifBadge()

    function window:notify(notifConfig)
        notifConfig = notifConfig or {}
        local notifType = notifConfig.type or "info"
        local duration = notifConfig.duration or 3

        local notif = notif_template:Clone()
        notif.Visible = true

        local dot = notif:FindFirstChild("dot")
        if dot then dot.BackgroundColor3 = NOTIF_COLORS[notifType] or NOTIF_COLORS.info end

        local titleLabel = notif:FindFirstChild("title")
        if titleLabel then titleLabel.Text = notifConfig.title or "Notification" end

        local msgLabel = notif:FindFirstChild("message")
        if msgLabel then msgLabel.Text = notifConfig.message or "" end

        notifCount = notifCount + 1
        updateNotifBadge()

        notif.Position = UDim2.new(1, 20, 0, 0)
        notif.Parent = notifications_container

        TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
        }):Play()

        task.delay(duration, function()
            notifCount = math.max(0, notifCount - 1)
            updateNotifBadge()
            local fadeOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, 0),
            })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                notif:Destroy()
            end)
        end)
    end

    function window:showModal(modalConfig)
        modalConfig = modalConfig or {}

        modal_frame.Visible = true
        modal_backdrop.Visible = true

        local titleLabel = modal_frame:FindFirstChild("title")
        if titleLabel then titleLabel.Text = modalConfig.title or "Confirm" end

        local msgLabel = modal_frame:FindFirstChild("message")
        if msgLabel then msgLabel.Text = modalConfig.message or "" end

        local buttons = modal_frame:FindFirstChild("buttons")
        local confirmBtn = buttons and buttons:FindFirstChild("confirm")
        local cancelBtn = buttons and buttons:FindFirstChild("cancel")

        if confirmBtn then confirmBtn.Text = modalConfig.confirmText or "Confirm" end
        if cancelBtn then cancelBtn.Text = modalConfig.cancelText or "Cancel" end

        local conns = {}

        local function closeModal(result)
            modal_frame.Visible = false
            modal_backdrop.Visible = false
            for _, c in ipairs(conns) do c:Disconnect() end
            if modalConfig.callback then modalConfig.callback(result) end
        end

        if confirmBtn then
            table.insert(conns, confirmBtn.MouseButton1Click:Connect(function() closeModal(true) end))
        end
        if cancelBtn then
            table.insert(conns, cancelBtn.MouseButton1Click:Connect(function() closeModal(false) end))
        end
        table.insert(conns, modal_backdrop.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then closeModal(false) end
        end))
    end

    do
        local isMinimized = false
        local search_closed_btn = title_bar:FindFirstChild("search_closed")
        local search_open_frame = title_bar:FindFirstChild("search_open")
        local minimize_btn = title_bar:FindFirstChild("minimize_btn")

        if minimize_btn then
            minimize_btn.MouseButton1Click:Connect(function()
                if isMinimized then return end
                isMinimized = true
                main_frame.Visible = false
                minimized_bar_ref.Visible = true
            end)
        end

        if minimized_bar_ref then
            local maxBtn = minimized_bar_ref:FindFirstChild("maximize_btn")
            if maxBtn then
                maxBtn.MouseButton1Click:Connect(function()
                    if not isMinimized then return end
                    isMinimized = false
                    minimized_bar_ref.Visible = false
                    main_frame.Visible = true
                end)
            end

            local barDragging = false
            local barDragOffset = Vector2.new()
            local dragHandle = minimized_bar_ref:FindFirstChild("drag_handle") or minimized_bar_ref

            dragHandle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    barDragging = true
                    local pos = minimized_bar_ref.AbsolutePosition + minimized_bar_ref.AbsoluteSize * minimized_bar_ref.AnchorPoint
                    barDragOffset = pos - Vector2.new(input.Position.X, input.Position.Y)
                end
            end)
            dragHandle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then barDragging = false end
            end)

            local barDragConn = UserInputService.InputChanged:Connect(newcclosure(function(input)
                if barDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    TweenService:Create(minimized_bar_ref, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                        Position = UDim2.new(0, input.Position.X + barDragOffset.X, 0, input.Position.Y + barDragOffset.Y),
                    }):Play()
                end
            end))
            table.insert(_G._uiLibConnections, barDragConn)
        end

        function window:minimize()
            if not isMinimized and minimize_btn then
                isMinimized = true
                main_frame.Visible = false
                minimized_bar_ref.Visible = true
            end
        end

        function window:maximize()
            if isMinimized then
                isMinimized = false
                minimized_bar_ref.Visible = false
                main_frame.Visible = true
            end
        end

        if search_closed_btn and search_open_frame then
            local searchInput = search_open_frame:FindFirstChild("input")
            local searchClose = search_open_frame:FindFirstChild("close")

            search_open_frame.Visible = false

            search_closed_btn.MouseButton1Click:Connect(function()
                search_closed_btn.Visible = false
                search_open_frame.Visible = true
                if searchInput then searchInput:CaptureFocus() end
            end)

            if searchClose then
                searchClose.MouseButton1Click:Connect(function()
                    search_open_frame.Visible = false
                    search_closed_btn.Visible = true
                    if searchInput then searchInput.Text = "" end
                    for _, child in ipairs(content:GetDescendants()) do
                        if child:IsA("GuiObject") and child:FindFirstChild("label") and child:FindFirstChild("sep") then
                            child.Visible = true
                        end
                    end
                end)
            end

            if searchInput then
                searchInput:GetPropertyChangedSignal("Text"):Connect(function()
                    local query = searchInput.Text:lower()
                    for _, child in ipairs(content:GetDescendants()) do
                        if child:IsA("GuiObject") and child:FindFirstChild("label") and child:FindFirstChild("sep") then
                            if query == "" then
                                child.Visible = true
                            else
                                child.Visible = child:FindFirstChild("label").Text:lower():find(query, 1, true) ~= nil
                            end
                        end
                    end
                end)
            end
        end
    end

    if login_panel_ref then
        login_panel_ref.Visible = false

        function window:showLogin(loginConfig)
            loginConfig = loginConfig or {}
            login_panel_ref.Visible = true
            main_frame.Visible = false

            local titleLabel = login_panel_ref:FindFirstChild("title")
            if titleLabel then titleLabel.Text = loginConfig.title or "Welcome Back" end

            local subtitleLabel = login_panel_ref:FindFirstChild("subtitle")
            if subtitleLabel then subtitleLabel.Text = loginConfig.subtitle or "Sign in to continue" end

            local status = login_panel_ref:FindFirstChild("status")
            if status then status.Visible = false end

            local usernameInput = login_panel_ref:FindFirstChild("username_input")
            local keyInput = login_panel_ref:FindFirstChild("key_input")
            local signInBtn = login_panel_ref:FindFirstChild("sign_in_btn")

            local usernameBox = usernameInput and usernameInput:FindFirstChild("input")
            local keyBox = keyInput and keyInput:FindFirstChild("input")

            if signInBtn then
                signInBtn.MouseButton1Click:Connect(function()
                    local user = usernameBox and usernameBox.Text or ""
                    local key = keyBox and keyBox.Text or ""
                    if loginConfig.callback then
                        local success, msg = loginConfig.callback(user, key)
                        if success then
                            login_panel_ref.Visible = false
                            main_frame.Visible = true
                        else
                            if status then
                                status.Text = msg or "Invalid credentials"
                                status.Visible = true
                            end
                        end
                    else
                        login_panel_ref.Visible = false
                        main_frame.Visible = true
                    end
                end)
            end
        end
    end

    if tooltip_frame then
        tooltip_frame.Visible = false
        local tooltipLabel = tooltip_frame:FindFirstChild("label")

        function window:showTooltip(text, guiObject)
            if not tooltipLabel then return end
            tooltipLabel.Text = text or ""
            tooltip_frame.Visible = true
            local pos = guiObject.AbsolutePosition
            local size = guiObject.AbsoluteSize
            tooltip_frame.Position = UDim2.new(0, pos.X + size.X / 2, 0, pos.Y - 30)
        end

        function window:hideTooltip()
            tooltip_frame.Visible = false
        end
    end

    task.defer(function()
        local uiScale = Instance.new("UIScale")
        uiScale.Scale = 0.9
        uiScale.Parent = main_frame

        local mainStroke = main_frame:FindFirstChildOfClass("UIStroke")
        local shadow = main_frame:FindFirstChild("shadow")
        local titleLine = title_bar:FindFirstChild("line")
        local dragIcon = title_bar:FindFirstChild("drag_icon")
        local origMainBg = main_frame.BackgroundTransparency
        local origStrokeT = mainStroke and mainStroke.Transparency or 1
        local origShadowT = shadow and shadow.ImageTransparency or 1
        local origLineT = titleLine and titleLine.BackgroundTransparency or 1
        local origLogoT = title_bar.logo.ImageTransparency
        local origBrandT = title_bar.brand_name.TextTransparency
        local origDragT = dragIcon and dragIcon.ImageTransparency or 1

        main_frame.BackgroundTransparency = 1
        if mainStroke then mainStroke.Transparency = 1 end
        if shadow then shadow.ImageTransparency = 1 end
        if titleLine then titleLine.BackgroundTransparency = 1 end
        title_bar.logo.ImageTransparency = 1
        title_bar.brand_name.TextTransparency = 1
        if dragIcon then dragIcon.ImageTransparency = 1 end

        local initCards = activeTab and activeTab._cards or {}
        local cardMetas = {}
        for ci, card in ipairs(initCards) do
            local meta = {
                bg = card.BackgroundTransparency,
                stroke = card:FindFirstChildOfClass("UIStroke"),
                texts = {},
                images = {},
            }
            if meta.stroke then meta.strokeT = meta.stroke.Transparency; meta.stroke.Transparency = 1 end
            card.BackgroundTransparency = 1
            for _, desc in ipairs(card:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    table.insert(meta.texts, { obj = desc, origT = desc.TextTransparency })
                    desc.TextTransparency = 1
                elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    table.insert(meta.images, { obj = desc, origT = desc.ImageTransparency })
                    desc.ImageTransparency = 1
                end
            end
            cardMetas[ci] = meta
        end

        local navMetas = {}
        for i, t in ipairs(tabs) do
            local isActive = (t == activeTab)
            local bStroke = t._btn:FindFirstChildOfClass("UIStroke")
            navMetas[i] = {
                bg = isActive and 0.72 or 1,
                labelT = isActive and 0 or t._btn.label.TextTransparency,
                iconT = isActive and 0 or t._btn.icon.ImageTransparency,
                labelColor = isActive and activeColor or inactiveColor,
                iconColor = isActive and activeIconColor or inactiveIconColor,
                stroke = bStroke,
                strokeEnabled = isActive and true or false,
            }
            t._btn.BackgroundTransparency = 1
            t._btn.label.TextTransparency = 1
            t._btn.icon.ImageTransparency = 1
            if bStroke then bStroke.Enabled = false end
        end

        main_frame.Visible = true
        Heartbeat:Wait()

        TweenService:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Scale = 1,
        }):Play()
        TweenService:Create(main_frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = origMainBg,
        }):Play()
        if mainStroke then
            TweenService:Create(mainStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Transparency = origStrokeT,
            }):Play()
        end

        if shadow then
            TweenService:Create(shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.08), {
                ImageTransparency = origShadowT,
            }):Play()
        end

        local titleTi = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.12)
        TweenService:Create(title_bar.logo, titleTi, { ImageTransparency = origLogoT }):Play()
        TweenService:Create(title_bar.brand_name, titleTi, { TextTransparency = origBrandT }):Play()
        if titleLine then
            TweenService:Create(titleLine, titleTi, { BackgroundTransparency = origLineT }):Play()
        end
        if dragIcon then
            TweenService:Create(dragIcon, titleTi, { ImageTransparency = origDragT }):Play()
        end

        for ci, card in ipairs(initCards) do
            local m = cardMetas[ci]
            local d = 0.18 + (ci - 1) * 0.06
            local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, d)
            TweenService:Create(card, ti, { BackgroundTransparency = m.bg }):Play()
            if m.stroke then
                TweenService:Create(m.stroke, ti, { Transparency = m.strokeT }):Play()
            end
            for _, t in ipairs(m.texts) do
                TweenService:Create(t.obj, ti, { TextTransparency = t.origT }):Play()
            end
            for _, img in ipairs(m.images) do
                TweenService:Create(img.obj, ti, { ImageTransparency = img.origT }):Play()
            end
        end

        for i, t in ipairs(tabs) do
            local nm = navMetas[i]
            local d = 0.22 + (i - 1) * 0.05
            local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, d)
            TweenService:Create(t._btn, ti, { BackgroundTransparency = nm.bg }):Play()
            TweenService:Create(t._btn.label, ti, {
                TextTransparency = nm.labelT, TextColor3 = nm.labelColor,
            }):Play()
            TweenService:Create(t._btn.icon, ti, {
                ImageTransparency = nm.iconT, ImageColor3 = nm.iconColor,
            }):Play()
            if nm.stroke and nm.strokeEnabled then
                task.delay(d, function() nm.stroke.Enabled = true end)
            end
        end

        local elapsed = 0
        while elapsed < 0.55 do
            elapsed = elapsed + Heartbeat:Wait()
        end
        uiScale:Destroy()
    end)

    return window
end

setstackhidden(lib.new, true)
makereadonly(lib)

return lib
