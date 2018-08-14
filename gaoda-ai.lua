--用于定义function willUse(self, className)
function getTurnUse(self)
    local cards = {}
    for _ ,c in sgs.qlist(self.player:getHandcards()) do
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end
    for _, id in sgs.qlist(self.player:getHandPile()) do
        local c = sgs.Sanguosha:getCard(id)
        if c:isAvailable(self.player) then table.insert(cards, c) end
    end
    if self.player:hasSkill("taoxi") and self.player:hasFlag("TaoxiRecord") then
        local taoxi_id = self.player:getTag("TaoxiId"):toInt()
        if taoxi_id and taoxi_id >= 0 then
            local taoxi_card = sgs.Sanguosha:getCard(taoxi_id)
            table.insert(cards, taoxi_card)
        end
    end

	if self.player:hasSkill("ronghe") then
		local list = self.player:property("ronghe"):toString():split("+")
		if #list > 0 then
			for _,l in ipairs(list) do
				local id = tonumber(l)
				if id and id >= 0 then
					local ronghe_card = sgs.Sanguosha:getCard(id)
					table.insert(cards, ronghe_card)
				end
			end
		end
    end
	
    local turnUse = {}
    local slash = sgs.Sanguosha:cloneCard("slash")
    local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
    self.slashAvail = slashAvail
    self.predictedRange = self.player:getAttackRange()
    self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

    self.weaponUsed = false
	--self:fillSkillCards(cards) 万恶的无限循环！！！！！
    self:sortByUseValue(cards)

    if self.player:hasWeapon("crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 1 then
        slashAvail = 100
        self.slashAvail = slashAvail
    elseif self.player:hasWeapon("vscrossbow") then
        slashAvail = slashAvail + 3
        self.slashAvail = slashAvail
    end

    for _, card in ipairs(cards) do
        local dummy_use = { isDummy = true }

        local type = card:getTypeId()
        self["use" .. sgs.ai_type_name[type + 1] .. "Card"](self, card, dummy_use)

        if dummy_use.card then
            if dummy_use.card:isKindOf("Slash") then
                if slashAvail > 0 then
                    slashAvail = slashAvail - 1
                    table.insert(turnUse, dummy_use.card)
                elseif dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(turnUse, dummy_use.card) end
            else
                if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
                    self.predictedRange = 10000
                elseif dummy_use.card:isKindOf("Weapon") then
                    self.predictedRange = sgs.weapon_range[card:getClassName()]
                    self.weaponUsed = true
                else
                    self.predictedRange = 1
                end
                if dummy_use.card:objectName() == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
                if dummy_use.card:objectName() == "VSCrossbow" then slashAvail = slashAvail + 3 self.slashAvail = slashAvail end
                table.insert(turnUse, dummy_use.card)
            end
        end
    end

    return turnUse
end

--判断AI在接下来的出牌阶段是否将会使用某牌（className）
function willUse(self, className)
	for _,card in ipairs(getTurnUse(self)) do
		if card:isKindOf(className) then
			return true
		end
	end
	return false
end

--地图炮
local map_skill={}
map_skill.name="map"
table.insert(sgs.ai_skills,map_skill)
map_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@map5") == 1 and #self.enemies > 0 then
		local card_str = ("#map:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#map"]=function(card, use, self)
	use.card = card
	for _,enemy in ipairs(self.enemies) do
		if use.to then use.to:append(enemy) end
	end
end

sgs.ai_use_value["map"] = 8
sgs.ai_use_priority["map"] = 5.3

--爆发系统
local bursta_skill={}
bursta_skill.name="bursta"
table.insert(sgs.ai_skills,bursta_skill)
bursta_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@bursta") == 1 and self.player:getMark("bursta") == 0 then
		local card_str = ("#bursta:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#bursta"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["bursta"] = 10
sgs.ai_use_priority["bursta"] = 10

local burstd_skill={}
burstd_skill.name="burstd"
table.insert(sgs.ai_skills,burstd_skill)
burstd_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@burstd") == 1 and self.player:getMark("burstd") == 0 then
		local card_str = ("#burstd:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#burstd"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["burstd"] = 10
sgs.ai_use_priority["burstd"] = 10

local burstp_skill={}
burstp_skill.name="burstp"
table.insert(sgs.ai_skills,burstp_skill)
burstp_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@burstp") == 1 and self.player:getMark("burstp") == 0 then
		local card_str = ("#burstp:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#burstp"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["burstp"] = 10
sgs.ai_use_priority["burstp"] = 10

--AI换肤
local skin_skill={}
skin_skill.name="skin"
table.insert(sgs.ai_skills,skin_skill)
skin_skill.getTurnUseCard=function(self,inclusive)
	math.random()
    if not self.player:hasUsed("#skin") and math.random(1, 100) <= 30 then
		local card_str = ("#skin:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#skin"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["skin"] = 1
sgs.ai_use_priority["skin"] = 10

--辉勇面
local yuexian_skill={}
yuexian_skill.name="yuexian"
table.insert(sgs.ai_skills,yuexian_skill)
yuexian_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("yuexian") ~= 1 and ((self.player:getMark("@rishi") == 0 and self.player:hasSkill("rishi"))
		or (self.player:getMark("@yihua") == 0 and self.player:hasSkill("yihua")) or (self.player:getMark("@shensheng") == 0 and self.player:hasSkill("shensheng"))) then
		if (self.player:getMark("@yihua") == 1 or not self.player:hasSkill("yihua"))
			and (self.player:getMark("@shensheng") == 1 or not self.player:hasSkill("shensheng")) and #self.enemies < 2
			and self.player:canSlash(self.enemies[1]) then
			return false
		end
		local card_str = ("#yuexian:.:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#yuexian"]=function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice.yuexian = function(self, choices, data)
	choices = choices:split("+")
	if #self.enemies < 2 and self.player:canSlash(self.enemies[1]) then
		table.removeOne(choices, "rishi")
	end
	return choices[1]
end

sgs.dynamic_value.benefit["yuexian"] = true

sgs.ai_use_value["yuexian"] = sgs.ai_use_value.Analeptic + 1
sgs.ai_use_priority["yuexian"] = sgs.ai_use_value.Analeptic + 1

sgs.ai_skill_invoke.yihua = function(self, data)
	return true
end

sgs.ai_skill_invoke.shensheng = function(self, data)
	return true
end

sgs.ai_skill_choice.shensheng = function(self, choices, data)
    local id = data:toString()
	if (sgs.Sanguosha:getCard(id):isKindOf("Weapon") and not self.player:getWeapon()) or
	   (sgs.Sanguosha:getCard(id):isKindOf("Armor") and not self.player:getArmor()) or
	   (sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse()) or
	   (sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse()) then
	    return "ssuse"
	else
	    return "ssobtain"
	end
end

sgs.ai_skill_use["@@shensheng"]=function(self,prompt)
    self:updatePlayers()
	local card = prompt:split(":")
	if card[2] == "slash" or card[2] == "fire_slash" or card[2] == "thunder_slash" then
	    self:sort(self.enemies, "defense")
		local targets = {}
		for _,enemy in ipairs(self.enemies) do
		    if (not self:slashProhibit(sgs.Sanguosha:getCard(card[5]), enemy)) and self.player:canSlash(enemy, sgs.Sanguosha:getCard(card[5])) then
				if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "peach" or card[2] == "analeptic" or card[2] == "ex_nihilo" or card[2] == "amazing_grace" or card[2] == "savage_assault" or card[2] == "archery_attack" or card[2] == "god_salvation" then
	    return ("%s:shensheng[%s:%s]=%s"):format(card[2],card[3],card[4],card[5])
	elseif card[2] == "iron_chain" then
	    local situation_is_friend = false
	    for _, friend in ipairs(self.friends) do
		    if friend:isChained() and (not friend:isProhibited(friend, sgs.Sanguosha:getCard(card[5]))) then
			    situation_is_friend = true
		    end
		end
		if situation_is_friend then
		    local targets = {}
			for _, friend in ipairs(self.friends) do
			    if friend:isChained() and (not friend:isProhibited(friend, sgs.Sanguosha:getCard(card[5]))) then
			        if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
					table.insert(targets,friend:objectName())
		        end
			end
			if #targets > 0 then
			    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
			else
			    return "."
			end
		else
		    local chained_enemy = 0
			local targets = {}
			for _, enemy in ipairs(self.enemies) do
			    if enemy:isChained() then
				    chained_enemy = chained_enemy + 1
				end
				if (not enemy:isChained()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
					if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
					table.insert(targets,enemy:objectName())
				end
			end
			if (#targets + chained_enemy) > 1 then
				return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
			else
			    return "."
			end
	    end
	elseif card[2] == "fire_attack" then
	    self:sort(self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isKongcheng()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "dismantlement" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "snatch" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) and
			self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, sgs.Sanguosha:getCard(card[5])) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "collateral" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if enemy:getWeapon() and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
			    for _, tos in ipairs(self.enemies) do
				    if enemy:objectName() ~= tos:objectName() and
					enemy:canSlash(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) and
					(not tos:isProhibited(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then
				        table.insert(targets,enemy:objectName())
						table.insert(targets,tos:objectName())
						break
					end
				end
			end
		end
		if #targets > 1 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "duel" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:getCard(card[5])) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "supply_shortage" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:containsTrick("supply_shortage")) and
			(not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) and
			self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, sgs.Sanguosha:getCard(card[5])) then
			    table.insert(targets,enemy:objectName())
				break
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "indulgence" then
	    self:sort(self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:containsTrick("indulgence")) and (not enemy:isProhibited(enemy, sgs.Sanguosha:getCard(card[5]))) then
			    table.insert(targets,enemy:objectName())
				break
			end
		end
		if #targets > 0 then
		    return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
		    return "."
		end
	elseif card[2] == "tactical_combo" then
		local targets = {}
		local friends = self.friends
		for i = 1, 2, 1 do
			local n = math.random(#friends)
			table.insert(targets, friends[n]:objectName())
			table.removeOne(friends, friends[n])
			if #friends == 0 then break end
		end
		if #targets > 0 then
			return ("%s:shensheng[%s:%s]=%s->%s"):format(card[2],card[3],card[4],card[5],table.concat(targets,"+"))
		else
			return "."
		end
	end
	return "."
end

--高达
--[[sgs.ai_skill_invoke.yuanzu = function(self, data)
	return true
end

sgs.ai_skill_choice.yuanzu = function(self, choices, data)
	local choice = choices:split("+")
	return choice[math.random(1, #choice)]
end]]

sgs.ai_skill_invoke.baizhan = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.to)
end

sgs.ai_skill_use["@@baizhan"]=function(self,prompt)
    self:updatePlayers()
	local name = self.player:property("baizhan"):toString()
	local num = self.player:getMark("baizhan")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	
	for _, card in ipairs(cards) do
		if card:getNumber() > num and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player))
			and (self.player:getHp() > 1 or (not isCard("Jink", card, self.player) and not isCard("Analeptic", card, self.player))) then
			
			local baizhan_card = sgs.Sanguosha:cloneCard(name)
			baizhan_card:addSubcard(card)
			
			if name == "slash" or name == "fire_slash" or name == "thunder_slash" then
				self:sort(self.enemies, "defense")
				local targets = {}
				for _,enemy in ipairs(self.enemies) do
					if (not self:slashProhibit(baizhan_card, enemy)) and self.player:canSlash(enemy, baizhan_card) then
						if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
						table.insert(targets,enemy:objectName())
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "peach" or name == "analeptic" or name == "ex_nihilo" or name == "amazing_grace" or name == "savage_assault" or name == "archery_attack" or name == "god_salvation" then
				return ("%s:baizhan[%s:%s]=%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId())
			elseif name == "iron_chain" then
				local situation_is_friend = false
				for _, friend in ipairs(self.friends) do
					if friend:isChained() and (not friend:isProhibited(friend, baizhan_card)) then
						situation_is_friend = true
					end
				end
				if situation_is_friend then
					local targets = {}
					for _, friend in ipairs(self.friends) do
						if friend:isChained() and (not friend:isProhibited(friend, baizhan_card)) then
							if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
							table.insert(targets,friend:objectName())
						end
					end
					if #targets > 0 then
						return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
					else
						return "."
					end
				else
					local chained_enemy = 0
					local targets = {}
					for _, enemy in ipairs(self.enemies) do
						if enemy:isChained() then
							chained_enemy = chained_enemy + 1
						end
						if (not enemy:isChained()) and (not enemy:isProhibited(enemy, baizhan_card)) then
							if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
							table.insert(targets,enemy:objectName())
						end
					end
					if (#targets + chained_enemy) > 1 then
						return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
					else
						return "."
					end
				end
			elseif name == "fire_attack" then
				self:sort(self.enemies, "hp")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:isKongcheng()) and (not enemy:isProhibited(enemy, baizhan_card)) then
						if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
						table.insert(targets,enemy:objectName())
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "dismantlement" then
				self:sort(self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, baizhan_card)) then
						if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
						table.insert(targets,enemy:objectName())
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "snatch" then
				self:sort(self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, baizhan_card)) and
					self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, baizhan_card) then
						if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
						table.insert(targets,enemy:objectName())
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "collateral" then
				self:sort(self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if enemy:getWeapon() and (not enemy:isProhibited(enemy, baizhan_card)) then
						for _, tos in ipairs(self.enemies) do
							if enemy:objectName() ~= tos:objectName() and
							enemy:canSlash(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) and
							(not tos:isProhibited(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then
								table.insert(targets,enemy:objectName())
								table.insert(targets,tos:objectName())
								break
							end
						end
					end
				end
				if #targets > 1 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "duel" then
				self:sort(self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:isProhibited(enemy, baizhan_card)) then
						if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, baizhan_card) then break end
						table.insert(targets,enemy:objectName())
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "supply_shortage" then
				self:sort(self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:containsTrick("supply_shortage")) and
					(not enemy:isProhibited(enemy, baizhan_card)) and
					self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, baizhan_card) then
						table.insert(targets,enemy:objectName())
						break
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "indulgence" then
				self:sort(self.enemies, "hp")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not enemy:containsTrick("indulgence")) and (not enemy:isProhibited(enemy, baizhan_card)) then
						table.insert(targets,enemy:objectName())
						break
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "tactical_combo" then
				local targets = {}
				local friends = self.friends
				for i = 1, 2, 1 do
					local n = math.random(#friends)
					table.insert(targets, friends[n]:objectName())
					table.removeOne(friends, friends[n])
					if #friends == 0 then break end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,card:getSuitString(),card:getNumberString(),card:getId(),table.concat(targets,"+"))
				else
					return "."
				end
			end
		end
	end
	return "."
end

local zhongjie_skill = {}
zhongjie_skill.name = "zhongjie"
table.insert(sgs.ai_skills, zhongjie_skill)
zhongjie_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return false end
	self:sort(self.enemies, "hp")
	if self:slashProhibit(sgs.Sanguosha:cloneCard("slash"), self.enemies[1]) then return false end
    if self.player:getMark("@zhongjie") > 0 and ((self.player:getHp() <= 1 and self.room:alivePlayerCount() > 2 and not self.player:isLord()) or
		(self.player:getHp() <= 2 and self:isWeak() and #self.enemies == 1 and self.enemies[1]:getHp() == 1)) then
		return sgs.Card_Parse("#zhongjie:.:")
	end
end

sgs.ai_skill_use_func["#zhongjie"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	use.card = card
	if use.to then
		use.to:append(self.enemies[1])
		return
	end
end

sgs.ai_use_value["zhongjie"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["zhongjie"] = 0.01

--夏亚渣古Ⅱ
sgs.ai_skill_invoke.huixing = function(self, data)
	if self.player:getPhase() == sgs.Player_Draw then
		return true
	else
		local resp = data:toCardResponse()
		return not self:isFriend(resp.m_who)
	end
end

--ZETA
local bianxing_skill = {}
bianxing_skill.name = "bianxing"
table.insert(sgs.ai_skills, bianxing_skill)
bianxing_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#bianxing") then return false end
	if self.player:hasSkill("jvjian") then
		if #self.enemies == 0 or self:getCardsNum("Slash") == 0 or self.player:getCardCount() <= 1 then return false end
		self:sort(self.enemies, "defenseSlash")
		local f = function(a, b)
			return self.player:distanceTo(a) < self.player:distanceTo(b)
		end
		table.sort(self.enemies, f)
		if not self:slashProhibit(sgs.Sanguosha:cloneCard("slash"), self.enemies[1]) and self.player:distanceTo(self.enemies[1]) - self.player:getAttackRange() <= 1
			and (self.player:distanceTo(self.enemies[1]) - self.player:getAttackRange() == 1 or self:getCardsNum("Slash") > 1 or self.enemies[1]:getArmor()) then
			return sgs.Card_Parse("#bianxing:.:")
		end
	elseif self.player:hasSkill("tuci") then
		if self.player:getCardCount() > 1 and not sgs.Slash_IsAvailable(self.player) then
			return sgs.Card_Parse("#bianxing:.:")
		end
	end
end

sgs.ai_skill_use_func["#bianxing"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isKindOf("Peach") or card:isKindOf("ExNihilo") then continue end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 1 then continue end
		if self.player:hasSkill("jvjian") and card:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then continue end
		use.card = sgs.Card_Parse("#bianxing:"..card:getId()..":")
		return
	end
end

sgs.ai_use_value["bianxing"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["bianxing"] = sgs.ai_use_value.Slash + 1

sgs.ai_skill_use["@@bianxing!"] = function(self, prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isKindOf("Peach") or card:isKindOf("ExNihilo") then continue end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 1 then continue end
		if card:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then continue end
		return ("#bianxing:"..card:getId()..":")
	end
end

sgs.ai_skill_invoke.chihun = function(self, data)
	return true
end

local jvjian_skill = {}
jvjian_skill.name = "jvjian"
table.insert(sgs.ai_skills, jvjian_skill)
jvjian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@chihun") > 0 and self.player:getMark("@jvjian") > 0 and #self.enemies > 0 then
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("Weapon") and card:isRed() then
				return sgs.Card_Parse("#jvjian:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#jvjian"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _,card in sgs.qlist(self.player:getCards("he")) do
		use.card = sgs.Card_Parse("#jvjian:" .. card:getId() .. ":")
		if use.to then use.to:append(self.enemies[1]) end
		return
	end
end

sgs.ai_use_value["jvjian"] = sgs.ai_use_value.Slash * 2
sgs.ai_use_priority["jvjian"] = sgs.ai_use_priority.Slash

sgs.ai_skill_choice.chonglang = function(self, choices, data)
	choices = choices:split("+")
	local use = data:toCardUse()
	if table.contains(choices, "chonglangB") then
		if use.to:first():getArmor() then
			return "chonglangB"
		end
	end
	if table.contains(choices, "chonglangA") then
		if self.player:getCardCount() > 1 and (not self.player:hasUsed("#bianxing") or self:getCardsNum("Slash") > 0)then
			return "chonglangA"
		else
			if table.contains(choices, "chonglangB") then
				return "chonglangB"
			end
		end
	end
	return "cancel"
end

local tuci_skill = {}
tuci_skill.name = "tuci"
table.insert(sgs.ai_skills, tuci_skill)
tuci_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@chihun") > 0 and self.player:getMark("@tuci") > 0 and #self.enemies > 0 then
		local x = 1
		for _,p in sgs.qlist(self.room:getPlayers()) do
			if p:objectName() ~= self.player:objectName() and p:isDead() then
				x = x + 1
			end
		end
		if x >= (self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic"))
			and (self.player:isLord() or #self.friends_noself == 0) then return false end
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				return sgs.Card_Parse("#tuci:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#tuci"] = function(card, use, self)
	local f = function(a, b)
		return a:getLostHp() < b:getLostHp()
	end
	table.sort(self.enemies, f)
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then
			use.card = sgs.Card_Parse("#tuci:.:")
			if use.to then use.to:append(self.enemies[1]) end
			return
		end
	end
end

sgs.ai_use_value["tuci"] = 2.33
sgs.ai_use_priority["tuci"] = sgs.ai_use_value.Slash + 2.33

--独角兽
sgs.ai_skill_invoke.shenshou = function(self, data)
	local target = data:toPlayer()
	return self:isEnemy(target)
end

sgs.ai_skill_cardask["@@shenshou"] = function(self)
    if self.player:hasSkill("xiaya") then
	    return self:getSuitNum("red",true,self.player) > 1
	elseif self.player:hasSkill("huanyi") and self.player:getMark("@huanyi") > 0 then
		return self:getSuitNum("red",true,self.player) > 1 and self:getSuitNum("red",false,self.player) > 0
	elseif self.player:getMark("@supermode") > 0 and self.player:getMark("jingxin") > 0 and self.player:getMark("@point") > 0 then
		return self:getSuitNum("red",true,self.player) > 0
	else
		if (self:getCardsNum("Peach") > 0) or (self:getSuitNum("red",true,self.player) < 2) or (self:getCardsNum("Jink") == 0) then return "." end
		for _, card in sgs.qlist(self.player:getCards("he")) do
		    if self:getCardsNum("Jink") > 1 then
				if card:isRed() then
					return card:getEffectiveId()
				end
			else
			    if card:isRed() and not isCard("Jink", card, self.player) then
					return card:getEffectiveId()
				end
			end
		end
	end
end

sgs.ai_skill_choice.NTD = function(self, choices, data)
	return "ntdrecover"
end

sgs.ai_skill_invoke.huimie = function(self, data)
    local use = data:toCardUse()
	return not use.card:isKindOf("GodSalvation") and not use.card:isKindOf("AmazingGrace") and self:isEnemy(use.from) and self:getSuitNum("red",false,self.player) > 0
end

sgs.ai_skill_use["@@huimie"] = function(self, prompt)
    self:updatePlayers()
	local card = prompt:split(":")
	if card[2] == "iron_chain" then
	    local situation_is_friend = false
	    for _, friend in ipairs(self.friends) do
		    if friend:isChained() and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			    situation_is_friend = true
		    end
		end
		if situation_is_friend then
		    local targets = {}
			for _, friend in ipairs(self.friends) do
			    if friend:isChained() and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			        if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
					table.insert(targets,friend:objectName())
		        end
			end
			if #targets > 0 then
			    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
			else
			    return "."
			end
		else
		    local chained_enemy = 0
			local targets = {}
			for _, enemy in ipairs(self.enemies) do
			    if enemy:isChained() then
				    chained_enemy = chained_enemy + 1
				end
				if (not enemy:isChained()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
					if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
					table.insert(targets,enemy:objectName())
				end
			end
			if (#targets + chained_enemy) > 1 then
				return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
			else
			    return "."
			end
	    end
	end
	if card[2] == "fire_attack" then
	    self:sort(self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isKongcheng()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
		    return "."
		end
	end
	if card[2] == "dismantlement" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
				if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets, friend:objectName())
			end
		end
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
		    return "."
		end
	end
	if card[2] == "snatch" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
		    if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) and
			self.player:distanceTo(friend) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,friend:objectName())
			end
		end
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) and
			self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
		    return "."
		end
	end
	if card[2] == "collateral" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if enemy:getWeapon() and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			    for _, tos in ipairs(self.enemies) do
				    if enemy:objectName() ~= tos:objectName() and
					enemy:canSlash(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) and
					(not tos:isProhibited(tos, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then
				        table.insert(targets,enemy:objectName())
						table.insert(targets,tos:objectName())
						break
					end
				end
			end
		end
		if #targets > 1 then
		    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
		    return "."
		end
	end
	if card[2] == "duel" then
	    self:sort(self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
		    if (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0))) then
			    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard(card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,enemy:objectName())
			end
		end
		if #targets > 0 then
		    return ("%s:huimie[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
		    return "."
		end
	end
	return "."
end

sgs.NTD_suit_value = {
	heart = 3.9,
	diamond = 3.9
}

function sgs.ai_cardneed.NTD(to, card)
	return card:isRed()
end

--FA独角兽

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

hasEquipArea = function(player, name)
	if (name == "treasure" and (Set(sgs.Sanguosha:getBanPackages()))["limitation_broken"] and (Set(sgs.Sanguosha:getBanPackages()))["gundamcard"])
	or player:getMark(name.."AreaRemoved") > 0 then
		return false
	end
	return true
end

blankEquipArea = function(player)
	if hasEquipArea(player, "weapon") or hasEquipArea(player, "armor") or hasEquipArea(player, "defensive_horse")
	or hasEquipArea(player, "offensive_horse") or hasEquipArea(player, "treasure") then
		return false
	end
	return true
end

local zhonggong_skill = {}
zhonggong_skill.name = "zhonggong"
table.insert(sgs.ai_skills, zhonggong_skill)
zhonggong_skill.getTurnUseCard = function(self, inclusive)
	if (not self.player:hasUsed("#zhonggong")) and (not blankEquipArea(self.player)) then
		return sgs.Card_Parse("#zhonggong:.:")
	end
end

sgs.ai_skill_use_func["#zhonggong"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		use.card = sgs.Card_Parse("#zhonggong:.:")
		if use.to then use.to:append(enemy) end
		return
	end
end

sgs.ai_skill_choice.zhonggong = function(self, choices, data)
	local equips = choices:split("+")
	for _,installed in sgs.qlist(self.player:getEquips()) do
		for _,equip in ipairs(equips) do
			if installed:getSubtype() ~= equip then
				return equip
			end
		end
	end
end

sgs.ai_use_value["zhonggong"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["zhonggong"] = sgs.ai_use_priority.Slash + 1

local linguang_skill = {}
linguang_skill.name = "linguang"
table.insert(sgs.ai_skills, linguang_skill)
linguang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@linguang") > 0 and self.player:isWounded() then
		if (self.player:getHp() > 1 and blankEquipArea(self.player)) or self.player:getHp() == 1 then
			return sgs.Card_Parse("#linguang:.:")
		end
	end
end

sgs.ai_skill_use_func["#linguang"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["linguang"] = sgs.ai_use_value.Peach + 0.1
sgs.ai_use_priority["linguang"] = sgs.ai_use_priority.Peach - 0.1

--刹帝利
sgs.ai_skill_invoke.qingyu = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_use["@@qingyu"] = function(self, prompt)
    self:updatePlayers()
	if prompt == "#qingyu1" then
	    return ("savage_assault:qingyu[spade:0]=.")
	elseif prompt == "#qingyu2" then
	    return ("archery_attack:qingyu[heart:0]=.")
	elseif prompt == "#qingyu3" then
	    self:sort(self.enemies, "handcard_defense")
		local targets = {}
		local card = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_Club, 0)
	    for _,enemy in ipairs(self.enemies) do
		    if (not enemy:isProhibited(enemy, card)) and (not enemy:isAllNude()) then
				if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) then break end
				table.insert(targets, enemy:objectName())
			end
		end
		if #targets > 0 then
	        return ("dismantlement:qingyu[club:0]=.->%s"):format(table.concat(targets,"+"))
		else
		    return "."
		end
	elseif prompt == "#qingyu4" then
	    self:sort(self.enemies, "handcard_defense")
		local targets = {}
		local card = sgs.Sanguosha:cloneCard("snatch", sgs.Card_Club, 0)
	    for _,enemy in ipairs(self.enemies) do
		    if (not enemy:isProhibited(enemy, card)) and (not enemy:isAllNude()) and
			self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) then
				if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) then break end
				table.insert(targets, enemy:objectName())
			end
		end
		if #targets > 0 then
	        return ("snatch:qingyu[diamond:0]=.->%s"):format(table.concat(targets,"+"))
		else
		    return "."
		end
	end
	return "."
end

sgs.ai_skill_invoke.siyi = function(self, data)
    local use = data:toCardUse()
	if use.card:isKindOf("AOE") then
		return #self.friends_noself > 0
    elseif use.card:isKindOf("GlobalEffect") then
		return #self.enemies > 0
	else
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if (use.to:contains(p) or self.room:isProhibited(self.player, p, use.card)) then continue end
			if (use.card:targetFilter(sgs.PlayerList(), p, self.player) and self:isEnemy(p)) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@siyi"]=function(self,prompt)
    self:updatePlayers()
    if prompt == "#siyi1" then
	    self:sort(self.friends_noself, "hp")
		local selectset = {}
	    for _, friend in ipairs(self.friends_noself) do
		    if friend:hasFlag("siyitarget") then
				table.insert(selectset, friend:objectName())
				if #selectset >= self.player:getEquips():length() then break end
			end
	    end
		if #selectset > 0 then
		    return ("#siyi:.:->%s"):format(table.concat(selectset,"+"))
		else
		    return "."
		end
	elseif prompt == "#siyi2" then
	    self:sort(self.enemies, "hp")
		local selectset = {}
	    for _, enemy in ipairs(self.enemies) do
		    if enemy:hasFlag("siyitarget") then
				table.insert(selectset, enemy:objectName())
				if #selectset >= self.player:getEquips():length() then break end
			end
	    end
		if #selectset > 0 then
		    return ("#siyi:.:->%s"):format(table.concat(selectset,"+"))
		else
		    return "."
		end
	end
    return "."
end

--新安洲
sgs.ai_view_as.xiaya = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() then
		return ("jink:xiaya[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.zaishi = function(self, data)
	return self:getSuitNum("red",false,self.player) < 2
end

sgs.ai_skill_invoke.wangling = function(self, data)
    local damage = data:toDamage()
	
	local guard = 0
	if self:getCardsNum("Guard") > 0 and damage.card and damage.card:isKindOf("Shoot") and damage.card:objectName() ~= "pierce_shoot" then
		guard = 1
	end
	
	return self.player:getHp() <= damage.damage and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + guard) < (damage.damage - self.player:getHp() + 1)
		and ((not damage.from) or (damage.from and self:isEnemy(damage.from)))
end

sgs.ai_skill_choice.wangling = function(self, choices, data)
	choices = choices:split("+")
	if table.contains(choices, "zaishi") then
		if self:getSuitNum("red",true,self.player) > 1 then
			return "zaishi"
		end
	end
	if table.contains(choices, "xiaya") then
		if self:getSuitNum("red",true,self.player) < 1 then
			return "xiaya"
		end
	end
	return choices[1]
end

--里歇尔
sgs.ai_skill_invoke.duilie = function(self, data)
    local promptlist = data:toString():split(":")
	local effect = promptlist[1]
	local enemy = findPlayerByObjectName(self.room, promptlist[2])
	if effect == "throw" then
	    return enemy and self:isEnemy(enemy)
	else
	    return true
	end
end

sgs.ai_skill_invoke.zhihui = function(self, data)
    local friend = 0
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if self:isFriend(p) and self.player:inMyAttackRange(p) then
		    friend = friend + 1
		end
	end
    return friend > 0
end

sgs.ai_skill_playerchosen.zhihui = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
end

--德尔塔+
local xiezhan_skill = {}
xiezhan_skill.name = "xiezhan"
table.insert(sgs.ai_skills, xiezhan_skill)
xiezhan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isNude() then return false end
	return sgs.Card_Parse("#xiezhan:.:")
end

sgs.ai_skill_use_func["#xiezhan"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		for _,friend in ipairs(self.friends_noself) do
			local card_id = card:getId()
			local range_fix = 0
			if self.player:getWeapon() and self.player:getWeapon():getId() == card_id then
				local weapon = self.player:getWeapon():getRealCard():toWeapon()
				range_fix = range_fix + weapon:getRange() - 1
			elseif self.player:getOffensiveHorse() and self.player:getOffensiveHorse():getId() == card_id then
				range_fix = range_fix + 1
			end
			if ((card:isKindOf("Weapon") and friend:getWeapon() == nil) or
				(card:isKindOf("Armor") and friend:getArmor() == nil) or
				(card:isKindOf("DefensiveHorse") and friend:getDefensiveHorse() == nil) or
				(card:isKindOf("OffensiveHorse") and friend:getOffensiveHorse() == nil) or
				(card:isKindOf("Treasure") and friend:getTreasure() == nil)) and
				self.player:distanceTo(friend, range_fix) <= self.player:getAttackRange() and sgs.Slash_IsAvailable(friend) and hasEquipArea(friend, card:getSubtype()) then
				use.card = sgs.Card_Parse("#xiezhan:"..card_id..":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_skill_playerchosen["xiezhan"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
end

sgs.ai_use_value["xiezhan"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["xiezhan"] = sgs.ai_use_priority.Slash

local tupo_skill = {}
tupo_skill.name = "tupo"
table.insert(sgs.ai_skills, tupo_skill)
tupo_skill.getTurnUseCard = function(self, inclusive)
	local card = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
	if card:isAvailable(self.player) and (not self.player:hasFlag("tupo_used")) and self.player:getHp() > 1 then
		local card_str = ("collateral:tupo[no_suit:0]=.")
		local card = sgs.Card_Parse(card_str)
		return card
	end
end

sgs.ai_skill_playerchosen["tupo"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
end

sgs.ai_use_value["tupo"] = sgs.ai_use_value.Collateral
sgs.ai_use_priority["tupo"] = sgs.ai_use_priority.Collateral

--黑独角兽
sgs.ai_skill_invoke.mengshi = function(self, data)
    local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isEnemy(p) then
			return not (p:isWounded() and p:getArmor() and p:getEquips():length() == 1 and p:getArmor():getClassName() == "SilverLion")
		elseif self:isFriend(p) then
			return (p:isWounded() and p:getArmor() and p:getArmor():getClassName() == "SilverLion")
		end
	end
	return false
end

sgs.ai_skill_cardchosen["mengshi"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	for i=1, #cards, 1 do
	    if self:isEnemy(who) then
			if not (who:isWounded() and cards[i]:getClassName() == "SilverLion") then
				return cards[i]
			end
		elseif self:isFriend(who) then
		    if (who:isWounded() and cards[i]:getClassName() == "SilverLion") then
				return cards[i]
			end
		end
	end
	return nil
end

local NTD2_skill = {}
NTD2_skill.name = "ntdtwo"
table.insert(sgs.ai_skills,NTD2_skill)
NTD2_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@NTD2") > 0 and self.player:isWounded() and self:getSuitNum("black", false, self.player) > 0 then
		local card_str = ("#ntdtwo:%d:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#ntdtwo"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["ntdtwo"] = 5
sgs.ai_use_priority["ntdtwo"] = 9.2

sgs.ai_skill_use["@@ntdtwo"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "handcard")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
	    if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0))) then
		    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, friend:objectName())
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0))) then
		    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, enemy:objectName())
		end
	end
	if #targets > 0 then
	    return ("%s:ntdtwo[no_suit:0]=.->%s"):format("dismantlement", table.concat(targets,"+"))
	else
	    return "."
	end
	return "."
end

sgs.NTD2_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.NTD2(to, card)
	return card:isBlack()
end

sgs.ai_skill_invoke.baosang = function(self, data)
	local use = data:toCardUse()
    if self:getSuitNum("black", false, self.player) > 0 and self:isEnemy(use.from) then
		for _,enemy in ipairs(self.enemies) do
			return ((not enemy:containsTrick("indulgence")) and
				(not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)))) or
				((not enemy:containsTrick("supply_shortage")) and
				(not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuit, 0))))
		end
	end
	return false
end

sgs.ai_skill_choice.baosang = function(self, choices, data)
	for _,enemy in ipairs(self.enemies) do
		if (not enemy:containsTrick("indulgence")) and
			(not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0))) then
			return "indulgence"
		end
	end
	return "supply_shortage"
end

sgs.ai_skill_use["@@baosang"] = function(self, prompt)
    self:updatePlayers()
	local pattern = prompt:split(":")[2]
	local targets = {}
	if pattern == "indulgence" then
		for _, enemy in ipairs(self.enemies) do
			if (not enemy:containsTrick(pattern)) and
				(not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0))) then
				if #targets >= 1 then break end
				table.insert(targets, enemy:objectName())
			end
		end
		if #targets == 1 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			for _,card in ipairs(cards) do
				if card:isBlack() then
					return ("%s:baosang[%s:%s]=%d->%s"):format(pattern, card:getSuitString(), card:getNumberString(), card:getEffectiveId(), targets[1])
				end
			end
		else
			return "."
		end
	else
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if (not enemy:containsTrick(pattern)) and
				(not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0))) and
				self.player:distanceTo(enemy) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)) then
				if #targets >= 1 then break end
				table.insert(targets, enemy:objectName())
			end
		end
		if #targets == 1 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			for _,card in ipairs(cards) do
				if card:isBlack() then
					return ("%s:baosang[%s:%s]=%d->%s"):format(pattern, card:getSuitString(), card:getNumberString(), card:getEffectiveId(), targets[1])
				end
			end
		else
			return "."
		end
	end
	return "."
end

--黑独角兽N
--[[sgs.ai_skill_use["@@shenshi"]=function(self,prompt)
    self:updatePlayers()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if #cards <= 1 then return false end
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	if #self.enemies > 0 and self.enemies[1]:getMaxCards() - self.enemies[1]:getHandcardNum() >= 2 then
		for _,card in ipairs(cards) do
			if card:isKindOf("Jink") or card:isKindOf("Nullification") then
				return ("#shenshi:%d:->%s"):format(card:getId(), self.enemies[1]:objectName())
			end
		end
	end
    if #self.friends_noself > 0 and (not self.friends_noself[1]:containsTrick("indulgence")) then
		local ids = {}
		local rand = math.random(1, 3)
		for _,card in ipairs(cards) do
			if (self.friends_noself[1]:isWounded() and card:isKindOf("Peach")) or (card:isKindOf("TrickCard") and not card:isKindOf("Nullification"))
				or (((card:isKindOf("Weapon") and self.friends_noself[1]:getWeapon() == nil) or
				(card:isKindOf("Armor") and self.friends_noself[1]:getArmor() == nil) or
				(card:isKindOf("DefensiveHorse") and self.friends_noself[1]:getDefensiveHorse() == nil) or
				(card:isKindOf("OffensiveHorse") and self.friends_noself[1]:getOffensiveHorse() == nil) or
				(card:isKindOf("Treasure") and self.friends_noself[1]:getTreasure() == nil)) and hasEquipArea(self.friends_noself[1], card:getSubtype())) then
				table.insert(ids, card:getId())
				if #ids >= rand then break end
			end
		end
		if #ids > 0 then
		    return ("#shenshi:%s:->%s"):format(table.concat(ids, "+"), self.friends_noself[1]:objectName())
		end
    end
    return "."
end]]

sgs.ai_skill_invoke.shenshi = function(self, data)
	local use = data:toCardUse()
	if use.from:objectName() == self.player:objectName() then
		local card = sgs.Sanguosha:cloneCard("duel")
		card:addSubcard(use.card)
		for _,p in sgs.qlist(use.to) do
			if self.player:getMark("@xuanguang") > 0 and (use.card:isKindOf("ThunderSlash") or use.card:isKindOf("FireSlash"))
				and p:getEquips():isEmpty() then
				return true
			end
			if self:hasHeavySlashDamage(self.player, use.card, p) then 
				return false
			end
			if (not self:hasTrickEffective(card, p, use.from)) and (self:slashIsEffective(use.card, p, use.from, false)) then
				return false
			end
		end
		return true
	else
		if self.player:getMark("@xuanguang") > 0 and (use.card:isKindOf("ThunderSlash") or use.card:isKindOf("FireSlash"))
			and self.player:getEquips():isEmpty() then
			return false
		end
		local card = sgs.Sanguosha:cloneCard("duel")
		card:addSubcard(use.card)
		if self:hasTrickEffective(card, use.from, self.player) and (self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") == 0
			or self:getCardsNum("Nullification") > 0 or self:hasHeavySlashDamage(use.from, use.card, self.player)) then
			return true
		end
	end
end

local NTD3_skill = {}
NTD3_skill.name = "ntdthree"
table.insert(sgs.ai_skills,NTD3_skill)
NTD3_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@NTD3") > 0 and self.player:isWounded() and self:getSuitNum("black", false, self.player) > 0 then
		local card_str = ("#ntdthree:%d:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#ntdthree"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["ntdthree"] = 5
sgs.ai_use_priority["ntdthree"] = 9.2

sgs.ai_skill_use["@@ntdthree"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "handcard")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
	    if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and (not friend:isProhibited(friend, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0))) then
		    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, friend:objectName())
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if (not enemy:isAllNude()) and (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0))) then
		    if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, enemy:objectName())
		end
	end
	if #targets > 0 then
	    return ("%s:ntdthree[no_suit:0]=.->%s"):format("dismantlement", table.concat(targets,"+"))
	else
	    return "."
	end
	return "."
end

sgs.NTD3_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.NTD3(to, card)
	return card:isBlack()
end

sgs.ai_skill_invoke.zuzhou = function(self, data)
	local use = data:toCardUse()
    if self:getSuitNum("black", false, self.player) > 0 and self:isEnemy(use.from) then
		self:sort(self.enemies, "defenseSlash")
		for _,enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0), enemy) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@zuzhou"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0)
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy) then
			if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash) then break end
			table.insert(targets, enemy:objectName())
		end
	end
	if #targets > 0 then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if card:isBlack() and not (self.player:getHp() == 1 and card:isKindOf("Analeptic")) then
				return ("slash:zuzhou[%s:%s]=%d->%s"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId(), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end

--EX-S
local fanshe_skill = {}
fanshe_skill.name = "fanshe"
table.insert(sgs.ai_skills,fanshe_skill)
fanshe_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:hasUsed("#fanshe") and #self.friends_noself > 0 then
		for _,f in ipairs(self.friends) do
			for _,e in ipairs(self.enemies) do
				if f:inMyAttackRange(e) or f:distanceTo(e) == 1 then
					local card_str = ("#fanshe:%d:")
					return sgs.Card_Parse(card_str)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#fanshe"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen.fanshe = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then
			for _,e in ipairs(self.enemies) do
				if target:inMyAttackRange(e) or target:distanceTo(e) == 1 then
					return target
				end
			end
			return target
		end
	end
end

sgs.ai_skill_use["@@fanshe"] = function(self, prompt)
	return ("#fanshe:.:")
end

sgs.ai_use_value["fanshe"] = 5
sgs.ai_use_priority["fanshe"] = 5

sgs.ai_skill_invoke.ALICE = function(self, data)
	return true
end

--百式
local luashipo_skill = {}
luashipo_skill.name = "luashipo"
table.insert(sgs.ai_skills,luashipo_skill)
luashipo_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getPile("lizhan"):length() < 3 and (not self.player:isKongcheng()) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards,true)
		for _,card in ipairs(cards) do
			if card:isKindOf("TrickCard") and (not card:isKindOf("Nullification")) and (not card:isKindOf("Snatch")) and
				(not card:isKindOf("Dismantlement")) and (not card:isKindOf("ExNihilo")) and (not card:isKindOf("Indulgence")) then
				local card_str = ("#luashipo:"..card:getId()..":")
				return sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#luashipo"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["luashipo"] = 4
sgs.ai_use_priority["luashipo"] = 9.2

sgs.ai_view_as.luashipo = function(card, player, card_place)
	if player:getPile("lizhan"):isEmpty() then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "lizhan" then
		return ("nullification:luashipo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local leishe_skill = {}
leishe_skill.name= "leishe"
table.insert(sgs.ai_skills,leishe_skill)
leishe_skill.getTurnUseCard=function(self)
	if self.player:getMark("@leishe") >= 3 and (not self.player:hasUsed("#leishe")) then
		return sgs.Card_Parse("#leishe:.:")
	end
end

sgs.ai_skill_use_func["#leishe"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			use.card = sgs.Card_Parse("#leishe:.:")
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["leishe"] = 2.5
sgs.ai_use_priority["leishe"] = sgs.ai_use_value.Slash - 0.1
sgs.dynamic_value.damage_card["leishe"] = true

sgs.ai_skill_cardask["@@shanguang"] = function(self, data)
	local source = data:toPlayer()
	local player = self.player

	if self:needToThrowArmor() then
		return "$" .. player:getArmor():getEffectiveId()
	end

	if not self:damageIsEffective(player, sgs.DamageStruct_Normal, source) then
		return "."
	end
	if self:getDamagedEffects(self.player, source) then
		return "."
	end
	if self:needToLoseHp(player, source) then
		return "."
	end

	local card_id
	if self:hasSkills(sgs.lose_equip_skill, player) then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getArmor() then card_id = player:getArmor():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then
		for _, card in sgs.qlist(player:getCards("h")) do
			if card:isKindOf("EquipCard") then
				card_id = card:getEffectiveId()
				break
			end
		end
	end

	if not card_id then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif self:isWeak(player) and player:getArmor() then card_id = player:getArmor():getId()
		elseif self:isWeak(player) and player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then return "." else return "$" .. card_id end
end

--闪光
local shanguang_skill = {}
shanguang_skill.name = "shanguang"
table.insert(sgs.ai_skills, shanguang_skill)
shanguang_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:usedTimes("#shanguang") <= self.player:getMark("@supermode")) and ((self.player:getHp() >= 3 and self:getCardsNum("Jink") > 0)
		or (self.player:getHp() <= 2 and self:getCardsNum("Jink") > 1) or (self.player:getMark("@supermode") > 0 and self:getCardsNum("Weapon") > 0)) then
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				return sgs.Card_Parse("#shanguang:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#shanguang"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then
			local ids = {}
			for _,card in sgs.qlist(self.player:getCards("he")) do
				local id = card:getId()
				if card:isKindOf("Jink") then
					table.insert(ids, id)
				elseif self.player:getMark("@supermode") > 0 and card:isKindOf("Weapon") then
					local rangefix = 0
					if self.player:getWeapon() and self.player:getWeapon():getId() == id then
						local weapon = self.player:getWeapon():getRealCard():toWeapon()
						rangefix = rangefix + weapon:getRange() - self.player:getAttackRange(false)
					end
					if self.player:inMyAttackRange(enemy, rangefix) then
						table.insert(ids, id)
					end
				end
			end
			if #ids == 0 then return end
			use.card = sgs.Card_Parse("#shanguang:"..ids[math.random(#ids)]..":")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value["shanguang"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shanguang"] = sgs.ai_use_priority.Slash + 1

sgs.ai_skill_invoke.jingxin = function(self, data)
	if (self.player:getHp() == 1 or (self:getCardsNum("Jink") + self:getCardsNum("Weapon")) > 1) and
		#self.enemies == 1 and (self.enemies[1]:getHp() == 1 or (self.enemies[1]:getHp() > 1 and self.enemies[1]:getCardCount() <= 1)) then
		return false
	end
	return true
end

sgs.ai_skill_invoke.chaojimoshi = function(self, data)
	local can_attack = false
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then
			can_attack = true
			break
		end
	end
	if can_attack and self:getCardsNum("Jink") > self.player:getMaxCards() then return false end
	return true
end

--飞翼零式
local wzpoint_skill = {}
wzpoint_skill.name = "wzpoint"
table.insert(sgs.ai_skills,wzpoint_skill)
wzpoint_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@point") > 3 and (self.player:getHandcardNum() <= 2 or self.player:getHp() == 1) then
		local card_str = ("#wzpoint:%d:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#wzpoint"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.benefit["wzpoint"] = true

sgs.ai_use_value["wzpoint"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["wzpoint"] = sgs.ai_use_priority.Slash + 0.1

local liuxing_skill = {}
liuxing_skill.name = "liuxing"
table.insert(sgs.ai_skills, liuxing_skill)
liuxing_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then table.insert(newcards, card) end
	end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	if newcards[1]:isBlack() and newcards[2]:isBlack() then
		local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack)
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash")

		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
				and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				self:sortByUseValue(blackcards, true)
				self:sortByUseValue(redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = redcard:getEffectiveId()
					card_id2 = othercard:getEffectiveId()
					break
				end
			end
		end
	end

	local card_str = ("slash:liuxing[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)
	local slash = sgs.Card_Parse(card_str)
	return slash
end

sgs.ai_view_as.liuxing = function(card, player, card_place)
	local usereason = sgs.Sanguosha:getCurrentCardUseReason()
	if usereason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
	if card_place ~= sgs.Player_PlaceEquip and player:getHandcardNum() >= 2 then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		local id1
		local id2
		for i = 0, 1, 1 do
			local id = player:handCards():at(i)
			slash:addSubcard(id)
			if id1 == nil then
				id1 = id
			else
				id2 = id
			end
		end
		local suit = slash:getSuitString()
		local number = slash:getNumberString()
		return ("slash:liuxing[%s:%s]=%d+%d"):format(suit, number, id1, id2)
	end
end

sgs.ai_use_value["liuxing"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["liuxing"] = sgs.ai_use_priority.Slash

sgs.ai_skill_invoke.lingshi = function(self, data)
	return true
end

--艾比安
sgs.ai_skill_invoke.mosu = function(self, data)
	return true
end

sgs.ai_skill_invoke.cishi = function(self, data)
	return true
end

--飞翼零式改
local shuangpao_skill={}
shuangpao_skill.name="shuangpao"
table.insert(sgs.ai_skills,shuangpao_skill)
shuangpao_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#shuangpao") or self.player:getHp() < 2 then return false end
	if not willUse(self, "Slash") then return false end
	if self.player:isKongcheng() then
		if self.player:getMark("@ew_lingshi") > 0 then
			local card_str = ("#shuangpao:%d:")
			return sgs.Card_Parse(card_str)
		end
	else
		for _,enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if (not self:slashProhibit(slash, enemy, self.player)) and (self.player:canSlash(enemy, slash) or (self.player:hasSkill("feiyi")
			and self.player:getHp() < 4)) and (not self:isWeak(self.player)) and self:getCardsNum("Slash") > 0 and self:slashIsAvailable() and self.player:distanceTo(enemy) > 1 then
				local card_str = ("#shuangpao:%d:")
				return sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#shuangpao"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["shuangpao"] = sgs.ai_use_value.Analeptic
sgs.ai_use_value["shuangpao"] = sgs.ai_use_value.Analeptic

sgs.ai_skill_invoke.ew_lingshi = function(self, data)
	return true
end

--地狱死神改
sgs.ai_skill_invoke.yindun = function(self, data)
	return true
end

sgs.ai_skill_invoke.ansha = function(self, data)
	local player = self.room:getCurrent()
	return not self:isFriend(player)
end

--重武装改
local gelin_skill = {}
gelin_skill.name = "gelin"
table.insert(sgs.ai_skills, gelin_skill)
gelin_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getPile("dan"):isEmpty() or not sgs.Slash_IsAvailable(self.player) then
		return false
	end
	for i = 0, self.player:getPile("dan"):length() - 1, 1 do
		local slash = sgs.Sanguosha:getCard(self.player:getPile("dan"):at(i))
		local slash_str = ("slash:gelin[%s:%s]=%d"):format(slash:getSuitString(), slash:getNumberString(), self.player:getPile("dan"):at(i))
		local gelinslash = sgs.Card_Parse(slash_str)
		for _,enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, gelinslash) and self:slashIsEffective(gelinslash, enemy) then
				local suit = slash:getSuitString()
				local number = slash:getNumberString()
				local card_id = slash:getEffectiveId()
				local card_str = ("slash:gelin[%s:%s]=%d"):format(suit, number, card_id)
				local slash = sgs.Card_Parse(card_str)
				assert(slash)
				return slash
			end
		end
	end
end

sgs.ai_view_as.gelin = function(card, player, card_place)
	if player:getPile("dan"):isEmpty() then return false end
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if card_place == sgs.Player_PlaceSpecial then
		if pattern == "jink" then
			if player:getPile("dan"):length() < 2 then return false end
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
			local id1
			local id2
			for i = 0, 1, 1 do
				local id = player:getPile("dan"):at(i)
				jink:addSubcard(id)
				if id1 == nil then
					id1 = id
				else
					id2 = id
				end
			end
			local suit = jink:getSuitString()
			local number = jink:getNumberString()
			if player:getPileName(id1) == "dan" and player:getPileName(id2) == "dan" then
				return ("jink:gelin[%s:%s]=%d+%d"):format(suit, number, id1, id2)
			end
		else
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			if player:getPileName(card_id) == "dan" then
				return ("slash:gelin[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end

sgs.ai_use_value["gelin"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["gelin"] = sgs.ai_use_priority.Slash

--沙漠改
sgs.ai_skill_invoke.shuanglian = function(self, data)
    local invoke = false
    local pattern = data:toStringList()[1]
	if pattern == "slash" then
		for _,enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				invoke = true
				break
			end
		end
	    return invoke and self:getCardsNum("Jink") > 0
	elseif pattern == "jink" then
		for _,enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) then
				invoke = true
				break
			end
		end
	    return invoke
	end
	return false
end

sgs.ai_skill_playerchosen.shuanglian = function(self, targets)
	for _, target in sgs.qlist(targets) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if self:isEnemy(target) and ((not self.player:hasFlag("shuanglian_jink")) or self:slashIsEffective(slash, target)) then
			return target
		end
	end
end

sgs.ai_skill_invoke.zaizhan = function(self, data)
    if #self.friends_noself > 0 then
		return self.player:getLostHp() > 1
	else
	    return self.player:getHp() < 2 or self.player:getHandcardNum() < 2
	end
	return false
end

sgs.ai_skill_use["@@zaizhan"]=function(self,prompt)
    self:updatePlayers()
    if #self.friends_noself > 0 then
	    self:sort(self.friends, "handcard")
		local selectset = {}
	    for _, friend in ipairs(self.friends) do
			table.insert(selectset, friend:objectName())
			if #selectset >= self.player:getLostHp() then break end
	    end
		if #selectset > 0 then
		    return ("#zaizhan:.:->%s"):format(table.concat(selectset,"+"))
		else
		    return "."
		end
	else
		return ("#zaizhan:.:->%s"):format(self.player:objectName())
    end
    return "."
end

--双头龙改
local shuanglong_skill={}
shuanglong_skill.name="shuanglong"
table.insert(sgs.ai_skills,shuanglong_skill)
shuanglong_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getHandcardNum() < 2 or self.player:hasFlag("shuanglong_success") or self.player:hasFlag("shuanglong_failed") then return false end
	return sgs.Card_Parse("#shuanglong:.:")
end

sgs.ai_skill_use_func["#shuanglong"]=function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
	    if not enemy:isKongcheng() then
			for _, card in ipairs(cards) do
				if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink") then
					use.card = sgs.Card_Parse("#shuanglong:"..card:getId()..":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["shuanglong1"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
end

sgs.ai_skill_playerchosen["shuanglong2"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_cardchosen["shuanglong"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	for i=1,#cards,1 do
		if (cards[i]:isKindOf("Weapon") and self.player:getWeapon() == nil) or
	    (cards[i]:isKindOf("Armor") and self.player:getArmor() == nil) or
		(cards[i]:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() == nil) or
		(cards[i]:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() == nil) then
			return cards[i]
		end
	end
	return nil
end

sgs.ai_use_value["shuanglong"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shuanglong"] = sgs.ai_use_priority.Slash + 1

--DX
local weibo_skill={}
weibo_skill.name="weibo"
table.insert(sgs.ai_skills,weibo_skill)
weibo_skill.getTurnUseCard=function(self,inclusive)
	if not willUse(self, "Slash") then return false end
	local n = 0
    for _,enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) then
			n = n + 1
		end
	end
	if (n == 1 and self.player:getMark("@point") > 0) or (n > 1 and self.player:getMark("@point") > 2) and self:getCardsNum("Slash") > 0 and sgs.Slash_IsAvailable(self.player) then
		local card_str = ("#weibo:%d:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#weibo"]=function(card, use, self)
	use.card = card
end

sgs.dynamic_value.benefit["weibo"] = true

sgs.ai_use_value["weibo"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["weibo"] = sgs.ai_use_priority.Analeptic

local weixing_skill={}
weixing_skill.name="weixing"
table.insert(sgs.ai_skills,weixing_skill)
weixing_skill.getTurnUseCard=function(self,inclusive)
    if self.player:hasUsed("#weixing") then return false end
	if not willUse(self, "Slash") then return false end
	local n = 0
    for _,enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) then
			n = n + 1
		end
	end
	if (n == 1 and self.player:getMark("@point") > 1) or (n > 1 and self.player:getMark("@point") > 3) and self:getCardsNum("Slash") > 0 and sgs.Slash_IsAvailable(self.player) then
		local card_str = ("#weixing:%d:")
		return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#weixing"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.benefit["weixing"] = true

sgs.ai_use_value["weixing"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["weixing"] = sgs.ai_use_priority.Analeptic

sgs.ai_skill_invoke.difa = function(self, data)
	return true
end

sgs.ai_skill_use["@@difa"] = function(self, prompt, method)
    local judge = self.player:getTag("difa"):toJudge()
    local ids = self.player:getPile("difa")
    if self.room:getMode():find("_mini_46") and not judge:isGood() then return "#difa:"..ids:first()..":" end
    if self:needRetrial(judge) then
        local cards = {}
        for _,id in sgs.qlist(ids) do
            table.insert(cards,sgs.Sanguosha:getCard(id))
        end
        local card_id = self:getRetrialCardId(cards, judge)
        if card_id ~= -1 then
            return "#difa:"..card_id..":"
        end
    end
    return "."    
end

--米基尔基恩
sgs.ai_skill_invoke.laobing = function(self, data)
	return true
end

sgs.ai_skill_invoke.baopo = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.to) then
	    return not (damage.to:isWounded() and damage.to:getArmor() and damage.to:getEquips():length() == 1 and damage.to:getArmor():getClassName() == "SilverLion")
	elseif self:isFriend(damage.to) then
	    return (damage.to:isWounded() and damage.to:getArmor() and damage.to:getArmor():getClassName() == "SilverLion")
	end
	return false
end

sgs.ai_skill_cardchosen["baopo"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	for i=1,#cards,1 do
	    if self:isEnemy(who) then
			if not (who:isWounded() and cards[i]:getClassName() == "SilverLion") then
				return cards[i]
			end
		elseif self:isFriend(who) then
		    if (who:isWounded() and cards[i]:getClassName() == "SilverLion") then
				return cards[i]
			end
		end
	end
	return nil
end

--突击
sgs.ai_skill_invoke.huanzhuang = function(self, data)
    local promptlist = data:toString():split(":")
	local effect = promptlist[1]
	local enemy = findPlayerByObjectName(self.room, promptlist[2])
	if effect == "throw" then
	    return enemy and self:isEnemy(enemy)
	else
	    if willUse(self, "Slash") or self.player:getHandcardNum() > 2 then
			return true
		end
	end
	return false
end

--[[sgs.ai_skill_invoke.xiangzhuan = function(self, data)
	return true
end]]

--神盾
local jiechi_skill = {}
jiechi_skill.name = "jiechi"
table.insert(sgs.ai_skills, jiechi_skill)
jiechi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getHandcardNum() < 2 then return false end
	for _,enemy in ipairs(self.enemies) do
		if not enemy:getEquips():isEmpty() then
			return sgs.Card_Parse("#jiechi:.:")
		end
	end
end

sgs.ai_skill_use_func["#jiechi"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,card in ipairs(cards) do
		if not (card:isKindOf("Peach") or card:isKindOf("ExNihilo")) then
			use.card = sgs.Card_Parse("#jiechi:"..card:getId()..":")
			if use.to then
				for _,enemy in ipairs(self.enemies) do
					if not enemy:getEquips():isEmpty() then
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value["jiechi"] = sgs.ai_use_value.Dismantlement
sgs.ai_use_priority["jiechi"] = sgs.ai_use_priority.Dismantlement

local juexin_skill = {}
juexin_skill.name = "juexin"
table.insert(sgs.ai_skills, juexin_skill)
juexin_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return false end
    if self.player:getMark("@juexin") > 0 and ((self.player:getHp() < 2 and self.room:alivePlayerCount() > 2 and not self.player:isLord()) or
		(self.player:getHp() == 2 and self.player:isKongcheng() and #self.enemies > 1) or
		(self.room:alivePlayerCount() == 2 and ((self.enemies[1]:getHp() == 2 and self.enemies[1]:isKongcheng()) or
		(self.enemies[1]:getHp() == 1 and self.enemies[1]:getHandcardNum() < 2)))) then
		return sgs.Card_Parse("#juexin:.:")
	end
end

sgs.ai_skill_use_func["#juexin"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	use.card = card
	if use.to then
		use.to:append(self.enemies[1])
		return
	end
end

sgs.ai_use_value["juexin"] = 3
sgs.ai_use_priority["juexin"] = 0.1

--暴风
local shuangqiang_skill = {}
shuangqiang_skill.name = "shuangqiang"
table.insert(sgs.ai_skills, shuangqiang_skill)
shuangqiang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPhase() ~= sgs.Player_Play then return false end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if (isCard("EquipCard", card, self.player) or isCard("TrickCard", card, self.player)) and not (isCard("ExNihilo", card, self.player)) then table.insert(newcards, card) end
	end
	if #newcards < 1 then return end

	local card_id1 = newcards[1]:getEffectiveId()

	if newcards[1]:isBlack() then
		local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack)
		local nosuit_slash = sgs.Sanguosha:cloneCard("slash")

		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
				and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				self:sortByUseValue(blackcards, true)
				self:sortByUseValue(redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1]
				if redcard and othercard then
					card_id1 = redcard:getEffectiveId()
					break
				end
			end
		end
	end

	local card_str = ("slash:shuangqiang[%s:%s]=%d"):format("to_be_decided", 0, card_id1)
	local slash = sgs.Card_Parse(card_str)
	return slash
end

sgs.ai_use_value["shuangqiang"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["shuangqiang"] = sgs.ai_use_priority.Slash + 0.1

local zuzhuang_skill = {}
zuzhuang_skill.name = "zuzhuang"
table.insert(sgs.ai_skills, zuzhuang_skill)
zuzhuang_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local equipcards = {}
	local trickcards = {}
	for _, card in ipairs(cards) do
		if isCard("EquipCard", card, self.player) then table.insert(equipcards, card)
		elseif isCard("TrickCard", card, self.player) and not (isCard("ExNihilo", card, self.player)) then table.insert(trickcards, card) end
	end
	if #equipcards < 1 or #trickcards < 1 then return end

	local card_id1 = equipcards[1]:getEffectiveId()
	local card_id2 = trickcards[1]:getEffectiveId()

	local card_str = ("slash:zuzhuang[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)
	local slash = sgs.Card_Parse(card_str)
	return slash
end

sgs.ai_use_value["zuzhuang"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["zuzhuang"] = sgs.ai_use_priority.Slash + 0.2

sgs.ai_skill_choice.zuzhuang = function(self, choices, data)
	local choice = choices:split("+")
	return choice[math.random(1, #choice)]
end

--决斗AS
local sijue_skill={}
sijue_skill.name="sijue"
table.insert(sgs.ai_skills,sijue_skill)
sijue_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	local card
	for _,acard in ipairs(cards)  do
		if (acard:isBlack()) and (acard:isKindOf("BasicCard")) then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:sijue[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_use_value["sijue"] = sgs.ai_use_value.Duel
sgs.ai_use_priority["sijue"] = sgs.ai_use_priority.Duel

sgs.ai_skill_invoke.pojia = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.from)
end

--迅雷
sgs.ai_skill_invoke.yinxian = function(self, data)
	return true
end

sgs.ai_skill_invoke.zhuanjin = function(self, data)
	return self:isFriend(data:toDying().who)
end

--自由
sgs.ai_skill_invoke.helie = function(self, data)
	local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:isKindOf("Peach") or card:isKindOf("ExNihilo") then
			n = n + 1
		end
	end
	return n == 0 and self.player:getHandcardNum() < self.player:getMaxHp()
end

sgs.ai_skill_invoke.jiaoxie = function(self, data)
	local dying = data:toDying()
	local target
	if dying.damage.from:objectName() == self.player:objectName() then
		target = dying.who
	elseif dying.who:objectName() == self.player:objectName() then
		target = dying.damage.from
	end
	if target == nil then return false end
	return self:isEnemy(target)
end

sgs.ai_skill_choice.jiaoxie = function(self, choices, data)
	local choice = choices:split("+")
	return choice[math.random(1, #choice)]
end

local qishe_skill = {}
qishe_skill.name = "qishe"
table.insert(sgs.ai_skills, qishe_skill)
qishe_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return false end
	if (#self.enemies > 1 or (#self.enemies == 1 and (self:getCardsNum("Slash") == 0 or self.player:distanceTo(self.enemies[1]) > self.player:getAttackRange()))) and
		(self.player:hasSkill("helie") or self.player:getHandcardNum() < 3) then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		local ids = {}
		for _,card in ipairs(cards) do
			table.insert(ids, card:getId())
		end
		local card_str = ("fire_slash:qishe[%s:%s]=%s"):format("to_be_decided", 0, table.concat(ids, "+"))
		local card = sgs.Card_Parse(card_str)
		return card
	end
end

sgs.ai_use_value["qishe"] = sgs.ai_use_value.FireSlash
sgs.ai_use_priority["qishe"] = sgs.ai_use_priority.Slash - 0.5

--正义
local shouwang_skill = {}
shouwang_skill.name = "shouwang"
table.insert(sgs.ai_skills, shouwang_skill)
shouwang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMaxHp() > 0 and self.player:getMark("Global_PreventPeach") == 0 and
		(self.player:getLostHp() > 1 or (self.player:getMaxHp() == 2 and self.player:getHp() == 1 and self.player:hasSkill("shouwang"))) then
		local card_str = ("peach:shouwang[no_suit:0]=.")
		local card = sgs.Card_Parse(card_str)
		return card
	end
end

sgs.ai_view_as.shouwang = function(card, player, card_place)
	if player:getMaxHp() > 0 and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:shouwang[no_suit:0]=.")
	end
end

sgs.ai_use_value["shouwang"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["shouwang"] = sgs.ai_use_priority.Peach - 0.5

sgs.ai_skill_invoke.huiwu = function(self, data)
	if self:getCardsNum("Slash") > 0 and sgs.Slash_IsAvailable(self.player) then return false end
	return self.player:getHandcardNum() == 1 or self.player:hasSkill("helie")
end

--瘟神禁断猎杀
local wenshen_skill = {} --感谢虫妹
wenshen_skill.name = "wenshen"
table.insert(sgs.ai_skills, wenshen_skill)
wenshen_skill.getTurnUseCard = function(self)
	if self:getCardsNum("EquipCard") == 0 then return false end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	if (self:getCardsNum("EquipCard") < 2 and self:getCardsNum("Slash") == 0) or not sgs.Analeptic_IsAvailable(self.player) then
		local newcards = {}
		for _, card in ipairs(cards) do
			if isCard("EquipCard", card, self.player) and (not card:hasFlag("using")) then table.insert(newcards, card) end
		end
		if #newcards < 1 then return end

		local card_id1 = newcards[1]:getEffectiveId()

		if newcards[1]:isBlack() then
			local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack)
			local nosuit_slash = sgs.Sanguosha:cloneCard("slash")

			self:sort(self.enemies, "defenseSlash")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
					and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
					local redcards, blackcards = {}, {}
					for _, acard in ipairs(newcards) do
						if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
					end
					if #redcards == 0 then break end

					local redcard, othercard

					self:sortByUseValue(blackcards, true)
					self:sortByUseValue(redcards, true)
					redcard = redcards[1]

					othercard = #blackcards > 0 and blackcards[1]
					if redcard and othercard then
						card_id1 = redcard:getEffectiveId()
						break
					end
				end
			end
		end
		local scard = sgs.Sanguosha:getCard(card_id1)
		local card_str = ("slash:wenshen[%s:%s]=%d"):format(scard:getSuitString(), scard:getNumberString(), card_id1)
		local slash = sgs.Card_Parse(card_str)
		return slash
	else
		local card
		for _,acard in ipairs(cards)  do
			if isCard("EquipCard", acard, self.player) then
				card = acard
				break
			end
		end

		if not card then return nil end
		local card_str = ("analeptic:wenshen[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
		local analeptic = sgs.Card_Parse(card_str)

		if sgs.Analeptic_IsAvailable(self.player, analeptic) and willUse(self, "Slash") then
			assert(analeptic)
			return analeptic
		end
	end
end

sgs.ai_use_value["wenshen"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["wenshen"] = sgs.ai_use_priority.Analeptic - 0.1

sgs.ai_view_as.wenshen = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local usereason = sgs.Sanguosha:getCurrentCardUseReason()
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if card:isKindOf("EquipCard") and (not card:hasFlag("using")) then
		if pattern == "slash" and usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return ("slash:wenshen[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("analeptic:wenshen[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.wenshen_keep_value = {
	EquipCard = sgs.ai_keep_value.Analeptic
}

sgs.ai_skill_playerchosen.jinduan = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	return nil
end

sgs.ai_skill_invoke.liesha = function(self, data)
	return true
end

--天意
sgs.ai_skill_playerchosen.longqi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	for _,target in ipairs(targets) do
		if self:isEnemy(target) and (not target:isKongcheng()) then
			return target
		end
	end
	return nil
end

sgs.ai_skill_cardchosen["longqi"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getHandcards())
	local cn = self.player:getMark("longqi_ai")
	local sides = {}
	if cn > 1 then table.insert(sides, cn - 1) end
	if cn < 13 then table.insert(sides, cn + 1) end
	for _,card in ipairs(cards) do
		local idn = card:getNumber()
		if table.contains(sides, idn) then
			return card
		end
	end
	for _,card in ipairs(cards) do
		local idn = card:getNumber()
		if idn == cn then
			return card
		end
	end
	return cards[math.random(#cards)]
end

--混沌深渊大地
sgs.ai_skill_use["@@hundun"] = function(self,prompt)
    self:updatePlayers()
    if #self.enemies > 0 then
	    self:sort(self.enemies, "defenseSlash")
		local selectset = {}
		for _,enemy in ipairs(self.enemies) do
			if not self:slashProhibit(sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitBlack, 0), enemy) then
				table.insert(selectset, enemy:objectName())
			end
			if #selectset >= 2 then break end
	    end
		if #selectset > 0 then
		    return ("#hundun:.:->%s"):format(table.concat(selectset,"+"))
		end
    end
    return "."
end

local dadi_skill={}
dadi_skill.name="dadi"
table.insert(sgs.ai_skills,dadi_skill)
dadi_skill.getTurnUseCard=function(self)
	if self.player:getHandcardNum() == 1 then
		local card = self.player:getHandcards():first()
		if (not isCard("ExNihilo", card, self.player)) and (not self.player:isWounded() or not isCard("Peach", card, self.player)) then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("slash:dadi[%s:%s]=%d"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			return slash
		end
	end
end

sgs.ai_view_as.dadi = function(card, player, card_place)
	local cd = player:getHandcards():first()
	if player:getHandcardNum() == 1 and (player:isWounded() or not player:faceUp()) then
		local suit = cd:getSuitString()
		local number = cd:getNumberString()
		local card_id = cd:getEffectiveId()
		return ("slash:dadi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["dadi"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["dadi"] = sgs.ai_use_priority.Slash + 1

--脉冲
sgs.ai_skill_choice.daohe = function(self, choices, data)
	choices = choices:split("+")
	if table.contains(choices, "jiying") then
		self:sort(self.enemies, "hp")
		local enemy = self.enemies[1]
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local n = 0
		if willUse(self, "Analeptic") then n = 1 end
		if willUse(self, "Slash") and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) and
			enemy:getHp() <= 1 + n then
			return "jiying"
		end
	end
	if table.contains(choices, "meiying") then
		if willUse(self, "Slash") and self:getCardsNum("Slash") > 1 then
			return "meiying"
		end
	end
	if table.contains(choices, "jianyingg") then
		return "jianyingg"
	end
	return choices[1]
end

sgs.ai_skill_invoke.jianyingg = function(self, data)
	return true
end

sgs.ai_skill_invoke.jiying = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end

--救世主
sgs.ai_skill_invoke.shanzhuan = function(self, data)
	return true
end

sgs.ai_skill_use["@@shanzhuan"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")
	local id = tonumber(prompt)
	local card = sgs.Sanguosha:getCard(id)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(card, enemy) then
			table.insert(targets, enemy:objectName())
			if (not card:isRed() and #targets == 1) or (card:isRed() and #targets == 2) then break end
		end
	end
	if #targets > 0 then
		return ("slash:shanzhuan[%s:%s]=%d->%s"):format(card:getSuitString(), card:getNumberString(), id, table.concat(targets, "+"))
	else
		return "."
	end
	return "."
end

sgs.ai_skill_invoke.zhongcheng = function(self, data)
    local damage = data:toDamage()
	return self:isEnemy(damage.from) and
	not (damage.from:getEquips():length() == 1 and damage.from:getArmor() and damage.from:getArmor():getClassName() == "SilverLion")
end

--晓
sgs.ai_skill_use["@@bachi"]=function(self,prompt)
    self:updatePlayers()
    if #self.enemies > 0 then
	    self:sort(self.enemies, "defenseSlash")
		local selectset = {}
	    for _,enemy in ipairs(self.enemies) do
			if (not enemy:isProhibited(enemy, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitRed, 0))) then
				table.insert(selectset, enemy:objectName())
			end
			if #selectset >= 2 then break end
	    end
		if #selectset > 0 then
			local cards = self.player:getCards("he")
			cards = sgs.QList2Table(cards)
			self:sortByUseValue(cards, true)
		    return ("#bachi:%d:->%s"):format(cards[1]:getEffectiveId(), table.concat(selectset,"+"))
		else
		    return "."
		end
    end
    return "."
end

local hubi_skill = {}
hubi_skill.name = "hubi"
table.insert(sgs.ai_skills, hubi_skill)
hubi_skill.getTurnUseCard = function(self, inclusive)
	if (not self.player:hasUsed("#hubi")) and self:getCardsNum("Jink") > 0 then
		return sgs.Card_Parse("#hubi:.:")
	end
end

sgs.ai_skill_use_func["#hubi"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	self:sort(self.friends, "defenseSlash")
	for _,card in ipairs(cards) do
		for _,friend in ipairs(self.friends) do
			local card_id = card:getId()
			if card:isKindOf("Jink") then
				use.card = sgs.Card_Parse("#hubi:"..card_id..":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_value["hubi"] = 5
sgs.ai_use_priority["hubi"] = 0.1

--突击自由
local daijin_skill = {}
daijin_skill.name = "daijin"
table.insert(sgs.ai_skills, daijin_skill)
daijin_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("daijin") then return false end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	local ids = {}
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			table.insert(newcards, card)
			table.insert(ids, card:getEffectiveId())
		end
	end
	if #newcards < 2 then return end

	local card_id1 = newcards[1]:getEffectiveId()
	local card_id2 = newcards[2]:getEffectiveId()

	if newcards[1]:isBlack() and newcards[2]:isBlack() then
		local black_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuitBlack)
		black_slash:setSkillName("daijin")
		local nosuit_slash = sgs.Sanguosha:cloneCard("fire_slash")
		nosuit_slash:setSkillName("daijin")

		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
				and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				self:sortByUseValue(blackcards, true)
				self:sortByUseValue(redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = redcard:getEffectiveId()
					card_id2 = othercard:getEffectiveId()
					break
				end
			end
		end
	end
	
	local card_str = ("fire_slash:daijin[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)
	
	if self.player:getMark("@seedsf") > 0 and self.player:getHandcardNum() > self.player:getMaxCards() + 1 and #self.enemies > 2 then
		card_str = ("fire_slash:daijin[%s:%s]=%s"):format("to_be_decided", 0, table.concat(ids, "+", 1, #self.enemies))
	end
	
	local slash = sgs.Card_Parse(card_str)
	return slash
end

sgs.ai_use_value["daijin"] = sgs.ai_use_value.FireSlash + 0.1
sgs.ai_use_priority["daijin"] = sgs.ai_use_priority.FireSlash

sgs.ai_skill_choice.daijin = function(self, choices, data)
	local choice = choices:split("+")
	return choice[math.random(1, #choice)]
end

sgs.ai_skill_invoke.chaoqi = function(self, data)
    local use = data:toCardUse()
	return not self:isFriend(use.from)
end

--无限正义
sgs.ai_skill_invoke.hanwei = function(self, data)
	local name = data:toString():split(":")[3]
	local enemy = findPlayerByObjectName(self.room, name)
	return enemy and self:isEnemy(enemy)
end

sgs.ai_skill_use["@@shijiu"] = function(self, prompt)
    self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy) then
			if #targets >= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash) then break end
			table.insert(targets, enemy:objectName())
		end
	end
	if #targets > 0 then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local suits = {}
		for _,cd in sgs.qlist(self.player:getEquips()) do
			local suit = cd:getSuit()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		for _,card in ipairs(cards) do
			if table.contains(suits, card:getSuit()) then
				return ("slash:shijiu[%s:%s]=%d->%s"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId(), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end

--命运
sgs.ai_skill_invoke.huanyi = function(self, data)
	return true
end

sgs.ai_view_as.huanyi = function(card, player, card_place)
	if player:getMark("@huanyi") == 0 then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() and card_place == sgs.Player_PlaceHand then
		return ("jink:huanyi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

--传说
sgs.ai_skill_invoke.jiqi = function(self, data)
	return true
end

sgs.ai_skill_use["@@jiqi"] = function(self,prompt)
    self:updatePlayers()
    if #self.enemies > 0 then
	    self:sort(self.enemies, "defense")
		local selectset = {}
		for _,enemy in ipairs(self.enemies) do
			table.insert(selectset, enemy:objectName())
			if #selectset >= self.player:getMark("jiqi") then break end
	    end
		if #selectset > 0 then
		    return ("#jiqi:.:->%s"):format(table.concat(selectset,"+"))
		end
    end
    return "."
end

--[[sgs.ai_skill_invoke.kelong = function(self, data)
	local dying = data:toDying()
	local damage = dying.damage
	local from = damage.from
	return self:isEnemy(from)
end]]

sgs.ai_skill_invoke.kelong = function(self, data)
	return true
end

sgs.ai_view_as.kelong = function(card, player, card_place)
	if player:getPile("kelong"):isEmpty() then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getPileName(card_id) == "kelong" then
		return ("jink:kelong[%s:%s]=%d"):format(suit, number, card_id)
	end
end

--漆黑突击
sgs.ai_skill_use["@@huantong"] = function(self, prompt)
    self:updatePlayers()
	local subcard = nil
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isBlack() and not card:hasFlag("using") then
			subcard = card
		end
	end
	if subcard == nil then return "." end
	local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", subcard:getSuit(), subcard:getNumber())
	iron_chain:addSubcard(subcard)
	local targets = {}
	self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if friend:isChained() and (not friend:isProhibited(friend, iron_chain)) then
			if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, iron_chain) then
				return ("iron_chain:huantong[%s:%s]=%s->%s"):format(iron_chain:getSuitString(), iron_chain:getNumberString(), subcard:getEffectiveId(), table.concat(targets, "+"))
			end
			table.insert(targets, friend:objectName())
		end
	end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:isChained()) and (not enemy:isProhibited(enemy, iron_chain)) then
			if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, iron_chain) then break end
			table.insert(targets, enemy:objectName())
		end
	end
	if #targets > 0 then
		return ("iron_chain:huantong[%s:%s]=%s->%s"):format(iron_chain:getSuitString(), iron_chain:getNumberString(), subcard:getEffectiveId(), table.concat(targets, "+"))
	elseif self.player:getHp() <= 2 and self:getCardsNum("Jink") == 0 then
		return ("iron_chain:huantong[%s:%s]=%s->%s"):format(iron_chain:getSuitString(), iron_chain:getNumberString(), subcard:getEffectiveId(), self.enemies[1]:objectName())
	end
	return "."
end

sgs.huantong_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.huantong(to, card)
	return card:isBlack()
end

local jianmie_skill = {}
jianmie_skill.name = "jianmie"
table.insert(sgs.ai_skills, jianmie_skill)
jianmie_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isNude() or not sgs.Slash_IsAvailable(self.player) then
		return false
	end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card:objectName() == "slash" and not card:hasFlag("using") then
			local slash_str = ("fire_slash:jianmie[%s:%s]=%d"):format(suit, number, card_id)
			local jianmieslash = sgs.Card_Parse(slash_str)
			local targets = {}
			self:sort(self.enemies, "defenseSlash")
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, jianmieslash) and self:slashIsEffective(jianmieslash, enemy) then
					if #targets == 1 then
						if enemy:isChained() or findPlayerByObjectName(self.room, targets[1]):isChained() then
							table.insert(targets, enemy:objectName())
						end
					else
						if #targets >= 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, jianmieslash) then break end
						table.insert(targets, enemy:objectName())
					end
				end
			end
			if #targets > 0 then
				return sgs.Card_Parse("#jianmie:" .. card:getEffectiveId() .. ":->" .. table.concat(targets, "+"))
			end
		end
	end
end

sgs.ai_skill_use_func["#jianmie"] = function(card, use, self)
	use.card = card
	if use.to then
		local targets = card:toString():split("->")[2]:split("+")
		for _,name in pairs(targets) do
			local target = findPlayerByObjectName(self.room, name)
			if target then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value["jianmie"] = sgs.ai_use_value.FireSlash + 0.1
sgs.ai_use_priority["jianmie"] = sgs.ai_use_priority.Slash + 0.1

--艾斯亚R
local duzhan_skill={}
duzhan_skill.name="duzhan"
table.insert(sgs.ai_skills,duzhan_skill)
duzhan_skill.getTurnUseCard=function(self)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:inMyAttackRange(self.player) then
			return false
		end
	end
	
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local handcard

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if (not card:isKindOf("Slash")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = handcard:getSuitString()
	local number = handcard:getNumberString()
	local card_id = handcard:getEffectiveId()
	local card_str = ("slash:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.duzhan = function(card, player, card_place)
	for _, p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
		if not p:inMyAttackRange(player) then
			return false
		end
	end

	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip then
		return ("jink:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	else
		return ("slash:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["duzhan"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["duzhan"] = sgs.ai_use_priority.Slash - 0.1

--再生加农/再生高达
local jidong_skill = {}
jidong_skill.name = "jidong"
table.insert(sgs.ai_skills, jidong_skill)
jidong_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:getCards("he"):length() > 2  and not self.player:hasUsed("#jidong")) or self.player:hasUsed("#reborns_transam") then
		if self.player:getGeneralName() == "REBORNS_GUNDAM" and (self:getCardsNum("FireSlash") + self:getCardsNum("ThunderSlash")) == 0 then return false end
		if self.player:getGeneralName() == "REBORNS_CANNON" and (self:getCardsNum("FireSlash") + self:getCardsNum("ThunderSlash")) > 0
			and (not self.player:hasUsed("#fengong") or self.player:hasUsed("#reborns_transam")) then return false end
		return sgs.Card_Parse("#jidong:.:")
	end
end

sgs.ai_skill_use_func["#jidong"] = function(card, use, self)
	if self.player:hasUsed("#reborns_transam") then
		use.card = sgs.Card_Parse("#jidong:.:")
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") then continue end
			use.card = sgs.Card_Parse("#jidong:"..card:getId()..":")
			return
		end
	end
end

sgs.ai_use_value["jidong"] = sgs.ai_use_value.ExNihilo - 0.2
sgs.ai_use_priority["jidong"] = sgs.ai_use_priority.ExNihilo - 0.2

local fengong_skill = {}
fengong_skill.name = "fengong"
table.insert(sgs.ai_skills, fengong_skill)
fengong_skill.getTurnUseCard = function(self, inclusive)
	if (self:getCardsNum("FireSlash") > 0 or self:getCardsNum("ThunderSlash") > 0)
		and (not self.player:hasUsed("#fengong") or self.player:hasUsed("#reborns_transam")) and #self.enemies > 0 then
		return sgs.Card_Parse("#fengong:.:")
	end
end

sgs.ai_skill_use_func["#fengong"] = function(card, use, self)
	self:sort(self.enemies, "hp")
    local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,card in ipairs(cards) do
		if card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") then
			use.card = sgs.Card_Parse("#fengong:"..card:getId()..":")
			if use.to then
				use.to:append(self.enemies[1])
				if #self.enemies > 1 then
					use.to:append(self.enemies[2])
				end
			end
			return
		end
	end
end

sgs.ai_use_value["fengong"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["fengong"] = sgs.ai_use_priority.Slash

local zaisheng_skill = {}
zaisheng_skill.name = "zaisheng"
table.insert(sgs.ai_skills, zaisheng_skill)
zaisheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#zaisheng") and not self.player:isNude() then
		return sgs.Card_Parse("#zaisheng:.:")
	end
end

sgs.ai_skill_use_func["#zaisheng"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		local card = sgs.Sanguosha:getCard(unpreferedCards[index])
		if not self.player:isJilei(card) and not card:isKindOf("FireSlash") and not card:isKindOf("ThunderSlash") then
			table.insert(use_cards, unpreferedCards[index])
		end
	end
	
	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#zaisheng:"..table.concat(use_cards, "+")..":")
		return
	end
end

sgs.ai_use_value["zaisheng"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["zaisheng"] = sgs.ai_use_priority.ExNihilo
sgs.dynamic_value.benefit["zaisheng"] = true

local reborns_transam_skill = {}
reborns_transam_skill.name = "reborns_transam"
table.insert(sgs.ai_skills, reborns_transam_skill)
reborns_transam_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@reborns_transam") > 0 and (self:getCardsNum("FireSlash") + self:getCardsNum("ThunderSlash")) > 1 and #self.enemies > 0 then
		return sgs.Card_Parse("#reborns_transam:.:")
	end
end

sgs.ai_skill_use_func["#reborns_transam"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["reborns_transam"] = sgs.ai_use_value.ExNihilo + 0.2
sgs.ai_use_priority["reborns_transam"] = sgs.ai_use_priority.ExNihilo + 0.2
sgs.dynamic_value.benefit["reborns_transam"] = true

--哈鲁特
sgs.ai_view_as.feijian = function(card, player, card_place)
	if player:getPile("jian"):isEmpty() or player:isNude() then return false end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and not card:isKindOf("Peach") and not card:hasFlag("using") then
		for _,id in sgs.qlist(player:getPile("jian")) do
			if sgs.Sanguosha:getCard(id):getSuitString() == suit then
				return ("slash:feijian[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end

local feijian_skill = {}
feijian_skill.name = "feijian"
table.insert(sgs.ai_skills, feijian_skill)
feijian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("jian"):isEmpty() or self.player:isNude() or not sgs.Slash_IsAvailable(self.player) then
		return false
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if not card:isKindOf("Peach") and not card:hasFlag("using") then
			for _,id in sgs.qlist(self.player:getPile("jian")) do
				if sgs.Sanguosha:getCard(id):getSuitString() == suit then
					local slash_str = ("slash:feijian[%s:%s]=%d"):format(suit, number, card_id)
					local feijianslash = sgs.Card_Parse(slash_str)
					for _,enemy in ipairs(self.enemies) do
						if self.player:canSlash(enemy, feijianslash) and self:slashIsEffective(feijianslash, enemy) then
							assert(feijianslash)
							return feijianslash
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_value["feijian"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["feijian"] = sgs.ai_use_priority.Slash + 0.1

local liuyan_skill = {}
liuyan_skill.name = "liuyan"
table.insert(sgs.ai_skills, liuyan_skill)
liuyan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getPile("jian"):isEmpty() or self.player:getMark("@MARUT") == 0 then
		return false
	end
	local spade, heart, club, diamond = 0, 0, 0, 0
	for _,i in sgs.qlist(self.player:getPile("jian")) do
		local suits = sgs.Sanguosha:getCard(i):getSuitString()
		if suits == "spade" then
			spade = spade + 1
		elseif suits == "heart" then
			heart = heart + 1
		elseif suits == "club" then
			club = club + 1
		elseif suits == "diamond" then
			diamond = diamond + 1
		end
	end
	for _,id in sgs.qlist(self.player:getPile("jian")) do
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		local suit_no = math.max(spade, heart, club, diamond)
		if (suit_no == spade and suit == "spade") or (suit_no == heart and suit == "heart") or (suit_no == club and suit == "club")
			or (suit_no == diamond and suit == "diamond") then
			if peach:isAvailable(self.player) then
				local peach_str = ("peach:liuyan[%s:%s]=%d"):format(suit, number, card_id)
				local use = sgs.Card_Parse(peach_str)
				assert(use)
				return use
			end
		end
	end
end

sgs.ai_view_as.liuyan = function(card, player, card_place)
	if player:getMark("@MARUT") == 0 or player:getPile("jian"):isEmpty() then return false end
	local spade, heart, club, diamond = 0, 0, 0, 0
	for _,i in sgs.qlist(player:getPile("jian")) do
		local suits = sgs.Sanguosha:getCard(i):getSuitString()
		if suits == "spade" then
			spade = spade + 1
		elseif suits == "heart" then
			heart = heart + 1
		elseif suits == "club" then
			club = club + 1
		elseif suits == "diamond" then
			diamond = diamond + 1
		end
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local suit_no = math.max(spade, heart, club, diamond)
	if (suit_no == spade and suit == "spade") or (suit_no == heart and suit == "heart") or (suit_no == club and suit == "club")
		or (suit_no == diamond and suit == "diamond") then
		if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "jian" and player:getMark("Global_PreventPeach") == 0 then
			return ("peach:liuyan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_use_value["liuyan"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["liuyan"] = sgs.ai_use_priority.Peach

local harute_transam_skill = {}
harute_transam_skill.name = "harute_transam"
table.insert(sgs.ai_skills, harute_transam_skill)
harute_transam_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@harute_transam") > 0 and willUse(self, "Slash") then
		local n = 0
		local suits = {}
		for _,id in sgs.qlist(self.player:getPile("jian")) do
			local suit = sgs.Sanguosha:getCard(id):getSuitString()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if (table.contains(suits, card:getSuitString()) and not card:isKindOf("Peach")) or card:isKindOf("Slash")  then
				n = n + 1
			end
		end
		local can_invoke = false
		self:sort(self.enemies, "hp")
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local p = self.enemies[1]
		if n >= 4 and #self.enemies > 0 and not p:isProhibited(p, card) and self:slashIsEffective(card, p, self.player) and not p:hasSkill("mosu") then
			return sgs.Card_Parse("#harute_transam:.:")
		end
	end
end

sgs.ai_skill_use_func["#harute_transam"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["harute_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["harute_transam"] = sgs.ai_use_priority.Analeptic

--ELS Q
local ronghe_skill={}
ronghe_skill.name="ronghe"
table.insert(sgs.ai_skills,ronghe_skill)
ronghe_skill.getTurnUseCard=function(self,inclusive)
    if not self.player:hasUsed("#ronghe") then
		if #self.enemies == 0 and #self.friends_noself == 0 then return false end
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not p:isKongcheng() and p:getHp() > self.player:getHp() then
				local card_str = ("#ronghe:.:")
				return sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#ronghe"]=function(card, use, self)
	use.card = card
	if use.to then
		local target = nil
		self:sort(self.enemies, "handcard")
		for i = #self.enemies, 1, -1 do
			local enemy = self.enemies[i]
			if not enemy:isKongcheng() and enemy:getHp() > self.player:getHp() then
				target = enemy
				break
			end
		end
		if target == nil then
			self:sort(self.friends_noself, "handcard")
			for i = #self.friends_noself, 1, -1 do
				local friend = self.friends_noself[i]
				if not friend:isKongcheng() and friend:getHp() > self.player:getHp() then
					target = friend
					break
				end
			end
		end
		if target ~= nil then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["ronghe"] = 10
sgs.ai_use_priority["ronghe"] = 10

sgs.ai_skill_invoke.lijie = function(self, data)
	local damage = data:toDamage()
	if self.player:isWounded() then
		if self:isFriend(damage.from) then
			if self.room:getTag("Dongchaer"):toString() == self.player:objectName()
				and self.room:getTag("Dongchaee"):toString() == damage.from:objectName() then
				for _,card in sgs.qlist(damage.from:getHandcards()) do
					if card:getSuit() == sgs.Card_Heart then
						return true
					end
				end
			end
		else
			return not (self.player:getHp() > 1 and damage.from:getHp() == 1)
		end
	end
	return false
end

sgs.ai_skill_cardchosen["lijie"] = function(self, who, flags)
	if self.room:getTag("Dongchaer"):toString() == self.player:objectName()
		and self.room:getTag("Dongchaee"):toString() == who:objectName() then
		for _,card in sgs.qlist(who:getHandcards()) do
			if card:getSuit() == sgs.Card_Heart then
				return card
			end
		end
	end
	return nil
end

--00QFS
sgs.ai_skill_invoke.quanren = function(self, data)
	local want_attack = false
	self:sort(self.enemies, "defenseSlash")
	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0), enemy) then
			want_attack = true
			break
		end
	end
	if self.player:hasSkill("fs_transam") and self.player:getMark("@fs_transam") > 0 then
		return (willUse(self, "Slash") and self:getCardsNum("Slash") >= 2) or (self:getCardsNum("Slash") == 0 and want_attack)
	end
	return self:getCardsNum("Slash") == 0 and want_attack
end

local quanren_skill={}
quanren_skill.name="quanren"
table.insert(sgs.ai_skills,quanren_skill)
quanren_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local list = self.player:property("quanren"):toString():split("+")
	if #list == 0 then return false end

	local handcard

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if (table.contains(list, tostring(card:getEffectiveId()))) and (not card:isKindOf("Slash")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = handcard:getSuitString()
	local number = handcard:getNumberString()
	local card_id = handcard:getEffectiveId()
	local card_str = ("slash:quanren[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.quanren = function(card, player, card_place)
	local list = player:property("quanren"):toString():split("+")
	if #list == 0 then return false end

	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand and table.contains(list, tostring(card_id)) then
		return ("slash:quanren[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["quanren"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["quanren"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_choice.quanren = function(self, choices, data)
	choices = {"quanrenpile", "quanrenpile", "quanrenhand"}
	return choices[math.random(3)]
end

sgs.ai_skill_invoke.yueqian = function(self, data)
	return true
end

local fs_transam_skill = {}
fs_transam_skill.name = "fs_transam"
table.insert(sgs.ai_skills, fs_transam_skill)
fs_transam_skill.getTurnUseCard = function(self, inclusive)
	local slash_count = 0
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Slash") then
			slash_count = slash_count + 1
		end
	end
    if self.player:getMark("@fs_transam") > 0 and willUse(self, "Slash") and slash_count >= 2 then
		return sgs.Card_Parse("#fs_transam:.:")
	end
end

sgs.ai_skill_use_func["#fs_transam"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["fs_transam"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["fs_transam"] = sgs.ai_use_priority.Slash + 0.05

--星创突击
sgs.ai_skill_invoke.jieneng = function(self, data)
	local use = data:toCardUse()
	local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
	local index = use.to:indexOf(self.player) + 1
	return self.player:getMark("@shineng") > 0 or self:getCardsNum("Jink") == 0 or jink_table[index] == 0 or jink_table[index] > self:getCardsNum("Jink")
end

local shineng_skill = {}
shineng_skill.name = "shineng"
table.insert(sgs.ai_skills, shineng_skill)
shineng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@shineng") > 0 and self.player:getPile("neng"):length() > 1 and (willUse(self, "Slash") or self.player:hasUsed("Slash") or self.player:getMaxCards() <= 1) then
		return sgs.Card_Parse("#shineng:.:")
	end
end

sgs.ai_skill_use_func["#shineng"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["shineng"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["shineng"] = sgs.ai_use_priority.Slash
sgs.dynamic_value.benefit["shineng"] = true

sgs.ai_skill_invoke.rg = function(self, data)
	return self.player:getMark("@shineng") == 0
end

--暗物质
local dm_transam_skill = {}
dm_transam_skill.name = "dm_transam"
table.insert(sgs.ai_skills, dm_transam_skill)
dm_transam_skill.getTurnUseCard = function(self, inclusive)
	local equips = self.player:getEquips()
	local installed, unlimited = true, false
	if (self:getCardsNum("Weapon") > 0 and self.player:getWeapon() == nil)
		or (self:getCardsNum("Armor") > 0 and self.player:getArmor() == nil)
		or (self:getCardsNum("DefensiveHorse") > 0 and self.player:getDefensiveHorse() == nil)
		or (self:getCardsNum("OffensiveHorse") > 0 and self.player:getOffensiveHorse() == nil)
		or (self:getCardsNum("Treasure") > 0 and self.player:getTreasure() == nil) then
		installed = false
	end
	if self.player:getWeapon() and self.player:getWeapon():getClassName() == "Crossbow" then
		unlimited = true
	end
    if self.player:getMark("@dm_transam") > 0 and equips:length() > 0 and installed
		and ((willUse(self, "Slash") and (not unlimited) and self:getCardsNum("Slash") > (2 - math.floor(equips:length() / 2)))
		or (self.player:getHp() <= 1 and self.player:getHandcardNum() <= 1)) then
		local ids = {}
		for _,card in sgs.qlist(equips) do
			table.insert(ids, card:getId())
		end
		return sgs.Card_Parse("#dm_transam:"..(table.concat(ids, "+"))..":")
	end
end

sgs.ai_skill_use_func["#dm_transam"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["dm_transam"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["dm_transam"] = sgs.ai_use_priority.Slash + 0.05

--创制燃焰
sgs.ai_skill_use["@@ciyuanbawangliu"] = function(self, prompt)
	local use = self.player:getTag("ciyuanbawangliu"):toCardUse()
	local quanfa = self.player:getPile("quanfa")
	for _,p in sgs.qlist(use.to) do
		for _,id in sgs.qlist(quanfa) do
			local qcard = sgs.Sanguosha:getCard(id)
			local name = qcard:objectName()
			if self.player:getMark("@tonghua") > 0 and qcard:isRed() then
				name = "fire_slash"
			end
			local acard = sgs.Sanguosha:cloneCard(name, use.card:getSuit(), use.card:getNumber())
			acard:addSubcard(use.card)
			
			if (use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")) and (p:getArmor() or p:getDefensiveHorse()) then
				return "."
			end
			
			local effective = (acard:isKindOf("Slash") and self:slashIsEffective(acard, p, self.player))
								or (acard:isKindOf("TrickCard") and self:hasTrickEffective(acard, p, self.player))
			
			if self.player:getMark("@tonghua") == 0 then
				if use.card:isKindOf("Slash") then
					if use.card:hasFlag("drank") then
						if qcard:isBlack() and qcard:isKindOf("Slash") and self:slashIsEffective(acard, p, self.player) then
							return ("#ciyuanbawangliu:" .. id .. ":")
						end
					else
						if qcard:isBlack() and effective then
							return ("#ciyuanbawangliu:" .. id .. ":")
						end
					end
				else
					if qcard:isBlack() and effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				end
			else
				if use.card:isKindOf("Slash") then
					if qcard:isKindOf("TrickCard") and effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				else
					if effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				end
			end
		end
	end
    return "."
end

--TRY燃焰
local hongbao_skill = {}
hongbao_skill.name = "hongbao"
table.insert(sgs.ai_skills,hongbao_skill)
hongbao_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@hongbao") > 0 and self.player:isWounded() and self:getSuitNum("red", false, self.player) > 0 and self.player:getPile("quanfa"):length() > 1 then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(cards,true)
		for _,card in ipairs(cards) do
			if card:isRed() and (not card:isKindOf("ExNihilo")) then
				local card_str = ("#hongbao:"..card:getId()..":")
				return sgs.Card_Parse(card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#hongbao"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["hongbao"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["hongbao"] = sgs.ai_use_value.ExNihilo - 0.5

local shengfeng_skill = {}
shengfeng_skill.name = "shengfeng"
table.insert(sgs.ai_skills, shengfeng_skill)
shengfeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getPile("quanfa"):isEmpty() or self.player:hasUsed("#shengfeng") then return false end
	
	local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
	fire_attack:setSkillName("shengfeng")
	
	for _,id in sgs.qlist(self.player:getPile("quanfa")) do
		local new_suit = true
		for _,i in sgs.qlist(fire_attack:getSubcards()) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(i):getSuit() then
				new_suit = false
				break
			end
		end
		if new_suit then
			fire_attack:addSubcard(id)
		end
	end
	
	if fire_attack:subcardsLength() < 2 then return false end
	
	for _,enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(fire_attack, enemy, self.player) then
			return fire_attack
		end
	end
end

sgs.ai_use_value["shengfeng"] = sgs.ai_use_value.FireAttack + 0.5
sgs.ai_use_priority["shengfeng"] = sgs.ai_use_value.FireAttack + 0.5

--G-SELF
sgs.ai_skill_invoke["#G_SELF_skill"] = function(self, data)
	return true
end

sgs.ai_view_as.huanse = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("nullification:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Nullification") then
			return ("jink:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_skill_invoke["#G_SELF_HT_skill"] = function(self, data)
	local target = self.player:getTag("G_SELF_HT_skill"):toPlayer()
	return self:isEnemy(target)
end

--完美G-SELF
local huancai_skill = {}
huancai_skill.name = "huancai"
table.insert(sgs.ai_skills, huancai_skill)
huancai_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("huancai") then return false end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _,card in ipairs(cards) do
		if not card:isKindOf("ExNihilo") and not (self.player:isWounded() and card:isKindOf("Peach")) and not (self:getCardsNum("Jink") == 1 and card:isKindOf("Jink")) then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("ex_nihilo:huancai[%s:%s]=%d"):format(suit, number, card_id)
			return sgs.Card_Parse(card_str)
		end
	end
end

sgs.ai_use_value["huancai"] = sgs.ai_use_value.ExNihilo + 1
sgs.ai_use_priority["huancai"] = sgs.ai_use_priority.Slash + 0.5

sgs.ai_view_as.huancai = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("nullification:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Nullification") then
			return ("jink:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

--巴巴托斯
sgs.ai_skill_invoke.tiexue = function(self, data)
	return true
end

sgs.ai_skill_choice.tiexue = function(self, choices, data)
	if willUse(self, "Slash") or willUse(self, "Duel") then
		return "tiexuebuff"
	end
	return "tiexuedraw"
end

--巴巴托斯 天狼
sgs.ai_skill_invoke.tianlang = function(self, data)
	return sgs.ai_skill_invoke.kunfen(self, data)
end

sgs.tianlang_suit_value = {
	spade = 3.9,
	club = 3.9
}

--巴巴托斯 帝王
sgs.ai_skill_invoke.diwang = function(self, data)
	local x = data:toString()
	if x and x:startsWith("draw") then
		x = tonumber(x:split(":")[2])
		if x < 2 then
			return willUse(self, "Slash") and not self:isWeak(self.player)
		else
			return true
		end
	else
		local damage = data:toDamage()
		if self:isEnemy(damage.to) then
			if damage.to:isChained() and #self.enemies > 1 then
				for _, friend in pairs(self.friends) do
					if friend:isChained() then
						return false
					end
				end
			end
			return true
		end
	end
end