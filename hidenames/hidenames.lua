local addonName = ...
local interactCVar = "SoftTargetInteract"

-- things to hide with the UI
local hiddenValues = {
    { "targetHighlightAlwaysShown", "0" },
    { "Outline", "0" },
    { "SoftTargetIconEnemy", "0" },
    { "SoftTargetIconInteract", "0" },
    { "SoftTargetIconGameObject", "0" },
    { "SoftTargetLowPriorityIcons", "0" },
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
    -- keep interact override tracked until combat ends
    if name == interactCVar and InCombatLockdown() then return end

    -- reapply
    if name:match("^SoftTarget") then
        C_CVar.SetTempCVar(name, activeOverrides[name])
    end
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
    if name == interactCVar and InCombatLockdown() then return end

    local currentValue = C_CVar.GetCVar(name)
    if currentValue and currentValue ~= value then
        C_CVar.SetTempCVar(name, value)
        if C_CVar.GetCVar(name) == value then
            activeOverrides[name] = currentValue
        end
    end
end

-- hide names or restore them when the UI is hidden/shown
local function UpdateNames()
    if HideNamesDisabled or UIParent:IsShown() then
        ClearOverrides()
        return
    end

    for _, setting in ipairs(hiddenValues) do
        ApplyOverride(setting[1], setting[2])
    end

    if HideNamesSuppressInteractGlow then
        ApplyOverride(interactCVar, "0")
    elseif activeOverrides[interactCVar] then
        ClearOverride(interactCVar)
    end

    for _, name in ipairs(playerSettings) do
        if not HideNamesShowPlayerNames then
            ApplyOverride(name, "0")
        elseif activeOverrides[name] then
            ClearOverride(name)
        end
    end
end

-- colour refs shared by chat and the minimap tooltip
local on, off = "|cff33ff66ON|r", "|cffa0a0a0OFF|r"
local show, hide = "|cffe7ff4dSHOW|r", "|cff46cfffHIDE|r"
local function ColorInput(text)
    return "|cffc7aeff" .. text .. "|r"
end

-- print current slash command settings
local function PrintSettings()
    local addonState = HideNamesDisabled and off or on
    local playerNameState = HideNamesShowPlayerNames and show or hide
    local glowState = HideNamesSuppressInteractGlow and hide or show
    print("HideNames " .. addonState .. ", player names " .. playerNameState .. ", interact glow " .. glowState .. ".")
    if not HideNamesDisabled and HideNamesSuppressInteractGlow then
        print("The Interact key pauses while the UI is hidden.")
    end
end

-- controls for non-minimap-button players
SLASH_HIDENAMES1 = "/hidenames"
SlashCmdList.HIDENAMES = function(message)
    local command, mode = message:lower():match("^%s*(%S+)%s*(.-)%s*$")
    local showOrHide = mode == "show" or mode == "hide"
    if mode == "" and (command == "on" or command == "off") then
        HideNamesDisabled = command == "off"
    elseif command == "players" and showOrHide then
        HideNamesShowPlayerNames = mode == "show"
    elseif command == "glow" and showOrHide then
        HideNamesSuppressInteractGlow = mode == "hide"
    else
        PrintSettings()
        print(ColorInput("/hidenames on") .. " or " .. ColorInput("off"))
        print(ColorInput("/hidenames players show") .. " or " .. ColorInput("hide"))
        print(ColorInput("/hidenames glow show") .. " or " .. ColorInput("hide"))
        return
    end

    UpdateNames()
    PrintSettings()
end

-- show minimap controls and their current settings
local displayedTooltip
local function ShowMinimapTooltip(tooltip)
    displayedTooltip = tooltip
    local addonState = HideNamesDisabled and off or on
    tooltip:SetText(C_AddOns.GetAddOnMetadata(addonName, "Title"), NORMAL_FONT_COLOR:GetRGB())
    tooltip:AddLine(ColorInput("Left Click") .. "   Enable/disable add-on ( " .. addonState .. " )", 1, 1, 1)
    if HideNamesDisabled then return end

    local playerNameState = HideNamesShowPlayerNames and show or hide
    local glowState = HideNamesSuppressInteractGlow and hide or show
    tooltip:AddLine(ColorInput("Right Click") .. "   Hide/show player names ( " .. playerNameState .. " )", 1, 1, 1)
    tooltip:AddLine(ColorInput("Shift + Right Click") .. "   Hide/show interact glow ( " .. glowState .. " )", 1, 1, 1)
    if HideNamesSuppressInteractGlow then
        tooltip:AddLine("The Interact key pauses while the UI is hidden.", 0.63, 0.63, 0.63)
    end
end

-- register minimap button with lib (used to be custom but that was breaking with leatrix and such)
local function CreateMinimapButton()
    local brokerLib = LibStub and LibStub("LibDataBroker-1.1", true)
    local iconLib = LibStub and LibStub("LibDBIcon-1.0", true)
    if not brokerLib or not iconLib then return end
    if not HideNamesMinimapDB then
        HideNamesMinimapDB = { minimapPos = math.deg(HideNamesMinimapAngle or math.rad(225)) }
    end
    HideNamesMinimapAngle = nil

    local launcher = brokerLib:NewDataObject(addonName, {
        type = "launcher",
        label = C_AddOns.GetAddOnMetadata(addonName, "Title"),
        icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture"),
        OnTooltipShow = ShowMinimapTooltip,
        OnLeave = function()
            displayedTooltip = nil
        end,
        OnClick = function(self, mouseButton)
            if mouseButton == "LeftButton" then
                HideNamesDisabled = not HideNamesDisabled
            elseif mouseButton == "RightButton" and not HideNamesDisabled then
                if IsShiftKeyDown() then
                    HideNamesSuppressInteractGlow = not HideNamesSuppressInteractGlow
                else
                    HideNamesShowPlayerNames = not HideNamesShowPlayerNames
                end
            else
                return
            end
            UpdateNames()

            if displayedTooltip and displayedTooltip:IsOwned(self) then
                ShowMinimapTooltip(displayedTooltip)
                displayedTooltip:Show()
            end
        end,
    })
    iconLib:Register(addonName, launcher, HideNamesMinimapDB)
end

-- hook into UI on login and clear addon's overrides on logout
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        ClearOverrides()
    elseif event == "PLAYER_LOGIN" then
        UIParent:HookScript("OnHide", UpdateNames)
        UIParent:HookScript("OnShow", UpdateNames)
        CreateMinimapButton()
        UpdateNames()
    elseif event == "PLAYER_REGEN_ENABLED" and (activeOverrides[interactCVar]
        or (HideNamesSuppressInteractGlow and not HideNamesDisabled and not UIParent:IsShown())) then
        UpdateNames()
    end
end)
