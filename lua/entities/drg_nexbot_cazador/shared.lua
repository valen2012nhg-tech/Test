ENT.Base = "drgbase_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "DRG Cazador"
ENT.Category = "DRGBase Nextbots"
ENT.Models = {"models/Zombie/Classic.mdl"}
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.UseWalkframes = false
ENT.BloodColor = BLOOD_COLOR_RED
ENT.RagdollOnDeath = true

ENT.Factions = {"FACTION_DRG_CAZADOR"}
ENT.PlayerTargeting = true
ENT.DetectionRange = 2000
ENT.AttackRange = 80
ENT.AttackDamage = 40
ENT.AttackCooldown = 1.0
ENT.MaxHealth = 250
ENT.WalkSpeed = 130
ENT.RunSpeed = 260

function ENT:CustomInitialize()
  self:SetHealth(self.MaxHealth)
  self._nextAttack = 0
end
