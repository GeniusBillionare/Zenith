--[[
    ZENITH CLIENT  |  LocalScript -> StarterPlayer > StarterPlayerScripts
    ClickGUI style dropdown menu.

    RightShift         open / close menu (changeable in Settings > GUI)
    Left click module  toggle it (Action modules run, Settings-tab entries expand)
    Right click module drop down its settings + keybind
    Drag panel header  move panel      |  Right click header: collapse panel
    Search bar         Ctrl+F or click it. Enter toggles the top result
]]

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Lighting        = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Stats           = game:GetService("Stats")
local TextService     = game:GetService("TextService")
local GuiService      = game:GetService("GuiService")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()
local PG     = LP:WaitForChild("PlayerGui")

do
local oldGui = PG:FindFirstChild("ZenithClient"); if oldGui then oldGui:Destroy() end
end
do
local oldGui2 = PG:FindFirstChild("AerovoltClient"); if oldGui2 then oldGui2:Destroy() end
end
do
local oldBlur2 = Lighting:FindFirstChild("AerovoltBlur"); if oldBlur2 then oldBlur2:Destroy() end
end
pcall(function() RunService:UnbindFromRenderStep("AerovoltRender") end)
do
local oldBlur = Lighting:FindFirstChild("ZenithBlur"); if oldBlur then oldBlur:Destroy() end
end
pcall(function() RunService:UnbindFromRenderStep("ZenithRender") end)

local CLIENT, VERSION = "ZENITH", "v3.0"
local FONT, FONT_B = Enum.Font.GothamMedium, Enum.Font.GothamBold

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------
local Conns = {}
local function Conn(sig, fn) local c = sig:Connect(fn); table.insert(Conns, c); return c end
local function Safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[Zenith] " .. tostring(err)) end
end
local function Hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function Root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Typing() return UIS:GetFocusedTextBox() ~= nil end
local function Down(k) return UIS:IsKeyDown(k) and not Typing() end
local function RayParams()
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = { LP.Character }
	return p
end
local function New(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function Fmt(v) return string.format("%g", v) end
local function B255(x) return math.floor(x * 255 + 0.5) end
local function Rgb(c) return string.format("rgb(%d,%d,%d)", B255(c.R), B255(c.G), B255(c.B)) end

----------------------------------------------------------------------
-- theme + painters (anything that depends on accent / state)
----------------------------------------------------------------------
local Themes = {
	Purple = Color3.fromRGB(160, 90, 255), Blue = Color3.fromRGB(70, 130, 255),
	Cyan = Color3.fromRGB(0, 200, 215),    Green = Color3.fromRGB(70, 215, 110),
	Red = Color3.fromRGB(255, 70, 80),     Orange = Color3.fromRGB(255, 150, 50),
	Pink = Color3.fromRGB(255, 100, 200),  Rainbow = Color3.new(1, 1, 1),
	Teal = Color3.fromRGB(0, 180, 170),    Lime = Color3.fromRGB(170, 230, 50),
	Yellow = Color3.fromRGB(250, 220, 60), Magenta = Color3.fromRGB(230, 50, 200),
	Indigo = Color3.fromRGB(90, 80, 230),  Coral = Color3.fromRGB(255, 115, 95),
	Sky = Color3.fromRGB(110, 190, 255),   Snow = Color3.fromRGB(235, 235, 245),
}
-- animated themes: the accent drifts through these colors. one "Theme Speed" slider drives all of them
local function RGBs(...) local t = {} for _, c in ipairs({ ... }) do t[#t + 1] = Color3.fromRGB(c[1], c[2], c[3]) end return t end
Themes.G = {
	Astral = RGBs({150, 85, 255}, {70, 125, 255}, {0, 205, 235}, {55, 235, 170}),
	Ocean = RGBs({0, 119, 255}, {0, 198, 255}, {0, 255, 208}),
	Sunset = RGBs({255, 94, 98}, {255, 153, 102}, {255, 209, 102}, {240, 101, 149}),
	Ember = RGBs({255, 61, 0}, {255, 143, 0}, {255, 213, 79}),
	Forest = RGBs({27, 158, 90}, {123, 216, 143}, {46, 196, 182}),
	Sakura = RGBs({255, 158, 199}, {255, 200, 221}, {199, 125, 255}),
	Ice = RGBs({160, 233, 255}, {111, 177, 255}, {224, 247, 255}),
	Toxic = RGBs({182, 255, 0}, {0, 230, 118}, {57, 255, 20}),
	Vaporwave = RGBs({255, 113, 206}, {185, 103, 255}, {1, 205, 254}, {5, 255, 161}),
	Galaxy = RGBs({125, 70, 210}, {117, 151, 222}, {196, 113, 237}, {18, 194, 233}),
	Gold = RGBs({249, 212, 35}, {255, 154, 0}, {255, 241, 168}),
	Mint = RGBs({127, 255, 212}, {62, 224, 176}, {184, 255, 233}),
	Crimson = RGBs({200, 20, 40}, {255, 23, 68}, {255, 97, 111}),
	Lavender = RGBs({179, 157, 219}, {149, 117, 205}, {225, 190, 231}),
	Neon = RGBs({255, 0, 255}, {0, 255, 255}),
	Candy = RGBs({255, 154, 158}, {250, 208, 196}, {161, 140, 209}),
	Twilight = RGBs({106, 130, 251}, {252, 92, 125}),
	Peach = RGBs({255, 184, 140}, {255, 126, 95}),
	Mojito = RGBs({29, 151, 108}, {147, 249, 185}),
	Monochrome = RGBs({255, 255, 255}, {150, 150, 160}, {90, 90, 100}),
}
Themes.Speed = 0.2
local ThemeOrder = { "Purple", "Blue", "Cyan", "Green", "Red", "Orange", "Pink", "Teal", "Lime", "Yellow", "Magenta", "Indigo", "Coral", "Sky", "Snow" }
do
	local gs = {}
	for n, st in pairs(Themes.G) do Themes[n] = st[1]; gs[#gs + 1] = n end
	table.sort(gs)
	table.remove(gs, table.find(gs, "Astral"))
	table.insert(ThemeOrder, "Astral")
	for _, n in ipairs(gs) do table.insert(ThemeOrder, n) end
	table.insert(ThemeOrder, "Rainbow")
end
local ThemeName = "Purple"

local function Accent(offset)
	if ThemeName == "Rainbow" then
		return Color3.fromHSV((tick() * Themes.Speed * 1.25 + (offset or 0)) % 1, 0.65, 1)
	end
	local stops = Themes.G[ThemeName]
	if stops then
		local n = #stops
		local t = ((tick() * Themes.Speed * 0.5 + (offset or 0) * 0.5) % 1) * n
		local i = math.floor(t)
		local f = t - i
		return stops[i % n + 1]:Lerp(stops[(i + 1) % n + 1], f * f * (3 - 2 * f))
	end
	return Themes[ThemeName]
end

local Painters = {}
local function AddPainter(inst, fn, mod)
	fn()
	table.insert(Painters, { inst = inst, fn = fn, mod = mod })
end
local function Repaint(mod)
	for i = #Painters, 1, -1 do
		local p = Painters[i]
		if not p.inst.Parent then table.remove(Painters, i)
		elseif mod == nil or p.mod == mod then p.fn() end
	end
end
local function Reg(inst, prop, offset)
	AddPainter(inst, function() inst[prop] = Accent(offset) end)
end

local C_HEAD, C_ROW, C_ROWHOV, C_SET = Color3.fromRGB(16, 16, 22), Color3.fromRGB(24, 24, 32), Color3.fromRGB(38, 38, 50), Color3.fromRGB(15, 15, 20)
local C_DIM, C_LIGHT, WHITE = Color3.fromRGB(135, 135, 150), Color3.fromRGB(200, 200, 212), Color3.new(1, 1, 1)

----------------------------------------------------------------------
-- module system
----------------------------------------------------------------------
local Categories = { "Combat", "Movement", "Player", "Render", "Utility", "Settings" }
local CatDesc = {
	Combat = "Aim helpers, hitbox tools and targeting for your own game.",
	Movement = "Modules that change how you move around the world.",
	Player = "Modules that change or protect your own character.",
	Render = "Modules that change what you see on your screen.",
	Utility = "Teleports, tools and quality-of-life modules.",
	Settings = "Configure Zenith itself: theme, menu, array list and more.",
}
local Modules, ByCat = {}, {}
for _, c in ipairs(Categories) do ByCat[c] = {} end
local ui = {}

----------------------------------------------------------------------
-- Zenith logo, drawn from polygons at runtime (no image upload needed)
----------------------------------------------------------------------
-- polygons are flat {x1, y1, x2, y2, ...} in the original 1254px artwork; each one is filled one
-- pixel row at a time so it stays crisp at any size
ui.LogoShapes = {
	Mark = {
		{ 734, 672, 534, 387, 282, 731, 340, 729, 533, 473, 704, 714 },
		{ 721, 719, 724, 731, 753, 731, 814, 654, 874, 731, 926, 731, 815, 588 },
	},
	Dots = { { 647.5, 488, 12 }, { 679.5, 534.5, 8.5 } },
	Letters = {
		{ 387, 785, 387, 791, 409, 791, 387, 818, 387, 823, 419, 823, 419, 818, 397, 818, 418, 790, 418, 785 },
		{ 475, 785, 475, 823, 503, 823, 503, 818, 481, 818, 481, 807, 500, 807, 500, 801, 481, 801, 481, 791, 503, 791, 503, 785 },
		{ 559, 785, 559, 823, 565, 823, 565, 798, 589, 823, 594, 823, 594, 785, 588, 785, 588, 811, 564, 785 },
		{ 651, 785, 651, 823, 657, 823, 657, 785 },
		{ 711, 785, 711, 791, 722, 791, 722, 823, 728, 823, 728, 791, 740, 791, 740, 785 },
		{ 793, 785, 793, 823, 799, 823, 799, 807, 820, 807, 820, 823, 826, 823, 826, 785, 820, 785, 820, 801, 799, 801, 799, 785 },
	},
}
-- height = pixel height of the logo. opts.text draws the ZENITH wordmark underneath, opts.color is the
-- shape color (the theme accent by default, so the whole logo follows your theme)
function ui.DrawLogo(parent, height, opts)
	opts = opts or {}
	local OX, OY, FW, MH, FH = 282, 386, 644, 346, 437
	local s = height / (opts.text and FH or MH)
	local fixed = opts.color
	local root = New("Frame", { Name = "ZenithLogo", Size = UDim2.fromOffset(math.floor(FW * s + 0.5), math.floor(height + 0.5)), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
	local function fill(poly, off)
		local parts = {}
		local n = #poly / 2
		local ymin, ymax = math.huge, -math.huge
		for i = 2, #poly, 2 do ymin = math.min(ymin, poly[i]); ymax = math.max(ymax, poly[i]) end
		for r = math.floor((ymin - OY) * s), math.ceil((ymax - OY) * s) - 1 do
			local sy = OY + (r + 0.5) / s
			local xs = {}
			for i = 1, n do
				local j = i % n + 1
				local ax, ay, bx, by = poly[2 * i - 1], poly[2 * i], poly[2 * j - 1], poly[2 * j]
				if (ay <= sy and sy < by) or (by <= sy and sy < ay) then
					table.insert(xs, ax + (sy - ay) / (by - ay) * (bx - ax))
				end
			end
			table.sort(xs)
			for k = 1, #xs - 1, 2 do
				local x0 = math.floor((xs[k] - OX) * s + 0.5)
				local x1 = math.floor((xs[k + 1] - OX) * s + 0.5)
				if x1 <= x0 then x1 = x0 + 1 end
				table.insert(parts, New("Frame", { Position = UDim2.fromOffset(x0, r), Size = UDim2.fromOffset(x1 - x0, 1), BackgroundColor3 = fixed or WHITE, BorderSizePixel = 0 }, root))
			end
		end
		-- the whole logo follows the theme; one painter per shape keeps it cheap
		if not fixed then
			AddPainter(root, function()
				local c = Accent(off)
				for _, f in ipairs(parts) do f.BackgroundColor3 = c end
			end)
		end
	end
	for i, p in ipairs(ui.LogoShapes.Mark) do fill(p, 0) end
	for i, d in ipairs(ui.LogoShapes.Dots) do
		local size = math.max(2, d[3] * 2 * s)
		local dot = New("Frame", { Position = UDim2.fromOffset((d[1] - OX) * s - size / 2, (d[2] - OY) * s - size / 2), Size = UDim2.fromOffset(size, size), BorderSizePixel = 0 }, root)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		AddPainter(dot, function() dot.BackgroundColor3 = fixed or Accent(0) end)
	end
	if opts.text then for i, p in ipairs(ui.LogoShapes.Letters) do fill(p, 0) end end
	return root
end

-- brief fade-in logo when the client loads
function ui.Splash()
	local cg = New("CanvasGroup", { Name = "Splash", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 330), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 50 }, ui.Gui)
	local logo = ui.DrawLogo(cg, 250, { text = true })
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.new(0.5, 0, 0.5, -8)
	New("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(300, 18), BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = C_DIM, Text = "ZENITH CLIENT  " .. VERSION }, cg)
	-- everything else stays hidden (shrunk to nothing) until the logo shoots outward into it
	local targets = {}
	for _, f in ipairs({ ui.TopRight, ui.Gui:FindFirstChild("Info") or false, ui.Gui:FindFirstChild("ZenithTabGui") or false }) do
		if f then
			targets[#targets + 1] = { f = f, pos = f.Position, us = New("UIScale", { Name = "ZSplash", Scale = 0.001 }, f) }
		end
	end
	local lus = New("UIScale", { Scale = 1 }, cg)
	TweenService:Create(cg, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }):Play()
	task.delay(2, function()
		local vp = ui.Gui.AbsoluteSize
		if cg.Parent then
			TweenService:Create(lus, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.5 }):Play()
			local t2 = TweenService:Create(cg, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
			t2:Play()
			t2.Completed:Connect(function() cg:Destroy() end)
		end
		for i, t in ipairs(targets) do
			task.delay((i - 1) * 0.1, function()
				local f = t.f
				if not f.Parent then return end
				f.Position = UDim2.fromOffset(vp.X / 2, vp.Y * 0.45)
				local info = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				TweenService:Create(t.us, info, { Scale = 1 }):Play()
				local tw = TweenService:Create(f, info, { Position = t.pos })
				tw.Completed:Connect(function() f.Position = t.pos; t.us:Destroy() end)
				tw:Play()
			end)
		end
	end)
end

-- the game's own values, saved before anything here can change them; modules go back to these when turned off
ui.Def = { FOV = Camera.FieldOfView, Gravity = workspace.Gravity, MaxZoom = LP.CameraMaxZoomDistance, MinZoom = LP.CameraMinZoomDistance }
function ui.CaptureHumanoid(h)
	ui.Def.WalkSpeed, ui.Def.JumpPower, ui.Def.UseJumpPower = h.WalkSpeed, h.JumpPower, h.UseJumpPower
	ui.Def.HipHeight, ui.Def.AutoRotate = h.HipHeight, h.AutoRotate
end
do
	local h0 = Hum()
	if h0 then ui.CaptureHumanoid(h0) end
	Conn(LP.CharacterAdded, function(c)
		local h = c:WaitForChild("Humanoid", 5)
		if h then ui.CaptureHumanoid(h) end
	end)
end

-- ---- mobile support -------------------------------------------------
-- ui.Phone: a touch device without a keyboard (layout gets bigger touch targets and scrolling panels)
ui.Phone = UIS.TouchEnabled and not UIS.KeyboardEnabled
-- the movement stick, as x = right and y = forward (-1 to 1), for flying and freecam
function ui.Controls()
	if ui._ctl == nil then
		local ok, c = pcall(function()
			return require(LP:WaitForChild("PlayerScripts", 3):WaitForChild("PlayerModule", 3)):GetControls()
		end)
		ui._ctl = ok and c or false
	end
	return ui._ctl
end
function ui.MoveVec()
	if not UIS.TouchEnabled then return Vector2.zero end
	local c = ui.Controls()
	if c then
		local ok, v = pcall(function() return c:GetMoveVector() end)
		if ok and v then return Vector2.new(v.X, -v.Z) end
	end
	local h = Hum()
	if h and h.MoveDirection.Magnitude > 0 then
		local cf = Camera.CFrame
		local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if fwd.Magnitude > 0 then return Vector2.new(h.MoveDirection:Dot(cf.RightVector), h.MoveDirection:Dot(fwd.Unit)) end
	end
	return Vector2.zero
end
-- round hold-to-use button on the right edge of the screen; slot 0 is the lowest. Returns { held, btn }
function ui.TouchBtn(text, slot)
	local st = { held = false }
	local b = New("TextButton", { Name = "ZenithTouch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 38 - slot * 76), Size = UDim2.fromOffset(64, 64), BackgroundColor3 = C_HEAD, BackgroundTransparency = 0.15, Text = text, Font = FONT_B, TextSize = 13, TextColor3 = WHITE, AutoButtonColor = false, ZIndex = 30 }, ui.Gui)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
	local stroke = New("UIStroke", { Thickness = 2 }, b)
	AddPainter(stroke, function() stroke.Color = Accent() end)
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then st.held = true end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then st.held = false end
	end)
	st.btn = b
	return st
end
function ui.DropTouch(st) if st and st.btn then st.btn:Destroy() end end
-- Left Ctrl on keyboard, or the DOWN button on a phone
function ui.Opt(name) local g = ui.GuiMod; return g == nil or g.Values[name] ~= false end
function ui.Lower(m) return (ui.Opt("Ctrl To Lower") and Down(Enum.KeyCode.LeftControl)) or (m._tDn ~= nil and m._tDn.held) end

local function Module(def)
	def.Enabled, def.Values, def._conns = false, {}, {}
	def.BindMode = "Toggle"
	for _, s in ipairs(def.Settings or {}) do
		if s.Type == "Mode" then
			local o = type(s.Options) == "function" and s.Options() or s.Options
			def.Values[s.Name] = s.Default or o[1]
		else
			def.Values[s.Name] = s.Default
		end
	end
	table.insert(Modules, def)
	table.insert(ByCat[def.Category], def)
	return def
end
local function Hook(m, sig, fn) table.insert(m._conns, sig:Connect(fn)) end

local function SetEnabled(m, state, silent)
	if m.Action or m.Passive or m.Enabled == state then return end
	m.Enabled = state
	if state then
		if m.OnEnable then Safe(m.OnEnable, m) end
	else
		for _, c in ipairs(m._conns) do c:Disconnect() end
		table.clear(m._conns)
		if m.OnDisable then Safe(m.OnDisable, m) end
	end
	if ui.OnToggle then ui.OnToggle(m, silent) end
end
local function ToggleModule(m)
	if m.Action then Safe(m.Action, m) elseif not m.Passive then SetEnabled(m, not m.Enabled) end
end

local function PlayerNames()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
	if #t == 0 then t[1] = "<none>" end
	return t
end
local function Target(m)
	local p = Players:FindFirstChild(m.Values.Target or "")
	if p and p ~= LP then return p end
	for _, o in ipairs(Players:GetPlayers()) do if o ~= LP then return o end end
end

local function Slider(name, min, max, step, default, desc) return { Name = name, Type = "Slider", Min = min, Max = max, Step = step, Default = default, Desc = desc } end
local function Toggle(name, default, desc) return { Name = name, Type = "Toggle", Default = default, Desc = desc } end
local function Mode(name, options, default, desc, suffix) return { Name = name, Type = "Mode", Options = options, Default = default, Desc = desc, Suffix = suffix } end
local function ColorSet(name, default, desc) return { Name = name, Type = "Color", Default = default, Desc = desc } end
local function Button(name, desc, fn) return { Name = name, Type = "Button", Desc = desc, Fn = fn } end
local ColorModes = { "Accent", "Team", "Rainbow", "White", "Red" }

local D_COLOR = "Color used: your accent color, the player's team color, rainbow, white or red."
local D_TEAM = "Ignores players who are on your own team."
local D_DIST = "Players farther away than this (in studs) are ignored."
local D_TARGET = "Which player to use. Left-click for the next player, right-click for the previous one."

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
Module{ Name = "Speed", Category = "Movement", Desc = "Run faster than normal. Pick WalkSpeed for the simplest option, or CFrame / Velocity to push your character along manually.",
	Settings = {
		Mode("Mode", { "WalkSpeed", "CFrame", "Velocity" }, "WalkSpeed", "How speed is applied. WalkSpeed edits your walk speed; CFrame and Velocity move you manually, which works in games that keep resetting WalkSpeed.", true),
		Slider("Speed", 16, 250, 1, 40, "Target speed in studs per second. Roblox's default is 16."),
	},
	OnEnable = function(m) local h = Hum(); m._orig = h and h.WalkSpeed or 16 end,
	OnDisable = function(m) local h = Hum(); if h then h.WalkSpeed = ui.Def.WalkSpeed or m._orig or 16 end end,
	OnTick = function(m, dt)
		local h, r = Hum(), Root(); if not h or not r then return end
		local mode, sp = m.Values.Mode, m.Values.Speed
		if mode == "WalkSpeed" then h.WalkSpeed = sp; return end
		h.WalkSpeed = m._orig
		local md = h.MoveDirection
		if md.Magnitude > 0 then
			if mode == "CFrame" then
				r.CFrame = r.CFrame + md * math.max(sp - h.WalkSpeed, 0) * dt
			else
				local v = r.AssemblyLinearVelocity
				r.AssemblyLinearVelocity = Vector3.new(md.X * sp, v.Y, md.Z * sp)
			end
		end
	end }

do
local function FlyClear(m)
	for _, k in ipairs({ "_lv", "_ao", "_att" }) do
		if m[k] then m[k]:Destroy(); m[k] = nil end
	end
end
local function FlyBuild(m, r)
	FlyClear(m)
	m._yaw = m._yaw or 0
	m._att = New("Attachment", { Name = "ZenithFly" }, r)
	m._lv = New("LinearVelocity", { Attachment0 = m._att, RelativeTo = Enum.ActuatorRelativeTo.World, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector, MaxForce = math.huge, VectorVelocity = Vector3.zero }, r)
	m._ao = New("AlignOrientation", { Attachment0 = m._att, Mode = Enum.OrientationAlignmentMode.OneAttachment, RigidityEnabled = false, MaxTorque = math.huge, Responsiveness = 25, CFrame = CFrame.fromOrientation(0, m._yaw, 0) }, r)
end

Module{ Name = "Fly", Category = "Movement", Desc = "Fly around with WASD, Space to go up and Shift or Ctrl to go down. On mobile use the stick and the UP and DOWN buttons.",
	Settings = {
		Mode("Mode", { "Velocity", "CFrame" }, "Velocity", "Velocity flies with physics and feels smoother. CFrame moves you directly.", true),
		Slider("Speed", 5, 400, 1, 70, "Horizontal flight speed."),
		Slider("Vertical", 5, 250, 1, 55, "Up and down speed."),
		Slider("Smoothing", 1, 30, 1, 10, "How quickly you speed up and slow down. Higher is snappier."),
		Toggle("Face Camera", true, "Turns your character to face where the camera looks."),
	},
	OnEnable = function(m)
		local r, h = Root(), Hum()
		if r then
			local l = r.CFrame.LookVector
			m._yaw = math.atan2(-l.X, -l.Z)
			m._vel = r.AssemblyLinearVelocity
			FlyBuild(m, r)
		end
		if h then h.PlatformStand = true end
		if UIS.TouchEnabled then m._tUp, m._tDn = ui.TouchBtn("UP", 1), ui.TouchBtn("DOWN", 0) end
	end,
	OnDisable = function(m)
		ui.DropTouch(m._tUp); ui.DropTouch(m._tDn); m._tUp, m._tDn = nil, nil
		FlyClear(m)
		local h, r = Hum(), Root()
		if h then h.PlatformStand = false end
		if r then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
	end,
	OnTick = function(m, dt)
		local h, r = Hum(), Root(); if not h or not r then return end
		h.PlatformStand = true
		if not m._lv or m._lv.Parent ~= r then
			m._vel = Vector3.zero
			FlyBuild(m, r)
		end
		local V = m.Values
		local cf, dir, vert = Camera.CFrame, Vector3.zero, 0
		if Down(Enum.KeyCode.W) then dir += cf.LookVector end
		if Down(Enum.KeyCode.S) then dir -= cf.LookVector end
		if Down(Enum.KeyCode.D) then dir += cf.RightVector end
		if Down(Enum.KeyCode.A) then dir -= cf.RightVector end
		if Down(Enum.KeyCode.Space) then vert += 1 end
		if (ui.Opt("Shift To Descend") and Down(Enum.KeyCode.LeftShift)) or (ui.Opt("Ctrl To Lower") and Down(Enum.KeyCode.LeftControl)) then vert -= 1 end
		local mv = ui.MoveVec()
		dir += cf.RightVector * mv.X + cf.LookVector * mv.Y
		if m._tUp and m._tUp.held then vert += 1 end
		if m._tDn and m._tDn.held then vert -= 1 end

		-- ease toward the wanted velocity instead of snapping to it
		local target = (dir.Magnitude > 0 and dir.Unit * V.Speed or Vector3.zero) + Vector3.new(0, vert * V.Vertical, 0)
		m._vel = m._vel:Lerp(target, 1 - math.exp(-V.Smoothing * dt))

		-- keep upright, face the camera (or the way you move)
		local flat = V["Face Camera"] and Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z) or Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude > 0.05 then m._yaw = math.atan2(-flat.X, -flat.Z) end
		local rot = CFrame.fromOrientation(0, m._yaw, 0)

		if V.Mode == "CFrame" then
			m._ao.Enabled = false
			m._lv.VectorVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			r.CFrame = CFrame.new(r.Position + m._vel * dt) * rot
		else
			m._ao.Enabled = true
			m._ao.CFrame = rot
			m._lv.VectorVelocity = m._vel
		end
	end }
end

local CAS = game:GetService("ContextActionService")
do
local function VFlyClear(m)
	for _, k in ipairs({ "_lv", "_ao", "_att" }) do
		if m[k] then m[k]:Destroy(); m[k] = nil end
	end
	m._root, m._seat = nil, nil
	CAS:UnbindAction("ZenithVFlySink")
end
local function VFlyBuild(m, root, seat)
	VFlyClear(m)
	m._root, m._seat = root, seat
	-- steer by the seat's orientation, whatever way the vehicle's main part happens to face
	m._rel = root.CFrame.Rotation:Inverse() * seat.CFrame.Rotation
	local l = seat.CFrame.LookVector
	m._yaw = math.atan2(-l.X, -l.Z)
	m._vel = root.AssemblyLinearVelocity
	m._att = New("Attachment", { Name = "ZenithVFly" }, root)
	m._lv = New("LinearVelocity", { Attachment0 = m._att, RelativeTo = Enum.ActuatorRelativeTo.World, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector, MaxForce = math.huge, VectorVelocity = Vector3.zero }, root)
	m._ao = New("AlignOrientation", { Attachment0 = m._att, Mode = Enum.OrientationAlignmentMode.OneAttachment, RigidityEnabled = false, MaxTorque = math.huge, Responsiveness = 20, CFrame = CFrame.fromOrientation(0, m._yaw, 0) * m._rel:Inverse() }, root)
	-- Space is our "up" key here, so stop it from also making you jump out of the seat
	CAS:BindActionAtPriority("ZenithVFlySink", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
end

Module{ Name = "VehicleFly", Category = "Movement", Desc = "Fly the seat or vehicle you are sitting in with WASD, Space to go up and Shift or Ctrl to go down. On mobile use the stick and the UP and DOWN buttons.",
	Settings = {
		Slider("Speed", 5, 500, 1, 90, "Horizontal flight speed."),
		Slider("Vertical", 5, 300, 1, 60, "Up and down speed."),
		Slider("Smoothing", 1, 30, 1, 8, "How quickly you speed up and slow down. Higher is snappier."),
		Toggle("Face Camera", true, "Turns the vehicle to face where the camera looks."),
	},
	OnEnable = function(m)
		local h = Hum()
		if not (h and h.SeatPart) then ui.Notify("Sit in a seat or vehicle to use VehicleFly", false) end
		if UIS.TouchEnabled then m._tUp, m._tDn = ui.TouchBtn("UP", 1), ui.TouchBtn("DOWN", 0) end
	end,
	OnDisable = function(m)
		ui.DropTouch(m._tUp); ui.DropTouch(m._tDn); m._tUp, m._tDn = nil, nil
		local root = m._root
		VFlyClear(m)
		if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
	end,
	OnTick = function(m, dt)
		local h = Hum(); if not h then return end
		local seat = h.SeatPart
		local root = seat and seat.AssemblyRootPart
		if not root or root.Anchored then
			if m._root then VFlyClear(m) end
			return
		end
		if m._root ~= root or m._seat ~= seat or not m._lv or m._lv.Parent ~= root then
			VFlyBuild(m, root, seat)
		end
		local V = m.Values
		local cf, dir, vert = Camera.CFrame, Vector3.zero, 0
		if Down(Enum.KeyCode.W) then dir += cf.LookVector end
		if Down(Enum.KeyCode.S) then dir -= cf.LookVector end
		if Down(Enum.KeyCode.D) then dir += cf.RightVector end
		if Down(Enum.KeyCode.A) then dir -= cf.RightVector end
		if Down(Enum.KeyCode.Space) then vert += 1 end
		if (ui.Opt("Shift To Descend") and Down(Enum.KeyCode.LeftShift)) or (ui.Opt("Ctrl To Lower") and Down(Enum.KeyCode.LeftControl)) then vert -= 1 end
		local mv = ui.MoveVec()
		dir += cf.RightVector * mv.X + cf.LookVector * mv.Y
		if m._tUp and m._tUp.held then vert += 1 end
		if m._tDn and m._tDn.held then vert -= 1 end

		local target = (dir.Magnitude > 0 and dir.Unit * V.Speed or Vector3.zero) + Vector3.new(0, vert * V.Vertical, 0)
		m._vel = m._vel:Lerp(target, 1 - math.exp(-V.Smoothing * dt))

		local flat = V["Face Camera"] and Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z) or Vector3.new(dir.X, 0, dir.Z)
		if flat.Magnitude > 0.05 then m._yaw = math.atan2(-flat.X, -flat.Z) end
		m._ao.CFrame = CFrame.fromOrientation(0, m._yaw, 0) * m._rel:Inverse()
		m._lv.VectorVelocity = m._vel
	end }
end

-- AirWalk and Jesus put an invisible floor under your feet (only on your client), so you stand on it
-- and the normal idle / walking animations play instead of the falling one.
ui.Plats = {}
function ui.MakePlatform(name)
	return New("Part", { Name = name, Anchored = true, CanCollide = true, CanTouch = false, Transparency = 1, Size = Vector3.new(22, 1, 22), TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, workspace)
end
function ui.DropPlatform(key)
	local p = ui.Plats[key]
	if p then p:Destroy(); ui.Plats[key] = nil end
end
-- height of the bottom of your feet
function ui.FeetY(r, h)
	local legs = h.RigType == Enum.HumanoidRigType.R6 and 2 or h.HipHeight
	return r.Position.Y - legs - r.Size.Y / 2
end

Module{ Name = "AirWalk", Category = "Movement", Desc = "Lets you walk on thin air without falling, with your normal walking animations. Jump to climb higher, hold Left Ctrl (or the LOWER button on mobile) to lower the floor.",
	Settings = {
		Toggle("Jump Raises Floor", true, "When you jump, the invisible floor lifts to where your jump ends so you climb instead of dropping back down."),
		Slider("Lower Speed", 5, 80, 1, 25, "How fast the floor drops while you hold Left Ctrl."),
	},
	OnEnable = function(m)
		local r, h = Root(), Hum()
		if r and h then
			m._level, m._char = ui.FeetY(r, h), LP.Character
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
		end
		if UIS.TouchEnabled then m._tDn = ui.TouchBtn("LOWER", 0) end
	end,
	OnDisable = function(m) ui.DropTouch(m._tDn); m._tDn = nil; ui.DropPlatform("Air") end,
	OnTick = function(m, dt)
		local r, h = Root(), Hum(); if not r or not h then return end
		local feet = ui.FeetY(r, h)
		if m._char ~= LP.Character or not m._level then
			m._level, m._char = feet, LP.Character
		end
		local V = m.Values
		local vel = r.AssemblyLinearVelocity
		if ui.Lower(m) then
			m._level -= V["Lower Speed"] * dt
		elseif V["Jump Raises Floor"] and feet > m._level + 0.6 and vel.Y <= 1 then
			-- you jumped and stopped rising: the floor moves up under your feet, so you land on it
			m._level = feet - 0.05
		end
		-- pushed or teleported far below the floor: start over from where you are
		if feet < m._level - 3 and not ui.Lower(m) then m._level = feet end
		local plat = ui.Plats.Air
		if not plat or not plat.Parent then plat = ui.MakePlatform("ZenithAirWalk"); ui.Plats.Air = plat end
		-- lead the platform slightly in the direction you move so fast movement never outruns it
		local lead = Vector3.new(vel.X, 0, vel.Z) * math.min(dt, 0.1) * 3
		plat.CFrame = CFrame.new(r.Position.X + lead.X, m._level - plat.Size.Y / 2, r.Position.Z + lead.Z)
	end }

Module{ Name = "Jesus", Category = "Movement", Desc = "Lets you walk on top of water. Hold Left Ctrl to sink.",
	Settings = { Slider("Swim Up Speed", 5, 60, 1, 20, "How fast you rise to the surface if you are already in the water.") },
	OnEnable = function(m) if UIS.TouchEnabled then m._tDn = ui.TouchBtn("SINK", 0) end end,
	OnDisable = function(m) ui.DropTouch(m._tDn); m._tDn = nil; ui.DropPlatform("Jesus") end,
	OnTick = function(m)
		local r, h = Root(), Hum(); if not r or not h then return end
		local sinking = ui.Lower(m)
		local plat = ui.Plats.Jesus
		local params = RayParams()
		params.IgnoreWater = false
		local skip = { LP.Character }
		if ui.Plats.Air then table.insert(skip, ui.Plats.Air) end
		if plat then table.insert(skip, plat) end
		params.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(r.Position + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), params)
		if hit and hit.Material == Enum.Material.Water and not sinking then
			if not plat or not plat.Parent then plat = ui.MakePlatform("ZenithJesus"); ui.Plats.Jesus = plat end
			plat.CanCollide = true
			plat.CFrame = CFrame.new(r.Position.X, hit.Position.Y - plat.Size.Y / 2, r.Position.Z)
		elseif plat then
			plat.CanCollide = false
		end
		-- already swimming: float up until the surface floor can catch you
		if not sinking and h:GetState() == Enum.HumanoidStateType.Swimming then
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, m.Values["Swim Up Speed"], v.Z)
		end
	end }

-- air swimming: a clean 3D swim vector from your movement keys/stick and camera, plus a check for real water
function ui.SwimDir(h)
	local md = h.MoveDirection
	if md.Magnitude < 0.05 then return Vector3.zero end
	local cf = Camera.CFrame
	local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	local f = flat.Magnitude > 0 and md:Dot(flat.Unit) or 0
	local d = cf.LookVector * f + cf.RightVector * md:Dot(cf.RightVector)
	return d.Magnitude > 0.01 and d.Unit or Vector3.zero
end
function ui.InWater(r)
	local now = os.clock()
	if now - (ui._wT or 0) < 0.25 then return ui._wV end
	ui._wT = now
	local ok, res = pcall(function()
		local p = r.Position
		local reg = Region3.new(p - Vector3.new(3, 3, 3), p + Vector3.new(3, 3, 3)):ExpandToGrid(4)
		for _, a in ipairs((workspace.Terrain:ReadVoxels(reg, 4))) do
			for _, b in ipairs(a) do for _, c in ipairs(b) do if c == Enum.Material.Water then return true end end end
		end
		return false
	end)
	ui._wV = ok and res or false
	return ui._wV
end
Module{ Name = "Swim", Category = "Movement", Desc = "Lets you swim through the air as if it were water. Space swims up, Left Ctrl swims down.",
	Settings = { Slider("Speed", 8, 100, 1, 28, "How fast you swim in any direction.") },
	OnEnable = function(m)
		workspace.Gravity = 0
		if UIS.TouchEnabled then m._tUp, m._tDn = ui.TouchBtn("UP", 1), ui.TouchBtn("DOWN", 0) end
	end,
	OnDisable = function(m)
		ui.DropTouch(m._tUp); ui.DropTouch(m._tDn); m._tUp, m._tDn = nil, nil
		workspace.Gravity = ui.Def.Gravity or 196.2
		local h = Hum()
		if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end,
	OnTick = function(m)
		local r, h = Root(), Hum(); if not r or not h then return end
		local speed = m.Values.Speed
		workspace.Gravity = 0
		h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
		h:ChangeState(Enum.HumanoidStateType.Swimming)
		h.WalkSpeed = speed
		local v = r.AssemblyLinearVelocity
		local tgt = ui.SwimDir(h) * speed
		if Down(Enum.KeyCode.Space) or (m._tUp and m._tUp.held) then tgt += Vector3.new(0, speed, 0)
		elseif ui.Lower(m) then tgt -= Vector3.new(0, speed, 0) end
		if tgt.Magnitude > speed then tgt = tgt.Unit * speed end
		r.AssemblyLinearVelocity = v:Lerp(tgt, 0.35)
	end }

Module{ Name = "SwimAssist", Category = "Movement", Desc = "Fixes swimming in the air when another script or game puts you in the swim state. Instead of flinging you in one direction, you swim where you point and stop when you let go.",
	Settings = {
		Slider("Speed", 5, 100, 1, 24, "How fast you swim."),
		Slider("Smoothing", 0.05, 1, 0.05, 0.35, "How quickly you reach full speed and stop. Lower is floatier."),
		Toggle("Only In Air", true, "Leaves real water alone and only takes over when you are swimming in the air."),
		Toggle("Vertical Keys", true, "Space swims up and Left Ctrl swims down while assisting."),
	},
	OnTick = function(m)
		local r, h = Root(), Hum(); if not r or not h then return end
		local V = m.Values
		if h:GetState() ~= Enum.HumanoidStateType.Swimming then return end
		if V["Only In Air"] and ui.InWater(r) then return end
		local tgt = ui.SwimDir(h) * V.Speed
		if V["Vertical Keys"] then
			if Down(Enum.KeyCode.Space) or h.Jump then tgt += Vector3.new(0, V.Speed, 0)
			elseif ui.Lower(m) then tgt -= Vector3.new(0, V.Speed, 0) end
		end
		if tgt.Magnitude > V.Speed then tgt = tgt.Unit * V.Speed end
		r.AssemblyLinearVelocity = r.AssemblyLinearVelocity:Lerp(tgt, V.Smoothing)
	end }

Module{ Name = "Jetpack", Category = "Movement", Desc = "Gives you a jetpack. Lift pushes you straight up, Steer flies you wherever your camera points.",
	Settings = {
		Mode("Mode", { "Lift", "Steer" }, "Lift", "Lift pushes you straight up while it is on. Steer flies you in the direction your camera is facing."),
		Slider("Power", 5, 150, 1, 40, "How fast the jetpack moves you in studs per second."),
	},
	OnTick = function(m)
		local r = Root(); if not r then return end
		local V = m.Values
		local v = r.AssemblyLinearVelocity
		if V.Mode == "Lift" then
			r.AssemblyLinearVelocity = Vector3.new(v.X, V.Power, v.Z)
		else
			r.AssemblyLinearVelocity = Camera.CFrame.LookVector * V.Power
		end
	end }

Module{ Name = "Noclip", Category = "Movement", Desc = "Turns off collision on your character so you can walk through walls and objects. Floors still hold you up.",
	OnEnable = function(m)
		Hook(m, RunService.Stepped, function()
			local c = LP.Character
			if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
		end)
	end }

Module{ Name = "InfiniteJump", Category = "Movement", Desc = "Lets you jump again while already in mid-air, as many times as you want.",
	Settings = {
		Mode("Mode", { "State", "Velocity" }, "State", "State re-triggers the humanoid jump. Velocity sets your upward speed directly using the Power setting."),
		Slider("Power", 30, 150, 1, 55, "Upward speed of each air jump. Only used by Velocity mode."),
	},
	OnEnable = function(m)
		Hook(m, UIS.JumpRequest, function()
			local h, r = Hum(), Root(); if not h or not r then return end
			if m.Values.Mode == "State" then h:ChangeState(Enum.HumanoidStateType.Jumping)
			else local v = r.AssemblyLinearVelocity; r.AssemblyLinearVelocity = Vector3.new(v.X, m.Values.Power, v.Z) end
		end)
	end }

Module{ Name = "HighJump", Category = "Movement", Desc = "Raises your jump power so every jump goes higher.",
	Settings = { Slider("Power", 50, 400, 1, 120, "Jump power. Roblox's default is 50.") },
	OnEnable = function(m) local h = Hum(); if h then m._u, m._p = h.UseJumpPower, h.JumpPower end end,
	OnDisable = function(m) local h = Hum(); if h then if ui.Def.UseJumpPower ~= nil then h.UseJumpPower = ui.Def.UseJumpPower else h.UseJumpPower = m._u ~= false end; h.JumpPower = ui.Def.JumpPower or m._p or 50 end end,
	OnTick = function(m) local h = Hum(); if h then h.UseJumpPower = true; h.JumpPower = m.Values.Power end end }

Module{ Name = "Bhop", Category = "Movement", Desc = "Hops automatically while you move and keeps your speed up in the air.",
	Settings = { Slider("Boost", 0, 40, 1, 6, "Extra air speed on top of your walk speed.") },
	OnTick = function(m)
		local h, r = Hum(), Root(); if not h or not r then return end
		if h.Sit or h.PlatformStand then return end
		local md = h.MoveDirection
		if md.Magnitude == 0 then return end
		if h.FloorMaterial ~= Enum.Material.Air then
			-- the default controls reset Humanoid.Jump every frame, so ask for the jump state directly
			if h:GetState() ~= Enum.HumanoidStateType.Jumping then
				h:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		else
			local v = r.AssemblyLinearVelocity
			local s = h.WalkSpeed + m.Values.Boost
			r.AssemblyLinearVelocity = Vector3.new(md.X * s, v.Y, md.Z * s)
		end
	end }

Module{ Name = "Glide", Category = "Movement", Desc = "Caps how fast you fall so you drift down slowly instead of dropping.",
	Settings = { Slider("Fall Speed", 1, 60, 1, 8, "Maximum downward speed in studs per second. Lower means a slower fall.") },
	OnTick = function(m)
		local h, r = Hum(), Root(); if not h or not r then return end
		local v = r.AssemblyLinearVelocity
		if h.FloorMaterial == Enum.Material.Air and v.Y < -m.Values["Fall Speed"] then
			r.AssemblyLinearVelocity = Vector3.new(v.X, -m.Values["Fall Speed"], v.Z)
		end
	end }

Module{ Name = "Spider", Category = "Movement", Desc = "Climb up walls by walking into them.",
	Settings = { Slider("Speed", 5, 80, 1, 28, "How fast you climb, in studs per second.") },
	OnTick = function(m)
		local h, r = Hum(), Root(); if not h or not r then return end
		if h.MoveDirection.Magnitude == 0 then return end
		if workspace:Raycast(r.Position, r.CFrame.LookVector * 2.5, RayParams()) then
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, m.Values.Speed, v.Z)
		end
	end }

Module{ Name = "Gravity", Category = "Movement", Desc = "Changes gravity for your own physics. Low values make you float, high values slam you down.",
	Settings = { Slider("Gravity", 0, 400, 1, 40, "Gravity in studs per second squared. Roblox's default is 196.2.") },
	OnEnable = function(m) m._orig = workspace.Gravity end,
	OnDisable = function(m) workspace.Gravity = ui.Def.Gravity or m._orig or 196.2 end,
	OnTick = function(m) workspace.Gravity = m.Values.Gravity end }

Module{ Name = "Dash", Category = "Movement", Desc = "Launches you forward in the direction the camera is facing. Bind it to a key for an instant dash.",
	Settings = { Slider("Power", 30, 300, 1, 100, "Dash speed in studs per second.") },
	Action = function(m)
		local r = Root(); if not r then return end
		local l = Camera.CFrame.LookVector
		local flat = Vector3.new(l.X, 0, l.Z)
		if flat.Magnitude < 0.01 then return end
		r.AssemblyLinearVelocity = flat.Unit * m.Values.Power + Vector3.new(0, 20, 0)
	end }

----------------------------------------------------------------------
-- PLAYER
----------------------------------------------------------------------
Module{ Name = "Spinbot", Category = "Player", Desc = "Spins your character around quickly.",
	Settings = { Slider("Speed", 1, 60, 1, 20, "Degrees turned every frame at 60 FPS. Higher spins faster.") },
	OnEnable = function() local h = Hum(); if h then h.AutoRotate = false end end,
	OnDisable = function() local h = Hum(); if h then h.AutoRotate = ui.Def.AutoRotate ~= false end end,
	OnTick = function(m, dt)
		local r = Root(); if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(m.Values.Speed) * dt * 60, 0) end
	end }

Module{ Name = "HipHeight", Category = "Player", Desc = "Hovers your character above the ground by raising its hip height.",
	Settings = { Slider("Height", 0, 40, 0.5, 6, "How high you float above the ground, in studs.") },
	OnEnable = function(m) local h = Hum(); m._orig = h and h.HipHeight or 2 end,
	OnDisable = function(m) local h = Hum(); if h then h.HipHeight = ui.Def.HipHeight or m._orig end end,
	OnTick = function(m) local h = Hum(); if h then h.HipHeight = m.Values.Height end end }

Module{ Name = "AntiSit", Category = "Player", Desc = "Stops you from sitting in seats and vehicles.",
	OnTick = function()
		local h = Hum(); if not h then return end
		h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		if h.Sit then h.Sit = false end
	end,
	OnDisable = function()
		local h = Hum(); if h then h:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
	end }

Module{ Name = "NoFall", Category = "Player", Desc = "Stops fall damage. Keeps your fall speed low the whole way down, softens the landing, and cancels the landing hit itself.",
	Settings = {
		Mode("Method", { "Both", "Clamp Speed", "Soft Land" }, "Both", "Clamp Speed never lets you fall faster than Max Fall Speed. Soft Land only cancels your speed just before the ground. Both does both."),
		Slider("Max Fall Speed", 10, 120, 1, 30, "The fastest you can fall while Clamp Speed is on. Lower it if a game's fall damage still gets you."),
		Slider("Threshold", 20, 120, 1, 45, "Fall speed where Soft Land starts cancelling your speed near the ground."),
		Toggle("Landing Reset", true, "The moment the game says you landed, your fall speed is set to zero so scripts reading it see nothing."),
		Toggle("No Ragdoll", true, "Stops the humanoid from tripping or ragdolling after a hard landing."),
		Toggle("Spike Guard", true, "Watches for the same signs fall-damage scripts look for: very high speed and speed that changes suddenly. When your speed jumps by more than the limit in one frame, it is flattened and held near zero for a moment."),
		Slider("Spike Limit", 20, 250, 5, 60, "How much your speed may change in a single frame before Spike Guard steps in."),
	},
	OnEnable = function(m) m._hum = nil; m._last = nil; m._grace = 0 end,
	OnDisable = function(m)
		local h = Hum()
		if h then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end
		m._hum = nil
	end,
	OnTick = function(m)
		local r, h = Root(), Hum(); if not r or not h then return end
		local V = m.Values
		if m._hum ~= h then
			-- a new character: set it up once
			m._hum = h
			if V["No Ragdoll"] then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end
			Hook(m, h.StateChanged, function(old, new)
				if V["Landing Reset"] and (new == Enum.HumanoidStateType.Landed or (old == Enum.HumanoidStateType.Freefall and new == Enum.HumanoidStateType.Running)) then
					local rr = Root()
					if rr then
						local v = rr.AssemblyLinearVelocity
						rr.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
					end
				end
			end)
		end
		local v = r.AssemblyLinearVelocity
		if V["Spike Guard"] then
			local last = m._last
			m._last = v
			local now = os.clock()
			if last and last.Y < -V.Threshold and (v - last).Magnitude > V["Spike Limit"] then
				m._grace = now + 0.3
			end
			if now < (m._grace or 0) then
				v = Vector3.new(v.X, math.max(v.Y, -2), v.Z)
				if v.Y > 5 then v = Vector3.new(v.X, 5, v.Z) end
				r.AssemblyLinearVelocity = v
				return
			end
			if math.abs(v.Y) > V["Max Fall Speed"] * 3 and v.Y > 0 then
				-- huge upward spikes right after a fall are collisions being resolved
				if last and last.Y < -V.Threshold then r.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z); return end
			end
		end
		local mode = V.Method
		if (mode == "Both" or mode == "Clamp Speed") and v.Y < -V["Max Fall Speed"] then
			v = Vector3.new(v.X, -V["Max Fall Speed"], v.Z)
			r.AssemblyLinearVelocity = v
		end
		if mode == "Both" or mode == "Soft Land" then
			-- the faster you fall, the earlier the ground has to be noticed
			local reach = math.max(14, -v.Y * 0.3)
			if v.Y < -V.Threshold and workspace:Raycast(r.Position, Vector3.new(0, -reach, 0), RayParams()) then
				r.AssemblyLinearVelocity = Vector3.new(v.X, -4, v.Z)
			end
		end
	end }

Module{ Name = "AntiVoid", Category = "Player", Desc = "If you fall below the void height, teleports you back to the last solid ground you stood on.",
	Settings = { Slider("Height", -450, 100, 10, -100, "Y-height that counts as the void. Set it below the lowest ground of your map.") },
	OnEnable = function(m) m._safe = nil end,
	OnTick = function(m)
		local h, r = Hum(), Root(); if not h or not r then return end
		if h.FloorMaterial ~= Enum.Material.Air and r.Position.Y > m.Values.Height + 10 then m._safe = r.CFrame end
		if r.Position.Y < m.Values.Height and m._safe then
			r.AssemblyLinearVelocity = Vector3.zero
			r.CFrame = m._safe + Vector3.new(0, 4, 0)
		end
	end }

Module{ Name = "Blink", Category = "Player", Desc = "Pauses what the server sees of you. You move freely on your screen, but the game still sees you standing where you started. Turn it off and everything you did catches up at once.",
	Settings = { Toggle("Ghost Clone", true, "Leaves a see-through copy of your body where the server thinks you are. It disappears when Blink turns off.") },
	OnEnable = function(m)
		local ok = pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(1) end)
		if not ok then
			ui.Notify("Your executor can't pause outgoing network data, so Blink can't work", false)
			task.defer(function() SetEnabled(m, false, true) end)
			return
		end
		local ch = LP.Character
		if ch and m.Values["Ghost Clone"] then
			local arch = ch.Archivable
			ch.Archivable = true
			local copy = ch:Clone()
			ch.Archivable = arch
			if copy then
				copy.Name = "ZenithBlinkGhost"
				for _, d in ipairs(copy:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
						d.Transparency = d.Name == "HumanoidRootPart" and 1 or math.max(d.Transparency, 0.65)
					elseif d:IsA("BaseScript") or d:IsA("Humanoid") or d:IsA("Decal") or d:IsA("Highlight") or d:IsA("BillboardGui") then
						d:Destroy()
					end
				end
				copy.Parent = workspace
				m._mark = copy
			end
		end
	end,
	OnDisable = function(m)
		pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(100000) end)
		if m._mark then m._mark:Destroy(); m._mark = nil end
	end }

-- Fling: your physics body is given an enormous velocity for the physics step only, and your real velocity is put back
-- before anything is drawn. You move and look completely normal, but anyone who touches you is thrown away.
Module{ Name = "Fling", Category = "Player", Desc = "While it is on, anyone who touches you gets flung away. You move and look completely normal.",
	Settings = { Slider("Power", 1000, 100000, 1000, 10000, "How hard people are launched. Higher flings farther but is harder on your own connection.") },
	OnEnable = function(m)
		m._vel = Vector3.zero
		-- physics: right after the game updates, give the body a huge velocity
		Hook(m, RunService.Heartbeat, function()
			local r = Root(); if not r then return end
			m._vel = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = m._vel * m.Values.Power + Vector3.new(0, m.Values.Power, 0)
		end)
		-- before drawing and before the next physics step, put your real velocity back
		Hook(m, RunService.RenderStepped, function()
			local r = Root(); if r then r.AssemblyLinearVelocity = m._vel end
		end)
		Hook(m, RunService.Stepped, function()
			local r = Root(); if r then r.AssemblyLinearVelocity = m._vel + Vector3.new(0, 0.1, 0) end
		end)
	end,
	OnDisable = function(m)
		local r = Root()
		if r and m._vel then r.AssemblyLinearVelocity = m._vel end
	end }

Module{ Name = "AntiFling", Category = "Player", Desc = "Stops other players from flinging you: their bodies stop colliding with yours, and any sudden launch or spin is cancelled.",
	Settings = {
		Toggle("Ignore Players", true, "Turns off collision with every other player's body on your screen. This is what stops most flings. You also walk through players."),
		Toggle("Restore Position", true, "If you do get launched, you are put back where you were a moment ago."),
		Toggle("Heavy Body", false, "Makes your own body much denser so small hits barely move you."),
		Slider("Threshold", 50, 1000, 10, 250, "Speed (studs per second) above which your movement counts as a fling. Raise it if it interferes with Fly or Dash."),
	},
	OnEnable = function(m)
		m._safe, m._saveT, m._hv = nil, 0, 0
		-- every other player's body parts are listed once and kept up to date, so nothing is searched each frame
		m._parts = {}
		local function watch(p, c)
			local list = {}
			m._parts[p] = list
			for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then list[#list + 1] = d end end
			Hook(m, c.DescendantAdded, function(d) if d:IsA("BasePart") then list[#list + 1] = d end end)
		end
		local function track(p)
			if p == LP then return end
			if p.Character then watch(p, p.Character) end
			Hook(m, p.CharacterAdded, function(c) watch(p, c) end)
		end
		for _, p in ipairs(Players:GetPlayers()) do track(p) end
		Hook(m, Players.PlayerAdded, track)
		Hook(m, Players.PlayerRemoving, function(p) m._parts[p] = nil end)
		-- before physics each frame: other players can no longer push you
		Hook(m, RunService.Stepped, function()
			if not m.Values["Ignore Players"] then return end
			for _, list in pairs(m._parts) do
				for i = #list, 1, -1 do
					local part = list[i]
					if part.Parent == nil then table.remove(list, i)
					elseif part.CanCollide then part.CanCollide = false end
				end
			end
		end)
		-- after physics: undo anything that still got through
		Hook(m, RunService.Heartbeat, function()
			local r = Root(); if not r then return end
			local V = m.Values
			local now = tick()
			local lin, ang = r.AssemblyLinearVelocity, r.AssemblyAngularVelocity
			if lin.Magnitude > V.Threshold or ang.Magnitude > 50 then
				r.AssemblyLinearVelocity = Vector3.zero
				r.AssemblyAngularVelocity = Vector3.zero
				if V["Restore Position"] and m._safe then r.CFrame = m._safe end
			elseif now - m._saveT > 0.1 then
				m._safe, m._saveT = r.CFrame, now
			end
			-- density is only reapplied once a second (it also covers a fresh respawn)
			if V["Heavy Body"] and now - m._hv > 1 then
				m._hv = now
				local c = LP.Character
				if c then
					for _, part in ipairs(c:GetChildren()) do
						if part:IsA("BasePart") then part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0, 1, 1) end
					end
				end
			end
		end)
	end,
	OnDisable = function(m)
		m._parts = nil
		local c = LP.Character
		if c then
			for _, part in ipairs(c:GetChildren()) do
				if part:IsA("BasePart") then part.CustomPhysicalProperties = nil end
			end
		end
	end }

Module{ Name = "RespawnHere", Category = "Player", Desc = "After you die, you respawn at the spot where you died instead of the spawn point.",
	OnEnable = function(m)
		Hook(m, RunService.Heartbeat, function()
			local r, h = Root(), Hum()
			if r and h and h.Health > 0 then m._last = r.CFrame end
		end)
		Hook(m, LP.CharacterAdded, function(c)
			local pos = m._last; if not pos then return end
			local r = c:WaitForChild("HumanoidRootPart", 5)
			if r then task.wait(0.15); r.CFrame = pos end
		end)
	end }

Module{ Name = "Reset", Category = "Player", Desc = "Kills your character so you respawn right away.",
	Action = function()
		local h, c = Hum(), LP.Character
		if h then h.Health = 0 end
		if c then c:BreakJoints() end
	end }

----------------------------------------------------------------------
-- RENDER (all local, only you see these)
----------------------------------------------------------------------
-- team detection: Roblox teams first, then the usual custom setups (attributes, leaderstats/value objects, team folders)
local TeamNames = { "Team", "TeamName", "team", "teamName", "TeamColor", "Side", "Faction", "Squad", "Alliance" }
function ui.TeamKey(p)
	if p.Team then return "T:" .. p.Team.Name end
	local ch = p.Character
	for _, o in ipairs({ p, ch }) do
		for _, n in ipairs(TeamNames) do
			local v = o:GetAttribute(n)
			if v ~= nil then return "A:" .. tostring(v) end
		end
	end
	for _, o in ipairs({ p, p:FindFirstChild("leaderstats"), ch, p:FindFirstChild("PlayerData"), p:FindFirstChild("Data") }) do
		for _, n in ipairs(TeamNames) do
			local v = o:FindFirstChild(n)
			if v and v:IsA("ValueBase") then return "V:" .. tostring(v.Value) end
		end
	end
	local par = ch and ch.Parent
	if par and par ~= workspace and par:IsA("Folder") and not table.find({ "Players", "Characters", "Live", "Alive", "Entities", "Living" }, par.Name) then return "F:" .. par.Name end
	return nil
end
function ui.SameTeam(p)
	local ok, r = pcall(function()
		local a = ui.TeamKey(LP)
		return a ~= nil and a == ui.TeamKey(p)
	end)
	return ok and r
end
function ui.TeamColor(p)
	if p.Team then return p.TeamColor.Color end
	local k = ui.TeamKey(p)
	if not k then return WHITE end
	local h = 0
	for i = 1, #k do h = (h * 31 + k:byte(i)) % 997 end
	return Color3.fromHSV(h / 997, 0.7, 1)
end
local function ColorFor(p, mode, off)
	if mode == "Team" then return ui.TeamColor(p)
	elseif mode == "Rainbow" then return Color3.fromHSV((tick() * Themes.Speed * 1.2 + (off or 0)) % 1, 0.7, 1)
	elseif mode == "White" then return WHITE
	elseif mode == "Red" then return Color3.fromRGB(255, 60, 60) end
	return Accent()
end
local function Pass(m, p, root)
	if m.Values["Team Check"] and ui.SameTeam(p) then return false end
	local mr = Root()
	if mr and root and (root.Position - mr.Position).Magnitude > m.Values["Max Distance"] then return false end
	return true
end

local ESP = Module{ Name = "ESP", Category = "Render", Desc = "Draws a 2D box around every player, with an optional health bar.",
	Settings = {
		Mode("Color", ColorModes, "Accent", D_COLOR),
		Toggle("Health Bar", true, "Shows a health bar on the left side of each box."),
		Toggle("Team Check", false, D_TEAM),
		Slider("Max Distance", 100, 5000, 50, 2000, D_DIST),
	} }
local Names = Module{ Name = "NameTags", Category = "Render", Desc = "Shows each player's name above them, with optional distance and health.",
	Settings = {
		Mode("Color", ColorModes, "White", D_COLOR),
		Toggle("Show Distance", true, "Adds how far away the player is, in studs."),
		Toggle("Show Health", true, "Adds the player's current health."),
		Toggle("Team Check", false, D_TEAM),
		Slider("Max Distance", 100, 5000, 50, 2000, D_DIST),
	} }
local Tracers = Module{ Name = "Tracers", Category = "Render", Desc = "Draws a line from your screen to every player so you can always tell where they are.",
	Settings = {
		Mode("Origin", { "Bottom", "Center", "Mouse" }, "Bottom", "Where the lines start: bottom of the screen, center of the screen, or your mouse.", true),
		Slider("Thickness", 1, 5, 0.5, 1.5, "Line thickness in pixels."),
		Mode("Color", ColorModes, "Accent", D_COLOR),
		Toggle("Team Check", false, D_TEAM),
		Slider("Max Distance", 100, 5000, 50, 3000, D_DIST),
	} }

-- Through Walls chams: a copy of each player is drawn in a full-screen viewport that uses the same camera
ui.Ghost = { items = {} }
function ui.GhostClear()
	local G = ui.Ghost
	for p, it in pairs(G.items) do it.model:Destroy(); G.items[p] = nil end
	if G.vf then G.vf:Destroy(); G.vf, G.cam = nil, nil end
end
function ui.GhostUpdate(m)
	local G = ui.Ghost
	if not G.vf then
		G.vf = New("ViewportFrame", { Name = "ZenithGhost", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Ambient = Color3.new(1, 1, 1), LightColor = Color3.new(1, 1, 1) }, ui.Gui)
		G.cam = New("Camera", {}, G.vf)
		G.vf.CurrentCamera = G.cam
	end
	G.cam.CFrame, G.cam.FieldOfView = Camera.CFrame, Camera.FieldOfView
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local ch = p.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local it = G.items[p]
			if ch and root and Pass(m, p, root) then
				if not it or it.char ~= ch or not it.model.Parent then
					if it then it.model:Destroy(); G.items[p] = nil end
					local arch = ch.Archivable
					ch.Archivable = true
					local copy = ch:Clone()
					ch.Archivable = arch
					if copy then
						local origs, clones, pairsList = ch:GetDescendants(), copy:GetDescendants(), {}
						for i, o in ipairs(origs) do
							local c = clones[i]
							if c and o:IsA("BasePart") and c:IsA("BasePart") then
								c.Anchored, c.CanCollide = true, false
								table.insert(pairsList, { o, c })
							end
						end
						for _, d in ipairs(clones) do
							if d:IsA("BaseScript") or d:IsA("Humanoid") then d:Destroy() end
						end
						copy.Parent = G.vf
						it = { char = ch, model = copy, parts = pairsList }
						G.items[p] = it
					end
				end
				if it then
					for _, pr in ipairs(it.parts) do
						if pr[1].Parent then pr[2].CFrame = pr[1].CFrame end
					end
				end
			elseif it then
				it.model:Destroy(); G.items[p] = nil
			end
		end
	end
end

local ChamObjs = {}
do
local function ClearChams() for _, h in pairs(ChamObjs) do h:Destroy() end table.clear(ChamObjs) end
-- TabGUI: the classic hacked-client side menu. Up/Down move, Right or Enter goes deeper or switches a module,
-- Left or Backspace goes back. Mouse and touch work too. It takes over the arrow keys while it is on.
Module{ Name = "TabGUI", Category = "Render", Desc = "A small menu under the Roblox buttons you can drive with the arrow keys or clicks, to switch modules and change settings without opening the full menu.",
	OnEnable = function(m)
		m._lvl, m._ci, m._mi, m._si = 1, 1, 1, 1
		local W, H = 124, 22
		local root = New("Frame", { Name = "ZenithTabGui", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 2 }, ui.Gui)
		New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, root)
		m._root = root
		local rows = {}
		local function curMods() return ByCat[Categories[m._ci]] or {} end
		local function curSets()
			local mod = curMods()[m._mi]
			return mod and mod.Settings or {}
		end
		local function valText(mod, st)
			local v = mod.Values[st.Name]
			if st.Type == "Toggle" then return v and "on" or "off" end
			if st.Type == "Slider" then return tostring(math.floor(v * 100 + 0.5) / 100) end
			if st.Type == "Mode" then return tostring(v) end
			if st.Type == "Button" then return "run" end
			return ""
		end
		local function column(order, padRows, width)
			local holder = New("Frame", { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, LayoutOrder = order }, root)
			New("UIPadding", { PaddingTop = UDim.new(0, padRows * H) }, holder)
			local col = New("Frame", { Size = UDim2.fromOffset(width, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C_HEAD, BackgroundTransparency = 0.12, BorderSizePixel = 0 }, holder)
			New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, col)
			return col
		end
		local function row(col, level, i, text)
			local b = New("TextButton", { Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = i }, col)
			local bar = New("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Visible = false }, b)
			local l = New("TextLabel", { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, b)
			local r = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(54, H), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C_DIM }, b)
			local rec = { b = b, bar = bar, l = l, r = r, col = level, i = i }
			table.insert(rows, rec)
			return rec
		end
		local function adjust(mod, st, dir)
			local v = mod.Values[st.Name]
			if st.Type == "Button" then Safe(st.Fn, mod) return end
			if st.Type == "Toggle" then mod.Values[st.Name] = not v
			elseif st.Type == "Slider" then
				-- Enter steps the slider up and wraps back to the start at the top
				local hi, nv = ui.MaxOf(st), v + dir * st.Step
				if nv > hi + 1e-6 then nv = st.Min elseif nv < st.Min then nv = hi end
				mod.Values[st.Name] = tonumber(string.format("%.4f", nv))
			elseif st.Type == "Mode" then
				local o = type(st.Options) == "function" and st.Options() or st.Options
				local idx = table.find(o, v) or 0
				mod.Values[st.Name] = o[((idx - 1 + dir) % #o) + 1]
			else return end
			if mod.OnChanged then Safe(mod.OnChanged, mod, st.Name) end
			ui.RebuildList(); ui.RefreshSliders(); Repaint()
		end
		function m._color()
			local acc = Accent()
			for _, rec in ipairs(rows) do
				local sel = (rec.col == 1 and rec.i == m._ci) or (rec.col == 2 and rec.i == m._mi) or (rec.col == 3 and rec.i == m._si)
				local active = rec.col == m._lvl
				rec.b.BackgroundTransparency = sel and 0.15 or 1
				rec.b.BackgroundColor3 = acc:Lerp(Color3.new(0, 0, 0), active and 0.5 or 0.78)
				rec.bar.Visible = sel and active
				rec.bar.BackgroundColor3 = acc
				local on = rec.mod and rec.mod.Enabled and not rec.mod.Action and not rec.mod.Passive
				rec.l.TextColor3 = (sel and active) and WHITE or (on and acc or C_LIGHT)
				if rec.st then rec.r.Text = valText(rec.mod, rec.st) end
			end
		end
		function m._build()
			for _, c in ipairs(root:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
			rows = {}
			local c1 = column(1, 0, W)
			for i, cat in ipairs(Categories) do
				local rec = row(c1, 1, i, cat)
				rec.b.MouseButton1Click:Connect(function() m._ci, m._mi, m._lvl = i, 1, 2; m._build() end)
			end
			if m._lvl >= 2 then
				local mods = curMods()
				local c2 = column(2, m._ci - 1, W + 8)
				for i, mod in ipairs(mods) do
					local rec = row(c2, 2, i, mod.Name)
					rec.mod = mod
					rec.b.MouseButton1Click:Connect(function() m._mi, m._lvl = i, 2; if mod.Passive then m._lvl, m._si = 3, 1 else ToggleModule(mod) end m._build() end)
					if mod.Settings and #mod.Settings > 0 then
						rec.r.Text = ">"
						local a = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(26, H), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, rec.b)
						a.MouseButton1Click:Connect(function() m._mi, m._lvl, m._si = i, 3, 1; m._build() end)
					end
				end
			end
			if m._lvl >= 3 then
				local mod = curMods()[m._mi]
				if mod then
					local c3 = column(3, (m._ci - 1) + (m._mi - 1), W + 64)
					for i, st in ipairs(mod.Settings or {}) do
						local rec = row(c3, 3, i, st.Name)
						rec.mod, rec.st = mod, st
						rec.b.MouseButton1Click:Connect(function() m._si, m._lvl = i, 3; adjust(mod, st, 1); m._build() end)
						rec.b.MouseButton2Click:Connect(function() m._si, m._lvl = i, 3; adjust(mod, st, -1); m._build() end)
					end
				end
			end
			m._color()
		end
		local function wrap(v, n) return n > 0 and ((v - 1) % n) + 1 or 1 end
		function m._key(key)
			local K = Enum.KeyCode
			local mods = curMods()
			if m._lvl == 1 then
				if key == K.Up then m._ci = wrap(m._ci - 1, #Categories); m._mi = 1
				elseif key == K.Down then m._ci = wrap(m._ci + 1, #Categories); m._mi = 1
				elseif key == K.Right or key == K.Return then if #mods > 0 then m._lvl = 2 end end
			elseif m._lvl == 2 then
				local mod = mods[m._mi]
				if key == K.Up then m._mi = wrap(m._mi - 1, #mods)
				elseif key == K.Down then m._mi = wrap(m._mi + 1, #mods)
				elseif key == K.Left or key == K.Backspace then m._lvl = 1
				elseif key == K.Return and mod then if mod.Passive then m._lvl, m._si = 3, 1 else ToggleModule(mod) end
				elseif key == K.Right and mod then
					if mod.Settings and #mod.Settings > 0 then m._lvl, m._si = 3, 1 elseif not mod.Passive then ToggleModule(mod) end
				end
			else
				local mod, sets = mods[m._mi], curSets()
				local st = sets[m._si]
				if key == K.Up then m._si = wrap(m._si - 1, #sets)
				elseif key == K.Down then m._si = wrap(m._si + 1, #sets)
				elseif key == K.Backspace or key == K.Left then m._lvl = 2
				elseif key == K.Return and st then adjust(mod, st, 1)
				end
			end
			m._build()
		end
		AddPainter(root, function() if m._color then m._color() end end)
		m._build()
		-- the arrow keys belong to this menu while it is on
		game:GetService("ContextActionService"):BindActionAtPriority("ZenithTabGui", function(_, state, input)
			if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			if state == Enum.UserInputState.Begin then m._key(input.KeyCode) end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Return, Enum.KeyCode.Backspace)
	end,
	OnDisable = function(m)
		pcall(function() game:GetService("ContextActionService"):UnbindAction("ZenithTabGui") end)
		if m._root then m._root:Destroy(); m._root = nil end
		m._build, m._color, m._key = nil, nil, nil
	end }

Module{ Name = "Chams", Category = "Render", Desc = "Highlights players with a glowing fill and outline that shows through walls.",
	Settings = {
		Mode("Style", { "Highlight", "Through Walls" }, "Highlight", "Highlight fills players with color. Through Walls redraws each player's real character on top of everything, so you see them as they look instead of a colored shape."),
		Mode("Color", ColorModes, "Accent", D_COLOR),
		Slider("Fill", 0, 1, 0.05, 0.6, "How strong the colored fill is. 0 shows only the outline."),
		Toggle("Outline", true, "Draws a solid outline around each player."),
		Toggle("Visible Only", false, "Only highlights parts of players that are not hidden behind walls."),
		Toggle("Team Check", false, D_TEAM),
		Slider("Max Distance", 100, 5000, 50, 3000, D_DIST),
	},
	OnDisable = function() ClearChams(); ui.GhostClear() end,
	OnRender = function(m)
		if m.Values.Style == "Through Walls" then
			ClearChams()
			ui.GhostUpdate(m)
			return
		end
		ui.GhostClear()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then
				local ch = p.Character
				local root = ch and ch:FindFirstChild("HumanoidRootPart")
				local h = ChamObjs[p]
				if ch and root and Pass(m, p, root) then
					if not h or h.Parent ~= ch then
						if h then h:Destroy() end
						h = New("Highlight", {}, ch); ChamObjs[p] = h
					end
					local c = ColorFor(p, m.Values.Color)
					h.FillColor, h.OutlineColor = c, c
					h.FillTransparency = 1 - m.Values.Fill
					h.OutlineTransparency = m.Values.Outline and 0 or 1
					h.DepthMode = m.Values["Visible Only"] and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
				elseif h then h:Destroy(); ChamObjs[p] = nil end
			end
		end
	end }
end

-- Xray: every world part turns see-through; the original transparency is remembered so it can be put back
ui.Xray = {}
function ui.XrayApply(level)
	for part, orig in pairs(ui.Xray) do
		if part.Parent then part.Transparency = math.max(orig, level) else ui.Xray[part] = nil end
	end
end
do
local function XrayTake(d, level)
	if d:IsA("BasePart") and d.ClassName ~= "Terrain" and not d:FindFirstAncestorOfClass("Model") then
		ui.Xray[d] = d.Transparency
		d.Transparency = math.max(d.Transparency, level)
	elseif d:IsA("BasePart") and d.ClassName ~= "Terrain" then
		local mdl = d:FindFirstAncestorOfClass("Model")
		-- skip anything that belongs to a character
		if not (mdl and mdl:FindFirstChildOfClass("Humanoid")) then
			ui.Xray[d] = d.Transparency
			d.Transparency = math.max(d.Transparency, level)
		end
	end
end
Module{ Name = "Xray", Category = "Render", Desc = "Makes the world see-through so you can see what is behind walls.",
	Settings = { Slider("Transparency", 0.1, 0.95, 0.05, 0.6, "How see-through everything becomes. Parts that were already more see-through stay as they are.") },
	OnChanged = function(m) ui.XrayApply(m.Values.Transparency) end,
	OnEnable = function(m)
		local level = m.Values.Transparency
		task.spawn(function()
			local n = 0
			for _, d in ipairs(workspace:GetDescendants()) do
				if not m.Enabled then return end
				XrayTake(d, m.Values.Transparency)
				n += 1
				if n % 400 == 0 then task.wait() end
			end
		end)
		Hook(m, workspace.DescendantAdded, function(d) XrayTake(d, m.Values.Transparency) end)
	end,
	OnDisable = function(m)
		for part, orig in pairs(ui.Xray) do
			if part.Parent then part.Transparency = orig end
		end
		ui.Xray = {}
	end }
end

do
local LightOrig = {}
Module{ Name = "Fullbright", Category = "Render", Desc = "Makes everything fully lit and removes shadows so dark areas are easy to see.",
	OnEnable = function()
		LightOrig = { Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient }
	end,
	OnDisable = function()
		if #LightOrig > 0 then
			Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(LightOrig)
		end
	end,
	OnTick = function()
		Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows = 2, 14, false
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190), Color3.fromRGB(190, 190, 190)
	end }
end

Module{ Name = "NoFog", Category = "Render", Desc = "Removes fog and atmospheric haze for a clear view into the distance.",
	OnEnable = function(m)
		m._fog = { Lighting.FogStart, Lighting.FogEnd }
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		m._atm = a and { a.Density, a.Haze }
	end,
	OnDisable = function(m)
		Lighting.FogStart, Lighting.FogEnd = m._fog[1], m._fog[2]
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a and m._atm then a.Density, a.Haze = m._atm[1], m._atm[2] end
	end,
	OnTick = function()
		Lighting.FogStart, Lighting.FogEnd = 1e8, 1e9
		local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a then a.Density = 0; a.Haze = 0 end
	end }

Module{ Name = "TimeChanger", Category = "Render", Desc = "Locks the time of day on your screen, no matter what the server does.",
	Settings = { Slider("Time", 0, 24, 0.25, 12, "Hour of the day from 0 to 24. 12 is noon, 0 and 24 are midnight.") },
	OnEnable = function(m) m._orig = Lighting.ClockTime end,
	OnDisable = function(m) Lighting.ClockTime = m._orig end,
	OnTick = function(m) Lighting.ClockTime = m.Values.Time end }

local Zoom
do
local FOVm = Module{ Name = "FOV", Category = "Render", Desc = "Changes your camera's field of view. Higher values show more of the world.",
	Settings = { Slider("FOV", 30, 120, 1, 90, "Field of view in degrees. Roblox's default is 70.") },
	OnDisable = function() Camera.FieldOfView = ui.Def.FOV end,
	OnRender = function(m)
		if Zoom and Zoom._active then return end
		Camera.FieldOfView = m.Values.FOV
	end }

Zoom = Module{ Name = "Zoom", Category = "Render", Desc = "Hold a key (or the ZOOM button on mobile) to zoom the camera in smoothly, release it to zoom back out.",
	Settings = {
		Mode("Key", { "C", "Z", "X", "V" }, "C", "The key you hold to zoom."),
		Slider("Zoom FOV", 10, 60, 1, 20, "Field of view while zoomed. Lower numbers zoom in more."),
	},
	OnEnable = function(m) if UIS.TouchEnabled then m._tz = ui.TouchBtn("ZOOM", 3) end end,
	OnDisable = function(m)
		ui.DropTouch(m._tz); m._tz = nil
		m._active = false; Camera.FieldOfView = FOVm.Enabled and FOVm.Values.FOV or ui.Def.FOV
	end,
	OnRender = function(m, dt)
		local zooming = Down(Enum.KeyCode[m.Values.Key]) or (m._tz ~= nil and m._tz.held)
		local base = FOVm.Enabled and FOVm.Values.FOV or ui.Def.FOV
		if zooming then m._active = true end
		if not m._active then return end
		local target = zooming and m.Values["Zoom FOV"] or base
		Camera.FieldOfView += (target - Camera.FieldOfView) * math.min(1, dt * 12)
		if not zooming and math.abs(Camera.FieldOfView - base) < 0.2 then Camera.FieldOfView = base; m._active = false end
	end }
end

do
local CrossFrames
Module{ Name = "Crosshair", Category = "Render", Desc = "Draws a custom crosshair in the center of your screen.",
	Settings = {
		Slider("Length", 2, 30, 1, 8, "Length of each crosshair line in pixels."),
		Slider("Gap", 0, 20, 1, 4, "Empty space in the middle of the crosshair in pixels."),
		Slider("Thickness", 1, 6, 1, 2, "Thickness of the lines in pixels."),
		Toggle("Center Dot", false, "Adds a small dot in the exact center."),
	},
	OnEnable = function()
		local holder = New("Frame", { Name = "Crosshair", BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new() }, ui.Gui)
		CrossFrames = { Holder = holder }
		for _, n in ipairs({ "Up", "Down", "Left", "Right", "Dot" }) do
			CrossFrames[n] = New("Frame", { BorderSizePixel = 0 }, holder)
		end
	end,
	OnDisable = function() if CrossFrames then CrossFrames.Holder:Destroy(); CrossFrames = nil end end,
	OnRender = function(m)
		if not CrossFrames then return end
		local L, g, t = m.Values.Length, m.Values.Gap, m.Values.Thickness
		local F, c = CrossFrames, Accent()
		F.Up.AnchorPoint, F.Up.Position, F.Up.Size = Vector2.new(0.5, 1), UDim2.fromOffset(0, -g), UDim2.fromOffset(t, L)
		F.Down.AnchorPoint, F.Down.Position, F.Down.Size = Vector2.new(0.5, 0), UDim2.fromOffset(0, g), UDim2.fromOffset(t, L)
		F.Left.AnchorPoint, F.Left.Position, F.Left.Size = Vector2.new(1, 0.5), UDim2.fromOffset(-g, 0), UDim2.fromOffset(L, t)
		F.Right.AnchorPoint, F.Right.Position, F.Right.Size = Vector2.new(0, 0.5), UDim2.fromOffset(g, 0), UDim2.fromOffset(L, t)
		F.Dot.AnchorPoint, F.Dot.Size, F.Dot.Visible = Vector2.new(0.5, 0.5), UDim2.fromOffset(t, t), m.Values["Center Dot"]
		for _, n in ipairs({ "Up", "Down", "Left", "Right", "Dot" }) do F[n].BackgroundColor3 = c end
	end }
end

local fpsAvg = 60
local function GetPing()
	local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
	return ok and math.floor(v) or 0
end
local HUDm
HUDm = Module{ Name = "HUD", Category = "Render", Desc = "Shows the Zenith title above the array list and FPS, ping and coordinates in the bottom left.",
	Settings = {
		Toggle("Watermark", true, "Shows the Zenith title above the array list."),
		Toggle("FPS", true, "Shows your frames per second in the bottom left."),
		Toggle("Ping", true, "Shows your ping in the bottom left."),
		Toggle("Coords", true, "Shows your X, Y and Z position in the bottom left."),
		Toggle("Speed", true, "Shows how fast your character is moving, in studs per second."),
		Toggle("Real Speed", true, "Shows your real speed from how far you actually moved each frame, so teleports and CFrame movement count too."),
		Slider("Text Size", 11, 24, 1, 14, "Size of the bottom left text."),
		Toggle("Theme Accent", true, "Uses your theme color for the title and info bar. Picking a Watermark Color turns this off."),
		ColorSet("Watermark Color", Color3.fromRGB(160, 90, 255), "Color of the title and info bar. Only used when Theme Accent is off."),
		ColorSet("Text Color", Color3.new(1, 1, 1), "Color of the FPS, ping and coordinates text."),
		ColorSet("Background Color", Color3.new(0, 0, 0), "Color of the boxes behind the HUD text."),
		Slider("Background Opacity", 0, 1, 0.05, 0.55, "How solid the boxes behind the text are."),
	},
	OnChanged = function(m, name)
		if name == "Watermark Color" and m.Values["Theme Accent"] then
			m.Values["Theme Accent"] = false
			Repaint()
		end
	end,
	OnEnable = function(m)
		-- title: sits at the top of the same right-aligned column as the array list
		local wm = New("Frame", { Name = "Watermark", Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, LayoutOrder = 0 }, ui.TopRight)
		local wmLabel = New("TextLabel", { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = FONT_B, TextSize = 20, RichText = true, Text = "" }, wm)
		local wmLogo = ui.DrawLogo(wm, 18)
		wmLogo.Position = UDim2.fromOffset(7, 5)
		New("UIPadding", { PaddingLeft = UDim.new(0, wmLogo.Size.X.Offset + 13), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 5) }, wmLabel)
		local wmLine = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, wm)
		-- clicking the title opens / closes the menu
		local wmBtn = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5 }, wm)
		wmBtn.MouseButton1Click:Connect(function() if ui.SetMenu then ui.SetMenu(not ui.MenuOpen) end end)
		ui.AddHover(wmBtn, function() return ui.HoverText(CLIENT, "Click to open or close the menu.") end, wmBtn)

		-- info box: bottom left
		local info = New("Frame", { Name = "Info", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, ui.Gui)
		local bar = New("Frame", { Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0 }, info)
		local label = New("TextLabel", { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, info)
		New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, label)
		m._wm, m._wmLabel, m._wmLine, m._info, m._bar, m._label = wm, wmLabel, wmLine, info, bar, label
	end,
	OnDisable = function(m)
		if m._wm then m._wm:Destroy() end
		if m._info then m._info:Destroy() end
		m._wm, m._wmLabel, m._wmLine, m._info, m._bar, m._label = nil, nil, nil, nil, nil, nil
	end,
	OnRender = function(m, dt)
		if not m._info then return end
		local V = m.Values
		fpsAvg += (1 / math.max(dt, 1e-4) - fpsAvg) * 0.05
		local main = V["Theme Accent"] and Accent() or V["Watermark Color"]
		local bg, tr = V["Background Color"], 1 - V["Background Opacity"]

		m._wm.Visible = V.Watermark
		m._wm.BackgroundColor3, m._wm.BackgroundTransparency = bg, tr
		m._wmLine.BackgroundColor3 = main
		m._wmLabel.Text = ("<font color=\"%s\">%s</font> <font color=\"rgb(150,150,165)\" size=\"14\">%s</font>"):format(Rgb(main), CLIENT, VERSION)

		local lines = {}
		if V.FPS then table.insert(lines, "FPS  " .. math.floor(fpsAvg)) end
		if V.Ping then table.insert(lines, "Ping " .. GetPing() .. "ms") end
		if V.Speed then
			local r = Root()
			if r then
				m._spd = (m._spd or 0) + (r.AssemblyLinearVelocity.Magnitude - (m._spd or 0)) * math.min(1, dt * 12)
				table.insert(lines, ("Speed %.1f"):format(m._spd))
			end
		end
		if V["Real Speed"] then
			local r = Root()
			if r then
				local pos = r.Position
				if m._lp and dt > 0 then
					local raw = (pos - m._lp).Magnitude / dt
					m._rs = (m._rs or 0) + (raw - (m._rs or 0)) * math.min(1, dt * 10)
				end
				m._lp = pos
				table.insert(lines, ("Real Speed %.1f"):format(m._rs or 0))
			end
		else
			m._lp = nil
		end
		if V.Coords then
			local r = Root()
			if r then
				local p = r.Position
				table.insert(lines, ("XYZ  %d, %d, %d"):format(math.floor(p.X), math.floor(p.Y), math.floor(p.Z)))
			end
		end
		m._info.Visible = #lines > 0
		m._info.BackgroundColor3, m._info.BackgroundTransparency = bg, tr
		m._bar.BackgroundColor3 = main
		m._label.TextSize = V["Text Size"]
		m._label.TextColor3 = V["Text Color"]
		m._label.Text = table.concat(lines, "\n")
	end }

Module{ Name = "CamDistance", Category = "Render", Desc = "Removes the limit on how far you can zoom the camera in and out.",
	Settings = {
		Slider("Max Zoom", 20, 2000, 10, 500, "Farthest the camera can zoom out, in studs."),
		Slider("Min Zoom", 0, 20, 0.5, 0.5, "Closest the camera can zoom in. 0 allows first person."),
	},
	OnEnable = function(m) m._o = { LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance } end,
	OnDisable = function(m) LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance = ui.Def.MaxZoom or m._o[1], ui.Def.MinZoom or m._o[2] end,
	OnTick = function(m) LP.CameraMaxZoomDistance, LP.CameraMinZoomDistance = m.Values["Max Zoom"], m.Values["Min Zoom"] end }

Module{ Name = "Freecam", Category = "Render", Desc = "Detaches the camera so you can fly around and look without moving your character. WASD to move, Q and E for down and up, hold right mouse to look, Shift to go faster. On mobile use the stick, the UP and DOWN buttons and drag the screen to look.",
	Settings = {
		Slider("Speed", 5, 300, 1, 50, "How fast the camera flies. Hold Shift for 3x."),
		Toggle("Freeze Character", true, "Anchors your character in place while the camera is detached. Applies when you enable Freecam."),
	},
	OnEnable = function(m)
		local x, y = Camera.CFrame:ToOrientation()
		m._pitch, m._yaw, m._pos = x, y, Camera.CFrame.Position
		Camera.CameraType = Enum.CameraType.Scriptable
		local r = Root()
		m._anch = nil
		if r and m.Values["Freeze Character"] then m._anch = r.Anchored; r.Anchored = true end
		if UIS.TouchEnabled then
			m._tUp, m._tDn = ui.TouchBtn("UP", 1), ui.TouchBtn("DOWN", 0)
			-- drag any free spot on the screen to look around
			Hook(m, UIS.InputChanged, function(i, gp)
				if i.UserInputType == Enum.UserInputType.Touch and not gp and not ui.MenuOpen then
					m._yaw -= i.Delta.X * math.rad(0.3)
					m._pitch = math.clamp(m._pitch - i.Delta.Y * math.rad(0.3), -1.5, 1.5)
				end
			end)
		end
	end,
	OnDisable = function(m)
		ui.DropTouch(m._tUp); ui.DropTouch(m._tDn); m._tUp, m._tDn = nil, nil
		Camera.CameraType = Enum.CameraType.Custom
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		local r, h = Root(), Hum()
		if r and m._anch ~= nil then r.Anchored = m._anch end
		if h then Camera.CameraSubject = h end
	end,
	OnRender = function(m, dt)
		-- hold right mouse to look: the cursor is pinned in place and its movement turns the camera
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not ui.MenuOpen and not Typing() then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local d = UIS:GetMouseDelta()
			m._yaw -= d.X * math.rad(0.3)
			m._pitch = math.clamp(m._pitch - d.Y * math.rad(0.3), -1.5, 1.5)
			m._looking = true
		elseif m._looking then
			m._looking = false
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
		local rot = CFrame.fromOrientation(m._pitch, m._yaw, 0)
		local dir = Vector3.zero
		if Down(Enum.KeyCode.W) then dir += rot.LookVector end
		if Down(Enum.KeyCode.S) then dir -= rot.LookVector end
		if Down(Enum.KeyCode.D) then dir += rot.RightVector end
		if Down(Enum.KeyCode.A) then dir -= rot.RightVector end
		if Down(Enum.KeyCode.E) then dir += Vector3.yAxis end
		if Down(Enum.KeyCode.Q) then dir -= Vector3.yAxis end
		local mv = ui.MoveVec()
		dir += rot.RightVector * mv.X + rot.LookVector * mv.Y
		if m._tUp and m._tUp.held then dir += Vector3.yAxis end
		if m._tDn and m._tDn.held then dir -= Vector3.yAxis end
		local sp = m.Values.Speed * (Down(Enum.KeyCode.LeftShift) and 3 or 1)
		if dir.Magnitude > 0 then m._pos += dir.Unit * sp * dt end
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = CFrame.new(m._pos) * rot
	end }

----------------------------------------------------------------------
-- COMBAT (everything here only changes your own client)
----------------------------------------------------------------------
local FOVc
local AimState = { active = 0, locked = 0 }

-- where you are aiming on screen: the screen center while the mouse is locked, otherwise your cursor
local function CenterMode(follow)
	return follow == "Center" or (follow ~= "Mouse" and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter)
end

-- where you are aiming on screen, in raw screen space. While the mouse is locked this is the engine's own
-- crosshair position, otherwise it is your cursor. "Center" forces the middle of the viewport.
local function AimPoint(follow)
	if follow == "Center" or ui.Phone then return Camera.ViewportSize / 2 end
	return UIS:GetMouseLocation()
end

-- center of the FOV circle: same as AimPoint, plus the optional Offset Y nudge (drawing and targeting only)
local function FovCenter()
	local f = FOVc.Values.Follow
	local c = AimPoint(f)
	if CenterMode(f) then c += Vector2.new(0, FOVc.Values["Offset Y"]) end
	return c
end

local function Held(mode)
	if mode == "Always" then return true end
	if UIS.TouchEnabled then
		-- no right mouse button on a phone: a shared AIM button stands in for it
		if not ui.AimBtn then ui.AimBtn = ui.TouchBtn("AIM", 4) end
		ui.AimBtn.btn.Visible = true
		if ui.AimBtn.held then return true end
	end
	local b = mode == "Hold Left Mouse" and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2
	return UIS:IsMouseButtonPressed(b)
end

local function AimSettings(list)
	table.insert(list, Mode("Aim Part", { "Head", "Torso" }, "Head", "Which part of the player to aim at."))
	table.insert(list, Mode("Priority", { "Crosshair", "Distance" }, "Crosshair", "Crosshair picks the player closest to where you aim. Distance picks the nearest player."))
	table.insert(list, Toggle("Use FOV", true, "Only targets players inside the FOV Circle. Turn it off to target anyone on screen."))
	table.insert(list, Toggle("Visible Check", true, "Ignores players hidden behind walls."))
	table.insert(list, Toggle("Team Check", true, D_TEAM))
	table.insert(list, Slider("Max Distance", 50, 2000, 50, 500, D_DIST))
	table.insert(list, Slider("Prediction", 0, 0.5, 0.01, 0, "Aims ahead of moving players by this many seconds."))
	return list
end

-- best player for an aim module right now, or nil. prefer = last target (kept a little longer so it doesn't flicker)
local function FindTarget(m, prefer)
	local V = m.Values
	local origin = Camera.CFrame.Position
	local center = FovCenter()
	local radius = FOVc.Values.Radius
	local best, bestScore
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and not (V["Team Check"] and ui.SameTeam(p)) then
			local ch = p.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local part = ch and (V["Aim Part"] == "Head" and ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
			if hum and part and hum.Health > 0 then
				local dist = (part.Position - origin).Magnitude
				if dist <= V["Max Distance"] then
					local v = Camera:WorldToViewportPoint(part.Position)
					if v.Z > 0 then
						local sd = (Vector2.new(v.X, v.Y) - center).Magnitude
						if not V["Use FOV"] or sd <= radius then
							local clear = true
							if V["Visible Check"] then
								local rp = RayParams()
								rp.FilterDescendantsInstances = { LP.Character, ch }
								clear = workspace:Raycast(origin, part.Position - origin, rp) == nil
							end
							if clear then
								local score = V.Priority == "Distance" and dist or sd
								if p == prefer then score *= 0.6 end
								if not bestScore or score < bestScore then
									best, bestScore = { player = p, part = part }, score
								end
							end
						end
					end
				end
			end
		end
	end
	return best
end

local function TargetPos(t, pred)
	return t.part.Position + t.part.AssemblyLinearVelocity * pred
end

-- turns the camera toward pos by a fraction (alpha) of the remaining angle, capped at maxStep radians
local function AimCamera(pos, alpha, maxStep)
	local camCF = Camera.CFrame
	local from = camCF.Position
	local want = pos - from
	if want.Magnitude < 0.01 then return end
	want = want.Unit
	local c = AimPoint(FOVc.Values.Follow)
	local cur = Camera:ViewportPointToRay(c.X, c.Y).Direction
	local ang = math.acos(math.clamp(cur:Dot(want), -1, 1))
	if ang < 0.0005 then return end
	local axis = cur:Cross(want)
	if axis.Magnitude < 1e-6 then return end
	local step = ang * alpha
	if maxStep then step = math.min(step, maxStep) end
	Camera.CFrame = CFrame.new(from) * CFrame.fromAxisAngle(axis.Unit, step) * camCF.Rotation
end

-- hitbox visualizer -------------------------------------------------
do
local VizObjs = {}
local function VizClear() for _, a in pairs(VizObjs) do a:Destroy() end table.clear(VizObjs) end
Module{ Name = "Hitbox Visualizer", Category = "Combat", Desc = "Draws a box around each player's real hitbox so you can see how big it is.",
	Settings = {
		Mode("Parts", { "Root", "Head", "Both", "Full Body" }, "Root", "Which parts of each player get a box."),
		Mode("Color", ColorModes, "Red", D_COLOR),
		Slider("Transparency", 0, 1, 0.05, 0.6, "How see-through the boxes are."),
		Toggle("Through Walls", true, "Shows the boxes even when the player is behind something."),
		Toggle("Team Check", false, D_TEAM),
		Slider("Max Distance", 100, 5000, 50, 1000, D_DIST),
	},
	OnDisable = VizClear,
	OnRender = function(m)
		local V, wanted = m.Values, {}
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p ~= LP and p.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if root and Pass(m, p, root) then
				local list, mode = {}, V.Parts
				if mode == "Root" or mode == "Both" then table.insert(list, root) end
				if mode == "Head" or mode == "Both" then
					local h = ch:FindFirstChild("Head")
					if h then table.insert(list, h) end
				end
				if mode == "Full Body" then
					for _, o in ipairs(ch:GetChildren()) do if o:IsA("BasePart") then table.insert(list, o) end end
				end
				local col = ColorFor(p, V.Color)
				for _, part in ipairs(list) do
					wanted[part] = true
					local a = VizObjs[part]
					if not a or a.Parent ~= part then
						if a then a:Destroy() end
						a = New("BoxHandleAdornment", { Name = "ZenithHitbox", Adornee = part }, part)
						VizObjs[part] = a
					end
					a.Size, a.Color3, a.Transparency = part.Size, col, V.Transparency
					a.AlwaysOnTop, a.ZIndex = V["Through Walls"], 1
				end
			end
		end
		for part, a in pairs(VizObjs) do
			if not wanted[part] then a:Destroy(); VizObjs[part] = nil end
		end
	end }
end

-- hitbox expander ---------------------------------------------------
do
local HB = {}
local function HBRestorePart(part)
	local o = HB[part]
	if o and part.Parent then
		part.Size, part.Transparency, part.CanCollide, part.Massless = o.Size, o.Transparency, o.CanCollide, o.Massless
	end
	HB[part] = nil
end
local function HBRestoreAll() for part in pairs(HB) do HBRestorePart(part) end end
Module{ Name = "Hitbox Expander", Category = "Combat", Desc = "Makes other players' hitboxes bigger on your client so they are easier to hit.",
	Settings = {
		Mode("Part", { "Root", "Head" }, "Root", "Which part of each player gets enlarged."),
		Slider("Size", 2, 40, 0.5, 8, "Width, height and depth of the enlarged hitbox in studs."),
		Slider("Transparency", 0, 1, 0.05, 0.7, "How see-through the enlarged part is."),
		Toggle("Team Check", true, D_TEAM),
	},
	OnDisable = function(m) m._part = nil; HBRestoreAll() end,
	OnTick = function(m)
		local V, wanted = m.Values, {}
		if m._part ~= V.Part then HBRestoreAll(); m._part = V.Part end
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p ~= LP and p.Character
			if ch and not (V["Team Check"] and ui.SameTeam(p)) then
				local hum = ch:FindFirstChildOfClass("Humanoid")
				local part = ch:FindFirstChild(V.Part == "Head" and "Head" or "HumanoidRootPart")
				if part and hum and hum.Health > 0 then
					wanted[part] = true
					if not HB[part] then
						HB[part] = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Massless = part.Massless }
					end
					part.Size = Vector3.new(V.Size, V.Size, V.Size)
					part.Transparency = V.Transparency
					part.CanCollide = false
					part.Massless = true
				end
			end
		end
		for part in pairs(HB) do
			if not wanted[part] then HBRestorePart(part) end
		end
	end }
end

-- fov circle --------------------------------------------------------
FOVc = Module{ Name = "FOV Circle", Category = "Combat", Desc = "Draws a circle on screen. Aim Assist and Aimbot only target players inside it.",
	Settings = {
		Slider("Radius", 20, 600, 5, 140, "Size of the circle in pixels. The aim modules use this as their targeting area."),
		Mode("Follow", { "Auto", "Center", "Mouse" }, "Auto", "Auto sits on your cursor, or the screen center while your mouse is locked."),
		Slider("Offset Y", -150, 150, 1, 0, "Moves the circle up or down in pixels if it does not line up with your crosshair. Only used when the circle sits on the screen center."),
		Slider("Thickness", 1, 6, 0.5, 1.5, "Line thickness in pixels."),
		Mode("Color", { "Accent", "White", "Red" }, "Accent", "Color of the circle."),
		Toggle("Filled", false, "Tints the inside of the circle."),
		Toggle("Highlight On Target", true, "Turns the circle red while an aim module has a target."),
		Toggle("Only When Aiming", false, "Hides the circle until an aim module is actually active."),
	},
	OnEnable = function(m)
		m._circle = New("Frame", { Name = "FOVCircle", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, ui.Gui)
		New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, m._circle)
		m._stroke = New("UIStroke", { Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, m._circle)
	end,
	OnDisable = function(m)
		if m._circle then m._circle:Destroy() end
		m._circle, m._stroke = nil, nil
	end,
	OnRender = function(m)
		local c, V = m._circle, m.Values
		if not c then return end
		c.Visible = not V["Only When Aiming"] or tick() - AimState.active < 0.15
		local center, r = FovCenter(), V.Radius
		c.Position = UDim2.fromOffset(center.X, center.Y)
		c.Size = UDim2.fromOffset(r * 2, r * 2)
		c.BackgroundTransparency = V.Filled and 0.88 or 1
		local col
		if V["Highlight On Target"] and tick() - AimState.locked < 0.15 then col = Color3.fromRGB(255, 70, 80)
		elseif V.Color == "White" then col = WHITE
		elseif V.Color == "Red" then col = Color3.fromRGB(255, 60, 60)
		else col = Accent() end
		c.BackgroundColor3, m._stroke.Color, m._stroke.Thickness = col, col, V.Thickness
	end }

-- aim assist --------------------------------------------------------
Module{ Name = "Aim Assist", Category = "Combat", Desc = "Gently pulls your camera toward players near your aim. You can still overpower it with your mouse.",
	Settings = AimSettings({
		Mode("Activate", { "Always", "Hold Right Mouse", "Hold Left Mouse" }, "Always", "When the pull is active."),
		Slider("Pull Speed", 5, 240, 5, 45, "Most degrees per second the camera is pulled. Lower is subtler."),
	}),
	OnDisable = function(m) m._cur = nil end,
	OnRender = function(m, dt)
		if ui.MenuOpen or Typing() or not Held(m.Values.Activate) then m._cur = nil return end
		AimState.active = tick()
		local t = FindTarget(m, m._cur)
		m._cur = t and t.player
		if not t then return end
		AimState.locked = tick()
		AimCamera(TargetPos(t, m.Values.Prediction), 1, math.rad(m.Values["Pull Speed"]) * dt)
	end }

-- aimbot ------------------------------------------------------------
Module{ Name = "Aimbot", Category = "Combat", Desc = "Locks your camera onto the nearest player.",
	Settings = AimSettings({
		Mode("Activate", { "Always", "Hold Right Mouse", "Hold Left Mouse" }, "Hold Right Mouse", "When the lock is active."),
		Slider("Smoothness", 0, 20, 1, 3, "How slowly the camera turns onto the target. 0 snaps instantly."),
	}),
	OnDisable = function(m) m._cur = nil end,
	OnRender = function(m, dt)
		if ui.MenuOpen or Typing() or not Held(m.Values.Activate) then m._cur = nil return end
		AimState.active = tick()
		local t = FindTarget(m, m._cur)
		m._cur = t and t.player
		if not t then return end
		AimState.locked = tick()
		local sm = m.Values.Smoothness
		AimCamera(TargetPos(t, m.Values.Prediction), sm == 0 and 1 or 1 - math.exp(-(30 / sm) * dt))
	end }

-- triggerbot --------------------------------------------------------
-- simulated left click: used by the Autoclicker and the Triggerbot
function ui.Click()
	if ui.MenuOpen then return end
	local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
	local ch = LP.Character
	local tool = ch and ch:FindFirstChildOfClass("Tool")
	-- on a phone a held tool is used directly, since there is no cursor to click with
	if touchOnly and tool then tool:Activate() return end
	if ui.VIM == nil then
		local ok, v = pcall(function() return game:GetService("VirtualInputManager") end)
		ui.VIM = ok and v or false
	end
	local pos = touchOnly and Camera.ViewportSize / 2 or UIS:GetMouseLocation()
	if ui.VIM then
		local ok = pcall(function()
			ui.VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
			ui.VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
		end)
		if ok then return end
	end
	if type(mouse1click) == "function" then pcall(mouse1click) return end
	if tool then tool:Activate() end
end

Module{ Name = "Autoclicker", Category = "Combat", Desc = "Clicks left mouse button over and over while you hold right click. On mobile, hold the on-screen CLICK button.",
	Settings = {
		Slider("CPS", 1, 30, 1, 10, "Clicks per second."),
		Mode("Activate", { "Hold Right Click", "Always" }, "Hold Right Click", "Hold Right Click clicks only while you hold the right mouse button or the mobile button. Always clicks the whole time it is on."),
		Toggle("Mobile Button", true, "Shows a CLICK button on touch devices. Hold it to autoclick."),
	},
	OnEnable = function(m)
		m._acc = 0
		if UIS.TouchEnabled and m.Values["Mobile Button"] then m._tc = ui.TouchBtn("CLICK", 2) end
	end,
	OnDisable = function(m)
		ui.DropTouch(m._tc); m._tc = nil
	end,
	OnTick = function(m, dt)
		local V = m.Values
		local active = V.Activate == "Always" or (m._tc ~= nil and m._tc.held) or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if not active or ui.MenuOpen or Typing() then m._acc = 0 return end
		m._acc += dt * V.CPS
		local n = 0
		while m._acc >= 1 and n < 5 do
			ui.Click()
			m._acc -= 1
			n += 1
		end
		if m._acc > 5 then m._acc = 0 end
	end }

Module{ Name = "Triggerbot", Category = "Combat", Desc = "Automatically uses your tool or clicks while your aim is over a player.",
	Settings = {
		Mode("Action", { "Use Tool", "Left Click" }, "Use Tool", "Use Tool activates your equipped tool. Left Click simulates a left mouse click, so it works without a tool."),
		Slider("Delay", 0, 500, 10, 60, "Milliseconds your aim must stay on a player before it fires."),
		Slider("Cooldown", 50, 1000, 10, 150, "Minimum milliseconds between tool uses. Only used by Use Tool."),
		Slider("Click CPS", 1, 30, 1, 10, "Clicks per second while aiming at a player. Only used by Left Click."),
		Slider("Max Distance", 20, 2000, 10, 300, D_DIST),
		Toggle("Team Check", true, D_TEAM),
	},
	OnDisable = function(m) m._since = nil end,
	OnTick = function(m)
		local V = m.Values
		local ch = LP.Character
		local tool = ch and ch:FindFirstChildOfClass("Tool")
		local clicking = V.Action == "Left Click"
		if ui.MenuOpen or Typing() or (not clicking and not tool) then m._since = nil return end
		local c = AimPoint("Auto")
		local ray = Camera:ViewportPointToRay(c.X, c.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * V["Max Distance"], RayParams())
		local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
		local p = model and Players:GetPlayerFromCharacter(model)
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if p and p ~= LP and hum and hum.Health > 0 and not (V["Team Check"] and ui.SameTeam(p)) then
			m._since = m._since or tick()
			local gap = clicking and 1000 / V["Click CPS"] or V.Cooldown
			if (tick() - m._since) * 1000 >= V.Delay and (tick() - (m._last or 0)) * 1000 >= gap then
				m._last = tick()
				if clicking then ui.Click() else tool:Activate() end
			end
		else
			m._since = nil
		end
	end }

----------------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------------
do
local Waypoint
Module{ Name = "ClickTP", Category = "Utility", Desc = "Teleports you to wherever you click in the world.",
	Settings = { Mode("Mode", { "Ctrl+Click", "Click" }, "Ctrl+Click", "Ctrl+Click needs Left Ctrl held while clicking. Click teleports on every single click.") },
	OnEnable = function(m)
		Hook(m, UIS.InputBegan, function(i, gp)
			if gp or ui.MenuOpen or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if m.Values.Mode == "Ctrl+Click" and not UIS:IsKeyDown(Enum.KeyCode.LeftControl) then return end
			local r = Root(); if r then r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
		end)
	end }

Module{ Name = "TP To Player", Category = "Utility", Desc = "Teleports you right next to the selected player.",
	Settings = { Mode("Target", PlayerNames, nil, D_TARGET) },
	Action = function(m)
		local p = Target(m)
		local tr, r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Root()
		if tr and r then r.CFrame = tr.CFrame * CFrame.new(0, 0, 3); ui.Notify("Teleported to " .. p.Name, true)
		else ui.Notify("No valid target", false) end
	end }

Module{ Name = "Follow", Category = "Utility", Desc = "Makes your character walk toward the selected player and keep following them.",
	Settings = {
		Mode("Target", PlayerNames, nil, D_TARGET),
		Slider("Distance", 3, 40, 1, 6, "How close to get before you stop walking, in studs."),
	},
	OnDisable = function() local h, r = Hum(), Root(); if h and r then h:MoveTo(r.Position) end end,
	OnTick = function(m)
		local p = Target(m)
		local tr = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local h, r = Hum(), Root()
		if tr and h and r and (tr.Position - r.Position).Magnitude > m.Values.Distance then h:MoveTo(tr.Position) end
	end }

Module{ Name = "Spectate", Category = "Utility", Desc = "Watch the game through another player's camera. Disable it to return to yourself.",
	Settings = { Mode("Target", PlayerNames, nil, D_TARGET) },
	OnDisable = function() local h = Hum(); if h then Camera.CameraSubject = h end end,
	OnRender = function(m)
		local p = Target(m)
		local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if h then Camera.CameraSubject = h end
	end }

Module{ Name = "Set Waypoint", Category = "Utility", Desc = "Saves your current position so you can teleport back to it later.",
	Action = function() local r = Root(); if r then Waypoint = r.CFrame; ui.Notify("Waypoint saved", true) end end }
Module{ Name = "Go To Waypoint", Category = "Utility", Desc = "Teleports you to the position you saved with Set Waypoint.",
	Action = function()
		local r = Root()
		if r and Waypoint then r.CFrame = Waypoint; ui.Notify("Teleported to waypoint", true) else ui.Notify("No waypoint set", false) end
	end }
end
Module{ Name = "TP To Spawn", Category = "Utility", Desc = "Teleports you to the first spawn point in the map.",
	Action = function()
		local s, r = workspace:FindFirstChildWhichIsA("SpawnLocation", true), Root()
		if s and r then r.CFrame = s.CFrame + Vector3.new(0, 5, 0) else ui.Notify("No spawn found", false) end
	end }

-- On-screen keyboard: tapping a key makes the game see a real key press, so phone players can use
-- keybinds (including this menu's key) and keyboard-only controls.
function ui.GetVIM()
	if ui.VIM == nil then
		local ok, v = pcall(function() return game:GetService("VirtualInputManager") end)
		ui.VIM = ok and v or false
	end
	return ui.VIM
end
ui.KBPages = {
	{
		{ { "One", "1" }, { "Two", "2" }, { "Three", "3" }, { "Four", "4" }, { "Five", "5" }, { "Six", "6" }, { "Seven", "7" }, { "Eight", "8" }, { "Nine", "9" }, { "Zero", "0" } },
		{ { "Q" }, { "W" }, { "E" }, { "R" }, { "T" }, { "Y" }, { "U" }, { "I" }, { "O" }, { "P" } },
		{ { "A" }, { "S" }, { "D" }, { "F" }, { "G" }, { "H" }, { "J" }, { "K" }, { "L" } },
		{ { "LeftShift", "Shift", 1.6 }, { "Z" }, { "X" }, { "C" }, { "V" }, { "B" }, { "N" }, { "M" }, { "Backspace", "Del", 1.6 } },
		{ { "LeftControl", "Ctrl", 1.3 }, { "LeftAlt", "Alt", 1.3 }, { "Space", "Space", 4 }, { "Return", "Enter", 1.6 }, { "@more", "More", 1.4 } },
	},
	{
		{ { "Escape", "Esc" }, { "Tab" }, { "Insert", "Ins" }, { "Delete", "Del" }, { "Home" }, { "End" }, { "PageUp", "PgUp" }, { "PageDown", "PgDn" } },
		{ { "F1" }, { "F2" }, { "F3" }, { "F4" }, { "F5" }, { "F6" }, { "F7" }, { "F8" }, { "F9" }, { "F10" } },
		{ { "F11" }, { "F12" }, { "LeftShift", "LShift", 1.3 }, { "RightShift", "RShift", 1.3 }, { "RightControl", "RCtrl", 1.3 }, { "RightAlt", "RAlt", 1.3 } },
		{ { "Up", "Up" }, { "Left", "Left" }, { "Down", "Down" }, { "Right", "Right" }, { "Space", "Space", 3 }, { "@more", "ABC", 1.4 } },
	},
}

Module{ Name = "Keyboard", Category = "Utility", Desc = "Shows an on-screen keyboard for mobile. Tapping a key makes the game see that key being pressed, so keybinds and keyboard-only controls work on a phone.",
	Settings = {
		Slider("Size", 0.6, 1.5, 0.05, 1, "How big the keyboard and its keys are."),
		Slider("Opacity", 0.2, 1, 0.05, 0.85, "How solid the keys are. Lower lets you see the game behind them."),
		Toggle("Sticky Modifiers", true, "Shift, Ctrl and Alt stay held after one tap and release on the next tap, so you can use key combinations."),
	},
	OnChanged = function(m) if m._build then m._build() end end,
	OnEnable = function(m)
		local vim = ui.GetVIM()
		if not vim then
			ui.Notify("This executor can't simulate key presses, so the keyboard can't work", false)
		end
		m._down, m._page = {}, 1
		local MODS = { LeftShift = true, RightShift = true, LeftControl = true, RightControl = true, LeftAlt = true, RightAlt = true }
		local function send(key, state)
			if vim then pcall(function() vim:SendKeyEvent(state, key, false, game) end) end
		end
		local function release(key)
			if m._down[key] then m._down[key] = nil; send(key, false) end
		end
		local frame = New("Frame", { Name = "ZenithKeyboard", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 40 }, ui.Gui)
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Center }, frame)
		local bar = New("TextButton", { Size = UDim2.fromOffset(300, 20), BackgroundColor3 = C_HEAD, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, Text = "KEYBOARD  -  drag here to move", Font = FONT_B, TextSize = 11, TextColor3 = C_DIM, LayoutOrder = 0, ZIndex = 41 }, frame)
		-- keep the title bar as wide as the keys: the first key row decides the width
		local barLine = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 41 }, bar)
		Reg(barLine, "BackgroundColor3")
		bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				-- switch from the bottom-center anchor to plain offsets so dragging works like the panels
				local ap, sz = frame.AbsolutePosition, frame.AbsoluteSize
				frame.AnchorPoint = Vector2.zero
				frame.Position = UDim2.fromOffset(ap.X, ap.Y)
				ui.BeginDrag(frame, i)
			end
		end)
		m._kbFrame = frame
		local rows = {}
		function m._build()
			for _, r in ipairs(rows) do r:Destroy() end
			rows = {}
			local V = m.Values
			local u = math.floor(34 * V.Size + 0.5)
			-- the title bar is as wide as the widest row (a scale width would collapse inside an auto-sized frame)
			local widest = 0
			for _, row in ipairs(ui.KBPages[m._page]) do
				local w = 3 * (#row - 1)
				for _, k in ipairs(row) do local kw = k[3] or 1; w += math.floor(u * kw + (kw - 1) * 3 + 0.5) end
				widest = math.max(widest, w)
			end
			bar.Size = UDim2.fromOffset(widest, 20)
			for ri, row in ipairs(ui.KBPages[m._page]) do
				local rf = New("Frame", { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, LayoutOrder = ri, ZIndex = 41 }, frame)
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, rf)
				table.insert(rows, rf)
				for ci, k in ipairs(row) do
					local name, label, w = k[1], k[2] or k[1], k[3] or 1
					local key = name ~= "@more" and Enum.KeyCode[name] or nil
					if name == "@more" or key then
						local b = New("TextButton", { Size = UDim2.fromOffset(math.floor(u * w + (w - 1) * 3 + 0.5), u), BackgroundColor3 = C_ROW, BackgroundTransparency = 1 - V.Opacity, BorderSizePixel = 0, AutoButtonColor = false, Text = label, Font = FONT_B, TextSize = math.max(9, math.floor(12 * V.Size)), TextColor3 = WHITE, LayoutOrder = ci, ZIndex = 42 }, rf)
						New("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
						local function paint() b.BackgroundColor3 = (key and m._down[key]) and Accent() or C_ROW end
						paint()
						if name == "@more" then
							b.Activated:Connect(function() m._page = m._page == 1 and 2 or 1; m._build() end)
						else
							b.InputBegan:Connect(function(i)
								if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								-- while a keybind is waiting for a key, the tapped key is the answer
								if ui.TryBind and ui.TryBind(key) then paint() return end
								if MODS[name] and V["Sticky Modifiers"] then
									-- tap once to hold, tap again to let go
									if m._down[key] then release(key) else m._down[key] = true; send(key, true) end
								else
									m._down[key] = true; send(key, true)
								end
								paint()
							end)
							b.InputEnded:Connect(function(i)
								if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
								if MODS[name] and V["Sticky Modifiers"] then return end
								release(key)
								paint()
								-- a normal key press also lets go of any sticky modifiers
								if V["Sticky Modifiers"] then
									local any = false
									for mk in pairs(MODS) do
										local code = Enum.KeyCode[mk]
										if m._down[code] and name ~= mk then release(code); any = true end
									end
									if any then m._build() end
								end
							end)
						end
					end
				end
			end
		end
		m._build()
		m._kbFrame, m._release = frame, release
	end,
	OnDisable = function(m)
		if m._down then
			for key in pairs(m._down) do
				local vim = ui.VIM
				if vim then pcall(function() vim:SendKeyEvent(false, key, false, game) end) end
			end
			m._down = {}
		end
		if m._kbFrame then m._kbFrame:Destroy(); m._kbFrame = nil end
		m._build = nil
	end }

Module{ Name = "AntiAFK", Category = "Utility", Desc = "Stops Roblox from kicking you for being idle for too long.",
	OnEnable = function(m)
		Hook(m, LP.Idled, function()
			pcall(function()
				local vu = game:GetService("VirtualUser")
				vu:CaptureController(); vu:ClickButton2(Vector2.new())
			end)
		end)
	end }

Module{ Name = "PlayerAlerts", Category = "Utility", Desc = "Shows a notification whenever a player joins or leaves the server.",
	OnEnable = function(m)
		Hook(m, Players.PlayerAdded, function(p) ui.Notify(p.Name .. " joined", true) end)
		Hook(m, Players.PlayerRemoving, function(p) ui.Notify(p.Name .. " left", false) end)
	end }

Module{ Name = "Rejoin", Category = "Utility", Desc = "Rejoins the server you are in right now. Only works in a published game, not in Studio.",
	Action = function()
		local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
		if not ok then ui.Notify("Rejoin only works in a published game", false) end
	end }

function ui.JoinPlayer(m)
	local name = tostring(m.Values.Username or ""):gsub("%s", "")
	if name == "" then ui.Notify("Type a username first", false) return end
	if Players:FindFirstChild(name) then ui.Notify(name .. " is already in this server", false) return end
	ui.Notify("Looking for " .. name .. "...", true)
	task.spawn(function()
		local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
		if not ok or not uid then ui.Notify("No Roblox user called " .. name, false) return end
		local placeId, jobId
		local ok2, cur, _, pid, iid = pcall(function() return TeleportService:GetPlayerPlaceInstanceAsync(uid) end)
		if ok2 and pid and iid then placeId, jobId = pid, iid end
		if not placeId then
			local req = request or http_request or (syn and syn.request)
			if req then
				local ok3, res = pcall(function()
					local r = req({ Url = "https://presence.roblox.com/v1/presence/users", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = game:GetService("HttpService"):JSONEncode({ userIds = { uid } }) })
					return game:GetService("HttpService"):JSONDecode(r.Body).userPresences[1]
				end)
				if ok3 and res and res.placeId and res.gameId then placeId, jobId = res.placeId, res.gameId end
			end
		end
		if not placeId then ui.Notify(name .. " is offline, or their joins are hidden", false) return end
		ui.Notify("Joining " .. name .. "...", true)
		if placeId ~= game.PlaceId and setclipboard then
			pcall(setclipboard, "roblox://experiences/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId)
		end
		local ok4 = pcall(function() TeleportService:TeleportToPlaceInstance(placeId, jobId, LP) end)
		if not ok4 then ui.Notify("Could not join. If it is a different game, the join link was copied to your clipboard", false) end
	end)
end
-- Player Lookup: search any Roblox player by username or display name, see their profile and act on them
ui.PL = { conns = {} }
function ui.PL.Http(url)
	local ok, r = pcall(function() return game:GetService("HttpService"):JSONDecode(game:HttpGet(url)) end)
	return ok and r or nil
end
function ui.PL.Stop()
	local PL = ui.PL
	for _, c in ipairs(PL.conns) do pcall(function() c:Disconnect() end) end
	PL.conns, PL.following, PL.spectating, PL.flinging = {}, nil, nil, false
	local h = Hum()
	if h and Camera.CameraSubject ~= h then Camera.CameraSubject = h end
end
function ui.PL.Destroy()
	ui.PL.Stop()
	if ui.PL.win then ui.PL.win:Destroy(); ui.PL.win = nil end
end
function ui.PL.Btn(parent, text, fn, order)
	local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C_ROW, BorderSizePixel = 0, AutoButtonColor = false, Text = text, Font = FONT, TextSize = 13, TextColor3 = WHITE, LayoutOrder = order }, parent)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = C_ROWHOV end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = C_ROW end)
	b.MouseButton1Click:Connect(function() Safe(fn, b) end)
	return b
end
function ui.PL.Thumb(img, id, big)
	task.spawn(function()
		local ok, url = pcall(function() return Players:GetUserThumbnailAsync(id, big and Enum.ThumbnailType.AvatarBust or Enum.ThumbnailType.HeadShot, big and Enum.ThumbnailSize.Size150x150 or Enum.ThumbnailSize.Size100x100) end)
		if ok and img.Parent then img.Image = url end
	end)
end
function ui.PL.Copy(text, what)
	if setclipboard then pcall(setclipboard, text); ui.Notify(what .. " copied", true) else ui.Notify("Your executor can't copy to the clipboard", false) end
end
function ui.PL.Actions(u)
	local PL = ui.PL
	for _, c in ipairs(PL.acts:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local p = Players:GetPlayerByUserId(u.id)
	local n = 0
	local function add(text, fn) n += 1; return ui.PL.Btn(PL.acts, text, fn, n) end
	add("Join Their Server", function() ui.JoinPlayer({ Values = { Username = u.name } }) end)
	if p and p ~= LP then
		add("Teleport To", function()
			local tr, r = p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Root()
			if tr and r then r.CFrame = tr.CFrame * CFrame.new(0, 0, 3) else ui.Notify("They have no character right now", false) end
		end)
		local fb = add(PL.following == p and "Stop Following" or "Follow", function(b)
			if PL.following == p then
				PL.following = nil; b.Text = "Follow"
				local h, r = Hum(), Root(); if h and r then h:MoveTo(r.Position) end
				return
			end
			PL.following = p; b.Text = "Stop Following"
			local c = Conn(RunService.Heartbeat, function()
				if PL.following ~= p then return end
				local tr, h = p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Hum()
				if tr and h then h:MoveTo(tr.Position) end
			end)
			table.insert(PL.conns, c)
		end)
		add(PL.spectating == p and "Stop Spectating" or "Spectate", function(b)
			if PL.spectating == p then
				PL.spectating = nil; b.Text = "Spectate"
				local h = Hum(); if h then Camera.CameraSubject = h end
				return
			end
			local th = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if not th then ui.Notify("They have no character right now", false) return end
			PL.spectating = p; b.Text = "Stop Spectating"
			Camera.CameraSubject = th
		end)
		add("Fling", function()
			if PL.flinging then return end
			local tr, r = p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Root()
			if not tr or not r then ui.Notify("They have no character right now", false) return end
			PL.flinging = true
			local home = r.CFrame
			local t0 = os.clock()
			local c1, c2
			c1 = Conn(RunService.Heartbeat, function()
				local t, rr = p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Root()
				if not t or not rr or os.clock() - t0 > 2.5 then return end
				rr.CFrame = t.CFrame
				rr.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
				rr.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
			end)
			c2 = Conn(RunService.RenderStepped, function()
				local rr = Root()
				if rr and os.clock() - t0 <= 2.5 then rr.AssemblyLinearVelocity = Vector3.zero; rr.AssemblyAngularVelocity = Vector3.zero end
			end)
			task.delay(2.6, function()
				c1:Disconnect(); c2:Disconnect()
				local rr = Root()
				if rr then rr.AssemblyLinearVelocity = Vector3.zero; rr.AssemblyAngularVelocity = Vector3.zero; rr.CFrame = home end
				PL.flinging = false
			end)
		end)
	end
	add("Copy Username", function() ui.PL.Copy(u.name, "Username") end)
	add("Copy User ID", function() ui.PL.Copy(tostring(u.id), "User ID") end)
	add("Copy Profile Link", function() ui.PL.Copy("https://www.roblox.com/users/" .. u.id .. "/profile", "Profile link") end)
end
function ui.PL.Select(u)
	local PL = ui.PL
	PL.sel = u
	PL.dn.Text = u.display or u.name
	PL.un.Text = "@" .. u.name .. (u.verified and "  (verified)" or "")
	PL.info.Text = "Loading..."
	PL.av.Image = ""
	ui.PL.Thumb(PL.av, u.id, true)
	ui.PL.Actions(u)
	task.spawn(function()
		local HS = "https://%s.roblox.com/v1/users/%d"
		local d = ui.PL.Http(string.format(HS, "users", u.id)) or {}
		local fr = ui.PL.Http("https://friends.roblox.com/v1/users/" .. u.id .. "/friends/count") or {}
		local fo = ui.PL.Http("https://friends.roblox.com/v1/users/" .. u.id .. "/followers/count") or {}
		local fg = ui.PL.Http("https://friends.roblox.com/v1/users/" .. u.id .. "/followings/count") or {}
		if PL.sel ~= u or not PL.info.Parent then return end
		local lines = { "<b>User ID</b>  " .. u.id }
		if d.created then
			local ok, dt = pcall(function() return DateTime.fromIsoDate(d.created) end)
			if ok and dt then
				lines[#lines + 1] = "<b>Joined</b>  " .. dt:FormatUniversalTime("LL", "en-us") .. "  (" .. math.floor((os.time() - dt.UnixTimestamp) / 86400) .. " days old)"
			end
		end
		lines[#lines + 1] = "<b>Friends</b>  " .. tostring(fr.count or "?") .. "    <b>Followers</b>  " .. tostring(fo.count or "?") .. "    <b>Following</b>  " .. tostring(fg.count or "?")
		if d.isBanned then lines[#lines + 1] = "<b>Banned</b>  yes" end
		local p = Players:GetPlayerByUserId(u.id)
		if p then
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			local tr, r = p.Character and p.Character:FindFirstChild("HumanoidRootPart"), Root()
			local extra = "<b>Status</b>  in your server"
			if h then extra ..= "  -  " .. math.floor(h.Health) .. " HP" end
			if tr and r then extra ..= "  -  " .. math.floor((tr.Position - r.Position).Magnitude) .. " studs away" end
			lines[#lines + 1] = extra
		else
			lines[#lines + 1] = "<b>Status</b>  not in your server"
		end
		if d.description and d.description ~= "" then
			local desc = d.description:gsub("[<>&]", ""):gsub("%s+", " ")
			lines[#lines + 1] = "<b>About</b>  " .. string.sub(desc, 1, 160)
		end
		PL.info.Text = table.concat(lines, "\n")
	end)
end
function ui.PL.Row(u, tag)
	local PL = ui.PL
	local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C_ROW, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = #PL.list:GetChildren() }, PL.list)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	local img = New("ImageLabel", { Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = C_HEAD, BorderSizePixel = 0 }, b)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
	ui.PL.Thumb(img, u.id, false)
	New("TextLabel", { Position = UDim2.fromOffset(50, 6), Size = UDim2.new(1, -56, 0, 18), BackgroundTransparency = 1, Text = u.display or u.name, Font = FONT_B, TextSize = 13, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	New("TextLabel", { Position = UDim2.fromOffset(50, 24), Size = UDim2.new(1, -56, 0, 16), BackgroundTransparency = 1, Text = "@" .. u.name .. (tag and ("  -  " .. tag) or ""), Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = C_ROWHOV end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = C_ROW end)
	b.MouseButton1Click:Connect(function() ui.PL.Select(u) end)
end
function ui.PL.Search(q)
	local PL = ui.PL
	q = tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", "")
	for _, c in ipairs(PL.list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	if q == "" then return end
	local seen = {}
	local lq = q:lower()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():find(lq, 1, true) or p.DisplayName:lower():find(lq, 1, true) then
			seen[p.UserId] = true
			ui.PL.Row({ id = p.UserId, name = p.Name, display = p.DisplayName }, "in your server")
		end
	end
	PL.status.Text = "Searching..."
	local my = os.clock(); PL.stamp = my
	task.spawn(function()
		local found = {}
		local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(q) end)
		if ok and uid and not seen[uid] then
			seen[uid] = true
			found[#found + 1] = { id = uid, name = q, display = q }
		end
		local res = ui.PL.Http("https://users.roblox.com/v1/users/search?limit=10&keyword=" .. game:GetService("HttpService"):UrlEncode(q))
		if res and res.data then
			for _, d in ipairs(res.data) do
				if not seen[d.id] then
					seen[d.id] = true
					found[#found + 1] = { id = d.id, name = d.name, display = d.displayName, verified = d.hasVerifiedBadge }
				end
			end
		end
		if PL.stamp ~= my or not PL.list.Parent then return end
		for _, u in ipairs(found) do ui.PL.Row(u) end
		PL.status.Text = (#PL.list:GetChildren() - 1 <= 0) and "No players found" or ""
	end)
end
function ui.PL.Build()
	local PL = ui.PL
	if PL.win then return end
	local vp = Camera.ViewportSize
	if vp.X < 400 then vp = Vector2.new(1280, 720) end
	local W, H = math.min(600, vp.X - 20), math.min(420, vp.Y - 30)
	local BG = Color3.fromRGB(18, 18, 25)
	local win = New("Frame", { Name = "ZenithLookup", Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset((vp.X - W) / 2, (vp.Y - H) / 2), BackgroundColor3 = BG, BorderSizePixel = 0, ZIndex = 60, ClipsDescendants = true }, ui.Gui)
	PL.win = win
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
	local stroke = New("UIStroke", { Thickness = 1.5, Transparency = 0.35 }, win)
	AddPainter(stroke, function() stroke.Color = Accent(0.2) end)
	local bar = New("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Color3.fromRGB(13, 13, 19), BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, win)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, bar)
	New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(13, 13, 19), BorderSizePixel = 0 }, bar)
	New("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = "Player Lookup", Font = FONT_B, TextSize = 16, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	local x = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "X", Font = FONT_B, TextSize = 14, TextColor3 = C_LIGHT }, bar)
	x.MouseButton1Click:Connect(function() if PL.mod then SetEnabled(PL.mod, false) else ui.PL.Destroy() end end)
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then ui.BeginDrag(win, i) end
	end)
	local line = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, bar)
	ui.StyleLine(line, 0, bar)
	-- left: search + results
	local LW = math.floor(W * 0.4)
	local box = New("TextBox", { Position = UDim2.fromOffset(10, 48), Size = UDim2.new(0, LW - 20, 0, 30), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, ClearTextOnFocus = false, Font = FONT, TextSize = 13, TextColor3 = WHITE, PlaceholderText = "Username or display name", PlaceholderColor3 = C_DIM, Text = "", TextXAlignment = Enum.TextXAlignment.Left }, win)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
	box.FocusLost:Connect(function(enter) if enter then ui.PL.Search(box.Text) end end)
	PL.status = New("TextLabel", { Position = UDim2.fromOffset(10, 82), Size = UDim2.new(0, LW - 20, 0, 14), BackgroundTransparency = 1, Text = "Press enter to search", Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left }, win)
	PL.list = New("ScrollingFrame", { Position = UDim2.fromOffset(10, 100), Size = UDim2.new(0, LW - 20, 1, -110), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, win)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, PL.list)
	New("Frame", { Position = UDim2.fromOffset(LW, 46), Size = UDim2.new(0, 1, 1, -56), BackgroundColor3 = Color3.fromRGB(38, 38, 50), BorderSizePixel = 0 }, win)
	-- right: profile
	local R = New("Frame", { Position = UDim2.fromOffset(LW + 10, 46), Size = UDim2.new(1, -(LW + 20), 1, -56), BackgroundTransparency = 1 }, win)
	PL.av = New("ImageLabel", { Size = UDim2.fromOffset(72, 72), BackgroundColor3 = C_HEAD, BorderSizePixel = 0 }, R)
	New("UICorner", { CornerRadius = UDim.new(0, 8) }, PL.av)
	PL.dn = New("TextLabel", { Position = UDim2.fromOffset(82, 8), Size = UDim2.new(1, -82, 0, 24), BackgroundTransparency = 1, Text = "No player selected", Font = FONT_B, TextSize = 18, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, R)
	PL.un = New("TextLabel", { Position = UDim2.fromOffset(82, 34), Size = UDim2.new(1, -82, 0, 18), BackgroundTransparency = 1, Text = "Search for someone on the left", Font = FONT, TextSize = 12, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, R)
	PL.info = New("TextLabel", { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 96), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 12, TextColor3 = C_LIGHT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, RichText = true }, R)
	PL.acts = New("ScrollingFrame", { Position = UDim2.fromOffset(0, 180), Size = UDim2.new(1, 0, 1, -180), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, R)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, PL.acts)
end
Module{ Name = "PlayerLookup", Category = "Utility", Desc = "Opens a window where you can search any Roblox player by username or display name, see their profile, and join their server. For players in your server you can also teleport, follow, spectate and fling them.",
	OnEnable = function(m) ui.PL.mod = m; ui.PL.Build() end,
	OnDisable = function(m) ui.PL.Destroy() end }

Module{ Name = "PlayerJoiner", Category = "Utility", Desc = "Type a player's username and press Join to go to the game and server they are in. Needs them to be online with joins allowed.", Passive = true,
	Settings = {
		{ Name = "Username", Type = "Text", Default = "", Desc = "The Roblox username of the player to join.", Placeholder = "username" },
		Button("Join Player", "Teleports you to the server this player is in.", function(m) ui.JoinPlayer(m) end),
	} }

Module{ Name = "ServerHop", Category = "Utility", Desc = "Moves you to a different public server of this game.",
	Settings = { Mode("Server", { "Random", "Smallest", "Largest" }, "Random", "Which server to join: any other server, the emptiest one, or the fullest one that still has room.") },
	Action = function(m)
		ui.Notify("Finding a server...", true)
		task.spawn(function()
			local ok, list = pcall(function()
				local HS = game:GetService("HttpService")
				local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
				return HS:JSONDecode(game:HttpGet(url)).data
			end)
			if not ok or type(list) ~= "table" then ui.Notify("Could not get the server list", false) return end
			local pool = {}
			for _, sv in ipairs(list) do
				if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then pool[#pool + 1] = sv end
			end
			if #pool == 0 then ui.Notify("No other server found", false) return end
			local pick
			local mode = m.Values.Server
			if mode == "Smallest" then table.sort(pool, function(a, b) return a.playing < b.playing end); pick = pool[1]
			elseif mode == "Largest" then table.sort(pool, function(a, b) return a.playing > b.playing end); pick = pool[1]
			else pick = pool[math.random(#pool)] end
			ui.Notify("Joining a server with " .. pick.playing .. " players", true)
			if not pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LP) end) then ui.Notify("Server hop failed", false) end
		end)
	end }

-- HappyMod Flight: the old-school flight. Hold jump and you shoot upward with an invisible water splash going off over and over.
-- Move your joystick or keys to swim around, let go of jump and you fall.
Module{ Name = "HappyModFlight", Category = "Movement", Desc = "The classic old-school flight. Hold jump and you shoot upward with a rapid water splash sound. Move to swim around while you hold it. Let go of jump and you fall.",
	Settings = {
		Slider("Power", 10, 120, 1, 45, "How fast you rise while holding jump, in studs per second."),
		Slider("Swim Speed", 0, 60, 1, 22, "How fast you move around while holding jump."),
		Toggle("Splash Sound", true, "Plays the water splash sound over and over while you are flying."),
		Toggle("Lie Down", false, "Lays your body flat, belly down, while you are flying."),
	},
	OnEnable = function(m)
		m._last = 0
		Hook(m, UIS.JumpRequest, function() m._last = os.clock() end)
	end,
	OnTick = function(m)
		local r, h = Root(), Hum()
		if not r or not h or h.Health <= 0 then return end
		local V = m.Values
		local held = h.Jump or UIS:IsKeyDown(Enum.KeyCode.Space) or os.clock() - m._last < 0.12
		if held then
			local md = h.MoveDirection
			local v = r.AssemblyLinearVelocity
			local hv = Vector3.new(v.X, 0, v.Z):Lerp(md * V["Swim Speed"], 0.25)
			r.AssemblyLinearVelocity = Vector3.new(hv.X, V.Power, hv.Z)
			m._flying = true
			if V["Lie Down"] then
				h.PlatformStand = true
				local look = Camera.CFrame.LookVector
				r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0) * CFrame.Angles(math.rad(-90), 0, 0)
				r.AssemblyAngularVelocity = Vector3.zero
				m._lay = true
			end
		elseif m._flying then
			m._flying = false
			if m._lay then
				m._lay = false
				h.PlatformStand = false
				local look = r.CFrame.LookVector
				r.CFrame = CFrame.new(r.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
			end
		end
		if V["Splash Sound"] and m._flying and os.clock() - (m._sndT or 0) > 0.06 then
			m._sndT = os.clock()
			local sd = Instance.new("Sound")
			sd.SoundId = "rbxasset://sounds/impact_water.mp3"
			sd.Volume = 0.5
			sd.PlaybackSpeed = 1 + math.random() * 0.5
			sd.Parent = r
			sd:Play()
			game:GetService("Debris"):AddItem(sd, 1.5)
		end
	end,
	OnDisable = function(m)
		if m._snd then m._snd:Destroy(); m._snd = nil end
		local r, h = Root(), Hum()
		if h and m._lay then
			m._lay = false
			h.PlatformStand = false
			if r then
				local look = r.CFrame.LookVector
				r.CFrame = CFrame.new(r.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
			end
		end
	end }

-- Freefall: every animation (idle, walk, run, swim...) is replaced by your fall animation
Module{ Name = "Freefall", Category = "Player", Desc = "Plays your falling animation all the time. Walking, running and standing still all show you mid-fall.",
	OnEnable = function(m)
		Hook(m, RunService.RenderStepped, function()
			local c = LP.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local an = h and h:FindFirstChildOfClass("Animator")
			if not an then return end
			if not m._track or m._owner ~= c then
				if m._track then pcall(function() m._track:Stop(0) end) end
				local id
				local sc = c:FindFirstChild("Animate")
				local f = sc and sc:FindFirstChild("fall")
				local a = f and f:FindFirstChildOfClass("Animation")
				id = a and a.AnimationId
				if not id or id == "" then id = h.RigType == Enum.HumanoidRigType.R15 and "rbxassetid://507767968" or "rbxassetid://180436148" end
				local anim = Instance.new("Animation")
				anim.AnimationId = id
				local ok, tr = pcall(function() return an:LoadAnimation(anim) end)
				if not ok then return end
				tr.Priority = Enum.AnimationPriority.Action
				tr.Looped = true
				m._track, m._owner = tr, c
			end
			if not m._track.IsPlaying then m._track:Play(0.1) end
		end)
	end,
	OnDisable = function(m)
		if m._track then pcall(function() m._track:Stop(0.1) end); m._track = nil end
	end }

----------------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------------
local ArrayList = Module{ Name = "ArrayList", Category = "Settings", Desc = "Lists your enabled modules on the right side of the screen, starting at the top.",
	Settings = {
		Mode("Sort", { "Longest", "Shortest", "Alphabetical" }, "Longest", "Order of the list: longest names first, shortest first, or alphabetical."),
		Toggle("Show Suffix", true, "Shows a module's current mode next to its name, for example Speed WalkSpeed."),
		Toggle("Background", true, "Draws a dark box behind each entry."),
		Toggle("Side Bar", true, "Draws a colored bar on the right edge of each entry."),
		Slider("Opacity", 0, 1, 0.05, 0.45, "How solid the background boxes are."),
		Slider("Text Size", 12, 26, 1, 16, "Size of the list text in pixels."),
	} }
local Notifs = Module{ Name = "Notifications", Category = "Settings", Desc = "Shows small pop-ups in the bottom right for warnings, teleports and other events.",
	Settings = {
		Slider("Duration", 1, 8, 0.5, 3, "How many seconds each pop-up stays on screen."),
		Toggle("Module Toggles", false, "Also shows a pop-up whenever a module is turned on or off."),
	} }
Module{ Name = "Theme", Category = "Settings", Desc = "Sets the accent color of the whole client. Gradient themes (Astral, Ocean, Sunset and more) and Rainbow animate, all at the speed of Theme Speed.", Passive = true,
	Settings = {
		Mode("Color", ThemeOrder, "Purple", "The accent color used across the menu, array list and visuals."),
		Slider("Theme Speed", 0.02, 1, 0.02, 0.2, "How fast every animated theme (Rainbow, Astral, Ocean, Sunset and the rest) moves through its colors."),
	},
	OnChanged = function(m)
		ThemeName, Themes.Speed = m.Values.Color, m.Values["Theme Speed"]
		Repaint()
	end }
local GuiSettings = Module{ Name = "GUI", Category = "Settings", Desc = "Controls how this menu opens and what it looks like.", Passive = true,
	Settings = {
		Slider("UI Scale", 0.5, 1.5, 0.05, ui.Phone and 0.75 or 1, "Makes the whole menu bigger or smaller. Lower it if the menu is too large for your screen."),
		Mode("UI Type", { "Click GUI", "Window" }, "Click GUI", "Click GUI shows every category as its own panel. Window shows one box with the categories on the left and the selected category on the right."),
		Mode("Menu Key", { "RightShift", "Insert", "RightControl", "RightAlt", "Delete", "Home" }, "RightShift", "The key that opens and closes this menu."),
		Toggle("Background Blur", true, "Blurs the game behind the menu while it is open."),
		Toggle("Background Dim", true, "Darkens the game behind the menu while it is open."),
		Toggle("Descriptions", true, "Shows a short description of whatever you hover over. Turn off to hide them completely."),
		Mode("Description Style", { "Cursor", "Bottom Bar" }, ui.Phone and "Bottom Bar" or "Cursor", "Cursor shows a small tip next to your mouse. Bottom Bar pins it to the bottom of the screen."),
		Toggle("High Slider Values", false, "Raises the maximum of speed, distance and size sliders far beyond their normal limits."),
		Toggle("Keep Across Teleports", false, "Reloads Zenith with your current settings after a rejoin or teleport. Needs this script saved as Zenith.luau in your executor workspace."),
		Toggle("Ctrl To Lower", true, "Left Ctrl lowers you in Fly, VehicleFly, AirWalk and Jesus. Turn off if Ctrl gets in the way."),
		Toggle("Shift To Descend", true, "Left Shift makes you descend in Fly and VehicleFly. Turn off if Shift gets in the way."),
		Toggle("Startup Logo", true, "Shows the Zenith logo for a moment when the client loads."),
	},
	OnChanged = function(m, name)
		if name == "High Slider Values" and ui.OnHighChanged then ui.OnHighChanged() end
		if name == "UI Scale" and ui.ApplyScale then ui.ApplyScale() end
		if name == "UI Type" and ui.SetUIType then ui.SetUIType(m.Values["UI Type"]) end
		if name == "Keep Across Teleports" and ui.SetKeep then ui.SetKeep(m.Values[name]) end
		ui.ApplyInterface()
	end }
-- everything about saving and loading lives in this one dropdown. "Default" is the normal saved config;
-- every game you add gets its own entry in the Target list.
ui.ConfigsMod = Module{ Name = "Configs", Category = "Settings", Desc = "Save and load your settings, with a separate config for each game. Open it to pick a config and save, load, add or delete it.", Passive = true, NoSave = true,
	Settings = {
		Mode("Target", function() return ui.GameNames and ui.GameNames() or { "Default" } end, "Default", "Which config the buttons below use. Default is your normal saved settings. Games you add show up here."),
		Button("Save Config", "Saves your current settings into the selected config.", function() ui.SaveTarget() end),
		Button("Load Config", "Loads the selected config right now.", function() ui.LoadTarget() end),
		Button("Add Game Config", "Creates a config for the game you are in, named after it, from your current settings.", function() ui.AddGameConfig() end),
		Button("Delete Config", "Deletes the selected game config. The Default config can't be deleted.", function() ui.DeleteTarget() end),
	} }
Module{ Name = "Reset Panels", Category = "Settings", Desc = "Puts every panel back in its default position.",
	Action = function() ui.ResetPanels() end }
Module{ Name = "Panic", Category = "Settings", Desc = "Instantly turns off every module. Use it if something goes wrong.",
	Action = function()
		for _, m in ipairs(Modules) do if m.Enabled and m.Category ~= "Settings" then SetEnabled(m, false, true) end end
		ui.RebuildList(); ui.Notify("All modules disabled", false)
	end }
Module{ Name = "Unload", Category = "Settings", Desc = "Completely removes Zenith from your game until you run it again.", Action = function() ui.Unload() end }

----------------------------------------------------------------------
-- high slider values + config file (writefile / readfile from the executor's file library)
----------------------------------------------------------------------
do
	local FILE = "ZenithConfig.json"
	local HttpService = game:GetService("HttpService")
	ui.ConfigFile = FILE
	ui.SessionFile = "ZenithSession.json"
	ui.KeepFile = "ZenithKeep.txt"
	ui.LoaderFile = "Zenith.luau"
	ui.CanFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
	ui.SliderRows = {}

	-- "Module.Setting" -> highest value while High Slider Values is on
	ui.HighMax = {
		["Speed.Speed"] = 900, ["Fly.Speed"] = 1500, ["Fly.Vertical"] = 900, ["VehicleFly.Speed"] = 2000, ["VehicleFly.Vertical"] = 1200,
		["InfiniteJump.Power"] = 500, ["HighJump.Power"] = 1500, ["Bhop.Boost"] = 150, ["Glide.Fall Speed"] = 200,
		["Spider.Speed"] = 300, ["Gravity.Gravity"] = 1500, ["Dash.Power"] = 1000, ["Spinbot.Speed"] = 240, ["HipHeight.Height"] = 150,
		["Jetpack.Power"] = 600, ["NoFall.Threshold"] = 400, ["AntiFling.Threshold"] = 5000, ["Follow.Distance"] = 200,
		["ESP.Max Distance"] = 20000, ["NameTags.Max Distance"] = 20000, ["Tracers.Max Distance"] = 20000, ["Chams.Max Distance"] = 20000,
		["CamDistance.Max Zoom"] = 10000, ["Freecam.Speed"] = 1000,
		["Hitbox Visualizer.Max Distance"] = 20000, ["Hitbox Expander.Size"] = 200, ["FOV Circle.Radius"] = 1500,
		["Aim Assist.Max Distance"] = 10000, ["Aim Assist.Pull Speed"] = 720, ["Aimbot.Max Distance"] = 10000, ["Triggerbot.Max Distance"] = 10000,
	}
	for _, m in ipairs(Modules) do
		for _, st in ipairs(m.Settings or {}) do
			if st.Type == "Slider" then st.High = ui.HighMax[m.Name .. "." .. st.Name] end
		end
	end

	function ui.MaxOf(st)
		return (GuiSettings.Values["High Slider Values"] and st.High) or st.Max
	end

	-- pulls any value that is above the current maximum back down; returns what it changed
	function ui.ClampSliders()
		local changedList = {}
		for _, m in ipairs(Modules) do
			for _, st in ipairs(m.Settings or {}) do
				if st.Type == "Slider" then
					local v, lim = m.Values[st.Name], ui.MaxOf(st)
					if type(v) == "number" and v > lim then
						m.Values[st.Name] = lim
						table.insert(changedList, { m, st.Name })
					end
				end
			end
		end
		return changedList
	end

	function ui.EncodeValue(v)
		if typeof(v) == "Color3" then return { t = "Color3", r = v.R, g = v.G, b = v.B } end
		return v
	end
	local function decode(v)
		if type(v) == "table" and v.t == "Color3" and type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
			return Color3.new(math.clamp(v.r, 0, 1), math.clamp(v.g, 0, 1), math.clamp(v.b, 0, 1))
		end
		return v
	end

	-- returns the saved config, or nil when there is no file / it can't be read (defaults are used then)
	function ui.ReadConfig(file)
		file = file or FILE
		if not ui.CanFS then return nil end
		local okF, exists = pcall(isfile, file)
		if not okF or not exists then return nil end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
		if ok and type(data) == "table" and type(data.modules) == "table" then return data end
		return nil
	end

	-- settings, keybinds and bind modes (before the menu is built so every row shows the loaded value)
	function ui.ApplyConfigValues(cfg)
		for _, m in ipairs(Modules) do
			local e = cfg.modules[m.Name]
			if type(e) == "table" then
				if type(e.values) == "table" then
					for _, st in ipairs(m.Settings or {}) do
						local v = decode(e.values[st.Name])
						if v ~= nil then
							if st.Type == "Slider" and type(v) == "number" then
								m.Values[st.Name] = math.clamp(v, st.Min, st.High or st.Max)
							elseif st.Type == "Toggle" and type(v) == "boolean" then
								m.Values[st.Name] = v
							elseif st.Type == "Mode" and type(v) == "string" then
								if type(st.Options) == "function" or table.find(st.Options, v) then m.Values[st.Name] = v end
							elseif st.Type == "Text" and type(v) == "string" then
								m.Values[st.Name] = v
							elseif st.Type == "Color" and typeof(v) == "Color3" then
								m.Values[st.Name] = v
							end
						end
					end
				end
				if type(e.bind) == "string" then
					local ok, key = pcall(function() return Enum.KeyCode[e.bind] end)
					if ok and key then m.Bind = key end
				end
				if e.bindMode == "Hold" or e.bindMode == "Toggle" then m.BindMode = e.bindMode end
			end
		end
		ui.ClampSliders() -- the High Slider Values toggle itself was just loaded, so settle the limits
		for _, m in ipairs(Modules) do
			if m.Name == "Theme" and m.OnChanged then Safe(m.OnChanged, m, "Color") end
		end
	end

	-- which modules were on
	function ui.ApplyConfigEnabled(cfg)
		for _, m in ipairs(Modules) do
			local e = cfg.modules[m.Name]
			if type(e) == "table" and type(e.enabled) == "boolean" and not m.Action and not m.Passive then
				SetEnabled(m, e.enabled, true)
			end
		end
	end

	-- Keep Across Teleports: queue_on_teleport only runs after a teleport / rejoin from this game, never on a
	-- normal join, and the queued code does nothing unless the keep flag file still says "1".
	local PAYLOAD = 'if isfile("ZenithKeep.txt") and readfile("ZenithKeep.txt") == "1" and isfile("Zenith.luau") then loadstring(readfile("Zenith.luau"))() end'
	function ui.QueuePersist()
		if ui._queued then return end
		if type(queue_on_teleport) ~= "function" then
			ui.Notify("Your executor has no queue_on_teleport, so settings can't carry over", false)
			return
		end
		ui._queued = true
		queue_on_teleport(PAYLOAD)
	end
	function ui.SetKeep(on)
		if not ui.CanFS then
			ui.Notify("Keeping settings needs an executor with file functions", false)
			return
		end
		pcall(writefile, ui.KeepFile, on and "1" or "0")
		if on then
			local okF, has = pcall(isfile, ui.LoaderFile)
			if not (okF and has) then
				ui.Notify("Save this script as Zenith.luau in your executor's workspace folder first", false)
			end
			ui.QueuePersist()
		end
	end

	-- per-game configs live together in one file; the game is identified by its universe id
	ui.GamesFile = "ZenithGames.json"
	ui.GameKey = tostring(game.GameId ~= 0 and game.GameId or game.PlaceId)
	function ui.ReadGames()
		local list = {}
		if not ui.CanFS then return list end
		local okF, exists = pcall(isfile, ui.GamesFile)
		if not okF or not exists then return list end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ui.GamesFile)) end)
		if ok and type(data) == "table" and type(data.games) == "table" then
			for _, g in ipairs(data.games) do
				if type(g) == "table" and type(g.id) == "string" and type(g.name) == "string" and type(g.cfg) == "table" and type(g.cfg.modules) == "table" then
					table.insert(list, g)
				end
			end
		end
		return list
	end
	function ui.WriteGames()
		if not ui.CanFS then return false end
		return (pcall(function() writefile(ui.GamesFile, HttpService:JSONEncode({ games = ui.Games })) end))
	end
	ui.Games = ui.ReadGames()
	function ui.FindGame(id)
		for _, g in ipairs(ui.Games) do if g.id == id then return g end end
	end

	-- a session file written right before a teleport (under 2 minutes old) beats the saved config once
	local cfg = ui.ReadConfig(ui.SessionFile)
	if cfg and type(cfg.t) == "number" and math.abs(os.time() - cfg.t) < 120 then
		ui.FromSession = true
	else
		-- this game's own config if it has one, otherwise the default
		local g = ui.FindGame(ui.GameKey)
		if g then
			cfg, ui.GameLoaded = g.cfg, g.name
		else
			cfg = ui.ReadConfig() or ui.ReadConfig("AerovoltConfig.json")
		end
	end
	ui.Config = cfg
	if cfg then ui.ApplyConfigValues(cfg) end
end

----------------------------------------------------------------------
-- main loop
----------------------------------------------------------------------
Conn(RunService.Heartbeat, function(dt)
	for _, m in ipairs(Modules) do if m.Enabled and m.OnTick then Safe(m.OnTick, m, dt) end end
end)

----------------------------------------------------------------------
-- gui root
----------------------------------------------------------------------
local Gui = New("ScreenGui", { Name = "ZenithClient", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 2147483647 }, PG)
ui.Gui = Gui

-- Two coordinate spaces are in play. "Raw" space is the real screen: UserInputService's mouse,
-- Camera:WorldToViewportPoint / ViewportPointToRay, and where a Position offset actually draws.
-- "Abs" space is GuiObject.AbsolutePosition, which can sit one GUI inset above raw space.
-- ui.MousePos() returns the cursor in abs space (for sliders, the color wheel, hover calibration).
-- Anything you place with Position, like the tooltip or the FOV circle, uses the raw mouse instead.
function ui.CalDY()
	local origin = ui.MenuFrame and -ui.MenuFrame.AbsolutePosition.Y or 0
	if not (ui.CalLo and ui.CalHi) then return origin end
	local inset = GuiService:GetGuiInset().Y
	for _, c in ipairs({ origin, 0, inset, -inset }) do
		if c >= ui.CalLo - 1.5 and c <= ui.CalHi + 1.5 then return c end
	end
	return (ui.CalLo + ui.CalHi) / 2
end
function ui.MousePos(i)
	if i and i.UserInputType == Enum.UserInputType.Touch then ui.TouchPos = Vector2.new(i.Position.X, i.Position.Y) end
	-- on a phone the "cursor" is the last touch; its position is already in GUI space
	if ui.Phone and ui.TouchPos then return ui.TouchPos end
	return UIS:GetMouseLocation() - Vector2.new(0, ui.CalDY())
end

local Blur = New("BlurEffect", { Name = "ZenithBlur", Size = 0 }, Lighting)

----------------------------------------------------------------------
-- ESP drawing
----------------------------------------------------------------------
local DrawGui = New("Frame", { Name = "ESP", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, Gui)
local Draw = {}
local function GetDraw(p)
	local d = Draw[p]; if d then return d end
	d = {}
	d.Box = New("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, DrawGui)
	d.Stroke = New("UIStroke", { Thickness = 1.5 }, d.Box)
	d.Label = New("TextLabel", { BackgroundTransparency = 1, Font = FONT_B, TextSize = 13, TextStrokeTransparency = 0.4, Size = UDim2.fromOffset(260, 16), AnchorPoint = Vector2.new(0.5, 1), Visible = false }, DrawGui)
	d.HBg = New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false }, DrawGui)
	d.HFill = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, d.HBg)
	d.Tracer = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false }, DrawGui)
	Draw[p] = d
	return d
end
local function HideDraw(d) d.Box.Visible, d.Label.Visible, d.HBg.Visible, d.Tracer.Visible = false, false, false, false end
Conn(Players.PlayerRemoving, function(p)
	local d = Draw[p]
	if d then d.Box:Destroy(); d.Label:Destroy(); d.HBg:Destroy(); d.Tracer:Destroy(); Draw[p] = nil end
	if ChamObjs[p] then ChamObjs[p]:Destroy(); ChamObjs[p] = nil end
end)

local BOX = Vector3.new(2.2, 2.9, 2.2)
local function Project(root)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	local c = root.Position
	for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
				local v = Camera:WorldToViewportPoint(c + Vector3.new(sx * BOX.X, sy * BOX.Y, sz * BOX.Z))
				if v.Z <= 0 then return nil end
				minX, maxX = math.min(minX, v.X), math.max(maxX, v.X)
				minY, maxY = math.min(minY, v.Y), math.max(maxY, v.Y)
			end end end
	return minX, minY, maxX, maxY
end

local function SetLine(f, a, b, thick)
	local dx, dy = b.X - a.X, b.Y - a.Y
	f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), thick)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Rotation = math.deg(math.atan2(dy, dx))
	f.Visible = true
end

local function UpdateESP()
	if not (ESP.Enabled or Names.Enabled or Tracers.Enabled) then
		for _, d in pairs(Draw) do HideDraw(d) end
		return
	end
	local vp = Camera.ViewportSize
	local me = Root()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local d = GetDraw(p)
			local ch = p.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local okE = ESP.Enabled and Pass(ESP, p, root)
				local okN = Names.Enabled and Pass(Names, p, root)
				local okT = Tracers.Enabled and Pass(Tracers, p, root)
				local x1, y1, x2, y2
				if okE or okN then x1, y1, x2, y2 = Project(root) end
				if okE and x1 then
					d.Box.Visible = true
					d.Box.Position = UDim2.fromOffset(x1, y1)
					d.Box.Size = UDim2.fromOffset(x2 - x1, y2 - y1)
					d.Stroke.Color = ColorFor(p, ESP.Values.Color)
					if ESP.Values["Health Bar"] then
						local f = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
						d.HBg.Visible = true
						d.HBg.Position = UDim2.fromOffset(x1 - 6, y1)
						d.HBg.Size = UDim2.fromOffset(3, y2 - y1)
						d.HFill.Size = UDim2.fromScale(1, f)
						d.HFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(70, 255, 100), f)
					else d.HBg.Visible = false end
				else d.Box.Visible, d.HBg.Visible = false, false end
				if okN and x1 then
					local dist = me and (root.Position - me.Position).Magnitude or 0
					local txt = p.DisplayName
					if Names.Values["Show Distance"] then txt ..= (" [%dm]"):format(dist) end
					if Names.Values["Show Health"] then txt ..= (" %dhp"):format(hum.Health) end
					d.Label.Visible = true
					d.Label.Text = txt
					d.Label.TextColor3 = ColorFor(p, Names.Values.Color)
					d.Label.Position = UDim2.fromOffset((x1 + x2) / 2, y1 - 2)
				else d.Label.Visible = false end
				if okT then
					local v = Camera:WorldToViewportPoint(root.Position)
					if v.Z > 0 then
						local o = Tracers.Values.Origin
						local origin = o == "Bottom" and Vector2.new(vp.X / 2, vp.Y) or o == "Center" and vp / 2 or UIS:GetMouseLocation()
						d.Tracer.BackgroundColor3 = ColorFor(p, Tracers.Values.Color)
						SetLine(d.Tracer, origin, Vector2.new(v.X, v.Y), Tracers.Values.Thickness)
					else d.Tracer.Visible = false end
				else d.Tracer.Visible = false end
			else HideDraw(d) end
		end
	end
end

----------------------------------------------------------------------
-- notifications (bottom right)
----------------------------------------------------------------------
do
local NotifHolder = New("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(240, 320), BackgroundTransparency = 1, ZIndex = 50 }, Gui)
New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, NotifHolder)
local notifCount = 0
function ui.Notify(text, good)
	if not Notifs.Enabled then return end
	notifCount += 1
	local f = New("Frame", { Size = UDim2.fromOffset(230, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C_HEAD, BackgroundTransparency = 0.1, BorderSizePixel = 0, LayoutOrder = notifCount }, NotifHolder)
	New("Frame", { Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, BackgroundColor3 = good == false and Color3.fromRGB(255, 80, 90) or Accent() }, f)
	-- long messages wrap onto more lines and the box grows taller to fit them
	local l = New("TextLabel", { Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 13, TextColor3 = WHITE, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, f)
	New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, l)
	task.delay(Notifs.Values.Duration, function()
		if f.Parent then
			TweenService:Create(f, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(l, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.wait(0.3)
			f:Destroy()
		end
	end)
end
end

----------------------------------------------------------------------
-- ArrayList (right side, starting at the top)
----------------------------------------------------------------------
local TopRight = New("Frame", { Name = "TopRight", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 1 }, Gui)
New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, TopRight)
ui.TopRight = TopRight

local ListHolder = New("Frame", { Name = "ArrayList", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, TopRight)
New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, ListHolder)

local ListEntries = {}
local TWEEN_IN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local NoSuffix = { ClickTP = true, Zoom = true, Theme = true, GUI = true, Configs = true }
local function GetSuffix(m)
	for _, s in ipairs(m.Settings or {}) do
		if s.Suffix then return tostring(m.Values[s.Name]) end
	end
	if NoSuffix[m.Name] then return nil end
	for _, s in ipairs(m.Settings or {}) do
		if s.Type == "Mode" and (s.Name == "Mode" or s.Name == "Method" or s.Name == "Style") then return tostring(m.Values[s.Name]) end
	end
end

-- entry = clipped outer frame (animates its height) holding an inner frame (slides in from the right)
local function CreateEntry(w, rowH)
	local e = { idx = 1, w = w, h = rowH }
	e.outer = New("Frame", { Size = UDim2.fromOffset(w, 0), BackgroundTransparency = 1, ClipsDescendants = true, BorderSizePixel = 0 }, ListHolder)
	e.inner = New("Frame", { Size = UDim2.new(1, 0, 0, rowH), Position = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, e.outer)
	e.lbl = New("TextLabel", { BackgroundTransparency = 1, Font = FONT, RichText = true, TextXAlignment = Enum.TextXAlignment.Left }, e.inner)
	New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, e.lbl)
	e.bar = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0 }, e.inner)
	AddPainter(e.lbl, function() e.lbl.TextColor3 = Accent(e.idx * 0.03) end)
	AddPainter(e.bar, function() e.bar.BackgroundColor3 = Accent(e.idx * 0.03) end)
	e.tw = TweenService:Create(e.outer, TWEEN_IN, { Size = UDim2.fromOffset(w, rowH) })
	e.tw.Completed:Connect(function() e.tw = nil end)
	e.tw:Play()
	TweenService:Create(e.inner, TWEEN_IN, { Position = UDim2.fromScale(0, 0) }):Play()
	return e
end

local function UpdateEntry(e, it, V, order, rowH)
	e.idx = order
	e.outer.LayoutOrder = order
	if e.w ~= it.w or e.h ~= rowH then
		e.w, e.h = it.w, rowH
		if e.tw then e.tw:Cancel(); e.tw = nil end
		e.outer.Size = UDim2.fromOffset(it.w, rowH)
		e.inner.Size = UDim2.new(1, 0, 0, rowH)
	end
	e.inner.BackgroundTransparency = V.Background and (1 - V.Opacity) or 1
	e.lbl.Size = UDim2.new(1, V["Side Bar"] and -2 or 0, 1, 0)
	e.lbl.TextSize = V["Text Size"]
	e.lbl.TextStrokeTransparency = V.Background and 1 or 0.6
	local txt = it.name
	if it.suffix then txt ..= " <font color=\"rgb(170,170,180)\">" .. it.suffix .. "</font>" end
	e.lbl.Text = txt
	e.bar.Visible = V["Side Bar"]
end

local function RemoveEntry(e)
	if e.tw then e.tw:Cancel(); e.tw = nil end
	TweenService:Create(e.inner, TWEEN_OUT, { Position = UDim2.fromScale(1, 0) }):Play()
	local t = TweenService:Create(e.outer, TWEEN_OUT, { Size = UDim2.fromOffset(e.w, 0) })
	t.Completed:Connect(function() e.outer:Destroy() end)
	t:Play()
end

local function RebuildArrayList()
	ListHolder.Visible = ArrayList.Enabled
	local V = ArrayList.Values
	local size = V["Text Size"]
	local rowH = size + 4
	local items, wanted = {}, {}
	for _, m in ipairs(Modules) do
		if m.Enabled and not m.Action and not m.Passive and m.Category ~= "Settings" then
			local suffix = V["Show Suffix"] and GetSuffix(m) or nil
			local plain = m.Name .. (suffix and (" " .. suffix) or "")
			local w = TextService:GetTextSize(plain, size, FONT, Vector2.new(1e4, 1e4)).X + 14 + (V["Side Bar"] and 2 or 0)
			table.insert(items, { m = m, name = m.Name, suffix = suffix, w = math.ceil(w) })
			wanted[m] = true
		end
	end
	if V.Sort == "Longest" then table.sort(items, function(a, b) return a.w > b.w end)
	elseif V.Sort == "Shortest" then table.sort(items, function(a, b) return a.w < b.w end)
	else table.sort(items, function(a, b) return a.name < b.name end) end

	for m, e in pairs(ListEntries) do
		if not wanted[m] then ListEntries[m] = nil; RemoveEntry(e) end
	end
	for i, it in ipairs(items) do
		local e = ListEntries[it.m]
		if not e then e = CreateEntry(it.w, rowH); ListEntries[it.m] = e end
		UpdateEntry(e, it, V, i, rowH)
	end
end
ui.RebuildList = RebuildArrayList

----------------------------------------------------------------------
-- menu root
----------------------------------------------------------------------
local Menu = New("Frame", { Name = "Menu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 10 }, Gui)
ui.MenuFrame = Menu
local Dim = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, Menu)
-- every panel lives in this frame, which the mouse wheel slides up and down
ui.ScrollY, ui.ScrollTarget = 0, 0
ui.Scroller = New("Frame", { Name = "Scroller", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }, Menu)

-- gradient themes: panel underlines become a drifting gradient of the theme's colors
ui.Lines = {}
function ui.StyleLine(line, offset, header)
	local g = New("UIGradient", { Enabled = false }, line)
	table.insert(ui.Lines, g)
	local cur
	AddPainter(line, function()
		local st = Themes.G[ThemeName]
		if st then
			if cur ~= ThemeName then
				cur = ThemeName
				local n, kp = #st, {}
				for i, c in ipairs(st) do kp[i] = ColorSequenceKeypoint.new((i - 1) / (n - 1), c) end
				g.Color = ColorSequence.new(kp)
			end
			line.BackgroundColor3 = WHITE
		else
			line.BackgroundColor3 = Accent(offset)
		end
		g.Enabled = st ~= nil
	end)
end
-- gradient themes: the panel underlines slowly shimmer
function ui.AuroraStep()
	if not Themes.G[ThemeName] then return end
	local t = tick()
	for i, g in ipairs(ui.Lines) do g.Offset = Vector2.new(math.sin(t * 0.5 + i) * 0.3, 0) end
end
local Modal = New("TextButton", { Size = UDim2.new(), BackgroundTransparency = 1, Text = "", Modal = false }, Menu)

-- hover description bar
local DescLabel = New("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = C_HEAD, BackgroundTransparency = 0.1, BorderSizePixel = 0, Font = FONT, TextSize = 13, TextColor3 = C_LIGHT, TextWrapped = true, RichText = true, Text = "", Visible = false, ZIndex = 300 }, Menu)
New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, DescLabel)
New("UISizeConstraint", { MaxSize = Vector2.new(560, 1e4) }, DescLabel)
do
local DescStroke = New("UIStroke", { Thickness = 1, Transparency = 0.3 }, DescLabel); Reg(DescStroke, "Color")
end
local function SetDesc(t) DescLabel.Text = t or ""; DescLabel.Visible = (t ~= nil and t ~= "") end

-- tooltip style follows the cursor; bottom bar style stays pinned
local function PlaceDesc()
	if ui.Phone or GuiSettings.Values["Description Style"] == "Bottom Bar" then
		DescLabel.AnchorPoint = Vector2.new(0.5, 1)
		DescLabel.Position = UDim2.new(0.5, 0, 1, -18)
		return
	end
	local mp, vp, sz = UIS:GetMouseLocation(), Gui.AbsoluteSize, DescLabel.AbsoluteSize
	local x = math.min(mp.X + 16, vp.X - sz.X - 6)
	local y = mp.Y + 22
	if y + sz.Y > vp.Y - 6 then y = mp.Y - sz.Y - 12 end
	DescLabel.AnchorPoint = Vector2.zero
	DescLabel.Position = UDim2.fromOffset(math.max(x, 6), math.max(y, 6))
end

do
local function Brief(str)
	if not str or str == "" then return "" end
	return str:match("^(.-%.)%s") or str
end
function ui.HoverText(title, desc)
	local d = Brief(desc)
	if d == "" then return "<b>" .. title .. "</b>" end
	return "<b>" .. title .. "</b>  -  " .. d
end
end

----------------------------------------------------------------------
-- hover system (checks the mouse against every target each frame,
-- so it can never get stuck like MouseEnter / MouseLeave can)
----------------------------------------------------------------------
local HoverTargets = {}
function ui.AddHover(inst, textFn, zref, cb)
	local t = { inst = inst, text = textFn, z = zref or inst, cb = cb, over = false, since = 0 }
	table.insert(HoverTargets, t)
	inst.MouseEnter:Connect(function() t.over = true; t.since = tick() end)
	inst.MouseLeave:Connect(function() t.over = false end)
end

local function Shown(inst)
	local o = inst
	while o and o ~= Gui do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o == Gui
end

local CurHover
local function SetHover(t)
	if CurHover == t then return end
	if CurHover and CurHover.cb then CurHover.cb(false) end
	CurHover = t
	if t then
		if t.cb then t.cb(true) end
		if GuiSettings.Values.Descriptions then SetDesc(t.text()) else SetDesc(nil) end
	else
		SetDesc(nil)
	end
end

local function InsideClip(inst)
	local o = inst.Parent
	while o and o ~= Gui do
		if o:IsA("GuiObject") and o.ClipsDescendants then return true end
		o = o.Parent
	end
	return false
end

-- the engine says the cursor is inside t, so its real Y lies between t's top and bottom;
-- every such sample narrows down how far the raw cursor reading is off
local function Calibrate(t)
	local inst = t.inst
	if InsideClip(inst) then return end
	local p, sz = inst.AbsolutePosition, inst.AbsoluteSize
	if sz.Y > 60 then return end
	local ry = UIS:GetMouseLocation().Y
	local lo, hi = ry - (p.Y + sz.Y), ry - p.Y
	if not ui.CalLo or lo > ui.CalHi + 3 or hi < ui.CalLo - 3 then
		ui.CalLo, ui.CalHi = lo, hi
	else
		ui.CalLo = math.max(ui.CalLo - 0.2, lo)
		ui.CalHi = math.min(ui.CalHi + 0.2, hi)
		if ui.CalLo > ui.CalHi then
			local mid = (ui.CalLo + ui.CalHi) / 2
			ui.CalLo, ui.CalHi = mid, mid
		end
	end
end

local function UpdateHover()
	if not ui.MenuOpen then
		for _, t in ipairs(HoverTargets) do t.over = false end
		SetHover(nil)
		return
	end
	local best, bestZ
	for i = #HoverTargets, 1, -1 do
		local t = HoverTargets[i]
		if not t.inst.Parent then
			table.remove(HoverTargets, i)
		elseif t.over then
			if Shown(t.inst) then
				local z = t.z.ZIndex
				if not best or z > bestZ or (z == bestZ and t.since > best.since) then best, bestZ = t, z end
			else
				t.over = false
			end
		end
	end
	SetHover(best)
	if best then Calibrate(best) end
	if CurHover and GuiSettings.Values.Descriptions then
		local txt = CurHover.text()
		if DescLabel.Text ~= txt then DescLabel.Text = txt end
		DescLabel.Visible = true
		PlaceDesc()
	else
		DescLabel.Visible = false
	end
end

local Drag, PanelDrag, Listening
local ROWH, SETH, PANEL_W, HEADER_H, GAP = 26, 24, 190, 30, 12
if ui.Phone then ROWH, SETH, PANEL_W, HEADER_H = 32, 30, 210, 34 end

-- no right click on touch: a quick tap on a panel header (no dragging) folds the panel up or down
function ui.TapCollapse(header, content)
	header.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch then return end
		local start, t0 = Vector2.new(i.Position.X, i.Position.Y), tick()
		local c
		c = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then
				c:Disconnect()
				local moved = (Vector2.new(i.Position.X, i.Position.Y) - start).Magnitude
				if moved < 8 and tick() - t0 < 0.35 then content.Visible = not content.Visible end
			end
		end)
	end)
end

-- a panel's list of modules; on a phone it scrolls once it would be taller than the screen
function ui.MakeContent(panel)
	if not ui.Phone then
		local c = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, panel)
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, c)
		return c
	end
	local c = New("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, panel)
	local lay = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, c)
	local function fit()
		local maxH = math.max(120, ui.Gui.AbsoluteSize.Y * 0.7 - HEADER_H)
		c.Size = UDim2.new(1, 0, 0, math.min(lay.AbsoluteContentSize.Y, maxH))
	end
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	fit()
	return c
end

local function changed(m, name)
	if m.OnChanged then Safe(m.OnChanged, m, name) end
	ui.RebuildList()
end

----------------------------------------------------------------------
-- color picker (one shared popup used by every Color setting)
----------------------------------------------------------------------
local PK_W, PK_H, WR = 176, 236, 60
local Picker = New("Frame", { Name = "Picker", Size = UDim2.fromOffset(PK_W, PK_H), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 250 }, Menu)
do
local pkStroke = New("UIStroke", { Thickness = 1.5 }, Picker); Reg(pkStroke, "Color")
end
local pkTitle = New("TextLabel", { Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1, Font = FONT_B, TextSize = 13, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, Picker)
local pkClose = New("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(20, 18), BackgroundTransparency = 1, Font = FONT_B, TextSize = 14, TextColor3 = C_DIM, Text = "x" }, Picker)

local Wheel = New("Frame", { Position = UDim2.fromOffset(PK_W / 2 - WR, 34), Size = UDim2.fromOffset(WR * 2, WR * 2), BackgroundTransparency = 1 }, Picker)
do
	local WL, N = WR + 4, 90
	for i = 0, N - 1 do
		local hue = i / N
		local ang = hue * 2 * math.pi
		local spoke = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(ang) * WL / 2, 0.5, math.sin(ang) * WL / 2),
			Size = UDim2.fromOffset(WL, 6), Rotation = hue * 360,
			BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, Wheel)
		New("UIGradient", { Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(WR / WL, Color3.fromHSV(hue, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)),
		}) }, spoke)
	end
end
local WheelDark = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WR * 2, WR * 2), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, Wheel)
New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, WheelDark)
do
local WheelRing = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WR * 2, WR * 2), BackgroundTransparency = 1, BorderSizePixel = 0 }, Wheel)
New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, WheelRing)
New("UIStroke", { Thickness = 10, Color = C_HEAD, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, WheelRing)
end
local Marker = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0 }, Wheel)
New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, Marker)
New("UIStroke", { Thickness = 2, Color = WHITE }, Marker)
local WheelHit = New("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, Wheel)

local Bar = New("Frame", { Position = UDim2.fromOffset(18, 34 + WR * 2 + 14), Size = UDim2.fromOffset(PK_W - 36, 14), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Picker)
local BarGrad = New("UIGradient", { Color = ColorSequence.new(Color3.new(0, 0, 0), WHITE) }, Bar)
local Knob = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(4, 20), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, Bar)
New("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0) }, Knob)
local BarHit = New("TextButton", { Position = UDim2.fromOffset(12, 34 + WR * 2 + 8), Size = UDim2.fromOffset(PK_W - 24, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, Picker)

local Preview = New("Frame", { Position = UDim2.fromOffset(18, PK_H - 34), Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0 }, Picker)
New("UIStroke", { Thickness = 1, Color = Color3.fromRGB(80, 80, 98) }, Preview)
local RgbLabel = New("TextLabel", { Position = UDim2.fromOffset(66, PK_H - 34), Size = UDim2.new(1, -74, 0, 22), BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = C_LIGHT, TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, Picker)

local Pk = { m = nil, s = nil, h = 0, sat = 0, v = 1 }
local function PickerApply(fromUser)
	local col = Color3.fromHSV(Pk.h, Pk.sat, Pk.v)
	local ang = Pk.h * 2 * math.pi
	Marker.Position = UDim2.new(0.5, math.cos(ang) * Pk.sat * WR, 0.5, math.sin(ang) * Pk.sat * WR)
	Marker.BackgroundColor3 = col
	WheelDark.BackgroundTransparency = Pk.v
	BarGrad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(Pk.h, Pk.sat, 1))
	Knob.Position = UDim2.fromScale(Pk.v, 0.5)
	Preview.BackgroundColor3 = col
	RgbLabel.Text = string.format("R %d   G %d   B %d", B255(col.R), B255(col.G), B255(col.B))
	if fromUser and Pk.m then
		Pk.m.Values[Pk.s.Name] = col
		Repaint(Pk.m)
		changed(Pk.m, Pk.s.Name)
	end
end

local function WheelFromMouse(x, y)
	local c = Wheel.AbsolutePosition + Wheel.AbsoluteSize / 2
	local dx, dy = x - c.X, y - c.Y
	if Pk.v < 0.05 then Pk.v = 1 end
	Pk.sat = math.min(math.sqrt(dx * dx + dy * dy) / (Wheel.AbsoluteSize.X / 2), 1)
	Pk.h = (math.atan2(dy, dx) / (2 * math.pi)) % 1
	PickerApply(true)
end
do
local function BarFromMouse(x)
	Pk.v = math.clamp((x - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
	PickerApply(true)
end
WheelHit.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		Drag = WheelFromMouse
		local ml = ui.MousePos(i); WheelFromMouse(ml.X, ml.Y)
	end
end)
BarHit.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		Drag = function(x) BarFromMouse(x) end
		BarFromMouse(ui.MousePos(i).X)
	end
end)
end

local function ClosePicker() Picker.Visible = false; Pk.m, Pk.s = nil, nil end
pkClose.MouseButton1Click:Connect(ClosePicker)

function ui.OpenPicker(m, s, row)
	if Picker.Visible and Pk.m == m and Pk.s == s then ClosePicker() return end
	Pk.m, Pk.s = m, s
	Pk.h, Pk.sat, Pk.v = m.Values[s.Name]:ToHSV()
	pkTitle.Text = m.Name .. ": " .. s.Name
	local rp, rs = row.AbsolutePosition, row.AbsoluteSize
	local vp = Camera.ViewportSize
	local org = Menu.AbsolutePosition
	local x = rp.X - org.X + rs.X + 8
	if x + PK_W > vp.X then x = rp.X - org.X - PK_W - 8 end
	local y = math.clamp(rp.Y - org.Y - 20, 10, math.max(vp.Y - PK_H - 10, 10))
	Picker.Position = UDim2.fromOffset(math.max(x, 4), y)
	Picker.Visible = true
	PickerApply(false)
end

do
local function pickerText() return ui.HoverText("Color wheel", "Click or drag to pick a color. The bar sets brightness.") end
for _, o in ipairs({ Picker, WheelHit, BarHit, pkClose }) do ui.AddHover(o, pickerText, Picker) end
end

----------------------------------------------------------------------
-- setting rows
----------------------------------------------------------------------
local function SettingButton(parent, order)
	return New("TextButton", { Size = UDim2.new(1, 0, 0, SETH), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order }, parent)
end
local function SettingLabel(row, text)
	return New("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 12, TextColor3 = C_LIGHT, TextXAlignment = Enum.TextXAlignment.Left }, row)
end
local function RightLabel(row)
	return New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Font = FONT, TextSize = 12, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Right }, row)
end

local function SliderRow(m, s, parent, order)
	local row = SettingButton(parent, order)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.5 }, row)
	Reg(fill, "BackgroundColor3")
	SettingLabel(row, s.Name)
	local valL = RightLabel(row)
	local function show()
		local v = m.Values[s.Name]
		fill.Size = UDim2.fromScale(math.clamp((v - s.Min) / (ui.MaxOf(s) - s.Min), 0, 1), 1)
		valL.Text = Fmt(v)
	end
	show()
	table.insert(ui.SliderRows, { row = row, show = show })
	local function setFromX(x)
		local a = math.clamp((x - row.AbsolutePosition.X) / math.max(row.AbsoluteSize.X, 1), 0, 1)
		local hi = ui.MaxOf(s)
		local v = s.Min + (hi - s.Min) * a
		v = s.Min + math.floor((v - s.Min) / s.Step + 0.5) * s.Step
		v = tonumber(string.format("%.4f", math.clamp(v, s.Min, hi)))
		m.Values[s.Name] = v
		show(); changed(m, s.Name)
	end
	row.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			Drag = function(x) setFromX(x) end
			setFromX(ui.MousePos(i).X)
		end
	end)
	return row
end

function ui.RefreshSliders()
	local list = ui.SliderRows
	for i = #list, 1, -1 do
		local r = list[i]
		if r.row.Parent then r.show() else table.remove(list, i) end
	end
end
function ui.OnHighChanged()
	for _, c in ipairs(ui.ClampSliders()) do
		local m = c[1]
		if m.OnChanged then Safe(m.OnChanged, m, c[2]) end
	end
	ui.RefreshSliders()
	ui.RebuildList()
end

local function ToggleRow(m, s, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, s.Name)
	local box = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0 }, row)
	New("UIStroke", { Color = Color3.fromRGB(70, 70, 88), Thickness = 1 }, box)
	local function paint() box.BackgroundColor3 = m.Values[s.Name] and Accent() or Color3.fromRGB(30, 30, 40) end
	AddPainter(box, paint)
	row.MouseButton1Click:Connect(function() m.Values[s.Name] = not m.Values[s.Name]; paint(); changed(m, s.Name) end)
	return row
end

local function ModeRow(m, s, parent, order)
	local function opts() return type(s.Options) == "function" and s.Options() or s.Options end
	if type(s.Options) == "function" then
		local o = opts()
		if not table.find(o, m.Values[s.Name]) then m.Values[s.Name] = o[1] end
	end
	local row = SettingButton(parent, order)
	SettingLabel(row, s.Name)
	local valL = RightLabel(row)
	Reg(valL, "TextColor3")
	local function refresh() valL.Text = tostring(m.Values[s.Name]) end
	refresh()
	AddPainter(valL, refresh)
	local function step(dir)
		local o = opts()
		local idx = table.find(o, m.Values[s.Name]) or 0
		idx = ((idx - 1 + dir) % #o) + 1
		m.Values[s.Name] = o[idx]
		refresh(); changed(m, s.Name)
	end
	row.MouseButton1Click:Connect(function() step(1) end)
	row.MouseButton2Click:Connect(function() step(-1) end)
	return row
end

local function ColorRow(m, s, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, s.Name)
	local sw = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 12), BorderSizePixel = 0 }, row)
	New("UIStroke", { Color = Color3.fromRGB(90, 90, 108), Thickness = 1 }, sw)
	AddPainter(sw, function() sw.BackgroundColor3 = m.Values[s.Name] end, m)
	row.MouseButton1Click:Connect(function() ui.OpenPicker(m, s, row) end)
	return row
end

local function ButtonRow(m, s, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, s.Name)
	local r = RightLabel(row)
	r.Text = "click"
	Reg(r, "TextColor3")
	row.MouseButton1Click:Connect(function() Safe(s.Fn, m) end)
	return row
end

function ui.TextRow(m, s, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, s.Name)
	local box = New("TextBox", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.5, 0, 1, -6), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, ClearTextOnFocus = false, Font = FONT, TextSize = 12, TextColor3 = WHITE, PlaceholderText = s.Placeholder or "type here", PlaceholderColor3 = C_DIM, Text = tostring(m.Values[s.Name] or ""), TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true }, row)
	New("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
	New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, box)
	box.FocusLost:Connect(function() m.Values[s.Name] = box.Text end)
	return row
end

local function BindRow(m, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, "Bind")
	local valL = RightLabel(row)
	AddPainter(valL, function()
		valL.TextColor3 = C_DIM
		valL.Text = m.Bind and ("[" .. m.Bind.Name .. "]") or "[NONE]"
	end, m)
	row.MouseButton1Click:Connect(function()
		if Listening then Repaint(Listening.m) end
		Listening = { m = m }
		valL.Text = "[ press a key ]"
	end)
	return row
end

----------------------------------------------------------------------
-- module row (used in panels and in search results)
----------------------------------------------------------------------
local function BindModeRow(m, parent, order)
	local row = SettingButton(parent, order)
	SettingLabel(row, "Bind Mode")
	local valL = RightLabel(row)
	Reg(valL, "TextColor3")
	local function refresh() valL.Text = m.BindMode end
	refresh()
	local function flip() m.BindMode = (m.BindMode == "Hold") and "Toggle" or "Hold"; refresh() end
	row.MouseButton1Click:Connect(flip)
	row.MouseButton2Click:Connect(flip)
	return row
end

local function BuildModuleRow(m, parent, showCat, idx, zref)
	local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = idx or 0 }, parent)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, holder)

	local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, ROWH), BackgroundColor3 = C_ROW, BackgroundTransparency = 0.05, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = 1 }, holder)
	local nameL = New("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = m.Name, Font = FONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, btn)
	New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = showCat and m.Category or "", Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Right }, btn)
	local ind = New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(12, ROWH), BackgroundTransparency = 1, Font = FONT_B, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center }, btn)

	-- fixed height + clipping so the settings can be tweened open and closed
	local setFrame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, BackgroundColor3 = C_SET, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, LayoutOrder = 2 }, holder)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, setFrame)

	local expanded, hover = false, false
	local function paint()
		if m.Enabled then
			btn.BackgroundColor3 = Accent((idx or 0) * 0.05):Lerp(Color3.new(0, 0, 0), 0.25)
			btn.BackgroundTransparency = 0
		else
			btn.BackgroundColor3 = hover and C_ROWHOV or C_ROW
			btn.BackgroundTransparency = 0.05
		end
		nameL.TextColor3 = (m.Enabled or hover) and WHITE or C_LIGHT
		ind.Text = expanded and "-" or "+"
		ind.TextColor3 = m.Enabled and WHITE or C_DIM
	end
	AddPainter(btn, paint, m)

	local rows = 0
	for _, s in ipairs(m.Settings or {}) do
		rows += 1
		local row
		if s.Type == "Slider" then row = SliderRow(m, s, setFrame, rows)
		elseif s.Type == "Mode" then row = ModeRow(m, s, setFrame, rows)
		elseif s.Type == "Color" then row = ColorRow(m, s, setFrame, rows)
		elseif s.Type == "Button" then row = ButtonRow(m, s, setFrame, rows)
		elseif s.Type == "Text" then row = ui.TextRow(m, s, setFrame, rows)
		else row = ToggleRow(m, s, setFrame, rows) end
		ui.AddHover(row, function() return ui.HoverText(m.Name .. ": " .. s.Name, s.Desc) end, zref)
	end
	if not m.Passive then
		rows += 1
		local row = BindRow(m, setFrame, rows)
		ui.AddHover(row, function()
			return ui.HoverText(m.Name .. ": Bind", "Sets a key that " .. (m.Action and "runs" or "toggles") .. " this module.")
		end, zref)
		if not m.Action then
			rows += 1
			local mrow = BindModeRow(m, setFrame, rows)
			ui.AddHover(mrow, function()
				return ui.HoverText(m.Name .. ": Bind Mode", "Toggle switches it on and off with the key, Hold keeps it on only while the key is down.")
			end, zref)
		end
	end
	local fullH = rows * SETH

	ui.AddHover(btn, function() return ui.HoverText(m.Name, m.Desc) end, zref, function(on) hover = on; paint() end)

	local expTween
	local function toggleExpand()
		expanded = not expanded
		if expTween then expTween:Cancel() end
		if expanded then
			setFrame.Visible = true
			expTween = TweenService:Create(setFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, fullH) })
		else
			if Pk.m == m then ClosePicker() end
			local t = TweenService:Create(setFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) })
			t.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and not expanded then setFrame.Visible = false end
			end)
			expTween = t
		end
		expTween:Play()
		paint()
	end
	btn.MouseButton1Click:Connect(function()
		if m._longPressed then m._longPressed = false return end
		if m.Passive then toggleExpand() else ToggleModule(m) end
	end)
	btn.MouseButton2Click:Connect(toggleExpand)
	-- touch has no right click: press and hold a module to open its settings
	btn.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch then return end
		local start = Vector2.new(i.Position.X, i.Position.Y)
		task.delay(0.45, function()
			if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then return end
			if (Vector2.new(i.Position.X, i.Position.Y) - start).Magnitude > 10 then return end
			m._longPressed = true
			toggleExpand()
		end)
	end)
	return holder
end

----------------------------------------------------------------------
-- panels
----------------------------------------------------------------------
local PanelFrames, PanelContents, PanelOrder = {}, {}, {}
local function Raise(panel)
	local i = table.find(PanelOrder, panel); if i then table.remove(PanelOrder, i) end
	table.insert(PanelOrder, panel)
	for n, p in ipairs(PanelOrder) do p.ZIndex = 4 + n end
end

do
local function CreatePanel(cat, index)
	local panel = New("Frame", { Name = cat, Size = UDim2.fromOffset(PANEL_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, ui.Scroller)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	local header = New("TextButton", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = 1 }, panel)
	New("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -40, 1, -2), BackgroundTransparency = 1, Text = cat, Font = FONT_B, TextSize = 15, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left }, header)
	New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 24, 1, -2), BackgroundTransparency = 1, Text = tostring(#ByCat[cat]), Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Right }, header)
	local line = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, header)
	ui.StyleLine(line, index * 0.12, header)

	local content = ui.MakeContent(panel)
	for i, m in ipairs(ByCat[cat]) do BuildModuleRow(m, content, false, i, panel) end

	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			ClosePicker()
			ui.BeginDrag(panel, i)
			Raise(panel)
		end
	end)
	header.MouseButton2Click:Connect(function() content.Visible = not content.Visible end)
	ui.TapCollapse(header, content)
	ui.AddHover(header, function()
		return ui.HoverText(cat, CatDesc[cat])
	end, panel)

	PanelFrames[index], PanelContents[index] = panel, content
	table.insert(PanelOrder, panel)
end
for i, cat in ipairs(Categories) do CreatePanel(cat, i) end
end

-- the Hub is the only tab open at first; it opens and closes every other tab
local HubPanel, HubContent
local HubPaints = {}
local function HubRefresh() for _, f in ipairs(HubPaints) do f() end end

-- panels can never leave the screen: the whole width and the header always stay visible
function ui.ClampXY(x, y)
	local vp = Vector2.new(math.min(ui.Gui.AbsoluteSize.X, Camera.ViewportSize.X), math.min(ui.Gui.AbsoluteSize.Y, Camera.ViewportSize.Y))
	local top = -(ui.ScrollY or 0)
	local sc = GuiSettings.Values["UI Scale"] or 1
	return math.clamp(x, 0, math.max(vp.X - PANEL_W * sc, 0)), math.clamp(y, top, math.max(vp.Y - HEADER_H * sc + top, top))
end
local function ClampPanel(p)
	local x, y = ui.ClampXY(p.Position.X.Offset, p.Position.Y.Offset)
	p.Position = UDim2.fromOffset(x, y)
end
function ui.ClampPanels()
	if HubPanel then ClampPanel(HubPanel) end
	for _, p in ipairs(PanelFrames) do ClampPanel(p) end
end

do
local function SetTab(index, open)
	local panel = PanelFrames[index]
	if not panel or panel.Visible == open then return end
	if open then
		ClampPanel(panel)
		panel.Visible = true
		Raise(panel)
		local pos = panel.Position
		panel.Position = pos + UDim2.fromOffset(0, 12)
		TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pos }):Play()
	else
		if Pk.m and Pk.m.Category == Categories[index] then ClosePicker() end
		panel.Visible = false
	end
	HubRefresh()
end
ui.SetTab = SetTab

do
	local panel = New("Frame", { Name = "Hub", Size = UDim2.fromOffset(PANEL_W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0 }, ui.Scroller)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	local header = New("TextButton", { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = 1 }, panel)
	New("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, -2), BackgroundTransparency = 1, Text = "Hub", Font = FONT_B, TextSize = 15, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left }, header)
	New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 44, 1, -2), BackgroundTransparency = 1, Text = VERSION, Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Right }, header)
	local line = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, header)
	ui.StyleLine(line, 0, header)

	local content = ui.MakeContent(panel)

	local function Row(order, text)
		local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, ROWH), BackgroundColor3 = C_ROW, BackgroundTransparency = 0.05, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order }, content)
		local nameL = New("TextLabel", { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, btn)
		return btn, nameL
	end

	for i, cat in ipairs(Categories) do
		local btn, nameL = Row(i, cat)
		New("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.3, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(#ByCat[cat]), Font = FONT, TextSize = 11, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Right }, btn)
		local hover = false
		local function paint()
			local open = PanelFrames[i].Visible
			if open then
				btn.BackgroundColor3 = Accent(i * 0.12):Lerp(Color3.new(0, 0, 0), 0.25)
				btn.BackgroundTransparency = 0
			else
				btn.BackgroundColor3 = hover and C_ROWHOV or C_ROW
				btn.BackgroundTransparency = 0.05
			end
			nameL.TextColor3 = (open or hover) and WHITE or C_LIGHT
		end
		AddPainter(btn, paint)
		table.insert(HubPaints, paint)
		btn.MouseButton1Click:Connect(function() SetTab(i, not PanelFrames[i].Visible) end)
		ui.AddHover(btn, function() return ui.HoverText(cat, CatDesc[cat]) end, panel, function(on) hover = on; paint() end)
	end

	local function ActionRow(order, text, desc, fn)
		local btn, nameL = Row(order, text)
		nameL.TextColor3 = C_DIM
		btn.MouseButton1Click:Connect(fn)
		ui.AddHover(btn, function() return ui.HoverText(text, desc) end, panel, function(on)
			btn.BackgroundColor3 = on and C_ROWHOV or C_ROW
			nameL.TextColor3 = on and WHITE or C_DIM
		end)
	end
	local n = #Categories
	ActionRow(n + 1, "Open All", "Opens every tab.", function() for i = 1, n do SetTab(i, true) end end)
	ActionRow(n + 2, "Close All", "Closes every tab and leaves only the Hub.", function() for i = 1, n do SetTab(i, false) end end)

	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			ClosePicker()
			ui.BeginDrag(panel, i)
			Raise(panel)
		end
	end)
	header.MouseButton2Click:Connect(function() content.Visible = not content.Visible end)
	ui.TapCollapse(header, content)
	ui.AddHover(header, function() return ui.HoverText("Hub", "Open and close the tabs you want to see.") end, panel)

	HubPanel, HubContent = panel, content
	table.insert(PanelOrder, panel)
end
end

function ui.ResetPanels()
	ClosePicker()
	ui.ScrollY, ui.ScrollTarget = 0, 0
	ui.Scroller.Position = UDim2.new()
	local vp = Camera.ViewportSize
	if vp.X < 400 then vp = Vector2.new(1280, 720) end
	local sc = GuiSettings.Values["UI Scale"] or 1
	local cols = #PanelFrames + 1
	local step = math.min((PANEL_W + GAP) * sc, (vp.X - 20 - PANEL_W * sc) / (cols - 1))
	local total = (cols - 1) * step + PANEL_W * sc
	local x0 = math.max(10, (vp.X - total) / 2)
	HubPanel.Position = UDim2.fromOffset(x0, 70)
	HubContent.Visible = true
	Raise(HubPanel)
	for i, p in ipairs(PanelFrames) do
		p.Position = UDim2.fromOffset(x0 + i * step, 70)
		PanelContents[i].Visible = true
		Raise(p)
	end
end
ui.ResetPanels()
HubRefresh()

function ui.BuildConfig()
	local cfg = { version = VERSION, modules = {}, panels = {} }
	for _, m in ipairs(Modules) do
		if m.NoSave then continue end
		local e = { values = {}, bindMode = m.BindMode }
		if m.Bind then e.bind = m.Bind.Name end
		if not m.Action and not m.Passive then e.enabled = m.Enabled end
		for _, st in ipairs(m.Settings or {}) do e.values[st.Name] = ui.EncodeValue(m.Values[st.Name]) end
		cfg.modules[m.Name] = e
	end
	cfg.panels.Hub = { x = HubPanel.Position.X.Offset, y = HubPanel.Position.Y.Offset, collapsed = not HubContent.Visible }
	for i, cat in ipairs(Categories) do
		local p = PanelFrames[i]
		cfg.panels[cat] = { x = p.Position.X.Offset, y = p.Position.Y.Offset, open = p.Visible, collapsed = not PanelContents[i].Visible }
	end
	return cfg
end

function ui.SaveConfig()
	if not ui.CanFS then
		ui.Notify("Saving needs an executor with writefile and readfile", false)
		return
	end
	local ok, err = pcall(function()
		writefile(ui.ConfigFile, game:GetService("HttpService"):JSONEncode(ui.BuildConfig()))
	end)
	if ok then
		ui.Notify("Settings saved", true)
	else
		ui.Notify("Could not save settings", false)
		warn("[Zenith] " .. tostring(err))
	end
end

-- written right before a rejoin or teleport, so the next session picks up exactly where this one left off
function ui.SaveSession()
	if not ui.CanFS then return end
	pcall(function()
		local cfg = ui.BuildConfig()
		cfg.t = os.time()
		writefile(ui.SessionFile, game:GetService("HttpService"):JSONEncode(cfg))
	end)
end

-- panel positions, which tabs are open and which are collapsed
function ui.ApplyLayout(cfg)
	local P = cfg.panels
	if type(P) ~= "table" then return end
	local function place(panel, e)
		if type(e) == "table" and type(e.x) == "number" and type(e.y) == "number" then
			panel.Position = UDim2.fromOffset(e.x, e.y)
		end
	end
	place(HubPanel, P.Hub)
	if type(P.Hub) == "table" then HubContent.Visible = P.Hub.collapsed ~= true end
	for i, cat in ipairs(Categories) do
		local e = P[cat]
		if type(e) == "table" then
			place(PanelFrames[i], e)
			if type(e.open) == "boolean" then PanelFrames[i].Visible = e.open end
			PanelContents[i].Visible = e.collapsed ~= true
		end
	end
	HubRefresh()
	ui.ClampPanels()
end


----------------------------------------------------------------------
-- game configs: names, add, save, load, delete
----------------------------------------------------------------------
-- shown name of a config; two games with the same title get their id added
function ui.GameLabel(g)
	local n = 0
	for _, o in ipairs(ui.Games) do if o.name == g.name then n += 1 end end
	return n > 1 and (g.name .. " [" .. g.id .. "]") or g.name
end
function ui.GameNames()
	local t = { "Default" }
	for _, g in ipairs(ui.Games) do table.insert(t, ui.GameLabel(g)) end
	return t
end
-- the selected game config, or nil when Default is selected
function ui.TargetGame()
	local v = ui.ConfigsMod.Values.Target
	for _, g in ipairs(ui.Games) do if ui.GameLabel(g) == v then return g end end
end
-- applies a whole config to the running client and refreshes everything on screen
function ui.CfgApply(cfg)
	ui.ApplyConfigValues(cfg)
	ui.ApplyConfigEnabled(cfg)
	ui.ApplyLayout(cfg)
	ui.OnHighChanged()
	ui.ApplyInterface()
	Repaint()
end
function ui.AddGameConfig()
	if not ui.CanFS then ui.Notify("Game configs need an executor with file functions", false) return end
	if ui.FindGame(ui.GameKey) then
		ui.Notify("This game already has a config. Select it and use Save Config", false)
		return
	end
	task.spawn(function()
		local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
		local name = ok and type(info) == "table" and type(info.Name) == "string" and info.Name or ("Game " .. ui.GameKey)
		if ui.FindGame(ui.GameKey) then return end
		local entry = { id = ui.GameKey, name = name, cfg = ui.BuildConfig() }
		table.insert(ui.Games, entry)
		if ui.WriteGames() then
			ui.ConfigsMod.Values.Target = ui.GameLabel(entry)
			Repaint()
			ui.Notify("Added config for " .. name .. ". Settings you save now go to it", true)
		else
			table.remove(ui.Games, #ui.Games)
			ui.Notify("Could not save the new config", false)
		end
	end)
end
function ui.SaveTarget()
	local g = ui.TargetGame()
	if not g then ui.SaveConfig() return end
	if not ui.CanFS then ui.Notify("Saving needs an executor with writefile and readfile", false) return end
	g.cfg = ui.BuildConfig()
	if ui.WriteGames() then ui.Notify("Saved to " .. g.name, true) else ui.Notify("Could not save the config", false) end
end
function ui.LoadTarget()
	local g = ui.TargetGame()
	local cfg = g and g.cfg or ui.ReadConfig()
	if not cfg then ui.Notify("Nothing saved there yet", false) return end
	ui.CfgApply(cfg)
	ui.Notify("Loaded " .. (g and g.name or "default settings"), true)
end
function ui.DeleteTarget()
	local g = ui.TargetGame()
	if not g then ui.Notify("The Default config can't be deleted", false) return end
	table.remove(ui.Games, table.find(ui.Games, g))
	ui.ConfigsMod.Values.Target = "Default"
	Repaint()
	if ui.WriteGames() then ui.Notify("Deleted " .. g.name, true) else ui.Notify("Could not update the config file", false) end
end

----------------------------------------------------------------------
-- search
----------------------------------------------------------------------
local SearchBar = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(340, 32), BackgroundColor3 = C_HEAD, BorderSizePixel = 0, ZIndex = 200 }, Menu)
do
local sStroke = New("UIStroke", { Thickness = 1.5 }, SearchBar); Reg(sStroke, "Color")
end
do
local SearchBox = New("TextBox", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, PlaceholderText = "Search any module...  (Ctrl+F)", PlaceholderColor3 = C_DIM, Text = "", ClearTextOnFocus = false, Font = FONT, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left }, SearchBar)
local Results = New("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 200 }, Menu)
New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Results)
local CurrentResults = {}
local function searchText() return ui.HoverText("Search", "Type to find any module from any tab.") end
ui.AddHover(SearchBar, searchText, SearchBar)
ui.AddHover(SearchBox, searchText, SearchBar)

local function RebuildSearch()
	for _, c in ipairs(Results:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local q = SearchBox.Text:lower()
	CurrentResults = {}
	if q == "" then return end
	for _, m in ipairs(Modules) do
		if m.Name:lower():find(q, 1, true) or (m.Desc and m.Desc:lower():find(q, 1, true)) or m.Category:lower():find(q, 1, true) then
			table.insert(CurrentResults, m)
		end
	end
	table.sort(CurrentResults, function(a, b)
		local ap, bp = a.Name:lower():sub(1, #q) == q, b.Name:lower():sub(1, #q) == q
		if ap ~= bp then return ap end
		return a.Name < b.Name
	end)
	for i = 1, math.min(#CurrentResults, 8) do BuildModuleRow(CurrentResults[i], Results, true, i, Results) end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(RebuildSearch)
SearchBox.FocusLost:Connect(function(enter)
	if enter and CurrentResults[1] then ToggleModule(CurrentResults[1]) end
end)

----------------------------------------------------------------------
-- dragging (panels, HUD, sliders, color wheel)
----------------------------------------------------------------------
function ui.BeginDrag(frame, input, onEnd, clamp)
	PanelDrag = { panel = frame, start = Vector2.new(input.Position.X, input.Position.Y), pos = frame.Position, onEnd = onEnd, clamp = clamp }
end

Conn(UIS.InputChanged, function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
	if i.UserInputType == Enum.UserInputType.Touch then ui.TouchPos = Vector2.new(i.Position.X, i.Position.Y) end
	if Drag then
		local ml = ui.MousePos()
		Drag(ml.X, ml.Y)
	end
	if PanelDrag then
		local d = Vector2.new(i.Position.X, i.Position.Y) - PanelDrag.start
		local nx, ny = PanelDrag.pos.X.Offset + d.X, PanelDrag.pos.Y.Offset + d.Y
		nx, ny = ui.ClampXY(nx, ny)
		PanelDrag.panel.Position = UDim2.fromOffset(nx, ny)
	end
end)
-- how far the menu can scroll: until the lowest open panel's bottom edge is on screen
function ui.ScrollLimit()
	local bottom = 0
	local function chk(p) if p and p.Visible then bottom = math.max(bottom, p.Position.Y.Offset + p.AbsoluteSize.Y) end end
	chk(HubPanel)
	for _, p in ipairs(PanelFrames) do chk(p) end
	return math.max(0, bottom - ui.Gui.AbsoluteSize.Y + 40)
end
Conn(UIS.InputChanged, function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseWheel or not ui.MenuOpen or ui.Phone then return end
	if Typing() then return end
	if Picker.Visible then ClosePicker() end
	ui.ScrollTarget = math.clamp(ui.ScrollTarget + i.Position.Z * 70, -ui.ScrollLimit(), 0)
end)
function ui.ScrollStep(dt)
	if ui.MenuOpen then ui.ScrollTarget = math.clamp(ui.ScrollTarget, -ui.ScrollLimit(), 0) end
	if ui.ScrollY == ui.ScrollTarget then return end
	ui.ScrollY += (ui.ScrollTarget - ui.ScrollY) * math.min(1, dt * 14)
	if math.abs(ui.ScrollTarget - ui.ScrollY) < 0.5 then ui.ScrollY = ui.ScrollTarget end
	ui.Scroller.Position = UDim2.fromOffset(0, ui.ScrollY)
end
Conn(UIS.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if PanelDrag and PanelDrag.onEnd then Safe(PanelDrag.onEnd) end
		Drag, PanelDrag = nil, nil
	end
end)

----------------------------------------------------------------------
-- toggle callback, interface, open / close
----------------------------------------------------------------------
ui.OnToggle = function(m, silent)
	Repaint(m)
	RebuildArrayList()
	if not silent and Notifs.Values["Module Toggles"] and m.Category ~= "Settings" then
		ui.Notify(m.Name .. (m.Enabled and " enabled" or " disabled"), m.Enabled)
	end
end

local function MenuKey() return Enum.KeyCode[GuiSettings.Values["Menu Key"]] end

function ui.ApplyInterface()
	if ui.MenuOpen then
		TweenService:Create(Blur, TweenInfo.new(0.2), { Size = GuiSettings.Values["Background Blur"] and 14 or 0 }):Play()
		TweenService:Create(Dim, TweenInfo.new(0.2), { BackgroundTransparency = GuiSettings.Values["Background Dim"] and 0.6 or 1 }):Play()
	end
end

-- Window UI type: one box, categories on the left, the selected category's modules on the right
function ui.BuildWindow()
	local vp = Camera.ViewportSize
	if vp.X < 400 then vp = Vector2.new(1280, 720) end
	local W, H = math.min(700, vp.X - 20), math.min(460, vp.Y - 40)
	local SW = W < 520 and 118 or 160
	local win = New("Frame", { Name = "Window", Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset((vp.X - W) / 2, (vp.Y - H) / 2), BackgroundColor3 = Color3.fromRGB(18, 18, 25), BorderSizePixel = 0, Visible = false, ClipsDescendants = true, ZIndex = 5 }, Menu)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
	local stroke = New("UIStroke", { Thickness = 1.5, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, win)
	AddPainter(stroke, function() stroke.Color = Accent(0.2) end)
	-- title bar
	local bar = New("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Color3.fromRGB(13, 13, 19), BorderSizePixel = 0, AutoButtonColor = false, Text = "" }, win)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, bar)
	New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(13, 13, 19), BorderSizePixel = 0 }, bar)
	local title = New("TextLabel", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0, 90, 1, -2), BackgroundTransparency = 1, Text = "Zenith", Font = FONT_B, TextSize = 19, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	ui.WinCrumb = New("TextLabel", { Position = UDim2.fromOffset(SW + 14, 0), Size = UDim2.new(1, -(SW + 24), 1, -2), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 13, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, bar)
	local line = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0 }, bar)
	ui.StyleLine(line, 0, bar)
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			ClosePicker()
			ui.BeginDrag(win, i)
		end
	end)
	-- sidebar
	local sideBg = New("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(0, SW, 1, -46), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0 }, win)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, sideBg)
	New("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0 }, sideBg)
	New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0 }, sideBg)
	New("TextLabel", { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -16, 0, 14), BackgroundTransparency = 1, Text = "CATEGORIES", Font = FONT_B, TextSize = 10, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left }, sideBg)
	local side = New("ScrollingFrame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, sideBg)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, side)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
	local foot = New("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -8), Size = UDim2.new(1, -24, 0, 16), BackgroundTransparency = 1, Text = LP.Name, Font = FONT, TextSize = 12, TextColor3 = C_DIM, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, sideBg)
	New("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(34, 34, 46), BorderSizePixel = 0 }, sideBg)
	-- module list
	ui.WinBody = New("ScrollingFrame", { Position = UDim2.fromOffset(SW, 46), Size = UDim2.new(1, -SW, 1, -46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, win)
	ui.WinHolder = New("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -26, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, ui.WinBody)
	New("UIPadding", { PaddingBottom = UDim.new(0, 10) }, ui.WinHolder)
	ui.WinCounts = {}
	for i, cat in ipairs(Categories) do
		local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(26, 26, 36), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = i }, side)
		New("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
		local mark = New("Frame", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(0, 3, 1, -16), BorderSizePixel = 0 }, b)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, mark)
		local l = New("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Text = cat, Font = FONT_B, TextSize = 14, TextColor3 = C_LIGHT, TextXAlignment = Enum.TextXAlignment.Left }, b)
		local cnt = New("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(26, 16), BackgroundColor3 = Color3.fromRGB(12, 12, 18), BorderSizePixel = 0, Text = tostring(#ByCat[cat]), Font = FONT, TextSize = 11, TextColor3 = C_DIM }, b)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, cnt)
		local hov = false
		b.MouseEnter:Connect(function() hov = true; Repaint() end)
		b.MouseLeave:Connect(function() hov = false; Repaint() end)
		AddPainter(b, function()
			local sel = ui.WinCat == i
			b.BackgroundTransparency = (sel or hov) and 0 or 1
			b.BackgroundColor3 = sel and Color3.fromRGB(30, 30, 42) or Color3.fromRGB(24, 24, 33)
			mark.Visible = sel
			mark.BackgroundColor3 = Accent(i * 0.1)
			l.TextColor3 = sel and WHITE or C_LIGHT
		end)
		b.MouseButton1Click:Connect(function() ClosePicker(); ui.WinSelect(i) end)
	end
	ui.Win = win
end
function ui.ApplyScale()
	local sc = GuiSettings.Values["UI Scale"] or 1
	local function put(f)
		local u = f:FindFirstChild("ZScale") or New("UIScale", { Name = "ZScale" }, f)
		u.Scale = sc
	end
	for _, p in ipairs(PanelFrames) do put(p) end
	if HubPanel then put(HubPanel) end
	if ui.Win then
		put(ui.Win)
		local vp = Camera.ViewportSize
		if vp.X < 400 then vp = Vector2.new(1280, 720) end
		local w, h = math.min(700, (vp.X - 20) / sc), math.min(460, (vp.Y - 40) / sc)
		ui.Win.Size = UDim2.fromOffset(w, h)
		local pos = ui.Win.Position
		local nx, ny = ui.ClampXY(pos.X.Offset, pos.Y.Offset)
		ui.Win.Position = UDim2.fromOffset(math.clamp(nx, 0, math.max(vp.X - w * sc, 0)), ny)
	end
	if ui.ClampPanels then ui.ClampPanels() end
end
function ui.WinSelect(i)
	ui.WinCat = i
	for j, c in ipairs(PanelContents) do
		if j == i then c.Parent = ui.WinHolder; c.Visible = true; c.LayoutOrder = 1
		else c.Parent = PanelFrames[j]; c.LayoutOrder = 2 end
	end
	ui.WinBody.CanvasPosition = Vector2.new()
	if ui.WinCrumb then ui.WinCrumb.Text = Categories[i] .. "  \xC2\xB7  " .. (CatDesc[Categories[i]] or "") end
	Repaint()
end
function ui.SetUIType(t)
	local win = t == "Window"
	if win and not ui.Win then ui.BuildWindow() end
	ui.UIType = t
	ui.Scroller.Visible = not win
	if ui.Win then ui.Win.Visible = win end
	if win then ui.WinSelect(ui.WinCat or 1)
	else for j, c in ipairs(PanelContents) do c.Parent = PanelFrames[j]; c.LayoutOrder = 2 end end
	ui.ApplyScale()
end

function ui.WheelSink(on)
	local cas = game:GetService("ContextActionService")
	if on then
		cas:BindActionAtPriority("ZenithWheel", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value + 20, Enum.UserInputType.MouseWheel)
	else
		pcall(function() cas:UnbindAction("ZenithWheel") end)
	end
end

local function SetMenu(open)
	ui.MenuOpen = open
	Modal.Modal = open
	ui.WheelSink(open)
	if open then
		Menu.Visible = true
		ui.ClampPanels()
		ui.ApplyInterface()
	else
		ClosePicker()
		SearchBox:ReleaseFocus()
		SetHover(nil)
		Drag, PanelDrag = nil, nil
		TweenService:Create(Blur, TweenInfo.new(0.2), { Size = 0 }):Play()
		TweenService:Create(Dim, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		task.delay(0.2, function() if not ui.MenuOpen then Menu.Visible = false end end)
	end
end

ui.SetMenu = SetMenu

----------------------------------------------------------------------
-- keybinds
----------------------------------------------------------------------
-- true when a keybind row was waiting for a key and this key was given to it
function ui.TryBind(key)
	if not Listening then return false end
	local m = Listening.m; Listening = nil
	if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace then m.Bind = nil else m.Bind = key end
	Repaint(m)
	return true
end
Conn(UIS.InputBegan, function(input, gp)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local key = input.KeyCode
	if ui.TryBind(key) then return end
	if key == MenuKey() then
		if not Typing() then SetMenu(not ui.MenuOpen) end
		return
	end
	if ui.MenuOpen and key == Enum.KeyCode.F and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		SearchBox:CaptureFocus() return
	end
	if gp or Typing() then return end
	for _, m in ipairs(Modules) do
		if m.Bind == key then
			if m.Action or m.BindMode ~= "Hold" then ToggleModule(m)
			elseif not m.Enabled then m._held = true; SetEnabled(m, true) end
		end
	end
end)
end

Conn(UIS.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	for _, m in ipairs(Modules) do
		if m.Bind == input.KeyCode and m._held then
			m._held = false
			if m.Enabled then SetEnabled(m, false) end
		end
	end
end)

----------------------------------------------------------------------
-- render step (runs right after Roblox's camera so FOV / Freecam stick)
----------------------------------------------------------------------
RunService:BindToRenderStep("ZenithRender", Enum.RenderPriority.Camera.Value + 1, function(dt)
	Camera = workspace.CurrentCamera
	if ui.AimBtn then ui.AimBtn.btn.Visible = false end
	for _, m in ipairs(Modules) do if m.Enabled and m.OnRender then Safe(m.OnRender, m, dt) end end
	Safe(UpdateESP)
	Safe(UpdateHover)
	if ThemeName == "Rainbow" or Themes.G[ThemeName] then Repaint() end
	Safe(ui.AuroraStep)
	Safe(ui.ScrollStep, dt)
end)

----------------------------------------------------------------------
-- unload
----------------------------------------------------------------------
function ui.Unload()
	for _, m in ipairs(Modules) do if m.Enabled then SetEnabled(m, false, true) end end
	for _, c in ipairs(Conns) do c:Disconnect() end
	pcall(function() RunService:UnbindFromRenderStep("ZenithRender") end)
	Modal.Modal = false
	Blur:Destroy()
	Gui:Destroy()
end

----------------------------------------------------------------------
-- start
----------------------------------------------------------------------
SetEnabled(ArrayList, true, true)
SetEnabled(Notifs, true, true)
SetEnabled(HUDm, true, true)
-- a saved config overrides the defaults above; with no file (or no file functions) the defaults stay
if ui.Config then
	ui.ApplyConfigEnabled(ui.Config)
	ui.ApplyLayout(ui.Config)
end
Conn(LP.OnTeleport, function(state)
	if GuiSettings.Values["Keep Across Teleports"] and (state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress) then
		ui.SaveSession()
	end
end)
if GuiSettings.Values["Keep Across Teleports"] then ui.SetKeep(true) end
ui.GuiMod = GuiSettings
Safe(ui.SetUIType, GuiSettings.Values["UI Type"])
Safe(ui.ApplyScale)
if GuiSettings.Values["Startup Logo"] then Safe(ui.Splash) end
ui.Notify("Zenith Client loaded" .. (ui.Config and (ui.FromSession and " (restored after teleport)" or (ui.GameLoaded and (" (" .. ui.GameLoaded .. " config loaded)") or " (config loaded)")) or "") .. " - press " .. GuiSettings.Values["Menu Key"] .. " to open the menu", true)