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
    BaseURL = "http://212.132.99.151:9611",
    ActiveUsers = 0,
    Messages = {},
    ChatEnabled = true,
    Connection = nil,
    ChatBox = nil,
    ChatVisible = false
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

function Lemon:ConnectChatServer()
    pcall(function()
        local response = game:HttpGet(ChatAPI.BaseURL .. "/connect")
        print("[Lemon] Connected to chat server")
        self:UpdateActiveUsers()
    end)
end

function Lemon:UpdateActiveUsers()
    pcall(function()
        local response = game:HttpGet(ChatAPI.BaseURL .. "/active_users")
        local data = HttpService:JSONDecode(response)
        ChatAPI.ActiveUsers = data.count or 0
        
        if self.ChatUI and self.ChatUI.ActiveUsersLabel then
            self.ChatUI.ActiveUsersLabel.Text = "👥 " .. ChatAPI.ActiveUsers
        end
    end)
end

function Lemon:SendChatMessage(message)
    if not ChatAPI.ChatEnabled then return end
    if message == "" then return end
    
    pcall(function()
        local data = {
            userId = lp.UserId,
            username = lp.Name,
            message = message,
            timestamp = os.time()
        }
        
        request({
            Url = ChatAPI.BaseURL .. "/send_message",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
        
        self:AddChatMessage(lp.UserId, lp.Name, message, os.time())
    end)
end

function Lemon:CreateChatUI()
    local ChatBox = Lemon:Create("Frame", {
        Parent = Lemon.Gui,
        Position = dim2(0, 10, 0.5, -150),
        Size = dim2(0, 260, 0, 350),
        BackgroundColor3 = themes.preset.background,
        BorderSizePixel = 0,
        ZIndex = 100,
        Visible = false
    })
    Lemon:Create("UICorner", {Parent = ChatBox, CornerRadius = dim(0, 8)})
    Lemon:Themify(Lemon:Create("UIStroke", {Parent = ChatBox, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")
    
    -- Header
    local Header = Lemon:Create("Frame", {
        Parent = ChatBox,
        Size = dim2(1, 0, 0, 35),
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
        Text = "👥 0",
        TextColor3 = themes.preset.accent,
        TextSize = 12,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Close button
    local CloseBtn = Lemon:Create("TextButton", {
        Parent = Header,
        Position = dim2(1, -10, 0.5, 0),
        AnchorPoint = vec2(1, 0.5),
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = themes.preset.subtext,
        TextSize = 14
    })
    CloseBtn.MouseButton1Click:Connect(function()
        ChatAPI.ChatVisible = false
        ChatBox.Visible = false
    end)
    
    -- Messages
    local MessagesFrame = Lemon:Create("ScrollingFrame", {
        Parent = ChatBox,
        Position = dim2(0, 0, 0, 35),
        Size = dim2(1, 0, 1, -70),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        CanvasSize = dim2(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Themify(MessagesFrame, "accent", "ScrollBarImageColor3")
    
    Lemon.ChatUI.MessagesList = Lemon:Create("UIListLayout", {
        Parent = MessagesFrame,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Lemon:Create("UIPadding", {
        Parent = MessagesFrame,
        PaddingLeft = dim(0, 8),
        PaddingRight = dim(0, 8),
        PaddingTop = dim(0, 8)
    })
    
    -- Input
    local InputFrame = Lemon:Create("Frame", {
        Parent = ChatBox,
        Position = dim2(0, 0, 1, -35),
        Size = dim2(1, 0, 0, 35),
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0
    })
    
    local InputBox = Lemon:Create("TextBox", {
        Parent = InputFrame,
        Position = dim2(0, 6, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(1, -45, 0, 26),
        BackgroundColor3 = themes.preset.element,
        Text = "",
        PlaceholderText = "Message...",
        TextColor3 = themes.preset.text,
        PlaceholderColor3 = themes.preset.subtext,
        TextSize = 12,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        ClearTextOnFocus = false
    })
    Lemon:Create("UICorner", {Parent = InputBox, CornerRadius = dim(0, 5)})
    
    local SendButton = Lemon:Create("TextButton", {
        Parent = InputFrame,
        Position = dim2(1, -32, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 26, 0, 26),
        BackgroundColor3 = themes.preset.accent,
        Text = "➤",
        TextColor3 = rgb(15, 15, 15),
        TextSize = 16
    })
    Lemon:Create("UICorner", {Parent = SendButton, CornerRadius = dim(0, 5)})
    
    SendButton.MouseButton1Click:Connect(function()
        Lemon:SendChatMessage(InputBox.Text)
        InputBox.Text = ""
    end)
    
    InputBox.FocusLost:Connect(function(enter)
        if enter then
            Lemon:SendChatMessage(InputBox.Text)
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
        username = "Hidden"
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
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = Flags["Lemon_StreamerMode"] and "rbxthumb://type=AvatarHeadShot&id=1&w=40&h=40" or "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=40&h=40"
    })
    Lemon:Create("UICorner", {Parent = Avatar, CornerRadius = dim(0, 10)})
    
    -- Username and Time
    local NameLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 28, 0, 0),
        Size = dim2(0, 0, 0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = username,
        TextColor3 = themes.preset.accent,
        TextSize = 11,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local TimeLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 28, 0, 0),
        Size = dim2(0, 35, 0, 14),
        BackgroundTransparency = 1,
        Text = os.date("%H:%M", timestamp),
        TextColor3 = themes.preset.subtext,
        TextSize = 9,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Right
    })
    TimeLabel.Position = dim2(1, -35, 0, 0)
    
    -- Message
    local MessageLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 28, 0, 16),
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = themes.preset.text,
        TextSize = 11,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    
    Lemon.ChatUI.MessagesFrame.CanvasPosition = vec2(0, Lemon.ChatUI.MessagesFrame.CanvasSize.Y.Offset)
end

function Lemon:ToggleChat()
    ChatAPI.ChatVisible = not ChatAPI.ChatVisible
    if ChatAPI.ChatBox then
        ChatAPI.ChatBox.Visible = ChatAPI.ChatVisible
    end
end

function Lemon:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = Lemon:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 25, 0, 25),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Lemon:Create("ImageLabel", {
        Parent = Resizing,
        AnchorPoint = vec2(1, 1),
        Position = dim2(1, -2, 1, -2),
        Size = dim2(0, 15, 0, 15),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=6153965696&w=150&h=150",
        ImageColor3 = themes.preset.accent,
        ImageTransparency = 0.3
    })

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(480, 350)
    local MAX_SIZE = vec2(700, 550)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true
            StartInputPos = input.Position
            StartSize = Parent.AbsoluteSize
        end
    end)

    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(
                math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X),
                math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)
            )
        end
    end)
end

function Lemon:Slider(properties)
    local Cfg = { 
        Name = properties.Name or "Slider", 
        Flag = properties.Flag, 
        Min = properties.Min or 0, 
        Max = properties.Max or 100, 
        Default = properties.Default or 0, 
        Increment = properties.Increment or 1, 
        Suffix = properties.Suffix or "", 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 38), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 18), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Items.Val = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 18), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

    Items.Track = Lemon:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 2, 0, 22), Size = dim2(1, -6, 0, 5), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Lemon:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })

    Items.Fill = Lemon:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Lemon:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    Items.Knob = Lemon:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 10, 0, 10), BackgroundColor3 = themes.preset.accent })
    Lemon:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })

    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        Lemon:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.1))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = true
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

function Lemon:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or "", 
        Placeholder = properties.Placeholder or "Enter text...", 
        Default = properties.Default or "", 
        Flag = properties.Flag, 
        Numeric = properties.Numeric or false, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 30), BackgroundTransparency = 1 })
    Items.Bg = Lemon:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Lemon:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 4) })

    Items.Input = Lemon:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })

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

function Lemon:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or "Dropdown", 
        Flag = properties.Flag, 
        Options = properties.Options or {}, 
        Default = properties.Default, 
        Callback = properties.Callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Lemon:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 42), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 16), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })

    Items.Main = Lemon:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 18), Size = dim2(1, 0, 0, 24), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Lemon:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 4) })

    Items.SelectedText = Lemon:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 1, 0), BackgroundTransparency = 1, Text = Cfg.Default or "Select...", TextColor3 = themes.preset.subtext, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    
    Items.Icon = Lemon:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -18, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 10, 0, 10), BackgroundTransparency = 1, Image = "rbxassetid://12338898398", ImageColor3 = themes.preset.subtext })

    Items.DropFrame = Lemon:Create("Frame", { 
        Parent = Lemon.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })

    Items.Scroll = Lemon:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, 0), 
        BackgroundTransparency = 1, ScrollBarThickness = 2, BorderSizePixel = 0, ZIndex = 201 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false
    local OptionBtns = {}

    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, data in ipairs(OptionBtns) do data.btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = Lemon:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 22), BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 12, 
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202
            })
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, {btn = btn, text = tostring(opt)})
        end
        Items.Scroll.CanvasSize = dim2(0, 0, 0, #Cfg.Options * 22)
    end

    local function ToggleDropdown()
        if isTweening then return end
        isTweening = true
        Open = not Open
        
        if Open then
            Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 2)
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            Items.DropFrame.Visible = true
            local targetHeight = math.clamp(#Cfg.Options * 22, 22, 150)
            Lemon:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.2))
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.2))
            tw.Completed:Wait()
        else
            Lemon:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.2))
            local tw = Lemon:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.2))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and Open and not isTweening then
            local mx, my = input.Position.X, input.Position.Y
            local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
            local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
            if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
               not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                ToggleDropdown()
            end
        end
    end)

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

function Lemon:Label(properties)
    local Cfg = { Name = properties.Name or "Label", Wrapped = properties.Wrapped or false, Items = {} }
    local Items = Cfg.Items
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 24 or 16), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Lemon)
end

function Lemon:Colorpicker(properties)
    local Cfg = { Color = properties.Color or rgb(255, 255, 255), Callback = properties.Callback or function() end, Flag = properties.Flag, Items = {} }
    local Items = Cfg.Items
    local btn = Lemon:Create("TextButton", { Parent = self.Items.Title or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -4, 0.5, 0), Size = dim2(0, 28, 0, 12), BackgroundColor3 = Cfg.Color, Text = "" })
    Lemon:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 3)})
    
    local h, s, v = Color3.toHSV(Cfg.Color)
    Items.DropFrame = Lemon:Create("Frame", { Parent = Lemon.Gui, Size = dim2(0, 140, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Lemon:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })
    
    Items.SVMap = Lemon:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 6, 0, 6), Size = dim2(1, -12, 1, -34), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Lemon:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 3) })
    Items.SVImage = Lemon:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, ZIndex = 202 })
    Items.SVKnob = Lemon:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 0, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Lemon:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    
    Items.HueBar = Lemon:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 6, 1, -20), Size = dim2(1, -12, 0, 12), AutoButtonColor = false, Text = "", BackgroundColor3 = rgb(255,255,255), ZIndex = 201 })
    Lemon:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 3) })
    Lemon:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    Items.HueKnob = Lemon:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 2, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })

    local Open, isTweening = false, false
    local function Toggle() 
        if isTweening then return end
        Open = not Open; isTweening = true
        if Open then
            Items.DropFrame.Visible = true
            Lemon:Tween(Items.DropFrame, {Size = dim2(0, 140, 0, 120)}, TweenInfo.new(0.2)):Wait()
        else
            Lemon:Tween(Items.DropFrame, {Size = dim2(0, 140, 0, 0)}, TweenInfo.new(0.2)):Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    function Cfg.set(color3)
        Cfg.Color = color3; btn.BackgroundColor3 = color3
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
                s, v = x, 1 - y; Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x; Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

function Lemon:Keybind(properties)
    local Cfg = { Name = properties.Name or "Keybind", Flag = properties.Flag, Default = properties.Default or Enum.KeyCode.Unknown, Callback = properties.Callback or function() end, Items = {} }
    local KeyBtn = Lemon:Create("TextButton", { Parent = self.Items.Title or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -4, 0.5, 0), Size = dim2(0, 35, 0, 14), BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext, Text = Keys[Cfg.Default] or "None", TextSize = 11 })
    Lemon:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 3)})
    
    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    InputService.InputBegan:Connect(function(input, gp)
        if gp and not binding then return end
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
        KeyBtn.Text = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

function Notifications:RefreshNotifications()
    local offset = 50
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 30)
        Lemon:Tween(v, {Position = dim_offset(15, offset)}, TweenInfo.new(0.3))
        offset += (ySize + 8)
    end
end

function Notifications:Create(properties)
    local Cfg = { Name = properties.Name or "Notification", Lifetime = properties.LifeTime or 2, Items = {} }
    local Items = Cfg.Items
    Items.Outline = Lemon:Create("Frame", { Parent = Lemon.Gui, Position = dim_offset(-300, 50), Size = dim2(0, 250, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 300 })
    Lemon:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 4) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Outline, Color = themes.preset.accent, Thickness = 1 }), "accent", "Color")
    Items.Name = Lemon:Create("TextLabel", { Parent = Items.Outline, Text = Cfg.Name, TextColor3 = themes.preset.text, BackgroundTransparency = 1, Size = dim2(1, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 302 })
    Lemon:Create("UIPadding", { Parent = Items.Name, PaddingTop = dim(0, 8), PaddingBottom = dim(0, 8), PaddingRight = dim(0, 10), PaddingLeft = dim(0, 10) })
    table.insert(Notifications.Notifs, Items.Outline)
    
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 50)
        Notifications:RefreshNotifications()
        task.wait(Cfg.Lifetime)
        Lemon:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.3))
        task.wait(0.3)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        Notifications:RefreshNotifications()
    end)
end

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

function Lemon:UpdateConfigList(ConfigHolder, Text)
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(Lemon.Directory .. "/configs") do
        local Name = file:gsub(Lemon.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Lemon.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function Lemon:Window(properties)
    local Cfg = {
        Title = properties.Title or "Lemon", 
        Subtitle = properties.Subtitle or ".gg",
        Size = properties.Size or dim2(0, 520, 0, 380), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false
    }

    if Lemon.Gui then Lemon.Gui:Destroy() end
    if Lemon.Other then Lemon.Other:Destroy() end
    if Lemon.ToggleGui then Lemon.ToggleGui:Destroy() end

    Lemon.Gui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonGG", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Lemon.Other = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true
    
    local deviceType = Lemon:GetDeviceType()
    local scaleFactor = deviceType == "Mobile" and 0.8 or (deviceType == "Tablet" and 0.88 or 1)
    local windowSize = dim2(0, Cfg.Size.X.Offset * scaleFactor, 0, Cfg.Size.Y.Offset * scaleFactor)

    Items.Wrapper = Lemon:Create("Frame", {
        Parent = Lemon.Gui, Position = dim2(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
        Size = windowSize, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    Items.Glow = Lemon:Create("ImageLabel", {
        ImageColor3 = themes.preset.glow, ScaleType = Enum.ScaleType.Slice, ImageTransparency = 0.65,
        Parent = Items.Wrapper, Size = dim2(1, 40, 1, 40), Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1, Position = dim2(0, -20, 0, -20), ZIndex = 0,
        SliceCenter = rect(vec2(21, 21), vec2(79, 79))
    })

    Items.Window = Lemon:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Lemon:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

    -- Header
    Items.Header = Lemon:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 40), BackgroundTransparency = 1, Active = true, ZIndex = 2 })
    
    Items.LogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.accent,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), 
        Size = dim2(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    
    Items.SubLogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), 
        Size = dim2(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Items.SubLogoText.Position = dim2(0, Items.LogoText.AbsoluteSize.X + 20, 0.5, 0)

    -- Settings Button (Top Right)
    Items.SettingsBtn = Lemon:Create("ImageButton", {
        Parent = Items.Header,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -40, 0.5, 0),
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11293977610",
        ImageColor3 = themes.preset.subtext,
        ZIndex = 5
    })
    
    -- Close Button
    Items.CloseBtn = Lemon:Create("ImageButton", {
        Parent = Items.Header,
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -12, 0.5, 0),
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://86658474847671",
        ImageColor3 = themes.preset.subtext,
        ZIndex = 5
    })
    Items.CloseBtn.MouseButton1Click:Connect(function() Cfg.ToggleMenu(false) end)

    -- Page Holder
    Items.PageHolder = Lemon:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 40), Size = dim2(1, 0, 1, -50), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Tab Box (Outside UI at bottom)
    Items.TabBox = Lemon:Create("Frame", {
        Parent = Lemon.Gui,
        AnchorPoint = vec2(0.5, 1),
        Position = dim2(0.5, 0, 1, -10),
        Size = dim2(0, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    Lemon:Create("UICorner", { Parent = Items.TabBox, CornerRadius = dim(0, 10) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.TabBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Lemon:Create("UIPadding", { Parent = Items.TabBox, PaddingLeft = dim(0, 8), PaddingRight = dim(0, 8), PaddingTop = dim(0, 5), PaddingBottom = dim(0, 5) })
    
    Items.TabHolder = Lemon:Create("Frame", { 
        Parent = Items.TabBox, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 6
    })
    Lemon:Create("UIListLayout", { 
        Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Horizontal, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 6) 
    })

    -- Dragging
    local Dragging, DragStart, StartPos
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
            Items.TabBox.Position = dim2(0.5, 0, 1, Items.Wrapper.Position.Y.Offset + windowSize.Y.Offset + 5)
        end
    end)
    
    Lemon:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        uiVisible = (bool == nil) and not uiVisible or bool
        Items.Wrapper.Visible = uiVisible
        Items.TabBox.Visible = uiVisible
        if ChatAPI.ChatBox then
            ChatAPI.ChatBox.Visible = uiVisible and ChatAPI.ChatVisible
        end
    end

    -- Chat button in settings
    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    -- Create Chat UI
    Lemon:CreateChatUI()
    Lemon:ConnectChatServer()
    
    task.spawn(function()
        while true do
            Lemon:UpdateActiveUsers()
            task.wait(5)
        end
    end)

    -- Touch toggle
    if InputService.TouchEnabled then
        Lemon.ToggleGui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonToggle", IgnoreGuiInset = true })
        local ToggleButton = Lemon:Create("ImageButton", {
            Name = "ToggleButton", Parent = Lemon.ToggleGui, Position = UDim2.new(1, -70, 0, 150), Size = UDim2.new(0, 45, 0, 45),
            BackgroundColor3 = themes.preset.element, Image = "rbxassetid://86658474847671", ZIndex = 10000,
        })
        Lemon:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 10) })
        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, Lemon)
end

function Lemon:Tab(properties)
    local Cfg = { Name = properties.Name or "Tab", Icon = properties.Icon or "rbxassetid://11293977610", Hidden = properties.Hidden or false, Items = {} }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        Items.Button = Lemon:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 30, 0, 30), 
            BackgroundColor3 = themes.preset.accent, BackgroundTransparency = 1, 
            Text = "", AutoButtonColor = false, ZIndex = 7, ClipsDescendants = true
        })
        Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 7) })
        
        Items.IconImg = Lemon:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 8 
        })
        
        Items.TabName = Lemon:Create("TextLabel", {
            Parent = Items.Button, Position = dim2(0.5, 0, 0.5, 0), AnchorPoint = vec2(0.5, 0.5),
            Size = dim2(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 11,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
            TextTransparency = 1, Visible = false, ZIndex = 8
        })
    end

    Items.Pages = Lemon:Create("CanvasGroup", { Parent = Lemon.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Lemon:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 12) })
    Lemon:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 8), PaddingBottom = dim(0, 8), PaddingRight = dim(0, 15), PaddingLeft = dim(0, 15) })

    Items.Left = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 12) })

    Items.Right = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -6, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 12) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        if oldTab and oldTab.Button then
            Lemon:Tween(oldTab.Button, {BackgroundTransparency = 1, Size = dim2(0, 30, 0, 30)}, TweenInfo.new(0.2))
            Lemon:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
            if oldTab.TabName then oldTab.TabName.Visible = false end
        end

        if Items.Button then 
            Lemon:Tween(Items.Button, {BackgroundTransparency = 0, Size = dim2(0, 85, 0, 30)}, TweenInfo.new(0.2))
            Lemon:Tween(Items.IconImg, {ImageColor3 = rgb(15, 15, 15)}, TweenInfo.new(0.2))
            Items.TabName.Visible = true
            Lemon:Tween(Items.TabName, {TextTransparency = 0}, TweenInfo.new(0.2))
        end
        
        task.spawn(function()
            if oldTab then
                Lemon:Tween(oldTab.Pages, {GroupTransparency = 1}, TweenInfo.new(0.15))
                task.wait(0.15)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Lemon.Other
            end
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true
            Lemon:Tween(Items.Pages, {GroupTransparency = 0}, TweenInfo.new(0.25))
            task.wait(0.25)
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Lemon)
end

function Lemon:Section(properties)
    local Cfg = { Name = properties.Name or "Section", Side = properties.Side or "Left", Items = {} }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Lemon:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Lemon:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 5) })
    
    Items.AccentLine = Lemon:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 2, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })

    Items.Header = Lemon:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 30), BackgroundTransparency = 1 })
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 12, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -24, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left 
    })

    Items.Container = Lemon:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 30), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 10), PaddingLeft = dim(0, 12), PaddingRight = dim(0, 12) })

    return setmetatable(Cfg, Lemon)
end

function Lemon:Toggle(properties)
    local Cfg = { Name = properties.Name or "Toggle", Flag = properties.Flag, Default = properties.Default or false, Callback = properties.Callback or function() end, Items = {} }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = "" })
    Items.Checkbox = Lemon:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 4, 0.5, 0), Size = dim2(0, 12, 0, 12), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Lemon:Create("UICorner", { Parent = Items.Checkbox, CornerRadius = dim(0, 3) })
    Items.CheckFill = Lemon:Create("Frame", {
        Parent = Items.Checkbox, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.accent, 
        BorderSizePixel = 0, BackgroundTransparency = 1
    })
    Lemon:Create("UICorner", { Parent = Items.CheckFill, CornerRadius = dim(0, 3) })
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 24, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -24, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })

    local State = false
    function Cfg.set(bool)
        State = bool
        Lemon:Tween(Items.CheckFill, {BackgroundTransparency = State and 0 or 1}, TweenInfo.new(0.15))
        Lemon:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.15))
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Lemon)
end

function Lemon:Button(properties)
    local Cfg = { Name = properties.Name or "Button", Callback = properties.Callback or function() end, Items = {} }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 28), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 4) })
    Items.Button.MouseButton1Click:Connect(function()
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.accent, TextColor3 = rgb(15,15,15)}, TweenInfo.new(0.1))
        task.wait(0.1)
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.15))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Lemon)
end

function Lemon:Configs(window)
    local ConfigHolder, Text
    local Tab = window:Tab({ Name = "", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left"})
    ConfigHolder = Section:Dropdown({ Name = "Configs", Options = {}, Flag = "config_Name_list" })
    Text = Section:Textbox({ Name = "Name", Flag = "config_Name_text", Default = "" })
    
    Lemon.UpdateConfigList = function()
        local List = {}
        for _, file in listfiles(Lemon.Directory .. "/configs") do
            local Name = file:gsub(Lemon.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Lemon.Directory .. "\\configs\\", "")
            List[#List + 1] = Name
        end
        if ConfigHolder then ConfigHolder.RefreshOptions(List) end
    end
    Lemon:UpdateConfigList()

    Section:Button({ Name = "Save", Callback = function()
        if Flags["config_Name_text"] == "" then return end
        writefile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Lemon:GetConfig())
        Lemon:UpdateConfigList()
        Notifications:Create({Name = "Saved: " .. Flags["config_Name_text"]})
    end})
    
    Section:Button({ Name = "Load", Callback = function()
        if Flags["config_Name_text"] == "" then return end
        Lemon:LoadConfig(readfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
        Notifications:Create({Name = "Loaded: " .. Flags["config_Name_text"]})
    end})
    
    Section:Button({ Name = "Delete", Callback = function()
        if Flags["config_Name_text"] == "" then return end
        delfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
        Lemon:UpdateConfigList()
        Notifications:Create({Name = "Deleted: " .. Flags["config_Name_text"]})
    end})

    local SectionRight = Tab:Section({Name = "Settings", Side = "Right"})
    
    SectionRight:Toggle({
        Name = "Streamer Mode",
        Flag = "Lemon_StreamerMode",
        Callback = function(state) end
    })
    
    SectionRight:Toggle({
        Name = "Chat System",
        Default = true,
        Callback = function(state)
            ChatAPI.ChatEnabled = state
            if not state and ChatAPI.ChatBox then
                ChatAPI.ChatBox.Visible = false
                ChatAPI.ChatVisible = false
            end
        end
    })
    
    SectionRight:Button({
        Name = "Toggle Chat Box",
        Callback = function()
            Lemon:ToggleChat()
        end
    })

    SectionRight:Label({Name = "Accent"}):Colorpicker({ Callback = function(c) Lemon:RefreshTheme("accent", c) end, Color = themes.preset.accent })
    
    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Callback = function() if not window.Tweening then window.ToggleMenu() end end,
        Default = Enum.KeyCode.RightShift
    })
    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right"})
    ServerSection:Button({ Name = "Rejoin", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, lp) end })
    ServerSection:Button({ Name = "Server Hop", Callback = function()
        local servers, cursor = {}, ""
        repeat
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
            local data = HttpService:JSONDecode(game:HttpGet(url))
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
            end
            cursor = data.nextPageCursor
        until not cursor or #servers > 0
        if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, lp) end
    end})
end

return Lemon
