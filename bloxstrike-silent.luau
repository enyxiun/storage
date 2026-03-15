local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CombatSettings = {
    ShowFOV = true,
    Color = Color3.fromRGB(255, 255, 255),
    aimFOV = 300,
    targetPart = "HumanoidRootPart",
    SilentEnabled = true,
    HitChance = 100,
    VisibleCheck = false
}

local FOVCircle = nil

local function updateFOVCircle()
    if FOVCircle then
        FOVCircle.Visible = false
        FOVCircle:Remove()
        FOVCircle = nil
    end
    
    if CombatSettings.ShowFOV then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 1
        FOVCircle.Color = CombatSettings.Color
        FOVCircle.Transparency = 0.5
        FOVCircle.Filled = false
        FOVCircle.Visible = true
        FOVCircle.Radius = CombatSettings.aimFOV
        FOVCircle.NumSides = 200
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end
end

local function teamCheck(p)
    return p:GetAttribute("Team") ~= LocalPlayer:GetAttribute("Team")
end

local function IsVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, Camera}
    local result = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = CombatSettings.aimFOV
    local mousePos = UserInputService:GetMouseLocation()
        
    local players = Players:GetPlayers()
    for i = 1, #players do
        local p = players[i]
        if p ~= LocalPlayer and p.Character and teamCheck(p) then
            local targetPart = p.Character:FindFirstChild(CombatSettings.targetPart)
            if targetPart then
                local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    if CombatSettings.VisibleCheck and not IsVisible(targetPart) then continue end
                    
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closest = p.Character
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function SetupSilentAim()
    local success, err = pcall(function()
        local BulletModule = ReplicatedStorage:WaitForChild("Components"):WaitForChild("Weapon"):WaitForChild("Classes"):WaitForChild("Bullet")
        local Bullet = require(BulletModule)
        local realMath = math
        
        getfenv(Bullet._performRaycast).math = setmetatable({}, {
            __index = function(_, index)
                if index == "min" then
                    local target = getClosestPlayer()
                    if target and CombatSettings.SilentEnabled then
                        if realMath.random(1, 100) <= CombatSettings.HitChance then
                            local part = target:FindFirstChild(CombatSettings.targetPart) or target:FindFirstChild("Head")
                            if part then
                                debug.setstack(2, 5, Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit))
                                return function() return 0 end
                            end
                        end
                    end
                end
                return realMath[index]
            end
        })
    end)

    if not success then
        LocalPlayer:Kick("This isnt a ban. is just a kick from script. the hook is wrong. if you got this erro. pls report")
    end
end

RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end)

SetupSilentAim()
