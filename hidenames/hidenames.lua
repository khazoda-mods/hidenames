local addonName = ...
local enabled = true

-- name and nameplate settings to override while the UI is hidden.
local hiddenValues = {
    { "UnitNameNPC", "0" },
    { "UnitNameHostleNPC", "0" },
    { "UnitNameInteractiveNPC", "0" },
    { "UnitNameFriendlySpecialNPCName", "0" },
    { "UnitNameNonCombatCreatureName", "0" },
    { "UnitNameForceHideMinus", "1" },
    { "UnitNameFriendlyPetName", "0" },
    { "UnitNameEnemyPetName", "0" },
    { "UnitNameFriendlyMinionName", "0" },
    { "UnitNameEnemyMinionName", "0" },
    { "UnitNameFriendlyGuardianName", "0" },
    { "UnitNameEnemyGuardianName", "0" },
    { "UnitNameFriendlyTotemName", "0" },
    { "UnitNameEnemyTotemName", "0" },
    { "nameplateShowFriendlyNpcs", "0" },
}

-- keep player settings for names in SHOW mode
local playerSettings = {
    "UnitNameOwn",
    "UnitSurnameOwn",
    "UnitNameFocused",
    "UnitNameFriendlyPlayerName",
    "UnitNameEnemyPlayerName",
    "UnitNameGuildTitle",
    "UnitNamePlayerGuild",
    "UnitNamePlayerPVPTitle",
    "nameplateShowFriendlyPlayers",
    "nameplateShowEnemies",
}

-- for remembering which overrides took effect so only they are cleared
local activeOverrides = {}

-- restore previous overriden settings
local function ClearOverride(name)
    C_CVar.RemoveTempCVar(name)
    activeOverrides[name] = nil
end

local function ClearOverrides()
    for name in pairs(activeOverrides) do
        ClearOverride(name)
    end
end

-- tracks only temporary changes the client accepted
local function ApplyOverride(name, value)
    local currentValue = C_CVar.GetCVar(name)
    if currentValue and currentValue ~= value then
        C_CVar.SetTempCVar(name, value)
        if C_CVar.GetCVar(name) == value then
            activeOverrides[name] = true
        end
    end
end

-- hide names or restore them when the UI is hidden/shown
local function UpdateNames()
    if not enabled or UIParent:IsShown() then
        ClearOverrides()
        return
    end

    for _, setting in ipairs(hiddenValues) do
        ApplyOverride(setting[1], setting[2])
    end

    for _, name in ipairs(playerSettings) do
        if not HideNamesShowPlayerNames then
            ApplyOverride(name, "0")
        elseif activeOverrides[name] then
            ClearOverride(name)
        end
    end
end

-- button tooltips for left and right click
local function ShowMinimapTooltip(button)
    if button:GetScript("OnUpdate") then
        return
    end

    local on, off = "|cff33ff66ON|r", "|cffa0a0a0OFF|r"
    local addonState = enabled and on or off
    local playerNameState = HideNamesShowPlayerNames and "|cffe7ff4dSHOW|r" or "|cff46cfffHIDE|r"
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(C_AddOns.GetAddOnMetadata(addonName, "Title"), NORMAL_FONT_COLOR:GetRGB())
    GameTooltip:AddLine("Left-click to toggle addon ( " .. addonState .. " )", 1, 1, 1)
    GameTooltip:AddLine("Right click to hide/show player names ( " .. playerNameState .. " )", 1, 1, 1)
    GameTooltip:Show()
end

-- keep the button on the minimap rim, remember angle and make draggable
local function PositionMinimapButton(button)
    local angle = HideNamesMinimapAngle or math.rad(225)
    local radius = Minimap:GetWidth() / 2 + 4
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function DragMinimapButton(button)
    local x, y = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    HideNamesMinimapAngle = math.atan2(y / scale - centerY, x / scale - centerX)
    PositionMinimapButton(button)
end

local function StopDragging(button)
    button:SetScript("OnUpdate", nil)
end

-- add minimap button and handle clicks
local function CreateMinimapButton()
    local button = CreateFrame("Button", addonName, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    PositionMinimapButton(button)

    -- use Blizzard's circular mask, minimap rim, and mouseover highlight
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    icon:SetTexture(C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)

    local rim = button:CreateTexture(nil, "OVERLAY")
    rim:SetSize(53, 53)
    rim:SetPoint("TOPLEFT")
    rim:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", DragMinimapButton)
    end)
    button:SetScript("OnDragStop", StopDragging)
    button:SetScript("OnHide", StopDragging)
    button:SetScript("OnEnter", ShowMinimapTooltip)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            HideNamesShowPlayerNames = not HideNamesShowPlayerNames
        else
            enabled = not enabled
        end
        UpdateNames()

        if GameTooltip:IsOwned(self) then
            ShowMinimapTooltip(self)
        end
    end)
end

-- hook into UI on login and clear addon's overrides on logout
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        ClearOverrides()
    elseif event == "PLAYER_LOGIN" then
        UIParent:HookScript("OnHide", UpdateNames)
        UIParent:HookScript("OnShow", UpdateNames)
        CreateMinimapButton()
        UpdateNames()
    end
end)
