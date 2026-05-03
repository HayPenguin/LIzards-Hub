-- ====================================
-- ULTRA SLIM ACCENT
-- ====================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local HITBOX_CONFIG
local headState
local SAFETY_RETURN_KEY
local AVS_TELEPORT_KEY



-- Mouse service
local Mouse = LocalPlayer:GetMouse()

-- Variables d'état pour les ESP et View
_G.ESP_STATE = _G.ESP_STATE or {}
local state = _G.ESP_STATE

_G.ESP_ALL_STATE = _G.ESP_ALL_STATE or { enabled = false, objects = {}, connections = {} }
local stateAll = _G.ESP_ALL_STATE

_G.ESP_TEAM_STATE = _G.ESP_TEAM_STATE or { enabled = false, objects = {}, connections = {} }
local stateTeam = _G.ESP_TEAM_STATE

_G.ADVANCED_ESP_STATE = _G.ADVANCED_ESP_STATE or { enabled = false, objects = {}, connections = {}, uiRefresh = nil }
local advEspState = _G.ADVANCED_ESP_STATE

_G.VIEW_STATE = _G.VIEW_STATE or { target = nil, originalSubject = nil, connection = nil }
local stateView = _G.VIEW_STATE

    -- État pour Click TP
        local clickTPEnabled = false
        local clickTPConnection = nil
        local bypassShield = false -- Bypass pour éviter TP dans le ciel/void

    -- État pour Auto Respawn
        _G.NoclipDeathSystemActive = _G.NoclipDeathSystemActive or false
        local diedRecently = false
        local deathPosition = Vector3.zero

    -- État pour CFrame Fly
        local flyActive    = false
        local flySpeed     = 80   -- studs/sec (lower default feels more natural for CFrame)
        local flyUseVelocityMode = false
        local FLY_TOGGLE_KEY = Enum.KeyCode.C
        local flyConn      = nil
        local flyInputConn = nil
        local flyEndConn   = nil
        local flyCharConn  = nil
        local flyKeys = {
            forward = false, back  = false,
            left    = false, right = false,
            up      = false, down  = false,
        }

    -- État pour Safe Rob
        local safeRobActive = false
        local safeRobConnection = nil
        local currentPrompt = nil
        local originalDist = nil
        local platform = nil
        local SAFE_ROB_TOGGLE_KEY = Enum.KeyCode.G

    -- État pour Invisibility
        local invisActive        = false
        local invisKeyConn       = nil
        local invisHintGui       = nil
        local invisHintShown     = false
        local actionHintGui      = nil
        local invisPlatform      = nil
        local invisCamPart       = nil
        local invisHologram      = nil
        local invisFreezeConn    = nil
        local invisFreezePos     = nil
        local invisSpecFlyConn   = nil
        local invisSpecInputConn = nil
        local invisSpecEndConn   = nil
        local invisSpecFlyPos    = Vector3.zero
        local invisSavedHumanoidState = nil
        local invisSpecKeys      = {
            forward = false, back = false,
            left = false, right = false,
            up = false, down = false,
            fast = false, slow = false,
        }
        local INVIS_TOGGLE_KEY        = Enum.KeyCode.H
        local INVIS_UNDERGROUND_DEPTH = 100
        local INVIS_PLATFORM_SIZE     = Vector3.new(8, 1, 8)
        local INVIS_PLATFORM_DROP     = 3.5
        local INVIS_BASE_SPEED        = 40
        local INVIS_FAST_MULTIPLIER   = 2
        local INVIS_SLOW_MULTIPLIER   = 0.5

    -- État pour No Props
        local noPropsConnections = {}
        local targetFolderNames = {"Entities", "Streetlights", "Props", "Fire Hydrants"}

    -- === LOGIQUE NO PROPS (Disable collision on all props) ===
        local function disableProperties(instance)
            if instance:IsA("BasePart") then
                instance.CanTouch = false
                instance.CanCollide = false
                end
            end

        local function setupFolder(folder)
            -- Disable for all current descendants
                local descendants = folder:GetDescendants()
                for _, descendant in ipairs(descendants) do
                disableProperties(descendant)
                end
    
            -- Monitor for new descendants added
        local conn = folder.DescendantAdded:Connect(disableProperties)
            table.insert(noPropsConnections, conn)
                end

        local function toggleNoProps(active)
            if active then
                -- Activer No Props
                local world = workspace:FindFirstChild("World")
                    if not world then return end
        
                     -- Set up existing folders
                     for _, folderName in ipairs(targetFolderNames) do
                     local folder = world:FindFirstChild(folderName)
                         if folder then
                     setupFolder(folder)
                 end
         end
        
            -- Monitor World for new target folders added
        local worldConn = world.ChildAdded:Connect(function(child)
            if table.find(targetFolderNames, child.Name) and child:IsA("Folder") then
                setupFolder(child)
                end
            end)
            table.insert(noPropsConnections, worldConn)
            else
            -- Désactiver No Props
            for _, conn in ipairs(noPropsConnections) do
                conn:Disconnect()
            end
            noPropsConnections = {}
        
            -- Réactiver les collisions (optionnel - peut causer des bugs)
            local world = workspace:FindFirstChild("World")
                if world then
                        for _, folderName in ipairs(targetFolderNames) do
                    local folder = world:FindFirstChild(folderName)
                        if folder then
                            for _, descendant in ipairs(folder:GetDescendants()) do
                                if descendant:IsA("BasePart") then
                                    descendant.CanTouch = true
                                    descendant.CanCollide = true
                                end
                            end
                        end
                    end
                end
            end
        end

    function invisEnsureHintGui()
        if invisHintGui then return invisHintGui end

        local sg = Instance.new("ScreenGui")
        sg.Name = "InvisibilityHintGui"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = playerGui

        local label = Instance.new("TextLabel")
        label.Name = "HintLabel"
        label.Size = UDim2.new(0, 320, 0, 34)
        label.Position = UDim2.new(0.5, -160, 0, 92)
        label.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.Text = ""
        label.TextColor3 = Color3.fromRGB(235, 235, 235)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 16
        label.Parent = sg
        Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

        invisHintGui = sg
        return sg
    end

    function ensureActionHintGui()
        if actionHintGui then return actionHintGui end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ActionHintGui"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.Parent = playerGui

        local label = Instance.new("TextLabel")
        label.Name = "HintLabel"
        label.Size = UDim2.new(0, 760, 0, 42)
        label.Position = UDim2.new(0.5, -380, 0, 92)
        label.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        label.BackgroundTransparency = 1
        label.TextTransparency = 1
        label.TextColor3 = Color3.fromRGB(235, 235, 235)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 16
        label.TextWrapped = true
        label.Parent = sg
        Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

        actionHintGui = sg
        return sg
    end

    function invisShowHint()
        if invisHintShown then return end
        invisHintShown = true

        local sg = invisEnsureHintGui()
        local label = sg:FindFirstChild("HintLabel")
        if not label then return end
        label.Text = getInvisibilityHintText()

        TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.25,
            TextTransparency = 0,
        }):Play()

        task.delay(3.5, function()
            if not label or not label.Parent then return end
            TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                TextTransparency = 1,
            }):Play()
        end)
    end

    function showActionHint(text, duration)
        local sg = ensureActionHintGui()
        local label = sg:FindFirstChild("HintLabel")
        if not label then return end

        label.Text = text or ""
        label.BackgroundTransparency = 1
        label.TextTransparency = 1

        TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.25,
            TextTransparency = 0,
        }):Play()

        task.delay(duration or 8, function()
            if not label or not label.Parent then return end
            TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                TextTransparency = 1,
            }):Play()
        end)
    end

    function invisGetPreviewCFrame(cam)
        cam = cam or workspace.CurrentCamera
        local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.001 then
            flatLook = Vector3.new(0, 0, -1)
        end
        return CFrame.lookAt(invisSpecFlyPos, invisSpecFlyPos + flatLook.Unit)
    end

    function invisDestroyPlatform()
        if invisPlatform then
            invisPlatform:Destroy()
            invisPlatform = nil
        end
    end

    function invisStopFreeze()
        if invisFreezeConn then
            invisFreezeConn:Disconnect()
            invisFreezeConn = nil
        end
        invisFreezePos = nil
    end

    function invisStartFreeze(pinPos)
        invisStopFreeze()
        invisFreezePos = pinPos
        invisFreezeConn = RunService.Heartbeat:Connect(function()
            if not invisActive then
                invisStopFreeze()
                return
            end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not invisFreezePos then return end
            if (hrp.Position - invisFreezePos).Magnitude > 0.35 then
                hrp.CFrame = CFrame.new(invisFreezePos) * hrp.CFrame.Rotation
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    function invisDestroyHologram()
        if invisHologram then
            invisHologram:Destroy()
            invisHologram = nil
        end
    end

    function invisUpdateHologram(cam)
        if not invisHologram or not invisHologram.Parent then return end
        pcall(function()
            invisHologram:PivotTo(invisGetPreviewCFrame(cam))
        end)
    end

    function invisStopSpectator()
        if invisSpecFlyConn   then invisSpecFlyConn:Disconnect();   invisSpecFlyConn   = nil end
        if invisSpecInputConn then invisSpecInputConn:Disconnect(); invisSpecInputConn = nil end
        if invisSpecEndConn   then invisSpecEndConn:Disconnect();   invisSpecEndConn   = nil end
        for k in pairs(invisSpecKeys) do
            invisSpecKeys[k] = false
        end
        if invisCamPart then
            invisCamPart:Destroy()
            invisCamPart = nil
        end
        local cam = workspace.CurrentCamera
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
        end
    end

    function invisCreateHologram(char)
        invisDestroyHologram()

        local oldArchivable = char.Archivable
        char.Archivable = true
        local ok, clone = pcall(function()
            return char:Clone()
        end)
        char.Archivable = oldArchivable
        if not ok or not clone then return nil end

        clone.Name = "InvisibilityHologram"
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CanCollide = false
                obj.CanTouch = false
                obj.CanQuery = false
                obj.Material = Enum.Material.ForceField
                obj.Color = Color3.fromRGB(80, 170, 255)
                obj.Transparency = 0.45
            elseif obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("Humanoid") then
                obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            elseif obj:IsA("Accessory") then
                local handle = obj:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    handle.Anchored = true
                    handle.CanCollide = false
                    handle.CanTouch = false
                    handle.CanQuery = false
                    handle.Material = Enum.Material.ForceField
                    handle.Color = Color3.fromRGB(80, 170, 255)
                    handle.Transparency = 0.45
                end
            end
        end

        clone.Parent = workspace
        invisHologram = clone
        invisUpdateHologram(workspace.CurrentCamera)
        return clone
    end

    function invisLockHumanoid(hum)
        if not hum then return end
        invisSavedHumanoidState = {
            WalkSpeed = hum.WalkSpeed,
            JumpPower = hum.JumpPower,
            AutoRotate = hum.AutoRotate,
        }
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
        hum.PlatformStand = false
    end

    function invisRestoreHumanoid(hum)
        if not hum then return end
        if invisSavedHumanoidState then
            hum.WalkSpeed = invisSavedHumanoidState.WalkSpeed
            hum.JumpPower = invisSavedHumanoidState.JumpPower
            hum.AutoRotate = invisSavedHumanoidState.AutoRotate
        else
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.AutoRotate = true
        end
        invisSavedHumanoidState = nil
    end

    function invisStartSpectator(originCFrame, char)
        local anchor = Instance.new("Part")
        anchor.Name = "InvisibilityCamAnchor"
        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.Transparency = 1
        anchor.CFrame = originCFrame
        anchor.Parent = workspace
        invisCamPart = anchor
        invisSpecFlyPos = originCFrame.Position

        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = anchor

        invisCreateHologram(char)

        invisSpecInputConn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == Enum.KeyCode.W then invisSpecKeys.forward = true end
            if inp.KeyCode == Enum.KeyCode.S then invisSpecKeys.back = true end
            if inp.KeyCode == Enum.KeyCode.A then invisSpecKeys.left = true end
            if inp.KeyCode == Enum.KeyCode.D then invisSpecKeys.right = true end
            if inp.KeyCode == Enum.KeyCode.Space then invisSpecKeys.up = true end
            if inp.KeyCode == Enum.KeyCode.Q then invisSpecKeys.down = true end
            if inp.KeyCode == Enum.KeyCode.LeftShift then invisSpecKeys.fast = true end
            if inp.KeyCode == Enum.KeyCode.LeftControl then invisSpecKeys.slow = true end
        end)
        invisSpecEndConn = UserInputService.InputEnded:Connect(function(inp)
            if inp.KeyCode == Enum.KeyCode.W then invisSpecKeys.forward = false end
            if inp.KeyCode == Enum.KeyCode.S then invisSpecKeys.back = false end
            if inp.KeyCode == Enum.KeyCode.A then invisSpecKeys.left = false end
            if inp.KeyCode == Enum.KeyCode.D then invisSpecKeys.right = false end
            if inp.KeyCode == Enum.KeyCode.Space then invisSpecKeys.up = false end
            if inp.KeyCode == Enum.KeyCode.Q then invisSpecKeys.down = false end
            if inp.KeyCode == Enum.KeyCode.LeftShift then invisSpecKeys.fast = false end
            if inp.KeyCode == Enum.KeyCode.LeftControl then invisSpecKeys.slow = false end
        end)
        invisSpecFlyConn = RunService.Heartbeat:Connect(function(dt)
            if not invisCamPart or not invisCamPart.Parent then return end
            local cf = cam.CFrame
            local look = cf.LookVector
            local right = cf.RightVector
            local dir = Vector3.zero
            if invisSpecKeys.forward then dir = dir + look end
            if invisSpecKeys.back then dir = dir - look end
            if invisSpecKeys.right then dir = dir + right end
            if invisSpecKeys.left then dir = dir - right end
            if invisSpecKeys.up then dir = dir + Vector3.new(0, 1, 0) end
            if invisSpecKeys.down then dir = dir - Vector3.new(0, 1, 0) end

            local speed = INVIS_BASE_SPEED
            if invisSpecKeys.fast then
                speed = speed * INVIS_FAST_MULTIPLIER
            end
            if invisSpecKeys.slow then
                speed = speed * INVIS_SLOW_MULTIPLIER
            end

            if dir.Magnitude > 0 then
                invisSpecFlyPos = invisSpecFlyPos + dir.Unit * speed * dt
            end

            invisCamPart.CFrame = CFrame.new(invisSpecFlyPos)
            invisUpdateHologram(cam)
        end)
    end

    -- === LOGIQUE INVISIBILITY (underground spectator hologram) ===
function toggleInvisibility(active)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if active then
            if not hum or not hrp then return end
            if invisActive then return end

            local undergroundCFrame = hrp.CFrame - Vector3.new(0, INVIS_UNDERGROUND_DEPTH, 0)
            local platformCFrame = undergroundCFrame * CFrame.new(0, -INVIS_PLATFORM_DROP, 0)

            invisDestroyPlatform()
            invisPlatform = Instance.new("Part")
            invisPlatform.Name = "InvisibilityPlatform"
            invisPlatform.Size = INVIS_PLATFORM_SIZE
            invisPlatform.Anchored = true
            invisPlatform.CanCollide = true
            invisPlatform.CanTouch = true
            invisPlatform.CanQuery = true
            invisPlatform.Transparency = 1
            invisPlatform.CFrame = platformCFrame
            invisPlatform.Parent = workspace

            invisLockHumanoid(hum)

            local hiddenPos = (platformCFrame * CFrame.new(0, INVIS_PLATFORM_DROP + 0.1, 0)).Position
            hrp.CFrame = CFrame.new(hiddenPos) * hrp.CFrame.Rotation
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            invisStartFreeze(hiddenPos)

            invisStartSpectator(workspace.CurrentCamera.CFrame, char)
            invisActive = true

        else
            if not invisActive then return end

            local previewCFrame = invisGetPreviewCFrame(workspace.CurrentCamera)

            invisStopFreeze()
            invisStopSpectator()
            invisDestroyPlatform()

            if hrp then
                hrp.CFrame = previewCFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
            if hum then
                invisRestoreHumanoid(hum)
                hum.PlatformStand = false
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            end
            invisDestroyHologram()
            invisActive = false
        end
    end

    function toggleInvisibilitySystem(active)
        if active then
            invisShowHint()

            if invisKeyConn then invisKeyConn:Disconnect() end
            invisKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == INVIS_TOGGLE_KEY then
                    toggleInvisibility(not invisActive)
                end
            end)
        else
            if invisKeyConn then
                invisKeyConn:Disconnect()
                invisKeyConn = nil
            end
            toggleInvisibility(false)
        end
    end

    -- === LOGIQUE SAFE ROB (Avoid getting arrested while robbing) ===
        local function findNearestPrompt(position)
        local nearest = nil
        local shortestDist = math.huge
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local part = obj.Parent
                        if part:IsA("BasePart") then
                        local dist = (part.Position - position).Magnitude
                            if dist < shortestDist then
                            shortestDist = dist
                                nearest = obj
                                end
                            end
                        end
                    end
                return nearest
            end

        local function toggleSafeRobMode()
        local char = LocalPlayer.Character
            if not char then 
                return end
        local root = char:FindFirstChild("HumanoidRootPart")
                if not root then 
                    return end
    
                if not safeRobActive then
                    -- Activate: Teleport up 20 studs, create platform, extend prompt range
                    root.CFrame = root.CFrame + Vector3.new(0, 20, 0)
        
                     -- Create temporary platform below
                        platform = Instance.new("Part")
                        platform.Size = Vector3.new(10, 1, 10)
                        platform.Position = root.Position - Vector3.new(0, 3, 0)
                        platform.Anchored = true
                        platform.CanCollide = true
                        platform.Transparency = 0.3
                        platform.Color = Color3.new(0, 0, 1)
                        platform.Parent = workspace
                        -- Extend nearest prompt range
                        currentPrompt = findNearestPrompt(root.Position)
                    if currentPrompt then
                    originalDist = currentPrompt.MaxActivationDistance
                    currentPrompt.MaxActivationDistance = 40
                 end
                    safeRobActive = true
                    else
                    -- Deactivate: Delete platform, reset prompt, teleport down
                    if platform then
                        platform:Destroy()
                        platform = nil
                     end
        
                    if currentPrompt then
                            currentPrompt.MaxActivationDistance = originalDist or 10
                            currentPrompt = nil
                            originalDist = nil
                     end
                    root.CFrame = root.CFrame + Vector3.new(0, -20, 0)
                    safeRobActive = false
                 end
                 end

        local function toggleSafeRob(active)
            if active then
                -- Activer Safe Rob
                safeRobConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then 
                    return end
                if input.KeyCode == SAFE_ROB_TOGGLE_KEY then
                    toggleSafeRobMode()
                 end
            end)
        
            -- Reset on respawn
            LocalPlayer.CharacterAdded:Connect(function(char)
                char:WaitForChild("HumanoidRootPart")
                safeRobActive = false
                currentPrompt = nil
                originalDist = nil
                if platform then
                    platform:Destroy()
                    platform = nil
                 end
             end)
            else
                -- Désactiver Safe Rob
                if safeRobConnection then
                safeRobConnection:Disconnect()
                safeRobConnection = nil
             end
        
                -- Reset si actif
                if safeRobActive then
                toggleSafeRobMode()
             end
             end
         end

    -- === LOGIQUE TAXI FARM ===
        _G.TAXI_FARM_STATE = _G.TAXI_FARM_STATE or 
            {
            enabled = false,
            running = true,
            panicTriggered = false,
            teleportQueue = false,
            mainLoop = nil
            }
        local taxiState = _G.TAXI_FARM_STATE
        local Speed = 300
        local UndergroundOffset = 255
        local function tweenToTarget(targetPosition)
        local character = LocalPlayer.Character
            if not character then 
                return end
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
            if not root or not humanoid then 
                return end
    
        local startPosition = root.Position
        local undergroundPosition = startPosition - Vector3.new(0, UndergroundOffset, 0)
        local targetUndergroundPosition = Vector3.new(targetPosition.X, undergroundPosition.Y, targetPosition.Z)
        local function doTween(position)
            root.Velocity = Vector3.new()
            root.RotVelocity = Vector3.new()
        local distance = (position - root.Position).Magnitude
        local duration = distance / Speed
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = CFrame.new(position)})
            tween:Play()
            return tween
         end

            humanoid.PlatformStand = true
            root.Anchored = true
            doTween(undergroundPosition).Completed:Wait()
            doTween(targetUndergroundPosition).Completed:Wait()
            doTween(targetPosition).Completed:Wait()
            root.Anchored = false
            humanoid.PlatformStand = false
            root.Velocity = Vector3.new()
            root.RotVelocity = Vector3.new()
            end

        local function toggleTaxiFarm(active)
            taxiState.enabled = active
    
            if active then
                -- Réinitialiser les états
                taxiState.running = true
                taxiState.panicTriggered = false
                taxiState.teleportQueue = true -- Auto-activate à chaque nouvelle mission
        
                -- Main Loop
                taxiState.mainLoop = task.spawn(function()
                    while taxiState.running do
        local clientContent = workspace:WaitForChild("Gameplay"):WaitForChild("Entities"):WaitForChild("ClientContent")
        local vehicleInteraction = clientContent:WaitForChild("VehicleInteraction", 9e9)

                if vehicleInteraction and taxiState.teleportQueue then
                    pcall(function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local Event = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("PlayerFunc")
                        Event:InvokeServer("talkToMission", vehicleInteraction)
                    end)
                    tweenToTarget(vehicleInteraction.Position)
                    taxiState.teleportQueue = true -- Réactiver pour la prochaine mission
                end
                task.wait(0.1)
            end
        end)
        
        else
        -- Désactiver Taxi Farm
        taxiState.running = false
        
        -- Cleanup main loop
        if taxiState.mainLoop then
            task.cancel(taxiState.mainLoop)
            taxiState.mainLoop = nil
        end
        
        taxiState.teleportQueue = false
        end
        end

    local function executePanic()
        if taxiState.panicTriggered then return end
        taxiState.panicTriggered = true
        taxiState.running = false
        taxiState.enabled = false
    
        -- Cleanup main loop
        if taxiState.mainLoop then
        task.cancel(taxiState.mainLoop)
        taxiState.mainLoop = nil
        end
    
        -- Reset character state
        local character = LocalPlayer.Character
        if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if root then
            root.Anchored = false
            root.Velocity = Vector3.new()
            root.RotVelocity = Vector3.new()
        end
        if humanoid then
            humanoid.PlatformStand = false
        end
        end
    
        -- Reset states
        _G.TAXI_FARM_STATE = {
        enabled = false,
        running = true,
        panicTriggered = false,
        teleportQueue = false,
        mainLoop = nil
        }
        end

    -- === LOGIQUE TOUCH FLING ===
local touchFlingEnabled = false
local touchFlingConnection = nil

function toggleTouchFling(active)
    touchFlingEnabled = active

    if active then
        touchFlingConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local otherHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    if otherHRP and (otherHRP.Position - hrp.Position).Magnitude < 6 then
                        hrp.Velocity = hrp.Velocity * 10000 + Vector3.new(0, 9000, 0)
                    end
                end
            end
        end)
    else
        if touchFlingConnection then
            touchFlingConnection:Disconnect()
            touchFlingConnection = nil
        end
    end
end

-- === LOGIQUE FLY (Heartbeat velocity-zeroing CFrame fly — replicates to server) ===
function toggleFly(active)
    if active then
        local function startFlyForChar(char)
            local hum = char:WaitForChild("Humanoid", 5)
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if not hum or not hrp then return end

            if flyConn      then flyConn:Disconnect()      flyConn      = nil end
            if flyInputConn then flyInputConn:Disconnect() flyInputConn = nil end
            if flyEndConn   then flyEndConn:Disconnect()   flyEndConn   = nil end

            local flyPos = hrp.Position

            flyInputConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                if inp.KeyCode == FLY_TOGGLE_KEY then
                    flyActive = not flyActive
                    if flyActive then
                        flyPos = hrp.Position
                        hum.PlatformStand = true
                        -- No Anchored=true — anchoring client-side doesn't replicate,
                        -- so other players would see you frozen. Instead we zero all
                        -- velocities every Heartbeat, which DOES replicate.
                    else
                        hum.PlatformStand = false
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        for k in pairs(flyKeys) do flyKeys[k] = false end
                    end
                end
                if inp.KeyCode == Enum.KeyCode.W           then flyKeys.forward = true end
                if inp.KeyCode == Enum.KeyCode.S           then flyKeys.back    = true end
                if inp.KeyCode == Enum.KeyCode.A           then flyKeys.left    = true end
                if inp.KeyCode == Enum.KeyCode.D           then flyKeys.right   = true end
                if inp.KeyCode == Enum.KeyCode.Space       then flyKeys.up      = true end
                if inp.KeyCode == Enum.KeyCode.LeftControl then flyKeys.down    = true end
            end)

            flyEndConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.KeyCode == Enum.KeyCode.W           then flyKeys.forward = false end
                if inp.KeyCode == Enum.KeyCode.S           then flyKeys.back    = false end
                if inp.KeyCode == Enum.KeyCode.A           then flyKeys.left    = false end
                if inp.KeyCode == Enum.KeyCode.D           then flyKeys.right   = false end
                if inp.KeyCode == Enum.KeyCode.Space       then flyKeys.up      = false end
                if inp.KeyCode == Enum.KeyCode.LeftControl then flyKeys.down    = false end
            end)

            flyConn = RunService.Heartbeat:Connect(function(dt)
                if not flyActive then return end
                local r = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not r then return end

                local cam   = workspace.CurrentCamera
                local look  = cam.CFrame.LookVector
                local right = cam.CFrame.RightVector

                local moveDir = Vector3.zero
                if flyKeys.forward then moveDir = moveDir + look  end
                if flyKeys.back    then moveDir = moveDir - look  end
                if flyKeys.right   then moveDir = moveDir + right end
                if flyKeys.left    then moveDir = moveDir - right end
                if flyKeys.up      then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if flyKeys.down    then moveDir = moveDir - Vector3.new(0, 1, 0) end

                if flyUseVelocityMode then
                    if moveDir.Magnitude > 0 then
                        r.Velocity = moveDir.Unit * flySpeed
                    else
                        r.Velocity = Vector3.zero
                    end

                    r.CFrame = CFrame.new(r.Position, r.Position + cam.CFrame.LookVector)
                else
                    if moveDir.Magnitude > 0 then
                        flyPos = flyPos + moveDir.Unit * flySpeed * dt
                    end

                    -- Zero velocity on every body part every frame — this is what
                    -- defeats gravity and replicates correctly to the server.
                    -- The server accepts client-owned character CFrame + zero velocity
                    -- and replicates the position to all other clients.
                    local c = LocalPlayer.Character
                    if c then
                        for _, part in ipairs(c:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.AssemblyLinearVelocity  = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end

                    r.CFrame = CFrame.new(flyPos) * cam.CFrame.Rotation
                end
            end)
        end

        if LocalPlayer.Character then startFlyForChar(LocalPlayer.Character) end
        flyCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
            flyActive = false
            startFlyForChar(char)
        end)
    else
        flyActive = false
        for _, c in pairs({ flyConn, flyInputConn, flyEndConn, flyCharConn }) do
            if c then c:Disconnect() end
        end
        flyConn = nil; flyInputConn = nil; flyEndConn = nil; flyCharConn = nil
        for k in pairs(flyKeys) do flyKeys[k] = false end

        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.PlatformStand then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- === LOGIQUE AUTO RESPAWN (Never get arrested & skip death timer) ===
local respawnRadius = 60
local respawnHeight = 5

function noclipCharacter(character)
    task.spawn(function()
        while character and character.Parent and _G.NoclipDeathSystemActive do
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            task.wait(0.1)
        end
    end)
end

function getRandomPosition()
    local angle = math.random() * 2 * math.pi
    local radius = math.random() * respawnRadius
    local xOffset = math.cos(angle) * radius
    local zOffset = math.sin(angle) * radius
    return deathPosition + Vector3.new(xOffset, respawnHeight, zOffset)
end

function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        if _G.NoclipDeathSystemActive then
            deathPosition = character:GetPivot().Position
            diedRecently = true
            noclipCharacter(character)
        end
    end)
end

local characterAddedConnection = nil

function toggleAutoRespawn(active)
    _G.NoclipDeathSystemActive = active
    
    if active then
        -- Activer Auto Respawn
        characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
            if _G.NoclipDeathSystemActive then
                newCharacter:WaitForChild("HumanoidRootPart")
                
                if diedRecently then
                    newCharacter.HumanoidRootPart.CFrame = CFrame.new(getRandomPosition())
                    diedRecently = false
                end
                
                setupCharacter(newCharacter)
            end
        end)
        
        -- Setup current character
        local currentCharacter = LocalPlayer.Character
        if currentCharacter then
            setupCharacter(currentCharacter)
        end
    else
        -- Désactiver Auto Respawn
        if characterAddedConnection then
            characterAddedConnection:Disconnect()
            characterAddedConnection = nil
        end
        diedRecently = false
    end
end

-- === LOGIQUE XYZ TP ===
function executeXYZTP(x, y, z)
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Direction vectors (relative to facing)
    local forward = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    local up = Vector3.new(0, 1, 0)
    
    -- Final movement vector
    local moveVector = 
        (forward * x) + 
        (right * y) + 
        (up * z)
    
    -- Apply teleport
    root.CFrame = root.CFrame + moveVector
end

-- =========================================
-- AIMBOT
-- =========================================
_G.LIZARD_AIMBOT = _G.LIZARD_AIMBOT or {
    enabled = false,
    holding = false,
    locked = false,
    fovCircle = nil,
    conn = nil,
    inputBegan = nil,
    inputEnded = nil,
    targetCache = {},
    targetList = {},
    cacheConns = {},
    cachedTargetChar = nil,
    cachedTargetPart = nil,
    nextTargetScan = 0,
    lastAimMouse = nil,
    lastAimLook = nil,
    aimTurnX = 0,
}
local aimState = _G.LIZARD_AIMBOT
for _, conn in ipairs({aimState.conn, aimState.inputBegan, aimState.inputEnded}) do
    if conn then pcall(function() conn:Disconnect() end) end
end
for _, conn in ipairs(aimState.cacheConns or {}) do
    if conn then pcall(function() conn:Disconnect() end) end
end
if aimState.fovCircle then pcall(function() aimState.fovCircle.Visible = false end) end
aimState.enabled = false
aimState.holding = false
aimState.locked = false
aimState.conn = nil
aimState.inputBegan = nil
aimState.inputEnded = nil
aimState.cacheConns = {}
aimState.targetCache = {}
aimState.targetList = {}
aimState.cachedTargetChar = nil
aimState.cachedTargetPart = nil
aimState.nextTargetScan = 0
aimState.lastAimMouse = nil
aimState.lastAimLook = nil
aimState.aimTurnX = 0

local AIMBOT_CONFIG = {
    toggleKey = "MouseButton2",
    method = "Camera",
    targetScope = "Players + NPCs",
    targetPart = "Head",
    mode = "Hold",
    wallCheck = false,
    teamCheck = false,
    smoothingEnabled = false,
    smoothness = 5,
    predictionEnabled = false,
    prediction = 0.3,
    distanceCheck = true,
    maxDistance = 1000,
    fovEnabled = false,
    fovRadius = 160,
    fovColor = Color3.fromRGB(255, 255, 255),
    filterMode = "None",
    filterCategory = "Teams",
    disabledTeams = {},
    disabledPlayers = {},
    onlyTeams = {},
    onlyPlayers = {},
}

function aimScopeAllowsPlayers()
    return AIMBOT_CONFIG.targetScope == "Players" or AIMBOT_CONFIG.targetScope == "Players + NPCs"
end

function aimScopeAllowsNPCs()
    return AIMBOT_CONFIG.targetScope == "NPCs" or AIMBOT_CONFIG.targetScope == "Players + NPCs"
end

function aimFilterHasOnlySelection()
    local onlySet = AIMBOT_CONFIG.filterCategory == "Teams" and AIMBOT_CONFIG.onlyTeams or AIMBOT_CONFIG.onlyPlayers
    return next(onlySet) ~= nil
end

function aimFilterMatches(player, category, teamSet, playerSet)
    if category == "Players" then return playerSet[player.Name] == true end
    return player.Team and teamSet[player.Team.Name] == true or false
end

function aimPassesPlayerFilter(player)
    if AIMBOT_CONFIG.filterMode == "Enable only for" then
        if not aimFilterHasOnlySelection() then return true end
        return aimFilterMatches(player, AIMBOT_CONFIG.filterCategory, AIMBOT_CONFIG.onlyTeams, AIMBOT_CONFIG.onlyPlayers)
    elseif AIMBOT_CONFIG.filterMode == "Disable only for" then
        return not aimFilterMatches(player, AIMBOT_CONFIG.filterCategory, AIMBOT_CONFIG.disabledTeams, AIMBOT_CONFIG.disabledPlayers)
    end
    return true
end

function aimInputMatches(input)
    if AIMBOT_CONFIG.toggleKey == "MouseButton1" then return input.UserInputType == Enum.UserInputType.MouseButton1 end
    if AIMBOT_CONFIG.toggleKey == "MouseButton2" then return input.UserInputType == Enum.UserInputType.MouseButton2 end
    if AIMBOT_CONFIG.toggleKey == "MouseButton3" then return input.UserInputType == Enum.UserInputType.MouseButton3 end
    local ok, keyCode = pcall(function()
        return Enum.KeyCode[AIMBOT_CONFIG.toggleKey]
    end)
    return ok and keyCode and input.KeyCode == keyCode
end

function aimFormatToggleKey()
    local key = AIMBOT_CONFIG.toggleKey or "MouseButton2"
    if key == "MouseButton1" then return "MB1" end
    if key == "MouseButton2" then return "MB2" end
    if key == "MouseButton3" then return "MB3" end
    return tostring(key)
end

function aimSetToggleFromInput(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
        AIMBOT_CONFIG.toggleKey = input.KeyCode.Name
        return true
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
        AIMBOT_CONFIG.toggleKey = input.UserInputType.Name
        return true
    end
    return false
end

function aimGetTargetPart(char)
    if not char then return nil end
    local name = AIMBOT_CONFIG.targetPart
    if name == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso")
    elseif name == "HumanoidRootPart" then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart")
end

function aimHasForceField(char)
    return char and char:FindFirstChildOfClass("ForceField") ~= nil
end

function aimIsValidTarget(char)
    if not char or char == LocalPlayer.Character then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = aimGetTargetPart(char)
    if not hum or hum.Health <= 0 or not part then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end

    local plr = Players:GetPlayerFromCharacter(char)
    if plr and not aimScopeAllowsPlayers() then return false end
    if not plr and not aimScopeAllowsNPCs() then return false end
    if plr and not aimPassesPlayerFilter(plr) then return false end
    if not plr and AIMBOT_CONFIG.filterMode == "Enable only for" and aimFilterHasOnlySelection() then return false end
    if plr and AIMBOT_CONFIG.teamCheck and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
        return false
    end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if AIMBOT_CONFIG.distanceCheck and localRoot and (part.Position - localRoot.Position).Magnitude > AIMBOT_CONFIG.maxDistance then
        return false
    end

    if AIMBOT_CONFIG.wallCheck then
        local cam = workspace.CurrentCamera
        local origin = cam.CFrame.Position
        local dir = part.Position - origin
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
        local result = workspace:Raycast(origin, dir, params)
        if result and not result.Instance:IsDescendantOf(char) then
            return false
        end
    end

    return true
end

function aimIterCharacters()
    local chars = {}
    if aimScopeAllowsPlayers() then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then table.insert(chars, plr.Character) end
        end
    end
    if aimScopeAllowsNPCs() then
        for i = #aimState.targetList, 1, -1 do
            local char = aimState.targetList[i]
            if char and char.Parent and aimState.targetCache[char] then
                table.insert(chars, char)
            else
                table.remove(aimState.targetList, i)
            end
        end
    end
    return chars
end

function aimTrackNPCModel(char)
    if not char or aimState.targetCache[char] or Players:GetPlayerFromCharacter(char) then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    aimState.targetCache[char] = true
    table.insert(aimState.targetList, char)
    table.insert(aimState.cacheConns, char.AncestryChanged:Connect(function(_, parent)
        if parent ~= nil then return end
        aimState.targetCache[char] = nil
    end))
end

function aimBuildTargetCache()
    aimState.targetCache = {}
    aimState.targetList = {}
    for _, conn in ipairs(aimState.cacheConns or {}) do
        if conn then conn:Disconnect() end
    end
    aimState.cacheConns = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
            aimTrackNPCModel(obj.Parent)
        end
    end
    table.insert(aimState.cacheConns, workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
            aimTrackNPCModel(obj.Parent)
        end
    end))
end

function aimClearTargetCache()
    for _, conn in ipairs(aimState.cacheConns or {}) do
        if conn then conn:Disconnect() end
    end
    aimState.cacheConns = {}
    aimState.targetCache = {}
    aimState.targetList = {}
    aimState.cachedTargetChar = nil
    aimState.cachedTargetPart = nil
end

function aimGetBestTarget()
    local cam = workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local bestChar, bestPart, bestScore = nil, nil, math.huge
    local turnX = aimState.aimTurnX or 0

    for _, char in ipairs(aimIterCharacters()) do
        if aimIsValidTarget(char) then
            local part = aimGetTargetPart(char)
            local pos = part.Position
            if AIMBOT_CONFIG.predictionEnabled then
                pos = pos + (part.AssemblyLinearVelocity * AIMBOT_CONFIG.prediction)
            end
            local screenPos, onScreen = cam:WorldToViewportPoint(pos)
            if onScreen then
                local screen = Vector2.new(screenPos.X, screenPos.Y)
                local offset = screen - mouse
                local dist = offset.Magnitude
                if (not AIMBOT_CONFIG.fovEnabled or dist <= AIMBOT_CONFIG.fovRadius) then
                    local score = dist
                    if math.abs(turnX) > 0.25 then
                        local side = offset.X >= 0 and 1 or -1
                        if side == (turnX > 0 and 1 or -1) then
                            score = score - math.min(math.abs(turnX) * 18, AIMBOT_CONFIG.fovRadius * 0.45)
                        else
                            score = score + math.min(math.abs(turnX) * 8, AIMBOT_CONFIG.fovRadius * 0.25)
                        end
                    end
                    if score < bestScore then
                        bestChar, bestPart, bestScore = char, part, score
                    end
                end
            end
        end
    end

    return bestChar, bestPart
end

function aimUpdateFovCircle()
    if aimState.fovCircle then
        pcall(function() aimState.fovCircle.Visible = false end)
        aimState.fovCircle = nil
    end
    if not aimState.fovGui or not aimState.fovGui.Parent then
        local gui = Instance.new("ScreenGui")
        gui.Name = "LizardFovCircleGui"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 1000000010
        gui.Parent = playerGui
        aimState.fovGui = gui
    end
    if not aimState.fovGuiCircle or not aimState.fovGuiCircle.Parent then
        local circle = Instance.new("Frame")
        circle.Name = "FovCircle"
        circle.BackgroundTransparency = 1
        circle.Visible = false
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Parent = aimState.fovGui
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", circle)
        stroke.Thickness = 1
        stroke.Color = AIMBOT_CONFIG.fovColor
        aimState.fovGuiCircle = circle
        aimState.fovGuiStroke = stroke
    end
    if not AIMBOT_CONFIG.enabled or not AIMBOT_CONFIG.fovEnabled then
        aimState.fovGuiCircle.Visible = false
        return
    end
    local mouse = UserInputService:GetMouseLocation()
    local radius = AIMBOT_CONFIG.fovRadius
    aimState.fovGuiCircle.Visible = true
    aimState.fovGuiCircle.Position = UDim2.fromOffset(mouse.X, mouse.Y)
    aimState.fovGuiCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
    if aimState.fovGuiStroke then aimState.fovGuiStroke.Color = AIMBOT_CONFIG.fovColor end
end

function aimStep()
    aimUpdateFovCircle()
    if not AIMBOT_CONFIG.enabled then return end
    local shouldAim = AIMBOT_CONFIG.mode == "Toggle" and aimState.locked or aimState.holding
    local cam = workspace.CurrentCamera
    local mouseNow = UserInputService:GetMouseLocation()
    local mouseTurn = aimState.lastAimMouse and (mouseNow.X - aimState.lastAimMouse.X) or 0
    local lookTurn = aimState.lastAimLook and cam.CFrame.RightVector:Dot(cam.CFrame.LookVector - aimState.lastAimLook) * 300 or 0
    aimState.lastAimMouse = mouseNow
    aimState.lastAimLook = cam.CFrame.LookVector
    aimState.aimTurnX = (aimState.aimTurnX or 0) * 0.65 + (math.abs(mouseTurn) > math.abs(lookTurn) and mouseTurn or lookTurn) * 0.35
    if not shouldAim then
        aimState.cachedTargetChar, aimState.cachedTargetPart = nil, nil
        return
    end

    local now = tick()
    if now >= (aimState.nextTargetScan or 0) then
        aimState.cachedTargetChar, aimState.cachedTargetPart = aimGetBestTarget()
        aimState.nextTargetScan = now + 0.08
    end
    if aimState.cachedTargetChar and not aimIsValidTarget(aimState.cachedTargetChar) then
        aimState.cachedTargetChar, aimState.cachedTargetPart = nil, nil
        aimState.nextTargetScan = 0
        return
    end
    local targetPart = aimState.cachedTargetChar and aimGetTargetPart(aimState.cachedTargetChar) or aimState.cachedTargetPart
    if shouldAim and targetPart then
        local predicted = targetPart.Position
        if AIMBOT_CONFIG.predictionEnabled then
            predicted = predicted + (targetPart.AssemblyLinearVelocity * AIMBOT_CONFIG.prediction)
        end
        local goal = CFrame.lookAt(cam.CFrame.Position, predicted)
        local alpha = AIMBOT_CONFIG.smoothingEnabled and math.clamp(1 / math.max(AIMBOT_CONFIG.smoothness, 1), 0.05, 1) or 1
        cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    end
end

function toggleAimbot(active)
    AIMBOT_CONFIG.enabled = active
    if active then
        if aimState.conn then return end
        aimBuildTargetCache()
        aimState.nextTargetScan = 0
        aimState.conn = RunService.RenderStepped:Connect(function()
            local ok, err = pcall(aimStep)
            if not ok and tick() - (aimState.lastRenderWarn or 0) > 2 then
                aimState.lastRenderWarn = tick()
                warn("[Aimbot] Render update failed:", err)
            end
        end)
        aimState.inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if aimInputMatches(input) then
                if AIMBOT_CONFIG.mode == "Toggle" then
                    aimState.locked = not aimState.locked
                else
                    aimState.holding = true
                end
            end
        end)
        aimState.inputEnded = UserInputService.InputEnded:Connect(function(input)
            if aimInputMatches(input) and AIMBOT_CONFIG.mode == "Hold" then
                aimState.holding = false
            end
        end)
    else
        for _, conn in ipairs({aimState.conn, aimState.inputBegan, aimState.inputEnded}) do
            if conn then conn:Disconnect() end
        end
        aimState.conn = nil
        aimState.inputBegan = nil
        aimState.inputEnded = nil
        aimState.holding = false
        aimState.locked = false
        aimState.lastAimMouse = nil
        aimState.lastAimLook = nil
        aimState.aimTurnX = 0
        aimClearTargetCache()
        if aimState.fovCircle then aimState.fovCircle.Visible = false end
        if aimState.fovGuiCircle then aimState.fovGuiCircle.Visible = false end
    end
end
-- Configuration
local Config = {
    openKey = Enum.KeyCode.Home,
    position = UDim2.new(0.5, -340, 0.5, -250),
    size = UDim2.new(0, 680, 0, 500),
    minSize = {width = 560, height = 380},
    
    categories = {
        {name = "AIM", scripts = {
            {name = "Aimbot", active = false, isAimbot = true},
            {name = "Expander HitBox", isHitboxExpander = true},
        }},
        {name = "VISUAL", scripts = {
            {name = "One Person ESP", isESP = true},
            {name = "View Player", isViewPlayer = true},
            {name = "Advanced ESP", active = false, isAdvancedESP = true},
            {name = "Inf Zoom-Out", active = false, isInfZoom = true}
        }},
        {name = "PLAYER", scripts = {
            {name = "Click TP", active = false, isClickTP = true},
            {name = "XYZ TP", isXYZTP = true},
            {name = "Fly", active = false, isFly = true},
            {name = "Safe Rob", active = false, isSafeRob = true},
            {name = "Infinite stats", active = false, isInfStats = true},
            {name = "Avoid death", active = false, isAvoidDeath = true},
            {name = "Anti-Arrest", active = false, isAntiArrest = true},
            {name = "House Anti-Kick", active = false, isHouseAntiKick = true},
            {name = "Expand Handcuff Range", active = false, isExpandCuffs = true},
            {name = "Anim Zombie FE", isZombie = true},
            {name = "Invisibility", active = false, isInvisibility = true},
        }},
        {name = "FARM", scripts = {
            {name = "Golf Autofarm", active = false, isGolfFarm = true},
        }},
        {name = "OTHER", scripts = {
            {name = "No Props", active = false, isNoProps = true},
            {name = "Remove REDLight/Speed", active = false, isRemoveRedSpeed = true},
            {name = "Inf Ammo", active = false, isInfAmmo = true},
            {name = "Bypass All Restrictions", active = false, isBypassAll = true},
            {name = "Car No Damage", active = false, isCarNoDamage = true},
            {name = "Instant Interact", active = false, isInstantInteract = true},
            {name = "Change outfit while wanted", active = false, isChangeAVS = true},
            {name = "UGC Emotes", isUGCEmotes = true},
            {name = "Violent mod menu", isViolentMenu = true},
            {name = "Auto ATM (Might miss sometimes)", active = false, isAutoATM = true},
        }},
        {name = "TELEPORT", scripts = {
            {name = "Hospital bed",          isTeleportPoint = true, tpPos = Vector3.new(3931,  -337,  -250)},
            {name = "Hospital",              isTeleportPoint = true, tpPos = Vector3.new(3887,     3,  -184)},
            {name = "Spawn",                 isTeleportPoint = true, tpPos = Vector3.new(3731,     4,  -446)},
            {name = "Clothing store City",   isTeleportPoint = true, tpPos = Vector3.new(3600,  -336,  -438)},
            {name = "Car shop",              isTeleportPoint = true, tpPos = Vector3.new(3720,  -447,  -301)},
            {name = "Police station",        isTeleportPoint = true, tpPos = Vector3.new(3351,  -337,  -495)},
            {name = "Autoshop",              isTeleportPoint = true, tpPos = Vector3.new(2805,     3,  -416)},
            {name = "National bank",         isTeleportPoint = true, tpPos = Vector3.new(3133,  -322,  -263)},
            {name = "Parking building",      isTeleportPoint = true, tpPos = Vector3.new(3124,    46,    68)},
            {name = "Cinema",                isTeleportPoint = true, tpPos = Vector3.new(3298,     3,   427)},
            {name = "Arcade",                isTeleportPoint = true, tpPos = Vector3.new(2946,  -346,  1762)},
            {name = "Golf",                  isTeleportPoint = true, tpPos = Vector3.new(2288,     3,  1990)},
            {name = "Gradview homes",        isTeleportPoint = true, tpPos = Vector3.new(3487,    77,  2047)},
            {name = "Grandview town",        isTeleportPoint = true, tpPos = Vector3.new(3487,    77,  2047)},
            {name = "Yacht",                 isTeleportPoint = true, tpPos = Vector3.new(985,    -22,  1300)},
            {name = "Leisville",             isTeleportPoint = true, tpPos = Vector3.new(781,      3,   888)},
            {name = "Maldini's pizza",       isTeleportPoint = true, tpPos = Vector3.new(764,   -337,   954)},
            {name = "Clothing store Leisville", isTeleportPoint = true, tpPos = Vector3.new(806, -337,  1055)},
            {name = "Gun store",             isTeleportPoint = true, tpPos = Vector3.new(-337,  -205,    63)},
            {name = "Yorktown",              isTeleportPoint = true, tpPos = Vector3.new(-292,     3,  -159)},
            {name = "Yorktown bank",         isTeleportPoint = true, tpPos = Vector3.new(-674,  -337,  -100)},
            {name = "Westdale hill",         isTeleportPoint = true, tpPos = Vector3.new(357,    178,  -446)},
            {name = "Prison",                isTeleportPoint = true, tpPos = Vector3.new(-1637,    3,  1264)},
            {name = "Milton homes",          isTeleportPoint = true, tpPos = Vector3.new(-583,     3,  1566)},
            {name = "Gas station",           isTeleportPoint = true, tpPos = Vector3.new(2274,     3,   128)},
        }},
        {name = "HOMES", scripts = {
            {name = "Enter Home", isHomeFinder = true},
        }},
        {name = "CAR", scripts = {
            {name = "Car Scanner", active = false, isCarScanner = true},
        }},
        {name = "AVATARS", scripts = {
            {name = "Avatar Saves", isAvatarSaves = true},
        }}
    },
    
    selectedCategory = 1,
    
colors = {
        background = Color3.fromRGB(8, 8, 10),        -- Noir pur profond
        header = Color3.fromRGB(12, 12, 15),          -- En-tête très sombre
        categoryBg = Color3.fromRGB(16, 16, 20),      -- Noir "Fumé" (box catégories)
        categoryBadge = Color3.fromRGB(10, 10, 12),   -- Badge presque invisible
        categorySelected = Color3.fromRGB(45, 25, 80), -- Violet sombre (sélection)
        categoryHover = Color3.fromRGB(22, 22, 28),    -- Survol très discret
        scriptBg = Color3.fromRGB(14, 14, 18),        -- Boutons de scripts noirs
        scriptHover = Color3.fromRGB(25, 15, 45),     -- Survol avec lueur violette
        activeButton = Color3.fromRGB(130, 50, 255),  -- Violet vif (Accentuation)
        inactiveButton = Color3.fromRGB(25, 25, 30),  -- Gris sombre (Bouton Off)
        textbox = Color3.fromRGB(25, 25, 30),         -- MEME COULEUR QUE INACTIVE BUTTON
        homeButton = Color3.fromRGB(35, 35, 40),      -- Bouton Home neutre
        unloadButton = Color3.fromRGB(150, 40, 40),   -- Rouge sombre
        text = Color3.fromRGB(230, 230, 230),         -- Blanc cassé
        textDim = Color3.fromRGB(90, 90, 100),        -- Texte sombre
        accent = Color3.fromRGB(140, 60, 255)         -- Violet des dégradés
    }
}

local KEYBIND_DEFAULTS = {
    menuOpen = Enum.KeyCode.Home,
    flyToggle = Enum.KeyCode.C,
    safeRobToggle = Enum.KeyCode.G,
    invisibilityToggle = Enum.KeyCode.H,
    hitboxDebug = Enum.KeyCode.H,
    hitboxKillAll = Enum.KeyCode.K,
    avoidDeathReturn = Enum.KeyCode.V,
    avsTeleport = Enum.KeyCode.Y,
}

local KEYBIND_ORDER = {
    { id = "menuOpen", label = "Menu Open" },
    { id = "flyToggle", label = "Fly Toggle" },
    { id = "safeRobToggle", label = "Safe Rob Toggle" },
    { id = "invisibilityToggle", label = "Invisibility Toggle" },
    { id = "hitboxDebug", label = "Hitbox Debug" },
    { id = "hitboxKillAll", label = "Hitbox Kill-All" },
    { id = "avoidDeathReturn", label = "Avoid Death Return" },
    { id = "avsTeleport", label = "Avatar Saves Teleport" },
}

local Keybinds = {
    menuOpen = KEYBIND_DEFAULTS.menuOpen,
    flyToggle = KEYBIND_DEFAULTS.flyToggle,
    safeRobToggle = KEYBIND_DEFAULTS.safeRobToggle,
    invisibilityToggle = KEYBIND_DEFAULTS.invisibilityToggle,
    hitboxDebug = KEYBIND_DEFAULTS.hitboxDebug,
    hitboxKillAll = KEYBIND_DEFAULTS.hitboxKillAll,
    avoidDeathReturn = KEYBIND_DEFAULTS.avoidDeathReturn,
    avsTeleport = KEYBIND_DEFAULTS.avsTeleport,
}

function keybindToString(keyCode)
    return keyCode and ("[" .. keyCode.Name:upper() .. "]") or "[NONE]"
end

function getInvisibilityHintText()
    return "Press " .. keybindToString(Keybinds.invisibilityToggle) .. " for invisibility"
end

function getFlyHintText()
    return keybindToString(Keybinds.flyToggle) .. " Toggle fly on/off"
end

function getHitboxInstructionText()
    return keybindToString(Keybinds.hitboxDebug) .. " Debug  |  " .. keybindToString(Keybinds.hitboxKillAll) .. " Kill All"
end

function getSafetyHealLabel()
    return "Healing...  WASD / Ctrl / Space to spectate.  Press " .. keybindToString(Keybinds.avoidDeathReturn) .. " to resurface (80+ HP needed)."
end

function getAVSInstructionText()
    return "CHANGE OUTFIT WHILE WANTED\nPress " .. keybindToString(Keybinds.avsTeleport) .. " to teleport to the outfit zone.\nPress " .. keybindToString(Keybinds.avsTeleport) .. " again to return to your original spot."
end

function getAVSStatusText()
    return "Teleported to outfit zone  |  " .. keybindToString(Keybinds.avsTeleport) .. " to return"
end

function serializeKeybinds()
    local out = {}
    for key, code in pairs(Keybinds) do
        out[key] = code and code.Name or nil
    end
    return out
end

function refreshLiveKeybindUI()
    if invisHintGui and invisHintGui:FindFirstChild("HintLabel") then
        invisHintGui.HintLabel.Text = getInvisibilityHintText()
    end
    if homeButton then
        homeButton.Text = Config.openKey.Name:upper()
    end
    local avsGui = _G.ChangeAVSState and _G.ChangeAVSState.gui
    if avsGui then
        local instrFrame = avsGui:FindFirstChild("InstrFrame")
        local instrText = instrFrame and instrFrame:FindFirstChildOfClass("TextLabel")
        if instrText then instrText.Text = getAVSInstructionText() end
        local statusLabel = avsGui:FindFirstChild("StatusLabel")
        if statusLabel then statusLabel.Text = getAVSStatusText() end
    end
    if headState and headState.enabled then
        updateHitboxStatusUI(getHitboxInstructionText(), true)
    end
    if _G.SaveSystem_RefreshScriptUI then
        _G.SaveSystem_RefreshScriptUI()
    end
    if _G.KeybindPanel_Refresh then _G.KeybindPanel_Refresh() end
end

function applySavedKeybinds(saved)
    if type(saved) ~= "table" then return end
    for key, name in pairs(saved) do
        if Keybinds[key] and type(name) == "string" and Enum.KeyCode[name] then
            Keybinds[key] = Enum.KeyCode[name]
        end
    end
    Config.openKey = Keybinds.menuOpen
    FLY_TOGGLE_KEY = Keybinds.flyToggle
    SAFE_ROB_TOGGLE_KEY = Keybinds.safeRobToggle
    INVIS_TOGGLE_KEY = Keybinds.invisibilityToggle
    if HITBOX_CONFIG then
        HITBOX_CONFIG.DEBUG_KEY = Keybinds.hitboxDebug
        HITBOX_CONFIG.KILL_ALL_KEY = Keybinds.hitboxKillAll
    end
    SAFETY_RETURN_KEY = Keybinds.avoidDeathReturn
    AVS_TELEPORT_KEY = Keybinds.avsTeleport
    refreshLiveKeybindUI()
end

applySavedKeybinds(serializeKeybinds())

-- === LOGIQUE CLICK TP ===
function toggleClickTP(active)
    clickTPEnabled = active
    
    if active then
        -- Activer Click TP
        if not clickTPConnection then
            clickTPConnection = Mouse.Button1Down:Connect(function()
                if clickTPEnabled and Mouse.Target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    -- Bypass : si activé, ne pas TP sur certains objets
                    if not bypassShield or (bypassShield and Mouse.Target.Name ~= "Sky" and Mouse.Target.Name ~= "Void") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = Mouse.Hit
                    end
                end
            end)
        end
    else
        -- Désactiver Click TP
        if clickTPConnection then
            clickTPConnection:Disconnect()
            clickTPConnection = nil
        end
    end
end

-- =========================================
-- BIG HEAD HITBOX V5
-- =========================================

HITBOX_CONFIG = {
    TARGET_MODE    = "Head",
    SIZE_BY_TARGET = {
        Head = 12,
        Torso = 12,
        HumanoidRootPart = 12,
        Limbs = 12,
    },
    TARGET_PLAYERS = true,
    TARGET_NPCS    = true,
    TEAM_CHECK     = false,   -- if true, skip teammates
    DEBUG_KEY      = Enum.KeyCode.H,
    KILL_ALL_KEY   = Enum.KeyCode.K,
    KILL_RANGE     = 100,     -- studs: only targets within this radius get pulled in
    KILL_SPAWN_DIST = 22      -- studs: how far in front of player the kill zone sits
}

local VISUAL_TYPES = {
    "BillboardGui", "Decal", "Texture", "SpecialMesh",
    "FaceControls", "WrapTarget", "SurfaceAppearance",
}

_G.BIG_HEAD_STATE = _G.BIG_HEAD_STATE or {
    enabled        = false,
    killAllActive  = false,
    debugActive    = false,
    connections    = {},
    targetCache    = {},
    instructionGui = nil,
    settingsRefresh = nil,
}
headState = _G.BIG_HEAD_STATE

function isVisualItem(item)
    for _, t in ipairs(VISUAL_TYPES) do
        if item:IsA(t) then return true end
    end
    return false
end

-- UI
function createHitboxUI()
    if headState.instructionGui then headState.instructionGui:Destroy() end
    local sg    = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    sg.Name     = "HitboxUI"
    sg.ResetOnSpawn = false
    local label = Instance.new("TextLabel", sg)
    label.Name                   = "MainLabel"
    label.Size                   = UDim2.new(1, 0, 0, 50)
    label.Position               = UDim2.new(0, 0, 0.8, 0)
    label.BackgroundTransparency = 1
    label.TextColor3             = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextSize               = 22
    label.Font                   = Enum.Font.SourceSansBold
    label.TextTransparency       = 1
    headState.instructionGui     = sg
    return label
end

function updateHitboxStatusUI(text, active, color)
    local label = headState.instructionGui and headState.instructionGui:FindFirstChild("MainLabel") or createHitboxUI()
    label.Text       = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = active and 0 or 1}):Play()
end

function getHitboxTargetSize(mode)
    return tonumber(HITBOX_CONFIG.SIZE_BY_TARGET[mode or HITBOX_CONFIG.TARGET_MODE]) or 12
end

function getHitboxTargetSizeVector(mode)
    local s = getHitboxTargetSize(mode)
    return Vector3.new(s, s, s)
end

function getHitboxPartNames(char, mode)
    mode = mode or HITBOX_CONFIG.TARGET_MODE
    if mode == "Head" then
        return {"Head"}
    elseif mode == "HumanoidRootPart" then
        return {"HumanoidRootPart"}
    elseif mode == "Torso" then
        if char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso") then
            return {"UpperTorso", "LowerTorso"}
        end
        return {"Torso"}
    elseif mode == "Limbs" then
        if char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("RightUpperArm") then
            return {
                "LeftUpperArm", "LeftLowerArm", "LeftHand",
                "RightUpperArm", "RightLowerArm", "RightHand",
                "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                "RightUpperLeg", "RightLowerLeg", "RightFoot",
            }
        end
        return {"Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    end
    return {}
end

function shouldUseGhostForHitboxPart(part)
    return part and part.Name ~= "HumanoidRootPart"
end

function ensureHitboxHighlight(part, name, color)
    if not part then return end
    local existing = part:FindFirstChild(name)
    if existing then
        existing.Color3 = color
        return
    end
    local box = Instance.new("SelectionBox", part)
    box.Name = name
    box.Adornee = part
    box.Color3 = color
    box.Transparency = 0.5
    if name == "KillAll_Highlight" then
        box.SurfaceTransparency = 0.8
    end
end

function clearHitboxHighlight(part, name)
    if part and part:FindFirstChild(name) then
        part[name]:Destroy()
    end
end

function refreshHitboxVisualsForCharacter(char)
    local cached = headState.targetCache[char]
    if not cached or not cached.Parts then return end
    for _, entry in pairs(cached.Parts) do
        if entry.Part and entry.Part.Parent then
            if headState.debugActive then
                ensureHitboxHighlight(entry.Part, "Debug_Highlight", Color3.fromRGB(0, 255, 0))
            else
                clearHitboxHighlight(entry.Part, "Debug_Highlight")
            end
        end
    end
end

function applyHitboxMode(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local cached = headState.targetCache[char]
    if not cached then return end

    restoreHitboxCharacter(char)
    cached.Parts = {}

    local targetNames = getHitboxPartNames(char, HITBOX_CONFIG.TARGET_MODE)
    local targetSize = getHitboxTargetSizeVector(HITBOX_CONFIG.TARGET_MODE)

    hum.AutomaticScalingEnabled = false

    for _, partName in ipairs(targetNames) do
        local realPart = char:FindFirstChild(partName)
        if realPart and realPart:IsA("BasePart") then
            local entry = {
                Part = realPart,
                Ghost = nil,
                ChildConn = nil,
                EnforcerConns = {},
                Original = {
                    Size = realPart.Size,
                    Transparency = realPart.Transparency,
                    CanCollide = realPart.CanCollide,
                    Massless = realPart.Massless,
                    Anchored = realPart.Anchored,
                }
            }

            if shouldUseGhostForHitboxPart(realPart) then
                local ok, fakePart = pcall(function()
                    return realPart:Clone()
                end)
                if ok and fakePart then
                    fakePart.Name = "VisualHitboxGhost_" .. realPart.Name
                    fakePart.Size = entry.Original.Size
                    fakePart.CanCollide = false
                    fakePart.Massless = true
                    fakePart.Anchored = false
                    fakePart.Transparency = entry.Original.Transparency
                    fakePart.CFrame = realPart.CFrame
                    for _, item in ipairs(fakePart:GetDescendants()) do
                        if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then item:Destroy() end
                    end
                    for _, item in ipairs(fakePart:GetChildren()) do
                        if item:IsA("WeldConstraint") or item:IsA("Motor6D") or item:IsA("Weld") then item:Destroy() end
                    end
                    fakePart.Parent = char
                    local weld = Instance.new("WeldConstraint", fakePart)
                    weld.Part0 = realPart
                    weld.Part1 = fakePart

                    for _, item in ipairs(realPart:GetChildren()) do
                        if isVisualItem(item) then
                            item.Parent = fakePart
                        end
                    end

                    entry.ChildConn = realPart.ChildAdded:Connect(function(child)
                        task.wait()
                        if child and child.Parent == realPart and isVisualItem(child) then
                            child.Parent = fakePart
                        end
                    end)
                    entry.Ghost = fakePart
                end
            end

            realPart.Size = targetSize
            realPart.Transparency = 1
            realPart.CanCollide = false
            realPart.Massless = true

            table.insert(entry.EnforcerConns, realPart:GetPropertyChangedSignal("Transparency"):Connect(function()
                if realPart.Transparency ~= 1 then realPart.Transparency = 1 end
            end))
            table.insert(entry.EnforcerConns, realPart:GetPropertyChangedSignal("Size"):Connect(function()
                if realPart.Size ~= targetSize then realPart.Size = targetSize end
            end))
            table.insert(entry.EnforcerConns, realPart:GetPropertyChangedSignal("CanCollide"):Connect(function()
                if realPart.CanCollide ~= false then realPart.CanCollide = false end
            end))
            if entry.Ghost then
                table.insert(entry.EnforcerConns, entry.Ghost:GetPropertyChangedSignal("Transparency"):Connect(function()
                    if entry.Ghost and entry.Ghost.Transparency ~= entry.Original.Transparency then
                        entry.Ghost.Transparency = entry.Original.Transparency
                    end
                end))
            end

            cached.Parts[realPart.Name] = entry
        end
    end

    refreshHitboxVisualsForCharacter(char)
end

function reapplyHitboxForAll()
    for char in pairs(headState.targetCache) do
        if char and char.Parent then
            applyHitboxMode(char)
        end
    end
    if headState.settingsRefresh then headState.settingsRefresh() end
end

function rebuildHitboxRoster()
    for char in pairs(headState.targetCache) do
        restoreHitboxCharacter(char)
    end
    headState.targetCache = {}
    if not headState.enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent:IsA("Model") then
            addToHitboxCache(obj.Parent)
        end
    end
    if headState.settingsRefresh then headState.settingsRefresh() end
end

-- Restore
function restoreHitboxCharacter(char)
    if not char then return end
    local cached = headState.targetCache[char]
    if not cached then return end
    if cached.Parts then
        for _, entry in pairs(cached.Parts) do
            if entry.ChildConn then entry.ChildConn:Disconnect() end
            if entry.EnforcerConns then
                for _, c in ipairs(entry.EnforcerConns) do c:Disconnect() end
            end
            local part = entry.Part
            if part and part.Parent then
                part.Anchored = entry.Original.Anchored
                part.Size = entry.Original.Size
                part.Transparency = entry.Original.Transparency
                part.CanCollide = entry.Original.CanCollide
                part.Massless = entry.Original.Massless
                if part:FindFirstChild("Debug_Highlight") then part.Debug_Highlight:Destroy() end
                if part:FindFirstChild("KillAll_Highlight") then part.KillAll_Highlight:Destroy() end
            end
            if entry.Ghost then
                if part and part.Parent then
                    for _, item in ipairs(entry.Ghost:GetChildren()) do
                        if isVisualItem(item) then item.Parent = part end
                    end
                end
                entry.Ghost:Destroy()
            end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutomaticScalingEnabled = true end
    cached.Parts = {}
end

function addToHitboxCache(char)
    if not char or headState.targetCache[char] or char == LocalPlayer.Character then return end
    local isPlayer = Players:GetPlayerFromCharacter(char)
    if isPlayer and not HITBOX_CONFIG.TARGET_PLAYERS then return end
    if not isPlayer and not HITBOX_CONFIG.TARGET_NPCS then return end
    -- Team check: skip players on the same team as us
    if isPlayer and HITBOX_CONFIG.TEAM_CHECK then
        if isPlayer.Team ~= nil and isPlayer.Team == LocalPlayer.Team then return end
    end
    local hum = char:WaitForChild("Humanoid", 3)
    if not hum then return end
    headState.targetCache[char] = { Humanoid = hum, Parts = {} }
    applyHitboxMode(char)

    -- Use HealthChanged instead of Died — fires the instant health hits 0,
    -- before the game's NPC cleanup code can destroy the model.
    local deathConn; deathConn = hum.HealthChanged:Connect(function(hp)
        if hp > 0 then return end
        deathConn:Disconnect()
        -- Small yield so ragdoll physics settles before we restore
        task.defer(function()
            restoreHitboxCharacter(char)
            headState.targetCache[char] = nil
        end)
    end)
    table.insert(headState.connections, deathConn)

    -- Safety net: if the model is removed from workspace entirely, clean up
    local ancestryConn; ancestryConn = char.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            ancestryConn:Disconnect()
            restoreHitboxCharacter(char)
            headState.targetCache[char] = nil
        end
    end)
    table.insert(headState.connections, ancestryConn)
end

function toggleHitboxDebug()
    headState.debugActive = not headState.debugActive
    updateHitboxStatusUI(headState.debugActive and "DEBUG ON" or "DEBUG OFF", true, Color3.fromRGB(0, 255, 0))
    for char in pairs(headState.targetCache) do refreshHitboxVisualsForCharacter(char) end
    task.wait(1)
    if not headState.killAllActive then updateHitboxStatusUI(getHitboxInstructionText(), true) end
end

function toggleHitboxKillAll()
    headState.killAllActive = not headState.killAllActive
    if not headState.killAllActive then
        updateHitboxStatusUI("STOPPING...", true, Color3.fromRGB(255, 255, 0))
        task.wait(0.2); updateHitboxStatusUI(getHitboxInstructionText(), true)
        return
    end
    local char_root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not char_root then headState.killAllActive = false return end
    local staticKillZone = char_root.CFrame * CFrame.new(0, 0, -HITBOX_CONFIG.KILL_SPAWN_DIST)
    updateHitboxStatusUI("KILL-ALL ACTIVE", true, Color3.fromRGB(255, 50, 50))
    local snapshot = {}
    for char in pairs(headState.targetCache) do
        local isPlayer = Players:GetPlayerFromCharacter(char)
        if HITBOX_CONFIG.TEAM_CHECK and isPlayer and isPlayer.Team ~= nil and isPlayer.Team == LocalPlayer.Team then
            -- skip teammate
        else
            -- Only include targets within the search radius
            local targetRoot = char:FindFirstChild("HumanoidRootPart")
            if targetRoot and (targetRoot.Position - char_root.Position).Magnitude <= HITBOX_CONFIG.KILL_RANGE then
                snapshot[char] = true
            end
        end
    end
    task.spawn(function()
        while headState.killAllActive and headState.enabled do
            local targetsAlive = 0
            for char in pairs(snapshot) do
                local data = headState.targetCache[char]
                if data and data.Humanoid and data.Humanoid.Health > 0 and data.Parts and next(data.Parts) then
                    targetsAlive = targetsAlive + 1
                    for _, entry in pairs(data.Parts) do
                        local part = entry.Part
                        if part and part.Parent then
                            part.Anchored = true
                            part.CFrame = staticKillZone
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                            ensureHitboxHighlight(part, "KillAll_Highlight", Color3.fromRGB(255, 0, 0))
                        end
                    end
                else snapshot[char] = nil end
            end
            if targetsAlive == 0 then headState.killAllActive = false break end
            RunService.Heartbeat:Wait()
        end
        for char in pairs(headState.targetCache) do restoreHitboxCharacter(char) end
        for char in pairs(headState.targetCache) do applyHitboxMode(char) end
        updateHitboxStatusUI(getHitboxInstructionText(), true)
    end)
end

local hitboxInputConn = nil

-- =========================================
-- HITBOX TOGGLE SYSTEM
-- =========================================

function cleanupHitbox()
    for _, c in ipairs(headState.connections) do c:Disconnect() end
    headState.connections = {}
    headState.settingsRefresh = nil
    if hitboxInputConn then hitboxInputConn:Disconnect() hitboxInputConn = nil end
    headState.killAllActive = false
    headState.debugActive = false
    for char in pairs(headState.targetCache) do restoreHitboxCharacter(char) end
    headState.targetCache = {}
    if headState.instructionGui then headState.instructionGui:Destroy() headState.instructionGui = nil end
end

function toggleHitbox(enable)
    headState.enabled = enable
    if enable then
        createHitboxUI()
        updateHitboxStatusUI(getHitboxInstructionText(), true)
        rebuildHitboxRoster()
        table.insert(headState.connections, workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("Humanoid") then
                task.delay(0.1, function() if obj.Parent then addToHitboxCache(obj.Parent) end end)
            end
        end))
        table.insert(headState.connections, Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(char) addToHitboxCache(char) end)
        end))
        -- H/K input listener
        hitboxInputConn = UserInputService.InputBegan:Connect(function(io, gpe)
            if gpe then return end
            if io.KeyCode == HITBOX_CONFIG.KILL_ALL_KEY then toggleHitboxKillAll()
            elseif io.KeyCode == HITBOX_CONFIG.DEBUG_KEY then toggleHitboxDebug() end
        end)
    else
        cleanupHitbox()
    end
end


-- === LOGIQUE VIEW PLAYER ===
local Camera = workspace.CurrentCamera

function clearView()
    if stateView.connection then
        stateView.connection:Disconnect()
    end

    if stateView.originalSubject then
        Camera.CameraSubject = stateView.originalSubject
    end

    stateView.target = nil
    stateView.connection = nil
    stateView.originalSubject = nil
end

function findPlayerByPartialName(partial)
    partial = partial:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower():sub(1, #partial) == partial then
            return plr
        end
    end
    return nil
end

function runViewPlayer(playerSearch)
    -- Vide = stop viewing
    if playerSearch == "" then
        clearView()
        return
    end

    -- Trouver le joueur
    local target = findPlayerByPartialName(playerSearch)
    if not target or not target.Character then
        return
    end

    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Même target = toggle off
    if stateView.target == target then
        clearView()
        return
    end

    -- Switch target
    clearView()
    stateView.target = target
    stateView.originalSubject = Camera.CameraSubject

    -- Lock camera to target
    Camera.CameraSubject = humanoid
    Camera.CameraType = Enum.CameraType.Custom

    -- Safety loop (character respawn / leave)
    stateView.connection = RunService.RenderStepped:Connect(function()
        if not stateView.target 
        or not stateView.target.Character 
        or not stateView.target.Character:FindFirstChildOfClass("Humanoid") then
            clearView()
        end
    end)
end

-- === LOGIQUE AUTO ATM HACK ===
local atmHackConnection = nil
local atmHackActive = false

function runAtmHack()
    local AtmGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui") 
        and LocalPlayer.PlayerGui.ScreenGui:FindFirstChild("Center")
        and LocalPlayer.PlayerGui.ScreenGui.Center:FindFirstChild("Middle")
        and LocalPlayer.PlayerGui.ScreenGui.Center.Middle:FindFirstChild("HackingMinigames")
        and LocalPlayer.PlayerGui.ScreenGui.Center.Middle.HackingMinigames:FindFirstChild("ATM Hack")

    local BlockedColor = Color3.fromRGB(74, 75, 93)
    local ClickedButtons = {}

    if AtmGui and AtmGui.Sequence1.Text ~= "" then
        -- Récupération des codes
        local Codes = {}
        for Code in string.gmatch(AtmGui.Sequence1.Text, "([^%s]+)") do
            table.insert(Codes, Code)
        end

        -- Scan des boutons
        for _, Button in ipairs(AtmGui.List:GetDescendants()) do
            if Button:IsA("ImageButton") and not ClickedButtons[Button] and Button.ImageColor3 ~= BlockedColor then
                for _, Label in ipairs(Button:GetDescendants()) do
                    if Label:IsA("TextLabel") then
                        for _, Code in ipairs(Codes) do
                            if Label.Text == Code then
                                -- Clic virtuel
                                local Pos = Button.AbsolutePosition
                                local Size = Button.AbsoluteSize
                                local X = Pos.X + Size.X/2
                                local Y = Pos.Y + (Size.Y/2) + 58 -- Offset correction GUI
                                game:GetService("VirtualInputManager"):SendMouseButtonEvent(X, Y, 0, true, game, 0)
                                game:GetService("VirtualInputManager"):SendMouseButtonEvent(X, Y, 0, false, game, 0)
                                ClickedButtons[Button] = true
                                break
                            end
                        end
                    end
                    if ClickedButtons[Button] then break end
                end
            end
        end
    end
end

function toggleAtmHack(active)
    atmHackActive = active
    if active then
        atmHackConnection = RunService.Heartbeat:Connect(function()
            if atmHackActive then
                runAtmHack()
            end
        end)
    else
        if atmHackConnection then
            atmHackConnection:Disconnect()
            atmHackConnection = nil
        end
    end
end

-- === LOGIQUE AUTO ATM (VirtualInputManager click solver) ===
local autoATMActive = false

function toggleAutoATM(active)
    autoATMActive = active
    if not active then return end
    task.spawn(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local BlockedColor = Color3.fromRGB(74, 75, 93)
        local ClickedButtons = {}

        local function getAtmGui()
            local pg = LocalPlayer.PlayerGui
            local ok, result = pcall(function()
                return pg.ScreenGui.Center.Middle.HackingMinigames["ATM Hack"]
            end)
            return ok and result or nil
        end

        local function getCodes(AtmGui)
            local Codes = {}
            for Code in string.gmatch(AtmGui.Sequence1.Text, "([^%s]+)") do
                table.insert(Codes, Code)
            end
            return Codes
        end

        local function clickButton(Button)
            local Pos  = Button.AbsolutePosition
            local Size = Button.AbsoluteSize
            local X = Pos.X + Size.X / 2
            local Y = Pos.Y + Size.Y / 2
            VirtualInputManager:SendMouseButtonEvent(X, Y, 0, true,  game, 0)
            VirtualInputManager:SendMouseButtonEvent(X, Y, 0, false, game, 0)
        end

        while autoATMActive do
            local AtmGui = getAtmGui()
            if AtmGui and AtmGui.Sequence1.Text ~= "" then
                local Codes = getCodes(AtmGui)
                for _, Button in ipairs(AtmGui.List:GetDescendants()) do
                    if Button:IsA("ImageButton") and not ClickedButtons[Button]
                    and Button.ImageColor3 ~= BlockedColor then
                        for _, Label in ipairs(Button:GetDescendants()) do
                            if Label:IsA("TextLabel") then
                                for _, Code in ipairs(Codes) do
                                    if Label.Text == Code then
                                        clickButton(Button)
                                        ClickedButtons[Button] = true
                                        break
                                    end
                                end
                            end
                            if ClickedButtons[Button] then break end
                        end
                    end
                end
            end
            task.wait()
        end
    end)
end

-- === LOGIQUE NO DAMAGE CAR (COLLISION FOLDER STORAGE) ===
local carNoDamageActive = false
local seatData = {} -- Format: [driveSeat] = {folder = collisionClone, parent = seatParent, connections = {}}
local carNoDamageConnection = nil

function disconnectSeatAll(driveSeat)
    if seatData[driveSeat] and seatData[driveSeat].connections then
        for _, conn in ipairs(seatData[driveSeat].connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        seatData[driveSeat].connections = {}
    end
end

function restoreCollisions(driveSeat)
    disconnectSeatAll(driveSeat)
    if not seatData[driveSeat] then return end
    
    local storedFolder = seatData[driveSeat].folder
    local targetParent = seatData[driveSeat].parent
    
    if not targetParent or not targetParent.Parent then
        seatData[driveSeat] = nil
        return
    end
    
    local existing = targetParent:FindFirstChild("Collisions")
    if existing then existing:Destroy() end
    
    if storedFolder then
        storedFolder.Parent = targetParent
        seatData[driveSeat] = nil
    end
end

function startMonitoringSeat(driveSeat, humanoid, character)
    if not seatData[driveSeat] then return end
    local connections = {}
    seatData[driveSeat].connections = connections
    
    local function onExit()
        task.wait(0.1)
        restoreCollisions(driveSeat)
    end

    table.insert(connections, humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        if humanoid.SeatPart ~= driveSeat then onExit() end
    end))
    
    table.insert(connections, humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if not humanoid.Sit then onExit() end
    end))

    local backupConn
    backupConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.SeatPart ~= driveSeat or not hum.Sit then
            backupConn:Disconnect()
            onExit()
        end
    end)
    table.insert(connections, backupConn)
end

function hookPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "EnterDriver" then return end
    
    prompt.Triggered:Connect(function(player)
        if player ~= LocalPlayer or not carNoDamageActive then return end
        
        local driveSeat = prompt.Parent and prompt.Parent.Parent
        if not driveSeat or not driveSeat:IsA("Seat") or driveSeat.Name ~= "DriveSeat" then return end
        
        local seatParent = driveSeat.Parent
        local collisionsFolder = seatParent and seatParent:FindFirstChild("Collisions")
        if not collisionsFolder or not collisionsFolder:IsA("Folder") then return end
        
        if seatData[driveSeat] then disconnectSeatAll(driveSeat) end
        
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        task.delay(1, function()
            if not collisionsFolder.Parent or not carNoDamageActive then return end
            seatData[driveSeat] = {
                folder = collisionsFolder:Clone(),
                parent = seatParent,
                connections = {}
            }
            collisionsFolder:Destroy()
            startMonitoringSeat(driveSeat, humanoid, character)
        end)
    end)
end

function toggleCarNoDamage(active)
    carNoDamageActive = active
    if active then
        for _, obj in ipairs(workspace:GetDescendants()) do hookPrompt(obj) end
        carNoDamageConnection = workspace.DescendantAdded:Connect(hookPrompt)
    else
        if carNoDamageConnection then carNoDamageConnection:Disconnect() end
        for driveSeat, _ in pairs(seatData) do restoreCollisions(driveSeat) end
        seatData = {}
    end
end

-- ============================================================
-- === LOGIQUE GOLF AUTOFARM                                ===
-- ============================================================
_G.GolfFarmState = _G.GolfFarmState or { running = false, thread = nil, inputConn = nil }
local golfState = _G.GolfFarmState

function toggleGolfFarm(active)
    if active then
        if golfState.running then return end
        golfState.running = true

        -- F8 panic key
        golfState.inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if not gpe and input.KeyCode == Enum.KeyCode.F8 then
                golfState.running = false
                if golfState.inputConn then golfState.inputConn:Disconnect() golfState.inputConn = nil end
            end
        end)

        golfState.thread = task.spawn(function()
            -- Stamina/food keep-alive
            local okCore, Core = pcall(function()
                return require(LocalPlayer.PlayerScripts.Framework.Core)
            end)
            if okCore and Core then
                task.spawn(function()
                    while golfState.running do
                        task.wait(0.15)
                        if Core.stamina ~= 100 then Core.stamina = 100 end
                        if Core.food ~= 100 then Core.food = 100 end
                    end
                end)
            end

            -- Anti-AFK: click top-right corner every 60s
            task.spawn(function()
                while golfState.running do
                    task.wait(60)
                    if not golfState.running then break end
                    local Camera = workspace.CurrentCamera
                    if Camera then
                        local vs = Camera.ViewportSize
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(vs.X - 5, 5, 0, true,  game, 0)
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(vs.X - 5, 5, 0, false, game, 0)
                    end
                end
            end)

            local Event = game:GetService("ReplicatedStorage").Remote.PlayerFunc

            local function randomWait(min, max)
                task.wait(math.random(min * 100, max * 100) / 100)
            end

            local function createLobby()
                if not golfState.running then return false end
                Event:InvokeServer("miniGolf", "createLobby")
                randomWait(0.1, 0.3)
                if not golfState.running then return false end
                Event:InvokeServer("miniGolf", "setLobbyBid", { bid = 700 })
                randomWait(0.1, 0.3)
                if not golfState.running then return false end
                Event:InvokeServer("miniGolf", "setLobbyReady")
                return true
            end

            local function waitForEntity()
                local startTime = tick()
                while golfState.running and tick() - startTime < 20 do
                    local entFolder = workspace.Gameplay.Entities:WaitForChild("Content", 9e9)
                    local cactus = entFolder:FindFirstChild(LocalPlayer.Name)
                    if cactus then return cactus end
                    task.wait(0.5)
                end
                return nil
            end

            local function fireShots()
                local shotCount = math.random(3, 6)
                for i = 1, shotCount do
                    if not golfState.running then break end
                    Event:InvokeServer("miniGolf", "shot")
                    randomWait(0.1, 0.14)
                end
            end

            local function tweenToHole(cactus)
                if not golfState.running then return false end
                local touchingParts = {}
                if cactus:IsA("Model") then
                    for _, part in pairs(cactus:GetDescendants()) do
                        if part:IsA("BasePart") then
                            for _, tp in pairs(part:GetTouchingParts()) do table.insert(touchingParts, tp) end
                        end
                    end
                else
                    touchingParts = cactus:GetTouchingParts()
                end
                local mapsFolder = workspace.World.Important["Mini Golf"].Maps
                local targetColor = Color3.fromRGB(58, 58, 58)
                local currentMap
                for _, tp in pairs(touchingParts) do
                    for _, map in pairs(mapsFolder:GetChildren()) do
                        if tp:IsDescendantOf(map) then
                            for _, child in pairs(map:GetChildren()) do
                                if child:IsA("Model") and child:FindFirstChild("Part") and child.Part.Color == targetColor then
                                    currentMap = child; break
                                end
                            end
                        end
                    end
                    if currentMap then break end
                end
                if not currentMap then return false end
                local holePart = currentMap:FindFirstChild("Part")
                if not holePart then return false end
                fireShots()
                if not golfState.running then return false end
                local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local goal = { CFrame = CFrame.new(holePart.Position) }
                if cactus:IsA("Model") and cactus.PrimaryPart then
                    local t = TweenService:Create(cactus.PrimaryPart, tweenInfo, goal); t:Play(); t.Completed:Wait()
                else
                    local t = TweenService:Create(cactus, tweenInfo, goal); t:Play(); t.Completed:Wait()
                end
                return true
            end

            while golfState.running do
                if not createLobby() then break end
                local cactus = waitForEntity()
                if not cactus then continue end
                while golfState.running do
                    local ef = workspace.Gameplay.Entities:FindFirstChild("Content")
                    cactus = ef and ef:FindFirstChild(LocalPlayer.Name) or nil
                    if not cactus then break end
                    if not tweenToHole(cactus) then task.wait(1); continue end
                    randomWait(2, 3)
                end
            end
        end)
    else
        golfState.running = false
        if golfState.inputConn then golfState.inputConn:Disconnect() golfState.inputConn = nil end
        if golfState.thread then task.cancel(golfState.thread) golfState.thread = nil end
    end
end

-- ============================================================
-- === LOGIQUE INFINITE STATS (Stamina/Jump Bypass)         ===
-- ============================================================
_G.StaminaJumpConnections = _G.StaminaJumpConnections or {}
_G.StaminaJumpActive = _G.StaminaJumpActive or false

local infStatsDefaultJumpPower = 50
local infStatsDefaultJumpHeight = 7.2
local infStatsUseJumpPower = true
local infStatsCaptured = false

function infStatsClearProgress()
    local ScreenGui = LocalPlayer.PlayerGui:WaitForChild("ScreenGui", 5)
    if not ScreenGui then return end
    local BottomFrame = ScreenGui:FindFirstChild("Left") and ScreenGui.Left:FindFirstChild("Bottom")
    if BottomFrame then
        for _, name in pairs({"Food", "Stamina"}) do
            local category = BottomFrame:FindFirstChild(name)
            if category then
                local bar = category:FindFirstChild("CircularProgressBar")
                if bar then
                    local progress = bar:FindFirstChild("Progress")
                    if progress then progress:Destroy() end
                end
            end
        end
    end
end

function infStatsCaptureDefaults(humanoid)
    if infStatsCaptured then return end
    task.spawn(function()
        local attempts = 0
        while attempts < 50 do
            if humanoid.JumpPower > 0 or humanoid.JumpHeight > 0 then
                infStatsDefaultJumpPower = humanoid.JumpPower
                infStatsDefaultJumpHeight = humanoid.JumpHeight
                infStatsUseJumpPower = humanoid.UseJumpPower
                infStatsCaptured = true
                break
            end
            attempts += 1
            task.wait(0.1)
        end
    end)
end

function toggleInfStats(active)
    if active then
        _G.StaminaJumpActive = true
        infStatsCaptured = false
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then infStatsCaptureDefaults(hum) end
        end
        task.spawn(infStatsClearProgress)
        local beat = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and infStatsCaptured then
                if infStatsUseJumpPower then
                    if hum.JumpPower < infStatsDefaultJumpPower then hum.JumpPower = infStatsDefaultJumpPower end
                else
                    if hum.JumpHeight < infStatsDefaultJumpHeight then hum.JumpHeight = infStatsDefaultJumpHeight end
                end
            end
        end)
        table.insert(_G.StaminaJumpConnections, beat)
        local inputCon = UserInputService.InputBegan:Connect(function(input, processed)
            if UserInputService:GetFocusedTextBox() then return end
            if input.KeyCode == Enum.KeyCode.Space and _G.StaminaJumpActive then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        table.insert(_G.StaminaJumpConnections, inputCon)
        local charCon = LocalPlayer.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            infStatsCaptured = false
            infStatsCaptureDefaults(hum)
            task.wait(1)
            infStatsClearProgress()
        end)
        table.insert(_G.StaminaJumpConnections, charCon)
    else
        _G.StaminaJumpActive = false
        for _, connection in pairs(_G.StaminaJumpConnections) do
            if connection then connection:Disconnect() end
        end
        _G.StaminaJumpConnections = {}
    end
end

-- ============================================================
-- === LOGIQUE HOUSE ANTI-KICK                              ===
-- ============================================================
local houseAntiKickConn         = nil
local houseAntiKickSpawnConn    = nil
local houseAntiKickExitConn     = nil
local houseAntiKickExitHooked   = {}
local houseAntiKickActive       = false
local houseAntiKickGuardEnabled = false
local houseAntiKickSuppressUntil = 0

local HAKICK_KICK_THRESHOLD     = 60
local HAKICK_CHECK_RATE         = 0.1

function hakFindExitAncestor(obj)
    local cur = obj
    while cur do
        if cur.Name == "_InteractionMainExit" then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

function hakHookExitPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if not hakFindExitAncestor(prompt) then return end
    if houseAntiKickExitHooked[prompt] then return end

    houseAntiKickExitHooked[prompt] = true
    print("[HouseAntiKick] Hooked exit prompt")
    prompt.Triggered:Connect(function(player)
        if player ~= LocalPlayer or not houseAntiKickActive then return end
        print("[HouseAntiKick] Exit prompt used, pausing anti-kick for intentional exit")
        houseAntiKickGuardEnabled = false
        houseAntiKickSuppressUntil = tick() + 1.0
    end)
end

function hakHookAllExitPrompts()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            hakHookExitPrompt(obj)
        end
    end
end

function hakGetLiveHouseInterior()
    local gameplay = workspace:FindFirstChild("Gameplay")
    local propertyInside = gameplay and gameplay:FindFirstChild("PropertyInside")
    if not propertyInside then return nil end
    if not propertyInside:FindFirstChild("_InteractionMainExit") then return nil end
    if not propertyInside:FindFirstChild("CenterPosition") then return nil end
    if not propertyInside:FindFirstChild("Interior") then return nil end
    if not propertyInside:FindFirstChild("Property") then return nil end
    return propertyInside
end

function hakStartTracking(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local lastPosition = hrp.Position
    local lastCheckTime = 0

    houseAntiKickGuardEnabled = hakGetLiveHouseInterior() ~= nil

    if houseAntiKickConn then
        houseAntiKickConn:Disconnect()
        houseAntiKickConn = nil
    end

    houseAntiKickConn = RunService.Heartbeat:Connect(function()
        if not houseAntiKickActive then
            houseAntiKickConn:Disconnect()
            houseAntiKickConn = nil
            return
        end

        if not character.Parent or humanoid.Health <= 0 then
            lastPosition = nil
            return
        end

        local now = tick()
        if now - lastCheckTime < HAKICK_CHECK_RATE then return end
        lastCheckTime = now

        local currentPosition = hrp.Position
        local isInsideHouseNow = hakGetLiveHouseInterior() ~= nil

        if now < houseAntiKickSuppressUntil then
            houseAntiKickGuardEnabled = false
            lastPosition = currentPosition
            return
        end

        if isInsideHouseNow and not houseAntiKickGuardEnabled then
            houseAntiKickGuardEnabled = true
            lastPosition = currentPosition
            print("[HouseAntiKick] Entered live house, protection armed.")
            return
        end

        if not houseAntiKickGuardEnabled then
            lastPosition = currentPosition
            return
        end

        if lastPosition then
            local distance = (currentPosition - lastPosition).Magnitude
            if distance > HAKICK_KICK_THRESHOLD then
                warn(string.format("[HouseAntiKick] Suspicious movement detected! Moved %.1f studs. Teleporting back.", distance))
                hrp.CFrame = CFrame.new(lastPosition)
                return
            end
        end

        if not isInsideHouseNow then
            houseAntiKickGuardEnabled = false
            lastPosition = currentPosition
            print("[HouseAntiKick] Left live house, protection paused.")
            return
        end

        lastPosition = currentPosition
    end)
end

function toggleHouseAntiKick(active)
    houseAntiKickActive = active
    houseAntiKickGuardEnabled = false
    houseAntiKickSuppressUntil = 0

    if houseAntiKickConn then
        houseAntiKickConn:Disconnect()
        houseAntiKickConn = nil
    end
    if houseAntiKickSpawnConn then
        houseAntiKickSpawnConn:Disconnect()
        houseAntiKickSpawnConn = nil
    end
    if houseAntiKickExitConn then
        houseAntiKickExitConn:Disconnect()
        houseAntiKickExitConn = nil
    end

    houseAntiKickExitHooked = {}

    if not active then
        print("[HouseAntiKick] DISABLED.")
        return
    end

    print("[HouseAntiKick] ENABLED. Max jump distance: " .. HAKICK_KICK_THRESHOLD .. " studs.")

    hakHookAllExitPrompts()
    houseAntiKickExitConn = workspace.DescendantAdded:Connect(function(obj)
        if not houseAntiKickActive then return end
        if obj:IsA("ProximityPrompt") then
            hakHookExitPrompt(obj)
        end
    end)

    if LocalPlayer.Character then
        hakStartTracking(LocalPlayer.Character)
    end

    houseAntiKickSpawnConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if not houseAntiKickActive then
            houseAntiKickSpawnConn:Disconnect()
            houseAntiKickSpawnConn = nil
            return
        end
        hakStartTracking(character)
    end)
end

-- ============================================================
-- === LOGIQUE ANTI-ARREST (Dodge handcuffs)                ===
-- ============================================================
local antiArrestConn = nil

local antiArrestActive = false

function toggleAntiArrest(active)
    antiArrestActive = active
    if antiArrestConn then antiArrestConn:Disconnect() antiArrestConn = nil end

    if not active then return end

    antiArrestConn = { Disconnect = function() antiArrestActive = false end }
    task.spawn(function()
        while antiArrestActive do
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer then continue end
                    local plrChar = plr.Character
                    if not plrChar then continue end

                    local plrHRP = plrChar:FindFirstChild("HumanoidRootPart")
                    if not plrHRP then continue end

                    -- Quick distance pre-check before scanning tools
                    if (plrHRP.Position - hrp.Position).Magnitude > 8 then continue end

                    for _, obj in ipairs(plrChar:GetChildren()) do
                        if obj:IsA("Tool") and obj.Name == "PD Handcuffs" then
                            local awayDir = hrp.Position - plrHRP.Position
                            awayDir = Vector3.new(awayDir.X, 0, awayDir.Z)
                            if awayDir.Magnitude < 0.01 then awayDir = Vector3.new(1, 0, 0) end
                            local rawTarget = hrp.Position + awayDir.Unit * 18

                            -- Raycast downward to find the actual surface at the target XZ,
                            -- excluding our own character so we don't land inside ourselves
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local myChar = LocalPlayer.Character
                            rayParams.FilterDescendantsInstances = myChar and {myChar} or {}

                            local rayResult = workspace:Raycast(
                                rawTarget + Vector3.new(0, 500, 0),
                                Vector3.new(0, -1000, 0),
                                rayParams
                            )
                            local landY = rayResult
                                and (rayResult.Position.Y + 3)
                                or  rawTarget.Y
                            hrp.CFrame = CFrame.new(rawTarget.X, landY, rawTarget.Z)
                            break
                        end
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

-- ============================================================
-- === LOGIQUE EXPAND HANDCUFF RANGE                        ===
-- ============================================================
local expandCuffsActive = false
local expandCuffsConn   = nil
-- key = prompt, value = {enforcerConn, origRange, origHold}
local expandCuffsPatched = {}

local EXPAND_CUFFS_RANGE = 29
local EXPAND_CUFFS_HOLD  = 0.1

-- Modify the original prompt's properties directly — don't destroy it.
-- This keeps the game's server-side arrest logic intact.
function expandCuffsApply(prompt)
    if expandCuffsPatched[prompt] then return end

    local origRange = prompt.MaxActivationDistance
    local origHold  = prompt.HoldDuration

    prompt.MaxActivationDistance = EXPAND_CUFFS_RANGE
    prompt.HoldDuration          = EXPAND_CUFFS_HOLD
    prompt.RequiresLineOfSight   = false

    -- Enforce our values whenever the game tries to reset them
    local enforcerConn = prompt:GetPropertyChangedSignal("MaxActivationDistance"):Connect(function()
        if expandCuffsActive and prompt.MaxActivationDistance ~= EXPAND_CUFFS_RANGE then
            prompt.MaxActivationDistance = EXPAND_CUFFS_RANGE
        end
    end)

    expandCuffsPatched[prompt] = {
        enforcerConn = enforcerConn,
        origRange    = origRange,
        origHold     = origHold,
    }
end

function expandCuffsRestore(prompt)
    local entry = expandCuffsPatched[prompt]
    if not entry then return end
    if entry.enforcerConn then entry.enforcerConn:Disconnect() end
    pcall(function()
        prompt.MaxActivationDistance = entry.origRange
        prompt.HoldDuration          = entry.origHold
    end)
    expandCuffsPatched[prompt] = nil
end

function toggleExpandCuffs(active)
    expandCuffsActive = active
    if expandCuffsConn then expandCuffsConn:Disconnect() expandCuffsConn = nil end

    if not active then
        for prompt in pairs(expandCuffsPatched) do
            expandCuffsRestore(prompt)
        end
        expandCuffsPatched = {}
        return
    end

    -- Intercept the moment the game adds the Handcuffs prompt and modify it
    expandCuffsConn = workspace.DescendantAdded:Connect(function(obj)
        if not expandCuffsActive then return end
        if not (obj:IsA("ProximityPrompt") and obj.Name == "Handcuffs") then return end
        local hrp = obj.Parent
        if not (hrp and hrp:IsA("BasePart") and hrp.Name == "HumanoidRootPart") then return end
        -- Only players, not NPCs
        local isPlayer = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") == hrp then
                isPlayer = true; break
            end
        end
        if not isPlayer then return end
        -- Use task.defer so the prompt is fully initialised before we touch it
        task.defer(function()
            if obj and obj.Parent then
                expandCuffsApply(obj)
            end
        end)
    end)

    -- Also patch any prompts already present right now
    for _, plr in ipairs(Players:GetPlayers()) do
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, c in ipairs(hrp:GetChildren()) do
                if c:IsA("ProximityPrompt") and c.Name == "Handcuffs" then
                    expandCuffsApply(c)
                end
            end
        end
    end

    -- Clean up patched prompts that have been removed from the game
    task.spawn(function()
        while expandCuffsActive do
            for prompt in pairs(expandCuffsPatched) do
                if not prompt.Parent then
                    expandCuffsPatched[prompt] = nil
                end
            end
            task.wait(5)
        end
    end)
end

-- ============================================================
-- === LOGIQUE AVOID DEATH (Safety teleport underground)    ===
-- ============================================================
-- Always reset the state table fresh so stale _G data can't block us
_G.SafetySystemActive = { Connections = {}, UI = nil, Active = false }
local SafetyState = _G.SafetySystemActive

local safetyIsInSafetyMode      = false
local safetyEspWasAutoEnabled    = false
local safetyWarningLabel         = nil   -- single status label (reused for prompt + status)
local safetyFreezeConn           = nil
local safetyFreezePos            = nil

local SAFETY_HEALTH_THRESHOLD    = 30
local SAFETY_RESURFACE_THRESH    = 80
SAFETY_RETURN_KEY          = Enum.KeyCode.V
local SEAT_OCCUPY_RADIUS         = 5
local SPEC_FLY_SPEED             = 40

-- The 7 known bed positions inside the hospital
local HOSPITAL_PROMPT_POSITIONS = {
    Vector3.new(3960.10205078125,  -337.0257873535156, -178.8904266357422),
    Vector3.new(3974.109375,       -337.0257873535156, -240.404052734375),
    Vector3.new(3978.75244140625,  -337.0257873535156, -260.7945556640625),
    Vector3.new(3935.88330078125,  -337.0257873535156, -245.35824584960938),
    Vector3.new(3914.94091796875,  -337.0257873535156, -250.12698364257812),
    Vector3.new(3964.7451171875,   -337.0257873535156, -199.2809600830078),
    Vector3.new(3970.665283203125, -337.0257873535156, -225.28042602539062),
}

-- Spectator camera state
local safetyCamPart       = nil
local safetySpecFlyPos    = Vector3.zero
local safetySpecFlyConn   = nil
local safetySpecInputConn = nil
local safetySpecEndConn   = nil
local safetySpecKeys      = { forward=false, back=false, left=false, right=false, up=false, down=false }

function safetyPickPromptPosition()
    local candidates = {}

    for _, pos in ipairs(HOSPITAL_PROMPT_POSITIONS) do
        local occupied = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hrp and (hrp.Position - pos).Magnitude < SEAT_OCCUPY_RADIUS then
                    occupied = true
                    break
                end
                if hum and hum.SeatPart and hum.SeatPart:IsA("BasePart") and (hum.SeatPart.Position - pos).Magnitude < SEAT_OCCUPY_RADIUS then
                    occupied = true
                    break
                end
            end
        end
        if not occupied then
            table.insert(candidates, pos)
        end
    end

    if #candidates == 0 then
        candidates = HOSPITAL_PROMPT_POSITIONS
    end

    return candidates[math.random(#candidates)]
end

-- Stop the character-freeze Heartbeat
function safetyStopFreeze()
    if safetyFreezeConn then safetyFreezeConn:Disconnect(); safetyFreezeConn = nil end
    safetyFreezePos = nil
end

-- Pin HRP to a position every frame so spectator WASD doesn't walk the character away
function safetyStartFreeze(pinPos)
    safetyFreezePos = pinPos
    safetyFreezeConn = RunService.Heartbeat:Connect(function()
        if not safetyIsInSafetyMode then safetyStopFreeze() return end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if (hrp.Position - safetyFreezePos).Magnitude > 1 then
            hrp.CFrame = CFrame.new(safetyFreezePos) * hrp.CFrame.Rotation
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- Stop spectator and restore camera to the character's humanoid
function safetyStopSpectator()
    if safetySpecFlyConn   then safetySpecFlyConn:Disconnect();   safetySpecFlyConn   = nil end
    if safetySpecInputConn then safetySpecInputConn:Disconnect(); safetySpecInputConn = nil end
    if safetySpecEndConn   then safetySpecEndConn:Disconnect();   safetySpecEndConn   = nil end
    for k in pairs(safetySpecKeys) do safetySpecKeys[k] = false end
    if safetyCamPart then safetyCamPart:Destroy(); safetyCamPart = nil end
    local cam = workspace.CurrentCamera
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then cam.CameraSubject = hum; cam.CameraType = Enum.CameraType.Custom end
end

-- Spawn anchor, point camera at it, attach WASD fly (moves camera only, not the character)
function safetyStartSpectator(originCFrame)
    local anchor = Instance.new("Part")
    anchor.Size         = Vector3.new(0.1, 0.1, 0.1)
    anchor.Anchored     = true
    anchor.CanCollide   = false
    anchor.CanTouch     = false
    anchor.Transparency = 1
    anchor.CFrame       = originCFrame
    anchor.Parent       = workspace
    safetyCamPart    = anchor
    safetySpecFlyPos = originCFrame.Position

    local cam = workspace.CurrentCamera
    cam.CameraType    = Enum.CameraType.Custom
    cam.CameraSubject = anchor

    safetySpecInputConn = UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.W           then safetySpecKeys.forward = true  end
        if inp.KeyCode == Enum.KeyCode.S           then safetySpecKeys.back    = true  end
        if inp.KeyCode == Enum.KeyCode.A           then safetySpecKeys.left    = true  end
        if inp.KeyCode == Enum.KeyCode.D           then safetySpecKeys.right   = true  end
        if inp.KeyCode == Enum.KeyCode.Space       then safetySpecKeys.up      = true  end
        if inp.KeyCode == Enum.KeyCode.LeftControl then safetySpecKeys.down    = true  end
    end)
    safetySpecEndConn = UserInputService.InputEnded:Connect(function(inp)
        if inp.KeyCode == Enum.KeyCode.W           then safetySpecKeys.forward = false end
        if inp.KeyCode == Enum.KeyCode.S           then safetySpecKeys.back    = false end
        if inp.KeyCode == Enum.KeyCode.A           then safetySpecKeys.left    = false end
        if inp.KeyCode == Enum.KeyCode.D           then safetySpecKeys.right   = false end
        if inp.KeyCode == Enum.KeyCode.Space       then safetySpecKeys.up      = false end
        if inp.KeyCode == Enum.KeyCode.LeftControl then safetySpecKeys.down    = false end
    end)
    safetySpecFlyConn = RunService.Heartbeat:Connect(function(dt)
        if not safetyCamPart or not safetyCamPart.Parent then return end
        local cf    = cam.CFrame
        local look  = cf.LookVector
        local right = cf.RightVector
        local dir   = Vector3.zero
        if safetySpecKeys.forward then dir = dir + look               end
        if safetySpecKeys.back    then dir = dir - look               end
        if safetySpecKeys.right   then dir = dir + right              end
        if safetySpecKeys.left    then dir = dir - right              end
        if safetySpecKeys.up      then dir = dir + Vector3.new(0,1,0) end
        if safetySpecKeys.down    then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then
            safetySpecFlyPos = safetySpecFlyPos + dir.Unit * SPEC_FLY_SPEED * dt
        end
        safetyCamPart.CFrame = CFrame.new(safetySpecFlyPos)
    end)
end

-- Helper: set the main label text and colour
function safetySetLabel(text, r, g, b)
    if not safetyWarningLabel then return end
    safetyWarningLabel.Text       = text
    safetyWarningLabel.TextColor3 = Color3.fromRGB(r, g, b)
    safetyWarningLabel.Visible    = true
end
function safetyHideLabel()
    if safetyWarningLabel then safetyWarningLabel.Visible = false end
end
-- Main healing trigger
function safetyGoHeal()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or safetyIsInSafetyMode then return end

    safetyEspWasAutoEnabled = _G.safetyGetESPState and not _G.safetyGetESPState()
    if safetyEspWasAutoEnabled and _G.safetyToggleESP then _G.safetyToggleESP() end

    safetyIsInSafetyMode = true

    -- Spectator camera starts from the player's current world position
    safetyStartSpectator(hrp.CFrame)

    -- Show the "hold E" instruction for 4 seconds, then switch to the heal status text
    safetySetLabel("Look around for a proximity prompt, hold E on it to start healing.", 220, 220, 220)
    task.delay(4, function()
        if safetyIsInSafetyMode then
            safetySetLabel(getSafetyHealLabel(), 140, 220, 140)
        end
    end)

    task.spawn(function()
        local targetPos = safetyPickPromptPosition()
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        safetyStartFreeze(targetPos)
    end)
end

-- Resurface: teleport to spectator camera position, stand character up properly
function safetyGoBack()
    if not safetyIsInSafetyMode then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    if hum and hum.Health < SAFETY_RESURFACE_THRESH then
        safetySetLabel("HEALTH TOO LOW  —  Need 80+ HP to resurface.  Keep healing...", 255, 100, 50)
        task.delay(3, function()
            if safetyIsInSafetyMode then safetySetLabel(getSafetyHealLabel(), 140, 220, 140) end
        end)
        return
    end

    -- Capture spectator camera position BEFORE stopping it
    local returnPos = safetyCamPart and safetyCamPart.Position or nil

    safetyStopFreeze()

    -- Eject from seat cleanly: clear PlatformStand, force GettingUp, jump
    if hum then
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        task.wait(0.1)
        hum.Jump = true
    end
    task.wait(0.2)

    -- Teleport to spectator camera's current position
    if hrp and returnPos then
        hrp.CFrame = CFrame.new(returnPos)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    -- Final GettingUp nudge to make sure the character stands
    if hum then
        task.delay(0.05, function()
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end)
    end

    safetyStopSpectator()
    safetyHideLabel()

    if safetyEspWasAutoEnabled and _G.safetyToggleESP then
        _G.safetyToggleESP()
        safetyEspWasAutoEnabled = false
    end
    safetyIsInSafetyMode = false
end

function toggleAvoidDeath(active)
    if active then
        SafetyState.Active = true
        if not SafetyState.UI then
            local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
            sg.Name         = "SafeZoneUI"
            sg.ResetOnSpawn = false
            SafetyState.UI  = sg

            -- Single label used for both the prompt and the status line
            local lbl = Instance.new("TextLabel", sg)
            lbl.Name                    = "StatusLabel"
            lbl.Size                    = UDim2.new(0, 560, 0, 44)
            lbl.Position                = UDim2.new(0.5, -280, 0, 32)
            lbl.BackgroundColor3        = Color3.fromRGB(12, 12, 16)
            lbl.BackgroundTransparency  = 0.35
            lbl.Text                    = ""
            lbl.TextColor3              = Color3.fromRGB(220, 220, 220)
            lbl.Font                    = Enum.Font.Gotham
            lbl.TextSize                = 15
            lbl.TextWrapped             = true
            lbl.Visible                 = false
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
            safetyWarningLabel = lbl
        end

        local monitorConn = RunService.Heartbeat:Connect(function()
            if not SafetyState.Active or safetyIsInSafetyMode then return end
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if hum.Health > 0 and hum.Health <= SAFETY_HEALTH_THRESHOLD then
                safetyGoHeal()
            end
        end)
        table.insert(SafetyState.Connections, monitorConn)

        table.insert(SafetyState.Connections, LocalPlayer.CharacterAdded:Connect(function()
            safetyIsInSafetyMode = false
            safetyStopFreeze()
            safetyStopSpectator()
            safetyHideLabel()
        end))

        table.insert(SafetyState.Connections, UserInputService.InputBegan:Connect(function(i, p)
            if not p and i.KeyCode == SAFETY_RETURN_KEY then safetyGoBack() end
        end))
    else
        SafetyState.Active = false
        safetyIsInSafetyMode = false
        safetyStopFreeze()
        safetyStopSpectator()
        for _, conn in pairs(SafetyState.Connections) do if conn then conn:Disconnect() end end
        SafetyState.Connections = {}
        if SafetyState.UI then SafetyState.UI:Destroy() SafetyState.UI = nil safetyWarningLabel = nil end
    end
end
-- ============================================================
-- === LOGIQUE CHANGE OUTFIT WHILE WANTED (AVS Teleport)    ===
-- ============================================================
_G.ChangeAVSState = _G.ChangeAVSState or { isTeleported = false, savedLocation = nil, connection = nil, gui = nil }
local avsState = _G.ChangeAVSState

AVS_TELEPORT_KEY = Keybinds.avsTeleport or Enum.KeyCode.Y
local AVS_TARGET_POS   = Vector3.new(3600.28, -336.05, -438.14)

function toggleChangeAVS(active)
    if active then
        if avsState.connection then return end
        -- One-time instructions panel
        if not avsState.gui then
            local mainGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
            mainGui.Name = "ChangeAVSGui"
            mainGui.ResetOnSpawn = false
            avsState.gui = mainGui

            -- Instructions frame (shown once on enable)
            local instrFrame = Instance.new("Frame", mainGui)
            instrFrame.Name = "InstrFrame"
            instrFrame.Size = UDim2.new(0, 420, 0, 110)
            instrFrame.Position = UDim2.new(0.5, -210, 0.5, -55)
            instrFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
            instrFrame.BorderSizePixel = 0
            Instance.new("UICorner", instrFrame).CornerRadius = UDim.new(0, 10)

            local instrBorder = Instance.new("UIStroke", instrFrame)
            instrBorder.Color = Color3.fromRGB(140, 60, 255)
            instrBorder.Thickness = 1.5

            local instrText = Instance.new("TextLabel", instrFrame)
            instrText.Size = UDim2.new(1, -20, 0, 65)
            instrText.Position = UDim2.new(0, 10, 0, 8)
            instrText.BackgroundTransparency = 1
            instrText.Text = getAVSInstructionText()
            instrText.TextColor3 = Color3.fromRGB(220, 220, 220)
            instrText.Font = Enum.Font.Gotham
            instrText.TextSize = 14
            instrText.TextXAlignment = Enum.TextXAlignment.Left
            instrText.TextWrapped = true

            local closeBtn = Instance.new("TextButton", instrFrame)
            closeBtn.Size = UDim2.new(0, 120, 0, 28)
            closeBtn.Position = UDim2.new(0.5, -60, 1, -36)
            closeBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
            closeBtn.Text = "GOT IT"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 13
            closeBtn.AutoButtonColor = false
            Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
            closeBtn.MouseButton1Click:Connect(function() instrFrame:Destroy() end)

            -- Teleported status label (hidden by default)
            local statusLabel = Instance.new("TextLabel", mainGui)
            statusLabel.Name = "StatusLabel"
            statusLabel.Size = UDim2.new(0, 340, 0, 40)
            statusLabel.Position = UDim2.new(0.5, -170, 0.12, 0)
            statusLabel.BackgroundTransparency = 0.45
            statusLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
            statusLabel.TextColor3 = Color3.fromRGB(140, 60, 255)
            statusLabel.Text = getAVSStatusText()
            statusLabel.Font = Enum.Font.GothamBold
            statusLabel.TextSize = 16
            statusLabel.Visible = false
            Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", statusLabel).Color = Color3.fromRGB(140, 60, 255)
        end

        avsState.connection = UserInputService.InputBegan:Connect(function(input, processed)
            if input.KeyCode == AVS_TELEPORT_KEY and not processed then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local label = avsState.gui and avsState.gui:FindFirstChild("StatusLabel")
                if not avsState.isTeleported then
                    avsState.savedLocation = hrp.CFrame
                    hrp.CFrame = CFrame.new(AVS_TARGET_POS)
                    avsState.isTeleported = true
                    if label then label.Visible = true end
                else
                    if avsState.savedLocation then hrp.CFrame = avsState.savedLocation end
                    avsState.isTeleported = false
                    if label then label.Visible = false end
                end
            end
        end)
    else
        if avsState.connection then avsState.connection:Disconnect() avsState.connection = nil end
        if avsState.gui then avsState.gui:Destroy() avsState.gui = nil end
        avsState.isTeleported = false
        avsState.savedLocation = nil
    end
end

local ugcEmotesLoaded = false
function runUGCEmotes()
    if ugcEmotesLoaded then return end
    ugcEmotesLoaded = true
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Rootleak/roblox/refs/heads/main/main.lua"))()
    showActionHint("You can add/remove emotes by executing this in Catalog Avatar Creator and playing whatever emote you want to add!", 8)
end

-- === LOGIQUE AVATAR REFRESH (SANS RESPAWN) ===
function runAvatarRefresh()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end
    
    -- Téléportation vers le haut pour forcer le refresh
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 255, 0)
    
    -- Si le système Anti-Arrest principal est actif
    if _G.NoclipDeathSystemActive then
        _G.TempNoclipOverride = true -- Désactive le TP aléatoire de 60 studs une seule fois
        return
    end
    
    -- Sinon, on active le système temporaire
    _G.NoclipDeathSystemActive = true
    _G.TempNoclipOnce = true
    _G.TempNoclipOverride = true
    
    local function noclipCharacter(char)
        task.spawn(function()
            while char and char.Parent and _G.NoclipDeathSystemActive do
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                task.wait(0.1)
            end
        end)
    end
    
    local function monitorCharacter(char)
        local humanoid = char:WaitForChild("Humanoid")
        task.spawn(function()
            while char and char.Parent and _G.NoclipDeathSystemActive do
                if humanoid.Health <= 0 then
                    noclipCharacter(char)
                    player.CharacterAdded:Wait()
                    
                    if _G.TempNoclipOnce then
                        _G.NoclipDeathSystemActive = false
                        _G.TempNoclipOnce = nil
                        _G.TempNoclipOverride = nil
                        break
                    end
                end
                task.wait(0.1)
            end
        end)
    end
    
    monitorCharacter(character)
end

-- === LOGIQUE FE ZOMBIE ===
function runZombieScript()
    -- Configuration des animations globales (nécessaire pour le loadstring)
    _G.idle1 = "3489171152"
    _G.idle2 = "3489171152"
    _G.walk = "3489174223" 
    _G.run = "3489173414"
    _G.jump = "616161997"
    _G.climb = "616156119"
    _G.fall = "616157476"

    -- Chargement du moteur d'animation
    loadstring(game:HttpGet("https://pastebin.com/raw/E6uL974H"))()
    
    task.wait(1.5)

    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer

    -- Fonction de lecture d'animation
    _G.PlayAnim = function(id, time, speed)
        pcall(function()
            local char = plr.Character
            if not char then return end
            char.Animate.Disabled = false
            local hum = char:FindFirstChildOfClass("Humanoid")
            local animtrack = hum:GetPlayingAnimationTracks()
            for _, track in pairs(animtrack) do
                track:Stop()
            end
            char.Animate.Disabled = true
            local Anim = Instance.new("Animation")
            Anim.AnimationId = "rbxassetid://"..id
            local loadanim = hum:LoadAnimation(Anim)
            loadanim:Play()
            loadanim.TimePosition = time
            loadanim:AdjustSpeed(speed)
            loadanim.Stopped:Connect(function()
                char.Animate.Disabled = false
            end)
        end)
    end

    -- Création du Tool d'attaque
    local AttackTool = Instance.new("Tool")
    AttackTool.Name = "Zombie Attack"
    AttackTool.RequiresHandle = false
    AttackTool.Parent = plr.Backpack

    AttackTool.Activated:Connect(function()
        _G.PlayAnim(3489169607, 0, 0.9)
        task.wait(1)
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, v in next, hum:GetPlayingAnimationTracks() do
                v:Stop()
            end
        end
    end)
    
    print("FE Zombie Loaded !")
end

-- === LOGIQUE INF AMMO ===
local infAmmoActive = false
local trackedAmmo = {}
local ammoHeartbeat = nil
local ammoConnections = {}

function processInfAmmoTool(tool)
    if not tool:IsA("Tool") then return end

    local config = tool:FindFirstChild("Config")
    if not config then return end

    local ammo = config:FindFirstChild("Ammo")
    if not ammo or not ammo:IsA("ValueBase") then return end

    -- Supprimer la restriction d'équipe
    local whitelistFolder = tool:FindFirstChild("_TeamWhitelisted")
    if whitelistFolder then
        whitelistFolder:Destroy()
    end

    if trackedAmmo[ammo] then return end
    trackedAmmo[ammo] = true

    -- Verrouillage des munitions
    ammo.Value = 999
    ammo.Changed:Connect(function()
        if infAmmoActive and ammo.Value ~= 999 then
            ammo.Value = 999
        end
    end)
end

function toggleInfAmmo(active)
    infAmmoActive = active
    if active then
        local function setupAmmoForChar()
            -- Scan backpack
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                processInfAmmoTool(item)
            end
            -- Watch for new tools picked up
            local connection = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
                task.wait(0.1)
                if infAmmoActive then processInfAmmoTool(child) end
            end)
            -- Also watch character for equipped tool
            local char = LocalPlayer.Character
            if char then
                local charConn = char.ChildAdded:Connect(function(child)
                    task.wait(0.1)
                    if infAmmoActive then processInfAmmoTool(child) end
                end)
                table.insert(ammoConnections, charConn)
            end
            table.insert(ammoConnections, connection)
        end

        setupAmmoForChar()

        -- Re-apply on respawn
        local respawnConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if infAmmoActive then
                trackedAmmo = {}
                setupAmmoForChar()
            end
        end)
        table.insert(ammoConnections, respawnConn)

        -- Heartbeat enforcer
        ammoHeartbeat = RunService.Heartbeat:Connect(function()
            if infAmmoActive then
                for ammo in pairs(trackedAmmo) do
                    if ammo.Parent and ammo.Value ~= 999 then
                        ammo.Value = 999
                    end
                end
            end
        end)
    else
        if ammoHeartbeat then
            ammoHeartbeat:Disconnect()
            ammoHeartbeat = nil
        end
        for _, c in ipairs(ammoConnections) do pcall(function() c:Disconnect() end) end
        ammoConnections = {}
        trackedAmmo = {}
        infAmmoActive = false
    end
end

-- === LOGIQUE BYPASS ALL RESTRICTIONS (MISE À JOUR) ===
local TARGET_AMMO = 999
local DELETE_NAMES = {_TrafficLightArea = true, _SpeedCameraArea = true, _TeamWhitelisted = true, _RestrictedArea = true}
local TARGET_FOLDERS = {"Entities", "Streetlights", "Props", "Fire Hydrants"}
local bypassConnections = {}
local bypassTrackedAmmo = {}

function processBypassTool(tool)
    if not tool:IsA("Tool") then return end
    local config = tool:FindFirstChild("Config")
    local ammo = config and config:FindFirstChild("Ammo")
    if ammo and ammo:IsA("ValueBase") then
        if not bypassTrackedAmmo[ammo] then
            bypassTrackedAmmo[ammo] = true
            ammo.Value = TARGET_AMMO
            table.insert(bypassConnections, ammo.Changed:Connect(function() 
                if _G.BypassActive then ammo.Value = TARGET_AMMO end 
            end))
        end
    end
end

_G.BypassActive = false

function toggleBypassAll(enabled)
    _G.BypassActive = enabled
    
    -- Nettoyage des anciennes connexions si on désactive
    for _, conn in ipairs(bypassConnections) do conn:Disconnect() end
    bypassConnections = {}
    
    if not enabled then 
        warn("[Bypass] Désactivé")
        return 
    end

    warn("[Bypass] Activé - Midnight Violet Mode")

    -- 1. Suppression & No-Collision (Streaming-Safe)
    local function handleObj(obj)
        if not _G.BypassActive then return end
        -- Suppression zones radars/police
        if DELETE_NAMES[obj.Name] then
            task.defer(function() if obj and obj.Parent then obj:Destroy() end end)
        end
        -- No collision sur les dossiers cibles
        if obj:IsA("BasePart") then
            local parentName = obj.Parent and obj.Parent.Name
            if table.find(TARGET_FOLDERS, parentName) then
                obj.CanTouch = false
                obj.CanCollide = false
            end
        end
    end

    -- Scan initial
    for _, obj in ipairs(workspace:GetDescendants()) do handleObj(obj) end
    -- Surveillance nouveaux objets
    table.insert(bypassConnections, workspace.DescendantAdded:Connect(handleObj))

    -- 2. Munitions illimitées
    local backpack = LocalPlayer:WaitForChild("Backpack")
    for _, item in ipairs(backpack:GetChildren()) do processBypassTool(item) end
    table.insert(bypassConnections, backpack.ChildAdded:Connect(function(child)
        task.wait(0.1)
        processBypassTool(child)
    end))

    -- Re-apply ammo on character reset
    table.insert(bypassConnections, LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if not _G.BypassActive then return end
        bypassTrackedAmmo = {}
        for _, item in ipairs(backpack:GetChildren()) do processBypassTool(item) end
        -- also watch equipped tool on new character
        table.insert(bypassConnections, newChar.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if _G.BypassActive then processBypassTool(child) end
        end))
    end))
    
    -- Heartbeat pour forcer les munitions
    table.insert(bypassConnections, game:GetService("RunService").Heartbeat:Connect(function()
        if _G.BypassActive then
            for ammo in pairs(bypassTrackedAmmo) do
                if ammo.Parent and ammo.Value ~= TARGET_AMMO then ammo.Value = TARGET_AMMO end
            end
        end
    end))
end

-- === LOGIQUE REMOVE REDLIGHT / SPEED CAMERA ===
function toggleRedLightSpeed(active)
    if not active then return end

    local worldFolder = workspace:FindFirstChild("World")
    if not worldFolder then
        warn("World folder not found in Workspace.")
        return
    end

    for _, object in ipairs(worldFolder:GetDescendants()) do
        if object.Name == "_TrafficLightArea" or object.Name == "_SpeedCameraArea" then
            object:Destroy()
        end
    end
end

-- === LOGIQUE INSTANT INTERACT ===
_G.InstantInteractState = _G.InstantInteractState or {
    active    = false,
    originals = {},
    conn      = nil
}
local iiState = _G.InstantInteractState

function iiApply(prompt)
    if not iiState.originals[prompt] then
        iiState.originals[prompt] = prompt.HoldDuration
    end
    prompt.HoldDuration = 0
end

function iiRestore(prompt)
    if iiState.originals[prompt] then
        pcall(function() prompt.HoldDuration = iiState.originals[prompt] end)
        iiState.originals[prompt] = nil
    end
end

function toggleInstantInteract(active)
    iiState.active = active
    if active then
        -- Scan workspace only (not all of game)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then iiApply(obj) end
        end
        -- Watch workspace only for new prompts
        iiState.conn = workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("ProximityPrompt") then iiApply(obj) end
        end)
    else
        if iiState.conn then iiState.conn:Disconnect() iiState.conn = nil end
        for prompt in pairs(iiState.originals) do iiRestore(prompt) end
        iiState.originals = {}
    end
end

-- === LOGIQUE INF ZOOM-OUT ===
local originalMinZoom = nil
local originalMaxZoom = nil

function toggleInfZoom(active)
    if active then
        -- Sauvegarder les valeurs originales
        originalMinZoom = LocalPlayer.CameraMinZoomDistance
        originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
        
        -- Appliquer le zoom infini
        LocalPlayer.CameraMinZoomDistance = 0
        LocalPlayer.CameraMaxZoomDistance = 100000
    else
        -- Restaurer les valeurs originales
        if originalMinZoom and originalMaxZoom then
            LocalPlayer.CameraMinZoomDistance = originalMinZoom
            LocalPlayer.CameraMaxZoomDistance = originalMaxZoom
        end
    end
end

-- === LOGIQUE ESP TEAM ONLY ===
local TARGET_TEAM_NAME = "Police" -- Peut être changé via settings
local MAX_SIZE_TEAM = 105
local MIN_SIZE_TEAM = 45
local ESP_COLOR_TEAM = Color3.fromRGB(60, 120, 255) -- BLUE

-- Configuration ESP Team (peut être modifiée par l'UI)
local ESP_TEAM_CONFIG = {
    AlwaysOnTop = true,
    OutlineTransparency = 0.4,
    FillTransparency = 0.45,
    ShowTextLabels = true
}

function isPolice(player)
    return player.Team and player.Team.Name == TARGET_TEAM_NAME
end

function removeTeamESP(player)
    local d = stateTeam.objects[player]
    if not d then return end
    if d.highlights then 
        for _, hl in ipairs(d.highlights) do 
            hl:Destroy() 
        end 
    end
    if d.billboard then d.billboard:Destroy() end
    if d.conn then d.conn:Disconnect() end
    stateTeam.objects[player] = nil
end

function clearTeamESP()
    for p in pairs(stateTeam.objects) do
        removeTeamESP(p)
    end
    for _, c in ipairs(stateTeam.connections) do c:Disconnect() end
    stateTeam.connections = {}
    stateTeam.enabled = false
end

function createTeamESP(player)
    if player == LocalPlayer then return end
    if stateTeam.objects[player] then return end
    if not isPolice(player) then return end
    if not player.Character then return end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Create multiple Highlights for parts except Head
    local highlights = {}
    for _, part in ipairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "Head" then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = part
            highlight.FillColor = ESP_COLOR_TEAM
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = ESP_TEAM_CONFIG.FillTransparency
            highlight.OutlineTransparency = ESP_TEAM_CONFIG.OutlineTransparency
            highlight.DepthMode = ESP_TEAM_CONFIG.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            highlight.Parent = part
            table.insert(highlights, highlight)
        end
    end

    local billboard = nil
    local conn = nil
    
    if ESP_TEAM_CONFIG.ShowTextLabels then
        -- Billboard
        billboard = Instance.new("BillboardGui")
        billboard.Adornee = root
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.Size = UDim2.fromOffset(80, 40)
        billboard.Parent = root

        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.fromScale(1, 0.65)
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = ESP_COLOR_TEAM
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.GothamBlack
        nameLabel.TextSize = 18
        nameLabel.Parent = billboard

        -- Distance
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Position = UDim2.fromScale(0, 0.62)
        distanceLabel.Size = UDim2.fromScale(1, 0.38)
        distanceLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        distanceLabel.TextStrokeTransparency = 0.2
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = 12
        distanceLabel.Parent = billboard

        conn = RunService.RenderStepped:Connect(function()
            if not stateTeam.enabled then return end
            if not player.Character or not isPolice(player) then
                removeTeamESP(player)
                return
            end

            local localChar = LocalPlayer.Character
            if not localChar then return end
            local localRoot = localChar:FindFirstChild("HumanoidRootPart")
            if not localRoot then return end

            local distance = (localRoot.Position - root.Position).Magnitude
            distanceLabel.Text = math.floor(distance) .. " studs"

            local size = math.clamp(distance * 0.25, MIN_SIZE_TEAM, MAX_SIZE_TEAM)
            billboard.Size = UDim2.fromOffset(size, size * 0.55)
        end)
    end

    stateTeam.objects[player] = { highlights = highlights, billboard = billboard, conn = conn }
end

-- Fonction pour rafraîchir l'ESP avec les nouvelles options
function refreshESPTeam()
    if not stateTeam.enabled then return end
    
    -- Clear all current ESP
    for _, d in pairs(stateTeam.objects) do
        if d.highlights then 
            for _, hl in ipairs(d.highlights) do 
                hl:Destroy() 
            end 
        end
        if d.billboard then d.billboard:Destroy() end
        if d.conn then d.conn:Disconnect() end
    end
    stateTeam.objects = {}
    
    -- Recreate with new settings
    for _, p in ipairs(Players:GetPlayers()) do
        createTeamESP(p)
    end
end

function toggleESPTeam()
    if stateTeam.enabled then
        clearTeamESP()
        return
    end

    stateTeam.enabled = true

    -- Player handling
    for _, player in ipairs(Players:GetPlayers()) do
        createTeamESP(player)

        table.insert(stateTeam.connections,
            player.CharacterAdded:Connect(function()
                task.wait(0.4)
                if stateTeam.enabled then
                    createTeamESP(player)
                end
            end)
        )

        table.insert(stateTeam.connections,
            player:GetPropertyChangedSignal("Team"):Connect(function()
                if not stateTeam.enabled then return end
                if isPolice(player) then
                    createTeamESP(player)
                else
                    removeTeamESP(player)
                end
            end)
        )
    end

    table.insert(stateTeam.connections,
        Players.PlayerRemoving:Connect(function(player)
            removeTeamESP(player)
        end)
    )
end

-- === LOGIQUE ESP ALL PLAYERS (AVEC OPTIONS) ===
local MAX_SIZE_ALL = 105
local MIN_SIZE_ALL = 45

-- Configuration ESP All (peut être modifiée par l'UI)
local ESP_ALL_CONFIG = {
    AlwaysOnTop = true,
    OutlineTransparency = 0.4,
    FillTransparency = 0.7,
    ShowTextLabels = true
}

function clearAllESP()
    for _, d in pairs(stateAll.objects) do
        if d.highlights then 
            for _, hl in ipairs(d.highlights) do 
                hl:Destroy() 
            end 
        end
        if d.billboard then d.billboard:Destroy() end
        if d.conn then d.conn:Disconnect() end
    end
    for _, c in pairs(stateAll.connections) do c:Disconnect() end
    stateAll.objects, stateAll.connections = {}, {}
    stateAll.enabled = false
end

function createESPForPlayer(player)
    if player == LocalPlayer or stateAll.objects[player] or not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Create multiple Highlights for parts except Head
    local highlights = {}
    for _, part in ipairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "Head" then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = part
            highlight.FillColor = Color3.fromRGB(255, 60, 60)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = ESP_ALL_CONFIG.FillTransparency
            highlight.OutlineTransparency = ESP_ALL_CONFIG.OutlineTransparency
            highlight.DepthMode = ESP_ALL_CONFIG.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            highlight.Parent = part
            table.insert(highlights, highlight)
        end
    end

    local billboard = nil
    local conn = nil
    
    if ESP_ALL_CONFIG.ShowTextLabels then
        billboard = Instance.new("BillboardGui")
        billboard.Adornee = root
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.Size = UDim2.fromOffset(80, 40)
        billboard.Parent = root

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.fromScale(1, 0.65)
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Font = Enum.Font.RobotoCondensed
        nameLabel.TextSize = 18
        nameLabel.Parent = billboard

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Position = UDim2.fromScale(0, 0.62)
        distanceLabel.Size = UDim2.fromScale(1, 0.38)
        distanceLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        distanceLabel.TextStrokeTransparency = 0.2
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = 12
        distanceLabel.Parent = billboard

        conn = RunService.RenderStepped:Connect(function()
            local localChar = LocalPlayer.Character
            if not localChar then return end
            local localRoot = localChar:FindFirstChild("HumanoidRootPart")
            if not localRoot then return end

            local distance = (localRoot.Position - root.Position).Magnitude
            distanceLabel.Text = math.floor(distance) .. " studs"

            local size = math.clamp(distance * 0.25, MIN_SIZE_ALL, MAX_SIZE_ALL)
            billboard.Size = UDim2.fromOffset(size, size * 0.55)
        end)
    end

    stateAll.objects[player] = { highlights = highlights, billboard = billboard, conn = conn }
end

function toggleESPAll()
    if stateAll.enabled then
        clearAllESP()
        return
    end

    stateAll.enabled = true

    for _, p in ipairs(Players:GetPlayers()) do
        createESPForPlayer(p)
        table.insert(stateAll.connections, p.CharacterAdded:Connect(function()
            task.wait(0.4)
            if stateAll.enabled then 
                -- Clear old ESP before creating new one
                local d = stateAll.objects[p]
                if d then
                    if d.highlights then 
                        for _, hl in ipairs(d.highlights) do 
                            hl:Destroy() 
                        end 
                    end
                    if d.billboard then d.billboard:Destroy() end
                    if d.conn then d.conn:Disconnect() end
                    stateAll.objects[p] = nil
                end
                createESPForPlayer(p) 
            end
        end))
    end

    table.insert(stateAll.connections, Players.PlayerRemoving:Connect(function(p)
        local d = stateAll.objects[p]
        if d then
            if d.highlights then 
                for _, hl in ipairs(d.highlights) do 
                    hl:Destroy() 
                end 
            end
            if d.billboard then d.billboard:Destroy() end
            if d.conn then d.conn:Disconnect() end
            stateAll.objects[p] = nil
        end
    end))
end

-- _G bridges so safetyGoHeal/Back (defined earlier) can call toggleESPAll
_G.safetyToggleESP   = function() toggleESPAll() end
_G.safetyGetESPState = function() return stateAll.enabled end

-- Fonction pour rafraîchir l'ESP avec les nouvelles options
function refreshESPAll()
    if not stateAll.enabled then return end
    
    -- Clear all current ESP
    for _, d in pairs(stateAll.objects) do
        if d.highlights then 
            for _, hl in ipairs(d.highlights) do 
                hl:Destroy() 
            end 
        end
        if d.billboard then d.billboard:Destroy() end
        if d.conn then d.conn:Disconnect() end
    end
    stateAll.objects = {}
    
    -- Recreate with new settings
    for _, p in ipairs(Players:GetPlayers()) do
        createESPForPlayer(p)
    end
end

-- === ADVANCED ESP ===
local ADV_ESP_CONFIG = {
    targetScope = "Players",
    performanceMode = true,
    maxDistance = 1000,
    boxEnabled = false,
    boxThickness = 1,
    boxColor = Color3.fromRGB(255, 255, 255),
    skeletonEnabled = false,
    skeletonThickness = 1,
    skeletonColor = Color3.fromRGB(255, 255, 255),
    lookArrowEnabled = false,
    lookArrowLength = 5,
    lookArrowThickness = 2,
    lookArrowHeadSize = 10,
    lookArrowColor = Color3.fromRGB(255, 255, 255),
    showName = false,
    showDistance = false,
    showHealth = false,
    nameMode = "Username",
    distanceMode = "Camera",
    namePosition = "Top",
    distancePosition = "Bottom",
    healthPosition = "Left",
    useTeamColor = false,
    useThemeColor = false,
    filterMode = "None",
    filterCategory = "Teams",
    disabledTeams = {},
    disabledPlayers = {},
    onlyTeams = {},
    onlyPlayers = {},
}

function advEspScopeAllowsPlayers()
    return ADV_ESP_CONFIG.targetScope == "Players" or ADV_ESP_CONFIG.targetScope == "Players + NPCs"
end

function advEspScopeAllowsNPCs()
    return ADV_ESP_CONFIG.targetScope == "NPCs" or ADV_ESP_CONFIG.targetScope == "Players + NPCs"
end

function advEspDisconnectAll()
    for _, conn in ipairs(advEspState.connections or {}) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    advEspState.connections = {}
end

function advEspDestroyPlayer(player)
    local data = advEspState.objects[player]
    if not data then return end
    for _, obj in ipairs(data.drawings or {}) do pcall(function() obj:Remove() end) end
    for _, obj in ipairs(data.instances or {}) do if obj then pcall(function() obj:Destroy() end) end end
    advEspState.objects[player] = nil
end

function advEspClearObjects()
    for player in pairs(advEspState.objects or {}) do advEspDestroyPlayer(player) end
    advEspState.objects = {}
end

function advEspIsPlayerTarget(target)
    return typeof(target) == "Instance" and target:IsA("Player")
end

function advEspIsNPCTarget(target)
    return typeof(target) == "Instance" and target:IsA("Model") and Players:GetPlayerFromCharacter(target) == nil
end

function advEspGetChar(target)
    local char = nil
    if advEspIsPlayerTarget(target) then
        char = target.Character
    elseif advEspIsNPCTarget(target) then
        char = target
    end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        return nil, nil, nil
    end
    return char, hum, root
end

function advEspFilterMatches(player, category, teamSet, playerSet)
    if category == "Players" then return playerSet[player.Name] == true end
    return player.Team and teamSet[player.Team.Name] == true or false
end

function advEspPassesFilter(target)
    if advEspIsNPCTarget(target) then
        if not advEspScopeAllowsNPCs() then return false end
        if ADV_ESP_CONFIG.filterMode == "Enable only for" then
            local onlySet = ADV_ESP_CONFIG.filterCategory == "Teams" and ADV_ESP_CONFIG.onlyTeams or ADV_ESP_CONFIG.onlyPlayers
            if next(onlySet) then return false end
        end
        return true
    end
    local player = advEspIsPlayerTarget(target) and target or nil
    if not player or player == LocalPlayer or not advEspScopeAllowsPlayers() then return false end
    if ADV_ESP_CONFIG.filterMode == "Enable only for" then
        local onlySet = ADV_ESP_CONFIG.filterCategory == "Teams" and ADV_ESP_CONFIG.onlyTeams or ADV_ESP_CONFIG.onlyPlayers
        if not next(onlySet) then return true end
        return advEspFilterMatches(player, ADV_ESP_CONFIG.filterCategory, ADV_ESP_CONFIG.onlyTeams, ADV_ESP_CONFIG.onlyPlayers)
    elseif ADV_ESP_CONFIG.filterMode == "Disable only for" then
        return not advEspFilterMatches(player, ADV_ESP_CONFIG.filterCategory, ADV_ESP_CONFIG.disabledTeams, ADV_ESP_CONFIG.disabledPlayers)
    end
    return true
end

function advEspGetColor(player)
    if ADV_ESP_CONFIG.useThemeColor then return Config.colors.accent end
    if advEspIsPlayerTarget(player) and ADV_ESP_CONFIG.useTeamColor and player.TeamColor then return player.TeamColor.Color end
    return ADV_ESP_CONFIG.boxColor
end

function advEspGetName(target, hum)
    if advEspIsPlayerTarget(target) then
        return ADV_ESP_CONFIG.nameMode == "Display" and target.DisplayName or target.Name
    end
    if hum and hum.DisplayName and hum.DisplayName ~= "" then return hum.DisplayName end
    return target and target.Name or "NPC"
end

function advEspGetGuiRoot()
    if advEspState.guiRoot and advEspState.guiRoot.Parent then return advEspState.guiRoot end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LizardAdvancedEspGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000009
    gui.Parent = playerGui
    advEspState.guiRoot = gui
    return gui
end

function advEspApplyGuiDrawing(obj)
    local inst = rawget(obj, "_inst")
    if not inst then return end
    local kind = rawget(obj, "_kind")
    local props = rawget(obj, "_props") or {}
    inst.Visible = props.Visible == true
    if kind == "Line" then
        local from = props.From or Vector2.new()
        local to = props.To or Vector2.new()
        local delta = to - from
        local len = math.max(delta.Magnitude, 1)
        inst.AnchorPoint = Vector2.new(0.5, 0.5)
        inst.Position = UDim2.fromOffset((from.X + to.X) * 0.5, (from.Y + to.Y) * 0.5)
        inst.Size = UDim2.fromOffset(len, math.max(props.Thickness or 1, 1))
        local angle
        if math.abs(delta.X) < 0.001 then
            angle = delta.Y >= 0 and math.pi / 2 or -math.pi / 2
        else
            angle = math.atan(delta.Y / delta.X)
            if delta.X < 0 then angle = angle + math.pi end
        end
        inst.Rotation = math.deg(angle)
        inst.BackgroundColor3 = props.Color or Color3.new(1, 1, 1)
    elseif kind == "Square" then
        local pos = props.Position or Vector2.new()
        local size = props.Size or Vector2.new()
        local stroke = rawget(obj, "_stroke")
        inst.Position = UDim2.fromOffset(pos.X, pos.Y)
        inst.Size = UDim2.fromOffset(size.X, size.Y)
        inst.BackgroundTransparency = props.Filled and 0.75 or 1
        inst.BackgroundColor3 = props.Color or Color3.new(1, 1, 1)
        if stroke then
            stroke.Color = props.Color or Color3.new(1, 1, 1)
            stroke.Thickness = math.max(props.Thickness or 1, 1)
        end
    elseif kind == "Text" then
        local pos = props.Position or Vector2.new()
        inst.Position = UDim2.fromOffset(pos.X, pos.Y)
        inst.Text = tostring(props.Text or "")
        inst.TextColor3 = props.Color or Color3.new(1, 1, 1)
        inst.TextSize = props.Size or 12
        inst.TextStrokeTransparency = props.Outline and 0.35 or 1
        inst.Size = UDim2.fromOffset(math.max(inst.TextBounds.X + 4, 24), math.max(inst.TextBounds.Y + 2, 14))
    end
end

function advEspNewGuiDrawing(kind)
    local root = advEspGetGuiRoot()
    local inst
    local obj = {_kind = kind, _props = {Visible = false}}
    if kind == "Text" then
        inst = Instance.new("TextLabel")
        inst.BackgroundTransparency = 1
        inst.Font = Enum.Font.GothamMedium
        inst.TextXAlignment = Enum.TextXAlignment.Left
        inst.TextYAlignment = Enum.TextYAlignment.Top
    else
        inst = Instance.new("Frame")
        inst.BorderSizePixel = 0
        inst.BackgroundTransparency = kind == "Square" and 1 or 0
        if kind == "Square" then
            obj._stroke = Instance.new("UIStroke", inst)
        end
    end
    inst.Visible = false
    inst.Parent = root
    obj._inst = inst
    local mt = {}
    mt.__index = function(t, k)
        if k == "Remove" then return function() if t._inst then t._inst:Destroy() end end end
        if k == "TextBounds" and t._inst and t._kind == "Text" then return t._inst.TextBounds end
        local props = rawget(t, "_props")
        return props and props[k] or rawget(t, k)
    end
    mt.__newindex = function(t, k, v)
        if k == "_inst" or k == "_stroke" or k == "_kind" or k == "_props" then
            rawset(t, k, v)
            return
        end
        local props = rawget(t, "_props")
        if props then props[k] = v end
        rawset(t, "_dirty", true)
    end
    return setmetatable(obj, mt)
end

function advEspNewDrawing(kind)
    return advEspNewGuiDrawing(kind)
end

function advEspFlushData(data)
    if not data then return end
    for _, obj in ipairs(data.drawings or {}) do
        if rawget(obj, "_dirty") then
            rawset(obj, "_dirty", false)
            advEspApplyGuiDrawing(obj)
        end
    end
end

function advEspEnsurePlayer(player)
    if player == LocalPlayer or advEspState.objects[player] or not advEspPassesFilter(player) then return end
    local drawings = {}
    local data = { drawings = drawings, instances = {} }
    data.box = advEspNewDrawing("Square"); if data.box then table.insert(drawings, data.box) end
    data.lookLine = advEspNewDrawing("Line"); if data.lookLine then table.insert(drawings, data.lookLine) end
    data.lookHeadA = advEspNewDrawing("Line"); if data.lookHeadA then table.insert(drawings, data.lookHeadA) end
    data.lookHeadB = advEspNewDrawing("Line"); if data.lookHeadB then table.insert(drawings, data.lookHeadB) end
    data.nameText = advEspNewDrawing("Text"); if data.nameText then table.insert(drawings, data.nameText) end
    data.distanceText = advEspNewDrawing("Text"); if data.distanceText then table.insert(drawings, data.distanceText) end
    data.healthText = advEspNewDrawing("Text"); if data.healthText then table.insert(drawings, data.healthText) end
    data.skeleton = {}
    for i = 1, 14 do
        local line = advEspNewDrawing("Line")
        if line then table.insert(data.skeleton, line); table.insert(drawings, line) end
    end
    advEspState.objects[player] = data
end

function advEspHideData(data)
    if not data then return end
    for _, obj in ipairs(data.drawings or {}) do pcall(function() obj.Visible = false end) end
end

function advEspProjectPart(char, name)
    local part = char and char:FindFirstChild(name)
    if not part then return nil end
    local point, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    return Vector2.new(point.X, point.Y)
end

function advEspProjectWorld(position)
    local point, onScreen = workspace.CurrentCamera:WorldToViewportPoint(position)
    if not onScreen then return nil end
    return Vector2.new(point.X, point.Y)
end

function advEspAddSkeletonSegment(segments, a, b)
    if a and b then table.insert(segments, {a, b}) end
end

function advEspLimbEnds(part)
    if not part then return nil, nil end
    local axis = part.CFrame.UpVector * (part.Size.Y * 0.45)
    return part.Position + axis, part.Position - axis
end

function advEspLimbEndsFromAnchor(part, anchor)
    local a, b = advEspLimbEnds(part)
    if not a or not b or not anchor then return a, b end
    if (b - anchor).Magnitude < (a - anchor).Magnitude then
        return b, a
    end
    return a, b
end

function advEspBuildSkeletonSegments(char)
    local segments = {}
    local upperTorso = char:FindFirstChild("UpperTorso")
    if upperTorso then
        local pairsList = {
            {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
            {"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
            {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
            {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        }
        for _, pair in ipairs(pairsList) do
            local a = char:FindFirstChild(pair[1])
            local b = char:FindFirstChild(pair[2])
            advEspAddSkeletonSegment(segments, a and a.Position, b and b.Position)
        end
        return segments
    end

    local torso = char:FindFirstChild("Torso")
    if not torso then return segments end
    local head = char:FindFirstChild("Head")
    local leftArm = char:FindFirstChild("Left Arm")
    local rightArm = char:FindFirstChild("Right Arm")
    local leftLeg = char:FindFirstChild("Left Leg")
    local rightLeg = char:FindFirstChild("Right Leg")
    local cf, size = torso.CFrame, torso.Size
    local up, right = cf.UpVector, cf.RightVector
    local upper = torso.Position + up * (size.Y * 0.28)
    local lower = torso.Position - up * (size.Y * 0.34)
    local leftShoulder = upper - right * (size.X * 0.58)
    local rightShoulder = upper + right * (size.X * 0.58)
    local leftHip = lower - right * (size.X * 0.25)
    local rightHip = lower + right * (size.X * 0.25)

    advEspAddSkeletonSegment(segments, head and head.Position, upper)
    advEspAddSkeletonSegment(segments, upper, lower)
    local leftArmTop, leftArmBottom = advEspLimbEndsFromAnchor(leftArm, leftShoulder)
    local rightArmTop, rightArmBottom = advEspLimbEndsFromAnchor(rightArm, rightShoulder)
    local leftLegTop, leftLegBottom = advEspLimbEndsFromAnchor(leftLeg, leftHip)
    local rightLegTop, rightLegBottom = advEspLimbEndsFromAnchor(rightLeg, rightHip)

    advEspAddSkeletonSegment(segments, upper, leftShoulder)
    advEspAddSkeletonSegment(segments, leftShoulder, leftArmTop)
    advEspAddSkeletonSegment(segments, leftArmTop, leftArmBottom)
    advEspAddSkeletonSegment(segments, upper, rightShoulder)
    advEspAddSkeletonSegment(segments, rightShoulder, rightArmTop)
    advEspAddSkeletonSegment(segments, rightArmTop, rightArmBottom)
    advEspAddSkeletonSegment(segments, lower, leftHip)
    advEspAddSkeletonSegment(segments, leftHip, leftLegTop)
    advEspAddSkeletonSegment(segments, leftLegTop, leftLegBottom)
    advEspAddSkeletonSegment(segments, lower, rightHip)
    advEspAddSkeletonSegment(segments, rightHip, rightLegTop)
    advEspAddSkeletonSegment(segments, rightLegTop, rightLegBottom)
    return segments
end

function advEspDrawSkeleton(data, char, color)
    local idx = 1
    if not ADV_ESP_CONFIG.skeletonEnabled then
        for i = 1, #data.skeleton do data.skeleton[i].Visible = false end
        return
    end
    local segments = advEspBuildSkeletonSegments(char)
    for _, segment in ipairs(segments) do
        local a = advEspProjectWorld(segment[1])
        local b = advEspProjectWorld(segment[2])
        if a and b and data.skeleton[idx] then
            local line = data.skeleton[idx]
            line.Visible = ADV_ESP_CONFIG.skeletonEnabled
            line.From = a
            line.To = b
            line.Color = ADV_ESP_CONFIG.skeletonColor or color
            line.Thickness = ADV_ESP_CONFIG.skeletonThickness
            idx = idx + 1
        end
        if idx > #data.skeleton then break end
    end
    for i = idx, #data.skeleton do data.skeleton[i].Visible = false end
end

function advEspTextOffset(posName, boxPos, boxSize, anchorX)
    anchorX = anchorX or (boxPos.X + boxSize.X / 2)
    if posName == "Top" then return Vector2.new(anchorX, boxPos.Y - 16), true end
    if posName == "Bottom" then return Vector2.new(anchorX, boxPos.Y + boxSize.Y + 2), true end
    if posName == "Left" then return Vector2.new(boxPos.X - 30, boxPos.Y + boxSize.Y / 2), false end
    return Vector2.new(boxPos.X + boxSize.X + 6, boxPos.Y + boxSize.Y / 2), false
end

function advEspUpdateText(textObj, visible, text, pos, centered, color)
    if not textObj then return end
    textObj.Visible = visible
    if not visible then return end
    pcall(function() textObj.Font = 2 end)
    textObj.Size = 12
    textObj.Text = text
    textObj.Color = color
    textObj.Outline = true
    textObj.Center = false
    if centered then
        local ok, bounds = pcall(function() return textObj.TextBounds end)
        if ok and bounds then
            pos = Vector2.new(pos.X - bounds.X / 2, pos.Y)
        end
    end
    textObj.Position = pos
end

function advEspGetScreenBounds(char, fallbackRoot)
    local cam = workspace.CurrentCamera
    local ok, cf, size = pcall(function() return char:GetBoundingBox() end)
    if not ok or not cf or not size then
        local point, onScreen = cam:WorldToViewportPoint(fallbackRoot.Position)
        if not onScreen then return nil end
        return Vector2.new(point.X - 18, point.Y - 45), Vector2.new(36, 90)
    end

    local half = size * 0.5
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local projected = 0
    for _, x in ipairs({-half.X, half.X}) do
        for _, y in ipairs({-half.Y, half.Y}) do
            for _, z in ipairs({-half.Z, half.Z}) do
                local point, onScreen = cam:WorldToViewportPoint((cf * CFrame.new(x, y, z)).Position)
                if onScreen then
                    minX = math.min(minX, point.X)
                    minY = math.min(minY, point.Y)
                    maxX = math.max(maxX, point.X)
                    maxY = math.max(maxY, point.Y)
                    projected = projected + 1
                end
            end
        end
    end
    if projected == 0 then return nil end

    local width = math.clamp(maxX - minX, 18, 260)
    local height = math.clamp(maxY - minY, 26, 420)
    local centerX = (minX + maxX) * 0.5
    return Vector2.new(centerX - width * 0.5, minY), Vector2.new(width, height)
end

function advEspUpdatePlayer(player, data)
    local char, hum, root = advEspGetChar(player)
    if not char or not advEspPassesFilter(player) then advEspHideData(data) return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distWorld = localRoot and (root.Position - localRoot.Position).Magnitude or 0
    if distWorld > ADV_ESP_CONFIG.maxDistance then advEspHideData(data) return end

    local cam = workspace.CurrentCamera
    local rootPoint, onScreen = cam:WorldToViewportPoint(root.Position)
    if not onScreen then advEspHideData(data) return end

    local boxPos, boxSize = advEspGetScreenBounds(char, root)
    if not boxPos then advEspHideData(data) return end
    local color = advEspGetColor(player)

    if data.box then
        data.box.Visible = ADV_ESP_CONFIG.boxEnabled
        if ADV_ESP_CONFIG.boxEnabled then
            data.box.Position = boxPos
            data.box.Size = boxSize
            data.box.Color = color
            data.box.Thickness = ADV_ESP_CONFIG.boxThickness
            data.box.Filled = false
        end
    end

    advEspDrawSkeleton(data, char, color)

    if data.lookLine then
        local visible = false
        local start, finish
        if ADV_ESP_CONFIG.lookArrowEnabled then
            start = Vector2.new(rootPoint.X, rootPoint.Y)
            local lookWorld = root.Position + root.CFrame.LookVector * ADV_ESP_CONFIG.lookArrowLength
            local lookPoint, lookOnScreen = cam:WorldToViewportPoint(lookWorld)
            finish = Vector2.new(lookPoint.X, lookPoint.Y)
            visible = lookOnScreen
        end
        data.lookLine.Visible = visible
        data.lookHeadA.Visible = visible
        data.lookHeadB.Visible = visible
        if visible then
            local dir = (finish - start)
            if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
            dir = dir.Unit
            local perp = Vector2.new(-dir.Y, dir.X)
            local hs = ADV_ESP_CONFIG.lookArrowHeadSize
            data.lookLine.From = start; data.lookLine.To = finish; data.lookLine.Color = ADV_ESP_CONFIG.lookArrowColor; data.lookLine.Thickness = ADV_ESP_CONFIG.lookArrowThickness
            data.lookHeadA.From = finish; data.lookHeadA.To = finish - dir * hs + perp * hs * 0.45; data.lookHeadA.Color = ADV_ESP_CONFIG.lookArrowColor; data.lookHeadA.Thickness = ADV_ESP_CONFIG.lookArrowThickness
            data.lookHeadB.From = finish; data.lookHeadB.To = finish - dir * hs - perp * hs * 0.45; data.lookHeadB.Color = ADV_ESP_CONFIG.lookArrowColor; data.lookHeadB.Thickness = ADV_ESP_CONFIG.lookArrowThickness
        end
    end

    local anchorX = rootPoint.X
    local namePos, nameCentered = advEspTextOffset(ADV_ESP_CONFIG.namePosition, boxPos, boxSize, anchorX)
    local distPos, distCentered = advEspTextOffset(ADV_ESP_CONFIG.distancePosition, boxPos, boxSize, anchorX)
    local hpPos, hpCentered = advEspTextOffset(ADV_ESP_CONFIG.healthPosition, boxPos, boxSize, anchorX)
    local nameText = advEspGetName(player, hum)
    local distText = ADV_ESP_CONFIG.distanceMode == "Camera" and math.floor((cam.CFrame.Position - root.Position).Magnitude) .. " cam" or math.floor(distWorld) .. " studs"
    advEspUpdateText(data.nameText, ADV_ESP_CONFIG.showName, nameText, namePos, nameCentered, color)
    advEspUpdateText(data.distanceText, ADV_ESP_CONFIG.showDistance, distText, distPos, distCentered, color)
    advEspUpdateText(data.healthText, ADV_ESP_CONFIG.showHealth, math.floor(hum.Health) .. " HP", hpPos, hpCentered, color)
end

function advEspRefreshAll()
    if not advEspState.enabled then return end
    for target in pairs(advEspState.objects) do
        if (advEspIsPlayerTarget(target) and not Players:FindFirstChild(target.Name)) or (advEspIsNPCTarget(target) and not target.Parent) or not advEspPassesFilter(target) then
            advEspDestroyPlayer(target)
        end
    end
    if advEspScopeAllowsPlayers() then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then advEspEnsurePlayer(player) end
        end
    end
    if advEspScopeAllowsNPCs() then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                advEspEnsurePlayer(obj.Parent)
            end
        end
    end
    if advEspState.uiRefresh then pcall(advEspState.uiRefresh) end
end

function toggleAdvancedESP(active)
    advEspState.enabled = active
    if active then
        advEspDisconnectAll()
        advEspRefreshAll()
        table.insert(advEspState.connections, Players.PlayerAdded:Connect(function(player)
            table.insert(advEspState.connections, player.CharacterAdded:Connect(function() task.wait(0.25); advEspRefreshAll() end))
            table.insert(advEspState.connections, player:GetPropertyChangedSignal("Team"):Connect(advEspRefreshAll))
            advEspRefreshAll()
        end))
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(advEspState.connections, player.CharacterAdded:Connect(function() task.wait(0.25); advEspRefreshAll() end))
                table.insert(advEspState.connections, player:GetPropertyChangedSignal("Team"):Connect(advEspRefreshAll))
            end
        end
        table.insert(advEspState.connections, Players.PlayerRemoving:Connect(function(player) advEspDestroyPlayer(player); if advEspState.uiRefresh then advEspState.uiRefresh() end end))
        table.insert(advEspState.connections, workspace.DescendantAdded:Connect(function(obj)
            if not advEspState.enabled or not advEspScopeAllowsNPCs() then return end
            if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                advEspEnsurePlayer(obj.Parent)
            end
        end))
        table.insert(advEspState.connections, RunService.RenderStepped:Connect(function()
            if not advEspState.enabled then return end
            local now = tick()
            local interval = ADV_ESP_CONFIG.performanceMode and 0.033 or 0
            if interval > 0 and now - (advEspState.lastUpdateTime or 0) < interval then return end
            advEspState.lastUpdateTime = now
            for player, data in pairs(advEspState.objects) do
                local ok, err = pcall(advEspUpdatePlayer, player, data)
                if not ok then
                    if tick() - (advEspState.lastRenderWarn or 0) > 2 then
                        advEspState.lastRenderWarn = tick()
                        warn("[AdvancedESP] Render update failed:", err)
                    end
                    advEspHideData(data)
                end
                advEspFlushData(data)
            end
        end))
    else
        advEspDisconnectAll()
        advEspClearObjects()
    end
end

-- === LOGIQUE ESP (CORRIGÉE) ===
local MAX_SIZE = 110
local MIN_SIZE = 45

function clearESP()
    if state.highlight then state.highlight:Destroy() end
    if state.billboard then state.billboard:Destroy() end
    if state.connection then state.connection:Disconnect() end
    state.highlight, state.billboard, state.connection, state.target = nil, nil, nil, nil
end

function findPlayer(partial)
    partial = partial:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():sub(1, #partial) == partial then
            return p
        end
    end
end

function runYourESP(playerSearch)
    -- 1. Si le champ est vide, on efface tout et on arrête
    if playerSearch == "" then 
        clearESP()
        return 
    end
    
    -- 2. On cherche la cible demandée
    local target = findPlayer(playerSearch)
    if not target or not target.Character then 
        clearESP() -- Optionnel : efface si on ne trouve personne
        return 
    end
    
    -- 3. LOGIQUE TOGGLE : Si la cible est déjà la même que l'actuelle, on éteint
    if state.target == target then
        clearESP()
        return
    end
    
    -- 4. Si c'est une NOUVELLE cible (ou la première), on nettoie l'ancien et on crée le nouveau
    clearESP()
    state.target = target
    
    local char = target.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.35
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    state.highlight = highlight
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = root
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.Size = UDim2.fromOffset(80, 40)
    billboard.Parent = root
    state.billboard = billboard
    
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 0.65)
    title.Text = "TARGET"
    title.TextColor3 = Color3.fromRGB(255, 60, 60)
    title.TextStrokeTransparency = 0
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Position = UDim2.fromScale(0, 0.62)
    distanceLabel.Size = UDim2.fromScale(1, 0.38)
    distanceLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    distanceLabel.TextStrokeTransparency = 0.2
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.Parent = billboard
    
    state.connection = RunService.RenderStepped:Connect(function()
        local localChar = LocalPlayer.Character
        if not localChar then return end
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot or not root.Parent then return end -- Sécurité si le joueur part
        
        local distance = (localRoot.Position - root.Position).Magnitude
        distanceLabel.Text = math.floor(distance) .. " studs"
        
        local size = math.clamp(distance * 0.25, MIN_SIZE, MAX_SIZE)
        billboard.Size = UDim2.fromOffset(size, size * 0.55)
    end)
end
-- Suppression de l'ancienne GUI
if playerGui:FindFirstChild("FXTGUI") then
    playerGui.FXTGUI:Destroy()
end

-- Création de la GUI principale
task.spawn(function() -- GUI BUILD SCOPE START
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FXTGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999999
screenGui.Parent = playerGui

-- === MAIN FRAME ===
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = Config.size
mainFrame.Position = Config.position
mainFrame.BackgroundColor3 = Config.colors.background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true 
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame



-- Logique d'animation
local isAnimating = false
local menuOpen = true
local savedPosition = Config.position -- Position sauvegardée

local gtaArrowRepeat = {token = 0, key = nil}

local function gtaHandleArrowKey(keyCode)
    if not menuOpen or UserInputService:GetFocusedTextBox() or not gtaNav then return end
    gtaShowSelection()

    if keyCode == Enum.KeyCode.Down then
        if gtaNav.optionIndex ~= nil then
            if not gtaExpandedNavStep or not gtaExpandedNavStep(1) then
                gtaNav.optionIndex = nil
                gtaSetScriptIndex(gtaNav.scriptIndex + 1)
            end
        else
            gtaSetScriptIndex(gtaNav.scriptIndex + 1)
        end
    elseif keyCode == Enum.KeyCode.Up then
        if gtaNav.optionIndex ~= nil then
            if not gtaExpandedNavStep or not gtaExpandedNavStep(-1) then
                gtaNav.optionIndex = nil
                gtaSetScriptIndex(gtaNav.scriptIndex - 1)
            end
        else
            gtaSetScriptIndex(gtaNav.scriptIndex - 1)
        end
    elseif keyCode == Enum.KeyCode.Right then
        local entered = false
        if gtaNav.optionIndex == nil and gtaExpandedItemsForCurrentScript then
            local items = gtaExpandedItemsForCurrentScript()
            if #items > 0 then
                gtaNav.optionIndex = 1
                entered = true
                if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
            end
        end
        if not entered then
            if not gtaExpandedNavAdjust or not gtaExpandedNavAdjust(1) then
                gtaSetCategory(Config.selectedCategory + 1)
            end
        end
    elseif keyCode == Enum.KeyCode.Left then
        if gtaNav.optionIndex ~= nil then
            local item = gtaGetExpandedItem and gtaGetExpandedItem()
            if item and item.left then
                gtaExpandedNavAdjust(-1)
            else
                gtaNav.optionIndex = nil
                if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
            end
        else
            gtaSetCategory(Config.selectedCategory - 1)
        end
    end
end

local function sinkGuiArrowMovement(_, _, input)
    if menuOpen and input and (
        input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down
        or input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right
    ) then
        if not gtaNav then return Enum.ContextActionResult.Sink end
        if input.UserInputState == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
            gtaHandleArrowKey(input.KeyCode)
            gtaArrowRepeat.token = gtaArrowRepeat.token + 1
            gtaArrowRepeat.key = input.KeyCode
            local token = gtaArrowRepeat.token
            local heldKey = input.KeyCode
            task.spawn(function()
                task.wait(0.35)
                while menuOpen and gtaArrowRepeat.token == token and gtaArrowRepeat.key == heldKey do
                    gtaHandleArrowKey(heldKey)
                    task.wait(0.07)
                end
            end)
        elseif input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
            if gtaArrowRepeat.key == input.KeyCode then
                gtaArrowRepeat.token = gtaArrowRepeat.token + 1
                gtaArrowRepeat.key = nil
            end
        end
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority(
    "LizardGuiArrowNavSink",
    sinkGuiArrowMovement,
    false,
    3000,
    Enum.KeyCode.Up,
    Enum.KeyCode.Down,
    Enum.KeyCode.Left,
    Enum.KeyCode.Right
)

function toggleMenu()
    if isAnimating then return end
    isAnimating = true
    
    if menuOpen then
        -- Sauvegarder la position actuelle avant de fermer
        savedPosition = mainFrame.Position
        
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(savedPosition.X.Scale, savedPosition.X.Offset, savedPosition.Y.Scale, savedPosition.Y.Offset)
        })
        tween:Play()
        tween.Completed:Wait()
        mainFrame.Visible = false
        menuOpen = false
        if gtaNav then gtaNav.visible = false end
        if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
    else
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Position = savedPosition
        local tween = TweenService:Create(mainFrame, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = Config.size,
            Position = savedPosition
        })
        tween:Play()
        tween.Completed:Wait()
        menuOpen = true
    end
    isAnimating = false
    -- Sync server browser visibility with main menu
    if _G.SB_SetVisible then _G.SB_SetVisible(menuOpen) end
end

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Config.colors.header
header.BorderSizePixel = 0
header.Active = true 
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 12)
headerBottom.Position = UDim2.new(0, 0, 1, -12)
headerBottom.BackgroundColor3 = Config.colors.header
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

-- Ligne accent sous header
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, 0)
accentLine.BackgroundColor3 = Config.colors.accent
accentLine.BorderSizePixel = 0
accentLine.Parent = header

local accentGradient = Instance.new("UIGradient")
accentGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.8),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 0.8)
})
accentGradient.Parent = accentLine

-- Titre
-- 1. Ton Image (Utilise ton ID spécifique)

local titleIcon = Instance.new("ImageButton")
titleIcon.Size = UDim2.new(0, 84, 0, 84)
titleIcon.Position = UDim2.new(0, -8, 0.5, -42)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://120005639715315"
titleIcon.ZIndex = 10
titleIcon.AutoButtonColor = false
titleIcon.Parent = header
titleIcon.MouseButton1Click:Connect(function()
    -- SB_ShowPrompt is set by a separate task.spawn; wait briefly if not ready yet
    local attempts = 0
    while not _G.SB_ShowPrompt and attempts < 20 do
        task.wait(0.1)
        attempts = attempts + 1
    end
    if _G.SB_ShowPrompt then _G.SB_ShowPrompt() end
end)

-- 2. Conteneur pour aligner le texte (Titre + Crédits)
local textContainer = Instance.new("Frame")
textContainer.Size = UDim2.new(1, -110, 1, 0)
textContainer.Position = UDim2.new(0, 62, 0, 0) -- Décalé pour laisser place à l'image
textContainer.BackgroundTransparency = 1
textContainer.Parent = header

-- 3. Ton Nouveau Titre
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.5, 0)
title.Position = UDim2.new(0, 0, 0.15, 0) -- Positionné en haut du header
title.BackgroundTransparency = 1
title.Text = "- Lizard UI - V2 " -- <--- CHANGE LE NOM ICI SI TU VEUX
title.TextColor3 = Config.colors.text
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = textContainer

-- 4. Les Crédits (Juste en dessous du titre)
local subCredits = Instance.new("TextLabel")
subCredits.Size = UDim2.new(1, 0, 0.3, 0)
subCredits.Position = UDim2.new(0, 0, 0.6, 0) -- Positionné juste sous le titre
subCredits.BackgroundTransparency = 1
subCredits.Text = "UI BY FXTHai | " -- <--- TEXTE DES CREDITS
subCredits.TextColor3 = Config.colors.textDim -- Utilise le gris discret de ta config
subCredits.Font = Enum.Font.Gotham
subCredits.TextSize = 12
subCredits.TextXAlignment = Enum.TextXAlignment.Left
subCredits.Parent = textContainer


-- Bouton HOME
homeButton = Instance.new("TextButton")
homeButton.Size = UDim2.new(0, 70, 0, 28)
homeButton.Position = UDim2.new(1, -125, 0.5, -14)
homeButton.BackgroundColor3 = Config.colors.homeButton
homeButton.BorderSizePixel = 0
homeButton.Text = Config.openKey.Name:upper()
homeButton.TextColor3 = Config.colors.text
homeButton.Font = Enum.Font.GothamBold
homeButton.TextSize = 11
homeButton.AutoButtonColor = false
homeButton.Parent = header

local homeCorner = Instance.new("UICorner")
homeCorner.CornerRadius = UDim.new(0, 6)
homeCorner.Parent = homeButton

-- Bouton Save/Load
local saveButton = Instance.new("TextButton")
saveButton.Size             = UDim2.new(0, 32, 0, 28)
saveButton.Position         = UDim2.new(1, -165, 0.5, -14)
saveButton.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
saveButton.BorderSizePixel  = 0
saveButton.Text             = "💾"
saveButton.TextSize         = 14
saveButton.AutoButtonColor  = false
saveButton.Parent           = header
Instance.new("UICorner", saveButton).CornerRadius = UDim.new(0, 6)
saveButton.MouseButton1Click:Connect(function()
    if _G.SavePanel_Toggle then _G.SavePanel_Toggle() end
end)

-- Bouton Keybinds
local keybindButton = Instance.new("TextButton")
keybindButton.Size             = UDim2.new(0, 32, 0, 28)
keybindButton.Position         = UDim2.new(1, -205, 0.5, -14)
keybindButton.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
keybindButton.BorderSizePixel  = 0
keybindButton.Text             = "⌨"
keybindButton.TextSize         = 14
keybindButton.TextColor3       = Config.colors.text
keybindButton.AutoButtonColor  = false
keybindButton.Parent           = header
Instance.new("UICorner", keybindButton).CornerRadius = UDim.new(0, 6)
keybindButton.MouseButton1Click:Connect(function()
    if _G.KeybindPanel_Toggle then _G.KeybindPanel_Toggle() end
end)

-- Bouton Unload
local unloadButton = Instance.new("TextButton")
unloadButton.Size = UDim2.new(0, 32, 0, 28)
unloadButton.Position = UDim2.new(1, -45, 0.5, -14)
unloadButton.BackgroundColor3 = Config.colors.unloadButton
unloadButton.BorderSizePixel = 0
unloadButton.Text = ""
unloadButton.AutoButtonColor = false
unloadButton.Parent = header

local unloadCorner = Instance.new("UICorner")
unloadCorner.CornerRadius = UDim.new(0, 6)
unloadCorner.Parent = unloadButton

local unloadX = Instance.new("TextLabel")
unloadX.Size = UDim2.new(1, 0, 1, 0)
unloadX.BackgroundTransparency = 1
unloadX.Text = "X" 
unloadX.TextColor3 = Config.colors.text
unloadX.Font = Enum.Font.GothamBold
unloadX.TextSize = 18
unloadX.Parent = unloadButton

-- Panel gauche
local categoryPanel = Instance.new("Frame")
categoryPanel.Name = "CategoryPanel"
categoryPanel.Size = UDim2.new(0, 170, 1, -72)
categoryPanel.Position = UDim2.new(0, 10, 0, 62)
categoryPanel.BackgroundColor3 = Config.colors.categoryBg
categoryPanel.BorderSizePixel = 0
categoryPanel.Parent = mainFrame

local categoryCorner = Instance.new("UICorner")
categoryCorner.CornerRadius = UDim.new(0, 10)
categoryCorner.Parent = categoryPanel

-- Badge Category
local categoryBadge = Instance.new("Frame")
categoryBadge.Name = "CategoryBadge"
categoryBadge.Size = UDim2.new(0, 82, 0, 20)
categoryBadge.Position = UDim2.new(0, 10, 0, 10)
categoryBadge.BackgroundColor3 = Config.colors.categoryBadge
categoryBadge.BorderSizePixel = 0
categoryBadge.Parent = categoryPanel

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 6)
badgeCorner.Parent = categoryBadge

local categoryTitle = Instance.new("TextLabel")
categoryTitle.Size = UDim2.new(1, 0, 1, 0)
categoryTitle.BackgroundTransparency = 1
categoryTitle.Text = "CATEGORY"
categoryTitle.TextColor3 = Config.colors.textDim
categoryTitle.Font = Enum.Font.GothamBold
categoryTitle.TextSize = 10
categoryTitle.TextXAlignment = Enum.TextXAlignment.Center
categoryTitle.Parent = categoryBadge

local categoryList = Instance.new("ScrollingFrame") -- On change Frame en ScrollingFrame
categoryList.Name = "CategoryList"
categoryList.Size = UDim2.new(1, -12, 1, -42)
categoryList.Position = UDim2.new(0, 6, 0, 36)
categoryList.BackgroundTransparency = 1
categoryList.BorderSizePixel = 0
categoryList.ScrollBarThickness = 2 -- Très fin pour rester "Slim"
categoryList.ScrollBarImageColor3 = Config.colors.accent
categoryList.CanvasSize = UDim2.new(0, 0, 0, 0) -- Calculé automatiquement par le script plus bas
categoryList.Parent = categoryPanel

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Padding = UDim.new(0, 6)
categoryLayout.Parent = categoryList
categoryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    categoryList.CanvasSize = UDim2.new(0, 0, 0, categoryLayout.AbsoluteContentSize.Y)
end)

-- Panel droit (AVEC SCROLL)
local scriptPanel = Instance.new("ScrollingFrame")
scriptPanel.Name = "ScriptPanel"
scriptPanel.Size = UDim2.new(1, -195, 1, -72)
scriptPanel.Position = UDim2.new(0, 190, 0, 62)
scriptPanel.BackgroundTransparency = 1
scriptPanel.BorderSizePixel = 0
scriptPanel.ScrollBarThickness = 5
scriptPanel.ScrollBarImageColor3 = Config.colors.accent
scriptPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
scriptPanel.Parent = mainFrame

local scriptLayout = Instance.new("UIListLayout")
scriptLayout.SortOrder = Enum.SortOrder.LayoutOrder
scriptLayout.Padding = UDim.new(0, 6)
scriptLayout.Parent = scriptPanel

-- Mise à jour automatique du CanvasSize
scriptLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scriptPanel.CanvasSize = UDim2.new(0, 0, 0, scriptLayout.AbsoluteContentSize.Y + 10)
end)

-- CREATION DES SCRIPTS
-- ============================================================
-- SUB-FUNCTIONS for createScriptToggle (split to stay under
-- Lua's 200-register limit per function)
-- ============================================================

local scriptPanelUiConnections = {}

function trackScriptUiConnection(conn)
    table.insert(scriptPanelUiConnections, conn)
    return conn
end

function clearScriptPanelUiConnections()
    for _, conn in ipairs(scriptPanelUiConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    scriptPanelUiConnections = {}
end

function registerExpandedNavItem(container, target, activateFn, leftFn, rightFn, scrollParent, visualTarget)
    if not _G.LizardExpandedNav then _G.LizardExpandedNav = {} end
    if scrollParent and not scrollParent:GetAttribute("LizardNavScrollWatch") then
        scrollParent:SetAttribute("LizardNavScrollWatch", true)
        trackScriptUiConnection(scrollParent:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if gtaNav and gtaNav.visible and gtaRepaintSelectionBox then
                task.defer(function() gtaRepaintSelectionBox(false) end)
            end
        end))
    end
    table.insert(_G.LizardExpandedNav, {
        container = container,
        target = target,
        visualTarget = visualTarget or target,
        activate = activateFn,
        left = leftFn,
        right = rightFn,
        scrollParent = scrollParent,
    })
end

function clearExpandedNavItems()
    _G.LizardExpandedNav = {}
end

function createESPAllUI(scriptData, container)
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -30, 0, 100)
    settingsFrame.Position = UDim2.new(0, 15, 0, 60)
    settingsFrame.BackgroundColor3 = Config.colors.categoryBg
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Visible = stateAll.enabled
    settingsFrame.Parent = container
    Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 6)

    local alwaysOnTopButton = Instance.new("TextButton")
    alwaysOnTopButton.Size = UDim2.new(0, 20, 0, 20)
    alwaysOnTopButton.Position = UDim2.new(0, 10, 0, 5)
    alwaysOnTopButton.BackgroundColor3 = ESP_ALL_CONFIG.AlwaysOnTop and Config.colors.activeButton or Config.colors.inactiveButton
    alwaysOnTopButton.Text = ESP_ALL_CONFIG.AlwaysOnTop and "✓" or ""
    alwaysOnTopButton.TextColor3 = Config.colors.text
    alwaysOnTopButton.Font = Enum.Font.GothamBold
    alwaysOnTopButton.TextSize = 14
    alwaysOnTopButton.AutoButtonColor = false
    alwaysOnTopButton.Parent = settingsFrame
    Instance.new("UICorner", alwaysOnTopButton).CornerRadius = UDim.new(0, 4)
    local alwaysOnTopLabel = Instance.new("TextLabel")
    alwaysOnTopLabel.Size = UDim2.new(1, -40, 0, 20)
    alwaysOnTopLabel.Position = UDim2.new(0, 35, 0, 5)
    alwaysOnTopLabel.BackgroundTransparency = 1
    alwaysOnTopLabel.Text = "Always On Top (ignore walls)"
    alwaysOnTopLabel.TextColor3 = Config.colors.text
    alwaysOnTopLabel.Font = Enum.Font.Gotham
    alwaysOnTopLabel.TextSize = 11
    alwaysOnTopLabel.TextXAlignment = Enum.TextXAlignment.Left
    alwaysOnTopLabel.Parent = settingsFrame

    local showLabelsButton = Instance.new("TextButton")
    showLabelsButton.Size = UDim2.new(0, 20, 0, 20)
    showLabelsButton.Position = UDim2.new(0, 10, 0, 30)
    showLabelsButton.BackgroundColor3 = ESP_ALL_CONFIG.ShowTextLabels and Config.colors.activeButton or Config.colors.inactiveButton
    showLabelsButton.Text = ESP_ALL_CONFIG.ShowTextLabels and "✓" or ""
    showLabelsButton.TextColor3 = Config.colors.text
    showLabelsButton.Font = Enum.Font.GothamBold
    showLabelsButton.TextSize = 14
    showLabelsButton.AutoButtonColor = false
    showLabelsButton.Parent = settingsFrame
    Instance.new("UICorner", showLabelsButton).CornerRadius = UDim.new(0, 4)
    local showLabelsLabel = Instance.new("TextLabel")
    showLabelsLabel.Size = UDim2.new(1, -40, 0, 20)
    showLabelsLabel.Position = UDim2.new(0, 35, 0, 30)
    showLabelsLabel.BackgroundTransparency = 1
    showLabelsLabel.Text = "Show Name + Distance"
    showLabelsLabel.TextColor3 = Config.colors.text
    showLabelsLabel.Font = Enum.Font.Gotham
    showLabelsLabel.TextSize = 11
    showLabelsLabel.TextXAlignment = Enum.TextXAlignment.Left
    showLabelsLabel.Parent = settingsFrame

    -- Outline slider
    local outlineLabel = Instance.new("TextLabel")
    outlineLabel.Size = UDim2.new(0, 120, 0, 20)
    outlineLabel.Position = UDim2.new(0, 10, 0, 55)
    outlineLabel.BackgroundTransparency = 1
    outlineLabel.Text = "Outline: " .. math.floor((1 - ESP_ALL_CONFIG.OutlineTransparency) * 100) .. "%"
    outlineLabel.TextColor3 = Config.colors.text
    outlineLabel.Font = Enum.Font.Gotham
    outlineLabel.TextSize = 11
    outlineLabel.TextXAlignment = Enum.TextXAlignment.Left
    outlineLabel.Parent = settingsFrame
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0, 250, 0, 6)
    sliderBg.Position = UDim2.new(0, 135, 0, 62)
    sliderBg.BackgroundColor3 = Config.colors.inactiveButton
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = settingsFrame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(1 - ESP_ALL_CONFIG.OutlineTransparency, 0, 1, 0)
    sliderFill.BackgroundColor3 = Config.colors.activeButton
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 16, 0, 16)
    sliderButton.Position = UDim2.new(1 - ESP_ALL_CONFIG.OutlineTransparency, -8, 0.5, -8)
    sliderButton.BackgroundColor3 = Config.colors.text
    sliderButton.Text = ""
    sliderButton.AutoButtonColor = false
    sliderButton.Parent = sliderBg
    Instance.new("UICorner", sliderButton).CornerRadius = UDim.new(1, 0)
    local dragging = false
    sliderButton.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    trackScriptUiConnection(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            ESP_ALL_CONFIG.OutlineTransparency = 1 - r
            sliderFill.Size = UDim2.new(r, 0, 1, 0)
            sliderButton.Position = UDim2.new(r, -8, 0.5, -8)
            outlineLabel.Text = "Outline: " .. math.floor(r * 100) .. "%"
            if stateAll.enabled then refreshESPAll() end
        end
    end))
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    -- Fill slider
    local fillLabel = Instance.new("TextLabel")
    fillLabel.Size = UDim2.new(0, 120, 0, 20)
    fillLabel.Position = UDim2.new(0, 10, 0, 80)
    fillLabel.BackgroundTransparency = 1
    fillLabel.Text = "Fill: " .. math.floor((1 - ESP_ALL_CONFIG.FillTransparency) * 100) .. "%"
    fillLabel.TextColor3 = Config.colors.text
    fillLabel.Font = Enum.Font.Gotham
    fillLabel.TextSize = 11
    fillLabel.TextXAlignment = Enum.TextXAlignment.Left
    fillLabel.Parent = settingsFrame
    local sliderBgF = Instance.new("Frame")
    sliderBgF.Size = UDim2.new(0, 250, 0, 6)
    sliderBgF.Position = UDim2.new(0, 135, 0, 87)
    sliderBgF.BackgroundColor3 = Config.colors.inactiveButton
    sliderBgF.BorderSizePixel = 0
    sliderBgF.Parent = settingsFrame
    Instance.new("UICorner", sliderBgF).CornerRadius = UDim.new(1, 0)
    local sliderFillF = Instance.new("Frame")
    sliderFillF.Size = UDim2.new(1 - ESP_ALL_CONFIG.FillTransparency, 0, 1, 0)
    sliderFillF.BackgroundColor3 = Config.colors.activeButton
    sliderFillF.BorderSizePixel = 0
    sliderFillF.Parent = sliderBgF
    Instance.new("UICorner", sliderFillF).CornerRadius = UDim.new(1, 0)
    local sliderBtnF = Instance.new("TextButton")
    sliderBtnF.Size = UDim2.new(0, 16, 0, 16)
    sliderBtnF.Position = UDim2.new(1 - ESP_ALL_CONFIG.FillTransparency, -8, 0.5, -8)
    sliderBtnF.BackgroundColor3 = Config.colors.text
    sliderBtnF.Text = ""
    sliderBtnF.AutoButtonColor = false
    sliderBtnF.Parent = sliderBgF
    Instance.new("UICorner", sliderBtnF).CornerRadius = UDim.new(1, 0)
    local draggingF = false
    sliderBtnF.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingF = true end end)
    trackScriptUiConnection(UserInputService.InputChanged:Connect(function(i)
        if draggingF and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - sliderBgF.AbsolutePosition.X) / sliderBgF.AbsoluteSize.X, 0, 1)
            ESP_ALL_CONFIG.FillTransparency = 1 - r
            sliderFillF.Size = UDim2.new(r, 0, 1, 0)
            sliderBtnF.Position = UDim2.new(r, -8, 0.5, -8)
            fillLabel.Text = "Fill: " .. math.floor(r * 100) .. "%"
            if stateAll.enabled then refreshESPAll() end
        end
    end))
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingF = false end end)

    -- Buttons logic
    alwaysOnTopButton.MouseButton1Click:Connect(function()
        ESP_ALL_CONFIG.AlwaysOnTop = not ESP_ALL_CONFIG.AlwaysOnTop
        alwaysOnTopButton.BackgroundColor3 = ESP_ALL_CONFIG.AlwaysOnTop and Config.colors.activeButton or Config.colors.inactiveButton
        alwaysOnTopButton.Text = ESP_ALL_CONFIG.AlwaysOnTop and "✓" or ""
        if stateAll.enabled then refreshESPAll() end
    end)
    showLabelsButton.MouseButton1Click:Connect(function()
        ESP_ALL_CONFIG.ShowTextLabels = not ESP_ALL_CONFIG.ShowTextLabels
        showLabelsButton.BackgroundColor3 = ESP_ALL_CONFIG.ShowTextLabels and Config.colors.activeButton or Config.colors.inactiveButton
        showLabelsButton.Text = ESP_ALL_CONFIG.ShowTextLabels and "✓" or ""
        if stateAll.enabled then refreshESPAll() end
    end)

    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 90, 0, 32)
    toggleButton.Position = UDim2.new(1, -100, 0, 11)
    toggleButton.BackgroundColor3 = stateAll.enabled and Config.colors.activeButton or Config.colors.inactiveButton
    toggleButton.Text = stateAll.enabled and "ON" or "OFF"
    toggleButton.TextColor3 = Config.colors.text
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 11
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = container
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)
    toggleButton.MouseButton1Click:Connect(function()
        toggleESPAll()
        scriptData.active = stateAll.enabled
        if stateAll.enabled then
            container.Size = UDim2.new(1, -10, 0, 170)
            settingsFrame.Visible = true
            toggleButton.BackgroundColor3 = Config.colors.activeButton
            toggleButton.Text = "ON"
        else
            container.Size = UDim2.new(1, -10, 0, 55)
            settingsFrame.Visible = false
            toggleButton.BackgroundColor3 = Config.colors.inactiveButton
            toggleButton.Text = "OFF"
        end
    end)
end

function createESPTeamUI(scriptData, container)
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -30, 0, 135)
    settingsFrame.Position = UDim2.new(0, 15, 0, 60)
    settingsFrame.BackgroundColor3 = Config.colors.categoryBg
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Visible = stateTeam.enabled
    settingsFrame.Parent = container
    Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 6)

    local teamLabel = Instance.new("TextLabel")
    teamLabel.Size = UDim2.new(0, 60, 0, 25)
    teamLabel.Position = UDim2.new(0, 10, 0, 5)
    teamLabel.BackgroundTransparency = 1
    teamLabel.Text = "Target:"
    teamLabel.TextColor3 = Config.colors.text
    teamLabel.Font = Enum.Font.Gotham
    teamLabel.TextSize = 12
    teamLabel.TextXAlignment = Enum.TextXAlignment.Left
    teamLabel.Parent = settingsFrame

    local policeButton = Instance.new("TextButton")
    policeButton.Size = UDim2.new(0, 80, 0, 25)
    policeButton.Position = UDim2.new(0, 75, 0, 5)
    policeButton.BackgroundColor3 = TARGET_TEAM_NAME == "Police" and Config.colors.activeButton or Config.colors.inactiveButton
    policeButton.Text = "Police"
    policeButton.TextColor3 = Config.colors.text
    policeButton.Font = Enum.Font.GothamBold
    policeButton.TextSize = 11
    policeButton.AutoButtonColor = false
    policeButton.Parent = settingsFrame
    Instance.new("UICorner", policeButton).CornerRadius = UDim.new(0, 4)

    local civilianButton = Instance.new("TextButton")
    civilianButton.Size = UDim2.new(0, 80, 0, 25)
    civilianButton.Position = UDim2.new(0, 165, 0, 5)
    civilianButton.BackgroundColor3 = TARGET_TEAM_NAME == "Civilian" and Config.colors.activeButton or Config.colors.inactiveButton
    civilianButton.Text = "Civilian"
    civilianButton.TextColor3 = Config.colors.text
    civilianButton.Font = Enum.Font.GothamBold
    civilianButton.TextSize = 11
    civilianButton.AutoButtonColor = false
    civilianButton.Parent = settingsFrame
    Instance.new("UICorner", civilianButton).CornerRadius = UDim.new(0, 4)

    local alwaysOnTopButton = Instance.new("TextButton")
    alwaysOnTopButton.Size = UDim2.new(0, 20, 0, 20)
    alwaysOnTopButton.Position = UDim2.new(0, 10, 0, 35)
    alwaysOnTopButton.BackgroundColor3 = ESP_TEAM_CONFIG.AlwaysOnTop and Config.colors.activeButton or Config.colors.inactiveButton
    alwaysOnTopButton.Text = ESP_TEAM_CONFIG.AlwaysOnTop and "✓" or ""
    alwaysOnTopButton.TextColor3 = Config.colors.text
    alwaysOnTopButton.Font = Enum.Font.GothamBold
    alwaysOnTopButton.TextSize = 14
    alwaysOnTopButton.AutoButtonColor = false
    alwaysOnTopButton.Parent = settingsFrame
    Instance.new("UICorner", alwaysOnTopButton).CornerRadius = UDim.new(0, 4)
    local alwaysOnTopLabel = Instance.new("TextLabel")
    alwaysOnTopLabel.Size = UDim2.new(1, -40, 0, 20)
    alwaysOnTopLabel.Position = UDim2.new(0, 35, 0, 35)
    alwaysOnTopLabel.BackgroundTransparency = 1
    alwaysOnTopLabel.Text = "Always On Top"
    alwaysOnTopLabel.TextColor3 = Config.colors.text
    alwaysOnTopLabel.Font = Enum.Font.Gotham
    alwaysOnTopLabel.TextSize = 11
    alwaysOnTopLabel.TextXAlignment = Enum.TextXAlignment.Left
    alwaysOnTopLabel.Parent = settingsFrame

    local showLabelsButton = Instance.new("TextButton")
    showLabelsButton.Size = UDim2.new(0, 20, 0, 20)
    showLabelsButton.Position = UDim2.new(0, 10, 0, 60)
    showLabelsButton.BackgroundColor3 = ESP_TEAM_CONFIG.ShowTextLabels and Config.colors.activeButton or Config.colors.inactiveButton
    showLabelsButton.Text = ESP_TEAM_CONFIG.ShowTextLabels and "✓" or ""
    showLabelsButton.TextColor3 = Config.colors.text
    showLabelsButton.Font = Enum.Font.GothamBold
    showLabelsButton.TextSize = 14
    showLabelsButton.AutoButtonColor = false
    showLabelsButton.Parent = settingsFrame
    Instance.new("UICorner", showLabelsButton).CornerRadius = UDim.new(0, 4)
    local showLabelsLabel = Instance.new("TextLabel")
    showLabelsLabel.Size = UDim2.new(1, -40, 0, 20)
    showLabelsLabel.Position = UDim2.new(0, 35, 0, 60)
    showLabelsLabel.BackgroundTransparency = 1
    showLabelsLabel.Text = "Show Name + Distance"
    showLabelsLabel.TextColor3 = Config.colors.text
    showLabelsLabel.Font = Enum.Font.Gotham
    showLabelsLabel.TextSize = 11
    showLabelsLabel.TextXAlignment = Enum.TextXAlignment.Left
    showLabelsLabel.Parent = settingsFrame

    -- Outline slider
    local outlineLabel = Instance.new("TextLabel")
    outlineLabel.Size = UDim2.new(0, 120, 0, 20)
    outlineLabel.Position = UDim2.new(0, 10, 0, 85)
    outlineLabel.BackgroundTransparency = 1
    outlineLabel.Text = "Outline: " .. math.floor((1 - ESP_TEAM_CONFIG.OutlineTransparency) * 100) .. "%"
    outlineLabel.TextColor3 = Config.colors.text
    outlineLabel.Font = Enum.Font.Gotham
    outlineLabel.TextSize = 11
    outlineLabel.TextXAlignment = Enum.TextXAlignment.Left
    outlineLabel.Parent = settingsFrame
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0, 250, 0, 6)
    sliderBg.Position = UDim2.new(0, 135, 0, 92)
    sliderBg.BackgroundColor3 = Config.colors.inactiveButton
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = settingsFrame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(1 - ESP_TEAM_CONFIG.OutlineTransparency, 0, 1, 0)
    sliderFill.BackgroundColor3 = Config.colors.activeButton
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.Position = UDim2.new(1 - ESP_TEAM_CONFIG.OutlineTransparency, -8, 0.5, -8)
    sliderBtn.BackgroundColor3 = Config.colors.text
    sliderBtn.Text = ""
    sliderBtn.AutoButtonColor = false
    sliderBtn.Parent = sliderBg
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)
    local dragging = false
    sliderBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    trackScriptUiConnection(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            ESP_TEAM_CONFIG.OutlineTransparency = 1 - r
            sliderFill.Size = UDim2.new(r, 0, 1, 0)
            sliderBtn.Position = UDim2.new(r, -8, 0.5, -8)
            outlineLabel.Text = "Outline: " .. math.floor(r * 100) .. "%"
            if stateTeam.enabled then refreshESPTeam() end
        end
    end))
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    -- Fill slider
    local fillLabel = Instance.new("TextLabel")
    fillLabel.Size = UDim2.new(0, 120, 0, 20)
    fillLabel.Position = UDim2.new(0, 10, 0, 110)
    fillLabel.BackgroundTransparency = 1
    fillLabel.Text = "Fill: " .. math.floor((1 - ESP_TEAM_CONFIG.FillTransparency) * 100) .. "%"
    fillLabel.TextColor3 = Config.colors.text
    fillLabel.Font = Enum.Font.Gotham
    fillLabel.TextSize = 11
    fillLabel.TextXAlignment = Enum.TextXAlignment.Left
    fillLabel.Parent = settingsFrame
    local sliderBgF = Instance.new("Frame")
    sliderBgF.Size = UDim2.new(0, 250, 0, 6)
    sliderBgF.Position = UDim2.new(0, 135, 0, 117)
    sliderBgF.BackgroundColor3 = Config.colors.inactiveButton
    sliderBgF.BorderSizePixel = 0
    sliderBgF.Parent = settingsFrame
    Instance.new("UICorner", sliderBgF).CornerRadius = UDim.new(1, 0)
    local sliderFillF = Instance.new("Frame")
    sliderFillF.Size = UDim2.new(1 - ESP_TEAM_CONFIG.FillTransparency, 0, 1, 0)
    sliderFillF.BackgroundColor3 = Config.colors.activeButton
    sliderFillF.BorderSizePixel = 0
    sliderFillF.Parent = sliderBgF
    Instance.new("UICorner", sliderFillF).CornerRadius = UDim.new(1, 0)
    local sliderBtnF = Instance.new("TextButton")
    sliderBtnF.Size = UDim2.new(0, 16, 0, 16)
    sliderBtnF.Position = UDim2.new(1 - ESP_TEAM_CONFIG.FillTransparency, -8, 0.5, -8)
    sliderBtnF.BackgroundColor3 = Config.colors.text
    sliderBtnF.Text = ""
    sliderBtnF.AutoButtonColor = false
    sliderBtnF.Parent = sliderBgF
    Instance.new("UICorner", sliderBtnF).CornerRadius = UDim.new(1, 0)
    local draggingF = false
    sliderBtnF.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingF = true end end)
    trackScriptUiConnection(UserInputService.InputChanged:Connect(function(i)
        if draggingF and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - sliderBgF.AbsolutePosition.X) / sliderBgF.AbsoluteSize.X, 0, 1)
            ESP_TEAM_CONFIG.FillTransparency = 1 - r
            sliderFillF.Size = UDim2.new(r, 0, 1, 0)
            sliderBtnF.Position = UDim2.new(r, -8, 0.5, -8)
            fillLabel.Text = "Fill: " .. math.floor(r * 100) .. "%"
            if stateTeam.enabled then refreshESPTeam() end
        end
    end))
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingF = false end end)

    -- Button logic
    policeButton.MouseButton1Click:Connect(function()
        TARGET_TEAM_NAME = "Police"
        policeButton.BackgroundColor3 = Config.colors.activeButton
        civilianButton.BackgroundColor3 = Config.colors.inactiveButton
        if stateTeam.enabled then clearTeamESP() toggleESPTeam() end
    end)
    civilianButton.MouseButton1Click:Connect(function()
        TARGET_TEAM_NAME = "Civilian"
        civilianButton.BackgroundColor3 = Config.colors.activeButton
        policeButton.BackgroundColor3 = Config.colors.inactiveButton
        if stateTeam.enabled then clearTeamESP() toggleESPTeam() end
    end)
    alwaysOnTopButton.MouseButton1Click:Connect(function()
        ESP_TEAM_CONFIG.AlwaysOnTop = not ESP_TEAM_CONFIG.AlwaysOnTop
        alwaysOnTopButton.BackgroundColor3 = ESP_TEAM_CONFIG.AlwaysOnTop and Config.colors.activeButton or Config.colors.inactiveButton
        alwaysOnTopButton.Text = ESP_TEAM_CONFIG.AlwaysOnTop and "✓" or ""
        if stateTeam.enabled then refreshESPTeam() end
    end)
    showLabelsButton.MouseButton1Click:Connect(function()
        ESP_TEAM_CONFIG.ShowTextLabels = not ESP_TEAM_CONFIG.ShowTextLabels
        showLabelsButton.BackgroundColor3 = ESP_TEAM_CONFIG.ShowTextLabels and Config.colors.activeButton or Config.colors.inactiveButton
        showLabelsButton.Text = ESP_TEAM_CONFIG.ShowTextLabels and "✓" or ""
        if stateTeam.enabled then refreshESPTeam() end
    end)

    -- Toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 90, 0, 32)
    toggleButton.Position = UDim2.new(1, -100, 0, 11)
    toggleButton.BackgroundColor3 = stateTeam.enabled and Config.colors.activeButton or Config.colors.inactiveButton
    toggleButton.Text = stateTeam.enabled and "ON" or "OFF"
    toggleButton.TextColor3 = Config.colors.text
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 11
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = container
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)
    toggleButton.MouseButton1Click:Connect(function()
        toggleESPTeam()
        scriptData.active = stateTeam.enabled
        if stateTeam.enabled then
            container.Size = UDim2.new(1, -10, 0, 205)
            settingsFrame.Visible = true
            toggleButton.BackgroundColor3 = Config.colors.activeButton
            toggleButton.Text = "ON"
        else
            container.Size = UDim2.new(1, -10, 0, 55)
            settingsFrame.Visible = false
            toggleButton.BackgroundColor3 = Config.colors.inactiveButton
            toggleButton.Text = "OFF"
        end
    end)
end

function createGenericToggleUI(scriptData, container)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 90, 0, 32)
    toggleButton.Position = UDim2.new(1, -100, 0, 11)
    toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
    toggleButton.Text = scriptData.active and "ON" or "OFF"
    toggleButton.TextColor3 = Config.colors.text
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 11
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = container
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

    -- Click TP settings
    local settingsFrame = nil
    if scriptData.isClickTP then
        settingsFrame = Instance.new("Frame")
        settingsFrame.Size = UDim2.new(1, -30, 0, 35)
        settingsFrame.Position = UDim2.new(0, 15, 0, 60)
        settingsFrame.BackgroundColor3 = Config.colors.categoryBg
        settingsFrame.BorderSizePixel = 0
        settingsFrame.Visible = scriptData.active
        settingsFrame.Parent = container
        Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 6)
        local bypassButton = Instance.new("TextButton")
        bypassButton.Size = UDim2.new(0, 25, 0, 25)
        bypassButton.Position = UDim2.new(0, 10, 0.5, -12)
        bypassButton.BackgroundColor3 = bypassShield and Config.colors.activeButton or Config.colors.inactiveButton
        bypassButton.Text = bypassShield and "✓" or ""
        bypassButton.TextColor3 = Config.colors.text
        bypassButton.Font = Enum.Font.GothamBold
        bypassButton.TextSize = 16
        bypassButton.AutoButtonColor = false
        bypassButton.Parent = settingsFrame
        Instance.new("UICorner", bypassButton).CornerRadius = UDim.new(0, 4)
        local bypassLabel = Instance.new("TextLabel")
        bypassLabel.Size = UDim2.new(1, -45, 1, 0)
        bypassLabel.Position = UDim2.new(0, 45, 0, 0)
        bypassLabel.BackgroundTransparency = 1
        bypassLabel.Text = "Block TP in sky/void"
        bypassLabel.TextColor3 = Config.colors.text
        bypassLabel.Font = Enum.Font.Gotham
        bypassLabel.TextSize = 12
        bypassLabel.TextXAlignment = Enum.TextXAlignment.Left
        bypassLabel.Parent = settingsFrame
        bypassButton.MouseButton1Click:Connect(function()
            bypassShield = not bypassShield
            bypassButton.BackgroundColor3 = bypassShield and Config.colors.activeButton or Config.colors.inactiveButton
            bypassButton.Text = bypassShield and "✓" or ""
        end)
    end

    -- Fly speed settings
    local flySettingsFrame = nil
    if scriptData.isFly then
        flySettingsFrame = Instance.new("Frame")
        flySettingsFrame.Size = UDim2.new(1, -30, 0, 78)
        flySettingsFrame.Position = UDim2.new(0, 15, 0, 60)
        flySettingsFrame.BackgroundColor3 = Config.colors.categoryBg
        flySettingsFrame.BorderSizePixel = 0
        flySettingsFrame.Visible = scriptData.active
        flySettingsFrame.Parent = container
        Instance.new("UICorner", flySettingsFrame).CornerRadius = UDim.new(0, 6)
        local speedLabel = Instance.new("TextLabel", flySettingsFrame)
        speedLabel.Size = UDim2.new(0, 90, 0, 20)
        speedLabel.Position = UDim2.new(0, 10, 0, 5)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "Speed: " .. flySpeed
        speedLabel.TextColor3 = Config.colors.text
        speedLabel.Font = Enum.Font.Gotham
        speedLabel.TextSize = 12
        speedLabel.TextXAlignment = Enum.TextXAlignment.Left
        local sliderBg = Instance.new("Frame", flySettingsFrame)
        sliderBg.Size = UDim2.new(1, -115, 0, 6)
        sliderBg.Position = UDim2.new(0, 105, 0, 9)
        sliderBg.BackgroundColor3 = Config.colors.inactiveButton
        sliderBg.BorderSizePixel = 0
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
        local MIN_SPD, MAX_SPD = 10, 300
        local initR = (flySpeed - MIN_SPD) / (MAX_SPD - MIN_SPD)
        local sliderFill = Instance.new("Frame", sliderBg)
        sliderFill.Size = UDim2.new(initR, 0, 1, 0)
        sliderFill.BackgroundColor3 = Config.colors.activeButton
        sliderFill.BorderSizePixel = 0
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
        local sliderHandle = Instance.new("TextButton", sliderBg)
        sliderHandle.Size = UDim2.new(0, 16, 0, 16)
        sliderHandle.Position = UDim2.new(initR, -8, 0.5, -8)
        sliderHandle.BackgroundColor3 = Config.colors.text
        sliderHandle.Text = ""
        sliderHandle.AutoButtonColor = false
        Instance.new("UICorner", sliderHandle).CornerRadius = UDim.new(1, 0)
        local hintLabel = Instance.new("TextLabel", flySettingsFrame)
        hintLabel.Size = UDim2.new(1, -20, 0, 14)
        hintLabel.Position = UDim2.new(0, 10, 1, -18)
        hintLabel.BackgroundTransparency = 1
        hintLabel.Text = getFlyHintText()
        hintLabel.TextColor3 = Config.colors.textDim
        hintLabel.Font = Enum.Font.Gotham
        hintLabel.TextSize = 11
        hintLabel.TextXAlignment = Enum.TextXAlignment.Left

        local modeButton = Instance.new("TextButton", flySettingsFrame)
        modeButton.Size = UDim2.new(0, 20, 0, 20)
        modeButton.Position = UDim2.new(0, 10, 0, 28)
        modeButton.BackgroundColor3 = flyUseVelocityMode and Config.colors.activeButton or Config.colors.inactiveButton
        modeButton.Text = flyUseVelocityMode and "✓" or ""
        modeButton.TextColor3 = Config.colors.text
        modeButton.Font = Enum.Font.GothamBold
        modeButton.TextSize = 14
        modeButton.AutoButtonColor = false
        Instance.new("UICorner", modeButton).CornerRadius = UDim.new(0, 4)

        local modeLabel = Instance.new("TextLabel", flySettingsFrame)
        modeLabel.Size = UDim2.new(1, -40, 0, 20)
        modeLabel.Position = UDim2.new(0, 38, 0, 28)
        modeLabel.BackgroundTransparency = 1
        modeLabel.Text = "Velocity Mode"
        modeLabel.TextColor3 = Config.colors.text
        modeLabel.Font = Enum.Font.Gotham
        modeLabel.TextSize = 12
        modeLabel.TextXAlignment = Enum.TextXAlignment.Left

        local flyDragging = false
        sliderHandle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then flyDragging = true end
        end)
        trackScriptUiConnection(UserInputService.InputChanged:Connect(function(inp)
            if flyDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((inp.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                flySpeed = math.floor(MIN_SPD + rel * (MAX_SPD - MIN_SPD))
                sliderFill.Size = UDim2.new(rel, 0, 1, 0)
                sliderHandle.Position = UDim2.new(rel, -8, 0.5, -8)
                speedLabel.Text = "Speed: " .. flySpeed
            end
        end))
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then flyDragging = false end
        end)

        modeButton.MouseButton1Click:Connect(function()
            flyUseVelocityMode = not flyUseVelocityMode
            modeButton.BackgroundColor3 = flyUseVelocityMode and Config.colors.activeButton or Config.colors.inactiveButton
            modeButton.Text = flyUseVelocityMode and "✓" or ""

            if scriptData.active then
                toggleFly(false)
                toggleFly(true)
            end
        end)
    end

    toggleButton.MouseButton1Click:Connect(function()
        scriptData.active = not scriptData.active
        toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
        toggleButton.Text = scriptData.active and "ON" or "OFF"

        if scriptData.isClickTP then
            container.Size = UDim2.new(1, -10, 0, scriptData.active and 105 or 55)
            if settingsFrame then settingsFrame.Visible = scriptData.active end
        end
        if scriptData.isFly then
            container.Size = UDim2.new(1, -10, 0, scriptData.active and 148 or 55)
            if flySettingsFrame then flySettingsFrame.Visible = scriptData.active end
        end
        if scriptData.isHitboxExpander then
            local newState = headState.enabled
            container.Size = UDim2.new(1, -10, 0, newState and 227 or 55)
        end

        -- Dispatch
        if scriptData.isClickTP then toggleClickTP(scriptData.active) end
        if scriptData.isFly then toggleFly(scriptData.active) end
        if scriptData.isSafeRob then toggleSafeRob(scriptData.active) end
        if scriptData.isInvisibility then toggleInvisibilitySystem(scriptData.active) end
        if scriptData.isNoProps then toggleNoProps(scriptData.active) end
        if scriptData.isInfAmmo then toggleInfAmmo(scriptData.active) end
        if scriptData.isBypassAll then toggleBypassAll(scriptData.active) end
        if scriptData.isCarNoDamage then toggleCarNoDamage(scriptData.active) end
        if scriptData.isAtmHack then toggleAtmHack(scriptData.active) end
        if scriptData.isAutoATM then toggleAutoATM(scriptData.active) end
        if scriptData.isRemoveRedSpeed then toggleRedLightSpeed(scriptData.active) end
        if scriptData.isInfZoom then toggleInfZoom(scriptData.active) end
        if scriptData.isInstantInteract then toggleInstantInteract(scriptData.active) end
        if scriptData.isGolfFarm then toggleGolfFarm(scriptData.active) end
        if scriptData.isInfStats then toggleInfStats(scriptData.active) end
        if scriptData.isAvoidDeath then toggleAvoidDeath(scriptData.active) end
        if scriptData.isAntiArrest then toggleAntiArrest(scriptData.active) end
        if scriptData.isHouseAntiKick then toggleHouseAntiKick(scriptData.active) end
        if scriptData.isExpandCuffs then toggleExpandCuffs(scriptData.active) end
        if scriptData.isChangeAVS then toggleChangeAVS(scriptData.active) end
        if scriptData.isUGCEmotes then
            runUGCEmotes()
            scriptData.active = false
            toggleButton.BackgroundColor3 = Config.colors.inactiveButton
            toggleButton.Text = "OFF"
        end
    end)
end

function createAimbotUI(scriptData, container)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 76, 0, 28)
    toggleButton.Position = UDim2.new(1, -86, 0, 8)
    toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
    toggleButton.Text = scriptData.active and "ON" or "OFF"
    toggleButton.TextColor3 = Config.colors.text
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 11
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = container
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

    scriptData.optionsCollapsed = scriptData.optionsCollapsed == true
    local optionsButton = Instance.new("TextButton")
    optionsButton.Size = UDim2.new(0, 86, 0, 28)
    optionsButton.Position = UDim2.new(1, -180, 0, 8)
    optionsButton.BackgroundColor3 = Config.colors.inactiveButton
    optionsButton.TextColor3 = Config.colors.accent
    optionsButton.Font = Enum.Font.GothamBold
    optionsButton.TextSize = 10
    optionsButton.AutoButtonColor = false
    optionsButton.Visible = scriptData.active
    optionsButton.Parent = container
    Instance.new("UICorner", optionsButton).CornerRadius = UDim.new(0, 6)

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, -24, 0, 356)
    panel.Position = UDim2.new(0, 12, 0, 48)
    panel.BackgroundColor3 = Config.colors.categoryBg
    panel.BorderSizePixel = 0
    panel.Visible = scriptData.active
    panel.Parent = container
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, -18, 0, 22)
    title.Position = UDim2.new(0, 9, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "AIMBOT"
    title.TextColor3 = Config.colors.accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left

    local function makeLabel(text, y)
        local row = Instance.new("Frame", panel)
        row.Size = UDim2.new(1, -18, 0, 23)
        row.Position = UDim2.new(0, 9, 0, y - 2)
        row.BackgroundColor3 = Config.colors.scriptBg
        row.BorderSizePixel = 0
        row.ZIndex = 1
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", panel)
        lbl.Size = UDim2.new(1, -126, 0, 20)
        lbl.Position = UDim2.new(0, 20, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Config.colors.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 2
        return lbl, row
    end

    local function makeToggle(text, y, getValue, setValue)
        local _, row = makeLabel(text, y)
        local btn = Instance.new("TextButton", panel)
        btn.Size = UDim2.new(0, 22, 0, 22)
        btn.Position = UDim2.new(1, -32, 0, y - 1)
        btn.BackgroundColor3 = getValue() and Config.colors.activeButton or Config.colors.inactiveButton
        btn.Text = getValue() and "✓" or ""
        btn.TextColor3 = Config.colors.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            setValue(not getValue())
            btn.BackgroundColor3 = getValue() and Config.colors.activeButton or Config.colors.inactiveButton
            btn.Text = getValue() and "✓" or ""
        end)
        registerExpandedNavItem(container, btn, function()
            setValue(not getValue())
            btn.BackgroundColor3 = getValue() and Config.colors.activeButton or Config.colors.inactiveButton
            btn.Text = getValue() and "ON" or ""
        end, nil, nil, nil, row)
    end

    local function makeCycle(text, y, values, getValue, setValue)
        local _, row = makeLabel(text, y)
        local btn = Instance.new("TextButton", panel)
        btn.Size = UDim2.new(0, 104, 0, 22)
        btn.Position = UDim2.new(1, -114, 0, y - 1)
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = Config.colors.inactiveButton
        btn.TextColor3 = Config.colors.accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Center
        btn.Text = tostring(getValue())
        btn.AutoButtonColor = false
        btn.ZIndex = 3
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local function cycle(delta)
            local current = getValue()
            local nextIndex = 1
            for i, v in ipairs(values) do
                if v == current then nextIndex = ((i - 1 + delta) % #values) + 1 break end
            end
            setValue(values[nextIndex])
            btn.Text = tostring(getValue())
        end
        btn.MouseButton1Click:Connect(function() cycle(1) end)
        registerExpandedNavItem(container, btn, function() cycle(1) end, function() cycle(-1) end, function() cycle(1) end, nil, row)
        return btn
    end

    local function makeNumber(text, y, getValue, setValue)
        makeLabel(text, y)
        local box = Instance.new("TextBox", panel)
        box.Size = UDim2.new(0, 64, 0, 22)
        box.Position = UDim2.new(1, -74, 0, y - 1)
        box.BackgroundColor3 = Config.colors.inactiveButton
        box.TextColor3 = Config.colors.accent
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.Text = tostring(getValue())
        box.ClearTextOnFocus = false
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then setValue(n) end
            box.Text = tostring(getValue())
        end)
    end

    local function makeSlider(text, y, minValue, maxValue, getValue, setValue, formatValue)
        local lbl, row = makeLabel(text, y)
        local sliderBg = Instance.new("Frame", panel)
        sliderBg.Size = UDim2.new(0, 112, 0, 6)
        sliderBg.Position = UDim2.new(1, -124, 0, y + 7)
        sliderBg.BackgroundColor3 = Config.colors.inactiveButton
        sliderBg.BorderSizePixel = 0
        sliderBg.ZIndex = 3
        Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", sliderBg)
        fill.BackgroundColor3 = Config.colors.activeButton
        fill.BorderSizePixel = 0
        fill.ZIndex = 4
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local handle = Instance.new("TextButton", sliderBg)
        handle.Size = UDim2.new(0, 14, 0, 14)
        handle.BackgroundColor3 = Config.colors.text
        handle.Text = ""
        handle.AutoButtonColor = false
        handle.ZIndex = 5
        Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

        local function updateVisual()
            local value = math.clamp(getValue(), minValue, maxValue)
            local rel = (value - minValue) / (maxValue - minValue)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            handle.Position = UDim2.new(rel, -7, 0.5, -7)
            lbl.Text = text .. ": " .. (formatValue and formatValue(value) or tostring(value))
        end

        local dragging = false
        local function applyFromX(x)
            local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            setValue(minValue + (maxValue - minValue) * rel)
            updateVisual()
        end
        local function step(delta)
            setValue(math.clamp(getValue() + delta, minValue, maxValue))
            updateVisual()
        end

        handle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        sliderBg.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                applyFromX(inp.Position.X)
            end
        end)
        trackScriptUiConnection(UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                applyFromX(inp.Position.X)
            end
        end))
        trackScriptUiConnection(UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end))
        updateVisual()
        local stepSize = text == "Fov Radius" and 10 or (text == "Prediction" and 0.05 or 1)
        registerExpandedNavItem(container, sliderBg, nil, function() step(-stepSize) end, function() step(stepSize) end, nil, row)
    end

    local function makeSection(text, y)
        local lbl = Instance.new("TextLabel", panel)
        lbl.Size = UDim2.new(1, -18, 0, 20)
        lbl.Position = UDim2.new(0, 9, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Config.colors.accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function makeAimFilterList(title, names, selectedSet, yPos)
        local holder = Instance.new("Frame", panel)
        holder.Size = UDim2.new(1, -18, 0, 126)
        holder.Position = UDim2.new(0, 9, 0, yPos)
        holder.BackgroundColor3 = Config.colors.scriptBg
        holder.BorderSizePixel = 0
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

        local titleLabel = Instance.new("TextLabel", holder)
        titleLabel.Size = UDim2.new(1, -18, 0, 20)
        titleLabel.Position = UDim2.new(0, 9, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Config.colors.accent
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 11
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local function setAll(value)
            for _, n in ipairs(names) do selectedSet[n] = value and true or nil end
            task.defer(refreshScripts)
        end

        local function bulkButton(text, xScale, callback)
            local btn = Instance.new("TextButton", holder)
            btn.Size = UDim2.new(0.5, -14, 0, 22)
            btn.Position = UDim2.new(xScale, xScale == 0 and 8 or 6, 0, 26)
            btn.BackgroundColor3 = Config.colors.inactiveButton
            btn.Text = text
            btn.TextColor3 = Config.colors.text
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(callback)
            registerExpandedNavItem(container, btn, callback)
        end

        bulkButton("Select All", 0, function() setAll(true) end)
        bulkButton("Unselect All", 0.5, function() setAll(false) end)

        local list = Instance.new("ScrollingFrame", holder)
        list.Size = UDim2.new(1, -16, 0, 68)
        list.Position = UDim2.new(0, 8, 0, 52)
        list.BackgroundColor3 = Config.colors.categoryBg
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 4
        list.ScrollBarImageColor3 = Config.colors.accent
        list.CanvasSize = UDim2.new(0, 0, 0, 0)
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
        local layout = Instance.new("UIListLayout", list)
        layout.Padding = UDim.new(0, 3)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
        end)

        if #names == 0 then
            local empty = Instance.new("TextLabel", list)
            empty.Size = UDim2.new(1, -8, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "Nothing to select right now."
            empty.TextColor3 = Config.colors.text
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
        end

        for _, n in ipairs(names) do
            local row = Instance.new("TextButton", list)
            row.Size = UDim2.new(1, -8, 0, 23)
            row.BackgroundColor3 = selectedSet[n] and Config.colors.activeButton or Config.colors.inactiveButton
            row.Text = n
            row.TextColor3 = Config.colors.text
            row.Font = Enum.Font.Gotham
            row.TextSize = 10
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.Parent = list
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            local pad = Instance.new("UIPadding", row)
            pad.PaddingLeft = UDim.new(0, 8)
            local function toggle()
                selectedSet[n] = not selectedSet[n] or nil
                row.BackgroundColor3 = selectedSet[n] and Config.colors.activeButton or Config.colors.inactiveButton
            end
            row.MouseButton1Click:Connect(toggle)
            registerExpandedNavItem(container, row, toggle, nil, nil, list)
        end
    end

    local function showAimBindCapture(button)
        local gui = Instance.new("ScreenGui", playerGui)
        gui.Name = "AimbotBindCapture"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 1000000015
        local popup = Instance.new("Frame", gui)
        popup.Size = UDim2.new(0, 220, 0, 54)
        popup.Position = UDim2.new(0.5, -110, 0.5, -27)
        popup.BackgroundColor3 = Config.colors.categoryBg
        popup.BackgroundTransparency = 1
        popup.BorderSizePixel = 0
        Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 9)
        local stroke = Instance.new("UIStroke", popup)
        stroke.Color = Config.colors.accent
        stroke.Transparency = 1
        stroke.Thickness = 1.2
        local label = Instance.new("TextLabel", popup)
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "waiting for input..."
        label.TextColor3 = Config.colors.text
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        TweenService:Create(popup, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Escape then
                conn:Disconnect()
                gui:Destroy()
                return
            end
            if aimSetToggleFromInput(input) then
                button.Text = aimFormatToggleKey()
                conn:Disconnect()
                gui:Destroy()
            end
        end)
    end

    local aimBindButton = makeCycle("Aimbot Toggle Key", 32, {AIMBOT_CONFIG.toggleKey}, function() return aimFormatToggleKey() end, function() end)
    aimBindButton.MouseButton1Click:Connect(function()
        showAimBindCapture(aimBindButton)
    end)
    makeCycle("Aimbot Method", 56, {"Camera"}, function() return AIMBOT_CONFIG.method end, function(v) AIMBOT_CONFIG.method = v end)
    makeCycle("Target Part", 80, {"Head", "Torso", "HumanoidRootPart"}, function() return AIMBOT_CONFIG.targetPart end, function(v) AIMBOT_CONFIG.targetPart = v end)
    makeCycle("Target Type", 104, {"Players", "NPCs", "Players + NPCs"}, function() return AIMBOT_CONFIG.targetScope end, function(v) AIMBOT_CONFIG.targetScope = v; aimState.cachedTargetChar = nil; aimState.cachedTargetPart = nil; aimState.nextTargetScan = 0 end)
    makeCycle("Aimbot Mode", 128, {"Hold", "Toggle"}, function() return AIMBOT_CONFIG.mode end, function(v) AIMBOT_CONFIG.mode = v; aimState.holding = false; aimState.locked = false end)
    makeToggle("Aimbot Wallcheck", 160, function() return AIMBOT_CONFIG.wallCheck end, function(v) AIMBOT_CONFIG.wallCheck = v end)
    makeToggle("Aimbot Team Check", 184, function() return AIMBOT_CONFIG.teamCheck end, function(v) AIMBOT_CONFIG.teamCheck = v end)
    makeToggle("Use Smoothing", 208, function() return AIMBOT_CONFIG.smoothingEnabled end, function(v) AIMBOT_CONFIG.smoothingEnabled = v end)
    makeSlider("Smoothness", 232, 1, 50, function() return AIMBOT_CONFIG.smoothness end, function(v) AIMBOT_CONFIG.smoothness = math.floor(v + 0.5) end, function(v) return tostring(math.floor(v + 0.5)) end)
    makeToggle("Use Prediction", 256, function() return AIMBOT_CONFIG.predictionEnabled end, function(v) AIMBOT_CONFIG.predictionEnabled = v end)
    makeSlider("Prediction", 280, 0, 2, function() return AIMBOT_CONFIG.prediction end, function(v) AIMBOT_CONFIG.prediction = math.floor(v * 100 + 0.5) / 100 end, function(v) return string.format("%.2f", v) end)
    makeToggle("Aimbot Distance Check", 304, function() return AIMBOT_CONFIG.distanceCheck end, function(v) AIMBOT_CONFIG.distanceCheck = v end)
    makeNumber("Max Distance", 328, function() return AIMBOT_CONFIG.maxDistance end, function(v) AIMBOT_CONFIG.maxDistance = math.max(1, v) end)

    makeSection("FILTER", 360)
    makeCycle("Filter Mode", 384, {"None", "Disable only for", "Enable only for"}, function() return AIMBOT_CONFIG.filterMode end, function(v) AIMBOT_CONFIG.filterMode = v; task.defer(refreshScripts) end)
    makeCycle("Filter Category", 408, {"Teams", "Players"}, function() return AIMBOT_CONFIG.filterCategory end, function(v) AIMBOT_CONFIG.filterCategory = v; task.defer(refreshScripts) end)
    local aimFilterEnd = 438
    if AIMBOT_CONFIG.filterMode ~= "None" then
        local names, seen = {}, {}
        if AIMBOT_CONFIG.filterCategory == "Teams" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Team then local n = p.Team.Name; if not seen[n] then seen[n] = true; table.insert(names, n) end end
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
        end
        table.sort(names)
        local selectedSet
        if AIMBOT_CONFIG.filterMode == "Enable only for" then
            selectedSet = AIMBOT_CONFIG.filterCategory == "Teams" and AIMBOT_CONFIG.onlyTeams or AIMBOT_CONFIG.onlyPlayers
        else
            selectedSet = AIMBOT_CONFIG.filterCategory == "Teams" and AIMBOT_CONFIG.disabledTeams or AIMBOT_CONFIG.disabledPlayers
        end
        makeAimFilterList(AIMBOT_CONFIG.filterCategory == "Teams" and "Teams List" or "Players List", names, selectedSet, 436)
        aimFilterEnd = 570
    end
    panel.Size = UDim2.new(1, -24, 0, aimFilterEnd)

    local fovPanel = Instance.new("Frame", container)
    fovPanel.Size = UDim2.new(1, -24, 0, 106)
    fovPanel.Position = UDim2.new(0, 12, 0, aimFilterEnd + 12)
    fovPanel.BackgroundColor3 = Config.colors.categoryBg
    fovPanel.BorderSizePixel = 0
    fovPanel.Visible = scriptData.active
    Instance.new("UICorner", fovPanel).CornerRadius = UDim.new(0, 8)

    local fovTitle = Instance.new("TextLabel", fovPanel)
    fovTitle.Size = UDim2.new(1, -18, 0, 22)
    fovTitle.Position = UDim2.new(0, 9, 0, 4)
    fovTitle.BackgroundTransparency = 1
    fovTitle.Text = "FOV CIRCLE"
    fovTitle.TextColor3 = Config.colors.accent
    fovTitle.Font = Enum.Font.GothamBold
    fovTitle.TextSize = 11
    fovTitle.TextXAlignment = Enum.TextXAlignment.Left

    local oldPanel = panel
    panel = fovPanel
    makeToggle("Fov Circle", 32, function() return AIMBOT_CONFIG.fovEnabled end, function(v) AIMBOT_CONFIG.fovEnabled = v end)
    makeSlider("Fov Radius", 56, 40, 500, function() return AIMBOT_CONFIG.fovRadius end, function(v) AIMBOT_CONFIG.fovRadius = math.floor(v + 0.5) end, function(v) return tostring(math.floor(v + 0.5)) end)
    makeCycle("Fov Color", 80, {"White", "Accent", "Red", "Green", "Blue"}, function()
        return AIMBOT_CONFIG.fovColorName or "White"
    end, function(v)
        AIMBOT_CONFIG.fovColorName = v
        local colors = {
            White = Color3.fromRGB(255, 255, 255),
            Accent = Config.colors.accent,
            Red = Color3.fromRGB(255, 70, 70),
            Green = Color3.fromRGB(90, 255, 120),
            Blue = Color3.fromRGB(90, 160, 255),
        }
        AIMBOT_CONFIG.fovColor = colors[v] or colors.White
    end)
    panel = oldPanel

    local function updateAimbotLayout()
        local expanded = scriptData.active and not scriptData.optionsCollapsed
        panel.Visible = expanded
        fovPanel.Visible = expanded
        optionsButton.Visible = scriptData.active
        optionsButton.Text = scriptData.optionsCollapsed and "OPTIONS >" or "OPTIONS v"
        container.Size = UDim2.new(1, -10, 0, scriptData.active and (expanded and (aimFilterEnd + 130) or 84) or 44)
        if not expanded and gtaNav then gtaNav.optionIndex = nil end
        if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
    end

    optionsButton.MouseButton1Click:Connect(function()
        scriptData.optionsCollapsed = not scriptData.optionsCollapsed
        updateAimbotLayout()
    end)
    registerExpandedNavItem(container, optionsButton, function()
        scriptData.optionsCollapsed = not scriptData.optionsCollapsed
        updateAimbotLayout()
    end)

    toggleButton.MouseButton1Click:Connect(function()
        scriptData.active = not scriptData.active
        toggleAimbot(scriptData.active)
        toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
        toggleButton.Text = scriptData.active and "ON" or "OFF"
        updateAimbotLayout()
    end)
    updateAimbotLayout()
end

function createAdvancedESPUI(scriptData, container)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 76, 0, 28)
    toggleButton.Position = UDim2.new(1, -86, 0, 8)
    toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
    toggleButton.Text = scriptData.active and "ON" or "OFF"
    toggleButton.TextColor3 = Config.colors.text
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 11
    toggleButton.AutoButtonColor = false
    toggleButton.Parent = container
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

    scriptData.optionsCollapsed = scriptData.optionsCollapsed == true
    local optionsButton = Instance.new("TextButton", container)
    optionsButton.Size = UDim2.new(0, 86, 0, 28)
    optionsButton.Position = UDim2.new(1, -180, 0, 8)
    optionsButton.BackgroundColor3 = Config.colors.inactiveButton
    optionsButton.TextColor3 = Config.colors.accent
    optionsButton.Font = Enum.Font.GothamBold
    optionsButton.TextSize = 10
    optionsButton.AutoButtonColor = false
    optionsButton.Visible = scriptData.active
    Instance.new("UICorner", optionsButton).CornerRadius = UDim.new(0, 6)

    local panel = Instance.new("Frame", container)
    panel.Size = UDim2.new(1, -24, 0, 1100)
    panel.Position = UDim2.new(0, 12, 0, 48)
    panel.BackgroundColor3 = Config.colors.categoryBg
    panel.BorderSizePixel = 0
    panel.Visible = scriptData.active
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

    local y = 8
    local function section(name)
        local lbl = Instance.new("TextLabel", panel)
        lbl.Size = UDim2.new(1, -18, 0, 22)
        lbl.Position = UDim2.new(0, 9, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Config.colors.accent
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        y = y + 26
    end
    local function rowBase(text)
        local row = Instance.new("Frame", panel)
        row.Size = UDim2.new(1, -18, 0, 23)
        row.Position = UDim2.new(0, 9, 0, y)
        row.BackgroundColor3 = Config.colors.scriptBg
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -130, 1, 0)
        lbl.Position = UDim2.new(0, 9, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Config.colors.text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        y = y + 25
        return row, lbl
    end
    local function refresh() advEspRefreshAll() end
    local function toggleRow(text, get, set)
        local row = rowBase(text)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 24, 0, 19)
        btn.Position = UDim2.new(1, -30, 0.5, -9)
        btn.BackgroundColor3 = get() and Config.colors.activeButton or Config.colors.inactiveButton
        btn.Text = get() and "ON" or ""
        btn.TextColor3 = Config.colors.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local function flip()
            set(not get())
            btn.BackgroundColor3 = get() and Config.colors.activeButton or Config.colors.inactiveButton
            btn.Text = get() and "ON" or ""
            refresh()
        end
        btn.MouseButton1Click:Connect(flip)
        registerExpandedNavItem(container, row, flip)
    end
    local function cycleRow(text, values, get, set)
        local row = rowBase(text)
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 112, 0, 19)
        btn.Position = UDim2.new(1, -118, 0.5, -9)
        btn.BackgroundColor3 = Config.colors.inactiveButton
        btn.TextColor3 = Config.colors.accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.Text = tostring(get())
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local function cyc(delta)
            local cur = get()
            local ni = 1
            for i, v in ipairs(values) do if v == cur then ni = ((i - 1 + delta) % #values) + 1 break end end
            set(values[ni])
            btn.Text = tostring(get())
            refresh()
        end
        btn.MouseButton1Click:Connect(function() cyc(1) end)
        registerExpandedNavItem(container, row, function() cyc(1) end, function() cyc(-1) end, function() cyc(1) end)
    end
    local function sliderRow(text, minV, maxV, stepV, get, set)
        local row, lbl = rowBase(text)
        local bg = Instance.new("Frame", row)
        bg.Size = UDim2.new(0, 112, 0, 6)
        bg.Position = UDim2.new(1, -120, 0.5, -3)
        bg.BackgroundColor3 = Config.colors.inactiveButton
        bg.BorderSizePixel = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame", bg)
        fill.BackgroundColor3 = Config.colors.activeButton
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local function upd()
            local v = math.clamp(get(), minV, maxV)
            fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
            lbl.Text = text .. ": " .. tostring(v)
        end
        local function setX(x)
            local rel = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            set(math.floor((minV + (maxV - minV) * rel) / stepV + 0.5) * stepV)
            upd(); refresh()
        end
        local drag = false
        bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; setX(i.Position.X) end end)
        trackScriptUiConnection(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then setX(i.Position.X) end end))
        trackScriptUiConnection(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
        registerExpandedNavItem(container, row, nil, function() set(math.clamp(get() - stepV, minV, maxV)); upd(); refresh() end, function() set(math.clamp(get() + stepV, minV, maxV)); upd(); refresh() end)
        upd()
    end
    local colorNames = {"White","Theme","Red","Green","Blue"}
    local colorMap = {White = Color3.fromRGB(255,255,255), Theme = Config.colors.accent, Red = Color3.fromRGB(255,70,70), Green = Color3.fromRGB(90,255,120), Blue = Color3.fromRGB(90,160,255)}
    local function colorRow(label, key, labelKey)
        cycleRow(label, colorNames, function() return ADV_ESP_CONFIG[labelKey] or "White" end, function(v) ADV_ESP_CONFIG[labelKey] = v; ADV_ESP_CONFIG[key] = colorMap[v] or colorMap.White end)
    end
    local function filterSelectionList(title, names, selectedSet)
        local holder = Instance.new("Frame", panel)
        holder.Size = UDim2.new(1, -18, 0, 144)
        holder.Position = UDim2.new(0, 9, 0, y)
        holder.BackgroundColor3 = Config.colors.scriptBg
        holder.BorderSizePixel = 0
        Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 7)

        local titleLabel = Instance.new("TextLabel", holder)
        titleLabel.Size = UDim2.new(1, -18, 0, 22)
        titleLabel.Position = UDim2.new(0, 9, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Config.colors.accent
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 11
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local function bulkButton(text, xScale, callback)
            local btn = Instance.new("TextButton", holder)
            btn.Size = UDim2.new(0.5, -14, 0, 22)
            btn.Position = UDim2.new(xScale, xScale == 0 and 8 or 6, 0, 28)
            btn.BackgroundColor3 = Config.colors.inactiveButton
            btn.Text = text
            btn.TextColor3 = Config.colors.text
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 10
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(callback)
            registerExpandedNavItem(container, btn, callback)
        end

        local function setAll(value)
            for _, n in ipairs(names) do selectedSet[n] = value and true or nil end
            refresh()
            task.defer(refreshScripts)
        end
        bulkButton("Select All", 0, function() setAll(true) end)
        bulkButton("Unselect All", 0.5, function() setAll(false) end)

        local list = Instance.new("ScrollingFrame", holder)
        list.Size = UDim2.new(1, -16, 0, 82)
        list.Position = UDim2.new(0, 8, 0, 56)
        list.BackgroundColor3 = Config.colors.categoryBg
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 4
        list.ScrollBarImageColor3 = Config.colors.accent
        list.CanvasSize = UDim2.new(0, 0, 0, 0)
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
        local layout = Instance.new("UIListLayout", list)
        layout.Padding = UDim.new(0, 3)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
        end)

        if #names == 0 then
            local empty = Instance.new("TextLabel", list)
            empty.Size = UDim2.new(1, -8, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "Nothing to select right now."
            empty.TextColor3 = Config.colors.text
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
        end

        for _, n in ipairs(names) do
            local row = Instance.new("TextButton", list)
            row.Size = UDim2.new(1, -8, 0, 23)
            row.BackgroundColor3 = selectedSet[n] and Config.colors.activeButton or Config.colors.inactiveButton
            row.Text = n
            row.TextColor3 = Config.colors.text
            row.Font = Enum.Font.Gotham
            row.TextSize = 10
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.Parent = list
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            local pad = Instance.new("UIPadding", row)
            pad.PaddingLeft = UDim.new(0, 8)
            local function toggle()
                selectedSet[n] = not selectedSet[n] or nil
                row.BackgroundColor3 = selectedSet[n] and Config.colors.activeButton or Config.colors.inactiveButton
                refresh()
            end
            row.MouseButton1Click:Connect(toggle)
            registerExpandedNavItem(container, row, toggle, nil, nil, list)
        end
        y = y + 150
    end

    section("GENERAL"); cycleRow("Target Type", {"Players","NPCs","Players + NPCs"}, function() return ADV_ESP_CONFIG.targetScope end, function(v) ADV_ESP_CONFIG.targetScope = v; advEspRefreshAll() end); toggleRow("Performance Mode", function() return ADV_ESP_CONFIG.performanceMode end, function(v) ADV_ESP_CONFIG.performanceMode = v end); sliderRow("Max Distance", 100, 3000, 100, function() return ADV_ESP_CONFIG.maxDistance end, function(v) ADV_ESP_CONFIG.maxDistance = v end)
    section("BOX"); toggleRow("Enable Box ESP", function() return ADV_ESP_CONFIG.boxEnabled end, function(v) ADV_ESP_CONFIG.boxEnabled = v end); sliderRow("Box Thickness", 1, 5, 1, function() return ADV_ESP_CONFIG.boxThickness end, function(v) ADV_ESP_CONFIG.boxThickness = v end); colorRow("Box Color", "boxColor", "boxColorName")
    section("SKELETON"); toggleRow("Enable Skeleton", function() return ADV_ESP_CONFIG.skeletonEnabled end, function(v) ADV_ESP_CONFIG.skeletonEnabled = v end); sliderRow("Skeleton Thickness", 1, 5, 1, function() return ADV_ESP_CONFIG.skeletonThickness end, function(v) ADV_ESP_CONFIG.skeletonThickness = v end); colorRow("Skeleton Color", "skeletonColor", "skeletonColorName")
    section("LOOK ARROW"); toggleRow("Show Look Direction", function() return ADV_ESP_CONFIG.lookArrowEnabled end, function(v) ADV_ESP_CONFIG.lookArrowEnabled = v end); sliderRow("Look Arrow Length", 2, 30, 1, function() return ADV_ESP_CONFIG.lookArrowLength end, function(v) ADV_ESP_CONFIG.lookArrowLength = v end); sliderRow("Look Arrow Thickness", 1, 5, 1, function() return ADV_ESP_CONFIG.lookArrowThickness end, function(v) ADV_ESP_CONFIG.lookArrowThickness = v end); sliderRow("Look Arrow Head Size", 4, 24, 1, function() return ADV_ESP_CONFIG.lookArrowHeadSize end, function(v) ADV_ESP_CONFIG.lookArrowHeadSize = v end); colorRow("Look Arrow Color", "lookArrowColor", "lookArrowColorName")
    section("TEXT"); toggleRow("Show Name", function() return ADV_ESP_CONFIG.showName end, function(v) ADV_ESP_CONFIG.showName = v end); cycleRow("Name Mode", {"Username","Display"}, function() return ADV_ESP_CONFIG.nameMode end, function(v) ADV_ESP_CONFIG.nameMode = v end); toggleRow("Show Distance", function() return ADV_ESP_CONFIG.showDistance end, function(v) ADV_ESP_CONFIG.showDistance = v end); cycleRow("Distance Mode", {"Camera","Player"}, function() return ADV_ESP_CONFIG.distanceMode end, function(v) ADV_ESP_CONFIG.distanceMode = v end); toggleRow("Show Health", function() return ADV_ESP_CONFIG.showHealth end, function(v) ADV_ESP_CONFIG.showHealth = v end); cycleRow("Name Text Position", {"Top","Bottom","Left","Right"}, function() return ADV_ESP_CONFIG.namePosition end, function(v) ADV_ESP_CONFIG.namePosition = v end); cycleRow("Distance Text Position", {"Bottom","Top","Left","Right"}, function() return ADV_ESP_CONFIG.distancePosition end, function(v) ADV_ESP_CONFIG.distancePosition = v end); cycleRow("Health Text Position", {"Left","Right","Top","Bottom"}, function() return ADV_ESP_CONFIG.healthPosition end, function(v) ADV_ESP_CONFIG.healthPosition = v end)
    section("COLOR"); toggleRow("Use Team Color", function() return ADV_ESP_CONFIG.useTeamColor end, function(v) ADV_ESP_CONFIG.useTeamColor = v; if v then ADV_ESP_CONFIG.useThemeColor = false end end); toggleRow("Use Menu Theme Color", function() return ADV_ESP_CONFIG.useThemeColor end, function(v) ADV_ESP_CONFIG.useThemeColor = v; if v then ADV_ESP_CONFIG.useTeamColor = false end end)
    section("FILTER"); cycleRow("Filter Mode", {"None","Disable only for","Enable only for"}, function() return ADV_ESP_CONFIG.filterMode end, function(v) ADV_ESP_CONFIG.filterMode = v; task.defer(refreshScripts) end); cycleRow("Filter Category", {"Teams","Players"}, function() return ADV_ESP_CONFIG.filterCategory end, function(v) ADV_ESP_CONFIG.filterCategory = v; task.defer(refreshScripts) end)
    local function selSet() if ADV_ESP_CONFIG.filterMode == "Enable only for" then return ADV_ESP_CONFIG.filterCategory == "Teams" and ADV_ESP_CONFIG.onlyTeams or ADV_ESP_CONFIG.onlyPlayers end return ADV_ESP_CONFIG.filterCategory == "Teams" and ADV_ESP_CONFIG.disabledTeams or ADV_ESP_CONFIG.disabledPlayers end
    local names, seen = {}, {}
    if ADV_ESP_CONFIG.filterMode ~= "None" and ADV_ESP_CONFIG.filterCategory == "Teams" then
        for _, p in ipairs(Players:GetPlayers()) do if p.Team then local n = p.Team.Name; if not seen[n] then seen[n] = true; table.insert(names, n) end end end
    elseif ADV_ESP_CONFIG.filterMode ~= "None" then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
    end
    table.sort(names)
    if ADV_ESP_CONFIG.filterMode ~= "None" then
        filterSelectionList(ADV_ESP_CONFIG.filterCategory == "Teams" and "Teams List" or "Players List", names, selSet())
    end
    panel.Size = UDim2.new(1, -24, 0, y + 8)
    local expandedHeight = y + 64

    local function updateAdvancedEspLayout()
        local expanded = scriptData.active and not scriptData.optionsCollapsed
        panel.Visible = expanded
        optionsButton.Visible = scriptData.active
        optionsButton.Text = scriptData.optionsCollapsed and "OPTIONS >" or "OPTIONS v"
        container.Size = UDim2.new(1, -10, 0, scriptData.active and (expanded and expandedHeight or 84) or 44)
        if not expanded and gtaNav then gtaNav.optionIndex = nil end
        if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
    end

    optionsButton.MouseButton1Click:Connect(function()
        scriptData.optionsCollapsed = not scriptData.optionsCollapsed
        updateAdvancedEspLayout()
    end)
    registerExpandedNavItem(container, optionsButton, function()
        scriptData.optionsCollapsed = not scriptData.optionsCollapsed
        updateAdvancedEspLayout()
    end)

    local function toggleCard()
        scriptData.active = not scriptData.active
        toggleAdvancedESP(scriptData.active)
        toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
        toggleButton.Text = scriptData.active and "ON" or "OFF"
        updateAdvancedEspLayout()
    end
    toggleButton.MouseButton1Click:Connect(toggleCard)
    updateAdvancedEspLayout()
end

function createScriptPrimaryUI(scriptData, container)
    if scriptData.isAimbot then
        createAimbotUI(scriptData, container)
        return true
    elseif scriptData.isAdvancedESP then
        createAdvancedESPUI(scriptData, container)
        return true
    elseif scriptData.isESP then
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 130, 0, 32)
        box.Position = UDim2.new(1, -140, 0.5, -16)
        box.BackgroundColor3 = Config.colors.textbox
        box.BackgroundTransparency = 0
        box.TextColor3 = Config.colors.accent
        box.PlaceholderText = "Target..."
        box.PlaceholderColor3 = Config.colors.textDim
        box.Text = ""
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.ClearTextOnFocus = false
        box.Parent = container
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                runYourESP(box.Text)
            end
        end)
        return true
    elseif scriptData.isViewPlayer then
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 130, 0, 32)
        box.Position = UDim2.new(1, -140, 0.5, -16)
        box.BackgroundColor3 = Config.colors.textbox
        box.BackgroundTransparency = 0
        box.TextColor3 = Config.colors.accent
        box.PlaceholderText = "View..."
        box.PlaceholderColor3 = Config.colors.textDim
        box.Text = ""
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.ClearTextOnFocus = false
        box.Parent = container
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        box.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                runViewPlayer(box.Text)
            end
        end)
        return true
    elseif scriptData.isXYZTP then
        local xBox = Instance.new("TextBox")
        xBox.Size = UDim2.new(0, 50, 0, 32)
        xBox.Position = UDim2.new(1, -320, 0.5, -16)
        xBox.BackgroundColor3 = Config.colors.inactiveButton
        xBox.TextColor3 = Config.colors.accent
        xBox.PlaceholderText = "X"
        xBox.PlaceholderColor3 = Config.colors.textDim
        xBox.Text = ""
        xBox.Font = Enum.Font.GothamBold
        xBox.TextSize = 11
        xBox.ClearTextOnFocus = false
        xBox.Parent = container
        Instance.new("UICorner", xBox).CornerRadius = UDim.new(0, 6)

        local yBox = Instance.new("TextBox")
        yBox.Size = UDim2.new(0, 50, 0, 32)
        yBox.Position = UDim2.new(1, -260, 0.5, -16)
        yBox.BackgroundColor3 = Config.colors.inactiveButton
        yBox.TextColor3 = Config.colors.accent
        yBox.PlaceholderText = "Y"
        yBox.PlaceholderColor3 = Config.colors.textDim
        yBox.Text = ""
        yBox.Font = Enum.Font.GothamBold
        yBox.TextSize = 11
        yBox.ClearTextOnFocus = false
        yBox.Parent = container
        Instance.new("UICorner", yBox).CornerRadius = UDim.new(0, 6)

        local zBox = Instance.new("TextBox")
        zBox.Size = UDim2.new(0, 50, 0, 32)
        zBox.Position = UDim2.new(1, -200, 0.5, -16)
        zBox.BackgroundColor3 = Config.colors.inactiveButton
        zBox.TextColor3 = Config.colors.accent
        zBox.PlaceholderText = "Z"
        zBox.PlaceholderColor3 = Config.colors.textDim
        zBox.Text = ""
        zBox.Font = Enum.Font.GothamBold
        zBox.TextSize = 11
        zBox.ClearTextOnFocus = false
        zBox.Parent = container
        Instance.new("UICorner", zBox).CornerRadius = UDim.new(0, 6)

        local tpButton = Instance.new("TextButton")
        tpButton.Size = UDim2.new(0, 90, 0, 32)
        tpButton.Position = UDim2.new(1, -100, 0.5, -16)
        tpButton.BackgroundColor3 = Config.colors.accent
        tpButton.Text = "TP"
        tpButton.TextColor3 = Config.colors.text
        tpButton.Font = Enum.Font.GothamBold
        tpButton.TextSize = 12
        tpButton.AutoButtonColor = false
        tpButton.Parent = container
        Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 6)

        tpButton.MouseButton1Click:Connect(function()
            local x = tonumber(xBox.Text) or 0
            local y = tonumber(yBox.Text) or 0
            local z = tonumber(zBox.Text) or 0
            executeXYZTP(x, y, z)
        end)
        return true
    elseif scriptData.isZombie then
        local execButton = Instance.new("TextButton")
        execButton.Size = UDim2.new(0, 90, 0, 32)
        execButton.Position = UDim2.new(1, -100, 0.5, -16)
        execButton.BackgroundColor3 = Config.colors.accent
        execButton.Text = "EXECUTE"
        execButton.TextColor3 = Config.colors.text
        execButton.Font = Enum.Font.GothamBold
        execButton.TextSize = 11
        execButton.Parent = container
        Instance.new("UICorner", execButton).CornerRadius = UDim.new(0, 6)
        execButton.MouseButton1Click:Connect(function()
            runZombieScript()
        end)
        return true
    elseif scriptData.isTaxiFarm then
        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 90, 0, 32)
        toggleButton.Position = UDim2.new(1, -200, 0, 11)
        toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
        toggleButton.Text = scriptData.active and "ON" or "OFF"
        toggleButton.TextColor3 = Config.colors.text
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.TextSize = 11
        toggleButton.AutoButtonColor = false
        toggleButton.Parent = container
        Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

        local panicButton = Instance.new("TextButton")
        panicButton.Size = UDim2.new(0, 90, 0, 32)
        panicButton.Position = UDim2.new(1, -100, 0, 11)
        panicButton.BackgroundColor3 = Config.colors.unloadButton
        panicButton.Text = "PANIC"
        panicButton.TextColor3 = Config.colors.text
        panicButton.Font = Enum.Font.GothamBold
        panicButton.TextSize = 11
        panicButton.AutoButtonColor = false
        panicButton.Parent = container
        Instance.new("UICorner", panicButton).CornerRadius = UDim.new(0, 6)

        toggleButton.MouseButton1Click:Connect(function()
            scriptData.active = not scriptData.active
            toggleButton.BackgroundColor3 = scriptData.active and Config.colors.activeButton or Config.colors.inactiveButton
            toggleButton.Text = scriptData.active and "ON" or "OFF"
            toggleTaxiFarm(scriptData.active)
        end)

        panicButton.MouseButton1Click:Connect(function()
            executePanic()
            scriptData.active = false
            toggleButton.BackgroundColor3 = Config.colors.inactiveButton
            toggleButton.Text = "OFF"
            panicButton.Text = "STOPPED"
            panicButton.BackgroundColor3 = Config.colors.categoryBadge
            task.wait(2)
            panicButton.Text = "PANIC"
            panicButton.BackgroundColor3 = Config.colors.unloadButton
        end)
        return true
    end

    return false
end

function createScriptSecondaryUI(scriptData, container)
    local handled = false
    if scriptData.isHitboxExpander then
        handled = true
        -- Settings dropdown (visible only when enabled)
        local hitboxSettings = Instance.new("Frame")
        hitboxSettings.Size = UDim2.new(1, -30, 0, 160)
        hitboxSettings.Position = UDim2.new(0, 15, 0, 60)
        hitboxSettings.BackgroundColor3 = Config.colors.categoryBg
        hitboxSettings.BorderSizePixel = 0
        hitboxSettings.Visible = headState.enabled
        hitboxSettings.Parent = container
        Instance.new("UICorner", hitboxSettings).CornerRadius = UDim.new(0, 6)

        local hitboxModeOptions = nil
        local sizeBox = nil

        local function makeCheckbox(parent, xPos, yPos, label, initVal, callback)
            local btn = Instance.new("TextButton", parent)
            btn.Size = UDim2.new(0, 20, 0, 20)
            btn.Position = UDim2.new(0, xPos, 0, yPos)
            btn.BackgroundColor3 = initVal and Config.colors.activeButton or Config.colors.inactiveButton
            btn.Text = initVal and "✓" or ""
            btn.TextColor3 = Config.colors.text
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local lbl = Instance.new("TextLabel", parent)
            lbl.Size = UDim2.new(0, 120, 0, 20)
            lbl.Position = UDim2.new(0, xPos + 26, 0, yPos)
            lbl.BackgroundTransparency = 1
            lbl.Text = label
            lbl.TextColor3 = Config.colors.text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            btn.MouseButton1Click:Connect(function()
                local newVal = callback()
                btn.BackgroundColor3 = newVal and Config.colors.activeButton or Config.colors.inactiveButton
                btn.Text = newVal and "✓" or ""
            end)
            return btn
        end

        -- Row 1: Players / NPCs checkboxes
        makeCheckbox(hitboxSettings, 10, 6, "Players", HITBOX_CONFIG.TARGET_PLAYERS, function()
            HITBOX_CONFIG.TARGET_PLAYERS = not HITBOX_CONFIG.TARGET_PLAYERS
            if headState.enabled then rebuildHitboxRoster() end
            return HITBOX_CONFIG.TARGET_PLAYERS
        end)
        makeCheckbox(hitboxSettings, 10, 32, "NPCs", HITBOX_CONFIG.TARGET_NPCS, function()
            HITBOX_CONFIG.TARGET_NPCS = not HITBOX_CONFIG.TARGET_NPCS
            if headState.enabled then rebuildHitboxRoster() end
            return HITBOX_CONFIG.TARGET_NPCS
        end)
        -- Row 2: Team check
        makeCheckbox(hitboxSettings, 10, 57, "Ignore my team", HITBOX_CONFIG.TEAM_CHECK, function()
            HITBOX_CONFIG.TEAM_CHECK = not HITBOX_CONFIG.TEAM_CHECK
            if headState.enabled then rebuildHitboxRoster() end
            return HITBOX_CONFIG.TEAM_CHECK
        end)

        -- Row 3: Kill aura range
        local rangeLabel = Instance.new("TextLabel", hitboxSettings)
        rangeLabel.Size = UDim2.new(0, 80, 0, 20)
        rangeLabel.Position = UDim2.new(0, 10, 0, 108)
        rangeLabel.BackgroundTransparency = 1
        rangeLabel.Text = "Kill range:"
        rangeLabel.TextColor3 = Config.colors.text
        rangeLabel.Font = Enum.Font.Gotham
        rangeLabel.TextSize = 12
        rangeLabel.TextXAlignment = Enum.TextXAlignment.Left

        local rangeBox = Instance.new("TextBox", hitboxSettings)
        rangeBox.Size = UDim2.new(0, 55, 0, 20)
        rangeBox.Position = UDim2.new(0, 90, 0, 108)
        rangeBox.BackgroundColor3 = Config.colors.inactiveButton
        rangeBox.TextColor3 = Config.colors.accent
        rangeBox.Text = tostring(HITBOX_CONFIG.KILL_RANGE)
        rangeBox.Font = Enum.Font.GothamBold
        rangeBox.TextSize = 12
        rangeBox.ClearTextOnFocus = false
        Instance.new("UICorner", rangeBox).CornerRadius = UDim.new(0, 4)
        rangeBox.FocusLost:Connect(function()
            local val = tonumber(rangeBox.Text)
            if val and val > 0 then
                HITBOX_CONFIG.KILL_RANGE = val
            else
                rangeBox.Text = tostring(HITBOX_CONFIG.KILL_RANGE)
            end
        end)

        -- Row 4: Target mode
        local modeLabel = Instance.new("TextLabel", hitboxSettings)
        modeLabel.Size = UDim2.new(0, 80, 0, 20)
        modeLabel.Position = UDim2.new(0, 10, 0, 82)
        modeLabel.BackgroundTransparency = 1
        modeLabel.Text = "Target:"
        modeLabel.TextColor3 = Config.colors.text
        modeLabel.Font = Enum.Font.Gotham
        modeLabel.TextSize = 12
        modeLabel.TextXAlignment = Enum.TextXAlignment.Left

        local modeButton = Instance.new("TextButton", hitboxSettings)
        modeButton.Size = UDim2.new(0, 140, 0, 22)
        modeButton.Position = UDim2.new(0, 90, 0, 81)
        modeButton.BackgroundColor3 = Config.colors.inactiveButton
        modeButton.TextColor3 = Config.colors.accent
        modeButton.Text = HITBOX_CONFIG.TARGET_MODE .. " ▼"
        modeButton.Font = Enum.Font.GothamBold
        modeButton.TextSize = 11
        modeButton.AutoButtonColor = false
        Instance.new("UICorner", modeButton).CornerRadius = UDim.new(0, 4)

        local function refreshHitboxModeButton()
            modeButton.Text = HITBOX_CONFIG.TARGET_MODE .. " ▼"
        end

        hitboxModeOptions = Instance.new("Frame", hitboxSettings)
        hitboxModeOptions.Size = UDim2.new(0, 140, 0, 88)
        hitboxModeOptions.Position = UDim2.new(0, 90, 0, 104)
        hitboxModeOptions.BackgroundColor3 = Config.colors.scriptBg
        hitboxModeOptions.BorderSizePixel = 0
        hitboxModeOptions.Visible = false
        hitboxModeOptions.ZIndex = 5
        Instance.new("UICorner", hitboxModeOptions).CornerRadius = UDim.new(0, 6)

        local modeLayout = Instance.new("UIListLayout", hitboxModeOptions)
        modeLayout.Padding = UDim.new(0, 2)
        modeLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for i, modeName in ipairs({"Head", "Torso", "HumanoidRootPart", "Limbs"}) do
            local option = Instance.new("TextButton", hitboxModeOptions)
            option.Size = UDim2.new(1, -6, 0, 20)
            option.Position = UDim2.new(0, 3, 0, 0)
            option.LayoutOrder = i
            option.BackgroundColor3 = Config.colors.inactiveButton
            option.TextColor3 = Config.colors.text
            option.Text = modeName
            option.Font = Enum.Font.Gotham
            option.TextSize = 11
            option.AutoButtonColor = false
            Instance.new("UICorner", option).CornerRadius = UDim.new(0, 4)
            option.MouseButton1Click:Connect(function()
                HITBOX_CONFIG.TARGET_MODE = modeName
                sizeBox.Text = tostring(getHitboxTargetSize(modeName))
                hitboxModeOptions.Visible = false
                refreshHitboxModeButton()
                if headState.enabled then reapplyHitboxForAll() end
            end)
        end

        modeButton.MouseButton1Click:Connect(function()
            hitboxModeOptions.Visible = not hitboxModeOptions.Visible
        end)

        -- Row 5: Hitbox size
        local sizeLabel = Instance.new("TextLabel", hitboxSettings)
        sizeLabel.Size = UDim2.new(0, 80, 0, 20)
        sizeLabel.Position = UDim2.new(0, 10, 0, 134)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.Text = "Hitbox size:"
        sizeLabel.TextColor3 = Config.colors.text
        sizeLabel.Font = Enum.Font.Gotham
        sizeLabel.TextSize = 12
        sizeLabel.TextXAlignment = Enum.TextXAlignment.Left

        sizeBox = Instance.new("TextBox", hitboxSettings)
        sizeBox.Size = UDim2.new(0, 55, 0, 20)
        sizeBox.Position = UDim2.new(0, 90, 0, 134)
        sizeBox.BackgroundColor3 = Config.colors.inactiveButton
        sizeBox.TextColor3 = Config.colors.accent
        sizeBox.Text = tostring(getHitboxTargetSize(HITBOX_CONFIG.TARGET_MODE))
        sizeBox.Font = Enum.Font.GothamBold
        sizeBox.TextSize = 12
        sizeBox.ClearTextOnFocus = false
        Instance.new("UICorner", sizeBox).CornerRadius = UDim.new(0, 4)
        sizeBox.FocusLost:Connect(function()
            local val = tonumber(sizeBox.Text)
            if val and val > 0 then
                HITBOX_CONFIG.SIZE_BY_TARGET[HITBOX_CONFIG.TARGET_MODE] = val
                if headState.enabled then reapplyHitboxForAll() end
            else
                sizeBox.Text = tostring(getHitboxTargetSize(HITBOX_CONFIG.TARGET_MODE))
            end
        end)
        headState.settingsRefresh = function()
            sizeBox.Text = tostring(getHitboxTargetSize(HITBOX_CONFIG.TARGET_MODE))
            refreshHitboxModeButton()
        end
        refreshHitboxModeButton()

        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 90, 0, 32)
        toggleButton.Position = UDim2.new(1, -100, 0, 11)
        toggleButton.BackgroundColor3 = headState.enabled and Config.colors.activeButton or Config.colors.inactiveButton
        toggleButton.Text = headState.enabled and "ON" or "OFF"
        toggleButton.TextColor3 = Config.colors.text
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.TextSize = 11
        toggleButton.AutoButtonColor = false
        toggleButton.Parent = container
        Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

        toggleButton.MouseButton1Click:Connect(function()
            local newState = not headState.enabled
            toggleHitbox(newState)
            toggleButton.BackgroundColor3 = newState and Config.colors.activeButton or Config.colors.inactiveButton
            toggleButton.Text = newState and "ON" or "OFF"
            -- expand / collapse settings
            container.Size = UDim2.new(1, -10, 0, newState and 227 or 55)
            hitboxSettings.Visible = newState
            if hitboxModeOptions then hitboxModeOptions.Visible = false end
        end)
    elseif scriptData.isAvatarSaves then
        handled = true
        -- ── File helpers ──────────────────────────────────────────
        local AVS_FOLDER = "LizardHub/avatars"
        local AVS_INDEX  = "LizardHub/avatars/index.json"
        local HS = game:GetService("HttpService")

        local function avsEnsure()
            pcall(function()
                if not isfolder("LizardHub") then makefolder("LizardHub") end
                if not isfolder(AVS_FOLDER)  then makefolder(AVS_FOLDER)  end
            end)
        end
        local function avsReadIndex()
            if not isfile or not isfile(AVS_INDEX) then return {} end
            local ok, t = pcall(function() return HS:JSONDecode(readfile(AVS_INDEX)) end)
            return (ok and type(t)=="table") and t or {}
        end
        local function avsWriteIndex(t)
            pcall(function() writefile(AVS_INDEX, HS:JSONEncode(t)) end)
        end
        local function avsIdsPath(n) return AVS_FOLDER.."/"..n..".json" end

        -- Save format: [{id="123", t=11}, ...] — stores type so viewport can use it
        local function avsSaveAvatar(name)
            avsEnsure()

            -- Get the in-game character
            local char = workspace:FindFirstChild("Characters")
                and workspace.Characters:FindFirstChild(LocalPlayer.Name)
                or LocalPlayer.Character
            if not char then return false, "Character not found" end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return false, "No Humanoid on character" end

            -- GetAppliedDescription returns the HumanoidDescription of what's
            -- currently worn. Accessory IDs are stored as CSV strings per slot.
            -- Source: https://devforum.roblox.com/t/how-to-get-asset-id-from-accessory/2390691
            local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
            if not ok or not desc then
                return false, "GetAppliedDescription failed: " .. tostring(desc)
            end

            local ids = {}
            local seen = {}

            local function addId(id)
                local s = tostring(id or ""):match("^%s*(.-)%s*$")
                if s ~= "" and s ~= "0" and not seen[s] then
                    seen[s] = true
                    table.insert(ids, s)
                    print("[AvatarSave] " .. s)
                end
            end

            -- Clothing (direct numeric properties)
            addId(desc.Shirt)
            addId(desc.Pants)
            addId(desc.GraphicTShirt)
            addId(desc.Face)
            addId(desc.Head)

            -- Accessories — each slot is a CSV string of catalog IDs
            local accSlots = {
                "HatAccessory", "HairAccessory", "FaceAccessory",
                "NeckAccessory", "ShouldersAccessory", "FrontAccessory",
                "BackAccessory", "WaistAccessory"
            }
            for _, slot in ipairs(accSlots) do
                local csv = desc[slot]
                if csv and csv ~= "" then
                    for _, id in ipairs(csv:split(",")) do
                        addId(id)
                    end
                end
            end

            print("[AvatarSave] Total: " .. #ids .. " items")

            if #ids == 0 then
                return false, "No items found — is your character loaded?"
            end

            pcall(function()
                writefile(avsIdsPath(name), HS:JSONEncode(ids))
                writefile("LizardHub/avatar_outfit.json", HS:JSONEncode(ids))
            end)

            local idx = avsReadIndex()
            local found = false
            for _, n in ipairs(idx) do if n == name then found = true break end end
            if not found then table.insert(idx, name) end
            avsWriteIndex(idx)
            return true, #ids
        end

        local function avsDelete(name)
            pcall(function() delfile(avsIdsPath(name)) end)
            if _G.AvatarSaves_Models then _G.AvatarSaves_Models[name] = nil end
            local idx = avsReadIndex()
            for i, n in ipairs(idx) do
                if n==name then table.remove(idx, i) break end
            end
            avsWriteIndex(idx)
        end

        -- ── Layout ────────────────────────────────────────────────
        local HDR_H   = 44
        local MAX_VIS = 400

        container.Size = UDim2.new(1, -10, 0, 55 + HDR_H + 4)

        -- Name box + Save button
        local hdrBar = Instance.new("Frame", container)
        hdrBar.Size             = UDim2.new(1, 0, 0, HDR_H)
        hdrBar.Position         = UDim2.new(0, 0, 0, 55)
        hdrBar.BackgroundTransparency = 1

        local nameBox = Instance.new("TextBox", hdrBar)
        nameBox.Size             = UDim2.new(1, -90, 0, 28)
        nameBox.Position         = UDim2.new(0, 6, 0, 8)
        nameBox.BackgroundColor3 = Color3.fromRGB(16, 12, 26)
        nameBox.TextColor3       = Config.colors.text
        nameBox.PlaceholderText  = "Avatar name..."
        nameBox.PlaceholderColor3 = Config.colors.textDim
        nameBox.Text             = ""
        nameBox.Font             = Enum.Font.Gotham
        nameBox.TextSize         = 11
        nameBox.ClearTextOnFocus = false
        Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 5)

        local topSaveBtn = Instance.new("TextButton", hdrBar)
        topSaveBtn.Size             = UDim2.new(0, 76, 0, 28)
        topSaveBtn.Position         = UDim2.new(1, -82, 0, 8)
        topSaveBtn.BackgroundColor3 = Config.colors.activeButton
        topSaveBtn.TextColor3       = Config.colors.text
        topSaveBtn.Text             = "💾 Save"
        topSaveBtn.Font             = Enum.Font.GothamBold
        topSaveBtn.TextSize         = 11
        topSaveBtn.AutoButtonColor  = false
        Instance.new("UICorner", topSaveBtn).CornerRadius = UDim.new(0, 5)

        -- Scroll list
        local avsList = Instance.new("ScrollingFrame", container)
        avsList.Size               = UDim2.new(1, -6, 0, 0)
        avsList.Position           = UDim2.new(0, 3, 0, 55 + HDR_H)
        avsList.BackgroundTransparency = 1
        avsList.BorderSizePixel    = 0
        avsList.ScrollBarThickness = 3
        avsList.ScrollBarImageColor3 = Config.colors.accent
        avsList.CanvasSize         = UDim2.new(0, 0, 0, 0)
        avsList.Visible            = false
        local avsLyt = Instance.new("UIListLayout", avsList)
        avsLyt.Padding   = UDim.new(0, 5)
        avsLyt.SortOrder = Enum.SortOrder.LayoutOrder

        local CARD_H_FLAT = 110  -- flat card, no viewport

        local function avsRecompute()
            local total = 0
            for _, c in ipairs(avsList:GetChildren()) do
                if c:IsA("Frame") then total = total + c.Size.Y.Offset + 5 end
            end
            avsList.CanvasSize = UDim2.new(0, 0, 0, total)
            local vis = math.min(total, MAX_VIS)
            avsList.Size    = UDim2.new(1, -6, 0, vis)
            avsList.Visible = total > 0
            container.Size  = UDim2.new(1, -10, 0, 55 + HDR_H + (total > 0 and vis or 0) + 4)
        end

        local function avsMakeCard(order, name)
            local card = Instance.new("Frame", avsList)
            card.Size             = UDim2.new(1, -2, 0, CARD_H_FLAT)
            card.BackgroundColor3 = Color3.fromRGB(14, 10, 22)
            card.BorderSizePixel  = 0
            card.LayoutOrder      = order
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
            local cs = Instance.new("UIStroke", card)
            cs.Color = Color3.fromRGB(55, 35, 95); cs.Thickness = 1

            -- Avatar name label
            local nameLbl = Instance.new("TextLabel", card)
            nameLbl.Size               = UDim2.new(1, -12, 0, 24)
            nameLbl.Position           = UDim2.new(0, 10, 0, 8)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text               = "👤  " .. name
            nameLbl.TextColor3         = Color3.fromRGB(200, 170, 255)
            nameLbl.Font               = Enum.Font.GothamBold
            nameLbl.TextSize           = 13
            nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
            nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd

            local statusLbl = Instance.new("TextLabel", card)
            statusLbl.Size               = UDim2.new(1, -12, 0, 14)
            statusLbl.Position           = UDim2.new(0, 10, 0, 34)
            statusLbl.BackgroundTransparency = 1
            statusLbl.Text               = "Open Avatar Shop → Import tab first"
            statusLbl.TextColor3         = Config.colors.textDim
            statusLbl.Font               = Enum.Font.Gotham
            statusLbl.TextSize           = 10
            statusLbl.TextXAlignment     = Enum.TextXAlignment.Left

            -- ▶ Import Avatar button
            local loadBtn = Instance.new("TextButton", card)
            loadBtn.Size             = UDim2.new(1, -12, 0, 30)
            loadBtn.Position         = UDim2.new(0, 6, 0, 54)
            loadBtn.BackgroundColor3 = Color3.fromRGB(35, 22, 70)
            loadBtn.TextColor3       = Color3.fromRGB(200, 160, 255)
            loadBtn.Text             = "▶ Import Avatar"
            loadBtn.Font             = Enum.Font.GothamBold
            loadBtn.TextSize         = 11
            loadBtn.AutoButtonColor  = false
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 6)

            -- Click dot for this card (shows where to click Wear)
            -- Instruction banner shown during import (replaces dot system)
            local instrGui = Instance.new("ScreenGui")
            instrGui.Name = "AvtrInstr_"..name
            instrGui.ResetOnSpawn = false
            instrGui.DisplayOrder = 2000000000
            instrGui.IgnoreGuiInset = true
            instrGui.Parent = LocalPlayer.PlayerGui

            local instrBg = Instance.new("Frame", instrGui)
            instrBg.Size = UDim2.new(0, 420, 0, 70)
            instrBg.Position = UDim2.new(0.5, -210, 0, 60)
            instrBg.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
            instrBg.BorderSizePixel = 0
            instrBg.Visible = false
            Instance.new("UICorner", instrBg).CornerRadius = UDim.new(0, 10)
            local instrStroke = Instance.new("UIStroke", instrBg)
            instrStroke.Color = Color3.fromRGB(100, 60, 200); instrStroke.Thickness = 1.5

            local instrTitle = Instance.new("TextLabel", instrBg)
            instrTitle.Size = UDim2.new(1, -16, 0, 22)
            instrTitle.Position = UDim2.new(0, 8, 0, 6)
            instrTitle.BackgroundTransparency = 1
            instrTitle.Text = "Avatar Import in progress"
            instrTitle.TextColor3 = Color3.fromRGB(200, 160, 255)
            instrTitle.Font = Enum.Font.GothamBold
            instrTitle.TextSize = 13
            instrTitle.TextXAlignment = Enum.TextXAlignment.Left

            local instrStep = Instance.new("TextLabel", instrBg)
            instrStep.Size = UDim2.new(1, -16, 0, 36)
            instrStep.Position = UDim2.new(0, 8, 0, 28)
            instrStep.BackgroundTransparency = 1
            instrStep.Text = ""
            instrStep.TextColor3 = Color3.fromRGB(220, 210, 255)
            instrStep.Font = Enum.Font.Gotham
            instrStep.TextSize = 12
            instrStep.TextXAlignment = Enum.TextXAlignment.Left
            instrStep.TextWrapped = true

            local isRunning = false
            local avtrCancelled = false

            -- Stop button (only visible while running)
            local stopBtn = Instance.new("TextButton", card)
            stopBtn.Size             = UDim2.new(0.48, -9, 0, 24)
            stopBtn.Position         = UDim2.new(0, 6, 0, 80)
            stopBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 10)
            stopBtn.TextColor3       = Color3.fromRGB(255, 180, 80)
            stopBtn.Text             = "✕ Stop"
            stopBtn.Font             = Enum.Font.GothamBold
            stopBtn.TextSize         = 11
            stopBtn.AutoButtonColor  = false
            stopBtn.Visible          = false
            Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)
            stopBtn.MouseButton1Click:Connect(function()
                avtrCancelled = true
                stopBtn.Text = "Stopping..."
            end)

            -- Delete button (always visible, right side)
            local delBtn = Instance.new("TextButton", card)
            delBtn.Size             = UDim2.new(0.48, -9, 0, 24)
            delBtn.Position         = UDim2.new(0.52, 3, 0, 80)
            delBtn.BackgroundColor3 = Color3.fromRGB(55, 16, 16)
            delBtn.TextColor3       = Color3.fromRGB(255, 100, 100)
            delBtn.Text             = "🗑 Delete"
            delBtn.Font             = Enum.Font.GothamBold
            delBtn.TextSize         = 11
            delBtn.AutoButtonColor  = false
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)
            delBtn.MouseButton1Click:Connect(function()
                if isRunning then return end
                avsDelete(name)
                instrGui:Destroy()
                card:Destroy()
                avsRecompute()
            end)

            loadBtn.MouseButton1Click:Connect(function()
                if isRunning then return end
                task.spawn(function()
                    isRunning     = true
                    avtrCancelled = false
                    stopBtn.Visible = true
                    stopBtn.Text    = "✕ Stop"
                    delBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 20)  -- dim delete while running
                    delBtn.TextColor3 = Color3.fromRGB(120, 60, 60)

                    local function dbg(msg)
                        statusLbl.Text = msg
                        print("[AvatarImporter:" .. name .. "] " .. msg)
                    end

                    local function resetButtons()
                        isRunning = false; avtrCancelled = false
                        stopBtn.Visible = false
                        delBtn.BackgroundColor3 = Color3.fromRGB(55, 16, 16)
                        delBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                        loadBtn.Text = "▶ Import Avatar"
                        instrBg.Visible = false
                    end

                    local function setInstr(step)
                        instrBg.Visible = true
                        instrStep.Text = step
                    end

                    -- Read IDs
                    local raw = nil
                    pcall(function()
                        if isfile and isfile(avsIdsPath(name)) then raw = readfile(avsIdsPath(name)) end
                    end)
                    if not raw then
                        dbg("⚠ No save file found")
                        resetButtons(); return
                    end

                    local ok, assets = pcall(function() return HS:JSONDecode(raw) end)
                    if not ok or type(assets)~="table" or #assets==0 then
                        dbg("⚠ File empty or corrupt")
                        resetButtons(); return
                    end

                    -- IDs are now a flat array of strings
                    local ids = {}
                    for _, a in ipairs(assets) do
                        if type(a) == "table" and a.id then
                            table.insert(ids, tostring(a.id))  -- old format compat
                        else
                            table.insert(ids, tostring(a))
                        end
                    end

                    -- Check avatar shop import tab is open
                    -- Find the shop UI elements (original approach — simple FindFirstChild)
                    local function getAvatarShop()
                        local sc  = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                        local r   = sc  and sc:FindFirstChild("Right")
                        local mid = r   and r:FindFirstChild("Middle")
                        return mid and mid:FindFirstChild("AvatarShop")
                    end

                    local function findUI(shop)
                        local panel = shop:FindFirstChild("Panel")
                        local inv   = panel and panel:FindFirstChild("Inventory")
                        if not inv then return nil, nil end
                        -- TextBox path: Inventory > TextBox (frame) > TextBoxFrame > TextBox
                        local tbFrame = inv:FindFirstChild("TextBox")
                        local realTB  = nil
                        if tbFrame then
                            local tbf = tbFrame:FindFirstChild("TextBoxFrame")
                            if tbf then realTB = tbf:FindFirstChild("TextBox") end
                            if not realTB then
                                for _, d in ipairs(tbFrame:GetDescendants()) do
                                    if d:IsA("TextBox") then realTB = d; break end
                                end
                            end
                        end
                        -- Import button: Inventory > ImportId
                        local importBtn = inv:FindFirstChild("ImportId")
                        return realTB, importBtn
                    end

                    local shop = getAvatarShop()
                    if not shop or not shop.Visible then
                        dbg("⚠ Open Avatar Shop → Import tab first")
                        resetButtons(); return
                    end

                    local VIM = game:GetService("VirtualInputManager")
                    local function vimClick(obj)
                        if not obj then return end
                        local p  = obj.AbsolutePosition
                        local sz = obj.AbsoluteSize
                        local x  = p.X + sz.X / 2
                        local y  = p.Y + sz.Y / 2
                        VIM:SendMouseMoveEvent(x, y, game)
                        task.wait(0.05)
                        VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
                        task.wait(0.08)
                        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
                        task.wait(0.08)
                    end

                    instrBg.Visible = true
                    instrStep.Text  = "Starting — IDs will be pasted automatically.\nFor each item: click IMPORT → click WEAR → click CLOSE → repeat."
                    loadBtn.Text = "⏳ Running..."
                    local done = 0

                    for i, id in ipairs(ids) do
                        if avtrCancelled then dbg("Stopped at "..(i-1).."/"..#ids); break end

                        shop = getAvatarShop()
                        if not shop or not shop.Visible then dbg("⚠ Import tab closed"); break end

                        local tb, importBtn = findUI(shop)
                        if not tb      then dbg("⚠ TextBox not found"); break end
                        if not importBtn then dbg("⚠ ImportId button not found"); break end

                        -- Set the ID directly into the textbox (this worked reliably)
                        tb.Text = id
                        task.wait(0.2)

                        dbg(i.."/"..#ids.." — importing ID: "..id)

                        -- VIM click the Import button
                        vimClick(importBtn)
                        task.wait(0.4)

                        -- Step 1: paste ID, show Import instruction, VIM click Import
                        setInstr("Item "..i.."/"..#ids.."  ·  The ID has been pasted.\nClick  IMPORT  to open the item popup.")
                        dbg(i.."/"..#ids.." — pasting ID, click Import")
                        task.wait(0.3)
                        vimClick(importBtn)
                        task.wait(0.4)

                        -- Wait up to 3s for ItemDetails popup to appear
                        local itemDetails = nil
                        local shopRef = getAvatarShop()
                        if shopRef then
                            local idf = shopRef:FindFirstChild("ItemDetails")
                            for _ = 1, 60 do
                                task.wait(0.05)
                                if avtrCancelled then break end
                                idf = shopRef:FindFirstChild("ItemDetails")
                                if idf and idf.Visible then itemDetails = idf; break end
                            end
                        end
                        if avtrCancelled then break end

                        if itemDetails then
                            -- Step 2: wait for Wear
                            setInstr("Item "..i.."/"..#ids.."  ·  Popup open!\nClick  WEAR  to equip the item.")
                            dbg(i.."/"..#ids.." — click Wear")
                            for _ = 1, 200 do
                                task.wait(0.05)
                                if avtrCancelled then break end
                                local idf2 = shopRef and shopRef:FindFirstChild("ItemDetails")
                                if not idf2 or not idf2.Visible then break end
                            end

                            if avtrCancelled then break end

                            -- Step 3: if popup still open, wait for Close
                            local idf3 = shopRef and shopRef:FindFirstChild("ItemDetails")
                            if idf3 and idf3.Visible then
                                setInstr("Item "..i.."/"..#ids.."  ·  Click  CLOSE  or the X on the popup.")
                                dbg(i.."/"..#ids.." — click Close")
                                for _ = 1, 200 do
                                    task.wait(0.05)
                                    if avtrCancelled then break end
                                    local idf4 = shopRef and shopRef:FindFirstChild("ItemDetails")
                                    if not idf4 or not idf4.Visible then break end
                                end
                            end

                            done = done + 1
                        else
                            dbg(i.."/"..#ids.." — no popup, skipping (invalid ID?)")
                        end

                        task.wait(0.25)
                    end

                    resetButtons()
                    dbg("✓ Done: "..done.."/"..#ids.." items")
                    statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
                    task.delay(4, function() statusLbl.TextColor3 = Config.colors.textDim end)
                end)
            end)

            return card
        end

        local function avsRebuild()
            for _, c in ipairs(avsList:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local idx = avsReadIndex()
            for i, n in ipairs(idx) do avsMakeCard(i, n) end
            avsRecompute()
        end

        topSaveBtn.MouseButton1Click:Connect(function()
            local name = nameBox.Text:match("^%s*(.-)%s*$")
            if name=="" then return end
            topSaveBtn.Text = "..."
            task.spawn(function()
                local ok, result = avsSaveAvatar(name)
                topSaveBtn.Text = "💾 Save"
                if ok then
                    nameBox.Text = ""
                    avsRebuild()
                end
            end)
        end)

        -- Build list when category first viewed
        local avsBuilt = false
        RunService.RenderStepped:Connect(function()
            if container.Visible and not avsBuilt then
                avsBuilt = true
                avsRebuild()
            end
        end)
    end
    return handled
end
function createScriptTertiaryUI(scriptData, container)
    if scriptData.isViolentMenu then
        local execButton = Instance.new("TextButton")
        execButton.Size = UDim2.new(0, 90, 0, 32)
        execButton.Position = UDim2.new(1, -100, 0.5, -16)
        execButton.BackgroundColor3 = Config.colors.inactiveButton
        execButton.Text = "LOAD"
        execButton.TextColor3 = Config.colors.text
        execButton.Font = Enum.Font.GothamBold
        execButton.TextSize = 11
        execButton.Parent = container
        Instance.new("UICorner", execButton).CornerRadius = UDim.new(0, 6)
        execButton.MouseButton1Click:Connect(function()
            execButton.Text = "ON"
            execButton.BackgroundColor3 = Config.colors.activeButton
            task.spawn(function()
                loadstring(game:HttpGet("https://vt-now.github.io/VIOLENT/vt.lua"))()
            end)
        end)
    elseif scriptData.isTeleportPoint then
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size             = UDim2.new(0, 90, 0, 32)
        tpBtn.Position         = UDim2.new(1, -100, 0.5, -16)
        tpBtn.BackgroundColor3 = Config.colors.inactiveButton
        tpBtn.TextColor3       = Config.colors.text
        tpBtn.Text             = "TP"
        tpBtn.Font             = Enum.Font.GothamBold
        tpBtn.TextSize         = 11
        tpBtn.AutoButtonColor  = false
        tpBtn.Parent           = container
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)
        tpBtn.MouseButton1Click:Connect(function()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.CFrame = CFrame.new(scriptData.tpPos)
            tpBtn.Text             = "✓"
            tpBtn.BackgroundColor3 = Config.colors.activeButton
            task.delay(1.2, function()
                tpBtn.Text             = "TP"
                tpBtn.BackgroundColor3 = Config.colors.inactiveButton
            end)
        end)
    elseif scriptData.isHomeFinder then
        local PROP_ROW_H = 38
        local DETAIL_H   = 44
        local LIST_MAX_H = 260
        local HEADER_H   = 44

        local scanBar = Instance.new("Frame", container)
        scanBar.Size             = UDim2.new(1, 0, 0, HEADER_H)
        scanBar.Position         = UDim2.new(0, 0, 0, 55)
        scanBar.BackgroundTransparency = 1

        local scanBtn = Instance.new("TextButton", scanBar)
        scanBtn.Size             = UDim2.new(0, 90, 0, 28)
        scanBtn.Position         = UDim2.new(0, 10, 0, 8)
        scanBtn.BackgroundColor3 = Config.colors.inactiveButton
        scanBtn.TextColor3       = Config.colors.text
        scanBtn.Text             = "↻ Scan"
        scanBtn.Font             = Enum.Font.GothamBold
        scanBtn.TextSize         = 11
        scanBtn.AutoButtonColor  = false
        Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

        local countLabel = Instance.new("TextLabel", scanBar)
        countLabel.Size               = UDim2.new(1, -115, 0, 28)
        countLabel.Position           = UDim2.new(0, 110, 0, 8)
        countLabel.BackgroundTransparency = 1
        countLabel.Text               = "Click Scan to load properties"
        countLabel.TextColor3         = Config.colors.textDim
        countLabel.Font               = Enum.Font.Gotham
        countLabel.TextSize           = 11
        countLabel.TextXAlignment     = Enum.TextXAlignment.Left

        local listFrame = Instance.new("ScrollingFrame", container)
        listFrame.Size               = UDim2.new(1, -8, 0, 0)
        listFrame.Position           = UDim2.new(0, 4, 0, 55 + HEADER_H)
        listFrame.BackgroundTransparency = 1
        listFrame.BorderSizePixel    = 0
        listFrame.ScrollBarThickness = 3
        listFrame.ScrollBarImageColor3 = Config.colors.accent
        listFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
        listFrame.Visible            = false
        local listLayout = Instance.new("UIListLayout", listFrame)
        listLayout.Padding           = UDim.new(0, 3)
        listLayout.SortOrder         = Enum.SortOrder.LayoutOrder

        local expandedRow = nil

        local function getOccupants(propFolder)
            local found = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                local ip = plr:FindFirstChild("InProperty")
                if ip and ip:IsA("ObjectValue") and ip.Value == propFolder then
                    table.insert(found, plr.Name)
                end
            end
            return found
        end

        local function getTeleportTarget(propFolder)
            local pi = propFolder:FindFirstChildOfClass("Model")
            if not pi then
                for _, c in ipairs(propFolder:GetChildren()) do
                    if c:IsA("Model") then pi = c break end
                end
            end
            if pi then
                local ok, cf = pcall(function() return pi:GetPivot() end)
                if ok then return cf end
                for _, d in ipairs(pi:GetDescendants()) do
                    if d:IsA("BasePart") then return d.CFrame end
                end
            end
            return nil
        end

        local function recomputeCanvas()
            local total = 0
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("Frame") then total = total + c.Size.Y.Offset + 3 end
            end
            listFrame.CanvasSize = UDim2.new(0, 0, 0, total)
            local visH = math.min(total, LIST_MAX_H)
            listFrame.Size = UDim2.new(1, -8, 0, visH)
            container.Size = UDim2.new(1, -10, 0, 55 + HEADER_H + visH + 4)
        end

        local function buildList()
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            expandedRow = nil

            local RS = game:GetService("ReplicatedStorage")
            local ok, activeFolder = pcall(function()
                return RS:WaitForChild("Stuff", 3)
                    :WaitForChild("Housing", 3)
                    :WaitForChild("Active", 3)
            end)

            if not ok or not activeFolder then
                countLabel.Text = "⚠ Could not find Housing.Active"
                return
            end

            local props = activeFolder:GetChildren()
            if #props == 0 then
                countLabel.Text = "No active properties"
                listFrame.Visible = false
                container.Size = UDim2.new(1, -10, 0, 55 + HEADER_H)
                return
            end

            countLabel.Text = #props .. " propert" .. (#props == 1 and "y" or "ies") .. " active"

            for i, propFolder in ipairs(props) do
                local row = Instance.new("Frame", listFrame)
                row.Size             = UDim2.new(1, -4, 0, PROP_ROW_H)
                row.BackgroundColor3 = Config.colors.categoryBg
                row.BorderSizePixel  = 0
                row.LayoutOrder      = i
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                local nameBtn = Instance.new("TextButton", row)
                nameBtn.Size             = UDim2.new(1, -28, 0, PROP_ROW_H)
                nameBtn.Position         = UDim2.new(0, 8, 0, 0)
                nameBtn.BackgroundTransparency = 1
                nameBtn.Text             = "🏠  " .. propFolder.Name
                nameBtn.TextColor3       = Config.colors.text
                nameBtn.Font             = Enum.Font.GothamBold
                nameBtn.TextSize         = 12
                nameBtn.TextXAlignment   = Enum.TextXAlignment.Left
                nameBtn.AutoButtonColor  = false

                local arrow = Instance.new("TextLabel", row)
                arrow.Size               = UDim2.new(0, 20, 0, PROP_ROW_H)
                arrow.Position           = UDim2.new(1, -22, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text               = "▸"
                arrow.TextColor3         = Config.colors.textDim
                arrow.Font               = Enum.Font.GothamBold
                arrow.TextSize           = 11
                arrow.TextXAlignment     = Enum.TextXAlignment.Center

                local detail = Instance.new("Frame", row)
                detail.Size             = UDim2.new(1, 0, 0, DETAIL_H)
                detail.Position         = UDim2.new(0, 0, 0, PROP_ROW_H)
                detail.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
                detail.BorderSizePixel  = 0
                detail.Visible          = false
                Instance.new("UICorner", detail).CornerRadius = UDim.new(0, 5)

                local occupantLabel = Instance.new("TextLabel", detail)
                occupantLabel.Size               = UDim2.new(1, -90, 1, 0)
                occupantLabel.Position           = UDim2.new(0, 8, 0, 0)
                occupantLabel.BackgroundTransparency = 1
                occupantLabel.TextColor3         = Config.colors.textDim
                occupantLabel.Font               = Enum.Font.Gotham
                occupantLabel.TextSize           = 11
                occupantLabel.TextXAlignment     = Enum.TextXAlignment.Left
                occupantLabel.TextYAlignment     = Enum.TextYAlignment.Center
                occupantLabel.TextWrapped        = true

                local tpBtn = Instance.new("TextButton", detail)
                tpBtn.Size             = UDim2.new(0, 72, 0, 28)
                tpBtn.Position         = UDim2.new(1, -80, 0.5, -14)
                tpBtn.BackgroundColor3 = Config.colors.activeButton
                tpBtn.TextColor3       = Config.colors.text
                tpBtn.Text             = "TP In"
                tpBtn.Font             = Enum.Font.GothamBold
                tpBtn.TextSize         = 11
                tpBtn.AutoButtonColor  = false
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

                tpBtn.MouseButton1Click:Connect(function()
                    local cf  = getTeleportTarget(propFolder)
                    local hrp = LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and cf then
                        hrp.CFrame = cf + Vector3.new(0, 5, 0) + cf.LookVector * 2
                        tpBtn.Text             = "✓"
                        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 20)
                        task.delay(1.5, function()
                            tpBtn.Text             = "TP In"
                            tpBtn.BackgroundColor3 = Config.colors.activeButton
                        end)
                    else
                        tpBtn.Text = "?"
                    end
                end)

                local rowData = { row = row, detail = detail, arrow = arrow }

                nameBtn.MouseButton1Click:Connect(function()
                    if expandedRow and expandedRow.row == row then
                        detail.Visible = false
                        row.Size = UDim2.new(1, -4, 0, PROP_ROW_H)
                        arrow.Text = "▸"
                        expandedRow = nil
                    else
                        -- Collapse previous
                        if expandedRow then
                            expandedRow.detail.Visible = false
                            expandedRow.row.Size = UDim2.new(1, -4, 0, PROP_ROW_H)
                            expandedRow.arrow.Text = "▸"
                        end
                        -- Fetch occupants only now (lazy, not polled)
                        local occ = getOccupants(propFolder)
                        occupantLabel.Text = #occ > 0
                            and ("Inside: " .. table.concat(occ, ", "))
                            or  "Nobody inside"
                        occupantLabel.TextColor3 = #occ > 0
                            and Color3.fromRGB(120, 200, 120)
                            or  Config.colors.textDim
                        detail.Visible = true
                        row.Size = UDim2.new(1, -4, 0, PROP_ROW_H + DETAIL_H)
                        arrow.Text = "▾"
                        expandedRow = rowData
                    end
                    recomputeCanvas()
                end)
            end

            listFrame.Visible = true
            recomputeCanvas()
        end

        scanBtn.MouseButton1Click:Connect(function()
            scanBtn.Text = "..."
            buildList()
            scanBtn.Text = "↻ Scan"
        end)
    else
        return false
    end
    return true
end

function createScriptQuaternaryUI(scriptData, container)
    if scriptData.isCarScanner then
        local CARD_H     = 76
        local DETAIL_H   = 104   -- extra rows for buttons
        local LIST_MAX_H = 380
        local HEADER_H   = 44
        local VP_W, VP_H = 86, 64

        -- ── Car-view ESP helpers ──────────────────────────────────────
        -- Outline-only highlights applied to a car model temporarily.
        -- Respects existing ESP: if stateAll.enabled we leave it alone.
        local csViewHighlights = {}  -- [model] = {Highlight, ...}
        local csViewWasESPOn    = false  -- did WE enable ESP?

        local function csApplyViewESP(model)
            if csViewHighlights[model] then return end
            local hls = {}
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local h = Instance.new("Highlight", part)
                    h.Adornee           = part
                    h.FillTransparency  = 1          -- no fill, outline only
                    h.OutlineColor      = Color3.fromRGB(80, 220, 80)
                    h.OutlineTransparency = 0
                    h.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
                    table.insert(hls, h)
                end
            end
            csViewHighlights[model] = hls
        end

        local function csRemoveViewESP(model)
            local hls = csViewHighlights[model]
            if not hls then return end
            for _, h in ipairs(hls) do pcall(function() h:Destroy() end) end
            csViewHighlights[model] = nil
        end

        container.Size = UDim2.new(1, -10, 0, 55 + HEADER_H + 4)

        local csBar = Instance.new("Frame", container)
        csBar.Size = UDim2.new(1, 0, 0, HEADER_H)
        csBar.Position = UDim2.new(0, 0, 0, 55)
        csBar.BackgroundTransparency = 1

        local csToggle = Instance.new("TextButton", csBar)
        csToggle.Size             = UDim2.new(0, 60, 0, 28)
        csToggle.Position         = UDim2.new(0, 10, 0, 8)
        csToggle.BackgroundColor3 = Config.colors.inactiveButton
        csToggle.TextColor3       = Config.colors.text
        csToggle.Text             = "OFF"
        csToggle.Font             = Enum.Font.GothamBold
        csToggle.TextSize         = 11
        csToggle.AutoButtonColor  = false
        Instance.new("UICorner", csToggle).CornerRadius = UDim.new(0, 6)

        local csCountLabel = Instance.new("TextLabel", csBar)
        csCountLabel.Size               = UDim2.new(1, -85, 0, 28)
        csCountLabel.Position           = UDim2.new(0, 80, 0, 8)
        csCountLabel.BackgroundTransparency = 1
        csCountLabel.Text               = "Click ON to start scanning"
        csCountLabel.TextColor3         = Config.colors.textDim
        csCountLabel.Font               = Enum.Font.Gotham
        csCountLabel.TextSize           = 11
        csCountLabel.TextXAlignment     = Enum.TextXAlignment.Left

        local csListFrame = Instance.new("ScrollingFrame", container)
        csListFrame.Size               = UDim2.new(1, -8, 0, 0)
        csListFrame.Position           = UDim2.new(0, 4, 0, 55 + HEADER_H)
        csListFrame.BackgroundTransparency = 1
        csListFrame.BorderSizePixel    = 0
        csListFrame.ScrollBarThickness = 3
        csListFrame.ScrollBarImageColor3 = Config.colors.accent
        csListFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
        csListFrame.Visible            = false
        local csLayout = Instance.new("UIListLayout", csListFrame)
        csLayout.Padding  = UDim.new(0, 3)
        csLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local csCards    = {}
        local csExpanded = nil
        local csVpConns  = {}
        local csRotConn  = nil
        local csCardN    = 0

        local function csRecompute()
            local total = 0
            for _, c in ipairs(csListFrame:GetChildren()) do
                if c:IsA("Frame") then total = total + c.Size.Y.Offset + 3 end
            end
            csListFrame.CanvasSize = UDim2.new(0, 0, 0, total)
            local visH = math.min(total, LIST_MAX_H)
            csListFrame.Size = UDim2.new(1, -8, 0, visH)
            local listH = csListFrame.Visible and visH or 0
            container.Size = UDim2.new(1, -10, 0, 55 + HEADER_H + listH + 4)
        end

        local function csStartRot()
            if csRotConn then return end
            csRotConn = RunService.RenderStepped:Connect(function(dt)
                for _, vp in ipairs(csVpConns) do
                    if vp.vpf and vp.vpf.Parent and vp.cam then
                        vp.angle = (vp.angle or 0) + dt * 0.65
                        local x   = math.cos(vp.angle) * vp.radius
                        local z   = math.sin(vp.angle) * vp.radius
                        local eye = Vector3.new(x, vp.centerY + vp.radius * 0.45, z)
                        vp.cam.CFrame = CFrame.new(eye, Vector3.new(0, vp.centerY, 0))
                    end
                end
            end)
        end

        local function csStopRot()
            if csRotConn then csRotConn:Disconnect() csRotConn = nil end
        end

        local function csMakeViewport(parent, model)
            local vpf = Instance.new("ViewportFrame", parent)
            vpf.Size             = UDim2.new(0, VP_W, 0, VP_H)
            vpf.Position         = UDim2.new(0, 4, 0.5, -(VP_H/2))
            vpf.BackgroundColor3 = Color3.fromRGB(8, 14, 8)
            vpf.BorderSizePixel  = 0
            vpf.Ambient          = Color3.fromRGB(160, 160, 160)
            vpf.LightDirection   = Vector3.new(-1, -2, -0.5)
            Instance.new("UICorner", vpf).CornerRadius = UDim.new(0, 5)

            local wm = Instance.new("WorldModel", vpf)
            local ok, clone = pcall(function() return model:Clone() end)
            if not ok then return vpf, nil, 6, 0 end

            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                    d:Destroy()
                end
            end
            pcall(function() clone:PivotTo(CFrame.new(0, 0, 0)) end)
            clone.Parent = wm

            local cam = Instance.new("Camera")
            cam.Parent       = vpf
            vpf.CurrentCamera = cam

            local ok2, cf, sz = pcall(function() return clone:GetBoundingBox() end)
            local radius  = ok2 and math.max(math.max(sz.X, sz.Z) * 0.75, 3) or 6
            local centerY = ok2 and cf.Position.Y or 0
            return vpf, cam, radius, centerY
        end

        local function csOwnerDist(model)
            local cfg = model:FindFirstChild("Config")
            local ldv = cfg and cfg:FindFirstChild("LastDrove")
            local owner = ldv and tostring(ldv.Value) or ""
            if owner == "" then return "No owner data" end
            local ds = model:FindFirstChild("DriveSeat")
            local dsPos = ds and ds:IsA("BasePart") and ds.Position
            if not dsPos then return owner .. " (no seat)" end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == owner then
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        return owner .. "  –  " .. math.round((hrp.Position - dsPos).Magnitude) .. " studs"
                    end
                    return owner .. " (no character)"
                end
            end
            return owner .. " (not in server)"
        end

        local function csAddCard(model, afkSince)
            if csCards[model] then return end
            csCardN = csCardN + 1

            local cfg = model:FindFirstChild("Config")
            local slv = cfg and cfg:FindFirstChild("SecurityLevel")
            local sl  = slv and slv.Value or "?"

            local row = Instance.new("Frame", csListFrame)
            row.Size             = UDim2.new(1, -4, 0, CARD_H)
            row.BackgroundColor3 = Color3.fromRGB(12, 20, 12)
            row.BorderSizePixel  = 0
            row.LayoutOrder      = csCardN
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

            local vpf, cam, radius, centerY = csMakeViewport(row, model)

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size             = UDim2.new(1, -(VP_W + 22), 0, 22)
            nameLbl.Position         = UDim2.new(0, VP_W + 12, 0, 8)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text             = model.Name
            nameLbl.TextColor3       = Color3.fromRGB(180, 230, 180)
            nameLbl.Font             = Enum.Font.GothamBold
            nameLbl.TextSize         = 11
            nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
            nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd

            local secLbl = Instance.new("TextLabel", row)
            secLbl.Size             = UDim2.new(0, 80, 0, 16)
            secLbl.Position         = UDim2.new(0, VP_W + 12, 0, 32)
            secLbl.BackgroundTransparency = 1
            secLbl.Text             = "🔒 Level " .. tostring(sl)
            secLbl.TextColor3       = (sl == 1)
                and Color3.fromRGB(100, 220, 100)
                or  Color3.fromRGB(220, 180, 60)
            secLbl.Font             = Enum.Font.Gotham
            secLbl.TextSize         = 10
            secLbl.TextXAlignment   = Enum.TextXAlignment.Left

            local arrow = Instance.new("TextLabel", row)
            arrow.Size             = UDim2.new(0, 18, 0, CARD_H)
            arrow.Position         = UDim2.new(1, -20, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text             = "▸"
            arrow.TextColor3       = Color3.fromRGB(100, 160, 100)
            arrow.Font             = Enum.Font.GothamBold
            arrow.TextSize         = 11
            arrow.TextXAlignment   = Enum.TextXAlignment.Center

            local detail = Instance.new("Frame", row)
            detail.Size             = UDim2.new(1, 0, 0, DETAIL_H)
            detail.Position         = UDim2.new(0, 0, 0, CARD_H)
            detail.BackgroundColor3 = Color3.fromRGB(8, 14, 8)
            detail.BorderSizePixel  = 0
            detail.Visible          = false
            Instance.new("UICorner", detail).CornerRadius = UDim.new(0, 5)

            local function mkD(y, txt)
                local l = Instance.new("TextLabel", detail)
                l.Size = UDim2.new(1, -100, 0, 16)  -- narrower to leave room for buttons
                l.Position = UDim2.new(0, 6, 0, y)
                l.BackgroundTransparency = 1
                l.Text = txt
                l.TextColor3 = Color3.fromRGB(160, 200, 160)
                l.Font = Enum.Font.Gotham
                l.TextSize = 11
                l.TextXAlignment = Enum.TextXAlignment.Left
                return l
            end

            local afkLbl  = mkD(4,  "⏱  AFK: calculating...")
            local ownLbl  = mkD(22, "👤  Owner: ...")
            local distLbl = mkD(40, "📍  Owner dist: ...")
            mkD(57, "🔒  Security: Level " .. tostring(sl))

            -- View toggle button
            local viewActive = false
            local viewBtn = Instance.new("TextButton", detail)
            viewBtn.Size             = UDim2.new(0, 74, 0, 26)
            viewBtn.Position         = UDim2.new(0, 6, 0, 74)
            viewBtn.BackgroundColor3 = Color3.fromRGB(25, 55, 25)
            viewBtn.TextColor3       = Color3.fromRGB(120, 220, 120)
            viewBtn.Text             = "👁 View"
            viewBtn.Font             = Enum.Font.GothamBold
            viewBtn.TextSize         = 11
            viewBtn.AutoButtonColor  = false
            Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 5)

            local function stopView()
                if not viewActive then return end
                viewActive = false
                viewBtn.Text             = "👁 View"
                viewBtn.BackgroundColor3 = Color3.fromRGB(25, 55, 25)
                csRemoveViewESP(model)
                -- Restore camera subject to our own humanoid
                local myHum = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if myHum then
                    Camera.CameraSubject = myHum
                    Camera.CameraType    = Enum.CameraType.Custom
                end
            end

            viewBtn.MouseButton1Click:Connect(function()
                viewActive = not viewActive
                if viewActive then
                    viewBtn.Text             = "👁 Viewing"
                    viewBtn.BackgroundColor3 = Color3.fromRGB(20, 90, 20)
                    csApplyViewESP(model)
                    -- Point camera at the DriveSeat (same mechanism as View Player)
                    local ds = model:FindFirstChild("DriveSeat")
                    if ds and ds:IsA("BasePart") then
                        Camera.CameraSubject = ds
                        Camera.CameraType    = Enum.CameraType.Custom
                    end
                else
                    stopView()
                end
            end)

            -- TP button
            local tpBtn = Instance.new("TextButton", detail)
            tpBtn.Size             = UDim2.new(0, 74, 0, 26)
            tpBtn.Position         = UDim2.new(0, 88, 0, 74)
            tpBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
            tpBtn.TextColor3       = Color3.fromRGB(130, 180, 255)
            tpBtn.Text             = "→ TP"
            tpBtn.Font             = Enum.Font.GothamBold
            tpBtn.TextSize         = 11
            tpBtn.AutoButtonColor  = false
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)

            tpBtn.MouseButton1Click:Connect(function()
                -- If viewing, stop view first
                if viewActive then stopView() end

                local ds = model:FindFirstChild("DriveSeat")
                local hrp = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and ds and ds:IsA("BasePart") then
                    hrp.CFrame = ds.CFrame + Vector3.new(0, 4, 0)
                    tpBtn.Text             = "✓"
                    tpBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 120)
                    task.delay(1.5, function()
                        tpBtn.Text             = "→ TP"
                        tpBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
                    end)
                end
            end)

            local vpData = nil
            if cam then
                vpData = { vpf = vpf, cam = cam, radius = radius, centerY = centerY,
                           angle = math.random() * math.pi * 2 }
                table.insert(csVpConns, vpData)
                csStartRot()
            end

            local rd = { row = row, detail = detail, arrow = arrow,
                         afkSince = afkSince or tick(),
                         afkLbl = afkLbl, ownLbl = ownLbl, distLbl = distLbl,
                         vpData = vpData, cfg = cfg }
            csCards[model] = rd

            -- Transparent full-row hit button
            local hitBtn = Instance.new("TextButton", row)
            hitBtn.Size             = UDim2.new(1, 0, 0, CARD_H)
            hitBtn.BackgroundTransparency = 1
            hitBtn.Text             = ""
            hitBtn.AutoButtonColor  = false
            hitBtn.ZIndex           = 3

            hitBtn.MouseButton1Click:Connect(function()
                if csExpanded and csExpanded.row == row then
                    detail.Visible = false
                    row.Size = UDim2.new(1, -4, 0, CARD_H)
                    arrow.Text = "▸"
                    csExpanded = nil
                else
                    if csExpanded then
                        csExpanded.detail.Visible = false
                        csExpanded.row.Size = UDim2.new(1, -4, 0, CARD_H)
                        csExpanded.arrow.Text = "▸"
                    end
                    -- Lazy-update detail fields
                    local afkSecs = math.floor(tick() - rd.afkSince)
                    afkLbl.Text = "⏱  AFK: " .. (afkSecs < 60
                        and (afkSecs .. "s")
                        or  (math.floor(afkSecs/60) .. "m " .. (afkSecs%60) .. "s"))
                    local ldv   = cfg and cfg:FindFirstChild("LastDrove")
                    local owner = ldv and tostring(ldv.Value) or ""
                    ownLbl.Text  = "👤  Owner: " .. (owner ~= "" and owner or "None")
                    distLbl.Text = "📍  Owner dist: " .. csOwnerDist(model)
                    detail.Visible = true
                    row.Size = UDim2.new(1, -4, 0, CARD_H + DETAIL_H)
                    arrow.Text = "▾"
                    csExpanded = rd
                end
                csRecompute()
            end)

            csListFrame.Visible = true
            csRecompute()
        end

        local function csRemoveCard(model)
            local rd = csCards[model]
            if not rd then return end
            csCardN = math.max(0, csCardN - 1)
            -- Clean up view ESP and restore camera if this card was being viewed
            csRemoveViewESP(model)
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if myHum and Camera.CameraSubject ~= myHum then
                local ds = model:FindFirstChild("DriveSeat")
                if ds and Camera.CameraSubject == ds then
                    Camera.CameraSubject = myHum
                    Camera.CameraType    = Enum.CameraType.Custom
                end
            end
            if rd.vpData then
                for i, v in ipairs(csVpConns) do
                    if v == rd.vpData then table.remove(csVpConns, i) break end
                end
                if #csVpConns == 0 then csStopRot() end
            end
            if csExpanded and csExpanded.row == rd.row then csExpanded = nil end
            rd.row:Destroy()
            csCards[model] = nil
            if csCardN == 0 then
                csListFrame.Visible = false
                csCountLabel.Text = "No eligible parked cars found"
                csRecompute()
            end
        end

        -- _G bridges for the monitor task.spawn
        _G.CarScanner_Add       = csAddCard
        _G.CarScanner_Remove    = csRemoveCard
        _G.CarScanner_IsActive  = function() return scriptData.active end
        _G.CarScanner_SetCount  = function(n, confirming)
            local parts = {}
            if n > 0 then
                table.insert(parts, n .. " parked car" .. (n == 1 and "" or "s"))
            end
            if confirming and confirming > 0 then
                table.insert(parts, "⏳ " .. confirming .. " confirming...")
            end
            if #parts == 0 then
                csCountLabel.Text = "No eligible parked cars found"
            else
                csCountLabel.Text = table.concat(parts, "  |  ")
            end
        end

        csToggle.MouseButton1Click:Connect(function()
            scriptData.active = not scriptData.active
            csToggle.BackgroundColor3 = scriptData.active
                and Config.colors.activeButton or Config.colors.inactiveButton
            csToggle.Text = scriptData.active and "ON" or "OFF"
            if scriptData.active then
                csCountLabel.Text = "Scanning..."
                if _G.CarScanner_Start then _G.CarScanner_Start() end
            else
                if _G.CarScanner_Stop then _G.CarScanner_Stop() end
                for m in pairs(csCards) do csRemoveCard(m) end
                csCardN = 0
                csListFrame.Visible = false
                csCountLabel.Text = "Click ON to start scanning"
                csRecompute()
            end
        end)
    elseif scriptData.isESPAll then
        createESPAllUI(scriptData, container)

    elseif scriptData.isESPTeam then
        createESPTeamUI(scriptData, container)

    else
        createGenericToggleUI(scriptData, container)
    end
    return true
end

function createScriptToggle(scriptData, index)
    local container = Instance.new("Frame")
    container.Name = "Script_" .. index
    local baseHeight = 55
    if scriptData.isClickTP and scriptData.active then
        baseHeight = 105
    elseif scriptData.isFly and scriptData.active then
        baseHeight = 148
    elseif scriptData.isAimbot and scriptData.active then
        baseHeight = scriptData.optionsCollapsed and 84 or (AIMBOT_CONFIG.filterMode ~= "None" and 700 or 568)
    elseif scriptData.isAdvancedESP and scriptData.active then
        baseHeight = scriptData.optionsCollapsed and 84 or 1160
    elseif scriptData.isESPTeam and scriptData.active then
        baseHeight = 205
    elseif scriptData.isESPAll and stateAll.enabled then
        baseHeight = 170
    elseif scriptData.isHitboxExpander and headState.enabled then
        baseHeight = 227
    end
    container.Size = UDim2.new(1, -10, 0, baseHeight)
    container.BackgroundColor3 = Config.colors.scriptBg
    container.Active = true
    container.Parent = scriptPanel

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 9)
    containerCorner.Parent = container

    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and _G.GtaNav_SetScript then
            _G.GtaNav_SetScript(index)
        end
    end)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -150, 0, 55)
    label.Position = UDim2.new(0, 18, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = scriptData.name
    label.TextColor3 = Config.colors.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local handled = createScriptPrimaryUI(scriptData, container)
        or createScriptSecondaryUI(scriptData, container)
        or createScriptTertiaryUI(scriptData, container)
        or createScriptQuaternaryUI(scriptData, container)
end

-- _G bridge: save system calls this to fire a toggle when loading a preset
_G.SaveSystem_DispatchToggle = function(scriptData)
    if scriptData.isClickTP       then toggleClickTP(scriptData.active) end
    if scriptData.isFly           then toggleFly(scriptData.active) end
    if scriptData.isAimbot        then toggleAimbot(scriptData.active) end
    if scriptData.isAdvancedESP   then toggleAdvancedESP(scriptData.active) end
    if scriptData.isSafeRob       then toggleSafeRob(scriptData.active) end
    if scriptData.isInfAmmo       then toggleInfAmmo(scriptData.active) end
    if scriptData.isBypassAll     then toggleBypassAll(scriptData.active) end
    if scriptData.isCarNoDamage   then toggleCarNoDamage(scriptData.active) end
    if scriptData.isAtmHack       then toggleAtmHack(scriptData.active) end
    if scriptData.isRemoveRedSpeed then toggleRedLightSpeed(scriptData.active) end
    if scriptData.isInfZoom       then toggleInfZoom(scriptData.active) end
    if scriptData.isInstantInteract then toggleInstantInteract(scriptData.active) end
    if scriptData.isGolfFarm      then toggleGolfFarm(scriptData.active) end
    if scriptData.isInfStats      then toggleInfStats(scriptData.active) end
    if scriptData.isAvoidDeath    then toggleAvoidDeath(scriptData.active) end
    if scriptData.isChangeAVS     then toggleChangeAVS(scriptData.active) end
    if scriptData.isAutoATM       then toggleAutoATM(scriptData.active) end
    if scriptData.isESPAll        then if scriptData.active and not stateAll.enabled then toggleESPAll() end end
    if scriptData.isESPTeam       then if scriptData.active and not stateTeam.enabled then toggleESPTeam() end end
    if scriptData.isInfZoom       then toggleInfZoom(scriptData.active) end
    if scriptData.isAntiArrest    then toggleAntiArrest(scriptData.active) end
    if scriptData.isExpandCuffs   then toggleExpandCuffs(scriptData.active) end
    if scriptData.isHouseAntiKick then toggleHouseAntiKick(scriptData.active) end
    if scriptData.isInvisibility  then toggleInvisibilitySystem(scriptData.active) end
    if scriptData.isNoProps       then toggleNoProps(scriptData.active) end
    if scriptData.isHitboxExpander then if scriptData.active then toggleHitbox(true) end end
end

_G.SaveSystem_RefreshScriptUI = function()
    refreshScripts()
end

function refreshScripts()
    clearScriptPanelUiConnections()
    clearExpandedNavItems()
    for _, child in ipairs(scriptPanel:GetChildren()) do 
        if child:IsA("Frame") then child:Destroy() end 
    end
    local cat = Config.categories[Config.selectedCategory]
    for i, v in ipairs(cat.scripts) do 
        createScriptToggle(v, i) 
    end
    if _G.GtaNav_Refresh then task.defer(_G.GtaNav_Refresh) end
end

local categoryButtons = {}
gtaNav = { scriptIndex = 1, visible = false, lastArrowAt = 0 }

function gtaNavTargetVisible(target)
    local node = target
    while node and node ~= screenGui do
        if node:IsA("GuiObject") and not node.Visible then return false end
        node = node.Parent
    end
    return true
end

function gtaExpandedItemsForCurrentScript()
    local items = {}
    for _, item in ipairs(_G.LizardExpandedNav or {}) do
        if item.container and item.container.Parent and item.container.Name == "Script_" .. tostring(gtaNav.scriptIndex)
            and item.container.AbsoluteSize.Y > 70 and item.target and item.target.Parent and gtaNavTargetVisible(item.target) then
            table.insert(items, item)
        end
    end
    table.sort(items, function(a, b)
        return a.target.AbsolutePosition.Y < b.target.AbsolutePosition.Y
    end)
    return items
end

function gtaGetExpandedItem()
    local items = gtaExpandedItemsForCurrentScript()
    if #items == 0 then gtaNav.optionIndex = nil return nil, items end
    if gtaNav.optionIndex == nil then return nil, items end
    gtaNav.optionIndex = math.clamp(gtaNav.optionIndex, 1, #items)
    return items[gtaNav.optionIndex], items
end

function gtaScrollTargetIntoView(target, scrollParent)
    if not target or not scriptPanel then return end
    if scrollParent and scrollParent.Parent then
        local innerTop = scrollParent.AbsolutePosition.Y
        local innerBottom = innerTop + scrollParent.AbsoluteSize.Y
        local targetTop = target.AbsolutePosition.Y
        local targetBottom = targetTop + target.AbsoluteSize.Y
        local innerY = scrollParent.CanvasPosition.Y
        if targetTop < innerTop + 4 then
            innerY = math.max(0, innerY - ((innerTop + 4) - targetTop))
        elseif targetBottom > innerBottom - 4 then
            innerY = innerY + (targetBottom - (innerBottom - 4))
        end
        if innerY ~= scrollParent.CanvasPosition.Y then
            scrollParent.CanvasPosition = Vector2.new(scrollParent.CanvasPosition.X, innerY)
        end
    end
    local panelTop = scriptPanel.AbsolutePosition.Y
    local panelBottom = panelTop + scriptPanel.AbsoluteSize.Y
    local targetTop = target.AbsolutePosition.Y
    local targetBottom = targetTop + target.AbsoluteSize.Y
    local newY = scriptPanel.CanvasPosition.Y
    if targetTop < panelTop + 8 then
        newY = math.max(0, newY - ((panelTop + 8) - targetTop))
    elseif targetBottom > panelBottom - 8 then
        newY = newY + (targetBottom - (panelBottom - 8))
    end
    if newY ~= scriptPanel.CanvasPosition.Y then
        scriptPanel.CanvasPosition = Vector2.new(scriptPanel.CanvasPosition.X, newY)
    end
end

function gtaExpandedNavStep(delta)
    local items = gtaExpandedItemsForCurrentScript()
    if #items == 0 then return false end
    if gtaNav.optionIndex == nil then return false end
    local nextIndex = gtaNav.optionIndex + delta
    if nextIndex < 1 or nextIndex > #items then return false end
    gtaNav.optionIndex = nextIndex
    if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
    return true
end

function gtaExpandedNavAdjust(delta)
    local item = gtaGetExpandedItem()
    if not item then return false end
    local fn = delta > 0 and item.right or item.left
    if fn then fn(); if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end return true end
    return false
end

function gtaExpandedNavActivate()
    local item = gtaGetExpandedItem()
    if item and item.activate then item.activate(); if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end return true end
    return false
end

local gtaNavBox = Instance.new("Frame")
gtaNavBox.Name = "GtaNavSelection"
gtaNavBox.BackgroundTransparency = 1
gtaNavBox.BorderSizePixel = 0
gtaNavBox.Visible = false
gtaNavBox.ZIndex = 200
gtaNavBox.Parent = mainFrame
Instance.new("UICorner", gtaNavBox).CornerRadius = UDim.new(0, 8)
local gtaNavStroke = Instance.new("UIStroke", gtaNavBox)
gtaNavStroke.Color = Config.colors.accent
gtaNavStroke.Thickness = 1.5
gtaNavStroke.Transparency = 0
local gtaNavBoxTween = nil

function gtaHideSelectionBox()
    if gtaNav then gtaNav.visible = false end
    if gtaNavBox then gtaNavBox.Visible = false end
end

function gtaResolveSelectionTarget()
    local expandedItem = gtaGetExpandedItem()
    local target = expandedItem and (expandedItem.visualTarget or expandedItem.target) or scriptPanel:FindFirstChild("Script_" .. tostring(gtaNav.scriptIndex))
    if not target then
        local catData = categoryButtons[Config.selectedCategory]
        target = catData and catData.btn
    end
    return target, expandedItem
end

function gtaPaintSelectionBox(target, expandedItem, instant)
    if not gtaNav.visible or not target or not target.Parent or not gtaNavTargetVisible(target) then
        gtaNavBox.Visible = false
        return
    end

    local mainAbs = mainFrame.AbsolutePosition
    local targetAbs = target.AbsolutePosition
    local inset = expandedItem and 1 or 0
    local pos = UDim2.fromOffset(targetAbs.X - mainAbs.X - inset, targetAbs.Y - mainAbs.Y - inset)
    local size = UDim2.fromOffset(target.AbsoluteSize.X + inset * 2, target.AbsoluteSize.Y + inset * 2)
    gtaNavBox.Visible = true
    if gtaNavBoxTween then pcall(function() gtaNavBoxTween:Cancel() end) end
    if instant then
        gtaNavBox.Position = pos
        gtaNavBox.Size = size
        return
    end
    gtaNavBoxTween = TweenService:Create(gtaNavBox, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = pos,
        Size = size,
    })
    gtaNavBoxTween:Play()
end

function gtaRepaintSelectionBox(instant)
    if not gtaNav or not gtaNav.visible then return end
    local target, expandedItem = gtaResolveSelectionTarget()
    gtaPaintSelectionBox(target, expandedItem, instant == true)
end

function gtaShowSelection()
    gtaNav.visible = true
    gtaNav.lastArrowAt = tick()
    if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
    local stamp = gtaNav.lastArrowAt
    task.delay(15, function()
        if gtaNav.lastArrowAt == stamp and tick() - stamp >= 15 then
            gtaNav.visible = false
            if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
        end
    end)
end

function gtaSetScriptIndex(index)
    local cat = Config.categories[Config.selectedCategory]
    local count = cat and #cat.scripts or 1
    gtaNav.scriptIndex = math.clamp(index, 1, math.max(count, 1))
    gtaNav.optionIndex = nil
    if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
end

_G.GtaNav_SetScript = gtaSetScriptIndex

function gtaSetCategory(index)
    local old = categoryButtons[Config.selectedCategory]
    if old then
        old.btn.BackgroundColor3 = Config.colors.categoryBg
        old.btn.TextColor3 = Config.colors.textDim
        old.bar.Visible = false
    end

    Config.selectedCategory = math.clamp(index, 1, #Config.categories)
    gtaNav.scriptIndex = 1
    gtaNav.optionIndex = nil

    local current = categoryButtons[Config.selectedCategory]
    if current then
        current.btn.BackgroundColor3 = Config.colors.categorySelected
        current.btn.TextColor3 = Config.colors.text
        current.bar.Visible = true
    end

    refreshScripts()
end

function gtaActivateSelected()
    local cat = Config.categories[Config.selectedCategory]
    local scriptData = cat and cat.scripts[gtaNav.scriptIndex]
    if not scriptData then return end
    gtaNav.optionIndex = nil

    if scriptData.isAimbot then
        scriptData.active = not scriptData.active
        toggleAimbot(scriptData.active)
    elseif scriptData.isAdvancedESP then
        scriptData.active = not scriptData.active
        toggleAdvancedESP(scriptData.active)
    elseif scriptData.isHitboxExpander then
        scriptData.active = not headState.enabled
        toggleHitbox(scriptData.active)
    elseif scriptData.isUGCEmotes then
        runUGCEmotes()
    elseif scriptData.isZombie then
        runZombieScript()
    elseif scriptData.isViolentMenu then
        task.spawn(function()
            loadstring(game:HttpGet("https://vt-now.github.io/VIOLENT/vt.lua"))()
        end)
    elseif scriptData.isTeleportPoint then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(scriptData.tpPos) end
    elseif scriptData.isClickTP or scriptData.isFly or scriptData.isSafeRob or scriptData.isInfAmmo
        or scriptData.isBypassAll or scriptData.isCarNoDamage or scriptData.isAutoATM
        or scriptData.isRemoveRedSpeed or scriptData.isInfZoom or scriptData.isInstantInteract
        or scriptData.isGolfFarm or scriptData.isInfStats or scriptData.isAvoidDeath
        or scriptData.isAntiArrest or scriptData.isHouseAntiKick or scriptData.isExpandCuffs
        or scriptData.isChangeAVS or scriptData.isInvisibility or scriptData.isNoProps
        or scriptData.isESPAll or scriptData.isESPTeam or scriptData.isAdvancedESP then
        scriptData.active = not scriptData.active
        if _G.SaveSystem_DispatchToggle then _G.SaveSystem_DispatchToggle(scriptData) end
    end

    refreshScripts()
end

_G.GtaNav_Refresh = function()
    if not gtaNav.visible then
        gtaNavBox.Visible = false
        return
    end

    local target, expandedItem = gtaResolveSelectionTarget()
    if not target then
        gtaNavBox.Visible = false
        return
    end

    gtaScrollTargetIntoView(target, expandedItem and expandedItem.scrollParent)
    task.defer(function()
        local latestTarget, latestExpandedItem = gtaResolveSelectionTarget()
        gtaPaintSelectionBox(latestTarget, latestExpandedItem)
    end)
end

scriptPanel:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if gtaNav and gtaNav.visible and gtaRepaintSelectionBox then
        task.defer(function() gtaRepaintSelectionBox(false) end)
    end
end)

function createCategoryButton(categoryData, index)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 36)
    button.BackgroundColor3 = Config.selectedCategory == index and Config.colors.categorySelected or Config.colors.categoryBg
    button.Text = "      " .. categoryData.name
    button.TextColor3 = Config.selectedCategory == index and Config.colors.text or Config.colors.textDim
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = categoryList
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    -- ULTRA SLIM BAR
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 2, 0, 16)
    accentBar.Position = UDim2.new(0, 8, 0.5, -8) 
    accentBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    accentBar.BorderSizePixel = 0
    accentBar.Visible = (Config.selectedCategory == index)
    accentBar.Parent = button

    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.colors.accent),
        ColorSequenceKeypoint.new(1, Config.colors.accent:Lerp(Color3.fromRGB(0,0,0), 0.3))
    })
    barGradient.Rotation = 90
    barGradient.Parent = accentBar

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = accentBar

    categoryButtons[index] = {btn = button, bar = accentBar}

    button.MouseButton1Click:Connect(function()
        gtaSetCategory(index)

        -- One-time per session popup when entering AVATARS
        if categoryData.name == "AVATARS" and not _G.AvatarCategoryShownTip then
            _G.AvatarCategoryShownTip = true
            local tipGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
            tipGui.Name = "AvatarTip"; tipGui.ResetOnSpawn = false; tipGui.DisplayOrder = 1000000010
            local tipF = Instance.new("Frame", tipGui)
            tipF.Size = UDim2.new(0, 400, 0, 140)
            tipF.Position = UDim2.new(0.5, -200, 0.5, -70)
            tipF.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
            tipF.BorderSizePixel = 0
            Instance.new("UICorner", tipF).CornerRadius = UDim.new(0, 10)
            local tipStroke = Instance.new("UIStroke", tipF)
            tipStroke.Color = Color3.fromRGB(100, 60, 200); tipStroke.Thickness = 1.5
            local tipTitle = Instance.new("TextLabel", tipF)
            tipTitle.Size = UDim2.new(1, -16, 0, 24)
            tipTitle.Position = UDim2.new(0, 8, 0, 8)
            tipTitle.BackgroundTransparency = 1
            tipTitle.Text = "👤  How to use Avatar Saves"
            tipTitle.TextColor3 = Color3.fromRGB(200, 160, 255)
            tipTitle.Font = Enum.Font.GothamBold
            tipTitle.TextSize = 14
            tipTitle.TextXAlignment = Enum.TextXAlignment.Left
            local tipBody = Instance.new("TextLabel", tipF)
            tipBody.Size = UDim2.new(1, -16, 0, 70)
            tipBody.Position = UDim2.new(0, 8, 0, 36)
            tipBody.BackgroundTransparency = 1
            tipBody.Text = "Before clicking Import Avatar, open the in-game\nAvatar Shop and navigate to the Import tab\n(the bag icon where you type an Asset ID).\n\nThen press Import Avatar and follow the instructions."
            tipBody.TextColor3 = Color3.fromRGB(200, 195, 220)
            tipBody.Font = Enum.Font.Gotham
            tipBody.TextSize = 12
            tipBody.TextXAlignment = Enum.TextXAlignment.Left
            tipBody.TextWrapped = true
            local tipClose = Instance.new("TextButton", tipF)
            tipClose.Size = UDim2.new(0, 120, 0, 28)
            tipClose.Position = UDim2.new(0.5, -60, 1, -36)
            tipClose.BackgroundColor3 = Color3.fromRGB(45, 25, 80)
            tipClose.TextColor3 = Color3.fromRGB(200, 160, 255)
            tipClose.Text = "Got it"
            tipClose.Font = Enum.Font.GothamBold
            tipClose.TextSize = 12
            tipClose.AutoButtonColor = false
            Instance.new("UICorner", tipClose).CornerRadius = UDim.new(0, 6)
            tipClose.MouseButton1Click:Connect(function() tipGui:Destroy() end)
        end
    end)
end

for i, v in ipairs(Config.categories) do createCategoryButton(v, i) end
refreshScripts()

-- Events
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Config.openKey then
        toggleMenu()
        return
    end
    if menuOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
        gtaHideSelectionBox()
    end
    if gp or UserInputService:GetFocusedTextBox() or not menuOpen then return end
    if input.KeyCode == Enum.KeyCode.Down then
        return
    elseif input.KeyCode == Enum.KeyCode.Up then
        return
    elseif input.KeyCode == Enum.KeyCode.Right then
        return
    elseif input.KeyCode == Enum.KeyCode.Left then
        return
    elseif input.KeyCode == Enum.KeyCode.Return then
        if not gtaExpandedNavActivate or not gtaExpandedNavActivate() then
            gtaActivateSelected()
        end
    elseif input.KeyCode == Enum.KeyCode.Backspace then
        if gtaNav and gtaNav.optionIndex ~= nil then
            gtaNav.optionIndex = nil
            if _G.GtaNav_Refresh then _G.GtaNav_Refresh() end
        else
            toggleMenu()
        end
    end
end)

homeButton.MouseButton1Click:Connect(function()
    homeButton.Text = "..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Keybinds.menuOpen = input.KeyCode
            applySavedKeybinds(serializeKeybinds())
            connection:Disconnect()
        end
    end)
end)

unloadButton.MouseButton1Click:Connect(function() 
    clearESP()
    clearAllESP()
    clearTeamESP()
    clearView()
    toggleInstantInteract(false)
    toggleAutoATM(false)
toggleInvisibilitySystem(false)
    toggleClickTP(false)
    toggleAutoRespawn(false)
    toggleAimbot(false)
    toggleAdvancedESP(false)
    toggleFly(false)
    toggleSafeRob(false)
    toggleNoProps(false)
    toggleInfStats(false)
    toggleAvoidDeath(false)
    toggleAntiArrest(false)
    toggleHouseAntiKick(false)
    toggleExpandCuffs(false)
    toggleChangeAVS(false)
    if headState.enabled then cleanupHitbox() end
    if clearScriptPanelUiConnections then clearScriptPanelUiConnections() end
    screenGui:Destroy() 
end)

-- Drag System
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        mainFrame.Position = newPos
        savedPosition = newPos -- Sauvegarder la nouvelle position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
    end
end)

-- Resize System
local resizing = false
local resizeStart = nil
local startSize = nil
local startResizePos = nil

local resizeHandle = Instance.new("Frame")
resizeHandle.Size = UDim2.new(0, 20, 0, 20)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.BackgroundColor3 = Config.colors.accent
resizeHandle.BackgroundTransparency = 0.5
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 10
resizeHandle.Parent = mainFrame

local resizeCorner = Instance.new("UICorner")
resizeCorner.CornerRadius = UDim.new(0, 4)
resizeCorner.Parent = resizeHandle

-- Icon resize (3 lignes diagonales)
local resizeIcon = Instance.new("TextLabel")
resizeIcon.Size = UDim2.new(1, 0, 1, 0)
resizeIcon.BackgroundTransparency = 1
resizeIcon.Text = "⋰"
resizeIcon.TextColor3 = Config.colors.text
resizeIcon.Font = Enum.Font.GothamBold
resizeIcon.TextSize = 16
resizeIcon.Rotation = 90
resizeIcon.Parent = resizeHandle

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        startSize = mainFrame.Size
        startResizePos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        
        local newWidth = math.max(Config.minSize.width, startSize.X.Offset + delta.X)
        local newHeight = math.max(Config.minSize.height, startSize.Y.Offset + delta.Y)
        
        mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        Config.size = mainFrame.Size
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)
end) -- GUI BUILD SCOPE END
-- ============================================================
task.spawn(function()

local SB_OWNER        = "YOUR_USERNAME_HERE"   -- ← paste your Roblox username
local SB_API_KEY      = "$2a$10$JqiO3pd./wDskS11hvZTL.vO/ta8vx0yZfMV1.VZVwR2nZ.BuMZSi"
local SB_BIN_ID       = "69aaccd543b1c97be9b9ca7f"
local SB_STALE_SEC    = 90    -- entries older than this (seconds) are treated as offline
local SB_HEARTBEAT_SEC = 40   -- how often this client updates its own entry

local SB_BASE_URL = "https://api.jsonbin.io/v3/b/" .. SB_BIN_ID
local SB_HEADERS  = {
    ["X-Master-Key"] = SB_API_KEY,
    ["Content-Type"] = "application/json",
}

-- Only the owner's username bypasses the password prompt automatically

-- ── helpers ──────────────────────────────────────────────────
-- Executors expose HTTP differently — find whichever one exists
function execRequest(options)
    if type(request) == "function" then
        return request(options)
    elseif type(http_request) == "function" then
        return http_request(options)
    elseif syn and type(syn.request) == "function" then
        return syn.request(options)
    elseif http and type(http.request) == "function" then
        return http.request(options)
    else
        error("No HTTP function available in this executor")
    end
end

function sbRequest(method, body)
    local ok, res = pcall(function()
        return execRequest({
            Url     = SB_BASE_URL,
            Method  = method,
            Headers = SB_HEADERS,
            Body    = body,
        })
    end)
    if not ok or not res then return nil end
    -- Some executors return StatusCode, others return status_code
    local code = res.StatusCode or res.status_code or 0
    if code < 200 or code >= 300 then return nil end
    local body_text = res.Body or res.body or ""
    local dok, data = pcall(function() return HttpService:JSONDecode(body_text) end)
    return dok and data or nil
end

function sbRead()
    local data = sbRequest("GET", nil)
    -- jsonbin wraps the record under .record, players are under .record.players
    if data and data.record and data.record.players then return data.record.players end
    return {}
end

function sbWrite(tbl)
    sbRequest("PUT", HttpService:JSONEncode({ players = tbl }))
end

function sbTimestamp()
    return os.time()  -- always Unix epoch, consistent across all clients
end

-- ── registration / heartbeat ────────────────────────────────
function sbRegister()
    task.spawn(function()
        -- Random jitter (0–3s) so multiple clients don't read/write simultaneously
        task.wait(math.random() * 3)

        -- Retry up to 3 times in case of a write collision
        for attempt = 1, 3 do
            local ok, entries = pcall(sbRead)
            if not ok or type(entries) ~= "table" then entries = {} end

            entries[LocalPlayer.Name] = {
                jobId     = tostring(game.JobId),
                placeId   = tonumber(game.PlaceId),
                timestamp = sbTimestamp(),
            }

            local wok = pcall(sbWrite, entries)
            if wok then break end

            -- Write failed — wait a bit then retry
            task.wait(1 + math.random() * 2)
        end
    end)
end

function sbUnregister()
    task.spawn(function()
        local ok, entries = pcall(sbRead)
        if not ok then return end
        entries[LocalPlayer.Name] = nil
        pcall(sbWrite, entries)
    end)
end

-- Register on load
sbRegister()

-- Heartbeat: keep our entry fresh so we appear online
-- Initial random offset so clients don't all pulse at the same time
task.spawn(function()
    task.wait(math.random(1, SB_HEARTBEAT_SEC))
    while true do
        sbRegister()
        task.wait(SB_HEARTBEAT_SEC)
    end
end)

local SB_PASSWORD = "AdminAccessPhase2Interactive2026"
local sbUnlocked  = (LocalPlayer.Name == SB_OWNER)  -- owner username still bypasses instantly

-- ── Password prompt UI (visible to everyone, triggered by Ctrl+Alt+X) ──
local sbGui = Instance.new("ScreenGui", playerGui)
sbGui.Name           = "ServerBrowserUI"
sbGui.ResetOnSpawn   = false
sbGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sbGui.DisplayOrder   = 1000000000  -- above main GUI's 999999999

local sbPrompt = Instance.new("Frame", sbGui)
sbPrompt.Size             = UDim2.new(0, 260, 0, 110)
sbPrompt.Position         = UDim2.new(0.5, -130, 0.5, -55)
sbPrompt.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
sbPrompt.BorderSizePixel  = 0
sbPrompt.Visible          = false
sbPrompt.ZIndex           = 20
Instance.new("UICorner", sbPrompt).CornerRadius = UDim.new(0, 10)
local sbPromptStroke = Instance.new("UIStroke", sbPrompt)
sbPromptStroke.Color     = Color3.fromRGB(80, 40, 140)
sbPromptStroke.Thickness = 1.5

local sbPromptTitle = Instance.new("TextLabel", sbPrompt)
sbPromptTitle.Size               = UDim2.new(1, 0, 0, 30)
sbPromptTitle.Position           = UDim2.new(0, 0, 0, 0)
sbPromptTitle.BackgroundTransparency = 1
sbPromptTitle.Text               = "🔒  Enter password"
sbPromptTitle.TextColor3         = Color3.fromRGB(200, 160, 255)
sbPromptTitle.Font               = Enum.Font.GothamBold
sbPromptTitle.TextSize           = 13
sbPromptTitle.ZIndex             = 21

local sbPasswordBox = Instance.new("TextBox", sbPrompt)
sbPasswordBox.Size             = UDim2.new(1, -20, 0, 30)
sbPasswordBox.Position         = UDim2.new(0, 10, 0, 36)
sbPasswordBox.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
sbPasswordBox.TextColor3       = Color3.fromRGB(220, 220, 220)
sbPasswordBox.PlaceholderText  = "Password..."
sbPasswordBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
sbPasswordBox.Text             = ""
sbPasswordBox.Font             = Enum.Font.Gotham
sbPasswordBox.TextSize         = 13
sbPasswordBox.ClearTextOnFocus = false
sbPasswordBox.ZIndex           = 21
Instance.new("UICorner", sbPasswordBox).CornerRadius = UDim.new(0, 6)

local sbPromptConfirm = Instance.new("TextButton", sbPrompt)
sbPromptConfirm.Size             = UDim2.new(0, 100, 0, 26)
sbPromptConfirm.Position         = UDim2.new(0.5, -50, 0, 74)
sbPromptConfirm.BackgroundColor3 = Color3.fromRGB(45, 25, 80)
sbPromptConfirm.TextColor3       = Color3.fromRGB(200, 160, 255)
sbPromptConfirm.Text             = "Unlock"
sbPromptConfirm.Font             = Enum.Font.GothamBold
sbPromptConfirm.TextSize         = 12
sbPromptConfirm.AutoButtonColor  = false
sbPromptConfirm.ZIndex           = 21
Instance.new("UICorner", sbPromptConfirm).CornerRadius = UDim.new(0, 6)

-- Close button on the prompt (visible to anyone who stumbles on it)
local sbPromptClose = Instance.new("TextButton", sbPrompt)
sbPromptClose.Size             = UDim2.new(0, 22, 0, 22)
sbPromptClose.Position         = UDim2.new(1, -26, 0, 4)
sbPromptClose.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
sbPromptClose.TextColor3       = Color3.fromRGB(255, 100, 100)
sbPromptClose.Text             = "✕"
sbPromptClose.Font             = Enum.Font.GothamBold
sbPromptClose.TextSize         = 12
sbPromptClose.AutoButtonColor  = false
sbPromptClose.ZIndex           = 22
Instance.new("UICorner", sbPromptClose).CornerRadius = UDim.new(0, 5)
sbPromptClose.MouseButton1Click:Connect(function()
    sbPrompt.Visible   = false
    sbPasswordBox.Text = ""
end)

-- _G bridge: titleIcon (in GUI scope) calls this to open the prompt
_G.SB_ShowPrompt = function()
    if sbUnlocked then
        sbPanel.Visible = not sbPanel.Visible
        if sbPanel.Visible then sbPopulate() end
    else
        sbPrompt.Visible   = true
        sbPasswordBox.Text = ""
        sbPasswordBox:CaptureFocus()
    end
end

-- _G bridge: toggleMenu calls this to sync hub visibility with main menu
_G.SB_SetVisible = function(visible)
    if not sbUnlocked then return end
    sbPanel.Visible    = visible and sbPanel.Visible or false
    sbToggleBtn.Visible = visible
end
-- ── Toggle button (hidden until unlocked) ────────────────────
local sbToggleBtn = Instance.new("TextButton", sbGui)
sbToggleBtn.Size              = UDim2.new(0, 38, 0, 38)
sbToggleBtn.Position          = UDim2.new(1, -48, 0.5, -19)
sbToggleBtn.BackgroundColor3  = Color3.fromRGB(30, 15, 55)
sbToggleBtn.TextColor3        = Color3.fromRGB(200, 160, 255)
sbToggleBtn.Text              = "👥"
sbToggleBtn.Font              = Enum.Font.GothamBold
sbToggleBtn.TextSize          = 18
sbToggleBtn.AutoButtonColor   = false
sbToggleBtn.ZIndex            = 10
sbToggleBtn.Visible           = sbUnlocked
Instance.new("UICorner", sbToggleBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", sbToggleBtn).Color = Color3.fromRGB(100, 50, 180)

-- Main panel
local sbPanel = Instance.new("Frame", sbGui)
sbPanel.Size             = UDim2.new(0, 320, 0, 380)
sbPanel.Position         = UDim2.new(1, -378, 0.5, -190)
sbPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
sbPanel.BorderSizePixel  = 0
sbPanel.Visible          = false
sbPanel.ZIndex           = 9
Instance.new("UICorner", sbPanel).CornerRadius = UDim.new(0, 10)
local sbStroke = Instance.new("UIStroke", sbPanel)
sbStroke.Color     = Color3.fromRGB(80, 40, 140)
sbStroke.Thickness = 1.5

local sbPopulate  -- forward declaration so tryUnlock and toggle button can call it

function tryUnlock()
    if sbPasswordBox.Text == SB_PASSWORD then
        sbUnlocked       = true
        sbPrompt.Visible = false
        sbPasswordBox.Text = ""
        sbToggleBtn.Visible = true
        sbPanel.Visible  = true
        sbPopulate()
    else
        -- Wrong password: flash red briefly, reveal nothing
        sbPasswordBox.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.delay(0.6, function()
            sbPasswordBox.TextColor3 = Color3.fromRGB(220, 220, 220)
            sbPasswordBox.Text = ""
        end)
    end
end

sbPromptConfirm.MouseButton1Click:Connect(tryUnlock)
sbPasswordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryUnlock() end
end)


-- Header
local sbHeader = Instance.new("Frame", sbPanel)
sbHeader.Size            = UDim2.new(1, 0, 0, 38)
sbHeader.BackgroundColor3 = Color3.fromRGB(20, 10, 38)
sbHeader.BorderSizePixel = 0
Instance.new("UICorner", sbHeader).CornerRadius = UDim.new(0, 10)
local sbTitle = Instance.new("TextLabel", sbHeader)
sbTitle.Size               = UDim2.new(1, -50, 1, 0)
sbTitle.Position           = UDim2.new(0, 12, 0, 0)
sbTitle.BackgroundTransparency = 1
sbTitle.Text               = "🌐  PLAYER HUB"
sbTitle.TextColor3         = Color3.fromRGB(200, 160, 255)
sbTitle.Font               = Enum.Font.GothamBold
sbTitle.TextSize           = 14
sbTitle.TextXAlignment     = Enum.TextXAlignment.Left

-- Refresh button
local sbRefreshBtn = Instance.new("TextButton", sbHeader)
sbRefreshBtn.Size             = UDim2.new(0, 70, 0, 24)
sbRefreshBtn.Position         = UDim2.new(1, -80, 0.5, -12)
sbRefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 80)
sbRefreshBtn.TextColor3       = Color3.fromRGB(200, 160, 255)
sbRefreshBtn.Text             = "↻ Refresh"
sbRefreshBtn.Font             = Enum.Font.Gotham
sbRefreshBtn.TextSize         = 12
sbRefreshBtn.AutoButtonColor  = false
Instance.new("UICorner", sbRefreshBtn).CornerRadius = UDim.new(0, 6)

-- Status bar
local sbStatus = Instance.new("TextLabel", sbPanel)
sbStatus.Size               = UDim2.new(1, -20, 0, 18)
sbStatus.Position           = UDim2.new(0, 10, 0, 44)
sbStatus.BackgroundTransparency = 1
sbStatus.Text               = "Fetching..."
sbStatus.TextColor3         = Color3.fromRGB(140, 140, 160)
sbStatus.Font               = Enum.Font.Gotham
sbStatus.TextSize           = 11
sbStatus.TextXAlignment     = Enum.TextXAlignment.Left

-- Scroll frame for entries
local sbScroll = Instance.new("ScrollingFrame", sbPanel)
sbScroll.Size               = UDim2.new(1, -16, 1, -72)
sbScroll.Position           = UDim2.new(0, 8, 0, 66)
sbScroll.BackgroundTransparency = 1
sbScroll.BorderSizePixel    = 0
sbScroll.ScrollBarThickness = 4
sbScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 180)
sbScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
local sbLayout = Instance.new("UIListLayout", sbScroll)
sbLayout.Padding            = UDim.new(0, 6)
sbLayout.SortOrder          = Enum.SortOrder.LayoutOrder

-- ── populate the list ────────────────────────────────────────
function sbClearList()
    for _, c in ipairs(sbScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

function sbMakeCard(username, jobId, placeId, isSelf, isSameServer)
    local card = Instance.new("Frame", sbScroll)
    card.Size             = UDim2.new(1, -4, 0, 52)
    card.BackgroundColor3 = isSelf
        and Color3.fromRGB(25, 18, 45)
        or  Color3.fromRGB(16, 16, 22)
    card.BorderSizePixel  = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    if isSelf then
        local cs = Instance.new("UIStroke", card)
        cs.Color = Color3.fromRGB(100, 50, 180); cs.Thickness = 1
    end

    local nameLabel = Instance.new("TextLabel", card)
    nameLabel.Size               = UDim2.new(1, -110, 0, 22)
    nameLabel.Position           = UDim2.new(0, 10, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text               = username .. (isSelf and "  (you)" or "")
    nameLabel.TextColor3         = isSelf
        and Color3.fromRGB(200, 160, 255)
        or  Color3.fromRGB(220, 220, 220)
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextSize           = 13
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.TextTruncate       = Enum.TextTruncate.AtEnd

    local serverLabel = Instance.new("TextLabel", card)
    serverLabel.Size               = UDim2.new(1, -110, 0, 16)
    serverLabel.Position           = UDim2.new(0, 10, 0, 28)
    serverLabel.BackgroundTransparency = 1
    serverLabel.Text               = isSameServer
        and "✓ Same server"
        or  ("Server: " .. string.sub(jobId, 1, 18) .. "...")
    serverLabel.TextColor3         = isSameServer
        and Color3.fromRGB(100, 220, 100)
        or  Color3.fromRGB(120, 120, 140)
    serverLabel.Font               = Enum.Font.Gotham
    serverLabel.TextSize           = 11
    serverLabel.TextXAlignment     = Enum.TextXAlignment.Left

    -- Join button (hidden for self and same-server)
    if not isSelf and not isSameServer then
        local joinBtn = Instance.new("TextButton", card)
        joinBtn.Size             = UDim2.new(0, 90, 0, 34)
        joinBtn.Position         = UDim2.new(1, -98, 0.5, -17)
        joinBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 80)
        joinBtn.TextColor3       = Color3.fromRGB(200, 160, 255)
        joinBtn.Text             = "Join →"
        joinBtn.Font             = Enum.Font.GothamBold
        joinBtn.TextSize         = 12
        joinBtn.AutoButtonColor  = false
        Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
        joinBtn.MouseButton1Click:Connect(function()
            joinBtn.Text             = "Joining..."
            joinBtn.BackgroundColor3 = Color3.fromRGB(25, 80, 25)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
            end)
        end)
    elseif isSameServer then
        local sameLabel = Instance.new("TextLabel", card)
        sameLabel.Size               = UDim2.new(0, 90, 0, 34)
        sameLabel.Position           = UDim2.new(1, -98, 0.5, -17)
        sameLabel.BackgroundTransparency = 1
        sameLabel.Text               = "Here"
        sameLabel.TextColor3         = Color3.fromRGB(100, 220, 100)
        sameLabel.Font               = Enum.Font.GothamBold
        sameLabel.TextSize           = 12
        sameLabel.TextXAlignment     = Enum.TextXAlignment.Center
    end

    return card
end

sbPopulate = function()
    sbStatus.Text             = "Fetching..."
    sbRefreshBtn.Text         = "..."
    sbRefreshBtn.AutoButtonColor = false

    task.spawn(function()
        local ok, entries = pcall(sbRead)
        if not ok or type(entries) ~= "table" then
            sbStatus.Text     = "⚠ HTTP failed — check executor allows requests"
            sbRefreshBtn.Text = "↻ Refresh"
            return
        end

        sbClearList()
        local now    = sbTimestamp()
        local count  = 0
        local order  = 0

        -- Self first
        local selfEntry = entries[LocalPlayer.Name]
        if selfEntry then
            local card = sbMakeCard(
                LocalPlayer.Name,
                selfEntry.jobId,
                selfEntry.placeId,
                true,
                selfEntry.jobId == game.JobId
            )
            card.LayoutOrder = 0
            count = count + 1
        end

        -- Others
        for username, entry in pairs(entries) do
            if username ~= LocalPlayer.Name then
                local age = now - (entry.timestamp or 0)
                if age <= SB_STALE_SEC then
                    order = order + 1
                    local card = sbMakeCard(
                        username,
                        entry.jobId,
                        entry.placeId,
                        false,
                        entry.jobId == game.JobId
                    )
                    card.LayoutOrder = order
                    count = count + 1
                end
            end
        end

        sbScroll.CanvasSize = UDim2.new(0, 0, 0, count * 58)
        sbStatus.Text       = count == 0
            and "No players online right now."
            or  (count .. " player" .. (count == 1 and "" or "s") .. " using the GUI")
        sbRefreshBtn.Text   = "↻ Refresh"
    end)
end

-- ── wire up buttons ──────────────────────────────────────────
sbToggleBtn.MouseButton1Click:Connect(function()
    sbPanel.Visible = not sbPanel.Visible
    if sbPanel.Visible then sbPopulate() end
end)

sbRefreshBtn.MouseButton1Click:Connect(sbPopulate)

-- Make panel draggable
local sbDragging, sbDragStart, sbPanelStart = false, nil, nil
sbHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sbDragging   = true
        sbDragStart  = inp.Position
        sbPanelStart = sbPanel.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if sbDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - sbDragStart
        sbPanel.Position = UDim2.new(
            sbPanelStart.X.Scale, sbPanelStart.X.Offset + delta.X,
            sbPanelStart.Y.Scale, sbPanelStart.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sbDragging = false
    end
end)

end) -- end SERVER BROWSER task.spawn

-- ============================================================
-- === SAVE / LOAD PRESET SYSTEM                            ===
-- ============================================================
task.spawn(function()

-- Flags that cannot be saved (one-shot, GUI-openers, selectors)
local UNSAVEABLE = {
    isUGCEmotes=true, isViolentMenu=true, isTeleportPoint=true,
    isHomeFinder=true, isXYZTP=true, isZombie=true,
    isESP=true, isViewPlayer=true, isHitboxExpander=true, isCarScanner=true,
    isAvatarSaves=true,
}

local SAVE_FOLDER  = "LizardHub"
local PRESET_PATH  = SAVE_FOLDER .. "/presets"
local CONFIG_PATH  = SAVE_FOLDER .. "/config.json"

-- ── File helpers ──────────────────────────────────────────────
function ensureFolders()
    if not isfolder(SAVE_FOLDER)  then makefolder(SAVE_FOLDER)  end
    if not isfolder(PRESET_PATH)  then makefolder(PRESET_PATH)  end
end

function safeRead(path)
    if not isfile(path) then return nil end
    local ok, data = pcall(readfile, path)
    return ok and data or nil
end

function safeWrite(path, content)
    pcall(writefile, path, content)
end

function loadConfig()
    local raw = safeRead(CONFIG_PATH)
    if not raw then return { autoLoad = false, autoPreset = nil } end
    local ok, t = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), raw)
    return ok and t or { autoLoad = false, autoPreset = nil }
end

function saveConfig(t)
    safeWrite(CONFIG_PATH, game:GetService("HttpService"):JSONEncode(t))
end

function listPresets()
    if not isfolder(PRESET_PATH) then return {} end
    local ok, files = pcall(listfiles, PRESET_PATH)
    if not ok then return {} end
    local names = {}
    for _, f in ipairs(files) do
        local name = f:match("[/\\]([^/\\]+)%.json$")
        if name then table.insert(names, name) end
    end
    table.sort(names)
    return names
end

function presetFile(name)
    return PRESET_PATH .. "/" .. name .. ".json"
end

-- ── Collect current active scripts ───────────────────────────
function collectActive()
    local active = {}
    for _, cat in ipairs(Config.categories) do
        for _, script in ipairs(cat.scripts) do
            local isSaveable = true
            for flag in pairs(UNSAVEABLE) do
                if script[flag] then isSaveable = false break end
            end
            if isSaveable and script.active == true then
                table.insert(active, script.name)
            end
        end
    end
    return active
end

function collectPresetPayload()
    return {
        version = 2,
        activeScripts = collectActive(),
        keybinds = serializeKeybinds(),
    }
end

function decodePresetData(raw)
    if not raw then return nil end
    local ok, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), raw)
    if not ok or not data then return nil end
    if type(data) == "table" and #data > 0 then
        return { version = 1, activeScripts = data, keybinds = nil }
    end
    if type(data) == "table" then
        return {
            version = data.version or 2,
            activeScripts = type(data.activeScripts) == "table" and data.activeScripts or {},
            keybinds = type(data.keybinds) == "table" and data.keybinds or nil,
        }
    end
    return nil
end

-- ── Apply a preset (enable scripts one by one with delay) ────
function applyPreset(presetData)
    if not presetData then return end
    if presetData.keybinds then
        applySavedKeybinds(presetData.keybinds)
    end
    task.spawn(function()
        for _, targetName in ipairs(presetData.activeScripts or {}) do
            for _, cat in ipairs(Config.categories) do
                for _, script in ipairs(cat.scripts) do
                    if script.name == targetName then
                        local isSaveable = true
                        for flag in pairs(UNSAVEABLE) do
                            if script[flag] then isSaveable = false break end
                        end
                        if isSaveable and not script.active then
                            script.active = true
                            -- Fire the toggle via _G dispatch bridge
                            if _G.SaveSystem_DispatchToggle then
                                _G.SaveSystem_DispatchToggle(script)
                            end
                        end
                    end
                end
            end
            task.wait(0.25)
        end
        -- Refresh the script list UI
        if _G.SaveSystem_RefreshScriptUI then
            _G.SaveSystem_RefreshScriptUI()
        end
    end)
end

-- ── UI ────────────────────────────────────────────────────────
local svGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
svGui.Name          = "SaveLoadUI"
svGui.ResetOnSpawn  = false
svGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
svGui.DisplayOrder  = 1000000002

local svPanel = Instance.new("Frame", svGui)
svPanel.Size             = UDim2.new(0, 320, 0, 440)
svPanel.Position         = UDim2.new(0.5, -160, 0.5, -220)
svPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
svPanel.BorderSizePixel  = 0
svPanel.Visible          = false
Instance.new("UICorner", svPanel).CornerRadius = UDim.new(0, 10)
local svStroke = Instance.new("UIStroke", svPanel)
svStroke.Color = Color3.fromRGB(40, 80, 40); svStroke.Thickness = 1.5

-- Header
local svHeader = Instance.new("Frame", svPanel)
svHeader.Size            = UDim2.new(1, 0, 0, 38)
svHeader.BackgroundColor3 = Color3.fromRGB(14, 28, 14)
svHeader.BorderSizePixel = 0
Instance.new("UICorner", svHeader).CornerRadius = UDim.new(0, 10)

local svTitle = Instance.new("TextLabel", svHeader)
svTitle.Size               = UDim2.new(1, -50, 1, 0)
svTitle.Position           = UDim2.new(0, 12, 0, 0)
svTitle.BackgroundTransparency = 1
svTitle.Text               = "💾  SAVE / LOAD PRESETS"
svTitle.TextColor3         = Color3.fromRGB(120, 220, 120)
svTitle.Font               = Enum.Font.GothamBold
svTitle.TextSize           = 13
svTitle.TextXAlignment     = Enum.TextXAlignment.Left

local svClose = Instance.new("TextButton", svHeader)
svClose.Size             = UDim2.new(0, 28, 0, 24)
svClose.Position         = UDim2.new(1, -34, 0.5, -12)
svClose.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
svClose.TextColor3       = Color3.fromRGB(255, 100, 100)
svClose.Text             = "✕"
svClose.Font             = Enum.Font.GothamBold
svClose.TextSize         = 12
svClose.AutoButtonColor  = false
Instance.new("UICorner", svClose).CornerRadius = UDim.new(0, 6)
svClose.MouseButton1Click:Connect(function() svPanel.Visible = false end)

-- Save new preset row
local svSaveRow = Instance.new("Frame", svPanel)
svSaveRow.Size             = UDim2.new(1, -16, 0, 36)
svSaveRow.Position         = UDim2.new(0, 8, 0, 46)
svSaveRow.BackgroundTransparency = 1

local svNameBox = Instance.new("TextBox", svSaveRow)
svNameBox.Size             = UDim2.new(1, -80, 0, 30)
svNameBox.Position         = UDim2.new(0, 0, 0, 3)
svNameBox.BackgroundColor3 = Color3.fromRGB(18, 28, 18)
svNameBox.TextColor3       = Color3.fromRGB(200, 255, 200)
svNameBox.PlaceholderText  = "Preset name..."
svNameBox.PlaceholderColor3 = Color3.fromRGB(80, 110, 80)
svNameBox.Text             = ""
svNameBox.Font             = Enum.Font.Gotham
svNameBox.TextSize         = 12
svNameBox.ClearTextOnFocus = false
Instance.new("UICorner", svNameBox).CornerRadius = UDim.new(0, 6)

local svSaveBtn = Instance.new("TextButton", svSaveRow)
svSaveBtn.Size             = UDim2.new(0, 70, 0, 30)
svSaveBtn.Position         = UDim2.new(1, -70, 0, 3)
svSaveBtn.BackgroundColor3 = Color3.fromRGB(25, 65, 25)
svSaveBtn.TextColor3       = Color3.fromRGB(120, 220, 120)
svSaveBtn.Text             = "💾 Save"
svSaveBtn.Font             = Enum.Font.GothamBold
svSaveBtn.TextSize         = 11
svSaveBtn.AutoButtonColor  = false
Instance.new("UICorner", svSaveBtn).CornerRadius = UDim.new(0, 6)

-- Auto-load checkbox row
local svAutoRow = Instance.new("Frame", svPanel)
svAutoRow.Size             = UDim2.new(1, -16, 0, 28)
svAutoRow.Position         = UDim2.new(0, 8, 0, 88)
svAutoRow.BackgroundTransparency = 1

local svAutoCheck = Instance.new("TextButton", svAutoRow)
svAutoCheck.Size             = UDim2.new(0, 20, 0, 20)
svAutoCheck.Position         = UDim2.new(0, 0, 0, 4)
svAutoCheck.Font             = Enum.Font.GothamBold
svAutoCheck.TextSize         = 13
svAutoCheck.AutoButtonColor  = false
Instance.new("UICorner", svAutoCheck).CornerRadius = UDim.new(0, 4)

local svAutoLabel = Instance.new("TextLabel", svAutoRow)
svAutoLabel.Size               = UDim2.new(1, -30, 0, 28)
svAutoLabel.Position           = UDim2.new(0, 28, 0, 0)
svAutoLabel.BackgroundTransparency = 1
svAutoLabel.Text               = "Auto-load last preset on startup"
svAutoLabel.TextColor3         = Color3.fromRGB(160, 200, 160)
svAutoLabel.Font               = Enum.Font.Gotham
svAutoLabel.TextSize           = 11
svAutoLabel.TextXAlignment     = Enum.TextXAlignment.Left
svAutoLabel.TextYAlignment     = Enum.TextYAlignment.Center

-- Divider label
local svListLabel = Instance.new("TextLabel", svPanel)
svListLabel.Size               = UDim2.new(1, -16, 0, 18)
svListLabel.Position           = UDim2.new(0, 8, 0, 120)
svListLabel.BackgroundTransparency = 1
svListLabel.Text               = "SAVED PRESETS"
svListLabel.TextColor3         = Color3.fromRGB(80, 130, 80)
svListLabel.Font               = Enum.Font.GothamBold
svListLabel.TextSize           = 10
svListLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Preset scroll list
local svScroll = Instance.new("ScrollingFrame", svPanel)
svScroll.Size               = UDim2.new(1, -12, 1, -148)
svScroll.Position           = UDim2.new(0, 6, 0, 142)
svScroll.BackgroundTransparency = 1
svScroll.BorderSizePixel    = 0
svScroll.ScrollBarThickness = 3
svScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 140, 60)
svScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
local svLayout = Instance.new("UIListLayout", svScroll)
svLayout.Padding            = UDim.new(0, 4)
svLayout.SortOrder          = Enum.SortOrder.LayoutOrder

-- ── State ─────────────────────────────────────────────────────
local svConfig = loadConfig()
local autoLoadEnabled = svConfig.autoLoad or false
local autoLoadPreset  = svConfig.autoPreset or nil

function refreshAutoCheckVisual()
    svAutoCheck.Text             = autoLoadEnabled and "✓" or ""
    svAutoCheck.BackgroundColor3 = autoLoadEnabled
        and Color3.fromRGB(30, 90, 30)
        or  Color3.fromRGB(25, 35, 25)
    svAutoCheck.TextColor3 = Color3.fromRGB(120, 220, 120)
end
refreshAutoCheckVisual()

-- ── Preset list ───────────────────────────────────────────────
function rebuildList()
    for _, c in ipairs(svScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local names = listPresets()
    for i, name in ipairs(names) do
        local row = Instance.new("Frame", svScroll)
        row.Size             = UDim2.new(1, -4, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(14, 22, 14)
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

        -- Is this the auto-load preset?
        if autoLoadPreset == name then
            local as = Instance.new("UIStroke", row)
            as.Color = Color3.fromRGB(60, 160, 60); as.Thickness = 1
        end

        -- Name (editable)
        local nameBox = Instance.new("TextBox", row)
        nameBox.Size             = UDim2.new(1, -140, 0, 26)
        nameBox.Position         = UDim2.new(0, 8, 0.5, -13)
        nameBox.BackgroundTransparency = 1
        nameBox.Text             = name
        nameBox.TextColor3       = Color3.fromRGB(190, 230, 190)
        nameBox.Font             = Enum.Font.GothamBold
        nameBox.TextSize         = 12
        nameBox.TextXAlignment   = Enum.TextXAlignment.Left
        nameBox.ClearTextOnFocus = false
        nameBox.FocusLost:Connect(function(enter)
            local newName = nameBox.Text:match("^%s*(.-)%s*$")
            if newName == "" or newName == name then
                nameBox.Text = name
                return
            end
            -- Rename: copy file, delete old
            local old = safeRead(presetFile(name))
            if old then
                safeWrite(presetFile(newName), old)
                pcall(delfile, presetFile(name))
                if autoLoadPreset == name then
                    autoLoadPreset = newName
                    svConfig.autoPreset = newName
                    saveConfig(svConfig)
                end
            end
            rebuildList()
        end)

        -- Load button
        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size             = UDim2.new(0, 46, 0, 28)
        loadBtn.Position         = UDim2.new(1, -132, 0.5, -14)
        loadBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
        loadBtn.TextColor3       = Color3.fromRGB(120, 220, 120)
        loadBtn.Text             = "Load"
        loadBtn.Font             = Enum.Font.GothamBold
        loadBtn.TextSize         = 11
        loadBtn.AutoButtonColor  = false
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 5)
        loadBtn.MouseButton1Click:Connect(function()
            local raw = safeRead(presetFile(name))
            local data = decodePresetData(raw)
            if data then
                applyPreset(data)
                loadBtn.Text             = "✓"
                loadBtn.BackgroundColor3 = Color3.fromRGB(20, 90, 20)
                task.delay(1.5, function() loadBtn.Text = "Load"; loadBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20) end)
            end
        end)

        -- Set as auto-load button
        local autoBtn = Instance.new("TextButton", row)
        autoBtn.Size             = UDim2.new(0, 36, 0, 28)
        autoBtn.Position         = UDim2.new(1, -82, 0.5, -14)
        autoBtn.BackgroundColor3 = autoLoadPreset == name
            and Color3.fromRGB(30, 90, 30)
            or  Color3.fromRGB(20, 35, 20)
        autoBtn.TextColor3       = Color3.fromRGB(120, 220, 120)
        autoBtn.Text             = "★"
        autoBtn.Font             = Enum.Font.GothamBold
        autoBtn.TextSize         = 13
        autoBtn.AutoButtonColor  = false
        Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 5)
        autoBtn.MouseButton1Click:Connect(function()
            if autoLoadPreset == name then
                autoLoadPreset = nil
                svConfig.autoPreset = nil
            else
                autoLoadPreset = name
                svConfig.autoPreset = name
            end
            saveConfig(svConfig)
            rebuildList()
        end)

        -- Delete button
        local delBtn = Instance.new("TextButton", row)
        delBtn.Size             = UDim2.new(0, 32, 0, 28)
        delBtn.Position         = UDim2.new(1, -40, 0.5, -14)
        delBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        delBtn.TextColor3       = Color3.fromRGB(255, 100, 100)
        delBtn.Text             = "🗑"
        delBtn.Font             = Enum.Font.GothamBold
        delBtn.TextSize         = 11
        delBtn.AutoButtonColor  = false
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 5)
        delBtn.MouseButton1Click:Connect(function()
            pcall(delfile, presetFile(name))
            if autoLoadPreset == name then
                autoLoadPreset = nil
                svConfig.autoPreset = nil
                saveConfig(svConfig)
            end
            rebuildList()
        end)
    end

    svScroll.CanvasSize = UDim2.new(0, 0, 0, #names * 48)
end

-- ── Save button handler ───────────────────────────────────────
svSaveBtn.MouseButton1Click:Connect(function()
    local name = svNameBox.Text:match("^%s*(.-)%s*$")
    if name == "" then return end
    ensureFolders()
    local payload = collectPresetPayload()
    safeWrite(presetFile(name), game:GetService("HttpService"):JSONEncode(payload))
    svNameBox.Text = ""
    svSaveBtn.Text             = "✓ Saved"
    svSaveBtn.BackgroundColor3 = Color3.fromRGB(20, 90, 20)
    task.delay(1.5, function()
        svSaveBtn.Text             = "💾 Save"
        svSaveBtn.BackgroundColor3 = Color3.fromRGB(25, 65, 25)
    end)
    rebuildList()
end)

-- ── Auto-load checkbox ────────────────────────────────────────
svAutoCheck.MouseButton1Click:Connect(function()
    autoLoadEnabled = not autoLoadEnabled
    svConfig.autoLoad = autoLoadEnabled
    saveConfig(svConfig)
    refreshAutoCheckVisual()
end)

-- ── Panel toggle (_G bridge) ──────────────────────────────────
_G.SavePanel_Toggle = function()
    svPanel.Visible = not svPanel.Visible
    if svPanel.Visible then
        ensureFolders()
        rebuildList()
    end
end

-- Hide with main menu
local origSBSetVisible2 = _G.SB_SetVisible
_G.SB_SetVisible = function(visible)
    if origSBSetVisible2 then origSBSetVisible2(visible) end
    if svPanel.Visible then svPanel.Visible = visible end
end

-- Draggable
local svDrag, svDragStart, svPanelStart = false, nil, nil
svHeader.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        svDrag = true; svDragStart = inp.Position; svPanelStart = svPanel.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - svDragStart
        svPanel.Position = UDim2.new(svPanelStart.X.Scale, svPanelStart.X.Offset + d.X,
            svPanelStart.Y.Scale, svPanelStart.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
end)

-- ── Auto-load on startup ──────────────────────────────────────
if autoLoadEnabled and autoLoadPreset then
    local raw = safeRead(presetFile(autoLoadPreset))
    if raw then
        local data = decodePresetData(raw)
        if data then
            task.wait(2)  -- wait for GUI to fully initialize
            applyPreset(data)
        end
    end
end

end) -- end SAVE SYSTEM task.spawn

-- ============================================================
-- === KEYBIND SETTINGS PANEL                               ===
-- ============================================================
task.spawn(function()
    local kbGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    kbGui.Name = "KeybindSettingsUI"
    kbGui.ResetOnSpawn = false
    kbGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    kbGui.DisplayOrder = 1000000003

    local kbPanel = Instance.new("Frame", kbGui)
    kbPanel.Size = UDim2.new(0, 340, 0, 390)
    kbPanel.Position = UDim2.new(0.5, -170, 0.5, -195)
    kbPanel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    kbPanel.BorderSizePixel = 0
    kbPanel.Visible = false
    Instance.new("UICorner", kbPanel).CornerRadius = UDim.new(0, 10)
    local kbStroke = Instance.new("UIStroke", kbPanel)
    kbStroke.Color = Color3.fromRGB(80, 80, 120)
    kbStroke.Thickness = 1.5

    local kbHeader = Instance.new("Frame", kbPanel)
    kbHeader.Size = UDim2.new(1, 0, 0, 38)
    kbHeader.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
    kbHeader.BorderSizePixel = 0
    Instance.new("UICorner", kbHeader).CornerRadius = UDim.new(0, 10)

    local kbTitle = Instance.new("TextLabel", kbHeader)
    kbTitle.Size = UDim2.new(1, -50, 1, 0)
    kbTitle.Position = UDim2.new(0, 12, 0, 0)
    kbTitle.BackgroundTransparency = 1
    kbTitle.Text = "⌨  KEYBIND SETTINGS"
    kbTitle.TextColor3 = Color3.fromRGB(190, 190, 255)
    kbTitle.Font = Enum.Font.GothamBold
    kbTitle.TextSize = 13
    kbTitle.TextXAlignment = Enum.TextXAlignment.Left

    local kbClose = Instance.new("TextButton", kbHeader)
    kbClose.Size = UDim2.new(0, 28, 0, 24)
    kbClose.Position = UDim2.new(1, -34, 0.5, -12)
    kbClose.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    kbClose.TextColor3 = Color3.fromRGB(255, 100, 100)
    kbClose.Text = "✕"
    kbClose.Font = Enum.Font.GothamBold
    kbClose.TextSize = 12
    kbClose.AutoButtonColor = false
    Instance.new("UICorner", kbClose).CornerRadius = UDim.new(0, 6)

    local kbNote = Instance.new("TextLabel", kbPanel)
    kbNote.Size = UDim2.new(1, -20, 0, 34)
    kbNote.Position = UDim2.new(0, 10, 0, 46)
    kbNote.BackgroundTransparency = 1
    kbNote.Text = "Movement keys stay fixed. Click a key to rebind it."
    kbNote.TextColor3 = Color3.fromRGB(140, 140, 160)
    kbNote.Font = Enum.Font.Gotham
    kbNote.TextSize = 11
    kbNote.TextWrapped = true
    kbNote.TextXAlignment = Enum.TextXAlignment.Left

    local kbScroll = Instance.new("ScrollingFrame", kbPanel)
    kbScroll.Size = UDim2.new(1, -16, 1, -94)
    kbScroll.Position = UDim2.new(0, 8, 0, 84)
    kbScroll.BackgroundTransparency = 1
    kbScroll.BorderSizePixel = 0
    kbScroll.ScrollBarThickness = 3
    kbScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    local kbLayout = Instance.new("UIListLayout", kbScroll)
    kbLayout.Padding = UDim.new(0, 6)
    kbLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local kbCaptureId = nil
    local kbDrag, kbDragStart, kbPanelStart = false, nil, nil

    local function kbRefresh()
        for _, child in ipairs(kbScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for i, item in ipairs(KEYBIND_ORDER) do
            local row = Instance.new("Frame", kbScroll)
            row.Size = UDim2.new(1, -2, 0, 38)
            row.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

            local label = Instance.new("TextLabel", row)
            label.Size = UDim2.new(1, -118, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = item.label
            label.TextColor3 = Config.colors.text
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left

            local bindBtn = Instance.new("TextButton", row)
            bindBtn.Size = UDim2.new(0, 96, 0, 26)
            bindBtn.Position = UDim2.new(1, -104, 0.5, -13)
            bindBtn.BackgroundColor3 = kbCaptureId == item.id and Color3.fromRGB(70, 60, 30) or Color3.fromRGB(32, 32, 44)
            bindBtn.TextColor3 = kbCaptureId == item.id and Color3.fromRGB(255, 220, 140) or Config.colors.text
            bindBtn.Text = kbCaptureId == item.id and "PRESS KEY" or keybindToString(Keybinds[item.id])
            bindBtn.Font = Enum.Font.GothamBold
            bindBtn.TextSize = 11
            bindBtn.AutoButtonColor = false
            Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)
            bindBtn.MouseButton1Click:Connect(function()
                kbCaptureId = item.id
                kbRefresh()
            end)
        end
        kbScroll.CanvasSize = UDim2.new(0, 0, 0, #KEYBIND_ORDER * 44)
    end

    local function kbSetVisible(visible)
        if visible then
            kbRefresh()
            kbPanel.Visible = true
            kbPanel.Size = UDim2.new(0, 306, 0, 350)
            kbPanel.Position = UDim2.new(0.5, -153, 0.5, -175)
            TweenService:Create(kbPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 340, 0, 390),
                Position = UDim2.new(0.5, -170, 0.5, -195),
            }):Play()
        else
            local tween = TweenService:Create(kbPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 306, 0, 350),
                Position = UDim2.new(0.5, -153, 0.5, -175),
            })
            tween:Play()
            tween.Completed:Connect(function()
                if not kbPanel.Visible then return end
                kbPanel.Visible = false
            end)
        end
    end

    _G.KeybindPanel_Refresh = kbRefresh
    _G.KeybindPanel_Toggle = function()
        kbSetVisible(not kbPanel.Visible)
    end

    kbClose.MouseButton1Click:Connect(function()
        kbSetVisible(false)
    end)

    kbHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            kbDrag = true
            kbDragStart = inp.Position
            kbPanelStart = kbPanel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if kbDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - kbDragStart
            kbPanel.Position = UDim2.new(kbPanelStart.X.Scale, kbPanelStart.X.Offset + d.X,
                kbPanelStart.Y.Scale, kbPanelStart.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then kbDrag = false end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not kbCaptureId then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            kbCaptureId = nil
            kbRefresh()
            return
        end
        Keybinds[kbCaptureId] = input.KeyCode
        kbCaptureId = nil
        applySavedKeybinds(serializeKeybinds())
        kbRefresh()
    end)

    local origSBSetVisible3 = _G.SB_SetVisible
    _G.SB_SetVisible = function(visible)
        if origSBSetVisible3 then origSBSetVisible3(visible) end
        if kbPanel.Visible then kbPanel.Visible = visible end
    end
end)

-- ============================================================
-- === CAR SCANNER MONITOR                                  ===
-- ============================================================
task.spawn(function()

local MOVE_THRESH  = 0.5   -- studs/s below this = parked
local AFK_CONFIRM  = 20    -- seconds parked before showing
local SCAN_RATE    = 0.5   -- seconds between scans

local csStatus  = {}  -- [model] = {moving, stoppedAt, shown}
local csRunning = false

function getVehicles()
    local gp = workspace:FindFirstChild("Gameplay")
    local vf = gp and gp:FindFirstChild("Vehicles")
    if not vf then return {} end
    return vf:GetChildren()
end

function getDriveVel(model)
    local ds = model:FindFirstChild("DriveSeat")
    if ds and ds:IsA("BasePart") then
        return ds.AssemblyLinearVelocity.Magnitude
    end
    for _, c in ipairs(model:GetChildren()) do
        if c:IsA("BasePart") then return c.AssemblyLinearVelocity.Magnitude end
    end
    return 0
end

function isEligible(model)
    if not model:IsA("Model") then return false end
    local cfg = model:FindFirstChild("Config")
    if not cfg then return false end
    local tv = cfg:FindFirstChild("Type")
    if not tv then return false end
    local typeVal = tv:IsA("StringValue") and tv.Value
        or (tv:IsA("ObjectValue") and tv.Value and tv.Value.Name)
        or ""
    if typeVal ~= "Civilian" then return false end
    local sv = cfg:FindFirstChild("SecurityLevel")
    if not sv then return false end
    local sl = sv.Value
    if sl == 3 or sl == "3" then return false end
    return true
end

function isOwnerNear(model)
    local cfg = model:FindFirstChild("Config")
    local ldv = cfg and cfg:FindFirstChild("LastDrove")
    if not ldv then return false end
    local ownerName = tostring(ldv.Value)
    if ownerName == "" then return false end
    local ds = model:FindFirstChild("DriveSeat")
    if not ds or not ds:IsA("BasePart") then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == ownerName then
            local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - ds.Position).Magnitude <= 3 then
                return true
            end
        end
    end
    return false
end

function scan()
    -- Clean up destroyed models
    for m in pairs(csStatus) do
        if not m.Parent then
            if csStatus[m].shown and _G.CarScanner_Remove then
                _G.CarScanner_Remove(m)
            end
            csStatus[m] = nil
        end
    end

    local shown       = 0
    local confirming  = 0

    for _, model in ipairs(getVehicles()) do
        if not isEligible(model) then
            local st = csStatus[model]
            if st and st.shown and _G.CarScanner_Remove then
                _G.CarScanner_Remove(model)
            end
            csStatus[model] = nil
            continue
        end

        local moving    = getDriveVel(model) > MOVE_THRESH
        local ownerNear = isOwnerNear(model)
        local st        = csStatus[model]

        if not st then
            csStatus[model] = { moving = moving, stoppedAt = moving and nil or tick(), shown = false }
            st = csStatus[model]
        end

        -- Owner came back or car started moving → remove if shown
        if ownerNear or moving then
            if st.shown and _G.CarScanner_Remove then
                _G.CarScanner_Remove(model)
                st.shown = false
            end
            st.moving    = true
            st.stoppedAt = nil
            continue
        end

        -- Car is parked and owner not nearby
        if not st.stoppedAt then st.stoppedAt = tick() end
        st.moving = false

        local waited = tick() - st.stoppedAt
        if not st.shown and waited >= AFK_CONFIRM then
            if _G.CarScanner_Add then
                _G.CarScanner_Add(model, st.stoppedAt)
                st.shown = true
            end
        elseif not st.shown then
            confirming = confirming + 1
        end
        if st.shown then shown = shown + 1 end
    end

    if _G.CarScanner_SetCount then _G.CarScanner_SetCount(shown, confirming) end
end

_G.CarScanner_Start = function()
    if csRunning then return end
    csRunning = true
    csStatus  = {}
    task.spawn(function()
        while csRunning do
            if _G.CarScanner_IsActive and _G.CarScanner_IsActive() then
                pcall(scan)
            end
            task.wait(SCAN_RATE)
        end
    end)
end

_G.CarScanner_Stop = function()
    csRunning = false
    csStatus  = {}
end

end) -- end CAR SCANNER MONITOR

