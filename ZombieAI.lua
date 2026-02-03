--!strict
-- Zombie AI avanzado para Roblox Studio
-- Características:
-- 1) Sigue al jugador más cercano con Pathfinding
-- 2) Sistema de escucha (sonido) con memoria de última posición oída
-- 3) Línea de visión: no puede verte si estás detrás de una pared
--
-- Requisitos:
-- - Modelo de zombie con Humanoid y HumanoidRootPart
-- - Este script va como Script de servidor dentro del modelo del zombie
-- - Ajusta los parámetros según tu juego

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local zombie = script.Parent
local humanoid = zombie:WaitForChild("Humanoid") :: Humanoid
local root = zombie:WaitForChild("HumanoidRootPart") :: BasePart

-- === CONFIGURACIÓN ===
local DETECTION_RADIUS = 80
local HEARING_RADIUS = 60
local VIEW_DISTANCE = 70
local FOV_DOT = 0.5 -- 0.5 = ~60 grados
local REPATH_INTERVAL = 1.0
local MEMORY_TIME = 4.0
local ATTACK_DISTANCE = 4

local PATH_PARAMS = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = true,
}

-- === ESTADO ===
local lastHeardPosition: Vector3? = nil
local lastHeardTime = 0
local currentTarget: Player? = nil
local currentPath: Path? = nil
local waypoints: {PathWaypoint} = {}
local waypointIndex = 0
local lastRepath = 0
local chasing = false

-- === UTILIDADES ===
local function getCharacterRoot(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function distanceTo(pos: Vector3): number
	return (root.Position - pos).Magnitude
end

local function hasLineOfSight(targetPos: Vector3): boolean
	local direction = targetPos - root.Position
	if direction.Magnitude > VIEW_DISTANCE then
		return false
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {zombie}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = workspace:Raycast(root.Position, direction, params)
	if not result then
		return true
	end

	-- Si el rayo impacta algo antes del objetivo, no hay visión
	return (result.Position - targetPos).Magnitude < 2
end

local function isInFOV(targetPos: Vector3): boolean
	local dir = (targetPos - root.Position).Unit
	local forward = root.CFrame.LookVector
	return forward:Dot(dir) >= FOV_DOT
end

local function getNearestPlayer(): (Player?, BasePart?)
	local nearest: Player? = nil
	local nearestRoot: BasePart? = nil
	local nearestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local pr = getCharacterRoot(player)
		if pr then
			local d = distanceTo(pr.Position)
			if d < nearestDist and d <= DETECTION_RADIUS then
				nearest = player
				nearestRoot = pr
				nearestDist = d
			end
		end
	end

	return nearest, nearestRoot
end

local function canSeePlayer(player: Player): boolean
	local pr = getCharacterRoot(player)
	if not pr then
		return false
	end
	return isInFOV(pr.Position) and hasLineOfSight(pr.Position)
end

local function heardPlayer(player: Player): boolean
	local pr = getCharacterRoot(player)
	if not pr then
		return false
	end
	if distanceTo(pr.Position) <= HEARING_RADIUS then
		lastHeardPosition = pr.Position
		lastHeardTime = time()
		return true
	end
	return false
end

local function computePath(destination: Vector3): boolean
	local path = PathfindingService:CreatePath(PATH_PARAMS)
	path:ComputeAsync(root.Position, destination)
	if path.Status ~= Enum.PathStatus.Success then
		return false
	end
	currentPath = path
	waypoints = path:GetWaypoints()
	waypointIndex = 1
	return true
end

local function moveToNextWaypoint()
	if waypointIndex > #waypoints then
		return
	end
	local wp = waypoints[waypointIndex]
	if wp.Action == Enum.PathWaypointAction.Jump then
		humanoid.Jump = true
	end
	humanoid:MoveTo(wp.Position)
end

humanoid.MoveToFinished:Connect(function(reached)
	if reached then
		waypointIndex += 1
		moveToNextWaypoint()
	end
end)

-- === LOOP PRINCIPAL ===
RunService.Heartbeat:Connect(function()
	local now = time()

	-- 1) Buscar al jugador más cercano
	local nearestPlayer, nearestRoot = getNearestPlayer()

	-- 2) Prioridad: visión directa
	if nearestPlayer and nearestRoot and canSeePlayer(nearestPlayer) then
		currentTarget = nearestPlayer
		chasing = true
		lastHeardPosition = nil
	elseif nearestPlayer and heardPlayer(nearestPlayer) then
		-- 3) Escucha: recuerda última posición
		currentTarget = nearestPlayer
		chasing = true
	elseif lastHeardPosition and (now - lastHeardTime) < MEMORY_TIME then
		-- 4) Ir a la última posición oída
		chasing = true
	else
		chasing = false
		currentTarget = nil
		lastHeardPosition = nil
	end

	if not chasing then
		return
	end

	local targetPos: Vector3?
	if currentTarget then
		local rootPart = getCharacterRoot(currentTarget)
		if rootPart then
			targetPos = rootPart.Position
		end
	end

	if not targetPos then
		targetPos = lastHeardPosition
	end

	if not targetPos then
		return
	end

	-- Recalcular path periódicamente
	if now - lastRepath >= REPATH_INTERVAL then
		lastRepath = now
		if computePath(targetPos) then
			moveToNextWaypoint()
		end
	end

	-- Ataque simple (puedes reemplazar con tu sistema)
	if currentTarget and nearestRoot then
		if distanceTo(nearestRoot.Position) <= ATTACK_DISTANCE then
			-- Daño básico
			local hum = currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") :: Humanoid?
			if hum then
				hum:TakeDamage(10)
			end
		end
	end
end)
