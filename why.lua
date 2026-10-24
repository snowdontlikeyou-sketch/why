-- ============================================================
-- PARTE 1/7 - Base + CONFIG + VisualSetters + Save/Load + UI
-- ============================================================
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local HS=game:GetService("HttpService")
local Camera=workspace.CurrentCamera
local LP=Players.LocalPlayer
local Mouse=LP:GetMouse()
local ScriptActive=true

local CONFIG={
    SilentAimEnabled=false, AutoFireInFOV=false, AutoFireDelay=249,
    ShowFOVCircle=false, FOV_Radius=180,
    AimbotEnabled=false, AimbotLockKey=Enum.UserInputType.MouseButton2,
    AimPart="Head", AimSpeed=60, AimPrediction=false, PredictionMs=69,
    StickyTarget=false, WallCheck=false, TargetIndicator=false, TeamCheck=false,
    ESPEnabled=false, ESPTeamCheck=false, LegitEnabled=false,
    UI_ToggleKey=Enum.KeyCode.K, ESP_ToggleKey=Enum.KeyCode.F, LegitToggleKey=Enum.KeyCode.Z,
}
local LegitBackup=nil
local CurrentTarget=nil
local LastFireTime=0
local AllConns={}

local VisualSetters={}
local function regVisual(key,setter)
    VisualSetters[key]=setter
end

local function addConn(c)
    table.insert(AllConns,c)
    return c
end

local SAVE_FILE="aimbotui_config.json"
local function serKey(k)
    if typeof(k)=="EnumItem" then return {__t=k.EnumType.Name,n=k.Name} end
    return k
end
local function desKey(d)
    if type(d)=="table" and d.__t then
        local ok,e=pcall(function() return Enum[d.__t][d.n] end)
        if ok then return e end
    end
end
local function saveConfig()
    if not writefile then return end
    local d={}
    for k,v in pairs(CONFIG) do
        if typeof(v)=="EnumItem" then d[k]=serKey(v) else d[k]=v end
    end
    pcall(function() writefile(SAVE_FILE,HS:JSONEncode(d)) end)
end
local function loadConfig()
    if not readfile or not isfile then return end
    local ok,e=pcall(isfile,SAVE_FILE)
    if not ok or not e then return end
    local r pcall(function() r=readfile(SAVE_FILE) end)
    if not r or r=="" then return end
    local ok2,d=pcall(function() return HS:JSONDecode(r) end)
    if not ok2 or type(d)~="table" then return end
    for k,v in pairs(d) do
        if CONFIG[k]~=nil then
            if type(v)=="table" and v.__t then
                local en=desKey(v)
                if en then CONFIG[k]=en end
            else
                CONFIG[k]=v
            end
        end
    end
end
loadConfig()

local SG=Instance.new("ScreenGui")
SG.Name="AimbotUI" SG.ResetOnSpawn=false SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.Parent=LP:WaitForChild("PlayerGui")

local Fov=Instance.new("Frame")
Fov.AnchorPoint=Vector2.new(.5,.5) Fov.Position=UDim2.new(.5,0,.5,0)
Fov.Size=UDim2.new(0,CONFIG.FOV_Radius*2,0,CONFIG.FOV_Radius*2)
Fov.BackgroundTransparency=1 Fov.Visible=false Fov.ZIndex=5 Fov.Parent=SG
local FC=Instance.new("UICorner") FC.CornerRadius=UDim.new(1,0) FC.Parent=Fov
local FS=Instance.new("UIStroke") FS.Thickness=2 FS.Color=Color3.fromRGB(0,220,255) FS.Transparency=.15 FS.Parent=Fov
local FG=Instance.new("UIGradient")
FG.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(.5,Color3.fromRGB(150,80,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,220,255)),
}
FG.Parent=FS

local Dot=Instance.new("Frame")
Dot.AnchorPoint=Vector2.new(.5,.5) Dot.Position=UDim2.new(.5,0,.5,0)
Dot.Size=UDim2.new(0,4,0,4) Dot.BackgroundColor3=Color3.fromRGB(0,220,255)
Dot.BorderSizePixel=0 Dot.ZIndex=6 Dot.Visible=false Dot.Parent=SG
local DC=Instance.new("UICorner") DC.CornerRadius=UDim.new(1,0) DC.Parent=Dot

local MF=Instance.new("Frame")
MF.AnchorPoint=Vector2.new(0,0) MF.Position=UDim2.new(0,30,0,30)
MF.Size=UDim2.new(0,340,0,600) MF.BackgroundColor3=Color3.fromRGB(18,18,24)
MF.BorderSizePixel=0 MF.Active=true MF.Draggable=true MF.ZIndex=10 MF.Parent=SG
local MC=Instance.new("UICorner") MC.CornerRadius=UDim.new(0,14) MC.Parent=MF
local MS=Instance.new("UIStroke") MS.Thickness=1.5 MS.Color=Color3.fromRGB(60,60,80) MS.Transparency=.3 MS.Parent=MF
local BGr=Instance.new("UIGradient") BGr.Rotation=45
BGr.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(24,24,34)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(14,14,20)),
}
BGr.Parent=MF

local Ti=Instance.new("TextLabel")
Ti.Position=UDim2.new(0,20,0,12) Ti.Size=UDim2.new(1,-110,0,24)
Ti.BackgroundTransparency=1 Ti.Text="AIMBOT PANEL"
Ti.TextColor3=Color3.fromRGB(240,240,255) Ti.TextSize=18
Ti.Font=Enum.Font.GothamBold Ti.TextXAlignment=Enum.TextXAlignment.Left
Ti.ZIndex=12 Ti.Parent=MF

local Sb=Instance.new("TextLabel")
Sb.Position=UDim2.new(0,20,0,32) Sb.Size=UDim2.new(1,-110,0,16)
Sb.BackgroundTransparency=1 Sb.Text="v7.2 • [K] Abrir/Fechar"
Sb.TextColor3=Color3.fromRGB(120,130,160) Sb.TextSize=11
Sb.Font=Enum.Font.Gotham Sb.TextXAlignment=Enum.TextXAlignment.Left
Sb.ZIndex=12 Sb.Parent=MF

local MinB=Instance.new("TextButton")
MinB.AnchorPoint=Vector2.new(1,0) MinB.Position=UDim2.new(1,-50,0,14)
MinB.Size=UDim2.new(0,26,0,26) MinB.BackgroundColor3=Color3.fromRGB(30,30,42)
MinB.BorderSizePixel=0 MinB.Text="—" MinB.TextColor3=Color3.fromRGB(220,220,240)
MinB.TextSize=16 MinB.Font=Enum.Font.GothamBold MinB.AutoButtonColor=false
MinB.ZIndex=13 MinB.Parent=MF
local MinC=Instance.new("UICorner") MinC.CornerRadius=UDim.new(0,6) MinC.Parent=MinB
local MinS=Instance.new("UIStroke") MinS.Thickness=1 MinS.Color=Color3.fromRGB(60,60,80) MinS.Parent=MinB

local ClsB=Instance.new("TextButton")
ClsB.AnchorPoint=Vector2.new(1,0) ClsB.Position=UDim2.new(1,-14,0,14)
ClsB.Size=UDim2.new(0,26,0,26) ClsB.BackgroundColor3=Color3.fromRGB(30,30,42)
ClsB.BorderSizePixel=0 ClsB.Text="×" ClsB.TextColor3=Color3.fromRGB(255,120,120)
ClsB.TextSize=18 ClsB.Font=Enum.Font.GothamBold ClsB.AutoButtonColor=false
ClsB.ZIndex=13 ClsB.Parent=MF
local ClsC=Instance.new("UICorner") ClsC.CornerRadius=UDim.new(0,6) ClsC.Parent=ClsB
local ClsS=Instance.new("UIStroke") ClsS.Thickness=1 ClsS.Color=Color3.fromRGB(60,60,80) ClsS.Parent=ClsB

local Dv=Instance.new("Frame")
Dv.Position=UDim2.new(0,20,0,55) Dv.Size=UDim2.new(1,-40,0,1)
Dv.BackgroundColor3=Color3.fromRGB(0,220,255) Dv.BorderSizePixel=0
Dv.ZIndex=12 Dv.Parent=MF
local DvG=Instance.new("UIGradient")
DvG.Transparency=NumberSequence.new{
    NumberSequenceKeypoint.new(0,1),
    NumberSequenceKeypoint.new(.5,.4),
    NumberSequenceKeypoint.new(1,1),
}
DvG.Parent=Dv

local TB=Instance.new("Frame")
TB.Position=UDim2.new(0,16,0,65) TB.Size=UDim2.new(1,-32,0,32)
TB.BackgroundTransparency=1 TB.ZIndex=12 TB.Parent=MF
local TBL=Instance.new("UIListLayout")
TBL.FillDirection=Enum.FillDirection.Horizontal
TBL.Padding=UDim.new(0,5) TBL.SortOrder=Enum.SortOrder.LayoutOrder
TBL.Parent=TB

local function mkTab(txt,ord)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1/3,-3.33,1,0)
    b.BackgroundColor3=Color3.fromRGB(24,24,32) b.BorderSizePixel=0
    b.Text=txt b.TextColor3=Color3.fromRGB(160,170,200) b.TextSize=11
    b.Font=Enum.Font.GothamBold b.AutoButtonColor=false b.ZIndex=13
    b.LayoutOrder=ord b.Parent=TB
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,6) c.Parent=b
    local s=Instance.new("UIStroke") s.Thickness=1 s.Color=Color3.fromRGB(60,60,80) s.Parent=b
    return b,s
end
local HB,HS_=mkTab("HOME",1)
local AB,AS_=mkTab("AIMBOT",2)
local CB,CS_=mkTab("CONFIGS",3)

-- ============================================================
-- PARTE 2/7 - HomePage + AimbotPage + ConfigsPage + setTab
-- ============================================================
local HomeP=Instance.new("Frame")
HomeP.Position=UDim2.new(0,0,0,105) HomeP.Size=UDim2.new(1,0,1,-105)
HomeP.BackgroundTransparency=1 HomeP.Visible=true HomeP.ZIndex=11 HomeP.Parent=MF

local AvF=Instance.new("Frame")
AvF.AnchorPoint=Vector2.new(.5,0) AvF.Position=UDim2.new(.5,0,0,20)
AvF.Size=UDim2.new(0,90,0,90) AvF.BackgroundColor3=Color3.fromRGB(24,24,32)
AvF.BorderSizePixel=0 AvF.ZIndex=12 AvF.Parent=HomeP
local AvC=Instance.new("UICorner") AvC.CornerRadius=UDim.new(1,0) AvC.Parent=AvF
local AvS=Instance.new("UIStroke") AvS.Thickness=2 AvS.Color=Color3.fromRGB(0,200,255) AvS.Parent=AvF
local AvI=Instance.new("ImageLabel")
AvI.AnchorPoint=Vector2.new(.5,.5) AvI.Position=UDim2.new(.5,0,.5,0)
AvI.Size=UDim2.new(1,-6,1,-6) AvI.BackgroundTransparency=1
AvI.Image="" AvI.ZIndex=13 AvI.Parent=AvF
local AvIC=Instance.new("UICorner") AvIC.CornerRadius=UDim.new(1,0) AvIC.Parent=AvI
task.spawn(function()
    local ok,i=pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
    end)
    if ok and i and ScriptActive then AvI.Image=i end
end)

local WL=Instance.new("TextLabel")
WL.Position=UDim2.new(0,20,0,125) WL.Size=UDim2.new(1,-40,0,26)
WL.BackgroundTransparency=1 WL.Text="Bem-vindo!"
WL.TextColor3=Color3.fromRGB(240,240,255) WL.TextSize=18
WL.Font=Enum.Font.GothamBold WL.TextXAlignment=Enum.TextXAlignment.Center
WL.ZIndex=12 WL.Parent=HomeP

local UL=Instance.new("TextLabel")
UL.Position=UDim2.new(0,20,0,152) UL.Size=UDim2.new(1,-40,0,20)
UL.BackgroundTransparency=1 UL.Text="@"..LP.Name
UL.TextColor3=Color3.fromRGB(0,200,255) UL.TextSize=13
UL.Font=Enum.Font.GothamMedium UL.TextXAlignment=Enum.TextXAlignment.Center
UL.ZIndex=12 UL.Parent=HomeP

local GC=Instance.new("Frame")
GC.Position=UDim2.new(0,20,0,190) GC.Size=UDim2.new(1,-40,0,74)
GC.BackgroundColor3=Color3.fromRGB(24,24,32) GC.BorderSizePixel=0
GC.ZIndex=12 GC.Parent=HomeP
local GCC=Instance.new("UICorner") GCC.CornerRadius=UDim.new(0,10) GCC.Parent=GC
local GCS=Instance.new("UIStroke") GCS.Thickness=1 GCS.Color=Color3.fromRGB(60,60,80) GCS.Parent=GC
local GT=Instance.new("TextLabel")
GT.Position=UDim2.new(0,14,0,8) GT.Size=UDim2.new(1,-28,0,16)
GT.BackgroundTransparency=1 GT.Text="JOGO ATUAL"
GT.TextColor3=Color3.fromRGB(120,130,160) GT.TextSize=10
GT.Font=Enum.Font.GothamBold GT.TextXAlignment=Enum.TextXAlignment.Left
GT.ZIndex=13 GT.Parent=GC
local GN=Instance.new("TextLabel")
GN.Position=UDim2.new(0,14,0,26) GN.Size=UDim2.new(1,-28,0,22)
GN.BackgroundTransparency=1 GN.Text="Carregando..."
GN.TextColor3=Color3.fromRGB(240,240,255) GN.TextSize=14
GN.Font=Enum.Font.GothamBold GN.TextXAlignment=Enum.TextXAlignment.Left
GN.TextTruncate=Enum.TextTruncate.AtEnd GN.ZIndex=13 GN.Parent=GC
local PI=Instance.new("TextLabel")
PI.Position=UDim2.new(0,14,0,50) PI.Size=UDim2.new(1,-28,0,16)
PI.BackgroundTransparency=1 PI.Text="PlaceId: "..tostring(game.PlaceId)
PI.TextColor3=Color3.fromRGB(140,150,180) PI.TextSize=10
PI.Font=Enum.Font.Gotham PI.TextXAlignment=Enum.TextXAlignment.Left
PI.ZIndex=13 PI.Parent=GC
task.spawn(function()
    local ok,i=pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and i and ScriptActive then GN.Text=i.Name
    elseif ScriptActive then GN.Text="Roblox Experience" end
end)

local FH=Instance.new("TextLabel")
FH.Position=UDim2.new(0,20,1,-50) FH.Size=UDim2.new(1,-40,0,16)
FH.BackgroundTransparency=1 FH.Text="Pressione [K] para abrir/fechar"
FH.TextColor3=Color3.fromRGB(90,100,130) FH.TextSize=10
FH.Font=Enum.Font.Gotham FH.TextXAlignment=Enum.TextXAlignment.Center
FH.ZIndex=12 FH.Parent=HomeP
local VH=Instance.new("TextLabel")
VH.Position=UDim2.new(0,20,1,-32) VH.Size=UDim2.new(1,-40,0,16)
VH.BackgroundTransparency=1 VH.Text="Aimbot Panel v7.2"
VH.TextColor3=Color3.fromRGB(90,100,130) VH.TextSize=10
VH.Font=Enum.Font.Gotham VH.TextXAlignment=Enum.TextXAlignment.Center
VH.ZIndex=12 VH.Parent=HomeP

local AimbP=Instance.new("Frame")
AimbP.Position=UDim2.new(0,0,0,105) AimbP.Size=UDim2.new(1,0,1,-105)
AimbP.BackgroundTransparency=1 AimbP.Visible=false AimbP.ZIndex=11 AimbP.Parent=MF
local Scr=Instance.new("ScrollingFrame")
Scr.Position=UDim2.new(0,0,0,0) Scr.Size=UDim2.new(1,0,1,0)
Scr.BackgroundTransparency=1 Scr.BorderSizePixel=0 Scr.ScrollBarThickness=4
Scr.ScrollBarImageColor3=Color3.fromRGB(0,200,255)
Scr.CanvasSize=UDim2.new(0,0,0,0) Scr.AutomaticCanvasSize=Enum.AutomaticSize.Y
Scr.ZIndex=11 Scr.Parent=AimbP
local ScrL=Instance.new("UIListLayout")
ScrL.Padding=UDim.new(0,8) ScrL.SortOrder=Enum.SortOrder.LayoutOrder ScrL.Parent=Scr
local ScrP=Instance.new("UIPadding")
ScrP.PaddingLeft=UDim.new(0,16) ScrP.PaddingRight=UDim.new(0,16)
ScrP.PaddingTop=UDim.new(0,8) ScrP.PaddingBottom=UDim.new(0,8) ScrP.Parent=Scr

local CfgP=Instance.new("Frame")
CfgP.Position=UDim2.new(0,0,0,105) CfgP.Size=UDim2.new(1,0,1,-105)
CfgP.BackgroundTransparency=1 CfgP.Visible=false CfgP.ZIndex=11 CfgP.Parent=MF
local CfgS=Instance.new("ScrollingFrame")
CfgS.Position=UDim2.new(0,0,0,0) CfgS.Size=UDim2.new(1,0,1,0)
CfgS.BackgroundTransparency=1 CfgS.BorderSizePixel=0 CfgS.ScrollBarThickness=4
CfgS.ScrollBarImageColor3=Color3.fromRGB(0,200,255)
CfgS.CanvasSize=UDim2.new(0,0,0,0) CfgS.AutomaticCanvasSize=Enum.AutomaticSize.Y
CfgS.ZIndex=11 CfgS.Parent=CfgP
local CfgL=Instance.new("UIListLayout")
CfgL.Padding=UDim.new(0,8) CfgL.SortOrder=Enum.SortOrder.LayoutOrder CfgL.Parent=CfgS
local CfgP2=Instance.new("UIPadding")
CfgP2.PaddingLeft=UDim.new(0,16) CfgP2.PaddingRight=UDim.new(0,16)
CfgP2.PaddingTop=UDim.new(0,8) CfgP2.PaddingBottom=UDim.new(0,8) CfgP2.Parent=CfgS

local function setTab(w)
    HomeP.Visible=(w=="home")
    AimbP.Visible=(w=="aimbot")
    CfgP.Visible=(w=="configs")
    local function st(b,s,a)
        b.TextColor3=a and Color3.fromRGB(0,220,255) or Color3.fromRGB(160,170,200)
        s.Color=a and Color3.fromRGB(0,200,255) or Color3.fromRGB(60,60,80)
        b.BackgroundColor3=a and Color3.fromRGB(30,30,44) or Color3.fromRGB(24,24,32)
    end
    st(HB,HS_,w=="home")
    st(AB,AS_,w=="aimbot")
    st(CB,CS_,w=="configs")
end
HB.MouseButton1Click:Connect(function() setTab("home") end)
AB.MouseButton1Click:Connect(function() setTab("aimbot") end)
CB.MouseButton1Click:Connect(function() setTab("configs") end)
setTab("home")

local function tw(o,t,p)
    TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play()
end

MinB.MouseEnter:Connect(function() tw(MinB,.15,{BackgroundColor3=Color3.fromRGB(50,50,65)}) end)
MinB.MouseLeave:Connect(function() tw(MinB,.15,{BackgroundColor3=Color3.fromRGB(30,30,42)}) end)
ClsB.MouseEnter:Connect(function() tw(ClsB,.15,{BackgroundColor3=Color3.fromRGB(60,30,30)}) end)
ClsB.MouseLeave:Connect(function() tw(ClsB,.15,{BackgroundColor3=Color3.fromRGB(30,30,42)}) end)

local min=false
local ns=UDim2.new(0,340,0,600)
local ms=UDim2.new(0,340,0,65)
MinB.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    min=not min
    if min then
        MinB.Text="+"
        tw(MF,.2,{Size=ms})
        TB.Visible=false HomeP.Visible=false AimbP.Visible=false CfgP.Visible=false
    else
        MinB.Text="—"
        tw(MF,.2,{Size=ns})
        TB.Visible=true setTab("home")
    end
end)

-- ============================================================
-- PARTE 3A/7 - mkSec + mkTog + mkSld
-- ============================================================
local function mkSec(txt,par)
    par=par or Scr
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,22) l.BackgroundTransparency=1
    l.Text=txt l.TextColor3=Color3.fromRGB(0,200,255) l.TextSize=12
    l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=11 l.Parent=par
    return l
end

local function mkTog(txt,def,onCh,par)
    par=par or Scr
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,0,0,36) r.BackgroundColor3=Color3.fromRGB(24,24,32)
    r.BorderSizePixel=0 r.ZIndex=11 r.Parent=par
    local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(0,8) rc.Parent=r
    local rs=Instance.new("UIStroke") rs.Thickness=1 rs.Color=Color3.fromRGB(60,60,80) rs.Parent=r
    local l=Instance.new("TextLabel")
    l.Position=UDim2.new(0,12,0,0) l.Size=UDim2.new(1,-90,1,0)
    l.BackgroundTransparency=1 l.Text=txt
    l.TextColor3=Color3.fromRGB(220,220,240) l.TextSize=12
    l.Font=Enum.Font.GothamMedium l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=12 l.Parent=r
    local sw=Instance.new("TextButton")
    sw.AnchorPoint=Vector2.new(1,.5) sw.Position=UDim2.new(1,-10,.5,0)
    sw.Size=UDim2.new(0,44,0,22)
    sw.BackgroundColor3=def and Color3.fromRGB(0,200,255) or Color3.fromRGB(50,50,65)
    sw.BorderSizePixel=0 sw.Text=def and "ON" or "OFF"
    sw.TextColor3=Color3.fromRGB(255,255,255) sw.TextSize=10
    sw.Font=Enum.Font.GothamBold sw.AutoButtonColor=false
    sw.ZIndex=12 sw.Parent=r
    local sc=Instance.new("UICorner") sc.CornerRadius=UDim.new(1,0) sc.Parent=sw
    local st=def
    local function setState(v,silent)
        st=v
        if v then
            tw(sw,.15,{BackgroundColor3=Color3.fromRGB(0,200,255)})
            sw.Text="ON"
        else
            tw(sw,.15,{BackgroundColor3=Color3.fromRGB(50,50,65)})
            sw.Text="OFF"
        end
        if not silent and onCh then onCh(v) end
    end
    _G["_TS_"..txt]=setState
    regVisual(txt,setState)
    sw.MouseButton1Click:Connect(function()
        if not ScriptActive then return end
        setState(not st,false)
    end)
    return r,setState
end

local function mkSld(txt,mn,mx,dv,isInt,onCh,par)
    par=par or Scr
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,0,0,56) r.BackgroundColor3=Color3.fromRGB(24,24,32)
    r.BorderSizePixel=0 r.ZIndex=11 r.Parent=par
    local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(0,8) rc.Parent=r
    local rs=Instance.new("UIStroke") rs.Thickness=1 rs.Color=Color3.fromRGB(60,60,80) rs.Parent=r
    local l=Instance.new("TextLabel")
    l.Position=UDim2.new(0,12,0,6) l.Size=UDim2.new(.7,0,0,18)
    l.BackgroundTransparency=1 l.Text=txt
    l.TextColor3=Color3.fromRGB(220,220,240) l.TextSize=12
    l.Font=Enum.Font.GothamMedium l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=12 l.Parent=r
    local vl=Instance.new("TextLabel")
    vl.AnchorPoint=Vector2.new(1,0) vl.Position=UDim2.new(1,-12,0,6)
    vl.Size=UDim2.new(0,60,0,18) vl.BackgroundTransparency=1
    vl.Text=tostring(dv) vl.TextColor3=Color3.fromRGB(0,200,255)
    vl.TextSize=12 vl.Font=Enum.Font.GothamBold
    vl.TextXAlignment=Enum.TextXAlignment.Right vl.ZIndex=12 vl.Parent=r
    local bb=Instance.new("Frame")
    bb.Position=UDim2.new(0,12,0,34) bb.Size=UDim2.new(1,-24,0,8)
    bb.BackgroundColor3=Color3.fromRGB(35,35,48) bb.BorderSizePixel=0
    bb.ZIndex=12 bb.Parent=r
    local bbc=Instance.new("UICorner") bbc.CornerRadius=UDim.new(1,0) bbc.Parent=bb
    local bf=Instance.new("Frame")
    bf.Size=UDim2.new((dv-mn)/(mx-mn),0,1,0)
    bf.BackgroundColor3=Color3.fromRGB(0,200,255) bf.BorderSizePixel=0
    bf.ZIndex=13 bf.Parent=bb
    local bfc=Instance.new("UICorner") bfc.CornerRadius=UDim.new(1,0) bfc.Parent=bf
    local fg=Instance.new("UIGradient")
    fg.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,220,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(120,60,255)),
    }
    fg.Parent=bf
    local drag=false
    local function uf(x)
        if not ScriptActive then return end
        local rel=math.clamp((x-bb.AbsolutePosition.X)/bb.AbsoluteSize.X,0,1)
        local v=mn+(mx-mn)*rel
        if isInt then v=math.floor(v+.5) end
        vl.Text=tostring(v)
        bf.Size=UDim2.new(rel,0,1,0)
        if onCh then onCh(v) end
    end
    addConn(bb.InputBegan:Connect(function(i)
        if not ScriptActive then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true uf(i.Position.X)
        end
    end))
    addConn(UIS.InputChanged:Connect(function(i)
        if not ScriptActive then return end
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            uf(i.Position.X)
        end
    end))
    addConn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end))
    regVisual("SLD_"..txt,function(v,silent)
        local rel=math.clamp((v-mn)/(mx-mn),0,1)
        vl.Text=tostring(v)
        bf.Size=UDim2.new(rel,0,1,0)
        if not silent and onCh then onCh(v) end
    end)
    return r
end

-- ============================================================
-- PARTE 3B/7 - mkDD + mkKB
-- ============================================================
local function mkDD(txt,opts,dIdx,onCh,par)
    par=par or Scr
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,0,0,62) r.BackgroundColor3=Color3.fromRGB(24,24,32)
    r.BorderSizePixel=0 r.ZIndex=11 r.Parent=par
    local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(0,8) rc.Parent=r
    local rs=Instance.new("UIStroke") rs.Thickness=1 rs.Color=Color3.fromRGB(60,60,80) rs.Parent=r
    local l=Instance.new("TextLabel")
    l.Position=UDim2.new(0,12,0,6) l.Size=UDim2.new(.7,0,0,18)
    l.BackgroundTransparency=1 l.Text=txt
    l.TextColor3=Color3.fromRGB(180,190,220) l.TextSize=11
    l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=12 l.Parent=r
    local b=Instance.new("TextButton")
    b.Position=UDim2.new(0,12,0,28) b.Size=UDim2.new(1,-24,0,26)
    b.BackgroundColor3=Color3.fromRGB(30,30,42) b.BorderSizePixel=0
    b.Text="  "..opts[dIdx].."  v" b.TextColor3=Color3.fromRGB(240,240,255)
    b.TextSize=12 b.Font=Enum.Font.GothamMedium
    b.TextXAlignment=Enum.TextXAlignment.Left b.AutoButtonColor=false
    b.ZIndex=12 b.Parent=r
    local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,6) bc.Parent=b
    local bs=Instance.new("UIStroke") bs.Thickness=1 bs.Color=Color3.fromRGB(60,60,80) bs.Parent=b
    local lf=nil
    local op=false
    local function cl()
        if lf then lf:Destroy() lf=nil end
        op=false
    end
    local function ol()
        lf=Instance.new("Frame")
        lf.AnchorPoint=Vector2.new(0,1) lf.Position=UDim2.new(0,0,0,0)
        lf.Size=UDim2.new(1,0,0,#opts*26)
        lf.BackgroundColor3=Color3.fromRGB(22,22,30) lf.BorderSizePixel=0
        lf.ZIndex=999 lf.Parent=b
        local lc=Instance.new("UICorner") lc.CornerRadius=UDim.new(0,6) lc.Parent=lf
        local ls=Instance.new("UIStroke") ls.Thickness=1
        ls.Color=Color3.fromRGB(0,200,255) ls.Transparency=.4 ls.Parent=lf
        for i,o in ipairs(opts) do
            local it=Instance.new("TextButton")
            it.Position=UDim2.new(0,0,0,(i-1)*26) it.Size=UDim2.new(1,0,0,26)
            it.BackgroundTransparency=1 it.Text="  "..o
            it.TextColor3=Color3.fromRGB(220,220,240) it.TextSize=12
            it.Font=Enum.Font.Gotham it.TextXAlignment=Enum.TextXAlignment.Left
            it.ZIndex=1000 it.Parent=lf
            it.MouseEnter:Connect(function()
                it.BackgroundTransparency=.85
                it.BackgroundColor3=Color3.fromRGB(0,200,255)
            end)
            it.MouseLeave:Connect(function() it.BackgroundTransparency=1 end)
            it.MouseButton1Click:Connect(function()
                if not ScriptActive then return end
                b.Text="  "..o.."  v"
                cl()
                if onCh then onCh(o) end
            end)
        end
        op=true
    end
    b.MouseButton1Click:Connect(function()
        if not ScriptActive then return end
        if op then cl() else ol() end
    end)
    addConn(UIS.InputBegan:Connect(function(input,gpe)
        if gpe then return end
        if not op or not lf then return end
        if input.UserInputType~=Enum.UserInputType.MouseButton1
            and input.UserInputType~=Enum.UserInputType.Touch then return end
        local pos=input.Position
        local aL=lf.AbsolutePosition
        local aS=lf.AbsoluteSize
        local bL=b.AbsolutePosition
        local bS=b.AbsoluteSize
        local inL=pos.X>=aL.X and pos.X<=aL.X+aS.X and pos.Y>=aL.Y and pos.Y<=aL.Y+aS.Y
        local inB=pos.X>=bL.X and pos.X<=bL.X+bS.X and pos.Y>=bL.Y and pos.Y<=bL.Y+bS.Y
        if not inL and not inB then cl() end
    end))
    regVisual("DD_"..txt,function(v,silent)
        b.Text="  "..v.."  v"
        if not silent and onCh then onCh(v) end
    end)
    return r
end

local function mkKB(txt,dKey,onCh,par)
    par=par or Scr
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,0,0,44) r.BackgroundColor3=Color3.fromRGB(24,24,32)
    r.BorderSizePixel=0 r.ZIndex=11 r.Parent=par
    local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(0,8) rc.Parent=r
    local rs=Instance.new("UIStroke") rs.Thickness=1 rs.Color=Color3.fromRGB(60,60,80) rs.Parent=r
    local l=Instance.new("TextLabel")
    l.Position=UDim2.new(0,12,0,6) l.Size=UDim2.new(1,-140,0,16)
    l.BackgroundTransparency=1 l.Text=txt
    l.TextColor3=Color3.fromRGB(220,220,240) l.TextSize=12
    l.Font=Enum.Font.GothamMedium l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=12 l.Parent=r
    local h=Instance.new("TextLabel")
    h.Position=UDim2.new(0,12,0,22) h.Size=UDim2.new(1,-140,0,14)
    h.BackgroundTransparency=1 h.Text="Click to bind"
    h.TextColor3=Color3.fromRGB(120,130,160) h.TextSize=10
    h.Font=Enum.Font.Gotham h.TextXAlignment=Enum.TextXAlignment.Left
    h.ZIndex=12 h.Parent=r
    local kb=Instance.new("TextButton")
    kb.AnchorPoint=Vector2.new(1,.5) kb.Position=UDim2.new(1,-10,.5,0)
    kb.Size=UDim2.new(0,120,0,28)
    kb.BackgroundColor3=Color3.fromRGB(30,30,42) kb.BorderSizePixel=0
    kb.Text="[ "..dKey.Name.." ]"
    kb.TextColor3=Color3.fromRGB(240,240,255) kb.TextSize=11
    kb.Font=Enum.Font.GothamBold kb.AutoButtonColor=false
    kb.ZIndex=12 kb.Parent=r
    local kc=Instance.new("UICorner") kc.CornerRadius=UDim.new(0,6) kc.Parent=kb
    local ks=Instance.new("UIStroke") ks.Thickness=1 ks.Color=Color3.fromRGB(60,60,80) ks.Parent=kb
    local lst=false
    kb.MouseButton1Click:Connect(function()
        if not ScriptActive then return end
        lst=true
        kb.Text="[ ... ]"
        ks.Color=Color3.fromRGB(0,200,255)
        h.Text="Pressione uma tecla..."
    end)
    addConn(UIS.InputBegan:Connect(function(i,g)
        if not lst then return end
        if g then return end
        if not ScriptActive then return end
        local nk
        if i.UserInputType==Enum.UserInputType.Keyboard then
            nk=i.KeyCode
        elseif i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.MouseButton2 then
            nk=i.UserInputType
        end
        if nk then
            kb.Text="[ "..nk.Name.." ]"
            lst=false
            ks.Color=Color3.fromRGB(60,60,80)
            h.Text="Click to bind"
            if onCh then onCh(nk) end
        end
    end))
    return r
end

-- ============================================================
-- PARTE 4/7 - Seções da aba AIMBOT + LEGIT
-- ============================================================
mkSec("SILENT AIM")
mkTog("Enable Silent Aim", CONFIG.SilentAimEnabled, function(v) CONFIG.SilentAimEnabled = v end)
mkTog("Auto Fire in FOV", CONFIG.AutoFireInFOV, function(v) CONFIG.AutoFireInFOV = v end)
mkSld("Auto Fire Delay (ms)", 0, 500, CONFIG.AutoFireDelay, true, function(v) CONFIG.AutoFireDelay = v end)
mkTog("Show FOV Circle", CONFIG.ShowFOVCircle, function(v)
    CONFIG.ShowFOVCircle = v
    Fov.Visible = v
    Dot.Visible = v
end)
mkSld("FOV Radius", 30, 600, CONFIG.FOV_Radius, true, function(v)
    CONFIG.FOV_Radius = v
    Fov.Size = UDim2.new(0, v*2, 0, v*2)
end)

mkSec("AIMBOT")
mkTog("LEGIT [Z]", CONFIG.LegitEnabled, function(v)
    CONFIG.LegitEnabled = v
    if v then
        LegitBackup = {
            SilentAimEnabled = CONFIG.SilentAimEnabled,
            AutoFireInFOV    = CONFIG.AutoFireInFOV,
            ShowFOVCircle    = CONFIG.ShowFOVCircle,
            AimbotEnabled    = CONFIG.AimbotEnabled,
            ESPEnabled       = CONFIG.ESPEnabled,
        }
        CONFIG.SilentAimEnabled = false
        CONFIG.AutoFireInFOV    = false
        CONFIG.ShowFOVCircle    = false
        CONFIG.AimbotEnabled    = false
        CONFIG.ESPEnabled       = false
        Fov.Visible = false
        Dot.Visible = false
    else
        if LegitBackup then
            CONFIG.SilentAimEnabled = LegitBackup.SilentAimEnabled
            CONFIG.AutoFireInFOV    = LegitBackup.AutoFireInFOV
            CONFIG.ShowFOVCircle    = LegitBackup.ShowFOVCircle
            CONFIG.AimbotEnabled    = LegitBackup.AimbotEnabled
            CONFIG.ESPEnabled       = LegitBackup.ESPEnabled
            Fov.Visible = CONFIG.ShowFOVCircle
            Dot.Visible = CONFIG.ShowFOVCircle
            LegitBackup = nil
        end
    end
end)
mkTog("Enable Aimbot", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
mkKB("Aimbot Lock", CONFIG.AimbotLockKey, function(k) CONFIG.AimbotLockKey = k end)
mkDD("Aim Part", {"Head","UpperTorso","HumanoidRootPart","Nearest"}, 1, function(opt) CONFIG.AimPart = opt end)
mkSld("Aim Speed", 1, 100, CONFIG.AimSpeed, true, function(v) CONFIG.AimSpeed = v end)
mkTog("Aim Prediction", CONFIG.AimPrediction, function(v) CONFIG.AimPrediction = v end)
mkSld("Prediction (ms)", 0, 200, CONFIG.PredictionMs, true, function(v) CONFIG.PredictionMs = v end)

mkSec("TARGET")
mkTog("Sticky Target", CONFIG.StickyTarget, function(v) CONFIG.StickyTarget = v end)
mkTog("Wall Check", CONFIG.WallCheck, function(v) CONFIG.WallCheck = v end)
mkTog("Target Indicator", CONFIG.TargetIndicator, function(v) CONFIG.TargetIndicator = v end)
mkTog("Team Check", CONFIG.TeamCheck, function(v) CONFIG.TeamCheck = v end)

mkSec("ESP")
mkTog("ESP Ativo", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
mkTog("ESP Team Check", CONFIG.ESPTeamCheck, function(v) CONFIG.ESPTeamCheck = v end)
mkKB("ESP Hotkey", CONFIG.ESP_ToggleKey, function(k) CONFIG.ESP_ToggleKey = k end)

-- ============================================================
-- PARTE 5/7 - Target Logic + Aimbot Loop + Hotkeys + ESP + Discord
-- ============================================================
local function isVisible(part)
    if not CONFIG.WallCheck then return true end
    local origin=Camera.CFrame.Position
    local dir=part.Position-origin
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={LP.Character,Camera}
    local res=workspace:Raycast(origin,dir,params)
    if res then
        if part:IsDescendantOf(res.Instance.Parent) then return true end
        return false
    end
    return true
end

local function getAimPart(char)
    if CONFIG.AimPart=="Nearest" then
        return char:FindFirstChild("Head")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild(CONFIG.AimPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
end

local function isValidTarget(p)
    if p==LP then return false end
    if CONFIG.TeamCheck and p.Team and LP.Team and p.Team==LP.Team then return false end
    local c=p.Character
    if not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health<=0 then return false end
    local pa=getAimPart(c)
    if not pa then return false end
    return true,pa
end

local function getClosestTarget()
    if CONFIG.StickyTarget and CurrentTarget then
        local ok,pa=isValidTarget(CurrentTarget)
        if ok then
            local sp,on=Camera:WorldToViewportPoint(pa.Position)
            if on then
                local c=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
                local d=(Vector2.new(sp.X,sp.Y)-c).Magnitude
                if d<=CONFIG.FOV_Radius and isVisible(pa) then
                    return CurrentTarget,pa
                end
            end
        end
    end
    local cl,cp
    local sh=CONFIG.FOV_Radius
    local c=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        local ok,pa=isValidTarget(p)
        if ok then
            local sp,on=Camera:WorldToViewportPoint(pa.Position)
            if on then
                local d=(Vector2.new(sp.X,sp.Y)-c).Magnitude
                if d<sh and isVisible(pa) then
                    sh=d cl=p cp=pa
                end
            end
        end
    end
    return cl,cp
end

local function isLockHeld()
    if CONFIG.AimbotLockKey==Enum.UserInputType.MouseButton1 then
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif CONFIG.AimbotLockKey==Enum.UserInputType.MouseButton2 then
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif CONFIG.AimbotLockKey==Enum.UserInputType.MouseButton3 then
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else
        return UIS:IsKeyDown(CONFIG.AimbotLockKey)
    end
end

RunService:BindToRenderStep("AimbotLoop",Enum.RenderPriority.Camera.Value+1,function(dt)
    if not ScriptActive then return end
    if not CONFIG.AimbotEnabled then
        CurrentTarget=nil
        return
    end
    local tgt,pa=getClosestTarget()
    CurrentTarget=tgt
    if tgt and pa and isLockHeld() then
        local ap=pa.Position
        if CONFIG.AimPrediction and CONFIG.PredictionMs>0 then
            local ch=tgt.Character
            local rt=ch and ch:FindFirstChild("HumanoidRootPart")
            if rt then
                local vel=rt.AssemblyLinearVelocity
                local predTime=CONFIG.PredictionMs/1000
                local offset=vel*predTime
                if offset.Magnitude>20 then
                    offset=offset.Unit*20
                end
                ap=ap+offset
            end
        end
        local cp=Camera.CFrame.Position
        local look=CFrame.new(cp,ap)
        local alpha
        if CONFIG.AimSpeed>=100 then
            alpha=1
        else
            local base=(CONFIG.AimSpeed/100)^1.35
            alpha=math.clamp(base*(dt*60),0.02,1)
        end
        Camera.CFrame=Camera.CFrame:Lerp(look,alpha)
    end
    if CONFIG.AutoFireInFOV and tgt then
        local n=tick()
        if n-LastFireTime>=(CONFIG.AutoFireDelay/1000) then
            LastFireTime=n
            Mouse.Button1Down()
            task.delay(0.03,function()
                if ScriptActive then Mouse.Button1Up() end
            end)
        end
    end
end)

local function applyLegit(on)
    if on then
        LegitBackup={
            SilentAimEnabled=CONFIG.SilentAimEnabled,
            AutoFireInFOV=CONFIG.AutoFireInFOV,
            ShowFOVCircle=CONFIG.ShowFOVCircle,
            AimbotEnabled=CONFIG.AimbotEnabled,
            ESPEnabled=CONFIG.ESPEnabled,
        }
        CONFIG.SilentAimEnabled=false
        CONFIG.AutoFireInFOV=false
        CONFIG.ShowFOVCircle=false
        CONFIG.AimbotEnabled=false
        CONFIG.ESPEnabled=false
        Fov.Visible=false
        Dot.Visible=false
    else
        if LegitBackup then
            CONFIG.SilentAimEnabled=LegitBackup.SilentAimEnabled
            CONFIG.AutoFireInFOV=LegitBackup.AutoFireInFOV
            CONFIG.ShowFOVCircle=LegitBackup.ShowFOVCircle
            CONFIG.AimbotEnabled=LegitBackup.AimbotEnabled
            CONFIG.ESPEnabled=LegitBackup.ESPEnabled
            Fov.Visible=CONFIG.ShowFOVCircle
            Dot.Visible=CONFIG.ShowFOVCircle
            LegitBackup=nil
        end
    end
    CONFIG.LegitEnabled=on
    local setter=_G["_TS_LEGIT [Z]"]
    if setter then setter(on,true) end
end

addConn(UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if not ScriptActive then return end
    if i.UserInputType==Enum.UserInputType.Keyboard then
        if i.KeyCode==CONFIG.UI_ToggleKey then
            MF.Visible=not MF.Visible
        end
        if i.KeyCode==CONFIG.ESP_ToggleKey then
            CONFIG.ESPEnabled=not CONFIG.ESPEnabled
            local s=_G["_TS_ESP Ativo"]
            if s then s(CONFIG.ESPEnabled,true) end
        end
        if i.KeyCode==CONFIG.LegitToggleKey then
            applyLegit(not CONFIG.LegitEnabled)
        end
    end
end))

local ESPObjects={}
local function createESP(p)
    if not ScriptActive then return end
    local c=p.Character
    if not c then return end
    local hl=Instance.new("Highlight")
    hl.Adornee=c
    hl.FillColor=Color3.fromRGB(0,220,255)
    hl.OutlineColor=Color3.fromRGB(255,255,255)
    hl.FillTransparency=.6
    hl.OutlineTransparency=0
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent=SG
        local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,100,0,20) -- Diminuí de 200x40 para 100x20
    bb.StudsOffset=Vector3.new(0,2.5,0) -- Subi um pouquinho pra ficar mais perto da cabeça
    bb.AlwaysOnTop=true
    bb.Adornee=c:FindFirstChild("Head")
    bb.Parent=SG
    local nl=Instance.new("TextLabel")
    nl.Size=UDim2.new(1,0,1,0)
    nl.BackgroundTransparency=1
    nl.Text=p.Name
    nl.TextColor3=Color3.fromRGB(255,255,255)
    nl.TextStrokeTransparency=0
    nl.TextStrokeColor3=Color3.fromRGB(0,0,0)
    nl.TextScaled=false -- Desliga o escalonamento
    nl.TextSize=10 -- Define o tamanho fixo da fonte (ajuste como quiser: 8, 10, 12...)
    nl.Font=Enum.Font.GothamBold
    nl.Parent=bb
    ESPObjects[p]={h=hl,b=bb}
end

local function removeESP(p)
    local o=ESPObjects[p]
    if o then
        if o.h then o.h:Destroy() end
        if o.b then o.b:Destroy() end
        ESPObjects[p]=nil
    end
end

local function setupP(p)
    if p==LP then return end
    addConn(p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ScriptActive and CONFIG.ESPEnabled then createESP(p) end
    end))
    if CONFIG.ESPEnabled and p.Character then createESP(p) end
end

for _,p in ipairs(Players:GetPlayers()) do setupP(p) end
addConn(Players.PlayerAdded:Connect(setupP))
addConn(Players.PlayerRemoving:Connect(removeESP))

RunService.RenderStepped:Connect(function()
    if not ScriptActive then return end
    for p,o in pairs(ESPObjects) do
        local v=CONFIG.ESPEnabled
        if v and CONFIG.ESPTeamCheck then
            if p.Team and LP.Team and p.Team==LP.Team then v=false end
        end
        if o.h then o.h.Enabled=v end
        if o.b then o.b.Enabled=v end
    end
    if CONFIG.ESPEnabled then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character and not ESPObjects[p] then createESP(p) end
        end
    end
end)

local DISCORD_LINK="https://discord.gg/SEU_CONVITE_AQUI"
local discordBtn=Instance.new("TextButton")
discordBtn.Position=UDim2.new(0,20,0,282)
discordBtn.Size=UDim2.new(1,-40,0,38)
discordBtn.BackgroundColor3=Color3.fromRGB(88,101,242)
discordBtn.BorderSizePixel=0
discordBtn.Text="COPIAR LINK DO DISCORD"
discordBtn.TextColor3=Color3.fromRGB(255,255,255)
discordBtn.TextSize=12
discordBtn.Font=Enum.Font.GothamBold
discordBtn.AutoButtonColor=false
discordBtn.ZIndex=12
discordBtn.Parent=HomeP
local dCorner=Instance.new("UICorner")
dCorner.CornerRadius=UDim.new(0,10)
dCorner.Parent=discordBtn
local dGrad=Instance.new("UIGradient")
dGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(88,101,242)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(114,137,218)),
}
dGrad.Parent=discordBtn
discordBtn.MouseEnter:Connect(function()
    tw(discordBtn,.15,{BackgroundColor3=Color3.fromRGB(110,120,255)})
end)
discordBtn.MouseLeave:Connect(function()
    tw(discordBtn,.15,{BackgroundColor3=Color3.fromRGB(88,101,242)})
end)
discordBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local ok=pcall(function() setclipboard(DISCORD_LINK) end)
    discordBtn.Text=ok and "LINK COPIADO!" or DISCORD_LINK
    task.delay(2,function()
        if ScriptActive and discordBtn and discordBtn.Parent then
            discordBtn.Text="COPIAR LINK DO DISCORD"
        end
    end)
end)

-- ============================================================
-- PARTE 6/7 - Configs (read/write, snapshot, sync, lista)
-- ============================================================
local CFG_FILE="aimbotui_saved_configs.json"
local AUTOLOAD_FILE="aimbotui_autoload.json"
local PENDING_FILE="aimbotui_pending_load.json"

local function readCfgs()
    if not readfile or not isfile then return {} end
    local ok,e=pcall(isfile,CFG_FILE)
    if not ok or not e then return {} end
    local r
    pcall(function() r=readfile(CFG_FILE) end)
    if not r or r=="" then return {} end
    local ok2,d=pcall(function() return HS:JSONDecode(r) end)
    if ok2 and type(d)=="table" then return d end
    return {}
end
local function writeCfgs(t)
    if not writefile then return end
    pcall(function() writefile(CFG_FILE,HS:JSONEncode(t)) end)
end

local AutoLoad={Enabled=false,LastConfig=""}
local function loadAutoLoad()
    if not readfile or not isfile then return end
    local ok,e=pcall(isfile,AUTOLOAD_FILE)
    if not ok or not e then return end
    local r
    pcall(function() r=readfile(AUTOLOAD_FILE) end)
    if not r or r=="" then return end
    local ok2,d=pcall(function() return HS:JSONDecode(r) end)
    if ok2 and type(d)=="table" then
        AutoLoad.Enabled=d.Enabled or false
        AutoLoad.LastConfig=d.LastConfig or ""
    end
end
local function saveAutoLoad()
    if not writefile then return end
    pcall(function() writefile(AUTOLOAD_FILE,HS:JSONEncode(AutoLoad)) end)
end
loadAutoLoad()

local function snapshot()
    return {
        SilentAimEnabled=CONFIG.SilentAimEnabled,
        AutoFireInFOV=CONFIG.AutoFireInFOV,
        AutoFireDelay=CONFIG.AutoFireDelay,
        ShowFOVCircle=CONFIG.ShowFOVCircle,
        FOV_Radius=CONFIG.FOV_Radius,
        AimbotEnabled=CONFIG.AimbotEnabled,
        AimPart=CONFIG.AimPart,
        AimSpeed=CONFIG.AimSpeed,
        AimPrediction=CONFIG.AimPrediction,
        PredictionMs=CONFIG.PredictionMs,
        StickyTarget=CONFIG.StickyTarget,
        WallCheck=CONFIG.WallCheck,
        TargetIndicator=CONFIG.TargetIndicator,
        TeamCheck=CONFIG.TeamCheck,
        ESPEnabled=CONFIG.ESPEnabled,
        ESPTeamCheck=CONFIG.ESPTeamCheck,
    }
end

local function syncVisuals()
    local function setTog(key,val)
        local s=VisualSetters[key]
        if s then pcall(s,val,true) end
    end
    setTog("Enable Silent Aim",CONFIG.SilentAimEnabled)
    setTog("Auto Fire in FOV",CONFIG.AutoFireInFOV)
    setTog("Show FOV Circle",CONFIG.ShowFOVCircle)
    setTog("Enable Aimbot",CONFIG.AimbotEnabled)
    setTog("Aim Prediction",CONFIG.AimPrediction)
    setTog("Sticky Target",CONFIG.StickyTarget)
    setTog("Wall Check",CONFIG.WallCheck)
    setTog("Target Indicator",CONFIG.TargetIndicator)
    setTog("Team Check",CONFIG.TeamCheck)
    setTog("ESP Ativo",CONFIG.ESPEnabled)
    setTog("ESP Team Check",CONFIG.ESPTeamCheck)
    local function setSld(key,val)
        local s=VisualSetters["SLD_"..key]
        if s then pcall(s,val,true) end
    end
    setSld("Auto Fire Delay (ms)",CONFIG.AutoFireDelay)
    setSld("FOV Radius",CONFIG.FOV_Radius)
    setSld("Aim Speed",CONFIG.AimSpeed)
    setSld("Prediction (ms)",CONFIG.PredictionMs)
    local dd=VisualSetters["DD_Aim Part"]
    if dd then pcall(dd,CONFIG.AimPart,true) end
    Fov.Size=UDim2.new(0,CONFIG.FOV_Radius*2,0,CONFIG.FOV_Radius*2)
    Fov.Visible=CONFIG.ShowFOVCircle
    Dot.Visible=CONFIG.ShowFOVCircle
end

local function applySnap(t)
    for k,v in pairs(t) do
        if CONFIG[k]~=nil then CONFIG[k]=v end
    end
    syncVisuals()
end

local cfgRows={}
local function refreshCfgList()
    for _,r in ipairs(cfgRows) do r:Destroy() end
    cfgRows={}
    local saved=readCfgs()
    local names={}
    for n,_ in pairs(saved) do table.insert(names,n) end
    table.sort(names)

    if #names==0 then
        local e=Instance.new("TextLabel")
        e.Size=UDim2.new(1,0,0,40)
        e.BackgroundColor3=Color3.fromRGB(24,24,32)
        e.BorderSizePixel=0
        e.Text="Nenhuma config salva"
        e.TextColor3=Color3.fromRGB(120,130,160)
        e.TextSize=12
        e.Font=Enum.Font.Gotham
        e.ZIndex=11
        e.Parent=CfgS
        local ec=Instance.new("UICorner")
        ec.CornerRadius=UDim.new(0,8)
        ec.Parent=e
        table.insert(cfgRows,e)
        return
    end

    for _,n in ipairs(names) do
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,40)
        row.BackgroundColor3=Color3.fromRGB(24,24,32)
        row.BorderSizePixel=0
        row.ZIndex=11
        row.Parent=CfgS
        local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(0,8) rc.Parent=row
        local rs=Instance.new("UIStroke") rs.Thickness=1 rs.Color=Color3.fromRGB(60,60,80) rs.Parent=row
        local lbl=Instance.new("TextLabel")
        lbl.Position=UDim2.new(0,12,0,0)
        lbl.Size=UDim2.new(1,-160,1,0)
        lbl.BackgroundTransparency=1
        lbl.Text=n
        lbl.TextColor3=Color3.fromRGB(220,220,240)
        lbl.TextSize=12
        lbl.Font=Enum.Font.GothamMedium
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.ZIndex=12
        lbl.Parent=row
        local loadB=Instance.new("TextButton")
        loadB.AnchorPoint=Vector2.new(1,.5)
        loadB.Position=UDim2.new(1,-84,.5,0)
        loadB.Size=UDim2.new(0,60,0,26)
        loadB.BackgroundColor3=Color3.fromRGB(0,180,220)
        loadB.BorderSizePixel=0
        loadB.Text="LOAD"
        loadB.TextColor3=Color3.fromRGB(255,255,255)
        loadB.TextSize=10
        loadB.Font=Enum.Font.GothamBold
        loadB.AutoButtonColor=false
        loadB.ZIndex=12
        loadB.Parent=row
        local lc=Instance.new("UICorner") lc.CornerRadius=UDim.new(0,6) lc.Parent=loadB
        local delB=Instance.new("TextButton")
        delB.AnchorPoint=Vector2.new(1,.5)
        delB.Position=UDim2.new(1,-14,.5,0)
        delB.Size=UDim2.new(0,60,0,26)
        delB.BackgroundColor3=Color3.fromRGB(180,50,50)
        delB.BorderSizePixel=0
        delB.Text="DEL"
        delB.TextColor3=Color3.fromRGB(255,255,255)
        delB.TextSize=10
        delB.Font=Enum.Font.GothamBold
        delB.AutoButtonColor=false
        delB.ZIndex=12
        delB.Parent=row
        local dc=Instance.new("UICorner") dc.CornerRadius=UDim.new(0,6) dc.Parent=delB

        loadB.MouseButton1Click:Connect(function()
            if not ScriptActive then return end
            local s=readCfgs()[n]
            if s then
                applySnap(s)
                AutoLoad.LastConfig=n
                saveAutoLoad()
                lbl.Text=n.."  [CARREGADO]"
                task.delay(1.5,function()
                    if lbl and lbl.Parent then lbl.Text=n end
                end)
            end
        end)
        delB.MouseButton1Click:Connect(function()
            if not ScriptActive then return end
            local s=readCfgs()
            s[n]=nil
            writeCfgs(s)
            if AutoLoad.LastConfig==n then
                AutoLoad.LastConfig=""
                saveAutoLoad()
            end
            refreshCfgList()
        end)

        table.insert(cfgRows,row)
    end
end

local saveSec=Instance.new("TextLabel")
saveSec.Size=UDim2.new(1,0,0,22)
saveSec.BackgroundTransparency=1
saveSec.Text="SALVAR CONFIGURACAO"
saveSec.TextColor3=Color3.fromRGB(0,200,255)
saveSec.TextSize=12
saveSec.Font=Enum.Font.GothamBold
saveSec.TextXAlignment=Enum.TextXAlignment.Left
saveSec.ZIndex=11
saveSec.Parent=CfgS

local saveRow=Instance.new("Frame")
saveRow.Size=UDim2.new(1,0,0,44)
saveRow.BackgroundColor3=Color3.fromRGB(24,24,32)
saveRow.BorderSizePixel=0
saveRow.ZIndex=11
saveRow.Parent=CfgS
local src=Instance.new("UICorner") src.CornerRadius=UDim.new(0,8) src.Parent=saveRow
local srs=Instance.new("UIStroke") srs.Thickness=1 srs.Color=Color3.fromRGB(60,60,80) srs.Parent=saveRow

local nameBox=Instance.new("TextBox")
nameBox.Position=UDim2.new(0,10,0,8)
nameBox.Size=UDim2.new(1,-110,0,28)
nameBox.BackgroundColor3=Color3.fromRGB(30,30,42)
nameBox.BorderSizePixel=0
nameBox.Text=""
nameBox.PlaceholderText="Nome da config"
nameBox.PlaceholderColor3=Color3.fromRGB(120,130,160)
nameBox.TextColor3=Color3.fromRGB(240,240,255)
nameBox.TextSize=12
nameBox.Font=Enum.Font.Gotham
nameBox.ClearTextOnFocus=false
nameBox.ZIndex=12
nameBox.Parent=saveRow
local nbc=Instance.new("UICorner") nbc.CornerRadius=UDim.new(0,6) nbc.Parent=nameBox

local saveBtn=Instance.new("TextButton")
saveBtn.AnchorPoint=Vector2.new(1,.5)
saveBtn.Position=UDim2.new(1,-10,.5,0)
saveBtn.Size=UDim2.new(0,90,0,28)
saveBtn.BackgroundColor3=Color3.fromRGB(0,200,255)
saveBtn.BorderSizePixel=0
saveBtn.Text="SALVAR"
saveBtn.TextColor3=Color3.fromRGB(255,255,255)
saveBtn.TextSize=11
saveBtn.Font=Enum.Font.GothamBold
saveBtn.AutoButtonColor=false
saveBtn.ZIndex=12
saveBtn.Parent=saveRow
local sbc=Instance.new("UICorner") sbc.CornerRadius=UDim.new(0,6) sbc.Parent=saveBtn

saveBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local nm=nameBox.Text
    if nm=="" then return end
    local all=readCfgs()
    all[nm]=snapshot()
    writeCfgs(all)
    nameBox.Text=""
    refreshCfgList()
end)

local listSec=Instance.new("TextLabel")
listSec.Size=UDim2.new(1,0,0,22)
listSec.BackgroundTransparency=1
listSec.Text="CONFIGS SALVAS"
listSec.TextColor3=Color3.fromRGB(0,200,255)
listSec.TextSize=12
listSec.Font=Enum.Font.GothamBold
listSec.TextXAlignment=Enum.TextXAlignment.Left
listSec.ZIndex=11
listSec.Parent=CfgS

refreshCfgList()

-- ============================================================
-- PARTE 7/7 - Auto Carregar + Server Detection + Shutdown
-- ============================================================
local autoSec=Instance.new("TextLabel")
autoSec.Size=UDim2.new(1,0,0,22)
autoSec.BackgroundTransparency=1
autoSec.Text="AUTO CARREGAR"
autoSec.TextColor3=Color3.fromRGB(0,200,255)
autoSec.TextSize=12
autoSec.Font=Enum.Font.GothamBold
autoSec.TextXAlignment=Enum.TextXAlignment.Left
autoSec.ZIndex=11
autoSec.Parent=CfgS

local autoRow=Instance.new("Frame")
autoRow.Size=UDim2.new(1,0,0,36)
autoRow.BackgroundColor3=Color3.fromRGB(24,24,32)
autoRow.BorderSizePixel=0
autoRow.ZIndex=11
autoRow.Parent=CfgS
local arc=Instance.new("UICorner") arc.CornerRadius=UDim.new(0,8) arc.Parent=autoRow
local ars=Instance.new("UIStroke") ars.Thickness=1 ars.Color=Color3.fromRGB(60,60,80) ars.Parent=autoRow

local autoLbl=Instance.new("TextLabel")
autoLbl.Position=UDim2.new(0,12,0,0)
autoLbl.Size=UDim2.new(1,-90,1,0)
autoLbl.BackgroundTransparency=1
autoLbl.Text="Recarregar em novo servidor"
autoLbl.TextColor3=Color3.fromRGB(220,220,240)
autoLbl.TextSize=12
autoLbl.Font=Enum.Font.GothamMedium
autoLbl.TextXAlignment=Enum.TextXAlignment.Left
autoLbl.ZIndex=12
autoLbl.Parent=autoRow

local autoSw=Instance.new("TextButton")
autoSw.AnchorPoint=Vector2.new(1,.5)
autoSw.Position=UDim2.new(1,-10,.5,0)
autoSw.Size=UDim2.new(0,44,0,22)
autoSw.BackgroundColor3=AutoLoad.Enabled and Color3.fromRGB(0,200,255) or Color3.fromRGB(50,50,65)
autoSw.BorderSizePixel=0
autoSw.Text=AutoLoad.Enabled and "ON" or "OFF"
autoSw.TextColor3=Color3.fromRGB(255,255,255)
autoSw.TextSize=10
autoSw.Font=Enum.Font.GothamBold
autoSw.AutoButtonColor=false
autoSw.ZIndex=12
autoSw.Parent=autoRow
local asc=Instance.new("UICorner") asc.CornerRadius=UDim.new(1,0) asc.Parent=autoSw

autoSw.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    AutoLoad.Enabled=not AutoLoad.Enabled
    if AutoLoad.Enabled then
        tw(autoSw,.15,{BackgroundColor3=Color3.fromRGB(0,200,255)})
        autoSw.Text="ON"
    else
        tw(autoSw,.15,{BackgroundColor3=Color3.fromRGB(50,50,65)})
        autoSw.Text="OFF"
    end
    saveAutoLoad()
end)

if AutoLoad.Enabled and AutoLoad.LastConfig~="" then
    local s=readCfgs()[AutoLoad.LastConfig]
    if s then applySnap(s) end
end

if readfile and isfile and writefile then
    pcall(function()
        if isfile(PENDING_FILE) then
            local raw=readfile(PENDING_FILE)
            if raw and raw~="" then
                local ok,d=pcall(function() return HS:JSONDecode(raw) end)
                if ok and type(d)=="table" and d.config then
                    applySnap(d.config)
                    if d.lastName then
                        AutoLoad.LastConfig=d.lastName
                        AutoLoad.Enabled=d.autoEnabled or true
                        saveAutoLoad()
                    end
                    writefile(PENDING_FILE,"")
                end
            end
        end
    end)
end

local lastPlace,lastJob=game.PlaceId,game.JobId
task.spawn(function()
    while ScriptActive do
        task.wait(1)
        local cp,cj=game.PlaceId,game.JobId
        local changed=(cp~=lastPlace) or (cj~="" and cj~=lastJob)
        if changed then
            lastPlace,lastJob=cp,cj
            saveConfig()
            if AutoLoad.Enabled and AutoLoad.LastConfig~="" then
                local s=readCfgs()[AutoLoad.LastConfig]
                if s and writefile then
                    pcall(function()
                        writefile(PENDING_FILE,HS:JSONEncode({
                            config=s,
                            autoEnabled=AutoLoad.Enabled,
                            lastName=AutoLoad.LastConfig,
                        }))
                    end)
                end
            end
        end
    end
end)

ClsB.MouseButton1Click:Connect(function()
    ScriptActive=false
    pcall(function() Mouse.Button1Up() end)
    pcall(function()
        Camera.CameraType=Enum.CameraType.Custom
        Camera.CameraSubject=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    end)
    for _,c in ipairs(AllConns) do pcall(function() c:Disconnect() end) end
    AllConns={}
    pcall(function() RunService:UnbindFromRenderStep("AimbotLoop") end)
    for p,o in pairs(ESPObjects) do
        if o.h then o.h:Destroy() end
        if o.b then o.b:Destroy() end
    end
    ESPObjects={}
    pcall(function() SG:Destroy() end)
end)

print("[Aimbot UI v7.2] Carregado com sucesso!")
