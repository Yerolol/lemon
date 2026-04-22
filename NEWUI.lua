--[[
    Lemon UI - Complete Fixed Version
    Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/username/Lemon/main/Lemon.lua"))()
]]

-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Library init / globals
getgenv().Lemon = getgenv().Lemon or {}
local Lemon = getgenv().Lemon

Lemon.Directory    = "Lemon.gg"
Lemon.Folders      = {"/configs"}
Lemon.Flags        = {}
Lemon.ConfigFlags  = {}
Lemon.Connections  = {}
Lemon.Notifications= {Notifs = {}}
Lemon.__index      = Lemon

local Flags          = Lemon.Flags
local ConfigFlags    = Lemon.ConfigFlags
local Notifications  = Lemon.Notifications

-- Lemon Yellow Theme
local themes = {
    preset = {
        accent       = rgb(255, 200, 0),
        glow         = rgb(255, 220, 50),
        background   = rgb(15, 15, 15),
        section      = rgb(25, 25, 25),
        element      = rgb(35, 35, 35),
        outline      = rgb(50, 50, 50),
        text         = rgb(255, 255, 255),
        subtext      = rgb(160, 160, 160),
        tab_active   = rgb(255, 200, 0),
        tab_inactive = rgb(15, 15, 15),
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

for _, path in Lemon.Folders do
    pcall(function() makefolder(Lemon.Directory .. path) end)
end

-- Chat System Variables
local ChatAPI = {
    BaseURL = "http://localhost:8000",
    ActiveUsers = 0,
    Messages = {},
    ChatEnabled = false,
    Connection = nil,
    ChatBox = nil
}

function Lemon:Tween(Object, Properties, Info)
    if not Object then return end
    local tween = TweenService:Create(Object, Info or TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
    tween:Play()
    return tween
end

function Lemon:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

function Lemon:GetDeviceType()
    if GuiService:IsTenFootInterface() then
        return "Console"
    elseif InputService.TouchEnabled and not InputService.KeyboardEnabled then
        return "Mobile"
    elseif InputService.TouchEnabled and InputService.KeyboardEnabled then
        return "Tablet"
    else
        return "PC"
    end
end

function Lemon:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function Lemon:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
end

-- Chat System Functions
function Lemon:ConnectChatServer()
    pcall(function()
        local response = game:HttpGet(ChatAPI.BaseURL .. "/connect")
        if response then
            print("[Lemon] Connected to chat server")
            self:UpdateActiveUsers()
        end
    end)
end

function Lemon:UpdateActiveUsers()
    pcall(function()
        local response = game:HttpGet(ChatAPI.BaseURL .. "/active_users")
        local data = HttpService:JSONDecode(response)
        ChatAPI.ActiveUsers = data.count or 0
        
        if Lemon.ChatUI and Lemon.ChatUI.ActiveUsersLabel then
            Lemon.ChatUI.ActiveUsersLabel.Text = "👥 " .. ChatAPI.ActiveUsers .. " Online"
        end
    end)
end

function Lemon:SendChatMessage(message)
    if not ChatAPI.ChatEnabled then return end
    
    pcall(function()
        local data = {
            userId = lp.UserId,
            username = Flags["Lemon_StreamerMode"] and "Hidden User" or lp.Name,
            message = message,
            timestamp = os.time()
        }
        
        request({
            Url = ChatAPI.BaseURL .. "/send_message",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

function Lemon:CreateChatUI()
    local ChatBox = Lemon:Create("Frame", {
        Parent = Lemon.Gui,
        Position = dim2(0, -290, 0.5, -200),
        Size = dim2(0, 280, 0, 380),
        BackgroundColor3 = themes.preset.background,
        BorderSizePixel = 0,
        ZIndex = 100,
        Visible = false
    })
    Lemon:Create("UICorner", {Parent = ChatBox, CornerRadius = dim(0, 8)})
    Lemon:Themify(Lemon:Create("UIStroke", {Parent = ChatBox, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")
    
    -- Chat Header
    local Header = Lemon:Create("Frame", {
        Parent = ChatBox,
        Size = dim2(1, 0, 0, 40),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0
    })
    Lemon:Create("UICorner", {Parent = Header, CornerRadius = dim(0, 8)})
    
    Lemon.ChatUI = {}
    Lemon.ChatUI.ActiveUsersLabel = Lemon:Create("TextLabel", {
        Parent = Header,
        Position = dim2(0, 10, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(1, -20, 0, 20),
        BackgroundTransparency = 1,
        Text = "👥 0 Online",
        TextColor3 = themes.preset.text,
        TextSize = 13,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(Lemon.ChatUI.ActiveUsersLabel, "text", "TextColor3")
    
    -- Close Chat Button
    local CloseChat = Lemon:Create("TextButton", {
        Parent = Header,
        Position = dim2(1, -10, 0.5, 0),
        AnchorPoint = vec2(1, 0.5),
        Size = dim2(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = themes.preset.subtext,
        TextSize = 16,
        ZIndex = 101
    })
    CloseChat.MouseButton1Click:Connect(function()
        ChatBox.Visible = false
    end)
    
    -- Chat Messages
    local MessagesFrame = Lemon:Create("ScrollingFrame", {
        Parent = ChatBox,
        Position = dim2(0, 0, 0, 40),
        Size = dim2(1, 0, 1, -80),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        CanvasSize = dim2(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageColor3 = themes.preset.accent
    })
    
    Lemon.ChatUI.MessagesList = Lemon:Create("UIListLayout", {
        Parent = MessagesFrame,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Lemon:Create("UIPadding", {
        Parent = MessagesFrame,
        PaddingLeft = dim(0, 8),
        PaddingRight = dim(0, 8),
        PaddingTop = dim(0, 6)
    })
    
    -- Chat Input
    local InputFrame = Lemon:Create("Frame", {
        Parent = ChatBox,
        Position = dim2(0, 0, 1, -40),
        Size = dim2(1, 0, 0, 40),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0
    })
    
    local InputBox = Lemon:Create("TextBox", {
        Parent = InputFrame,
        Position = dim2(0, 8, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(1, -50, 0, 28),
        BackgroundColor3 = themes.preset.element,
        Text = "",
        PlaceholderText = "Type a message...",
        TextColor3 = themes.preset.text,
        PlaceholderColor3 = themes.preset.subtext,
        TextSize = 13,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        ClearTextOnFocus = false
    })
    Lemon:Create("UICorner", {Parent = InputBox, CornerRadius = dim(0, 6)})
    Lemon:Themify(InputBox, "element", "BackgroundColor3")
    Lemon:Themify(InputBox, "text", "TextColor3")
    
    local SendButton = Lemon:Create("TextButton", {
        Parent = InputFrame,
        Position = dim2(1, -8, 0.5, 0),
        AnchorPoint = vec2(1, 0.5),
        Size = dim2(0, 30, 0, 28),
        BackgroundColor3 = themes.preset.accent,
        Text = "➤",
        TextColor3 = rgb(15, 15, 15),
        TextSize = 16,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold)
    })
    Lemon:Create("UICorner", {Parent = SendButton, CornerRadius = dim(0, 6)})
    Lemon:Themify(SendButton, "accent", "BackgroundColor3")
    
    SendButton.MouseButton1Click:Connect(function()
        if InputBox.Text ~= "" then
            Lemon:SendChatMessage(InputBox.Text)
            Lemon:AddChatMessage(lp.UserId, lp.Name, InputBox.Text, os.time())
            InputBox.Text = ""
        end
    end)
    
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and InputBox.Text ~= "" then
            Lemon:SendChatMessage(InputBox.Text)
            Lemon:AddChatMessage(lp.UserId, lp.Name, InputBox.Text, os.time())
            InputBox.Text = ""
        end
    end)
    
    Lemon.ChatUI.MessagesFrame = MessagesFrame
    Lemon.ChatUI.Box = ChatBox
    ChatAPI.ChatBox = ChatBox
    
    return ChatBox
end

function Lemon:AddChatMessage(userId, username, message, timestamp)
    if not Lemon.ChatUI or not Lemon.ChatUI.MessagesFrame then return end
    
    if Flags["Lemon_StreamerMode"] then
        username = "Hidden User"
    end
    
    local MessageFrame = Lemon:Create("Frame", {
        Parent = Lemon.ChatUI.MessagesFrame,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    })
    
    -- Avatar
    local Avatar = Lemon:Create("ImageLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 0, 0, 2),
        Size = dim2(0, 22, 0, 22),
        BackgroundTransparency = 1,
        Image = Flags["Lemon_StreamerMode"] and "rbxthumb://type=AvatarHeadShot&id=1&w=44&h=44" or "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=44&h=44"
    })
    Lemon:Create("UICorner", {Parent = Avatar, CornerRadius = dim(0, 11)})
    
    -- Username and Time
    local NameLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 28, 0, 2),
        Size = dim2(1, -60, 0, 14),
        BackgroundTransparency = 1,
        Text = username,
        TextColor3 = themes.preset.accent,
        TextSize = 11,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(NameLabel, "accent", "TextColor3")
    
    local TimeLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(1, -5, 0, 2),
        AnchorPoint = vec2(1, 0),
        Size = dim2(0, 40, 0, 14),
        BackgroundTransparency = 1,
        Text = os.date("%H:%M", timestamp),
        TextColor3 = themes.preset.subtext,
        TextSize = 10,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Right
    })
    Lemon:Themify(TimeLabel, "subtext", "TextColor3")
    
    -- Message
    local MessageLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 28, 0, 18),
        Size = dim2(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = themes.preset.text,
        TextSize = 12,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    Lemon:Themify(MessageLabel, "text", "TextColor3")
    
    Lemon.ChatUI.MessagesFrame.CanvasPosition = vec2(0, Lemon.ChatUI.MessagesFrame.CanvasSize.Y.Offset)
end

-- Window function
function Lemon:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or "Lemon", 
        Subtitle = properties.Subtitle or properties.subtitle or ".gg",
        Size = properties.Size or properties.size or dim2(0, 700, 0, 550), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    if Lemon.Gui then Lemon.Gui:Destroy() end
    if Lemon.Other then Lemon.Other:Destroy() end
    if Lemon.ToggleGui then Lemon.ToggleGui:Destroy() end

    Lemon.Gui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonGG", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Lemon.Other = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true
    
    -- Auto-size based on device
    local deviceType = Lemon:GetDeviceType()
    local scaleFactor = 1
    if deviceType == "Mobile" then
        scaleFactor = 0.8
    elseif deviceType == "Tablet" then
        scaleFactor = 0.88
    end
    
    local windowSize = dim2(0, Cfg.Size.X.Offset * scaleFactor * 1.2, 0, Cfg.Size.Y.Offset * scaleFactor * 1.2)

    Items.Wrapper = Lemon:Create("Frame", {
        Parent = Lemon.Gui, Position = dim2(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
        Size = windowSize, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    Items.Glow = Lemon:Create("ImageLabel", {
        ImageColor3 = themes.preset.glow,
        ScaleType = Enum.ScaleType.Slice,
        ImageTransparency = 0.65,
        BorderColor3 = rgb(0, 0, 0),
        Parent = Items.Wrapper,
        Size = dim2(1, 40, 1, 40),
        Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1,
        Position = dim2(0, -20, 0, -20),
        BackgroundColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        SliceCenter = rect(vec2(21, 21), vec2(79, 79)),
        ZIndex = 0
    })
    Lemon:Themify(Items.Glow, "glow", "ImageColor3")

    Items.Window = Lemon:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Lemon:Themify(Items.Window, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 12) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 45), BackgroundTransparency = 1, Active = true, ZIndex = 2 })

    Items.LogoBlock = Lemon:Create("Frame", {
        Parent = Items.Header, 
        AnchorPoint = vec2(0, 0.5), 
        Position = dim2(0, 16, 0.5, 0), 
        Size = dim2(0, 18, 0, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    Lemon:Create("UICorner", { Parent = Items.LogoBlock, CornerRadius = dim(0, 4) })
    Lemon:Themify(Items.LogoBlock, "accent", "BackgroundColor3")

    Items.LogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 16, 0, 10), 
        Size = dim2(0, 0, 0, 13), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 16, 0, 23), 
        Size = dim2(0, 0, 0, 11), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.SubLogoText, "subtext", "TextColor3")

    -- BIGGER OPEN/CLOSE BUTTON
    Items.CloseBtn = Lemon:Create("ImageButton", {
        Parent = Lemon.Gui,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -20, 0, 20),
        Size = dim2(0, 48, 0, 48),  -- BIGGER
        BackgroundColor3 = themes.preset.section,  -- Background added
        Image = "rbxassetid://86658474847671",
        ImageColor3 = themes.preset.subtext,
        ZIndex = 1000
    })
    Lemon:Create("UICorner", { Parent = Items.CloseBtn, CornerRadius = dim(0, 12) })  -- Cleaner corner
    Lemon:Themify(Items.CloseBtn, "subtext", "ImageColor3")
    Lemon:Themify(Items.CloseBtn, "section", "BackgroundColor3")
    
    Items.CloseBtn.MouseButton1Click:Connect(function()
        Cfg.ToggleMenu()
    end)

    Items.PageHolder = Lemon:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 45), Size = dim2(1, 0, 1, -90), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Footer with Profile
    Items.Footer = Lemon:Create("Frame", { 
        Parent = Items.Window, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), 
        Size = dim2(1, 0, 0, 45), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 
    })

    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.AvatarFrame = Lemon:Create("Frame", {
        Parent = Items.Footer, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 16, 0.5, 0), 
        Size = dim2(0, 28, 0, 28), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 5
    })
    Lemon:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(0, 6) })
    
    Items.Avatar = Lemon:Create("ImageLabel", { 
        Parent = Items.AvatarFrame, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), 
        Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot, ZIndex = 6 
    })
    Lemon:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(0, 6) })

    Items.Username = Lemon:Create("TextLabel", {
        Parent = Items.Footer, Text = lp.Name, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 52, 0, 10), Size = dim2(0, 150, 0, 13),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
    })
    Lemon:Themify(Items.Username, "text", "TextColor3")

    Items.Status = Lemon:Create("TextLabel", {
        Parent = Items.Footer, Text = "🍋 Lemon User", TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 52, 0, 24), Size = dim2(0, 150, 0, 11),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
    })
    Lemon:Themify(Items.Status, "subtext", "TextColor3")

    -- Settings Button
    Items.SettingsBtn = Lemon:Create("ImageButton", {
        Parent = Items.Footer, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -16, 0.5, 0),
        Size = dim2(0, 20, 0, 20), BackgroundTransparency = 1, Image = "rbxassetid://11293977610", ImageColor3 = themes.preset.subtext, ZIndex = 5
    })
    Lemon:Themify(Items.SettingsBtn, "subtext", "ImageColor3")
    
    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    -- Tab Box (Outside UI, below it)
    Items.TabBox = Lemon:Create("Frame", {
        Parent = Items.Wrapper,
        AnchorPoint = vec2(0.5, 0),
        Position = dim2(0.5, 0, 1, 5),
        Size = dim2(0, 0, 0, 42),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    Lemon:Create("UICorner", { Parent = Items.TabBox, CornerRadius = dim(0, 14) })
    Lemon:Themify(Items.TabBox, "section", "BackgroundColor3")
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.TabBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Lemon:Create("UIPadding", {
        Parent = Items.TabBox,
        PaddingLeft = dim(0, 6),
        PaddingRight = dim(0, 6),
        PaddingTop = dim(0, 5),
        PaddingBottom = dim(0, 5)
    })
    
    Items.TabHolder = Lemon:Create("Frame", { 
        Parent = Items.TabBox,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 6
    })
    Lemon:Create("UIListLayout", { 
        Parent = Items.TabHolder, 
        FillDirection = Enum.FillDirection.Horizontal, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, 
        VerticalAlignment = Enum.VerticalAlignment.Center, 
        Padding = dim(0, 2) 
    })

    -- Dragging Logic
    local Dragging, DragInput, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
            
            if ChatAPI.ChatBox then
                ChatAPI.ChatBox.Position = dim2(0, Items.Wrapper.Position.X.Offset - 290, 0.5, Items.Wrapper.Position.Y.Offset - 200)
            end
        end
    end)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
        if ChatAPI.ChatBox and ChatAPI.ChatEnabled then
            ChatAPI.ChatBox.Visible = uiVisible and ChatAPI.ChatEnabled
        end
    end

    -- Create Chat UI
    Lemon:CreateChatUI()
    
    -- Position chat relative to UI
    if ChatAPI.ChatBox then
        ChatAPI.ChatBox.Position = dim2(0, Items.Wrapper.Position.X.Offset - 290, 0.5, Items.Wrapper.Position.Y.Offset - 200)
    end

    return setmetatable(Cfg, Lemon)
end

-- Tab function (SINGLE PANEL VERSION)
function Lemon:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610", 
        Hidden = properties.Hidden or properties.hidden or false, 
        Items = {} 
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        Items.Button = Lemon:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 36, 0, 32), 
            BackgroundColor3 = themes.preset.accent,
            BackgroundTransparency = 1, 
            Text = "",  -- ICON ONLY, NO TEXT
            AutoButtonColor = false, ZIndex = 7,
            ClipsDescendants = true
        })
        Lemon:Themify(Items.Button, "accent", "BackgroundColor3")
        Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 10) })
        
        Items.IconImg = Lemon:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 20, 0, 20), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 8 
        })
        Lemon:Themify(Items.IconImg, "subtext", "ImageColor3")
    end

    Items.Pages = Lemon:Create("CanvasGroup", { Parent = Lemon.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Lemon:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 12) })
    Lemon:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 8), PaddingBottom = dim(0, 8), PaddingRight = dim(0, 16), PaddingLeft = dim(0, 16) })

    -- SINGLE PANEL INSTEAD OF SPLIT
    Items.Main = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 4, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Main, Padding = dim(0, 10) })
    Lemon:Create("UIPadding", { Parent = Items.Main, PaddingBottom = dim(0, 8) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        -- Close any open dropdowns in old tab
        if oldTab and oldTab.DropFrame then
            oldTab.DropFrame.Visible = false
        end

        local buttonTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            Lemon:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween)
            Lemon:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
        end

        if Items.Button then 
            Lemon:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            Lemon:Tween(Items.IconImg, {ImageColor3 = rgb(15, 15, 15)}, buttonTween)
        end
        
        task.spawn(function()
            if oldTab then
                Lemon:Tween(oldTab.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 8)}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Lemon.Other
            end

            Items.Pages.Position = dim2(0, 0, 0, 8) 
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Lemon:Tween(Items.Pages, {GroupTransparency = 0, Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.wait(0.35)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Lemon)
end

-- Section function (CLEANER DESIGN)
function Lemon:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        RightIcon = properties.RightIcon or properties.righticon or "rbxassetid://12338898398",
        Items = {} 
    }
    local Items = Cfg.Items

    -- Cleaner section design
    Items.Section = Lemon:Create("Frame", { 
        Parent = self.Items.Main,  -- Now parented to Main (single panel)
        Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = rgb(20, 20, 20),  -- Darker cleaner background
        BorderSizePixel = 0, ClipsDescendants = true 
    })
    Lemon:Themify(Items.Section, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 10) })
    
    -- Clean border stroke
    Lemon:Themify(Lemon:Create("UIStroke", { 
        Parent = Items.Section, 
        Color = rgb(40, 40, 40), 
        Thickness = 1 
    }), "outline", "Color")
    
    Items.AccentLine = Lemon:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 3, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })
    Lemon:Themify(Items.AccentLine, "accent", "BackgroundColor3")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 32), BackgroundTransparency = 1 })
    
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 12, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -46, 0, 13), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "text", "TextColor3")

    Items.Chevron = Lemon:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(1, -12, 0.5, 0), AnchorPoint = vec2(1, 0.5), Size = dim2(0, 11, 0, 11),
        BackgroundTransparency = 1, Image = Cfg.RightIcon, ImageColor3 = themes.preset.subtext, 
        Rotation = 0
    })
    Lemon:Themify(Items.Chevron, "subtext", "ImageColor3")

    Items.Container = Lemon:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 32), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 10), PaddingLeft = dim(0, 12), PaddingRight = dim(0, 12) })

    return setmetatable(Cfg, Lemon)
end

-- MODERN TOGGLE ELEMENT (SWITCH STYLE)
function Lemon:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 28), BackgroundTransparency = 1, Text = "" })
    
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 0, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -60, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    -- Modern switch style
    Items.Switch = Lemon:Create("Frame", {
        Parent = Items.Button,
        Position = dim2(1, -50, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 40, 0, 18),
        BackgroundColor3 = themes.preset.element
    })
    Lemon:Create("UICorner", {Parent = Items.Switch, CornerRadius = dim(1, 0)})
    Lemon:Themify(Items.Switch, "element", "BackgroundColor3")

    Items.Knob = Lemon:Create("Frame", {
        Parent = Items.Switch,
        Size = dim2(0, 16, 0, 16),
        Position = dim2(0, 1, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Lemon:Create("UICorner", {Parent = Items.Knob, CornerRadius = dim(1, 0)})

    local State = false
    function Cfg.set(bool)
        State = bool
        
        Lemon:Tween(Items.Knob, {
            Position = State and dim2(1, -17, 0.5, 0) or dim2(0, 1, 0.5, 0)
        }, TweenInfo.new(0.2))
        
        Lemon:Tween(Items.Switch, {
            BackgroundColor3 = State and themes.preset.accent or themes.preset.element
        }, TweenInfo.new(0.2))
        
        Lemon:Tween(Items.Title, {
            TextColor3 = State and themes.preset.text or themes.preset.subtext
        }, TweenInfo.new(0.2))
        
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

-- Button Element
function Lemon:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 28), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Lemon:Themify(Items.Button, "element", "BackgroundColor3")
    Lemon:Themify(Items.Button, "subtext", "TextColor3")
    Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) })

    Items.Button.MouseButton1Click:Connect(function()
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.accent, TextColor3 = rgb(15,15,15)}, TweenInfo.new(0.1))
        task.wait(0.1)
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Lemon)
end

-- FIXED SLIDER ELEMENT (NO NAN + SMOOTH)
function Lemon:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 18), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Val = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 18), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right })
    Lemon:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Lemon:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 3, 0, 22), Size = dim2(1, -7, 0, 5), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Lemon:Themify(Items.Track, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(0, 8) })

    Items.Fill = Lemon:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Lemon:Themify(Items.Fill, "accent", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(0, 8) })
    
    Items.Knob = Lemon:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 10, 0, 10), BackgroundColor3 = themes.preset.accent })
    Lemon:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(0, 8) })
    Lemon:Themify(Items.Knob, "accent", "BackgroundColor3")

    local Value = Cfg.Default
    function Cfg.set(val)
        -- FIX: No NaN, proper type checking
        if typeof(val) ~= "number" then 
            val = Cfg.Min 
        end
        
        Value = math.clamp(val, Cfg.Min, Cfg.Max)
        Value = math.floor(Value / Cfg.Increment + 0.5) * Cfg.Increment
        
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        
        local percent = (Value - Cfg.Min) / (Cfg.Max - Cfg.Min)
        Lemon:Tween(Items.Fill, {
            Size = dim2(percent, 0, 1, 0)
        }, TweenInfo.new(0.1))
        
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = true
            local percent = math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * percent)
        end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = false 
        end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * percent)
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Textbox Element
function Lemon:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 30), BackgroundTransparency = 1 })
    Items.Bg = Lemon:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Lemon:Themify(Items.Bg, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 8) })

    Items.Input = Lemon:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Lemon:Themify(Items.Input, "text", "TextColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

-- FIXED DROPDOWN (NO SEARCH, CLICK OUTSIDE, PROPER POSITION)
function Lemon:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 42), BackgroundTransparency = 1, ClipsDescendants = false })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 14), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    Items.Main = Lemon:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 18), Size = dim2(1, 0, 0, 24), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Lemon:Themify(Items.Main, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 8) })

    Items.SelectedText = Lemon:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 1, 0), BackgroundTransparency = 1, Text = Cfg.Default or "Select...", TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Lemon:Themify(Items.SelectedText, "subtext", "TextColor3")
    
    Items.Icon = Lemon:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -18, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 9, 0, 9), BackgroundTransparency = 1, Image = "rbxassetid://12338898398", ImageColor3 = themes.preset.subtext })

    -- Dropdown now parented to Container for proper positioning
    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Items.Container, 
        Position = dim2(0, 0, 0, 44),  -- Sits directly under button
        Size = dim2(1, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, 
        Visible = false, 
        ZIndex = 200, 
        ClipsDescendants = true 
    })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 8) })

    Items.Scroll = Lemon:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, 
        Position = dim2(0, 4, 0, 4), 
        Size = dim2(1, -8, 1, -8), 
        BackgroundTransparency = 1, 
        ScrollBarThickness = 0, 
        BorderSizePixel = 0, 
        ZIndex = 201,
        CanvasSize = dim2(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local OptionBtns = {}

    local function ToggleDropdown()
        if not Open then
            Open = true
            Items.DropFrame.Visible = true
            Items.DropFrame.Size = dim2(1, 0, 0, 0)
            
            local visibleCount = #Cfg.Options
            local targetHeight = math.clamp(visibleCount * 24 + 8, 32, 160)  -- NO SEARCH BAR HEIGHT
            
            Lemon:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.2))
            Lemon:Tween(Items.DropFrame, {Size = dim2(1, 0, 0, targetHeight)}, TweenInfo.new(0.2))
        else
            Open = false
            Lemon:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.2))
            Lemon:Tween(Items.DropFrame, {Size = dim2(1, 0, 0, 0)}, TweenInfo.new(0.2))
            task.wait(0.2)
            Items.DropFrame.Visible = false
        end
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    -- CLICK OUTSIDE TO CLOSE
    InputService.InputBegan:Connect(function(input)
        if Open and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local framePos = Items.DropFrame.AbsolutePosition
            local frameSize = Items.DropFrame.AbsoluteSize
            
            if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                    mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                ToggleDropdown()
            end
        end
    end)

    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        
        -- Clear old options
        for _, btn in ipairs(OptionBtns) do btn:Destroy() end
        table.clear(OptionBtns)
        
        -- Create new options
        for _, opt in ipairs(Cfg.Options) do
            local btn = Lemon:Create("TextButton", { 
                Parent = Items.Scroll, 
                Size = dim2(1, -8, 0, 24), 
                BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), 
                TextColor3 = themes.preset.subtext, 
                TextSize = 12, 
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), 
                TextXAlignment = Enum.TextXAlignment.Left, 
                ZIndex = 202
            })
            Lemon:Themify(btn, "subtext", "TextColor3")
            btn.MouseButton1Click:Connect(function() 
                Cfg.set(opt)
                ToggleDropdown() 
            end)
            table.insert(OptionBtns, btn)
        end
    end

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    
    return setmetatable(Cfg, Lemon)
end

-- Label Element
function Lemon:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 24 or 16), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Lemon)
end

-- Colorpicker Element
function Lemon:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 200, 0), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local parentContainer = self.Items.Title or self.Items.Button or self.Items.Container
    local btn = Lemon:Create("TextButton", { Parent = parentContainer, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -5, 0.5, 0), Size = dim2(0, 28, 0, 13), BackgroundColor3 = Cfg.Color, Text = "" })
    Lemon:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 8)})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = Lemon:Create("Frame", { Parent = Lemon.Gui, Size = dim2(0, 140, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Lemon:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })

    Items.SVMap = Lemon:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 6, 0, 6), Size = dim2(1, -12, 1, -34), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Lemon:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 8) })
    Items.SVImage = Lemon:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    Lemon:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 8) })
    
    Items.SVKnob = Lemon:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 0, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Lemon:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    Lemon:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0) })

    Items.HueBar = Lemon:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 6, 1, -20), Size = dim2(1, -12, 0, 12), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Lemon:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 8) })
    Lemon:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = Lemon:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 2, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Lemon:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })

    local Open = false

    local function Toggle() 
        Open = not Open
        
        if Open then
            Items.DropFrame.Visible = true
            Lemon:Tween(Items.DropFrame, {Size = dim2(0, 140, 0, 120)}, TweenInfo.new(0.2))
        else
            Lemon:Tween(Items.DropFrame, {Size = dim2(0, 140, 0, 0)}, TweenInfo.new(0.2))
            task.wait(0.2)
            Items.DropFrame.Visible = false
        end
    end
    btn.MouseButton1Click:Connect(Toggle)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local svDragging, hueDragging = false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if Open then Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X - 140 + btn.AbsoluteSize.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 2) end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Keybind Element
function Lemon:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    
    local parentContainer = self.Items.Title or self.Items.Container
    local KeyBtn = Lemon:Create("TextButton", { Parent = parentContainer, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -5, 0.5, 0), Size = dim2(0, 35, 0, 14), BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext, Text = Keys[Cfg.Default] or "None", TextSize = 11, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium) })
    Lemon:Themify(KeyBtn, "element", "BackgroundColor3")
    Lemon:Themify(KeyBtn, "subtext", "TextColor3")
    Lemon:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 8)})

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

-- Notifications
function Notifications:RefreshNotifications()
    local offset = 50
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 36)
        Lemon:Tween(v, {Position = dim_offset(20, offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 10)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Notification"; 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = Lemon:Create("Frame", { Parent = Lemon.Gui; Position = dim_offset(-500, 50); Size = dim2(0, 280, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.background; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true })
    Lemon:Themify(Items.Outline, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 10) })
   
    Items.Name = Lemon:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 12; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Lemon:Themify(Items.Name, "text", "TextColor3")
   
    Lemon:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 8); PaddingBottom = dim(0, 8); PaddingRight = dim(0, 10); PaddingLeft = dim(0, 10); })
   
    Items.TimeBar = Lemon:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 2), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Lemon:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 50)
        Notifications:RefreshNotifications()
        Lemon:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 2)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        Lemon:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.4)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        task.wait(0.05)
        Notifications:RefreshNotifications()
    end)
end

-- Save and load configs
function Lemon:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

function Lemon:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

local ConfigHolder
function Lemon:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(Lemon.Directory .. "/configs") do
        local Name = file:gsub(Lemon.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Lemon.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function Lemon:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "Settings", Icon = "rbxassetid://11293977610", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    Lemon:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Lemon:GetConfig())
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            pcall(function()
                Lemon:LoadConfig(readfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
                Lemon:UpdateConfigList()
                Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
            end)
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Settings"})

    -- Streamer Mode
    SectionRight:Toggle({
        Name = "Streamer Mode",
        Flag = "Lemon_StreamerMode",
        Callback = function(state)
            if state then
                window.Items.Username.Text = "Hidden User"
                window.Items.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48"
            else
                window.Items.Username.Text = lp.Name
                window.Items.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
            end
        end
    })
    
    -- Chat System Toggle
    SectionRight:Toggle({
        Name = "Enable Chat System",
        Default = false,
        Callback = function(state)
            ChatAPI.ChatEnabled = state
            if ChatAPI.ChatBox then
                ChatAPI.ChatBox.Visible = state
            end
            if state then
                Lemon:ConnectChatServer()
                task.spawn(function()
                    while ChatAPI.ChatEnabled do
                        Lemon:UpdateActiveUsers()
                        task.wait(5)
                    end
                end)
            end
        end
    })

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Glow Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("glow", color3) end, Color = themes.preset.glow })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function() 
            if window.Tweening then return end 
            window.ToggleMenu() 
        end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() 
        game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) 
    end})

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then 
                        table.insert(servers, server) 
                    end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then 
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) 
            end
        end
    })
end

return Lemon
