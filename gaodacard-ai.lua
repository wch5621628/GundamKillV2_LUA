if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end

if not sgs.ai_damage_effect then
	sgs.ai_damage_effect = {}
end

function SmartAI:useCardShoot(card, use)
	if #self.enemies == 0 then return false end
	if self.player:usedTimes("Shoot") >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then return false end
	use.card = card
	if use.to then
		local f = function(a, b)
			if self.player:inMyAttackRange(a) == self.player:inMyAttackRange(b) then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return self.player:inMyAttackRange(a)
			end
		end
		table.sort(self.enemies, f)
		local tar = 1
		if card:objectName() == "spread_shoot" then
			tar = 2
		end
		for _,enemy in ipairs(self.enemies) do
			if enemy:getMark("@duilieB") > 0 and math.mod(card:getNumber(), 2) == 0 and card:getNumber() > 0 then continue end
			use.to:append(enemy)
			if use.to:length() >= tar + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) then return end
		end
	end
end

sgs.ai_use_value.Shoot = sgs.ai_use_value.Slash
sgs.ai_keep_value.Shoot = sgs.ai_keep_value.Slash
sgs.ai_use_priority.Shoot = sgs.ai_use_priority.Slash

sgs.ai_use_value.Guard = sgs.ai_use_value.Jink
sgs.ai_keep_value.Guard = sgs.ai_keep_value.Jink

function SmartAI:useCardTacticalCombo(card, use)
	if self.player:getMark("@duilieB") > 0 and math.mod(card:getNumber(), 2) == 0 and card:getNumber() > 0 then return end
	use.card = card
	if use.to then
		local targets = self.friends
		for i = 1, 2, 1 do
			local n = math.random(#targets)
			use.to:append(targets[n])
			table.removeOne(targets, targets[n])
			if #targets == 0 then break end
		end
		return
	end
end

sgs.ai_use_priority.TacticalCombo = sgs.ai_use_priority.Slash - 1
sgs.ai_use_value.TacticalCombo = 4
sgs.ai_keep_value.TacticalCombo = 1
sgs.dynamic_value.benefit.TacticalCombo = true

sgs.ai_nullification.TacticalCombo = function(self, card, from, to, positive)
	if positive then
		if self:isEnemy(to) and to:getHandcardNum() >= 3 then
			return true
		end
	else
		if self:isFriend(to) and to:getHandcardNum() >= 3 then
			return true
		end
	end
	return
end

sgs.ai_use_priority.LaplaceBox = 0.8

--高达杀乱入卡
function SmartAI:useCardFinalVent(card, use)
	if #self.enemies == 0 then return false end
	use.card = card
	if use.to then
		self:sort(self.enemies, "hp")
		for _,enemy in ipairs(self.enemies) do
			if enemy:getMark("@duilieB") > 0 and math.mod(card:getNumber(), 2) == 0 and card:getNumber() > 0 then continue end
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_priority.FinalVent = sgs.ai_use_priority.FireAttack + 0.1
sgs.ai_use_value.FinalVent = sgs.ai_use_value.FireAttack + 0.1
sgs.ai_keep_value.FinalVent = sgs.ai_keep_value.FireAttack + 0.1

sgs.ai_nullification.FinalVent = function(self, card, from, to, positive)
	if not positive then
		if self:isEnemy(to) then
			return true
		end
	else
		if self:isFriend(to) then
			return true
		end
	end
	return
end

function SmartAI:useCardDecade(card, use)
	if #self.enemies == 0 then return false end
	use.card = card
	if use.to then
		self:sort(self.enemies, "hp")
		for _,enemy in ipairs(self.enemies) do
			if enemy:getMark("@duilieB") > 0 and math.mod(card:getNumber(), 2) == 0 and card:getNumber() > 0 then continue end
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_priority.Decade = sgs.ai_use_priority.FireAttack + 0.1
sgs.ai_use_value.Decade = sgs.ai_use_value.FireAttack + 0.1
sgs.ai_keep_value.Decade = sgs.ai_keep_value.FireAttack + 0.1

sgs.ai_nullification.Decade = function(self, card, from, to, positive)
	if not positive then
		if self:isEnemy(to) then
			return true
		end
	else
		if self:isFriend(to) then
			return true
		end
	end
	return
end