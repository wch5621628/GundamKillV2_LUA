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
			local slash = room:askForUseCard(effect.to, "slash", "@tactical_combo", -1, sgs.Card_MethodUse, false)
			if (not slash) then
				room:drawCards(effect.to, 1, "tactical_combo")
			end
		end
	end
}
tactical_combo:clone(1, 1):setParent(extension)
tactical_combo:clone(1, 2):setParent(extension)
tactical_combo:clone(3, 1):setParent(extension)
tactical_combo:clone(3, 2):setParent(extension)

sgs.LoadTranslationTable{
	["gaodacard"] = "高达杀卡牌",

	["tactical_combo"] = "战术连携",
	["TacticalCombo"] = "战术连携",
	[":tactical_combo"] = "锦囊牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一至两名角色\
	<b>效果</b>：令目标角色选择一项：使用一张【杀】（无次数限制），或摸一张牌。",
	["@tactical_combo"] = "请使用一张【杀】（无次数限制），或摸一张牌。",
}
