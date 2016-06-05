if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end

if not sgs.ai_damage_effect then
	sgs.ai_damage_effect = {}
end

function SmartAI:useCardTacticalCombo(card, use)
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