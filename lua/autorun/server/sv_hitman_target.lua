-- convars
local creditsBonus = CreateConVar("ttt2_hitman_target_credit_bonus", "1", FCVAR_SERVER_CAN_EXECUTE, "The credit bonus given when a Traitor kills his target. (Def: 2)")
local chatReveal = CreateConVar("ttt2_hitman_target_chatreveal", "0", FCVAR_SERVER_CAN_EXECUTE, "Enables or disables if the Traitor should be revealed if he killed nontarget (Def: 0)")

-- select Targets
local function GetTargets(ply)
	local targets = {}
	local detes = {}

	if not IsValid(ply) or not ply:IsActive() or not ply:Alive() or ply.IsGhost and ply:IsGhost() or ply:GetSubRole() ~= ROLE_HITMAN then
		return targets
	end

	for _, pl in ipairs(player.GetAll()) do
		if pl:Alive() and pl:IsActive() and not pl:IsInTeam(ply) and (not pl.IsGhost or not pl:IsGhost()) then
			if pl:IsRole(ROLE_DETECTIVE) then
				detes[#detes + 1] = pl
			else
				targets[#targets + 1] = pl
			end
		end
	end

	if #targets < 1 then
		targets = detes
	end

	return targets
end

local function SelectNewTarget(ply)
	local targets = GetTargets(ply)

	if #targets > 0 then
		ply:SetTargetPlayer(targets[math.random(1, #targets)])
	else
		ply:SetTargetPlayer(nil)
	end
end

local function HitmanTargetChanged(ply, _, attacker)
	ply.targetAttacker = nil

	if GetRoundState() == ROUND_ACTIVE and IsValid(attacker) and attacker:IsPlayer() and (not attacker.IsGhost or not attacker:IsGhost()) then
		ply.targetAttacker = attacker
	end
end
hook.Add("PlayerDeath", "HitmanTargetChanged", HitmanTargetChanged)

local function HitmanTargetDied(ply)
	if GetRoundState() == ROUND_ACTIVE then
		local attacker = ply.targetAttacker

		if IsValid(attacker) and attacker:GetSubRole() == ROLE_HITMAN and (not attacker.IsGhost or not attacker:IsGhost()) and IsValid(attacker:GetTargetPlayer()) then
			if attacker:GetTargetPlayer() == ply then -- if attacker's target is the dead player
				local val = creditsBonus:GetInt()
				local text = ""

				if val > 0 and attacker:IsActive() then
					attacker:AddCredits(val)

					text = "You received " .. val .. " credit(s) for eleminating your target."
				else
					text = "You've killed your target!"
				end

				attacker:ChatPrint(text)

				SelectNewTarget(attacker)
			elseif chatReveal:GetBool() and attacker ~= ply then -- Reveal Sidekick
				local text = attacker:Nick() .. " is a " .. string.upper(attacker:GetSubRoleData().name) .. "!"

				for _, pl in ipairs(player.GetAll()) do
					pl:ChatPrint(text)
				end
			end
		end

		for _, pl in ipairs(player.GetAll()) do
			local target = pl:GetTargetPlayer()

			if (not IsValid(attacker) or pl ~= attacker) and (not pl.IsGhost or not pl:IsGhost()) and IsValid(target) and target == ply and pl:GetSubRole() == ROLE_HITMAN then
				pl:ChatPrint("Your target died...") -- info Textmessage

				SelectNewTarget(pl)
			end
		end
	end
end
hook.Add("PostPlayerDeath", "HitmanTargetDied", HitmanTargetDied)

local function HitmanTargetSpawned(ply)
	if GetRoundState() == ROUND_ACTIVE then
		for _, v in ipairs(player.GetAll()) do
			local target = v:GetTargetPlayer()

			if ply ~= v and v:IsActive() and v:Alive() and v:GetSubRole() == ROLE_HITMAN and (not IsValid(target) or not target:Alive() or not target:IsActive()) then
				SelectNewTarget(v)
			end
		end

		local target = ply:GetTargetPlayer()

		if ply:GetSubRole() == ROLE_HITMAN and (not IsValid(target) or not target:Alive() or not target:IsActive()) then
			SelectNewTarget(ply)
		end
	end
end
hook.Add("PlayerSpawn", "HitmanTargetSpawned", HitmanTargetSpawned)

local function HitmanTargetDisconnected(ply)
	for _, v in ipairs(player.GetAll()) do
		if v:GetSubRole() == ROLE_HITMAN and v:GetTargetPlayer() == ply then
			SelectNewTarget(v)
		end
	end
end
hook.Add("PlayerDisconnected", "HitmanTargetDisconnected", HitmanTargetDisconnected)

local function HitmanTargetRoleChanged(ply, old, new)
	if old == ROLE_HITMAN then
		ply:SetTargetPlayer(nil)
	end

	if GetRoundState() == ROUND_ACTIVE then
		for _, v in ipairs(player.GetAll()) do
			if v:GetSubRole() == ROLE_HITMAN and v:GetTargetPlayer() == ply and v:IsInTeam(ply) then
				SelectNewTarget(v)
			end
		end
	end
end
hook.Add("TTT2UpdateSubrole", "HitmanTargetRoleChanged", HitmanTargetRoleChanged)

local function HitmanGotSelected()
	for _, ply in ipairs(player.GetAll()) do
		if ply:GetSubRole() == ROLE_HITMAN then
			SelectNewTarget(ply)
		end
	end
end
hook.Add("TTTBeginRound", "HitmanGotSelected", HitmanGotSelected)
