module("extensions.gaodacard", package.seeall)
extension = sgs.Package("gaodacard", sgs.Package_CardPack)

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
if not sgs.Sanguosha:getSkill("laplace_box_skill") then skills:append(laplace_box_skill) end
if not sgs.Sanguosha:getSkill("laplace_box_card") then skills:append(laplace_box_card) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["gaodacard"] = "高达杀卡牌",

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