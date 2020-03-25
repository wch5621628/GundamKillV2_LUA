module("extensions.boss", package.seeall)
extension = sgs.Package("boss", sgs.Package_GeneralPack)

--获得G币
gainCoin = function(player, n)
	if n < 1 then return false end

	local room = player:getRoom()
	
	local json = require("json")
	local jsonValue = {
	player:objectName(),
	"yomeng"
	}
	local wholist = sgs.SPlayerList()
	wholist:append(player)
	room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))

	local log = sgs.LogMessage()
	log.type = "#coin"
	log.from = player
	log.arg = n
	room:sendLog(log)
	if n == 1 then
		room:broadcastSkillInvoke("gdsbgm", 7)
	else
		room:broadcastSkillInvoke("gdsbgm", 8)
	end
	
	local ip = room:getOwner():getIp()
	if (player:getState() == "online" or player:getState() == "trust") then
		room:setPlayerMark(player, "lucky_item_n", n)
		--room:askForUseCard(player, "@@luckyrecord!", "@luckyrecord")
		
		room:acquireSkill(player, "#luckyrecordm", false)
		player:getMaxCards() -- 强制让客户端执行MaxCardsSkill里的extra_func进行存档
		room:detachSkillFromPlayer(player, "#luckyrecordm", true, true)
		
		room:setPlayerMark(player, "lucky_item_n", 0)
		room:setPlayerFlag(player, "-g2data_saved")
	end
end

--获得特殊道具
gainSPItem = function(player, item, n)
	if not n then n = 1 end
	if n < 1 then return false end

	local room = player:getRoom()
	
	local log = sgs.LogMessage()
	log.type = "#" .. item
	log.from = player
	log.arg = n
	log.arg2 = item
	room:sendLog(log)
	
	local ip = room:getOwner():getIp()
	if (player:getState() == "online" or player:getState() == "trust") then
		room:setPlayerProperty(player, "lucky_item", sgs.QVariant(item))
		room:setPlayerMark(player, "lucky_item_n", n)
		
		room:acquireSkill(player, "#luckyrecordm", false)
		player:getMaxCards() -- 强制让客户端执行MaxCardsSkill里的extra_func进行存档
		room:detachSkillFromPlayer(player, "#luckyrecordm", true, true)
		
		room:setPlayerProperty(player, "lucky_item", sgs.QVariant())
		room:setPlayerMark(player, "lucky_item_n", 0)
		room:setPlayerFlag(player, "-g2data_saved")
	end
end

function getWinner(victim)
    local room = victim:getRoom()
    local winner = ""

    if room:getMode() == "06_3v3" then
        local role = victim:getRoleEnum()
        if role == sgs.Player_Lord then
			winner = "renegade+rebel"
        elseif role == sgs.Player_Renegade then
			winner = "lord+loyalist"
        end
    elseif room:getMode() == "06_XMode" then
        local role = victim:getRole()
        local leader = victim:getTag("XModeLeader"):toPlayer()
        if leader:getTag("XModeBackup"):toStringList():isEmpty() then
            if role:startsWith("r") then
                winner = "lord+loyalist"
            else
                winner = "renegade+rebel"
			end
        end
    elseif room:getMode() == "08_defense" then
        local alive_roles = room:aliveRoles(victim)
        if not table.contains(alive_roles, "loyalist") then
            winner = "rebel"
        elseif not table.contains(alive_roles, "rebel") then
            winner = "loyalist"
		end
    elseif sgs.GetConfig("EnableHegemony", true) then
        local has_anjiang, has_diff_kingdoms = false, false
        local init_kingdom = ""
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:property("basara_generals"):toString() ~= "" then
                has_anjiang = true
			end
            if init_kingdom:isEmpty() then
                init_kingdom = p:getKingdom()
            elseif init_kingdom ~= p:getKingdom() then
                has_diff_kingdoms = true
			end
        end

        if not has_anjiang and not has_diff_kingdoms then
            local winners = {}
            local aliveKingdom = room:getAlivePlayers():first():getKingdom()
            for _,p in sgs.qlist(room:getPlayers()) do
                if p:isAlive() then
					table.insert(winners, p:objectName())
				end
                if p:getKingdom() == aliveKingdom then
                    local generals = p:property("basara_generals"):toString():split("+")
                    if #generals and sgs.GetConfig("Enable2ndGeneral", false) then continue end
                    if #generals > 1 then continue end

                    --if someone showed his kingdom before death,
                    --he should be considered victorious as well if his kingdom survives
                    table.insert(winners, p:objectName())
                end
            end
            winner = table.concat(winners, "+")
        end
        --[[if winner ~= "" then
            for _,player in sgs.qlist(room:getAllPlayers()) then
                if player:getGeneralName() == "anjiang" then
                    local generals = player:property("basara_generals"):toString():split("+")
                    room:changePlayerGeneral(player, generals[1])

                    room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getGeneral():getKingdom()))
                    room:setPlayerProperty(player, "role", BasaraMode::getMappedRole(player:getKingdom()))

                    generals.takeFirst()
                    player:setProperty("basara_generals", table.concat(generals, "+"))
                    room:notifyProperty(player, player, "basara_generals")
                end
                if sgs.GetConfig("Enable2ndGeneral", true) and player:getGeneral2Name() == "anjiang" then
                    local generals = player:property("basara_generals"):toString():split("+")
                    room:changePlayerGeneral2(player, generals[1])
                end
            end
        end]]--It is useless as it is irrelevant in LUA.
    else
        local alive_roles = room:aliveRoles(victim)
        local role = victim:getRoleEnum()
        if role == sgs.Player_Lord then
            if #alive_roles == 1 and alive_roles[1] == "renegade" then
                winner = room:getAlivePlayers():first():objectName()
            else
                winner = "rebel"
            end
        elseif role == sgs.Player_Rebel or role == sgs.Player_Renegade then
            if not table.contains(alive_roles, "rebel") and not table.contains(alive_roles, "renegade") then
                winner = "lord+loyalist"
            end
        else
        end
    end

    return winner
end

--灭绝爆发
burste = sgs.CreateTriggerSkill{
	name = "burste",
	events = {sgs.EventPhaseStart},
	priority = 1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getMark("@burste9") == 0 and player:getMark("@burste6") == 0 and player:getMark("@burste3") == 0 then return false end
			
			local n = room:getOtherPlayers(player):length()
			-- 二项分布/几何分布：1 - (1 - prob) ^ n = 60%
			local prob = 1 - math.pow(0.4, 1 / n)
			local targets = {}
			for i, p in sgs.qlist(room:getOtherPlayers(player)) do
				math.randomseed(os.time() * (i + 1))
				local N = math.random(10000000)
				if N < prob * 10000000 then
					table.insert(targets, p)
				end
			end
			
			if #targets > 0 then
				room:sendCompulsoryTriggerLog(player, "burste")
				if player:getMark("@burste9") == 1 then
					room:setPlayerMark(player, "@burste9", 0)
					room:setPlayerMark(player, "@burste6", 1)
				elseif player:getMark("@burste6") == 1 then
					room:setPlayerMark(player, "@burste6", 0)
					room:setPlayerMark(player, "@burste3", 1)
				elseif player:getMark("@burste3") == 1 then
					room:setPlayerMark(player, "@burste3", 0)
				end
				
				for _, p in ipairs(targets) do
					room:doAnimate(1, player:objectName(), p:objectName())
					room:loseHp(p)
				end
			end
		end
	end
}

-- 通用效果：房主赢了可以选择重玩此局（联机刷币甚佳）
_mini_0_skill = sgs.CreateTriggerSkill{
	name = "_mini_0_skill",
	events = {sgs.GameOverJudge},
	priority = 0,
	global = true,
	can_trigger = function(self, player)
		local mode = player:getGameMode()
		if mode:startsWith("_mini_") then
			local n = string.gsub(mode, "_mini_", "")
			n = tonumber(n)
			return n >= 2
		end
		return false
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local owner = room:getOwner()
		local winner = getWinner(player) -- player is victim
		if winner ~= "" then
			if string.find(winner, owner:getRole()) or string.find(winner, owner:objectName())then
				local choice = room:askForChoice(owner, "restart_mini?", "restart_mini+next_mini", sgs.QVariant())
				if choice == "restart_mini" then
					room:setTag("NextGameMode", sgs.QVariant(player:getGameMode()))
				end
			end
		end
	end
}

-- 剧情效果：单挑谁赢谁拿10个G币而已
_mini_2_skill = sgs.CreateTriggerSkill{
	name = "_mini_2_skill",
	events = {sgs.GameOverJudge},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_2"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAllPlayers(true)) do
			if p:objectName() ~= player:objectName() then
				gainCoin(p, 10)
			end
		end
	end
}

-- 剧情效果：巴巴托斯会复活两次，第一次复活变身8/8天狼并获得技能“狂骨”，第二次复活变身12/12帝王并获得技能“血祭”
-- 反贼胜利可以拿10个G币，主公胜利不会拿（BOSS强度都让你嗨翻天了，还想当BOSS骗G币？）
_mini_3_skill = sgs.CreateTriggerSkill{
	name = "_mini_3_skill",
	events = {sgs.GameOverJudge, sgs.BuryVictim},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_3"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isLord() then
			if event == sgs.GameOverJudge then
				if player:getGeneralName() == "BARBATOS" then
					room:revivePlayer(player)
					return true
				elseif player:getGeneralName() == "LUPUS" then
					room:revivePlayer(player)
					return true
				else
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if p:objectName() ~= player:objectName() then
							gainCoin(p, 10)
						end
					end
				end
			else
				if player:getGeneralName() == "BARBATOS" then
					room:changeHero(player, "LUPUS", true, true, false, true)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(8))
					room:setPlayerProperty(player, "hp", sgs.QVariant(8))
					player:throwAllCards()
					player:drawCards(8)
					if not player:faceUp() then
						player:turnOver()
					end
					if player:isChained() then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
					room:acquireSkill(player, "kuanggu")
					return true
				elseif player:getGeneralName() == "LUPUS" then
					room:changeHero(player, "REX", true, true, false, true)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(12))
					room:setPlayerProperty(player, "hp", sgs.QVariant(12))
					player:throwAllCards()
					player:drawCards(12)
					if not player:faceUp() then
						player:turnOver()
					end
					if player:isChained() then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
					room:acquireSkill(player, "xueji")
					return true
				end
			end
		end
	end
}

-- 剧情效果：清完杂兵后，原本两个穿藤甲的杂兵会复活成命运和传说
-- 主公/忠臣胜利可以拿10个G币
_mini_4_skill = sgs.CreateTriggerSkill{
	name = "_mini_4_skill",
	events = {sgs.GameOverJudge, sgs.BuryVictim},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_4"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameOverJudge then
			if player:getKingdom() == "OMNI" and room:getLieges("OMNI", player):isEmpty() then
				local a, b = room:getAllPlayers(true):at(5), room:getAllPlayers(true):at(6)
				room:revivePlayer(a)
				room:revivePlayer(b)
				if a:objectName() == player:objectName() then
					room:setPlayerFlag(player, "_mini_4_destiny")
					room:changeHero(b, "LEGEND", true, true, false, true)
					b:drawCards(4)
					if not b:faceUp() then
						b:turnOver()
					end
					if b:isChained() then
						room:setPlayerProperty(b, "chained", sgs.QVariant(false))
					end
					return true
				elseif b:objectName() == player:objectName() then
					room:setPlayerFlag(player, "_mini_4_legend")
					room:changeHero(a, "DESTINY", true, true, false, true)
					a:drawCards(4)
					if not a:faceUp() then
						a:turnOver()
					end
					if a:isChained() then
						room:setPlayerProperty(a, "chained", sgs.QVariant(false))
					end
					return true
				else
					room:changeHero(a, "DESTINY", true, true, false, true)
					a:drawCards(4)
					if not a:faceUp() then
						a:turnOver()
					end
					if a:isChained() then
						room:setPlayerProperty(a, "chained", sgs.QVariant(false))
					end
					
					room:changeHero(b, "LEGEND", true, true, false, true)
					b:drawCards(4)
					if not b:faceUp() then
						b:turnOver()
					end
					if b:isChained() then
						room:setPlayerProperty(b, "chained", sgs.QVariant(false))
					end
					return true
				end
			elseif player:getKingdom() == "ZAFT" and room:getLieges("ZAFT", player):isEmpty() then
				for _,p in sgs.qlist(room:getAllPlayers(true)) do
					if p:getKingdom() == "ORB" then
						gainCoin(p, 10)
					end
				end
			end
		else
			if player:hasFlag("_mini_4_destiny") then
				room:setPlayerFlag(player, "-_mini_4_destiny")
				room:changeHero(player, "DESTINY", true, true, false, true)
				player:throwAllCards()
				player:drawCards(4)
				if not player:faceUp() then
					player:turnOver()
				end
				if player:isChained() then
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
				return true
			elseif player:hasFlag("_mini_4_legend") then
				room:setPlayerFlag(player, "-_mini_4_legend")
				room:changeHero(player, "LEGEND", true, true, false, true)
				player:throwAllCards()
				player:drawCards(4)
				if not player:faceUp() then
					player:turnOver()
				end
				if player:isChained() then
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
				return true
			end
		end
	end
}

-- 剧情效果：若未出现双方均发动“明镜止水”的状态，甲方进入濒死状态时，其将体力回复至1点，然后乙方获得X个“怒”标记（X为甲方的体力回复值）
-- 胜利者可以拿10+Y个G币（Y为其“怒”标记数量）
_mini_5_skill = sgs.CreateTriggerSkill{
	name = "_mini_5_skill",
	events = {sgs.DrawInitialCards, sgs.EnterDying, sgs.GameOverJudge},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_5"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawInitialCards then
			if player:isLord() then
				player:speak("Gundam Fight!Ready~Go!")
				player:getNextAlive():speak("Gundam Fight!Ready~Go!")
				room:broadcastSkillInvoke(self:objectName())
				room:getThread():delay(3500)
			end
		elseif event == sgs.EnterDying then
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				if p:getMark("@mingjingzhishui") == 0 and p:getMark("@m_mingjingzhishui") == 0 then
					local x = 1 - player:getHp()
					room:recover(player, sgs.RecoverStruct(player, nil, x))
					local oppo = player:getNextAlive()
					room:addPlayerMark(oppo, "@wrath", x)
					local log = sgs.LogMessage()
					log.type = "#_mini_5_skill"
					log.from = oppo
					log.to:append(player)
					log.arg = x
					log.arg2 = oppo:getMark("@wrath")
					room:sendLog(log)
					return false
				end
			end
		else
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				if p:objectName() ~= player:objectName() then
					gainCoin(p, 10 + p:getMark("@wrath"))
				end
			end
		end
	end
}

-- 头目讨伐战：1 BOSS vs 4 讨伐队

-- BOSS专属效果：
--若存活讨伐队有3名或以上：
-- 1. BOSS摸牌数+2
-- 2. BOSS出牌阶段结束后，充能点数+1，上限为6
-- 3. 若BOSS未觉醒：讨伐队角色回合开始时，有30%机率触发效果：受到BOSS专用支援机“渣古I狙击型”的【贯穿射击】
-- 4. 若BOSS已觉醒：讨伐队角色回合结束后，若下家不为BOSS，则BOSS进行一个额外的回合

-- 讨伐队赢了可以拿15个G币&1枚银鸟吊坠
_mini_6_skill = sgs.CreateTriggerSkill{
	name = "_mini_6_skill",
	events = {sgs.GameOverJudge, sgs.EventPhaseEnd, sgs.DrawNCards, sgs.EventPhaseStart},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_6"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameOverJudge then
			if player:isLord() then
				room:doLightbox("image=image/animate/SHAMBLO_death.png", 8000)
				room:getThread():delay(2000)
				room:broadcastSkillInvoke("shenshou")
				room:getThread():delay(1500)
				for _,p in sgs.qlist(room:getAllPlayers(true)) do
					if p:objectName() ~= player:objectName() then
						gainCoin(p, 15)
						gainSPItem(p, "bird_pendant")
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if room:getOtherPlayers(player):length() >= 3 then
				if player:isLord() and player:getPhase() == sgs.Player_Play then
					local x = player:getMark("@point")
					if x < 6 then
						player:gainMark("@point")
					end
				elseif not player:isLord() and player:getPhase() == sgs.Player_Finish then
					local boss = room:getLord()
					if boss:getMark("@boss_qiangnian") > 0 and player:getNextAlive():objectName() ~= boss:objectName() then
						boss:gainAnExtraTurn()
					end
				end
			end
		elseif event == sgs.DrawNCards then
			if player:isLord() and room:getOtherPlayers(player):length() >= 3 then
				local count = data:toInt() + 2
				data:setValue(count)
			end
		else
			if not player:isLord() and room:getOtherPlayers(player):length() >= 3 and player:getPhase() == sgs.Player_RoundStart then
				local n = math.random(100)
				if n <= 30 then
					local boss = room:getLord()
					if boss:getMark("@boss_qiangnian") > 0 then return false end
					room:setPlayerProperty(boss, "general2", sgs.QVariant("ZAKU_I_ST"))
					room:broadcastSkillInvoke(self:objectName())
					room:getThread():delay(2000)
					
					local shoot = sgs.Sanguosha:cloneCard("pierce_shoot", sgs.Card_NoSuit, 0)
					shoot:setSkillName("zabing")
					room:useCard(sgs.CardUseStruct(shoot, boss, player))
					
					room:setPlayerProperty(boss, "general2", sgs.QVariant(""))
				end
			end
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("burste") then skills:append(burste) end
if not sgs.Sanguosha:getSkill("_mini_0_skill") then skills:append(_mini_0_skill) end
if not sgs.Sanguosha:getSkill("_mini_2_skill") then skills:append(_mini_2_skill) end
if not sgs.Sanguosha:getSkill("_mini_3_skill") then skills:append(_mini_3_skill) end
if not sgs.Sanguosha:getSkill("_mini_4_skill") then skills:append(_mini_4_skill) end
if not sgs.Sanguosha:getSkill("_mini_5_skill") then skills:append(_mini_5_skill) end
if not sgs.Sanguosha:getSkill("_mini_6_skill") then skills:append(_mini_6_skill) end
sgs.Sanguosha:addSkills(skills)

SHAMBLO = sgs.General(extension, "SHAMBLO", "ZEON", 7, false, true, true)

boss_juao = sgs.CreateTriggerSkill{
	name = "boss_juao",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Weapon") then
			local invoked = false
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:distanceTo(p) == 1 then
					if not invoked and room:askForSkillInvoke(player, self:objectName(), data) then
						invoked = true
						room:broadcastSkillInvoke(self:objectName())
					end
					if invoked then
						room:damage(sgs.DamageStruct(self:objectName(), player, p))
					else
						break
					end
				end
			end
		end
	end
}

boss_fuchou = sgs.CreateTriggerSkill{
	name = "boss_fuchou",
	events = {sgs.TargetSpecifying, sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecifying or (event == sgs.TargetConfirming and use.to:contains(player)) then
			if use.card and use.card:getSuit() <= 3 and use.card:objectName():endsWith("shoot") and use.to:length() == 1 and room:getOtherPlayers(player):length() >= 3 then
				local card = room:askForCard(player, ".|"..use.card:getSuitString(), "@boss_fuchou", data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false)
				if card then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
					
					local orig = use.to:first()
					local prev = orig
					for i = 1, 5 do
						local targets = room:getOtherPlayers(player)
						targets:removeOne(prev)
						local n = targets:length()
						local p = targets:at(math.random(0, n - 1))
						
						room:setEmotion(p, "reflector")
						room:doAnimate(1, prev:objectName(), p:objectName())
						room:broadcastSkillInvoke(self:objectName(), 4)
						room:getThread():delay(0400)
						
						prev = p
					end
					
					if orig:objectName() ~= prev:objectName() then
						local log1 = sgs.LogMessage()
						log1.type = "$CancelTarget"
						log1.from = use.from
						log1.arg = use.card:objectName()
						log1.to:append(orig)
						room:sendLog(log1)
						use.to:removeOne(orig)
						if not use.from:isProhibited(prev, use.card) then
							local log2 = sgs.LogMessage()
							log2.type = "#BecomeTarget"
							log2.from = prev
							log2.card_str = use.card:toString()
							room:sendLog(log2)
							use.to:append(prev)
							room:sortByActionOrder(use.to)
						end
						data:setValue(use)
					end
					
					if not prev:isNude() then
						local id_throw = room:askForCardChosen(player, prev, "he", self:objectName())
						room:throwCard(id_throw, prev, player)
					end
				end
			end
		end
	end
}

boss_miehou_card = sgs.CreateSkillCard{
	name = "boss_miehou",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		room:broadcastSkillInvoke(self:objectName(), 3)
		source:loseMark("@point", 6)
	
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
		analeptic:setSkillName("boss_miehou_card")
		if not source:isProhibited(source, analeptic) then
			room:useCard(sgs.CardUseStruct(analeptic, source, source), true)
		end
		room:getThread():delay(1000)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("boss_miehou_card")
		local tos = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not source:isProhibited(p, slash) then
				tos:append(p)
			end
		end
		if not tos:isEmpty() then
			room:useCard(sgs.CardUseStruct(slash, source, tos), true)
		end
	end
}

boss_miehou = sgs.CreateZeroCardViewAsSkill{
	name = "boss_miehou",
	view_as = function(self, cards)
		return boss_miehou_card:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@point") >= 6 and not player:hasUsed("#boss_miehou")
	end
}

boss_qiangnian = sgs.CreateTriggerSkill{
	name = "boss_qiangnian",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@boss_qiangnian") == 0 then
			local can_invoke = player:getHp() <= 4
			if not can_invoke then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("NTD") and p:getMark("@NTD") > 0 or p:hasSkill("ntdtwo") and p:getMark("@NTD2") == 0 or p:hasSkill("ntdthree") and p:getMark("@NTD3") == 0 or p:hasSkill("ntdfour") and p:getMark("@NTD4") > 0 then
						can_invoke = true
						break
					end
				end
			end
		
			if not can_invoke then return false end
		
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:doSuperLightbox("SHAMBLO", "boss_qiangnian")
			room:setPlayerProperty(player, "general", sgs.QVariant("SHAMBLO_skin1"))
			player:gainMark("@boss_qiangnian")
			room:setPlayerMark(player, "boss_qiangnian", 1)
			if player:getMaxHp() > 4 then
				room:loseMaxHp(player, player:getMaxHp() - 4)
			end
			player:drawCards(4, self:objectName())
			if player:getMark("@point") < 6 then
				player:gainMark("@point", 6 - player:getMark("@point"))
			end
			
			--灭绝爆发
			room:setPlayerMark(player, "@burste9", 1)
			local log = sgs.LogMessage()
			log.type = "#BGM"
			log.arg = ":burste"
			room:sendLog(log)
			room:acquireSkill(player, "burste")
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"burste"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:broadcastSkillInvoke("gdsbgm", 4)
		end
	end
}

SHAMBLO:addSkill(boss_juao)
SHAMBLO:addSkill(boss_fuchou)
SHAMBLO:addSkill(boss_miehou)
SHAMBLO:addSkill(boss_qiangnian)

SHAMBLO_skin1 = sgs.General(extension, "SHAMBLO_skin1", "ZEON", 8, false, true, true)
ZAKU_I_ST = sgs.General(extension, "ZAKU_I_ST", "", 0, true, true, true)
ZAKU_I_ST:setGender(sgs.General_Neuter)
--total hide boss
sgs.LoadTranslationTable{
	["boss"] = "BOSS",
	["restart_mini?"] = "重玩此局？",
	["restart_mini"] = "重玩",
	["next_mini"] = "下一局",
	["#_mini_5_skill"] = "<b><font color='yellow'>剧情效果</font></b>：由于未出现双方均发动“<b><font color='yellow'>明镜止水</font></b>”的状态，%to 继续战斗！<br>%from 得到了 %arg 枚 <b><font color='yellow'>怒</font></b> 标记，胜利后可额外获得 %arg2 枚G币",
	
	["burste"] = "灭绝爆发",
	[":burste"] = "<span style=\"background-color: #581a1d\"><font color='#eb8f1e'><b>灭绝爆发(Extinct Burst)：</b></span></font><b>[BOSS专用]</b>结束阶段开始时，60%机率消耗3点能量，令至少一名其他角色失去1点体力。",
	
	["SHAMBLO"] = "尚布罗",
	["#SHAMBLO"] = "重力的井底",
	["~SHAMBLO"] = "",
	["designer:SHAMBLO"] = "高达杀制作组",
	["cv:SHAMBLO"] = "罗妮·贾维",
	["illustrator:SHAMBLO"] = "wch5621628",
	["boss_juao"] = "巨螯",
	[":boss_juao"] = "当你使用武器牌后，你可以对所有距离1的角色各造成1点伤害。",
	["boss_fuchou"] = "复仇",
	[":boss_fuchou"] = "当你指定或成为【射击】的唯一目标时，若存活的其他角色有3名或以上，你可以弃置一张相同花色的牌作为反射镜，令此【射击】于所有其他角色中随机转移5次，然后你弃置最终目标一张牌。", -- 此设计是为了用神杀的指示线模拟光束不断反射的画面233
	["@boss_fuchou"] = "请弃置一张相同花色的牌发动技能“复仇”",
	["boss_miehou"] = "灭吼",
	[":boss_miehou"] = "<b><font color='red'>充能技，</font></b>出牌阶段限一次，你可以消耗6点充能点数，视为你使用【酒】并对所有其他角色使用【杀】。",
	["boss_miehou_card"] = "灭吼",
	["boss_qiangnian"] = "强念",
	[":boss_qiangnian"] = "<img src=\"image/mark/@boss_qiangnian.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时，若你的体力为4或更低，或有角色已发动<b>“NT-D”</b>，你将体力上限减至4点，摸4张牌，补满6点充能点数，启动<span style=\"background-color: #581a1d\"><font color='#eb8f1e'><b>“灭绝爆发”</b></span></font>。",
	["SHAMBLO_skin1"] = "尚布罗",
	["ZAKU_I_ST"] = "渣古I狙击型",
}
