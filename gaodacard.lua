module("extensions.gaodacard", package.seeall)
extension = sgs.Package("gaodacard", sgs.Package_CardPack)

shoot = sgs.CreateBasicCard{--BUG:can't view as
	name = "shoot",
	class_name = "Shoot",
	subtype = "attack_card",
	target_fixed = false,
	can_recast = false,
	suit = 0,
	number = 6,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
			and #targets < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, self)
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player:usedTimes("Shoot") < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, self)
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		local hit_targets, missed_targets = {}, sgs.SPlayerList()
		math.random()
		for _, t in ipairs(targets) do
			if source:inMyAttackRange(t) or math.random(1, 100) <= 70 then
				room:setEmotion(t, "lockon")
				table.insert(hit_targets, t)
			else
				missed_targets:append(t)
			end
		end
		if not missed_targets:isEmpty() then
			local log = sgs.LogMessage()
			log.type = "#shoot_failed"
			log.from = source
			log.to = missed_targets
			log.card_str = self:toString()
			room:sendLog(log)
		end
		for _, t in ipairs(hit_targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		--room:setEmotion(source, "killer")
		if not room:askForCard(target, "jink", "shoot-jink:"..source:objectName()..":"..self:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, source) then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			damage.card = self
			room:damage(damage)
		end
	end
}

for n = 6, 12, 2 do
	shoot:clone(0, n):setParent(extension)
end
for n = 7, 13, 2 do
	shoot:clone(1, n):setParent(extension)
end
for n = 6, 12, 3 do
	shoot:clone(2, n):setParent(extension)
end
for n = 7, 13, 3 do
	shoot:clone(3, n):setParent(extension)
end

pierce_shoot = sgs.CreateBasicCard{
	name = "pierce_shoot",
	class_name = "Shoot",
	subtype = "attack_card",
	target_fixed = false,
	can_recast = false,
	suit = 0,
	number = 6,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
			and #targets < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, self)
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player:usedTimes("Shoot") < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, self)
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		local hit_targets, missed_targets = {}, sgs.SPlayerList()
		math.random()
		for _, t in ipairs(targets) do
			if source:inMyAttackRange(t) or math.random(1, 100) <= 70 then
				room:setEmotion(t, "lockon")
				table.insert(hit_targets, t)
			else
				missed_targets:append(t)
			end
		end
		if not missed_targets:isEmpty() then
			local log = sgs.LogMessage()
			log.type = "#shoot_failed"
			log.from = source
			log.to = missed_targets
			log.card_str = self:toString()
			room:sendLog(log)
		end
		for _, t in ipairs(hit_targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		--room:setEmotion(source, "killer")
		if not room:askForCard(target, "jink", "shoot-jink:"..source:objectName()..":"..self:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, source) then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			damage.card = self
			room:damage(damage)
		end
	end
}

for n = 1, 3, 2 do
	pierce_shoot:clone(0, n):setParent(extension)
end
for n = 2, 4, 2 do
	pierce_shoot:clone(1, n):setParent(extension)
end
pierce_shoot:clone(2, 5):setParent(extension)
pierce_shoot:clone(3, 6):setParent(extension)

spread_shoot = sgs.CreateBasicCard{
	name = "spread_shoot",
	class_name = "Shoot",
	subtype = "attack_card",
	target_fixed = false,
	can_recast = false,
	suit = 0,
	number = 6,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
			and #targets < 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, self)
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player:usedTimes("Shoot") < 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, self)
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		local hit_targets, missed_targets = {}, sgs.SPlayerList()
		math.random()
		for _, t in ipairs(targets) do
			if (source:inMyAttackRange(t) and math.random(1, 100) <= 50 + 50 / #targets)
				or (not source:inMyAttackRange(t) and math.random(1, 100) <= 35 + 35 / #targets) then
				room:setEmotion(t, "lockon")
				table.insert(hit_targets, t)
			else
				missed_targets:append(t)
			end
		end
		if not missed_targets:isEmpty() then
			local log = sgs.LogMessage()
			log.type = "#shoot_failed"
			log.from = source
			log.to = missed_targets
			log.card_str = self:toString()
			room:sendLog(log)
		end
		for _, t in ipairs(hit_targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		--room:setEmotion(source, "killer")
		if not room:askForCard(target, "jink", "shoot-jink:"..source:objectName()..":"..self:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, source) then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			damage.card = self
			room:damage(damage)
		end
	end
}

spread_shoot:clone(0, 1):setParent(extension)
spread_shoot:clone(1, 2):setParent(extension)
for n = 3, 5, 2 do
	spread_shoot:clone(2, n):setParent(extension)
end
for n = 4, 6, 2 do
	spread_shoot:clone(3, n):setParent(extension)
end

Guard = sgs.CreateBasicCard{
	name = "Guard",
	class_name = "Guard",
	subtype = "defense_card",
	target_fixed = true,
	can_recast = false,
	suit = 2,
	number = 9,
	available = function(self, player)
		return false
	end
}

for s = 2, 3, 1 do
	for n = 9, 12, 1 do
		Guard:clone(s, n):setParent(extension)
	end
end
Guard:clone(0, 7):setParent(extension)
Guard:clone(0, 13):setParent(extension)
Guard:clone(1, 7):setParent(extension)
Guard:clone(1, 13):setParent(extension)

counter_guard = sgs.CreateBasicCard{
	name = "counter_guard",
	class_name = "Guard",
	subtype = "defense_card",
	target_fixed = true,
	can_recast = false,
	suit = 2,
	number = 9,
	available = function(self, player)
		return false
	end
}

counter_guard:clone(0, 2):setParent(extension)
counter_guard:clone(2, 2):setParent(extension)

Guard_skill = sgs.CreateTriggerSkill{
	name = "Guard_skill",
	events = {sgs.DamageInflicted},
	global = true,
	priority = -1,
	can_trigger = function(self, target)
		if target:getMark("luaqiangwub") > 0 then return false end --强武另行处理
		for _,card in sgs.qlist(target:getHandcards()) do
			if card:isKindOf("Guard") then
				return target and target:isAlive()
			end
		end
		return false
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Shoot") and damage.card:objectName() ~= "pierce_shoot") then
			local guard
			if damage.from then
				guard = room:askForCard(player, "Guard", "@Guard:"..damage.card:objectName()..":"..damage.from:objectName(), sgs.QVariant(), sgs.Card_MethodUse, damage.from)
			else
				guard = room:askForCard(player, "Guard", "@@Guard:"..damage.card:objectName(), sgs.QVariant(), sgs.Card_MethodUse, nil)
			end
			if guard then
				math.random()
				if (damage.card:isKindOf("Shoot") or math.random(1, 100) <= 70) then
					local log = sgs.LogMessage()
					log.type = "#burstd"
					log.to:append(damage.to)
					log.arg = damage.damage
					log.arg2 = damage.damage - 1
					room:sendLog(log)
					damage.damage = damage.damage - 1
					if damage.damage < 1 then
						room:setEmotion(player, "skill_nullify")
						
						if damage.from and guard:objectName() == "counter_guard" then
							room:doAnimate(1, player:objectName(), damage.from:objectName())
							local card = room:askForCard(damage.from, "jink", "@fengong", sgs.QVariant(), sgs.Card_MethodResponse, player, false, self:objectName(), false)
							if not card then
								room:damage(sgs.DamageStruct(guard, player, damage.from))
							end
						end
						
						return true
					end
					data:setValue(damage)
				else
					local log = sgs.LogMessage()
					log.type = "#Guard_failed"
					log.from = player
					log.card_str = guard:toString()
					room:sendLog(log)
				end
			end
		end
	end
}

tactical_combo = sgs.CreateTrickCard{
	name = "tactical_combo",
	class_name = "TacticalCombo",
	suit = 1,
	number = 2,
	target_fixed = false,
	can_recast = false,
	subtype = "multiple_target_trick",
	subclass = sgs.LuaTrickCard_LuaTrickCard_TypeNormal,
	filter = function(self, targets, to_select)
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:objectName() == effect.to:objectName() and effect.to:getAI() and sgs.Slash_IsAvailable(effect.to) then --For AI use only
			room:drawCards(effect.to, 1, "tactical_combo")
		else
			room:setPlayerFlag(effect.to, "tactical_combo")
			local slash = room:askForUseCard(effect.to, "slash", "@tactical_combo", -1, sgs.Card_MethodUse, false)
			if (not slash) then
				room:drawCards(effect.to, 1, "tactical_combo")
			end
			room:setPlayerFlag(effect.to, "-tactical_combo")
		end
	end
}

tactical_combo:clone(1, 1):setParent(extension)
tactical_combo:clone(1, 2):setParent(extension)
tactical_combo:clone(3, 1):setParent(extension)
tactical_combo:clone(3, 2):setParent(extension)

laplace_box_skill = sgs.CreateTriggerSkill{
	name = "laplace_box_skill",
	events = {sgs.EventPhaseStart, sgs.Damaged},
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasTreasure("laplace_box")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				room:sendCompulsoryTriggerLog(player, "laplace_box")
				local use = sgs.CardUseStruct()
				local card = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
				card:setSkillName("laplace_box")
				use.card = card
				use.from = player
				room:useCard(use)
			end
		else
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() then
				room:sendCompulsoryTriggerLog(player, "laplace_box")
				room:obtainCard(damage.from, player:getTreasure():getRealCard())
			end
		end
	end
}

laplace_box_card = sgs.CreateTriggerSkill{
	name = "laplace_box_card",
	events = {sgs.TargetSpecifying, sgs.CardEffected, sgs.CardFinished},
	global = true,
	priority = 3,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "laplace_box" and use.card:isKindOf("AmazingGrace") and use.from:objectName() == player:objectName() then
				local card_ids = room:getTag("AmazingGrace"):toIntList()
				card_ids:append(room:getNCards(1):first())
				local _data = sgs.QVariant()
				_data:setValue(card_ids)
				room:setTag("LaplaceBox", _data)
				room:removeTag("AmazingGrace")
				room:clearAG()
				room:fillAG(card_ids)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card and effect.card:getSkillName() == "laplace_box" and effect.card:isKindOf("AmazingGrace") then
				room:setPlayerFlag(player, "Global_NonSkillNullify")
				local card_ids = room:getTag("LaplaceBox"):toIntList()
				if not room:isCanceled(effect) then
					local n = 1
					if effect.from:objectName() == player:objectName() then
						n = 2
					end
					for i = 1, n, 1 do
						local card_id = room:askForAG(player, card_ids, false, "amazing_grace")
						room:takeAG(player, card_id)
						card_ids:removeOne(card_id)
						local _data = sgs.QVariant()
						_data:setValue(card_ids)
						room:setTag("LaplaceBox", _data)
					end
				end
				return true
			end
		else
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "laplace_box" and use.card:isKindOf("AmazingGrace") and use.from:objectName() == player:objectName() then
				local card_ids = room:getTag("LaplaceBox"):toIntList()
				if card_ids:isEmpty() then return false end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(card_ids)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "amazing_grace", "")
				room:throwCard(dummy, reason, nil)
				room:removeTag("LaplaceBox")
			end
		end
	end
}

laplace_box = sgs.CreateTreasure{
	name = "laplace_box",
	class_name = "LaplaceBox",
	suit = 3,
	number = 7,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("laplace_box_skill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end
}

laplace_box:clone():setParent(extension)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Guard_skill") then skills:append(Guard_skill) end
if not sgs.Sanguosha:getSkill("laplace_box_skill") then skills:append(laplace_box_skill) end
if not sgs.Sanguosha:getSkill("laplace_box_card") then skills:append(laplace_box_card) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["gaodacard"] = "高达杀卡牌",

	["shoot"] = "射击",
	["Shoot"] = "射击",
	[":shoot"] = "基本牌\
	<b>时机</b>：出牌阶段限一次\
	<b>目标</b>：一名其他角色\
	<b>命中率</b>：攻击范围内：100%，攻击范围外：70%\
	<b>效果</b>：被命中的目标角色须打出一张【闪】，否则对其造成1点伤害。",
	["shoot-jink"] = "%src 使用了【%dest】，请打出一张【闪】",
	["#shoot_failed"] = "%from 对 %to 使用的 %card 命中失败",
	
	["pierce_shoot"] = "贯穿射击",
	[":pierce_shoot"] = "基本牌\
	<b>时机</b>：出牌阶段限一次\
	<b>目标</b>：一名其他角色\
	<b>命中率</b>：攻击范围内：100%，攻击范围外：70%\
	<b>效果</b>：被命中的目标角色须打出一张【闪】，否则对其造成1点伤害，<b><font color='orange'>不可被【挡】响应</font></b>。",
	
	["spread_shoot"] = "扩散射击",
	[":spread_shoot"] = "基本牌\
	<b>时机</b>：出牌阶段限一次\
	<b>目标</b>：<b><font color='#00cc66'>一至两名其他角色</font></b>\
	<b>命中率</b>：攻击范围内：<b><font color='#00cc66'>50+50/目标数 %</font></b>，攻击范围外：<b><font color='#00cc66'>35+35/目标数 %</font></b>\
	<b>效果</b>：被命中的目标角色须打出一张【闪】，否则对其造成1点伤害。",
	
	["Guard"] = "挡",
	[":Guard"] = "基本牌\
	<b>时机</b>：受到【杀】/【射击】的伤害时\
	<b>目标</b>：此【杀】/【射击】造成的伤害\
	<b>格挡率</b>：【杀】：70%，【射击】：100%\
	<b>效果</b>：被格挡的【杀】/【射击】对你造成的伤害-1。",
	["@Guard"] = "%dest 令你受到【%src】的伤害，请使用一张【档】",
	["@@Guard"] = "你受到【%src】造成的伤害，请使用一张【档】",
	["#Guard_failed"] = "%from 使用的 %card 格挡失败",
	
	["counter_guard"] = "反击挡",
	[":counter_guard"] = "基本牌\
	<b>时机</b>：受到【杀】/【射击】的伤害时\
	<b>目标</b>：此【杀】/【射击】造成的伤害\
	<b>格挡率</b>：【杀】：70%，【射击】：100%\
	<b>效果</b>：被格挡的【杀】/【射击】对你造成的伤害-1，<b><font color='#6952d8'>若伤害减至0，来源须打出一张【闪】，否则你对其造成1点伤害</font></b>。",
	
	["tactical_combo"] = "战术连携",
	["TacticalCombo"] = "战术连携",
	[":tactical_combo"] = "战术牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一至两名角色\
	<b>效果</b>：令目标角色选择一项：使用一张【杀】（无次数限制），或摸一张牌。",
	["@tactical_combo"] = "请使用一张【杀】（无次数限制），或摸一张牌。",
	
	["laplace_box"] = "拉普拉斯之盒",
	["LaplaceBox"] = "拉普拉斯之盒",
	[":laplace_box"] = "装备牌·宝物\
	<b>宝物技能</b>：\
	1. 锁定技。结束阶段开始时，视为你使用一张【和平协议】，并额外亮出一张牌，且你额外获得其中一张牌。\
	2. 锁定技。当你受到伤害后，伤害来源获得此牌。",
}