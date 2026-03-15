AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PATH_RECOMPUTE_DELAY = 0.25

function ENT:CanTarget(ent)
  return IsValid(ent) and ent:IsPlayer() and ent:Alive()
end

function ENT:GetClosestPlayer()
  local bestTarget
  local bestDistance = math.huge

  for _, ply in ipairs(player.GetHumans()) do
    if self:CanTarget(ply) then
      local dist = self:GetRangeTo(ply)
      if dist < bestDistance then
        bestDistance = dist
        bestTarget = ply
      end
    end
  end

  return bestTarget
end

function ENT:DoMeleeAttack(target)
  if CurTime() < self._nextAttack then return end
  if not self:CanTarget(target) then return end

  if self:GetRangeTo(target) > self.AttackRange then return end

  self._nextAttack = CurTime() + self.AttackCooldown

  self:EmitSound("npc/zombie/zo_attack1.wav", 80, 100)

  local dmg = DamageInfo()
  dmg:SetDamage(self.AttackDamage)
  dmg:SetAttacker(self)
  dmg:SetInflictor(self)
  dmg:SetDamageType(DMG_SLASH)
  target:TakeDamageInfo(dmg)
end

function ENT:ChaseTarget(target)
  if not self:CanTarget(target) then return end

  local path = Path("Follow")
  path:SetMinLookAheadDistance(120)
  path:SetGoalTolerance(self.AttackRange * 0.75)
  path:Compute(self, target:GetPos())

  if not path:IsValid() then return end

  while path:IsValid() and self:CanTarget(target) do
    path:Update(self, target:GetPos())

    if self.loco:IsStuck() then
      self:HandleStuck()
      return
    end

    if self:GetRangeTo(target) <= self.AttackRange then
      self:DoMeleeAttack(target)
    end

    if path:GetAge() > PATH_RECOMPUTE_DELAY then
      path:Compute(self, target:GetPos())
    end

    coroutine.yield()
  end
end

function ENT:RunBehaviour()
  while true do
    local target = self:GetClosestPlayer()

    if IsValid(target) then
      self:StartActivity(ACT_RUN)
      self.loco:SetDesiredSpeed(self.RunSpeed)
      self:ChaseTarget(target)
    else
      self:StartActivity(ACT_WALK)
      self.loco:SetDesiredSpeed(self.WalkSpeed)
      coroutine.wait(0.2)
    end

    coroutine.yield()
  end
end

function ENT:OnInjured(dmg)
  self:EmitSound("npc/zombie/zombie_pain" .. math.random(1, 6) .. ".wav", 75, 100)
end

function ENT:OnOtherKilled(victim, info)
  if victim:IsPlayer() then
    self:EmitSound("npc/zombie/zombie_voice_idle" .. math.random(1, 14) .. ".wav", 85, 100)
  end
end
