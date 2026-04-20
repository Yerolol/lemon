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
        accent       = rgb(255, 200, 0),     -- Yellow
        glow         = rgb(255, 220, 50),    -- Light Yellow Glow
        
        background   = rgb(15, 15, 15),      -- Almost Black
        section      = rgb(25, 25, 25),      -- Dark Gray
        element      = rgb(35, 35, 35),      -- Slightly Lighter Dark
        
        outline      = rgb(50, 50, 50),      -- Dark Outline
        text         = rgb(255, 255, 255),   -- White Text
        subtext      = rgb(160, 160, 160),   -- Gray Text
        
        tab_active   = rgb(255, 200, 0),     -- Yellow
        tab_inactive = rgb(15, 15, 15),      -- Black
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
    BaseURL = "http://localhost:8000", -- FastAPI server URL
    ActiveUsers = 0,
    Messages = {},
    ChatEnabled = true,
    Connection = nil
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

local function AddSubtleGradient(parent, rotation)
    return Lemon:Create("UIGradient", {
        Parent = parent,
        Rotation = rotation or 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(255, 255, 255)),
            ColorSequenceKeypoint.new(1, rgb(200, 180, 50)) -- Yellowish tint
        })
    })
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
        if ChatAPI.Connection then
            ChatAPI.Connection:Disconnect()
        end
        
        ChatAPI.Connection = game:HttpGetAsync(ChatAPI.BaseURL .. "/connect")
        if ChatAPI.Connection then
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
        
        if self.ChatUI and self.ChatUI.ActiveUsersLabel then
            self.ChatUI.ActiveUsersLabel.Text = "👥 " .. ChatAPI.ActiveUsers .. " Online"
        end
    end)
end

function Lemon:SendChatMessage(message)
    if not ChatAPI.ChatEnabled then return end
    
    pcall(function()
        local data = {
            userId = lp.UserId,
            username = lp.Name,
            message = message,
            timestamp = os.time()
        }
        
        local response = request({
            Url = ChatAPI.BaseURL .. "/send_message",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

function Lemon:CreateChatUI()
    local ChatBox = Lemon:Create("Frame", {
        Parent = self.Gui,
        Position = dim2(0, 10, 0.5, -200),
        Size = dim2(0, 280, 0, 400),
        BackgroundColor3 = themes.preset.background,
        BorderSizePixel = 0,
        ZIndex = 100,
        Visible = false
    })
    Lemon:Create("UICorner", {Parent = ChatBox, CornerRadius = dim(0, 8)})
    Lemon:Themify(Lemon:Create("UIStroke", {Parent = ChatBox, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")
    
    -- Chat Header with Active Users
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
        TextSize = 14,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(Lemon.ChatUI.ActiveUsersLabel, "text", "TextColor3")
    
    -- Chat Messages Container
    local MessagesFrame = Lemon:Create("ScrollingFrame", {
        Parent = ChatBox,
        Position = dim2(0, 0, 0, 40),
        Size = dim2(1, 0, 1, -80),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = dim2(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Themify(MessagesFrame, "element", "ScrollBarImageColor3")
    
    Lemon.ChatUI.MessagesList = Lemon:Create("UIListLayout", {
        Parent = MessagesFrame,
        Padding = dim(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Lemon:Create("UIPadding", {
        Parent = MessagesFrame,
        PaddingLeft = dim(0, 8),
        PaddingRight = dim(0, 8),
        PaddingTop = dim(0, 8)
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
        Size = dim2(1, -70, 0, 30),
        BackgroundColor3 = themes.preset.element,
        Text = "",
        PlaceholderText = "Type a message...",
        TextColor3 = themes.preset.text,
        PlaceholderColor3 = themes.preset.subtext,
        TextSize = 14,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        ClearTextOnFocus = false
    })
    Lemon:Create("UICorner", {Parent = InputBox, CornerRadius = dim(0, 6)})
    Lemon:Themify(InputBox, "element", "BackgroundColor3")
    Lemon:Themify(InputBox, "text", "TextColor3")
    
    local SendButton = Lemon:Create("TextButton", {
        Parent = InputFrame,
        Position = dim2(1, -35, 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 30, 0, 30),
        BackgroundColor3 = themes.preset.accent,
        Text = "➤",
        TextColor3 = rgb(15, 15, 15),
        TextSize = 18,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold)
    })
    Lemon:Create("UICorner", {Parent = SendButton, CornerRadius = dim(0, 6)})
    Lemon:Themify(SendButton, "accent", "BackgroundColor3")
    
    SendButton.MouseButton1Click:Connect(function()
        if InputBox.Text ~= "" then
            Lemon:SendChatMessage(InputBox.Text)
            InputBox.Text = ""
        end
    end)
    
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and InputBox.Text ~= "" then
            Lemon:SendChatMessage(InputBox.Text)
            InputBox.Text = ""
        end
    end)
    
    Lemon.ChatUI.MessagesFrame = MessagesFrame
    Lemon.ChatUI.Box = ChatBox
    
    return ChatBox
end

function Lemon:AddChatMessage(userId, username, message, timestamp)
    if not Lemon.ChatUI or not Lemon.ChatUI.MessagesFrame then return end
    
    -- Check Streamer Mode
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
        Position = dim2(0, 0, 0, 4),
        Size = dim2(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Image = Flags["Lemon_StreamerMode"] and "rbxthumb://type=AvatarHeadShot&id=1&w=48&h=48" or "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=48&h=48"
    })
    Lemon:Create("UICorner", {Parent = Avatar, CornerRadius = dim(0, 12)})
    
    -- Username
    local NameLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(0, 32, 0, 2),
        Size = dim2(1, -32, 0, 16),
        BackgroundTransparency = 1,
        Text = username,
        TextColor3 = themes.preset.accent,
        TextSize = 12,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Lemon:Themify(NameLabel, "accent", "TextColor3")
    
    -- Time
    local TimeLabel = Lemon:Create("TextLabel", {
        Parent = MessageFrame,
        Position = dim2(1, -40, 0, 2),
        AnchorPoint = vec2(1, 0),
        Size = dim2(0, 40, 0, 16),
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
        Position = dim2(0, 32, 0, 20),
        Size = dim2(1, -32, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = themes.preset.text,
        TextSize = 13,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    Lemon:Themify(MessageLabel, "text", "TextColor3")
    
    -- Scroll to bottom
    Lemon.ChatUI.MessagesFrame.CanvasPosition = vec2(0, Lemon.ChatUI.MessagesFrame.CanvasSize.Y.Offset)
end

function Lemon:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = Lemon:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 34, 0, 34),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Lemon:Create("ImageLabel", {
        Parent = Resizing,
        AnchorPoint = vec2(1, 1),
        Position = dim2(1, -4, 1, -4),
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=Asset&id=6153965696&w=150&h=150",
        ImageColor3 = themes.preset.accent,
        ImageTransparency = 0.5
    })
    
    Lemon:Themify(grip, "accent", "ImageColor3")

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(500, 400)
    local MAX_SIZE = vec2(800, 600)

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

-- Window function
function Lemon:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "Lemon", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or ".gg",
        Size = properties.Size or properties.size or dim2(0, 650, 0, 450), 
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
        scaleFactor = 0.85
    elseif deviceType == "Tablet" then
        scaleFactor = 0.9
    end
    
    local windowSize = dim2(0, Cfg.Size.X.Offset * scaleFactor, 0, Cfg.Size.Y.Offset * scaleFactor)

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
        Name = "\0",
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
    Lemon:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) })
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 2 })

    Items.LogoBlock = Lemon:Create("Frame", {
        Parent = Items.Header, 
        AnchorPoint = vec2(0, 0.5), 
        Position = dim2(0, 20, 0.5, 0), 
        Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    Lemon:Create("UICorner", { Parent = Items.LogoBlock, CornerRadius = dim(0, 4) })
    Lemon:Themify(Items.LogoBlock, "accent", "BackgroundColor3")

    Items.LogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 20, 0, 12), 
        Size = dim2(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Lemon:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 20, 0, 26), 
        Size = dim2(0, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Lemon:Themify(Items.SubLogoText, "subtext", "TextColor3")

    Items.PageHolder = Lemon:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 50), Size = dim2(1, 0, 1, -55), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Tab Box in middle bottom
    Items.TabBox = Lemon:Create("Frame", {
        Parent = Items.Window,
        AnchorPoint = vec2(0.5, 1),
        Position = dim2(0.5, 0, 1, -5),
        Size = dim2(0, 0, 0, 45),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = themes.preset.section,
        BorderSizePixel = 0,
        ZIndex = 5
    })
    Lemon:Create("UICorner", { Parent = Items.TabBox, CornerRadius = dim(0, 10) })
    Lemon:Themify(Items.TabBox, "section", "BackgroundColor3")
    Lemon:Themify(Lemon:Create("UIStroke", { Parent = Items.TabBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    -- Tab padding
    local TabPadding = Lemon:Create("UIPadding", {
        Parent = Items.TabBox,
        PaddingLeft = dim(0, 8),
        PaddingRight = dim(0, 8),
        PaddingTop = dim(0, 6),
        PaddingBottom = dim(0, 6)
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
        Padding = dim(0, 8) 
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
            
            -- Move chat box with UI
            if Lemon.ChatUI and Lemon.ChatUI.Box then
                Lemon.ChatUI.Box.Position = dim2(0, 10, 0.5, Items.Wrapper.Position.Y.Offset + 100)
            end
        end
    end)
    Lemon:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
        if Lemon.ChatUI and Lemon.ChatUI.Box then
            Lemon.ChatUI.Box.Visible = uiVisible and ChatAPI.ChatEnabled
        end
    end

    -- Open/Close button with custom icon
    Items.CloseBtn = Lemon:Create("ImageButton", {
        Parent = Items.Window,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, -10, 0, 10),
        Size = dim2(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Image = "rbxassetid://86658474847671",
        ImageColor3 = themes.preset.subtext,
        ZIndex = 10
    })
    Lemon:Themify(Items.CloseBtn, "subtext", "ImageColor3")
    
    Items.CloseBtn.MouseButton1Click:Connect(function()
        Cfg.ToggleMenu(false)
    end)

    if InputService.TouchEnabled then
        Lemon.ToggleGui = Lemon:Create("ScreenGui", { Parent = CoreGui, Name = "LemonToggle", IgnoreGuiInset = true })
        local ToggleButton = Lemon:Create("ImageButton", {
            Name = "ToggleButton", Parent = Lemon.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 55, 0, 55),
            BackgroundTransparency = 0.2, BackgroundColor3 = themes.preset.element, Image = "rbxassetid://86658474847671", ZIndex = 10000,
        })
        Lemon:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 12) })
        Lemon:Themify(ToggleButton, "element", "BackgroundColor3")
        Lemon:Themify(Lemon:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

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

    -- Create Chat UI
    local ChatBox = Lemon:CreateChatUI()
    
    -- Connect to chat server
    Lemon:ConnectChatServer()
    
    -- Periodically update active users
    task.spawn(function()
        while true do
            Lemon:UpdateActiveUsers()
            task.wait(5)
        end
    end)

    return setmetatable(Cfg, Lemon)
end

-- Tab function
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
            Parent = self.Items.TabHolder, Size = dim2(0, 32, 0, 32), 
            BackgroundColor3 = themes.preset.accent,
            BackgroundTransparency = 1, 
            Text = "", AutoButtonColor = false, ZIndex = 7,
            ClipsDescendants = true
        })
        Lemon:Themify(Items.Button, "accent", "BackgroundColor3")
        Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) })
        
        Items.IconImg = Lemon:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 8 
        })
        Lemon:Themify(Items.IconImg, "subtext", "ImageColor3")
        
        Items.TabName = Lemon:Create("TextLabel", {
            Parent = Items.Button,
            Position = dim2(0.5, 0, 0.5, 0),
            AnchorPoint = vec2(0.5, 0.5),
            Size = dim2(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = Cfg.Name,
            TextColor3 = themes.preset.text,
            TextSize = 12,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
            TextTransparency = 1,
            Visible = false,
            ZIndex = 8
        })
        Lemon:Themify(Items.TabName, "text", "TextColor3")
    end

    Items.Pages = Lemon:Create("CanvasGroup", { Parent = Lemon.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Lemon:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 10), PaddingBottom = dim(0, 10), PaddingRight = dim(0, 20), PaddingLeft = dim(0, 20) })

    Items.Left = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 10) })

    Items.Right = Lemon:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Lemon:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 14) })
    Lemon:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 10) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            Lemon:Tween(oldTab.Button, {BackgroundTransparency = 1, Size = dim2(0, 32, 0, 32)}, buttonTween)
            Lemon:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
            if oldTab.TabName then
                oldTab.TabName.Visible = false
            end
        end

        if Items.Button then 
            Lemon:Tween(Items.Button, {BackgroundTransparency = 0, Size = dim2(0, 100, 0, 32)}, buttonTween)
            Lemon:Tween(Items.IconImg, {ImageColor3 = rgb(15, 15, 15)}, buttonTween)
            Items.TabName.Visible = true
            Lemon:Tween(Items.TabName, {TextTransparency = 0}, buttonTween)
        end
        
        task.spawn(function()
            if oldTab then
                Lemon:Tween(oldTab.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 10)}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Lemon.Other
            end

            Items.Pages.Position = dim2(0, 0, 0, 10) 
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

-- Section function
function Lemon:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        RightIcon = properties.RightIcon or properties.righticon or "rbxassetid://12338898398",
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Lemon:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Lemon:Themify(Items.Section, "section", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 6) })
    
    Items.AccentLine = Lemon:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 3, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })
    Lemon:Themify(Items.AccentLine, "accent", "BackgroundColor3")

    Items.Header = Lemon:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    
    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 14, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -46, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "text", "TextColor3")

    Items.Chevron = Lemon:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(1, -14, 0.5, 0), AnchorPoint = vec2(1, 0.5), Size = dim2(0, 12, 0, 12),
        BackgroundTransparency = 1, Image = Cfg.RightIcon, ImageColor3 = themes.preset.subtext, 
        Rotation = 0
    })
    Lemon:Themify(Items.Chevron, "subtext", "ImageColor3")

    Items.Container = Lemon:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 36), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Lemon:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    Lemon:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 12), PaddingLeft = dim(0, 14), PaddingRight = dim(0, 14) })

    return setmetatable(Cfg, Lemon)
end

-- Elements (Toggle, Button, Slider, Textbox, Dropdown, Label, Colorpicker, Keybind)
-- [All element functions remain the same, just replace "Pulse" with "Lemon" and adjust colors]

function Lemon:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 22), BackgroundTransparency = 1, Text = "" })
    
    Items.Checkbox = Lemon:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 6, 0.5, 0), Size = dim2(0, 14, 0, 14), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Lemon:Themify(Items.Checkbox, "element", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Checkbox, CornerRadius = dim(0, 3) })

    Items.CheckFill = Lemon:Create("Frame", {
        Parent = Items.Checkbox, Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0,
        BackgroundTransparency = 1
    })
    Lemon:Themify(Items.CheckFill, "accent", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.CheckFill, CornerRadius = dim(0, 3) })

    Items.Title = Lemon:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 30, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -26, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Lemon:Themify(Items.Title, "subtext", "TextColor3")

    local State = false
    function Cfg.set(bool)
        State = bool
        Lemon:Tween(Items.CheckFill, {BackgroundTransparency = State and 0 or 1}, TweenInfo.new(0.2))
        Lemon:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.2))
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Lemon)
end

function Lemon:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Lemon:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 30), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Lemon:Themify(Items.Button, "element", "BackgroundColor3")
    Lemon:Themify(Items.Button, "subtext", "TextColor3")
    Lemon:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 4) })

    Items.Button.MouseButton1Click:Connect(function()
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.outline, TextColor3 = themes.preset.text}, TweenInfo.new(0.1))
        task.wait(0.1)
        Lemon:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Lemon)
end

-- [Include all other element functions: Slider, Textbox, Dropdown, Label, Colorpicker, Keybind]
-- [Copy them from the original but replace "Pulse" with "Lemon"]

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
   
    Items.Outline = Lemon:Create("Frame", { Parent = Lemon.Gui; Position = dim_offset(-500, 50); Size = dim2(0, 300, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.background; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true })
    Lemon:Themify(Items.Outline, "background", "BackgroundColor3")
    Lemon:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 4) })
   
    Items.Name = Lemon:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Lemon:Themify(Items.Name, "text", "TextColor3")
   
    Lemon:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 10); PaddingBottom = dim(0, 10); PaddingRight = dim(0, 12); PaddingLeft = dim(0, 12); })
   
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

    local Tab = window:Tab({ Name = "", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left"})

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
            Lemon:LoadConfig(readfile(Lemon.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Lemon:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
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

    local SectionRight = Tab:Section({Name = "Settings", Side = "Right"})

    -- Streamer Mode
    SectionRight:Toggle({
        Name = "Streamer Mode",
        Flag = "Lemon_StreamerMode",
        Callback = function(state)
            -- Hide all usernames
        end
    })
    
    -- Chat System Toggle
    SectionRight:Toggle({
        Name = "Enable Chat System",
        Default = true,
        Callback = function(state)
            ChatAPI.ChatEnabled = state
            if Lemon.ChatUI and Lemon.ChatUI.Box then
                Lemon.ChatUI.Box.Visible = state and window.Items.Wrapper.Visible
            end
            if state then
                Lemon:ConnectChatServer()
            end
        end
    })

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Glow Color"}):Colorpicker({ Callback = function(color3) Lemon:RefreshTheme("glow", color3) end, Color = themes.preset.glow })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })
end

return Lemon
