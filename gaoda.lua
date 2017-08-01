module("extensions.gaoda", package.seeall)
extension=sgs.Package("gaoda")
--extension = sgs.Package("gaoda", sgs.Package_GeneralPack)

--高达杀胆创功能（true:开启, false:关闭）
animation = true --萌妹纸动画
auto_bgm = true --自动切换BGM
auto_backdrop = true --自动切换起始背景
gg_effect = true --阵亡特效
opening = true --开场对白
dlc = true --武将解锁系统（每5场游戏解锁1名隐藏武将）+记录胜率
map_attack = true --地图炮系统（5~7人场：1人持有|8~9人场：2人持有|10人场：3人持有。地图炮持有者为随机分配，受到第1点伤害后显示能量槽，之后每受到1点伤害后便增加1点能量，满5点能量可发炮，每名角色每场只可发炮一次，各高达系列的地图炮效果有所不同。）
burst_system = true --爆发系统（每造成1点伤害后，获得1点爆发能量。每受到1点伤害后，获得2点爆发能量。若爆发能量达到9点，爆发能量不再增加，并随机获得一种爆发状态。出牌阶段，你可以进入相应的爆发状态，直到爆发能量耗尽。）
show_winrate = true --显示胜率（颜神黑科技基础，在武将一览的高达杀武将第一行前可见）
g_skin = true --皮肤系统（暂仅限主将换肤）
lucky_card = true --扭蛋、彩蛋模式（游戏开始时随机选定一张游戏牌，当玩家使用同名同花色同点数的牌时，获得一枚金币并播放妖梦gif）
zy_system = false --昼夜系统（60%常|20%昼：判定牌♣视为♦|20%夜：判定牌♥视为♠）

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

if file_exists("extensions/GScenarios.lua") then
	require "extensions.GScenarios" --[[高达杀剧情模式（通关可以获得一枚高达杀金币（G币），用作扭蛋。
										开启剧情模式：1. 双击EnableGScenarios.bat	2. 打开游戏并选择对应的X人场
										关闭剧情模式：1.关闭游戏 2. 双击DisableGScenarios.bat）]]
	if GScenarios and sgs.Sanguosha:translate("gaoda") == "gaoda" then
		sgs.Alert("高达杀剧情模式已启动")
	end
end

gdata = "g.lua"
g2data = "g2.lua"

do
    require  "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	config.kingdoms = { "EFSF", "SLEEVE", "OMNI", "ZAFT", "ORB", "CB", "TEKKADAN", "OTHERS"--[[, "wei", "shu", "wu", "qun", "god"]] }
	config.kingdom_colors = {
		EFSF = "#547998",
        SLEEVE = "#96943D",
		OMNI = "#3cc451",
		ZAFT = "#FF0000",
		ORB = "#feea00",
		CB = "#7097df",
		TEKKADAN = "#d80000",
        OTHERS = "#8A807A",
		wei = "#547998",
		shu = "#D0796C",
		wu = "#4DB873",
		qun = "#8A807A",
		god = "#96943D"
	}
end

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
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

--[[function getWinRate(name)
	require("g")
	local f = loadstring("return "..name)
	local rate = f()
	if tostring(rate) == "-1.#IND" then
		return "未知"
	end
	local round = function(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	rate = round(rate*100)
	return rate
end]]--broadcast after gamefinished

function resumeHuaShen(target)--BUG Resolver
	local room = target:getRoom()
	local json = require ("json")
	for _,player in sgs.qlist(room:getAlivePlayers()) do
		if player:hasSkill("huimie") and (player:getGeneralName() == "UNICORN" or player:getGeneral2Name() == "UNICORN") then
			local general = sgs.Sanguosha:getGeneral("UNICORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"huimie",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		elseif player:hasSkill("baosang") and (player:getGeneralName() == "BANSHEE" or player:getGeneral2Name() == "BANSHEE") then
			local general = sgs.Sanguosha:getGeneral("BANSHEE_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"baosang",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		elseif player:hasSkill("zuzhou") and (player:getGeneralName() == "NORN" or player:getGeneral2Name() == "NORN") then
			local general = sgs.Sanguosha:getGeneral("NORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"zuzhou",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		elseif player:getMark("jingxin") > 0 and (player:getGeneralName() == "SHINING" or player:getGeneral2Name() == "SHINING") then
			local general = sgs.Sanguosha:getGeneral("SHINING_S")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"jingxin",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
	end
end

--[[function CardList2IntList(cards)
	local ids = sgs.IntList()
	for _,card in sgs.qlist(cards) do
		ids:append(card:getId())
	end
	return ids
end

function IntList2CardList(ids)
	local cards = sgs.CardList()
	for _,id in sgs.qlist(ids) do
		cards:append(sgs.Sanguosha:getCard(id))
	end
	return cards
end]]-- Useful functions

--===============↓↓For FA_UNICORN Use↓↓===============--
hasEquipArea = function(player, name)
	if (name == "treasure" and (Set(sgs.Sanguosha:getBanPackages()))["limitation_broken"] and (Set(sgs.Sanguosha:getBanPackages()))["gundamcard"])
	or player:getMark(name.."AreaRemoved") > 0 then
		return false
	end
	return true
end

removeEquipArea = function(player, name)
	if hasEquipArea(player, name) then
		local room = player:getRoom()
		room:setPlayerMark(player, name.."AreaRemoved", 1)
		local classname
		if name == "defensive_horse" then classname = "DefensiveHorse"
		elseif name == "offensive_horse" then classname = "OffensiveHorse"
		else classname = name:gsub("^%l", string.upper) end
		room:setPlayerCardLimitation(player, "use", classname.."$0", false)
		local equips = {"weapon", "armor", "defensive_horse", "offensive_horse", "treasure"}
		for i = 1, 5, 1 do
			if name == equips[i] and player:getEquip(i-1) then
				room:throwCard(player:getEquip(i-1), nil)
				break
			end
		end
		local log = sgs.LogMessage()
		log.type = "#RemoveEquipArea"
		log.from = player
		log.arg = name
		room:sendLog(log)
	end
end

removeWholeEquipArea = function(player)
	local equips = {"weapon", "armor", "defensive_horse", "offensive_horse", "treasure"}
	for _,equip in ipairs(equips) do
		removeEquipArea(player, equip)
	end
end

blankEquipArea = function(player)
	if hasEquipArea(player, "weapon") or hasEquipArea(player, "armor") or hasEquipArea(player, "defensive_horse")
	or hasEquipArea(player, "offensive_horse") or hasEquipArea(player, "treasure") then
		return false
	end
	return true
end

equipprohibit = sgs.CreateProhibitSkill
{
	name = "#equipprohibit",
	is_prohibited = function(self, from, to, card)
		if to and card:isKindOf("EquipCard") and (not hasEquipArea(to, card:getSubtype()))  then
			return true
		end
	end
}
--===============↑↑For FA_UNICORN Use↑↑===============--

--【阵亡特效】
gdsrule = sgs.CreateTriggerSkill{
	name = "gdsrule",
	events = {sgs.GameOverJudge--[[,sgs.GameStart]]},
	global = true,
	can_trigger = function(self, player)
		return gg_effect
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.GameOverJudge then
	    local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			if death.damage and death.damage.from and string.find(death.damage.from:getGeneralName(), "FREEDOM") then
				if string.find(death.who:getGeneralName(), "PROVIDENCE") then
					room:doLightbox("image=image/animate/FREEDOM_PROVIDENCE.png", 1000)
				elseif string.find(death.who:getGeneralName(), "SAVIOUR") then
					room:doLightbox("image=image/animate/FREEDOM_SAVIOUR.png", 1000)
				end
			elseif ((death.damage and death.damage.from and death.damage.from:getGeneralName() == "IMPULSE") or death.who:hasFlag("IMPULSE_FREEDOM"))
				and string.find(death.who:getGeneralName(), "FREEDOM") then
				room:doLightbox("image=image/animate/IMPULSE_FREEDOM.png", 1000)
			end
			if file_exists("image/generals/card/"..death.who:getGeneralName()..".jpg") then
				room:doLightbox(("image=image/generals/card/%s.jpg"):format(death.who:getGeneralName()), 0500)
			end
			if sgs.Sanguosha:translate("~"..death.who:getGeneralName()) ~= "~"..death.who:getGeneralName() and
				sgs.Sanguosha:translate("~"..death.who:getGeneralName()) ~= "" then
				room:doLightbox("~"..death.who:getGeneralName(), 1000)
			end
		end
	end
	--[[if event == sgs.GameStart then
	    if player:getPhase() == sgs.Player_Play then return false end
	    if player:getGeneral():getPackage() ~= "gaoda" then
		    local changelist = {}
		    local all = sgs.Sanguosha:getLimitedGeneralNames()
			for _,name in ipairs(all) do
		        if sgs.Sanguosha:getGeneral(name):getPackage() == "gaoda" and not table.contains(changelist,name) then
				    table.insert(changelist,name)
				end
			end
			local rand = math.random(1,#changelist)
			room:changeHero(player, changelist[rand], true, true, false, false)
			room:setPlayerProperty(player, "kingdom", sgs.QVariant(sgs.Sanguosha:getGeneral(changelist[rand]):getKingdom()))
		end
	end]]
	end
}

--【萌妹纸动画】
gdsvoice = sgs.CreateTriggerSkill{
	name = "gdsvoice",
	events = {sgs.AfterDrawInitialCards, sgs.EventPhaseStart, sgs.ChoiceMade},
	global = true,
	can_trigger = function(self, player)
	    return animation == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		math.random()
	if event == sgs.AfterDrawInitialCards then
	    if player:getState() ~= "robot" then
			room:setPlayerFlag(player, "skip_anime")
			local choice = {"seshia", "meiling", "yuudachi"}
			room:setPlayerProperty(player, "emotion", sgs.QVariant(choice[math.random(3)]))
			local emotion = player:property("emotion"):toString()
			if emotion == "seshia" then
				room:broadcastSkillInvoke("gdsvoice",math.random(1,4))
			elseif emotion == "meiling" then
			    room:broadcastSkillInvoke("gdsvoice",math.random(5,8))
			elseif emotion == "yuudachi" then
			    room:broadcastSkillInvoke("gdsvoice",math.random(9,13))
			end
			local json = require("json")
			local jsonValue = {
			player:objectName(),
			emotion
			}
			local wholist = sgs.SPlayerList()
            wholist:append(player)
			room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			resumeHuaShen(player)
        end
	end
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
			room:setEmotion(player,"light")
    	    if player:getState() ~= "robot" and math.random(1,10) <= 7 and not player:hasFlag("skip_anime") then
			    local emotion = player:property("emotion"):toString()
				if emotion == "seshia" then
				    room:broadcastSkillInvoke("gdsvoice",math.random(1,4))
			    elseif emotion == "meiling" then
			        room:broadcastSkillInvoke("gdsvoice",math.random(5,8))
				elseif emotion == "yuudachi" then
					room:broadcastSkillInvoke("gdsvoice",math.random(9,13))
			    end
			    local json = require("json")
				local jsonValue = {
				player:objectName(),
				emotion
				}
				local wholist = sgs.SPlayerList()
				wholist:append(player)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
				resumeHuaShen(player)
            end
		end
		if player:getPhase() == sgs.Player_Finish then
		    room:setEmotion(player,"dark")
		end
	end
	if event == sgs.ChoiceMade then
	    if player:getState() ~= "robot" and math.random(1,10) == 1 then
		    local emotion = player:property("emotion"):toString()
		    if emotion == "seshia" then
				room:broadcastSkillInvoke("gdsvoice",math.random(2,4))
			elseif emotion == "meiling" then
			    room:broadcastSkillInvoke("gdsvoice",math.random(6,8))
			elseif emotion == "yuudachi" then
				room:broadcastSkillInvoke("gdsvoice",math.random(9,13))
			end
			local json = require("json")
			local jsonValue = {
			player:objectName(),
			emotion
			}
			local wholist = sgs.SPlayerList()
			wholist:append(player)
			room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			resumeHuaShen(player)
        end
	end
	end,
}

--【自动切换BGM】
changeBGM = function(name)
	sgs.SetConfig("BackgroundMusic", "audio/system/"..name..".ogg")
end

generalName2BGM = function(name)
	math.random()
	local bgms = {
		{"BGM0", "IIVS"},
		{"BGM1", "HARUTE", "ELSQ", "00QFS"},
		{"BGM2", "CAG"},
		{"BGM"..math.random(5, 6), "BUILD_BURNING"},
		{"BGM7", "DESTINY", "SP_DESTINY"},
		{"BGM8", "IMPULSE", "SAVIOUR"},
		{"BGM9", "UNICORN", "UNICORN_NTD", "FA_UNICORN", "KSHATRIYA", "SINANJU", "ReZEL", "DELTA_PLUS", "BANSHEE", "NORN", "PHENEX"},
		{"BGM10", "FREEDOM", "FREEDOM_D"},
		{"BGM11", "WZ", "EPYON"},
		{"BGM12", "WZC", "DSH", "HAC", "SANDROCK", "ALTRON"},
		{"BGM13", "GINN", "STRIKE", "AEGIS", "BUSTER", "DUEL_AS", "BLITZ", "BLITZ_Y"},
		{"BGM14", "REBORNS_CANNON", "REBORNS_GUNDAM"},
		{"BGM15", "EX_S"},
		{"BGM16", "DX"},
		{"BGM17", "JUSTICE"},
		{"BGM18", "CFR"},
		{"BGM19", "PROVIDENCE"},
		{"BGM20", "EXIA_R"},
		{"BGM21", "SBS", "DARK_MATTER"},
		{"BGM22", "HYAKU_SHIKI"},
		{"BGM23", "BARBATOS"},
		{"BGM24", "GUNDAM"},
		{"BGM25", "SHINING"},
		{"BGM26", "DESTROY", "AKATSUKI", "IJ", "LEGEND"},
		{"BGM27", "SF"},
		{"BGM28", "LUPUS", "REX"},
		{"BGM29", "STRIKE_NOIR"}
	}
	for _,bgm in ipairs(bgms) do
		if table.contains(bgm, name) and file_exists("audio/system/"..bgm[1]..".ogg") then
			return bgm[1]
		end
	end
	local n = -1
	for i = 0, 998, 1 do
		if file_exists("audio/system/BGM"..i..".ogg") then
			n = i
		else
			break
		end
	end
	if n == -1 then return "background" end
	return "BGM"..math.random(0, n)
end

gdsbgm = sgs.CreateTriggerSkill{
	name = "gdsbgm",
	events = {sgs.GameStart},
	global = true,
	priority = 3,
	can_trigger = function(self, player)
	    return auto_bgm == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = global_room
		if room:getTag("gdsbgm"):toBool() then return false end
		room:setTag("gdsbgm", sgs.QVariant(true))
		local name = generalName2BGM(room:getLord():getGeneralName())
		changeBGM(name)
		local ip = room:getOwner():getIp()
		if ip ~= "" and string.find(ip, "127.0.0.1") and room:getMode() ~= "06_3v3" then --联机状态时切换BGM无效
			if name == "background" then name = "BGM0" end
			if dlc then
				local log = sgs.LogMessage()
				log.type = "#BGM"
				log.arg = name
				room:sendLog(log)
			else
				room:doLightbox(name, 1000, 50)
			end
		end
	end
}
--[[bgm = {"0","0"}
gdsbgm = sgs.CreateTriggerSkill{
	name = "gdsbgm",
	events = {sgs.ChoiceMade,sgs.DrawInitialCards},
	global = true,
	can_trigger = function(self, player)
	    return auto_bgm == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if (event == sgs.ChoiceMade or event == sgs.DrawInitialCards) then
			local BGM_No = math.random(1,3)
			local t = os.clock()
			if t >= tonumber(bgm[1]) + tonumber(bgm[2]) then
				table.removeOne(bgm,bgm[1])
				table.insert(bgm,1,""..t.."")
				if BGM_No == 1 then
					table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"140")
					room:broadcastSkillInvoke("gdsbgm",1)
				elseif BGM_No == 2 then
					table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"203")
					room:broadcastSkillInvoke("gdsbgm",2)
				elseif BGM_No == 3 then
				    table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"177")
					room:broadcastSkillInvoke("gdsbgm",3)
				end
			end
	    end
	end,
}]]

--【自动切换起始背景】
if auto_backdrop then
	--[[os.remove("backdrop/default.jpg")
	local no = math.random(1,4)
	os.execute("copy change/default"..no..".jpg backdrop")
	os.rename("backdrop/default"..no..".jpg", "backdrop/default.jpg")
	os.execute太危险了(＞﹏＜)]]
    math.random() --傲娇的lua随机数，要我用挫计来骗他
	local n = 0
	for i = 1, 998, 1 do
		if file_exists("image/system/backdrop/new-version"..i..".jpg") then
			n = i
		else
			break
		end
	end
	local index = math.random(n)
	if n == 0 then index = "" end
	sgs.SetConfig("BackgroundImage", "image/system/backdrop/new-version"..index..".jpg")
end

--【开场对白】
if opening then
    math.random()
	local month = os.date("%m")
	if month == "01" or month == "02" then
		sgs.Sanguosha:playAudioEffect("audio/system/ny"..math.random(3)..".ogg", false)
	else
		sgs.Sanguosha:playAudioEffect("audio/system/op"..math.random(3)..".ogg", false)
	end
end

--【武将解锁系统】
if dlc then
	--file = assert(io.open(gdata, "r"), "在根目录创建一个空的g.lua档案即可解决问题poi")
	local file = io.open(gdata, "r")
	t = {}
	if file ~= nil then
		t = file:read("*all"):split("\n")
		file:close()
	end
end

saveRecord = function(player, record_table, record_type) --record_type: 0. +1 gameplay , 1. +1 win , 2. +1 win & +1 gameplay
	assert(record_type >= 0 and record_type <= 2, "record_type should be 0, 1 or 2")
	local tt = record_table
	local win = {}
	local times = {}
	for id,item in pairs(tt) do
		local s = item:split("=")
		tt[id] = s[1]
		local pr = s[2]:split("/")
		table.insert(win, tonumber(pr[1]))
		table.insert(times, tonumber(pr[2]))
	end
	if not table.contains(tt, "GameTimes") then
		table.insert(tt, "GameTimes")
		table.insert(win, 0)
		table.insert(times, 0)
	end
	local all = sgs.Sanguosha:getLimitedGeneralNames()
	for _,name in pairs(all) do
		if sgs.Sanguosha:getGeneral(name):getPackage() == "gaoda" and not table.contains(tt, name) then
			table.insert(tt, name)
			table.insert(win, 0)
			table.insert(times, 0)
		end
	end
	local record2 = assert(io.open(gdata, "w"))
	for d,text in pairs(tt) do
		local m = win[d]
		local n = times[d]
		
		local name = player:getGeneralName()
		local skin_id =  string.find(name, "_skin") --皮肤武将使用原名记录胜率(g_skin)
		if skin_id then
			name = string.sub(name, 1, skin_id - 1)
		end
		
		local name2 = ""
		if player:getGeneral2() then
			name2 = player:getGeneral2Name()
			local skin_id2 =  string.find(name2, "_skin")
			if skin_id2 then
				name2 = string.sub(name2, 1, skin_id2 - 1)
			end
		end
		
		if text == "GameTimes" or name == text or (name2 ~= "" and name2 == text and name ~= name2) then
			if record_type ~= 0 then -- record_type 1 or 2
				m = m + 1
			end
			if record_type ~= 1 then -- record_type 0 or 2
				n = n + 1
			end
		end
		
		local input = text.."="..tostring(m).."/"..tostring(n)
		t[d] = input
		record2:write(input)
		if d ~= #tt then
			record2:write("\n")
		end
	end
	record2:close()
end

gdsrecordcard = sgs.CreateSkillCard{
	name = "gdsrecord",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, use)
	end
}

gdsrecordvs = sgs.CreateZeroCardViewAsSkill{
	name = "gdsrecord",
	response_pattern = "@@gdsrecord!",
	view_as = function(self)
		if not sgs.Self:hasFlag("gdata_saved") then
			sgs.Self:setFlags("gdata_saved")
			local file = io.open(gdata, "r")
			local tt = {}
			if file ~= nil then
				tt = file:read("*all"):split("\n")
				file:close()
			end
			saveRecord(sgs.Self, tt, sgs.Self:getMark("record_type"))
		end
		return gdsrecordcard:clone()
	end
}

gdsrecord = sgs.CreateTriggerSkill{
--[[Rule: 1. single mode +1 gameplay when game STARTED & +1 win (if win) when game FINISHED;
		2. online mode +1 gameplay & +1 win (if win) simultaneously when game FINISHED;
		3. single mode escape CAN +1 gameplay, online mode escape CANNOT +1 gameplay;
		4. +1 win (if win) when game FINISHED (no escape);
		5. online mode trust when game FINISHED CANNOT +1 neither gameplay nor win
		
	规则：1. 单机模式在游戏开始时+1游玩次数 & 在游戏结束时+1胜利次数（如果胜利）；
		2. 联机模式在游戏结束时同时+1游玩次数 & +1胜利次数（如果胜利）；
		3. 单机模式逃跑可以+1游玩次数，联机模式逃跑则不能+1游玩次数；
		4. 游戏结束时依然存在的玩家（没有逃跑）才会+1胜利次数（如果胜利）；
		5. 联机模式在游戏结束时托管的玩家不会记录游玩次数和胜利次数
]]
	name = "gdsrecord",
	events = {sgs.DrawInitialCards, sgs.GameOverJudge},
	global = true,
	view_as_skill = gdsrecordvs,
	can_trigger = function(self, player)
	    return dlc == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if event == sgs.DrawInitialCards then
			if player:getMark("@coin") > 0 then return false end
			if player:objectName() == room:getOwner():objectName() then
				local ip = room:getOwner():getIp()
				if ip ~= "" and string.find(ip, "127.0.0.1") then
					saveRecord(room:getOwner(), t, 0)
				end
			end
		else
			if room:getMode() == "04_boss" and player:isLord()
				and sgs.GetConfig("BossModeEndless", false) or room:getTag("BossModeLevel"):toInt() < sgs.GetConfig("BossLevel", 0) - 1 then
					return false
				end
			if room:getMode() == "02_1v1" then
				local list = player:getTag("1v1Arrange"):toStringList()
				local rule = sgs.GetConfig("1v1/Rule", "2013")
				local n = 0
				if rule == "2013" then n = 3 end
				if list:length() > n then return false end
			end

			local winner = getWinner(player) -- player is victim
			if winner ~= "" then
				local ip = room:getOwner():getIp()
				if ip ~= "" and string.find(ip, "127.0.0.1") then
					if string.find(winner, room:getOwner():getRole()) or string.find(winner, room:getOwner():objectName()) then
						saveRecord(room:getOwner(), t, 1)
					end
				else
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if p:getState() == "online" then
							if string.find(winner, p:getRole()) or string.find(winner, p:objectName()) then
								room:setPlayerMark(p, "record_type", 2)
							end
							room:askForUseCard(p, "@@gdsrecord!", "@gdsrecord")
							room:setPlayerFlag(p, "-gdata_saved")
							room:setPlayerMark(p, "record_type", 0)
						end
					end
				end
			end
		end
	end
}

--【地图炮系统】
mapcard = sgs.CreateSkillCard{
	name = "map",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "@map5", 0)
		room:detachSkillFromPlayer(source, "map", true)
		if source:getKingdom() == "OMNI" or source:getKingdom() == "ZAFT" or source:getKingdom() == "ORB" then
			local log = sgs.LogMessage()
			log.type = "#map"
			log.from = source
			log.arg = "map2"
			room:sendLog(log)
			room:broadcastSkillInvoke("maprecord", 2)
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"map2"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:getThread():delay(1500)
			for _,q in ipairs(targets) do
				room:loseHp(q, 2)
			end
		elseif source:getKingdom() == "CB" or source:getGeneralName():startsWith("REBORNS") then
			local log = sgs.LogMessage()
			log.type = "#map"
			log.from = source
			log.arg = "map3"
			room:sendLog(log)
			room:broadcastSkillInvoke("maprecord", 3)
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"map3"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:getThread():delay(1500)
			for _,q in ipairs(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), nil, q, 2, sgs.DamageStruct_Fire))
			end
		else
			local log = sgs.LogMessage()
			log.type = "#map"
			log.from = source
			log.arg = "map1"
			room:sendLog(log)
			room:broadcastSkillInvoke("maprecord", 1)
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"map1"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:getThread():delay(1500)
			for _,q in ipairs(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), nil, q, 2, sgs.DamageStruct_Thunder))
			end
		end
		resumeHuaShen(source)
	end
}

map = sgs.CreateZeroCardViewAsSkill{
	name = "map&",
	view_as = function(self)
		return mapcard:clone()
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@map5") == 1
	end
}

maprecord = sgs.CreateTriggerSkill{
	name = "maprecord",
	events = {sgs.AfterDrawInitialCards, sgs.Damaged},
	priority = 3,
	global = true,
	can_trigger = function(self, player)
	    return map_attack == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AfterDrawInitialCards then
			if player:objectName() ~= room:getAllPlayers(true):first():objectName() then return false end
			math.random()
			local players = room:getAllPlayers()
			local num = players:length()
			if num < 5 or room:getMode() == "06_3v3" then return false end
			local p = players:at(math.random(0, num - 1))
			room:setPlayerMark(p, "map0", 1)
			if num >= 8 then
				players:removeOne(p)
				local q = players:at(math.random(0, num - 2))
				room:setPlayerMark(q, "map0", 1)
				if num >= 10 then
					players:removeOne(q)
					local r = players:at(math.random(0, num - 3))
					room:setPlayerMark(r, "map0", 1)
				end
			end
		else
			if player:getMark("@map5") == 1 then return false end
			local damage = data:toDamage()
			for i=1, damage.damage, 1 do
				if player:getMark("map0") == 1 then
					room:setPlayerMark(player, "map0", 0)
					room:setPlayerMark(player, "@map0", 1)
					room:attachSkillToPlayer(player, "map")
				elseif player:getMark("@map0") == 1 then
					room:setPlayerMark(player, "@map0", 0)
					room:setPlayerMark(player, "@map1", 1)
				elseif player:getMark("@map1") == 1 then
					room:setPlayerMark(player, "@map1", 0)
					room:setPlayerMark(player, "@map2", 1)
				elseif player:getMark("@map2") == 1 then
					room:setPlayerMark(player, "@map2", 0)
					room:setPlayerMark(player, "@map3", 1)
				elseif player:getMark("@map3") == 1 then
					room:setPlayerMark(player, "@map3", 0)
					room:setPlayerMark(player, "@map4", 1)
				elseif player:getMark("@map4") == 1 then
					room:broadcastSkillInvoke("gdsbgm", 2)
					room:setPlayerMark(player, "@map4", 0)
					room:setPlayerMark(player, "@map5", 1)
				else
					break
				end
			end
		end
	end
}

--【爆发系统】
burstacard = sgs.CreateSkillCard{
	name = "bursta",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "@bursta", 0)
		room:setPlayerMark(source, "@bursta9", 1)
		local log = sgs.LogMessage()
		log.type = "#BGM"
		log.arg = ":bursta"
		room:sendLog(log)
		room:detachSkillFromPlayer(source, "bursta", true)
		for _,p in sgs.qlist(room:getAllPlayers(true)) do
			local json = require("json")
			local jsonValue = {
			p:objectName(),
			"bursta"
			}
			local wholist = sgs.SPlayerList()
			wholist:append(p)
			room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
		end
		room:broadcastSkillInvoke("gdsbgm", 4)
		resumeHuaShen(source)
	end
}

bursta = sgs.CreateZeroCardViewAsSkill{
	name = "bursta&",
	view_as = function(self)
		return burstacard:clone()
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@bursta") == 1
	end
}

burstdcard = sgs.CreateSkillCard{
	name = "burstd",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "@burstd", 0)
		room:setPlayerMark(source, "@burstd9", 1)
		local log = sgs.LogMessage()
		log.type = "#BGM"
		log.arg = ":burstd"
		room:sendLog(log)
		room:detachSkillFromPlayer(source, "burstd", true)
		for _,p in sgs.qlist(room:getAllPlayers(true)) do
			local json = require("json")
			local jsonValue = {
			p:objectName(),
			"burstd"
			}
			local wholist = sgs.SPlayerList()
			wholist:append(p)
			room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
		end
		room:broadcastSkillInvoke("gdsbgm", 4)
		resumeHuaShen(source)
	end
}

burstd = sgs.CreateZeroCardViewAsSkill{
	name = "burstd&",
	view_as = function(self)
		return burstdcard:clone()
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@burstd") == 1
	end
}

burstpcard = sgs.CreateSkillCard{
	name = "burstp",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "@burstp", 0)
		room:setPlayerMark(source, "@burstp9", 1)
		local log = sgs.LogMessage()
		log.type = "#BGM"
		log.arg = ":burstp"
		room:sendLog(log)
		room:detachSkillFromPlayer(source, "burstp", true)
		for _,p in sgs.qlist(room:getAllPlayers(true)) do
			local json = require("json")
			local jsonValue = {
			p:objectName(),
			"burstp"
			}
			local wholist = sgs.SPlayerList()
			wholist:append(p)
			room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
		end
		room:broadcastSkillInvoke("gdsbgm", 4)
		resumeHuaShen(source)
	end
}

burstp = sgs.CreateZeroCardViewAsSkill{
	name = "burstp&",
	view_as = function(self)
		return burstpcard:clone()
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@burstp") == 1
	end
}

burstrecord = sgs.CreateTriggerSkill{
	name = "burstrecord",
	events = {sgs.Damage, sgs.Damaged, sgs.DamageCaused, sgs.DamageInflicted, sgs.DrawNCards},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return burst_system == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if (event == sgs.Damage and damage.from and damage.from:objectName() == player:objectName()) or
			(event == sgs.Damaged and damage.to and damage.to:objectName() == player:objectName()) then
			if player:getTag("burst_end"):toBool() then return false end
			local n = 1
			if event == sgs.Damaged then n = 2 end
			for i = 1, damage.damage * n, 1 do
				if not player:getTag("burst"):toBool() then
					player:setTag("burst", sgs.QVariant(true))
					room:setPlayerMark(player, "@burst1", 1)
				elseif player:getMark("@burst1") == 1 then
					room:setPlayerMark(player, "@burst1", 0)
					room:setPlayerMark(player, "@burst2", 1)
				elseif player:getMark("@burst2") == 1 then
					room:setPlayerMark(player, "@burst2", 0)
					room:setPlayerMark(player, "@burst3", 1)
				elseif player:getMark("@burst3") == 1 then
					room:setPlayerMark(player, "@burst3", 0)
					room:setPlayerMark(player, "@burst4", 1)
				elseif player:getMark("@burst4") == 1 then
					room:setPlayerMark(player, "@burst4", 0)
					room:setPlayerMark(player, "@burst5", 1)
				elseif player:getMark("@burst5") == 1 then
					room:setPlayerMark(player, "@burst5", 0)
					room:setPlayerMark(player, "@burst6", 1)
				elseif player:getMark("@burst6") == 1 then
					room:setPlayerMark(player, "@burst6", 0)
					room:setPlayerMark(player, "@burst7", 1)
				elseif player:getMark("@burst7") == 1 then
					room:setPlayerMark(player, "@burst7", 0)
					room:setPlayerMark(player, "@burst8", 1)
				elseif player:getMark("@burst8") == 1 then
					player:setTag("burst_end", sgs.QVariant(true))
					room:broadcastSkillInvoke("gdsbgm", 2)
					room:setPlayerMark(player, "@burst8", 0)
					local types = {"a", "d", "p"}
					local name = types[math.random(3)]
					room:setPlayerMark(player, "@burst"..name, 1)
					room:attachSkillToPlayer(player, "burst"..name)
				else
					break
				end
			end
		elseif event == sgs.DamageCaused and damage.from and damage.from:objectName() == player:objectName() then
			if player:getMark("@bursta9") == 0 and player:getMark("@bursta6") == 0 and player:getMark("@bursta3") == 0 then return false end
			local n = math.random(100)
			if n <= 30 then
				room:sendCompulsoryTriggerLog(player, "bursta")
				local log = sgs.LogMessage()
				log.type = "#bursta"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg = damage.damage
				log.arg2 = damage.damage + 1
				room:sendLog(log)
				if player:getMark("@bursta9") == 1 then
					room:setPlayerMark(player, "@bursta9", 0)
					room:setPlayerMark(player, "@bursta6", 1)
				elseif player:getMark("@bursta6") == 1 then
					room:setPlayerMark(player, "@bursta6", 0)
					room:setPlayerMark(player, "@bursta3", 1)
				elseif player:getMark("@bursta3") == 1 then
					room:setPlayerMark(player, "@bursta3", 0)
				end
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted and damage.to and damage.to:objectName() == player:objectName() then
			if player:getMark("@burstd9") == 0 and player:getMark("@burstd6") == 0 and player:getMark("@burstd3") == 0 then return false end
			local n = math.random(100)
			if n <= 30 then
				room:sendCompulsoryTriggerLog(player, "burstd")
				local log = sgs.LogMessage()
				log.type = "#burstd"
				log.to:append(damage.to)
				log.arg = damage.damage
				log.arg2 = damage.damage - 1
				room:sendLog(log)
				if player:getMark("@burstd9") == 1 then
					room:setPlayerMark(player, "@burstd9", 0)
					room:setPlayerMark(player, "@burstd6", 1)
				elseif player:getMark("@burstd6") == 1 then
					room:setPlayerMark(player, "@burstd6", 0)
					room:setPlayerMark(player, "@burstd3", 1)
				elseif player:getMark("@burstd3") == 1 then
					room:setPlayerMark(player, "@burstd3", 0)
				end
				damage.damage = damage.damage - 1
				if damage.damage < 1 then
					room:setEmotion(player, "skill_nullify")
					return true
				end
				data:setValue(damage)
			end
		elseif event == sgs.DrawNCards and room:getCurrent():objectName() == player:objectName() then
			if player:getMark("@burstp9") == 0 and player:getMark("@burstp6") == 0 and player:getMark("@burstp3") == 0 then return false end
			local n = math.random(100)
			if n <= 30 then
				room:sendCompulsoryTriggerLog(player, "burstp")
				local log = sgs.LogMessage()
				log.type = "#burstp"
				log.from = player
				log.arg = 1
				room:sendLog(log)
				if player:getMark("@burstp9") == 1 then
					room:setPlayerMark(player, "@burstp9", 0)
					room:setPlayerMark(player, "@burstp6", 1)
				elseif player:getMark("@burstp6") == 1 then
					room:setPlayerMark(player, "@burstp6", 0)
					room:setPlayerMark(player, "@burstp3", 1)
				elseif player:getMark("@burstp3") == 1 then
					room:setPlayerMark(player, "@burstp3", 0)
				end
				local num = data:toInt()
				num = num + 1
				data:setValue(num)
			end 
		else
			return false
		end
	end
}

--【显示胜率】（续页底）
if show_winrate then
	winshow = sgs.General(extension, "winshow", "", 0, true, true, false)
	winshow:setGender(sgs.General_Sexless)
	winrate = sgs.CreateMasochismSkill{
		name = "winrate",
		on_damaged = function() 
		end
	}
	winshow:addSkill(winrate)
end

--【皮肤系统】（续页底）
if g_skin then
	g_skin_cp = {
		{"FREEDOM", "FREEDOM_skin1"},
		{"JUSTICE", "JUSTICE_skin1"},
		{"PROVIDENCE", "PROVIDENCE_skin1", "PROVIDENCE_skin2"},
		{"SAVIOUR", "SAVIOUR_skin1"},
		{"BARBATOS", "BARBATOS_skin1"},
		{"LUPUS", "LUPUS_skin1"},
		{"REX", "REX_skin1"}
	}
end
	
skincard = sgs.CreateSkillCard{
	name = "skin",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, use)
		local source = use.from
		local name = source:getGeneralName()
		local convert = {}
		for _,cp in ipairs(g_skin_cp) do
			if table.contains(cp, name) then
				convert = cp
				break
			end
		end
		local general_name = room:askForGeneral(source, table.concat(convert, "+"))
		if general_name and table.contains(convert, general_name) then
			--room:changeHero(source, general_name, false, false, false, false)
			room:setPlayerProperty(source, "general", sgs.QVariant(general_name))
		end
		
		if source:getGeneral2() then
			local name2 = source:getGeneral2Name()
			local convert2 = {}
			for _,cp2 in ipairs(g_skin_cp) do
				if table.contains(cp2, name2) then
					convert2 = cp2
					break
				end
			end
			local general_name2 = room:askForGeneral(source, table.concat(convert2, "+"))
			if general_name2 and table.contains(convert2, general_name2) then
				room:setPlayerProperty(source, "general2", sgs.QVariant(general_name2))
			end
		end
	end
}

skin = sgs.CreateZeroCardViewAsSkill{
	name = "skin&",
	view_as = function(self)
		return skincard:clone()
    end,
	enabled_at_play = function(self, player)
		return true
	end
}

skinrecord = sgs.CreateTriggerSkill{
	name = "skinrecord",
	events = {sgs.AfterDrawInitialCards, sgs.BeforeGameOverJudge},
	priority = 3,
	global = true,
	can_trigger = function(self, player)
	    return g_skin == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AfterDrawInitialCards then
			for _,cp in ipairs(g_skin_cp) do
				if cp[1] == player:getGeneralName() or cp[1] == player:getGeneral2Name() then
					room:attachSkillToPlayer(player, "skin")
					break
				end
			end
		else
			local name = player:getGeneralName()
			local skin_id =  string.find(name, "_skin")
			if skin_id then
				name = string.sub(name, 1, skin_id - 1)
				--room:changeHero(player, name, false, false, false, false)
				room:setPlayerProperty(player, "general", sgs.QVariant(name))
			end
			
			if player:getGeneral2() then
				local name2 = player:getGeneral2Name()
				local skin_id2 =  string.find(name2, "_skin")
				if skin_id2 then
					name2 = string.sub(name2, 1, skin_id2 - 1)
					room:setPlayerProperty(player, "general2", sgs.QVariant(name2))
				end
			end
		end
	end
}

--【扭蛋、彩蛋模式】（续页底）
if lucky_card then
	itemshow = sgs.General(extension, "itemshow", "", 0, true, true, false)
	itemshow:setGender(sgs.General_Sexless)
	
	itemnumcard = sgs.CreateSkillCard{
		name = "itemnum",
		target_fixed = true,
		will_throw = false,
		handling_method = sgs.Card_MethodNone,
		about_to_use = function(self, room, use)
			room:removePlayerMark(use.from, "@coin")
			room:setEmotion(use.from, "capsule")
			room:broadcastSkillInvoke("gdsbgm", 7)
			room:getThread():delay(3700)
			room:broadcastSkillInvoke("gdsbgm", 9)
			room:doLightbox("image=image/generals/card/BARBATOS_skin1.jpg", 1500)
		end
	}

	itemnumvs = sgs.CreateZeroCardViewAsSkill{
		name = "itemnum",
		view_as = function(self)
			return itemnumcard:clone()
		end,
		enabled_at_play = function(self, player)
			return player:getMark("@coin") > 0
		end
	}
	
	itemnum = sgs.CreateTriggerSkill{
		name = "itemnum",
		events = {sgs.DrawInitialCards, sgs.DrawNCards, sgs.EventPhaseEnd},
		view_as_skill = itemnumvs,
		global = true,
		priority = 3,
		can_trigger = function(self, player)
			return lucky_card == true
		end,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.DrawInitialCards then
				local ip = room:getOwner():getIp()
				if ip ~= "" and string.find(ip, "127.0.0.1") and player:objectName() == room:getOwner():objectName()
					and file_exists("extensions/GScenarios.lua") and file_exists(g2data) and player:getGameMode() == "02p" then
					require "extensions.GScenarios"
					require "g2"
					if GScenarios and Coin ~= nil and Coin > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
						player:throwAllMarks()
						player:clearPrivatePiles()
						room:changeHero(player, "itemshow", false, false, false, false)
						room:setPlayerMark(player, "@coin", Coin)
						room:setPlayerProperty(player, "role", sgs.QVariant("unknown"))
						room:setPlayerProperty(player, "kingdom", sgs.QVariant("OTHERS"))
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							p:throwAllMarks()
							p:clearPrivatePiles()
							room:changeHero(p, "itemshow", false, false, false, false)
							room:setPlayerProperty(p, "alive", sgs.QVariant(false))
							room:setPlayerProperty(p, "role", sgs.QVariant("unknown"))
							room:setPlayerProperty(p, "kingdom", sgs.QVariant("OTHERS"))
							room:doBroadcastNotify(sgs.CommandType.S_COMMAND_KILL_PLAYER, sgs.QVariant(p:objectName()))
						end
						data:setValue(0)
					end
				end
			elseif event == sgs.DrawNCards then
				if player:getMark("@coin") > 0 then
					data:setValue(0)
				end
			else
				if player:getGeneralName() == "itemshow" and player:getPhase() == sgs.Player_Play then
					room:gameOver(".")
				end
			end
		end
	}
	
	itemshow:addSkill(itemnum)
end

saveItem = function(item_type, num)
	local file = io.open(g2data, "r")
	local tt = {}
	if file ~= nil then
		tt = file:read("*all"):split("\n")
		file:close()
	end
	
	local record = assert(io.open(g2data, "w"))
    local n = 0
    for _,item in pairs(tt) do
        local s = item:split("=")
		if s[1] == item_type then
			n = tonumber(s[2])
			break
		end
    end
    record:write(item_type .. "=" .. (n + num))
    record:close()
end

luckyrecordcard = sgs.CreateSkillCard{
	name = "luckyrecord",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, use)
	end
}

luckyrecordvs = sgs.CreateZeroCardViewAsSkill{
	name = "luckyrecord",
	response_pattern = "@@luckyrecord!",
	view_as = function(self)
		if not sgs.Self:hasFlag("g2data_saved") then
			sgs.Self:setFlags("g2data_saved")
			saveItem("Coin", 1)
		end
		return luckyrecordcard:clone()
	end
}

luckyrecord = sgs.CreateTriggerSkill{
	name = "luckyrecord",
	events = {sgs.AfterDrawInitialCards, sgs.CardUsed, sgs.CardResponded},
	priority = 3,
	global = true,
	view_as_skill = luckyrecordvs,
	can_trigger = function(self, player)
	    return lucky_card == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AfterDrawInitialCards then
			if player:objectName() ~= room:getAllPlayers(true):first():objectName() or room:getOwner():getMark("@coin") > 0 then return false end
			local id = sgs.Sanguosha:getRandomCards():first()
			room:setTag("lucky_card", sgs.QVariant(id))
			local log = sgs.LogMessage()
			log.type = "#lucky_card"
			log.card_str = sgs.Sanguosha:getCard(id):toString()
			room:sendLog(log)
		else
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				local id = room:getTag("lucky_card"):toInt()
				local lcard = sgs.Sanguosha:getCard(id)
				if card:objectName() == lcard:objectName() and card:getSuit() == lcard:getSuit() and card:getNumber() == lcard:getNumber() then
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						local json = require("json")
						local jsonValue = {
						p:objectName(),
						"yomeng"
						}
						local wholist = sgs.SPlayerList()
						wholist:append(p)
						room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
					end
					local log = sgs.LogMessage()
					log.type = "#coin"
					log.from = player
					log.arg = 1
					room:sendLog(log)
					room:broadcastSkillInvoke("gdsbgm", 7)
					
					local ip = room:getOwner():getIp()
					if ip ~= "" and string.find(ip, "127.0.0.1") and player:objectName() == room:getOwner():objectName() then
						saveItem("Coin", 1)
					else
						if player:getState() == "online" then
							room:askForUseCard(player, "@@luckyrecord!", "@luckyrecord")
							room:setPlayerFlag(player, "-g2data_saved")
						end
					end
				end
			end
		end
	end
}

--【昼夜系统】
zyrecord = sgs.CreateTriggerSkill{
	name = "zyrecord",
	events = {sgs.AfterDrawInitialCards, sgs.FinishRetrial},
	priority = 3,
	global = true,
	can_trigger = function(self, player)
	    return zy_system == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AfterDrawInitialCards then
			if player:objectName() ~= room:getAllPlayers(true):first():objectName() then return false end
			math.random()
			local n = math.random(5)
			if n == 1 then
				room:doSuperLightbox("sun", "sun")
				local log = sgs.LogMessage()
				log.type = "#sun"
				room:sendLog(log)
				room:setTag("zy_system", sgs.QVariant("zy_system_z"))
			elseif n == 2 then
				room:doSuperLightbox("moon", "moon")
				local log = sgs.LogMessage()
				log.type = "#moon"
				room:sendLog(log)
				room:setTag("zy_system", sgs.QVariant("zy_system_y"))
			end
		else
			local judge = data:toJudge()
			local zy = room:getTag("zy_system"):toString()
			if zy == nil or zy == "" then return false end
			if zy == "zy_system_z" then --♣视为♦
				if judge.card:getSuit() == sgs.Card_Club then
					local new_card = sgs.Sanguosha:getWrappedCard(judge.card:getId())
					new_card:setSkillName(zy)
					new_card:setSuit(sgs.Card_Diamond)
					new_card:setModified(true)
					judge.card = new_card
					judge:updateResult()
					
					room:broadcastUpdateCard(room:getAllPlayers(true), judge.card:getId(), new_card)
					local log = sgs.LogMessage()
					log.type = "#FilterJudge"
					log.from = player
					log.arg = zy
					room:sendLog(log)
				end
			elseif zy == "zy_system_y" then --♥视为♠
				if judge.card:getSuit() == sgs.Card_Heart then
					local new_card = sgs.Sanguosha:getWrappedCard(judge.card:getId())
					new_card:setSkillName(zy)
					new_card:setSuit(sgs.Card_Spade)
					new_card:setModified(true)
					judge.card = new_card
					judge:updateResult()
					
					room:broadcastUpdateCard(room:getAllPlayers(true), judge.card:getId(), new_card)
					local log = sgs.LogMessage()
					log.type = "#FilterJudge"
					log.from = player
					log.arg = zy
					room:sendLog(log)
				end
			end
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("gdsrule") then skills:append(gdsrule) end
if not sgs.Sanguosha:getSkill("gdsvoice") then skills:append(gdsvoice) end
if not sgs.Sanguosha:getSkill("gdsbgm") then skills:append(gdsbgm) end
if not sgs.Sanguosha:getSkill("#equipprohibit") then skills:append(equipprohibit) end
if not sgs.Sanguosha:getSkill("gdsrecord") then skills:append(gdsrecord) end
if not sgs.Sanguosha:getSkill("map") then skills:append(map) end
if not sgs.Sanguosha:getSkill("maprecord") then skills:append(maprecord) end
if not sgs.Sanguosha:getSkill("bursta") then skills:append(bursta) end
if not sgs.Sanguosha:getSkill("burstd") then skills:append(burstd) end
if not sgs.Sanguosha:getSkill("burstp") then skills:append(burstp) end
if not sgs.Sanguosha:getSkill("burstrecord") then skills:append(burstrecord) end
if not sgs.Sanguosha:getSkill("skin") then skills:append(skin) end
if not sgs.Sanguosha:getSkill("skinrecord") then skills:append(skinrecord) end
if not sgs.Sanguosha:getSkill("luckyrecord") then skills:append(luckyrecord) end
if not sgs.Sanguosha:getSkill("zyrecord") then skills:append(zyrecord) end
sgs.Sanguosha:addSkills(skills)

IIVS = sgs.General(extension, "IIVS", "OTHERS", 4, true, false)

yuexiancard=sgs.CreateSkillCard{
    name="yuexian",
    target_fixed=true,
    will_throw=false,
on_use=function(self, room, source, targets)
    local jihuo = {"rishi","yihua","shensheng"}
	if source:getMark("@rishi") == 1 or (not source:hasSkill("rishi")) then
		table.removeOne(jihuo,"rishi")
	end
	if source:getMark("@yihua") == 1 or (not source:hasSkill("yihua")) then
		table.removeOne(jihuo, "yihua")
	end
	if source:getMark("@shensheng") == 1 or (not source:hasSkill("shensheng")) then
		table.removeOne(jihuo, "shensheng")
	end
    local choice = room:askForChoice(source, self:objectName(), table.concat(jihuo,"+"), sgs.QVariant())
	if choice then
		if choice == "rishi" then
			room:broadcastSkillInvoke("yuexian", 1)
		elseif choice == "yihua" then
			room:broadcastSkillInvoke("yuexian", 2)
		elseif choice == "shensheng" then
			room:broadcastSkillInvoke("yuexian", 3)
		end
	    source:gainMark("@point")
	    --room:acquireSkill(source, choice)
		room:setPlayerMark(source, "@"..choice,1)
		local log = sgs.LogMessage()
		log.from = source
        log.type = "#yuexian"
        log.arg = choice
        room:sendLog(log)
	end
	if source:getMark("@point") >=3 then
	    source:loseAllMarks("@point")
		local log = sgs.LogMessage()
		log.from = source
        log.type = "#point"
        log.arg = "#IIVSp"
        room:sendLog(log)
	    room:setPlayerMark(source, "yuexian",2)
		room:setEmotion(source, "yuexian")
	end
end,
}

yuexian=sgs.CreateViewAsSkill{
    name="yuexian",
    n=0,
view_as=function(self, cards)
    local acard=yuexiancard:clone()
    acard:setSkillName(self:objectName())
    return acard
end,
enabled_at_play=function(self,player)
    return player:getMark("yuexian") ~= 1 and ((player:getMark("@rishi") == 0 and player:hasSkill("rishi"))
		or (player:getMark("@yihua") == 0 and player:hasSkill("yihua")) or (player:getMark("@shensheng") == 0 and player:hasSkill("shensheng")))
end,
enabled_at_response=function(self,player,pattern) 
    return false 
end,
}

yuexianmark=sgs.CreateTriggerSkill{
	name="#yuexianmark",
	events={sgs.TurnStart, sgs.PreCardUsed},
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.TurnStart then
			if player:getMark("yuexian") > 0 then
				room:removePlayerMark(player, "yuexian", 1)
			end
			--room:handleAcquireDetachSkills(player, "-rishi|-yihua|-shensheng")
			room:setPlayerMark(player,"@rishi",0)
			room:setPlayerMark(player,"@yihua",0)
			room:setPlayerMark(player,"@shensheng",0)
		else
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "yuexian" then
				return true
			end
		end
	end,
}

rishi = sgs.CreateTriggerSkill{
	name = "rishi",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark("@rishi") == 0 then return false end
		local use = data:toCardUse()
	    if use.card and use.card:getSkillName() ~= "yihua" and use.card:getSkillName() ~= "shensheng" and ((use.card:isKindOf("Slash") or use.card:isKindOf("SingleTargetTrick")) and use.to:length() > 1) or (use.card:isKindOf("IronChain") and use.to:length() > 2) then
		    room:broadcastSkillInvoke("rishi")
		end
	end,
}

rishiv = sgs.CreateTargetModSkill{
	name = "#rishiv",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player and player:getMark("@rishi") == 1 then
			return 1
		end
	end,
	distance_limit_func = function(self, player)
		if player and player:getMark("@rishi") == 1 then
			return 998
		end
	end
}

yihua = sgs.CreateTriggerSkill{
	name = "yihua",
	events = {sgs.PostCardEffected,sgs.PreCardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark("@yihua") == 0 then return false end
		if event == sgs.PostCardEffected then
			local effect = data:toCardEffect()
			if effect.card:isNDTrick() and effect.from:objectName() ~= player:objectName() and room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
				player:drawCards(1)
				if player:canSlash(effect.from, false) then
					room:setPlayerFlag(player,"yihua")
					room:askForUseSlashTo(player, effect.from, "#yihua", false)
				end
			end
			room:setPlayerFlag(player,"-yihua")
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and (not use.card:isKindOf("FireSlash")) and player:hasFlag("yihua") then
				room:setPlayerFlag(player,"-yihua")
				local fslash = sgs.Sanguosha:cloneCard("fire_slash",use.card:getSuit(),use.card:getNumber())
				fslash:addSubcard(use.card)
				fslash:setSkillName(self:objectName())
				use.card = fslash
				data:setValue(use)
				room:setEmotion(player, "fire_slash")
			end
		end
	end
}

shenshengvs = sgs.CreateViewAsSkill{
	name = "shensheng",
	n = 0,
	view_as = function(self, cards)
	    local id = sgs.Sanguosha:getCard(sgs.Self:getMark("shensheng"))
		local acard = sgs.Sanguosha:cloneCard(id:objectName(), id:getSuit(), id:getNumber())
		acard:setSkillName("shensheng")
		acard:addSubcard(id)
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern)
		return pattern == "@@shensheng"
	end
}

shensheng = sgs.CreateTriggerSkill{
	name = "shensheng",
	events = {sgs.TargetConfirmed},
	view_as_skill = shenshengvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark("@shensheng") == 0 then return false end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) and room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
			local show = room:getNCards(2)
			room:fillAG(show)
			for i=0,1,1 do
				local cd = show:at(i)
				local card = sgs.Sanguosha:getCard(cd)
				if card:isKindOf("EquipCard") then
					local choice = room:askForChoice(player, self:objectName(), "ssuse+ssobtain", sgs.QVariant(""..card:getId()))
					if choice == "ssuse" then
						room:useCard(sgs.CardUseStruct(card, player, player))
					elseif choice == "ssobtain" then
						room:obtainCard(player,cd)
					end
				else
					if card:isKindOf("Jink") or card:isKindOf("Nullification") or (card:isKindOf("Peach") and not player:isWounded()) then
						room:obtainCard(player,cd)
					else
						room:setPlayerMark(player,"shensheng",card:getId())
						local scard = sgs.Sanguosha:getCard(player:getMark("shensheng"))
						local use = room:askForUseCard(player, "@@shensheng", ("#shensheng:%s:%s:%s:%s"):format(scard:objectName(),scard:getSuitString(),scard:getNumber(),scard:getEffectiveId()))
						if use then
						else
							room:obtainCard(player,cd)
						end
					end
				end
			end
			room:clearAG()
			room:setPlayerMark(player,"shensheng",0)
		end
	end
}

IIVS:addSkill(yuexian)
IIVS:addSkill(yuexianmark)
IIVS:addSkill(rishi)
IIVS:addSkill(rishiv)
IIVS:addSkill(yihua)
IIVS:addSkill(shensheng)
--[[local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("rishi") then skills:append(rishi) end
if not sgs.Sanguosha:getSkill("#rishiv") then skills:append(rishiv) end
if not sgs.Sanguosha:getSkill("yihua") then skills:append(yihua) end
if not sgs.Sanguosha:getSkill("shensheng") then skills:append(shensheng) end
sgs.Sanguosha:addSkills(skills)
IIVS:addRelateSkill("rishi")
IIVS:addRelateSkill("yihua")
IIVS:addRelateSkill("shensheng")]]
extension:insertRelatedSkills("rishi", "#rishiv")

GUNDAM = sgs.General(extension, "GUNDAM", "EFSF", 4, true, false)

yuanzu = sgs.CreateTriggerSkill{
	name = "yuanzu",
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameStart or
			(event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or
			(event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
			local skilllist = {}
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				for _,skill in sgs.qlist(p:getVisibleSkillList()) do
					local name = skill:objectName()
					if not table.contains(skilllist, name) and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Wake and
						not skill:isLordSkill() and not skill:isAttachedLordSkill() and name ~= "yuanzu" and name ~= "jidong" then
						table.insert(skilllist, name)
					end
				end
			end
			if #skilllist ~= 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local yuanzuskill = player:property("yuanzu"):toString()
					if yuanzuskill then
						room:detachSkillFromPlayer(player, yuanzuskill)
						room:setPlayerProperty(player, "yuanzu", sgs.QVariant())
					end
					local skill
					if #skilllist >= 14 and not player:getAI() then
						local first = {}
						local second = {}
						for i,s in ipairs(skilllist) do
							if i <= #skilllist/2 then
								table.insert(first, s)
								if i == math.floor(#skilllist/2) then
									table.insert(first, "gnext")
								end
							else
								table.insert(second, s)
								if i == #skilllist then
									table.insert(second, "gprevious")
								end
							end
						end
						::yuanzu_retry::
						local choice1 = room:askForChoice(player, self:objectName(), table.concat(first, "+"))
						if choice1 and choice1 ~= "gnext" then
							skill = choice1
						else
							local choice2 = room:askForChoice(player, self:objectName(), table.concat(second, "+"))
							if choice2 and choice2 ~= "gprevious" then
								skill = choice2
							else
								goto yuanzu_retry
							end
						end
					else
						skill = room:askForChoice(player, self:objectName(), table.concat(skilllist, "+"))
					end
					if skill then
						room:setPlayerProperty(player, "yuanzu", sgs.QVariant(skill))
						local target = room:findPlayerBySkillName(skill)
						room:setEmotion(target, "judgegood")
						room:acquireSkill(player, skill)
						local json = require ("json")
						local jsonValue = {
							10,
							player:objectName(),
							"GUNDAM",
							skill,
						}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					end
				end
			end
		end
	end
}

GUNDAM:addSkill(yuanzu)

UNICORN = sgs.General(extension, "UNICORN", "EFSF", 4, true, false)

shenshou = sgs.CreateTriggerSkill{
	name = "shenshou",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if player:objectName() == use.from:objectName() and use.card:isKindOf("Slash") and use.card:isRed() and
	room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke("shenshou")
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local acard = room:askForCard(p, ".|red|.|.", "@@shenshou:"..player:getGeneralName(), data, sgs.Card_MethodNone, player, false, self:objectName(), true)
			if acard then
				player:obtainCard(acard)
			    return false
			else
				jink_table[index] = 0
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
	end,
}

NTD = sgs.CreateTriggerSkill
{
	name = "NTD",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and player:getHp() < 3 and
		player:getMark("@NTD") == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			--[[if auto_bgm then
				room:getThread():trigger(sgs.NonTrigger, room, player, sgs.QVariant("audio/system/bgm_uc.ogg"))
			end]]
			room:broadcastSkillInvoke("NTD")
			room:doLightbox("image=image/animate/NTD.png", 1500)
			room:setEmotion(player, "NTD")
			room:getThread():delay(2700)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("UNICORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"huimie",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			player:gainMark("@NTD")
			room:setPlayerMark(player, "NTD", 1)
			room:loseMaxHp(player)
			if not player:isKongcheng() then
				local n = 0
				local handcards = player:handCards()
				room:fillAG(handcards)
				for _,h in sgs.qlist(handcards) do
					if sgs.Sanguosha:getCard(h):isRed() then
						n = n + 1
					end
				end
				if n > 0 then
					for i=1, n ,1 do
						if player:isWounded() then
							local choice = room:askForChoice(player, self:objectName(), "ntdrecover+ntddraw")
							if choice == "ntdrecover" then
								local recover = sgs.RecoverStruct()
								recover.recover = 1
								recover.who = player
								room:recover(player,recover)
							else
								room:drawCards(player, 1)
							end
						else
							room:drawCards(player, 1)
						end
					end
				else
					room:getThread():delay(1500)
				end
				room:clearAG()
			end
			room:acquireSkill(player,"huimie")
			use.to = sgs.SPlayerList()
			data:setValue(use)
		end
	end,
}

huimievs = sgs.CreateZeroCardViewAsSkill{
	name = "huimie",
	view_as = function(self)
	    local pattern = sgs.Self:property("hmuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName("huimiecard")
		return acard
    end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@huimie"
	end,
}

huimie = sgs.CreateTriggerSkill
{
	name = "huimie",
	events = {sgs.TargetConfirming},
	view_as_skill = huimievs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and (not player:isKongcheng())
		and room:askForSkillInvoke(player, self:objectName(), data) then
			local red = room:askForCard(player, ".|red|.|hand", "@huimie:"..use.card:objectName(), data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false)
			if red then
				room:broadcastSkillInvoke("huimie")
				local acard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
				if acard:isAvailable(player) then
					if use.card:objectName() == "ex_nihilo" or use.card:objectName() == "amazing_grace"
					or use.card:objectName() == "savage_assault" or use.card:objectName() == "archery_attack"
					or use.card:objectName() == "god_salvation" then
						local u = sgs.CardUseStruct()
						local acard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1)
						acard:setSkillName("huimiecard")
						u.card = acard
						u.from = player
						room:useCard(u)
					else
						room:setPlayerProperty(player, "hmuse", sgs.QVariant(use.card:objectName()))
						room:askForUseCard(player, "@@huimie", "#huimie:"..use.card:objectName())
						room:setPlayerProperty(player, "hmuse", sgs.QVariant())
					end
				end
				use.to = sgs.SPlayerList()
				data:setValue(use)
			end
		end
	end
}

quanwu = sgs.CreateTriggerSkill
{
	name = "quanwu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@NTD") > 0 and player:getEquips():length() >= 3 then
			room:broadcastSkillInvoke("quanwu")
			room:doLightbox("image=image/animate/quanwu.png", 1500)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:setPlayerMark(player, "quanwu", 1)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("FA_UNICORN")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			room:setPlayerMark(player, "@NTD", 0)
			room:changeHero(player, "FA_UNICORN", false, true, player:getGeneralName() ~= "UNICORN", true)
		end
	end
}

UNICORN:addSkill(shenshou)
UNICORN:addSkill(quanwu)
UNICORN:addSkill(NTD)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("huimie") then skills:append(huimie) end
sgs.Sanguosha:addSkills(skills)
UNICORN:addRelateSkill("huimie")

UNICORN_NTD = sgs.General(extension, "UNICORN_NTD", "EFSF", 4, true, true, true)
UNICORN_NTD:addSkill("shenshou")
UNICORN_NTD:addSkill("quanwu")
UNICORN_NTD:addSkill("NTD")
UNICORN_NTD:addRelateSkill("huimie")

FA_UNICORN = sgs.General(extension, "FA_UNICORN", "EFSF", 3, true, false)

zhonggongcard = sgs.CreateSkillCard{
	name = "zhonggong",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local choices = {}
		if hasEquipArea(effect.from, "weapon") then table.insert(choices, "weapon") end
		if hasEquipArea(effect.from, "armor") then table.insert(choices, "armor") end
		if hasEquipArea(effect.from, "defensive_horse") then table.insert(choices, "defensive_horse") end
		if hasEquipArea(effect.from, "offensive_horse") then table.insert(choices, "offensive_horse") end
		if hasEquipArea(effect.from, "treasure") then table.insert(choices, "treasure") end
		local choice = room:askForChoice(effect.from, "zhonggong", table.concat(choices, "+"), sgs.QVariant())
		removeEquipArea(effect.from, choice)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}

zhonggong = sgs.CreateZeroCardViewAsSkill{
	name = "zhonggong",
	view_as = function()
	    local acard = zhonggongcard:clone()
		acard:setSkillName("zhonggong")
		return acard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#zhonggong")) and (not blankEquipArea(player))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

qingzhuang = sgs.CreateTriggerSkill{
	name = "qingzhuang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
	    if blankEquipArea(player) and effect.card:isRed() and effect.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("qingzhuang")
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = "qingzhuang_redslash"
			room:sendLog(log)
			return true
		end
	end
}

qingzhuangdistance = sgs.CreateDistanceSkill{
    name = "#qingzhuangdistance",
    correct_func = function(self, from, to)
		if from:hasSkill("qingzhuang") and blankEquipArea(from) then
			return -2
		end
    end
}

linguangcard = sgs.CreateSkillCard{
	name = "linguang",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@linguang")
		room:doSuperLightbox("FA_UNICORN", "linguang")
		room:recover(source, sgs.RecoverStruct(source))
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			p:turnOver()
		end
		removeWholeEquipArea(source)
		room:acquireSkill(source, "#linguangfilter", false)
		room:filterCards(source, source:getCards("he"), false)
	end
}

linguangvs = sgs.CreateZeroCardViewAsSkill{
	name = "linguang",
	view_as = function()
	    local acard = linguangcard:clone()
		acard:setSkillName("linguang")
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@linguang") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

linguang = sgs.CreateTriggerSkill{
	name = "linguang",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart},
	view_as_skill = linguangvs,
	on_trigger = function(self, event, player, data)
		if player:getMark("@linguang") == 0 then
			player:gainMark("@linguang")
		end
	end
}

linguangfilter = sgs.CreateFilterSkill{
	name = "#linguangfilter",
	view_filter = function(self, card)
		return card:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}

FA_UNICORN:addSkill(zhonggong)
FA_UNICORN:addSkill(qingzhuang)
FA_UNICORN:addSkill(qingzhuangdistance)
FA_UNICORN:addSkill(linguang)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#linguangfilter") then skills:append(linguangfilter) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("qingzhuang", "#qingzhuangdistance")

KSHATRIYA = sgs.General(extension, "KSHATRIYA", "SLEEVE", 4, false, false)

qingyuvs = sgs.CreateViewAsSkill{
	name = "qingyu",
	n = 0,
	view_as = function(self, cards)
	if sgs.Self:getMark("qingyuspade") > 0 then
		local acard = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_Spade, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyuheart") > 0 then
		local acard = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_Heart, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyuclub") > 0 then
		local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_Club, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyudiamond") > 0 then
		local acard = sgs.Sanguosha:cloneCard("snatch", sgs.Card_Diamond, -1)
		acard:setSkillName("qingyu")
		return acard
	else return nil
	end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern)
		return pattern == "@@qingyu"
	end
}

qingyuspade = {}
qingyuheart = {}
qingyuclub = {}
qingyudiamond = {}
qingyu = sgs.CreateTriggerSkill{
	name = "qingyu",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.PreCardUsed},
	view_as_skill = qingyuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and player:getPhase() == sgs.Player_Discard and move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
					table.insert(qingyuspade,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
				    table.insert(qingyuheart,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club then
				    table.insert(qingyuclub,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
				    table.insert(qingyudiamond,id)
				end
			end
		end
	elseif event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Discard and
		(#qingyuspade > 0 or #qingyuheart > 0 or #qingyuclub > 0 or #qingyudiamond > 0)
		and room:askForSkillInvoke(player, self:objectName(), data) then
		local show = sgs.IntList()
		for _,a in ipairs(qingyuspade) do
		    show:append(a)
		end
		for _,b in ipairs(qingyuheart) do
		    show:append(b)
		end
		for _,c in ipairs(qingyuclub) do
		    show:append(c)
		end
		for _,d in ipairs(qingyudiamond) do
		    show:append(d)
		end
		room:fillAG(show)
			if #qingyuspade > 0 and player:isAlive() then
			    room:setPlayerMark(player, "qingyuspade", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu1")
				room:setPlayerMark(player, "qingyuspade", 0)
			end
			if #qingyuheart > 0 and player:isAlive() then
			    room:setPlayerMark(player, "qingyuheart", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu2")
				room:setPlayerMark(player, "qingyuheart", 0)
			end
			if #qingyuclub > 0 and player:isAlive() then
			    room:setPlayerMark(player, "qingyuclub", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu3")
				room:setPlayerMark(player, "qingyuclub", 0)
			end
			if #qingyudiamond > 0 and player:isAlive() then
			    room:setPlayerMark(player, "qingyudiamond", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu4")
				room:setPlayerMark(player, "qingyudiamond", 0)
			end
		end
			while #qingyuspade > 0 do
				table.remove(qingyuspade)
			end
			while #qingyuheart > 0 do
				table.remove(qingyuheart)
			end
			while #qingyuclub > 0 do
				table.remove(qingyuclub)
			end
			while #qingyudiamond > 0 do
				table.remove(qingyudiamond)
			end
			room:clearAG()
	elseif event == sgs.PreCardUsed then
	    local use = data:toCardUse()
		if use.card:subcardsLength() == 0 and use.card:getSkillName() == "qingyu" then
		    if use.card:isKindOf("SavageAssault") then
			    for _,e in ipairs(qingyuspade) do
		            use.card:addSubcard(e)
		        end
			elseif use.card:isKindOf("ArcheryAttack") then
			    for _,f in ipairs(qingyuheart) do
		            use.card:addSubcard(f)
		        end
			elseif use.card:isKindOf("Dismantlement") then
			    for _,g in ipairs(qingyuclub) do
		            use.card:addSubcard(g)
		        end
			elseif use.card:isKindOf("Snatch") then
			    for _,h in ipairs(qingyudiamond) do
		            use.card:addSubcard(h)
		        end
			end
			data:setValue(use)
		else return false
		end
	end
	end
}

siyicard = sgs.CreateSkillCard{
	name = "siyi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:hasFlag("siyitarget") and #targets < player:getEquips():length()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerFlag(effect.to,"siyiflag")
		local log = sgs.LogMessage()
		log.type = "$siyilog"
		log.from = effect.from
		log.to:append(effect.to)
		room:sendLog(log)
	end
}

siyivs = sgs.CreateZeroCardViewAsSkill{
	name = "siyi" ,
	view_as = function()
	    local acard = siyicard:clone()
		acard:setSkillName("siyi")
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@siyi"
	end
}

siyi = sgs.CreateTriggerSkill{
	name = "siyi",
	events = {sgs.TargetSpecifying, sgs.CardUsed, sgs.PreCardUsed},
	view_as_skill = siyivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if (use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect"))
			and player:hasEquip() and use.to:length() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				for _,c in sgs.qlist(use.to) do
					room:setPlayerFlag(c,"siyitarget")
				end
				if use.card:isKindOf("AOE") then
					room:askForUseCard(player, "@@siyi", "#siyi1")
				else
					room:askForUseCard(player, "@@siyi", "#siyi2")
				end
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerFlag(p,"-siyitarget")
					if p:hasFlag("siyiflag") then
						room:setPlayerFlag(p,"-siyiflag")
						use.to:removeOne(p)
					end
				end
			end
			data:setValue(use)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("SingleTargetTrick") and use.to:length() > 1) or (use.card:isKindOf("IronChain") and use.to:length() > 2) then
				room:broadcastSkillInvoke("siyi")
			end
		else
			local n = player:getEquips():length()
			if n == 0 then return false end
			::siyi_loop::
			n = n - 1
			local use = data:toCardUse()
			if use.card:isKindOf("Collateral") then
				local available_targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
					if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
						available_targets:append(p)
					end
				end
				
				if available_targets:isEmpty() or not room:askForSkillInvoke(player, self:objectName(), data) then return false end
				
				local tos = {}
				for _,t in sgs.qlist(use.to) do
					table.insert(tos, t:objectName())
				end
				
				room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
				room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
				room:askForUseCard(player, "@@qiaoshui!", "@qiaoshui-add:::collateral")
				
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if (p:hasFlag("ExtraCollateralTarget")) then
						room:setPlayerFlag(p, "-ExtraCollateralTarget")
						extra = p
						break
					end
				end
				
				if (extra == nil) then					
					extra = available_targets:at(math.random(available_targets:length()) - 1)
					local victims = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(extra)) do
						if (extra:canSlash(p) and not (p:objectName() == player:objectName() and p:hasSkill("kongcheng") and p:isLastHandCard(use.card, true))) then
							victims:append(p)
						end
					end
					
					if victims:isEmpty() then return false end
					
					local _data = sgs.QVariant()
					_data:setValue(victims:at(math.random(victims:length()) - 1))
					extra:setTag("collateralVictim", _data)
				end

                use.to:append(extra)
                room:sortByActionOrder(use.to)

                local log = sgs.LogMessage()
                log.type = "#QiaoshuiAdd"
                log.from = player
                log.to:append(extra)
                log.card_str = use.card:toString()
                log.arg = self:objectName()
                room:sendLog(log)
				
                room:doAnimate(1, player:objectName(), extra:objectName())
				
                local victim = extra:getTag("collateralVictim"):toPlayer()
				if (victim) then
					local log = sgs.LogMessage()
					log.type = "#CollateralSlash"
					log.from = player
					log.to:append(victim)
					room:sendLog(log)
					
					room:doAnimate(1, extra:objectName(), victim:objectName())
				end
				
				room:setPlayerProperty(player, "extra_collateral", sgs.QVariant())
				room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant())
				
				data:setValue(use)
				
				if available_targets:length() > 1 and n > 0 then
					goto siyi_loop
				end
			end
		end
	end
}

siyiadd = sgs.CreateTargetModSkill{
	name = "#siyiadd",
	pattern = "TrickCard+^DelayedTrick",
	extra_target_func = function(self, player)
	if player and player:hasSkill("siyi") and player:hasEquip() then
		return (player:getEquips():length())
	end
	end
}

KSHATRIYA:addSkill(qingyu)
KSHATRIYA:addSkill(siyi)
KSHATRIYA:addSkill(siyiadd)
extension:insertRelatedSkills("siyi", "#siyiadd")

SINANJU = sgs.General(extension, "SINANJU", "SLEEVE", 4, true, false)

xiaya = sgs.CreateViewAsSkill{
	name = "xiaya",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:setSkillName(self:objectName())
			jink:addSubcard(card:getId())
			return jink
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

zaishi = sgs.CreateTriggerSkill{
	name = "zaishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
			room:broadcastSkillInvoke("zaishi")
			local n = 0
			data:setValue(0)
			while player:isAlive() do
				room:fillAG(player:handCards())
				room:getThread():delay(700)
				if n >= 4 then break end
				local red = 0
				for _,cd in sgs.qlist(player:handCards()) do
					if sgs.Sanguosha:getCard(cd):isRed() then
						red = red + 1
					end
				end
				if red >= 3 then break end
				player:drawCards(1)
				n = n + 1
			end
			for i = 1, n+1, 1 do
				room:clearAG()
			end
		end
	end
}

wangling = sgs.CreateTriggerSkill{
	name = "wangling",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	    local skilllist = {}
		for _,skill in sgs.qlist(player:getVisibleSkillList()) do
			if skill:objectName() ~= "wangling" and (not skill:isAttachedLordSkill()) then
		        table.insert(skilllist,skill:objectName())
			end
		end
		if #skilllist == 1 then
		    if room:askForSkillInvoke(player,self:objectName(),data) then
			    room:broadcastSkillInvoke("wangling")
				room:detachSkillFromPlayer(player, skilllist[1], false, false)
				if damage.from then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
					slash:setSkillName("wanglingcard")
					local use = sgs.CardUseStruct()
					use.from = player
					use.to:append(damage.from)
					use.card = slash
					room:useCard(use,true)
				end
				return true
			end
		elseif #skilllist > 1 then
		    if room:askForSkillInvoke(player,self:objectName(),data) then
			    room:broadcastSkillInvoke("wangling")
			    local choice = room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
				if choice then
					room:detachSkillFromPlayer(player, choice, false, false)
					if damage.from then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
						slash:setSkillName("wanglingcard")
						local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(damage.from)
						use.card = slash
						room:useCard(use,true)
					end
				    return true
				end
			end
		elseif #skilllist == 0 then return false
		end
		while #skilllist > 0 do
		    table.remove(skilllist)
		end
	end
}

SINANJU:addSkill(xiaya)
SINANJU:addSkill(zaishi)
SINANJU:addSkill(wangling)

ReZEL = sgs.General(extension, "ReZEL", "EFSF", 4, true, false)

duilie = sgs.CreateTriggerSkill{
	name = "duilie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
		    for _,q in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(q,"@duilieA",0)
				room:setPlayerMark(q,"@duilieB",0)
				room:setPlayerMark(q,"@duilieC",0)
				room:setPlayerMark(q,"@duilieD",0)
		    end
			if room:askForSkillInvoke(player,self:objectName(),data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.good = true
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if math.mod(judge.card:getNumber(),2) == 1 then
					room:setPlayerMark(player,"@duilieA",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type = "#duilieA"
					room:sendLog(log)
				end
				if math.mod(judge.card:getNumber(),2) == 0 then
					room:setPlayerMark(player,"@duilieB",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieB"
					room:sendLog(log)
				end
				if judge:isGood() then
					room:setPlayerMark(player,"@duilieC",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieC"
					room:sendLog(log)
				else
					room:setPlayerMark(player,"@duilieD",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieD"
					room:sendLog(log)
				end
			end
		end
	end
	end,
}

duiliee = sgs.CreateTriggerSkill{
	name = "#duiliee",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardEffected, sgs.CardUsed, sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()   
	if event == sgs.CardEffected then
		local can_invoke = false
		for _,owner in sgs.qlist(room:getAlivePlayers()) do
			if owner:hasSkill("duilie") and owner:hasSkill("zhihui") then
				can_invoke = true
			end
		end
		if can_invoke == false then return false end
	    local effect = data:toCardEffect()
		if player:getMark("@duilieD") > 0 and effect.card:isRed() and (not effect.card:isKindOf("EquipCard")) and (not effect.card:isKindOf("SkillCard")) then
		    if room:askForSkillInvoke(player,"duilie",sgs.QVariant(string.format("draw:%s:%s", player:objectName(), self:objectName()))) then
		        player:drawCards(1)
			end
		end
		if player:getMark("@duilieB") > 0 and math.mod(effect.card:getNumber(),2) == 0 and effect.card:getNumber() > 0 and (not effect.card:isKindOf("EquipCard")) and (not effect.card:isKindOf("SkillCard")) then
			local log = sgs.LogMessage()
			log.from = player
			log.arg = "duilie"
			log.type = "#duilieBe"
			room:sendLog(log)
			return true
		end
	end
	if event == sgs.CardUsed then
	    local can_invoke = false
		for _,owner in sgs.qlist(room:getAlivePlayers()) do
			if owner:hasSkill("duilie") then
				can_invoke = true
			end
		end
		if can_invoke == false then return false end
	    local use = data:toCardUse()
		if player:getMark("@duilieC") > 0 and use.card:isBlack() and (not use.card:isKindOf("EquipCard")) and (not use.card:isKindOf("SkillCard")) then
		    for _,p in sgs.qlist(use.to) do
		        if (not p:isNude()) and room:askForSkillInvoke(player,"duilie",sgs.QVariant(string.format("throw:%s:%s", p:objectName(), self:objectName()))) then
				    local to_throw = room:askForCardChosen(player, p, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, p, player)
				end
			end
		end
	end
	if event == sgs.Death then
	    local death = data:toDeath()
		if death.who:hasSkill("zhihui") then
		    room:setPlayerMark(player,"@duilieA",0)
			room:setPlayerMark(player,"@duilieB",0)
			room:setPlayerMark(player,"@duilieC",0)
			room:setPlayerMark(player,"@duilieD",0)
		end
	end
	end,
}

duilied = sgs.CreateTargetModSkill{
	name = "#duilied",
	pattern = ".",
	distance_limit_func = function(self, player, card)
		local can_invoke = false
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("duilie") and p:hasSkill("zhihui") then
				can_invoke = true
			end
		end
		if player and player:getMark("@duilieA") > 0 and math.mod(card:getNumber(),2) == 1 and card:getNumber() > 0 and (can_invoke or player:hasSkill("duilie")) then
			return 998
		end
	end,
}

zhihui = sgs.CreateTriggerSkill{
	name = "zhihui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    local n = 0
	    local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				tos:append(p)
				n = n + 1
			end
		end
		if n == 0 then return false end
	    if player:getPhase() == sgs.Player_Start and (player:getMark("@duilieA") > 0 or player:getMark("@duilieB") > 0 or player:getMark("@duilieC") > 0 or player:getMark("@duilieD") > 0) and room:askForSkillInvoke(player,self:objectName(),data) then
			local target = room:askForPlayerChosen(player, tos, self:objectName(), "@@zhihui", true, true)
			if target then
			    room:acquireSkill(target, "#duiliee")
				if player:getMark("@duilieA") > 0 then
				    room:setPlayerMark(target,"@duilieA",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieA"
					room:sendLog(log)
				end
				if player:getMark("@duilieB") > 0 then
				    room:setPlayerMark(target,"@duilieB",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieB"
					room:sendLog(log)
				end
				if player:getMark("@duilieC") > 0 then
				    room:setPlayerMark(target,"@duilieC",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieC"
					room:sendLog(log)
				end
				if player:getMark("@duilieD") > 0 then
				    room:setPlayerMark(target,"@duilieD",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieD"
					room:sendLog(log)
				end
			end
		end
	end
	end,
}

ReZEL:addSkill(duilie)
ReZEL:addSkill(duiliee)
ReZEL:addSkill(duilied)
ReZEL:addSkill(zhihui)
extension:insertRelatedSkills("duilie", "#duiliee")
extension:insertRelatedSkills("duilie", "#duilied")

DELTA_PLUS = sgs.General(extension, "DELTA_PLUS", "EFSF", 4, true, false)

xiezhancard = sgs.CreateSkillCard{
	name = "xiezhan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if player:getWeapon() and player:getWeapon():getId() == card_id then
			local weapon = player:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif player:getOffensiveHorse() and player:getOffensiveHorse():getId() == card_id then
			range_fix = range_fix + 1
		end
		if #targets ~= 0 or to_select:objectName() == player:objectName() then return false end
		local card = sgs.Sanguosha:getCard(card_id)
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil and player:distanceTo(to_select, range_fix) <= player:getAttackRange() and sgs.Slash_IsAvailable(to_select) and hasEquipArea(to_select, card:getSubtype())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:objectName(), ""))
		local players = room:getOtherPlayers(effect.to)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitRed, 0)
		slash:setSkillName("xiezhancard")
		for _,p in sgs.qlist(players) do
			if p:isProhibited(p, slash) then
				players:removeOne(p)
			end
		end
		if players:isEmpty() then return false end
		local target = room:askForPlayerChosen(effect.from, players, self:objectName(), "@dummy-slash2:"..effect.to:objectName())
		if target then
			room:useCard(sgs.CardUseStruct(slash, effect.to, target), false)
		end
	end,
}

xiezhan = sgs.CreateOneCardViewAsSkill{
	name = "xiezhan",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
	    local acard = xiezhancard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}

tupovs = sgs.CreateZeroCardViewAsSkill{
	name = "tupo",
	view_as = function(self)
		local acard = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		local card = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
		return card:isAvailable(player) and (not player:hasFlag("tupo_used"))
	end,
}

tupo = sgs.CreateTriggerSkill{
	name = "tupo",
	events = {sgs.CardEffected, sgs.PostCardEffected, sgs.ChoiceMade},
	view_as_skill = tupovs,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardEffected or event == sgs.PostCardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Collateral") and effect.card:getSkillName() == "tupo" then
				if event == sgs.CardEffected then
					room:setPlayerFlag(player, "tupo_target")
				else
					if player:hasFlag("tupo_target") then
						room:setPlayerFlag(player, "-tupo_target")
					else
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("tupo_used") then
								local card = sgs.Sanguosha:getCard(player:getMark("tupo_id"))
								if card then
									room:useCard(sgs.CardUseStruct(card, p, p))
								end
								room:setPlayerMark(player, "tupo_id", 0)
								local players = room:getOtherPlayers(p)
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("tupocard")
								for _,q in sgs.qlist(players) do
									if q:isProhibited(q, slash) then
										players:removeOne(q)
									end
								end
								if not players:isEmpty() then
									local target = room:askForPlayerChosen(p, players, self:objectName(), "@dummy-slash")
									if target then
										room:useCard(sgs.CardUseStruct(slash, p, target), true)
									end
								end
								break
							end
						end
						room:loseHp(effect.from)
					end
				end
			end
		elseif event == sgs.ChoiceMade then
			if not player:hasFlag("tupo_target") then return false end
			local choice_data = data:toString():split(":")
			if choice_data[1] == "cardUsed" and choice_data[2] == "slash" and choice_data[3]:startsWith("collateral-slash") then
				room:setPlayerFlag(player, "-tupo_target")
				room:setPlayerMark(player, "tupo_id", player:getWeapon():getRealCard():getId())
			end
		end
	end,
}

tuporecord = sgs.CreateTriggerSkill{
	name = "#tuporecord",
	events = {sgs.CardUsed,  sgs.CardFinished},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Collateral") and use.card:getSkillName() == "tupo" then
			room:setPlayerFlag(player, "tupo_used")
		end
	end,
}

DELTA_PLUS:addSkill(xiezhan)
DELTA_PLUS:addSkill(tupo)
DELTA_PLUS:addSkill(tuporecord)
extension:insertRelatedSkills("tupo", "#tuporecord")

BANSHEE = sgs.General(extension, "BANSHEE", "EFSF", 4, false, false)

mengshi = sgs.CreateTriggerSkill{
	name = "mengshi",
	events = {sgs.TargetSpecified, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
				for _,p in sgs.qlist(use.to) do
					if p:hasEquip() and room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local to_return = room:askForCardChosen(player, p, "e", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(p, sgs.Sanguosha:getCard(to_return), reason)
						if not player:getPhase() ~= sgs.Player_NotActive then
							room:addPlayerMark(player, self:objectName())
						end
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end
}

mengshislash = sgs.CreateTargetModSkill{
	name = "#mengshislash",
	pattern = "Slash",
	residue_func = function(self, from)
		if from:hasSkill("mengshi") then
			return from:getMark("mengshi")
		else
			return 0
		end
	end
}

NTD2card = sgs.CreateSkillCard{
	name = "ntdtwo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("NTD")
		room:doLightbox("image=image/animate/ntdtwo.png", 1500)
		room:setEmotion(source, "NTD2")
		room:getThread():delay(2400)
		local json = require ("json")
		local general = sgs.Sanguosha:getGeneral("BANSHEE_NTD")
		assert(general)
		local jsonValue = {
			10,
			source:objectName(),
			general:objectName(),
			"baosang",
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		source:loseMark("@NTD2")
	    room:loseMaxHp(source)
		if not source:isKongcheng() then
			local n = 0
			local handcards = source:handCards()
			room:fillAG(handcards)
			for _,h in sgs.qlist(handcards) do
				if sgs.Sanguosha:getCard(h):isBlack() then
					n = n + 1
				end
			end
			if n > 0 then
				for i = 1, n, 1 do
					if not room:askForUseCard(source, "@@ntdtwo", "@ntdtwo") then break end
				end
			else
				room:getThread():delay(1500)
			end
			room:clearAG()
		end
		room:acquireSkill(source, "baosang")
	end
}

NTD2vs = sgs.CreateZeroCardViewAsSkill{
    name = "ntdtwo",
	response_pattern = "@@ntdtwo",
    view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@ntdtwo" then
			local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
			acard:setSkillName(self:objectName())
			return acard
		else
			return NTD2card:clone()
		end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@NTD2") > 0
    end
}

NTD2 = sgs.CreateTriggerSkill{
	name = "ntdtwo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@NTD2",
	view_as_skill = NTD2vs,
	on_trigger = function() 
	end
}

baosangvs = sgs.CreateOneCardViewAsSkill{
	name = "baosang",
	filter_pattern = ".|black|.|hand",
	response_pattern = "@@baosang",
	response_or_use = true,
	view_as = function(self, card)
	    local pattern = sgs.Self:property("bsuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end
}

baosang = sgs.CreateTriggerSkill{
	name = "baosang",
	events = {sgs.TargetConfirming},
	view_as_skill = baosangvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and (not player:isKongcheng())
			and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "indulgence+supply_shortage", data)
			room:setPlayerProperty(player, "bsuse", sgs.QVariant(choice))
			if room:askForUseCard(player, "@@baosang", "@baosang:"..choice) then
				use.to = sgs.SPlayerList()
				data:setValue(use)
			end
			room:setPlayerProperty(player, "bsuse", sgs.QVariant())
		end
	end
}

BANSHEE:addSkill(mengshi)
BANSHEE:addSkill(mengshislash)
BANSHEE:addSkill(NTD2)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("baosang") then skills:append(baosang) end
sgs.Sanguosha:addSkills(skills)
BANSHEE:addRelateSkill("baosang")
extension:insertRelatedSkills("mengshi", "#mengshislash")

BANSHEE_NTD = sgs.General(extension, "BANSHEE_NTD", "EFSF", 4, false, true, true)
BANSHEE_NTD:addSkill("mengshi")
BANSHEE_NTD:addSkill("ntdtwo")
BANSHEE_NTD:addRelateSkill("baosang")

--[[NORN = sgs.General(extension, "NORN", "EFSF", 4, true, dlc, dlc)
if dlc then
	if t[1] then
		local times = tonumber(t[1]:split("/")[2])
		if times == 5 and sgs.Sanguosha:translate("NORN") == "NORN" then
			sgs.Alert("累计5场游戏——你获得新机体：黑独角兽-命运女神！")
		end
		if times >= 5 then]]
			NORN = sgs.General(extension, "NORN", "EFSF", 4, true, false)
		--[[end
	end
end]]

--[[function ShenshiMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "shenshi", ""))
		move.to_pile_name = "po"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "shenshi", ""))
		move.from_pile_name = "po"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

shenshicard = sgs.CreateSkillCard{
	name = "shenshi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
	    return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(), effect.to:objectName(), "shenshi","")
		room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceHand, reason, true)
		ShenshiMove(self:getSubcards(), true, effect.to)
		room:setPlayerProperty(effect.to, "shenshi", sgs.QVariant(table.concat(sgs.QList2Table(self:getSubcards()), "+")))
	end,
}

shenshivs = sgs.CreateViewAsSkill{
	name = "shenshi",
	n = 3,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	response_pattern = "@@shenshi",
	view_as = function(self, cards)
		if #cards > 0 and #cards < 4 then
			local acard = shenshicard:clone()
			for _,c in ipairs(cards)do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
    end,
}

shenshi = sgs.CreateTriggerSkill{
	name = "shenshi",
	events = {sgs.EventPhaseEnd},
	view_as_skill = shenshivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			room:askForUseCard(player, "@@shenshi", "@shenshi")
		end
	end,
}

shenshi_damage = sgs.CreateTriggerSkill{
	name = "#shenshi_damage",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local splayer = room:findPlayerBySkillName("shenshi")
			local list = player:property("shenshi"):toString():split("+")
			if #list > 0 then
				room:damage(sgs.DamageStruct(self:objectName(), splayer, player))
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(Table2IntList(list))
				room:throwCard(dummy, nil)
			end
		end
	end
}

shenshi_global = sgs.CreateTriggerSkill{
	name = "#shenshi_global",
	events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				local list = player:property("shenshi"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					for _,l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						end
					end
					ShenshiMove(to_remove, false, player)
					for _,id in sgs.qlist(to_remove) do
						table.removeOne(list, tostring(id))
					end
					local pattern = sgs.QVariant()
					if #list > 0 then
						pattern = sgs.QVariant(table.concat(list, "+"))
					end
					room:setPlayerProperty(player, "shenshi", pattern)
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local source = move.reason.m_playerId
			if source and move.from and move.from:objectName() ~= source and player:objectName() == source
				and move.from_places:contains(sgs.Player_PlaceHand) and move.reason.m_skillName ~= "longqi"
				and not(room:getTag("Dongchaer"):toString() == player:objectName()
				and room:getTag("Dongchaee"):toString() == move.from:objectName()) then
				local list = move.from:property("shenshi"):toString():split("+")
				if #list > 0 then
					if #list == 1 and move.from:getHandcards():length() == 1 then return false end
					local ids = sgs.IntList()
					for _,l in pairs(list) do
						ids:append(tonumber(l))
					end
					local to_move = move.card_ids
					local invisible_hands = move.from:getHandcards()
					for _,k in sgs.qlist(move.from:getHandcards()) do
						if ids:contains(k:getId()) then
							invisible_hands:removeOne(k)
						end
					end
					if invisible_hands:length() == 0 then
						local po = ids
						for _,x in sgs.qlist(move.card_ids) do
							if ids:contains(x) then
								room:fillAG(po)
								local id = room:askForAG(player, po, false, "shenshi")
								if id ~= -1 then
									to_move:append(id)
									to_move:removeOne(x)
									po:removeOne(id)
								end
								room:clearAG()
							end
						end
					else
						local hands = sgs.IntList()
						for _,i in sgs.qlist(move.card_ids) do
							if room:getCardPlace(i) == sgs.Player_PlaceHand then
								if ids:contains(i) then
									local rand = invisible_hands:at(math.random(0, invisible_hands:length() - 1)):getId()
									to_move:append(rand)
									to_move:removeOne(i)
									i = rand
								end
								hands:append(i)
							end
						end
						if hands:length() == move.from:getHandcardNum() or hands:length() == 0 then return false end
						local view = ids
						for _,j in sgs.qlist(hands) do
							if view:length() == 0 then break end
							local choice = room:askForChoice(player, "shenshi", "shenshipile+shenshihand", data)
							if choice == "shenshipile" then
								if view:length() == 1 then
									local id = view:first()
									to_move:append(id)
									to_move:removeOne(j)
									view:removeOne(id)
								else
									room:fillAG(view)
									local id = room:askForAG(player, view, false, "shenshi")
									if id ~= -1 then
										to_move:append(id)
										to_move:removeOne(j)
										view:removeOne(id)
									end
									room:clearAG()
								end
							else
								break
							end
						end
					end
					local bools = sgs.BoolList()
					for _,t in sgs.qlist(to_move) do
						bools:append(ids:contains(t))
					end
					move.card_ids = to_move
					move.open = bools
					data:setValue(move)
				end
			end
		end
	end
}]]

shenshi = sgs.CreateTriggerSkill{
	name = "shenshi" ,
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "#CardViewAs"
					log.from = player
					log.arg = "duel"
					log.card_str = use.card:toString()
					room:sendLog(log)
					local duel = sgs.Sanguosha:cloneCard("duel", use.card:getSuit(), use.card:getNumber())
					duel:addSubcard(use.card)
					if use.card:getSkillName() ~= "" then
						duel:setSkillName(use.card:getSkillName())
					end
					use.card = duel
					data:setValue(use)
				end
			end
		end
	end
}

NTD3card = sgs.CreateSkillCard{
	name = "ntdthree",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("NTD")
		room:doLightbox("image=image/animate/ntdthree.png", 1500)
		room:setEmotion(source, "NTD3")
		room:getThread():delay(2400)
		local json = require ("json")
		local general = sgs.Sanguosha:getGeneral("NORN_NTD")
		assert(general)
		local jsonValue = {
			10,
			source:objectName(),
			general:objectName(),
			"zuzhou",
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		source:loseMark("@NTD3")
	    room:loseMaxHp(source)
		if not source:isKongcheng() then
			local n = 0
			local handcards = source:handCards()
			room:fillAG(handcards)
			for _,h in sgs.qlist(handcards) do
				if sgs.Sanguosha:getCard(h):isBlack() then
					n = n + 1
				end
			end
			if n > 0 then
				for i = 1, n, 1 do
					if not room:askForUseCard(source, "@@ntdthree", "@ntdthree") then break end
				end
			else
				room:getThread():delay(1500)
			end
			room:clearAG()
		end
		room:acquireSkill(source, "zuzhou")
	end
}

NTD3vs = sgs.CreateZeroCardViewAsSkill{
    name = "ntdthree",
	response_pattern = "@@ntdthree",
    view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@ntdthree" then
			local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
			acard:setSkillName(self:objectName())
			return acard
		else
			return NTD3card:clone()
		end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@NTD3") > 0
    end
}

NTD3 = sgs.CreateTriggerSkill{
	name = "ntdthree",
	frequency = sgs.Skill_Limited,
	limit_mark = "@NTD3",
	view_as_skill = NTD3vs,
	on_trigger = function() 
	end
}

zuzhouvs = sgs.CreateOneCardViewAsSkill{
	name = "zuzhou",
	filter_pattern = ".|black|.|hand",
	response_pattern = "@@zuzhou",
	response_or_use = true,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end
}

zuzhou = sgs.CreateTriggerSkill{
	name = "zuzhou",
	events = {sgs.TargetConfirming, sgs.PreCardUsed},
	view_as_skill = zuzhouvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirming then
			if use.card and use.card:isNDTrick() and use.to:contains(player) and (not player:isKongcheng())
				and room:askForSkillInvoke(player, self:objectName(), data) then
				if room:askForUseCard(player, "@@zuzhou", "@zuzhou") then
					use.to = sgs.SPlayerList()
					data:setValue(use)
				end
			end
		else
			if use.card and use.card:getSkillName() == "zuzhou" then
				local voice = false
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getGeneralName() == "UNICORN" or p:getGeneralName() == "FA_UNICORN" then
						voice = true
						break
					end
				end
				if voice then
					room:broadcastSkillInvoke(self:objectName(), 4)
				else
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
				end
				return true
			end
		end
	end
}

xuanguang = sgs.CreateTriggerSkill
{
	name = "xuanguang",
	events = {sgs.AskForPeachesDone},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getHp() < 1 and player:getMark("@xuanguang") == 0 and player:getMark("@NTD3") == 0 then
			room:broadcastSkillInvoke("xuanguang")
			room:doLightbox("image=image/animate/xuanguang.png", 1500)
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:setPlayerMark(player, "xuanguang", 1)
			player:gainMark("@xuanguang")
			removeWholeEquipArea(player)
			room:handleAcquireDetachSkills(player, "-zuzhou|#xuanguangfilter|#xuanguangdefense")
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
			room:filterCards(player, player:getCards("he"), false)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("NORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"xuanguang",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
	end
}

xuanguangfilter = sgs.CreateFilterSkill{
	name = "#xuanguangfilter",
	view_filter = function(self, card)
		return card:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(peach)
		return wrap
	end
}

xuanguangdefense = sgs.CreateTriggerSkill
{
	name = "#xuanguangdefense",
	events = {sgs.DamageForseen},
	can_trigger = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@xuanguang") > 0 then
				return true
			end
		end
		return false
	end,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal and player:getEquips():isEmpty() then
			room:broadcastSkillInvoke("xuanguang", 1)
			room:notifySkillInvoked(player, "xuanguang")
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#xuanguang"
			log.from = player
			log.arg = "xuanguang"
			room:sendLog(log)
			return true
		end
    end
}

NORN:addSkill(shenshi)
--NORN:addSkill(shenshi_damage)
--NORN:addSkill(shenshi_global)
NORN:addSkill(xuanguang)
NORN:addSkill(NTD3)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("zuzhou") then skills:append(zuzhou) end
if not sgs.Sanguosha:getSkill("#xuanguangfilter") then skills:append(xuanguangfilter) end
if not sgs.Sanguosha:getSkill("#xuanguangdefense") then skills:append(xuanguangdefense) end
sgs.Sanguosha:addSkills(skills)
NORN:addRelateSkill("zuzhou")
--extension:insertRelatedSkills("shenshi", "#shenshi_damage")

NORN_NTD = sgs.General(extension, "NORN_NTD", "EFSF", 4, true, true, true)
NORN_NTD:addSkill("shenshi")
NORN_NTD:addSkill("ntdthree")
NORN_NTD:addRelateSkill("zuzhou")

PHENEX = sgs.General(extension, "PHENEX", "EFSF", 4, true, true, true)

shenniaocard = sgs.CreateSkillCard{
	name = "shenniao",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		room:setPlayerMark(effect.to, "@shenniao", 1)
		room:setPlayerMark(effect.to, "Equips_Nullified_to_Yourself", 1)
		if effect.to:hasEquip() then
			local log = sgs.LogMessage()
			log.type = "$shenniaolog"
			log.from = effect.from
			log.to:append(effect.to)
			log.arg = self:objectName()
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:addSubcards(effect.to:getEquips())
			log.card_str = card:subcardString()
			room:sendLog(log)
		end
		--[[room:setPlayerProperty(effect.to, "alive", sgs.QVariant(false))
		room:setPlayerProperty(effect.to, "role", sgs.QVariant("unknown"))--set original role before revive
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_KILL_PLAYER, sgs.QVariant(effect.to:objectName()))]]--BUG:neo zeong test
	end,
}

shenniaovs = sgs.CreateViewAsSkill{
    name = "shenniao",
    n = 2,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
    view_as = function(self, cards)
	if #cards == 2 then
        local acard = shenniaocard:clone()
		for _,card in pairs(cards) do
			acard:addSubcard(card)
		end
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return not player:hasUsed("#shenniao")
    end,
}

shenniao = sgs.CreateTriggerSkill{
	name = "shenniao",
	events = {sgs.EventPhaseStart},
	view_as_skill = shenniaovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
    if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			    if p:getMark("@shenniao") > 0 then
				    room:setPlayerMark(p, "@shenniao", 0)
					room:setPlayerMark(p, "Equips_Nullified_to_Yourself", 0)
				end
			end
		end
	end
	end,
}

PHENEX:addSkill(shenniao)

EX_S = sgs.General(extension, "EX_S", "EFSF", 4, true, false)

fanshecard = sgs.CreateSkillCard{
	name = "fanshe",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
		room:moveCardsAtomic(move, true)
		local card = sgs.Sanguosha:getCard(ids:first())
		if card:isRed() then
			room:setEmotion(source, "judgegood")
			local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "@fanshe")
			if target then
				target:addToPile("INCOM", card)
				room:setEmotion(target, "INCOM1")
			end
		else
			room:setEmotion(source, "judgebad")
			room:throwCard(card, nil)
		end
	end,
}

fanshevs = sgs.CreateViewAsSkill{
	name = "fanshe",
	n = 0,
	view_as = function(self, cards)
		if #cards == 0 then
			local acard = fanshecard:clone()
			acard:setSkillName("fanshe")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fanshe")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

fanshe = sgs.CreateTriggerSkill{
	name = "fanshe",
	events = {sgs.EventPhaseStart, sgs.PreCardUsed, sgs.EventPhaseEnd},
	view_as_skill = fanshevs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPile("INCOM"):length() > 0 then
					local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					card:addSubcards(p:getPile("INCOM"))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName())
					room:obtainCard(player, card, reason)
				end
			end
		end
	elseif event == sgs.PreCardUsed then
		local use = data:toCardUse()
		if use.card and not use.card:isKindOf("SkillCard") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPile("INCOM"):length() > 0 then
					local move = sgs.CardsMoveStruct()
					local int = sgs.IntList()
					int:append(use.card:getId())
					move.card_ids = int
					move.to = p
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, p:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					room:setEmotion(p, "INCOM2")
					room:doAnimate(1, player:objectName(), p:objectName())
					room:getThread():delay(0400)
					local log = sgs.LogMessage()
					log.type = "#BecomeUser"
					log.from = p
					log.card_str = use.card:toString()
					room:sendLog(log)
					use.from = p
					if use.card:isKindOf("AOE") then
						use.to = room:getOtherPlayers(p)
					elseif use.card:isKindOf("GlobalEffect") then
						use.to = room:getAlivePlayers()
					elseif use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Analeptic") or
					use.card:isKindOf("EquipCard") or use.card:isKindOf("Lightning") then
						local list = sgs.SPlayerList()
						list:append(p)
						use.to = list
					end
					data:setValue(use)
					break
				end
			end
		end
	elseif event == sgs.EventPhaseEnd then --For AI use only
		if player:getPhase() == sgs.Player_Play then
			if player:getAI() then
				if not player:hasUsed("#fanshe") then
					room:askForUseCard(player, "@@fanshe", "@fansheAI")
				end
			end
		end
	end
	end,
}

fansheD = sgs.CreateTriggerSkill{
	name = "#fansheD",
	events = {sgs.ConfirmDamage},
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getPile("INCOM"):length() > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage and damage.card and not damage.card:isKindOf("SkillCard") then
		local skillowners = room:findPlayersBySkillName("fanshe")
		for _,p in sgs.qlist(skillowners) do
			if p:hasUsed("#fanshe") then
				room:setEmotion(player, "INCOM2")
				room:doAnimate(1, p:objectName(), player:objectName())
				room:getThread():delay(0400)
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				damage.from = p
				data:setValue(damage)
				break
			end
		end
	end
	end,
}

fansheTM = sgs.CreateTargetModSkill{
	name = "#fansheTM",
	pattern = ".",
	distance_limit_func = function(self, player, card)
		local valid = false
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:getPile("INCOM"):length() > 0 then
				valid = true
				break
			end
		end
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") and valid then
			return 998
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					return sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, p, card)
				else
					return 0
				end
			end
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					return 998
				else
					return 0
				end
			end
		end
	end,
}

fansheP = sgs.CreateProhibitSkill
{
	name = "#fansheP",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("fanshe") and from:hasUsed("#fanshe") and to then
			for _,p in sgs.qlist(from:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					if p:isProhibited(p, card) or not card:isAvailable(p) then
						return true
					else
						return (card:isKindOf("Slash") and not p:canSlash(to)) or
						((card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) and (p:objectName() == to:objectName()
						or p:distanceTo(to) > 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, p, card)))
						or ((card:isKindOf("Dismantlement") or card:isKindOf("Collateral") or card:isKindOf("Duel") or
						card:isKindOf("Indulgence")) and p:objectName() == to:objectName())
					end
				end
			end
		end
	end,
}

ALICE = sgs.CreateTriggerSkill{
	name = "ALICE",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerFlag(player, "-ALICE")
			local ids = sgs.IntList()
			for i=0, 2, 1 do
				ids:append(room:getDrawPile():at(i))
			end
			room:fillAG(ids, player)
			room:getThread():delay(1500)
			room:clearAG(player)
			local plist = sgs.SPlayerList()
			plist:append(player)
			local list = sgs.IntList()
			if sgs.Sanguosha:getCard(ids:at(0)):getSuit() == sgs.Sanguosha:getCard(ids:at(1)):getSuit() then
				if not list:contains(ids:at(0)) then list:append(ids:at(0)) end
				if not list:contains(ids:at(1)) then list:append(ids:at(1)) end
			end
			if sgs.Sanguosha:getCard(ids:at(0)):getSuit() == sgs.Sanguosha:getCard(ids:at(2)):getSuit() then
				if not list:contains(ids:at(0)) then list:append(ids:at(0)) end
				if not list:contains(ids:at(2)) then list:append(ids:at(2)) end
			end
			if sgs.Sanguosha:getCard(ids:at(1)):getSuit() == sgs.Sanguosha:getCard(ids:at(2)):getSuit() then
				if not list:contains(ids:at(1)) then list:append(ids:at(1)) end
				if not list:contains(ids:at(2)) then list:append(ids:at(2)) end
			end
			if list:length() >= 2 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local move2 = sgs.CardsMoveStruct(list, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DEMONSTRATE, player:objectName(), self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move2)
				room:notifyMoveCards(true, moves, false, plist)
				room:notifyMoveCards(false, moves, false, plist)
				local pattern = ""
				for _,id in sgs.qlist(list) do
					if pattern == "" then
						pattern = sgs.Sanguosha:getCard(id):toString()
					else
						pattern = pattern .. "," .. sgs.Sanguosha:getCard(id):toString()
					end
				end
				local card2obtain = room:askForCard(player, pattern, "@ALICE-obtain", data, sgs.Card_MethodNone,
										nil, false, self:objectName(), false)
				if card2obtain then
					local move3 = sgs.CardsMoveStruct(card2obtain:getId(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movess = sgs.CardsMoveList()
					movess:append(move3)
					room:notifyMoveCards(true, movess, false, plist)
					room:notifyMoveCards(false, movess, false, plist)
					room:obtainCard(player, card2obtain)
					list:removeOne(card2obtain:getId())
				else
					local random_id = list:at(math.random(0, list:length()-1))
					local move3 = sgs.CardsMoveStruct(random_id, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movess = sgs.CardsMoveList()
					movess:append(move3)
					room:notifyMoveCards(true, movess, false, plist)
					room:notifyMoveCards(false, movess, false, plist)
					room:obtainCard(player, random_id)
					list:removeOne(random_id)
				end
				if damage.from then
					if list:length() >= 2 then
						local pattern2 = ""
						for _,id2 in sgs.qlist(list) do
							if pattern2 == "" then
								pattern2 = sgs.Sanguosha:getCard(id2):toString()
							else
								pattern2 = pattern2 .. "," .. sgs.Sanguosha:getCard(id2):toString()
							end
						end
						local card2give = room:askForCard(player, pattern2, "@ALICE-give:"..damage.from:getGeneralName(),
											data, sgs.Card_MethodNone, damage.from, false, self:objectName(), true)
						if card2give then
							local move3 = sgs.CardsMoveStruct(card2give:getId(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
							local movess = sgs.CardsMoveList()
							movess:append(move3)
							room:notifyMoveCards(true, movess, false, plist)
							room:notifyMoveCards(false, movess, false, plist)
							room:obtainCard(damage.from, card2give)
							list:removeOne(card2give:getId())
						else
							local random_id = list:at(math.random(0, list:length()-1))
							local move3 = sgs.CardsMoveStruct(random_id, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
							local movess = sgs.CardsMoveList()
							movess:append(move3)
							room:notifyMoveCards(true, movess, false, plist)
							room:notifyMoveCards(false, movess, false, plist)
							room:obtainCard(damage.from, random_id)
							list:removeOne(random_id)
						end
					else
						local move3 = sgs.CardsMoveStruct(list:at(0), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
						local movess = sgs.CardsMoveList()
						movess:append(move3)
						room:notifyMoveCards(true, movess, false, plist)
						room:notifyMoveCards(false, movess, false, plist)
						room:obtainCard(damage.from, list:at(0))
						list:removeOne(list:at(0))
					end
					room:setPlayerFlag(player, "ALICE")
				end
				for i=0, 2, 1 do
					if list:contains(ids:at(i)) then
						room:throwCard(ids:at(i), nil)
					end
				end
				if list:length() > 0 then
					local movef = sgs.CardsMoveStruct(list, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movesf = sgs.CardsMoveList()
					movesf:append(movef)
					room:notifyMoveCards(true, movesf, false, plist)
					room:notifyMoveCards(false, movesf, false, plist)
				end
				if player:hasFlag("ALICE") then
					room:setPlayerFlag(player, "-ALICE")
					return true
				end
			end
		end
	end,
}

EX_S:addSkill(fanshe)
EX_S:addSkill(fansheD)
EX_S:addSkill(ALICE)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#fansheTM") then skills:append(fansheTM) end
if not sgs.Sanguosha:getSkill("#fansheP") then skills:append(fansheP) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("fanshe", "#fansheD")

HYAKU_SHIKI = sgs.General(extension, "HYAKU_SHIKI", "EFSF", 4, true, false)

luashipocard = sgs.CreateSkillCard{
	name = "luashipo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("luashipo", math.random(1, 2))
		source:addToPile("lizhan", self)
	end
}

luashipovs = sgs.CreateOneCardViewAsSkill{
	name = "luashipo",
	expand_pile = "lizhan",
	response_pattern = "nullification",
	view_filter = function(self, card)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("TrickCard") and (not card:isKindOf("Nullification")) and (not sgs.Sanguosha:matchExpPattern(".|.|.|lizhan", sgs.Self, card))
		end
		return sgs.Sanguosha:matchExpPattern(".|.|.|lizhan", sgs.Self, card)
	end,
	view_as = function(self, card)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local acard = luashipocard:clone()
			acard:addSubcard(card)
			acard:setSkillName(self:objectName())
			return acard
		else
			local ncard = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
			ncard:addSubcard(card)
			ncard:setSkillName(self:objectName())
			return ncard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("lizhan"):length() < 3
	end,
	enabled_at_nullification = function(self, player)
		return not player:getPile("lizhan"):isEmpty()
	end
}

luashipo = sgs.CreateTriggerSkill{
	name = "luashipo",
	events = {sgs.PreCardUsed},
	view_as_skill = luashipovs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "luashipo" then
			if use.card:isKindOf("Nullification") then
				room:broadcastSkillInvoke("luashipo", math.random(3, 4))
			end
			return true
		end
	end
}

leishecard = sgs.CreateSkillCard{
	name = "leishe",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < 1
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("maprecord", 1)
		room:doLightbox("image=image/animate/leishe.png", 1500)
		source:loseMark("@leishe", 3)
		room:damage(sgs.DamageStruct("leishe", source, targets[1], 1, sgs.DamageStruct_Thunder))
	end
}

leishevs = sgs.CreateZeroCardViewAsSkill{
	name = "leishe",
	view_as = function(self)
		local acard = leishecard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@leishe") >= 3 and (not player:hasUsed("#leishe"))
	end
}

leishe = sgs.CreateTriggerSkill{
	name = "leishe",
	events = {sgs.CardUsed},
	view_as_skill = leishevs,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Nullification") and use.card:getSkillName() == "luashipo" then
			player:gainMark("@leishe")
		end
	end
}

HYAKU_SHIKI:addSkill(luashipo)
HYAKU_SHIKI:addSkill(leishe)

SHINING = sgs.General(extension, "SHINING", "OTHERS", 4, true, false)--LUA By ZY

shanguangcard = sgs.CreateSkillCard{
	name = "shanguang",
	filter = function(self, targets, to_select, player) 
		if #targets ~= 0 or to_select:objectName() == player:objectName() then return false end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and player:getWeapon() and player:getWeapon():getId() == self:getSubcards():first() then
			local card = player:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - player:getAttackRange(false)
		end
		return player:inMyAttackRange(to_select, rangefix)
	end,
	on_use = function(self, room, source, targets)
		local data = sgs.QVariant()
		data:setValue(source)
		if not room:askForCard(targets[1], ".Equip", "@@shanguang", data, self:objectName()) then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
		end
	end
}

shanguangvs = sgs.CreateOneCardViewAsSkill{
	name = "shanguang",
	view_filter = function(self, card)
		return card:isKindOf("Jink") or (sgs.Self:getMark("@supermode") > 0 and card:isKindOf("Weapon"))
	end,
	view_as = function(self, card) 
		local skill_card = shanguangcard:clone()
		skill_card:addSubcard(card)
		return skill_card
	end,
	enabled_at_play = function(self, player)
		local x = 1
		if player:getMark("@supermode") > 0 then x = 2 end
		return player:usedTimes("#shanguang") < x
	end
}

shanguang = sgs.CreateTriggerSkill
{
	name = "shanguang",
	events = {sgs.PreCardUsed},
	view_as_skill = shanguangvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() then
			if player:getMark("@supermode") > 0 then
				room:broadcastSkillInvoke(self:objectName(), 2)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			return true
		end
	end
}

chaojimoshi = sgs.CreateTriggerSkill{
	name = "chaojimoshi",
	frequency = sgs.Skill_Wake,
	events = {sgs.Damaged, sgs.EventPhaseStart, sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:getMark("@supermode") == 0 then
				room:addPlayerMark(player, "supermode_damage", data:toDamage().damage)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("@supermode") == 0 and player:getMark("supermode_damage") >= 3 then
				room:setPlayerFlag(player, "skip_anime")
				if player:hasSkill("jingxin") then
					if player:getMark("@point") < 3 then
						if room:askForSkillInvoke(player, "jingxin", data) then
							room:broadcastSkillInvoke("jingxin")
							room:setEmotion(player, "jingxin")
							player:drawCards(1, "jingxin")
							player:gainMark("@point")
							return false
						end
					else
						room:broadcastSkillInvoke("chaojimoshi", 2)
						room:setEmotion(player, "mingjingzhishui")
						room:getThread():delay(5000)
						room:addPlayerMark(player, "jingxin")
						local json = require ("json")
						local general = sgs.Sanguosha:getGeneral("SHINING_S")
						assert(general)
						local jsonValue = {
							10,
							player:objectName(),
							general:objectName(),
							"jingxin",
						}
						room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
					end
				end
				if player:getMark("jingxin") == 0 then
					room:broadcastSkillInvoke("chaojimoshi", 1)
				end
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:gainMark("@supermode")
				room:addPlayerMark(player, self:objectName())
				if player:getMaxHp() > 1 then
					room:loseMaxHp(player, player:getMaxHp() - 1)
				end
			end
		elseif event == sgs.CardAsked then
			if player:getMark("@supermode") > 0 and player:getMark("jingxin") > 0 and player:getMark("@point") > 0 and data:toStringList()[1] == "jink" and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("jink")) then
				room:broadcastSkillInvoke("chaojimoshi", 3)
				player:loseMark("@point")
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jink:setSkillName("chaojimoshi_jink")
				room:provide(jink)
				return true
			end
		end
	end
}

chaojimoshi_atk = sgs.CreateAttackRangeSkill{
	name = "#chaojimoshi_atk",
	extra_func = function(self, player)
		if player and player:getMark("@supermode") > 0 then
			return 1
		end
	end
}

jingxin = sgs.CreateMasochismSkill{
	name = "jingxin",
	on_damaged = function() 
	end
}

chaojimoshi_max = sgs.CreateMaxCardsSkill{
	name = "#chaojimoshi_max",
	extra_func = function(self, player)
		if player and player:getMark("@supermode") > 0 and player:getMark("jingxin") > 0 then
			return 2
		end
	end
}

SHINING:addSkill(shanguang)
SHINING:addSkill(jingxin)
SHINING:addSkill(chaojimoshi)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#chaojimoshi_atk") then skills:append(chaojimoshi_atk) end
if not sgs.Sanguosha:getSkill("#chaojimoshi_max") then skills:append(chaojimoshi_max) end
sgs.Sanguosha:addSkills(skills)

SHINING_S = sgs.General(extension, "SHINING_S", "OTHERS", 4, true, true, true)

WZ = sgs.General(extension, "WZ", "OTHERS", 4, true, false)

wzpointcard = sgs.CreateSkillCard{
	name = "wzpoint",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local x = source:getMark("@point")
		source:loseAllMarks("@point")
		source:drawCards(x)
	end
}

wzpoint = sgs.CreateZeroCardViewAsSkill{
	name = "wzpoint&",
	view_as = function(self, cards)
		return wzpointcard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@point") > 0
	end,
}

feiyi = sgs.CreateTargetModSkill{
	name = "feiyi",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHp() <= 2 then
			return 998
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHp() == 1 then
			return 1
		end
	end,
}

liuxingvs = sgs.CreateViewAsSkill{
	name = "liuxing",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	    if #cards == 2 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			for _,card in ipairs(cards) do
			    slash:addSubcard(card)
			end
			slash:setSkillName("liuxing")
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getHandcardNum() >= 2
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
		    return player:getHandcardNum() >= 2 and
			sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		end
		return false
	end,
}

liuxing = sgs.CreateTriggerSkill{
	name = "liuxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed,sgs.ConfirmDamage,sgs.CardFinished},
	view_as_skill = liuxingvs,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
	if event == sgs.CardUsed then
		if use.card:isKindOf("Slash") and use.card:getSkillName() == "liuxing" then
			player:gainMark("@point")
			local judge = sgs.JudgeStruct()
		    judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				room:setCardFlag(use.card, "liuxing")
			end
		end
	end
	if event == sgs.ConfirmDamage then
	    local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "liuxing" and damage.card:hasFlag("liuxing") then
			room:broadcastSkillInvoke("liuxing",5)
			room:clearCardFlag(damage.card)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end
	if event == sgs.CardFinished then
	    if use.card:hasFlag("liuxing") then
		    room:clearCardFlag(use.card)
		end
	end
	end,
}

lingshi = sgs.CreateTriggerSkill{
	name = "lingshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
    if player:getPhase() == sgs.Player_Start and player:getMark("@point") >= 3 and room:askForSkillInvoke(player, "lingshi", data) then
		if room:findPlayer("EPYON") then
			room:broadcastSkillInvoke("qishi",3)
			room:getThread():delay(2400)
			room:broadcastSkillInvoke("lingshi",8)
			room:broadcastSkillInvoke("lingshi",7)
		else
			room:broadcastSkillInvoke("lingshi",8)
			room:broadcastSkillInvoke("lingshi",math.random(1,6))
		end
		room:askForGuanxing(player, room:getNCards(3), sgs.Room_GuanxingUpOnly)
	end
	end,
}

WZ:addSkill(wzpoint)
WZ:addSkill(feiyi)
WZ:addSkill(liuxing)
WZ:addSkill(lingshi)

EPYON = sgs.General(extension, "EPYON", "OTHERS", 4, true, false)

qishi = sgs.CreateFilterSkill{
	name = "qishi",
	view_filter = function(self, card)
		return card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("FireAttack")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end,
}

--[[qishislash = sgs.CreateTargetModSkill{
	name = "#qishislash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
	if player and player:hasSkill("qishi") then
	    return (1 - player:getAttackRange(true))
	end
	end,
}]]

qishislash = sgs.CreateAttackRangeSkill{
	name = "#qishislash",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill("qishi") then
			return 1
		end
	end,
}

mosu = sgs.CreateTriggerSkill{
	name = "mosu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.Damaged then
	    local damage = data:toDamage()
		if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive and damage.from:objectName() ~= player:objectName()
			and player:getMark("mosufrom") == 0 and room:askForSkillInvoke(player, "mosu", data) then
			if room:findPlayer("WZ+WZC") then
			    room:broadcastSkillInvoke("mosu",7)
				room:getThread():delay(1700)
				room:broadcastSkillInvoke("wzpoint",4)
			else
				room:broadcastSkillInvoke("mosu",math.random(1,6))
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				room:setPlayerMark(p,"mosufrom",0)
				room:setPlayerMark(p,"mosuto",0)
			end
			room:setPlayerMark(player,"mosufrom",1)
			room:setPlayerMark(damage.from,"mosuto",1)
			local log = sgs.LogMessage()
			log.type = "#SkipAllPhase"
			log.from = damage.from
			room:sendLog(log)
			local log2 = sgs.LogMessage()
			log2.type = "#Fangquan"
			log2.to:append(player)
			room:sendLog(log2)
			room:clearAG()
			player:gainAnExtraTurn()
			local card_ids = room:getTag("LaplaceBox"):toIntList()
			if not card_ids:isEmpty() then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(card_ids)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", "amazing_grace", "")
				room:throwCard(dummy, reason, nil)
				room:removeTag("LaplaceBox")
			end
			room:throwEvent(sgs.TurnBroken)
		end
	elseif event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Finish then
		    if player:getMark("mosufrom") > 0 then
			    room:setPlayerMark(player,"mosufrom",0)
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				if p:getMark("mosuto") > 0 then
				    room:setPlayerMark(p,"mosuto",0)
				end
			end
		end
	end
	end,
}

mosudistance = sgs.CreateDistanceSkill{
    name = "#mosudistance",
    correct_func = function(self, from, to)
		if from and from:hasSkill("mosu") and from:getMark("mosufrom") > 0 and to and to:getMark("mosuto") > 0 then
			return -998
		end
    end
}

cishi = sgs.CreateTriggerSkill{
	name = "cishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local death = data:toDeath()
		if death.damage and death.damage.from and death.damage.from:hasSkill("cishi") and death.damage.from:getPhase() == sgs.Player_Play and death.who:objectName() == player:objectName() then
			if room:askForSkillInvoke(death.damage.from, "cishi", data) then
				room:broadcastSkillInvoke("cishi")
				room:setPlayerFlag(death.damage.from,"cishi")
				death.damage.from:drawCards(2)
			end
		end
	end
}

cishislash = sgs.CreateTargetModSkill{
	name = "#cishislash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("cishi") then
			return 998
		end
	end,
}

EPYON:addSkill(qishi)
EPYON:addSkill(qishislash)
EPYON:addSkill(mosu)
EPYON:addSkill(mosudistance)
EPYON:addSkill(cishi)
EPYON:addSkill(cishislash)
extension:insertRelatedSkills("qishi", "#qishislash")
extension:insertRelatedSkills("mosu", "#mosudistance")
extension:insertRelatedSkills("cishi", "#cishislash")

WZC = sgs.General(extension, "WZC", "OTHERS", 4, true, false)

shuangpaocard = sgs.CreateSkillCard{
	name = "shuangpao",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#shuangpao"
        room:sendLog(log)
	end
}

shuangpaovs = sgs.CreateViewAsSkill{
	name = "shuangpao",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
		local acard = shuangpaocard:clone()
		acard:setSkillName("shuangpao")
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#shuangpao")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

shuangpao = sgs.CreateTriggerSkill{
	name = "shuangpao",
	events = {sgs.ConfirmDamage},
	view_as_skill = shuangpaovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:distanceTo(damage.to) > 1 and damage.card:isKindOf("Slash") and player:hasUsed("#shuangpao") then
			damage.damage = damage.damage + 1
		    data:setValue(damage)
			return false
		end
	end,
}

ew_lingshi = sgs.CreateTriggerSkill{
	name = "ew_lingshi",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart,sgs.HpLost, sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getMark("@ew_lingshi") == 0 then
		    player:gainMark("@ew_lingshi")
		end
	end
	if event == sgs.HpLost or event == sgs.Damaged then
		if player:isKongcheng() and player:getMark("@ew_lingshi") > 0 and room:askForSkillInvoke(player, "ew_lingshi", data) then
		    player:loseMark("@ew_lingshi")
			local sp_voice = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "EPYON" then
					sp_voice = 1
					break
				elseif p:getGeneralName() == "ALTRON" then
				    sp_voice = 2
					break
				end
			end
			if sp_voice == 1 then
			    room:broadcastSkillInvoke("qishi",3)
				--room:getThread():delay(2400)
				room:doSuperLightbox("WZC", self:objectName())
				room:broadcastSkillInvoke("ew_lingshi",8)
				room:broadcastSkillInvoke("ew_lingshi",7)
			elseif sp_voice == 2 then
			    room:broadcastSkillInvoke("ew_lingshi", 9)
				--room:getThread():delay(3000)
				room:doSuperLightbox("WZC", self:objectName())
				room:broadcastSkillInvoke("ew_lingshi",8)
			else
				room:broadcastSkillInvoke("ew_lingshi",8)
				room:broadcastSkillInvoke("ew_lingshi",math.random(1,6))
				room:doSuperLightbox("WZC", self:objectName())
			end
			local id = sgs.Sanguosha:getCard(room:getDrawPile():at(room:getDrawPile():length()-1)):getId()
			room:askForGuanxing(player, room:getNCards(10))
			while sgs.Sanguosha:getCard(room:getDrawPile():at(room:getDrawPile():length()-1)):getId() ~= id do
			    room:obtainCard(player, room:getDrawPile():at(room:getDrawPile():length()-1), false)
			end
			player:turnOver()
		end
	end
	end,
}

WZC:addSkill("feiyi")
WZC:addSkill(shuangpao)
WZC:addSkill(ew_lingshi)

DSH = sgs.General(extension, "DSH", "OTHERS", 4, true, false)

yindun = sgs.CreateTriggerSkill
{
	name = "yindun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke(self:objectName())
		player:drawCards(1)
		player:turnOver()
	end
	end,
}

yindunp = sgs.CreateProhibitSkill
{
	name = "#yindunp",
	is_prohibited = function(self, from, to, card)
		if(to and to:hasSkill("yindun") and not to:faceUp()) then
			return card:isKindOf("Slash")
		end
	end,
}

anshalist = {}
ansha = sgs.CreateTriggerSkill{
    name = "ansha",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    priority = -1,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if room:getCurrent():getPhase() ~= sgs.Player_Discard then return false end
		for _,card_id in sgs.qlist(move.card_ids) do
			local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                table.insert(anshalist, card_id)
			end
        end
	end
	if event == sgs.EventPhaseEnd then
        if #anshalist == 0 or player:getPhase() ~= sgs.Player_Discard then return false end
		while #anshalist > 0 do
	        table.remove(anshalist)
	    end
		for _,selfplayer in sgs.qlist(allplayers) do
            if selfplayer:objectName() == player:objectName() or
			selfplayer:faceUp() or
			selfplayer:isNude() then continue end
			if room:askForSkillInvoke(selfplayer, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:askForDiscard(selfplayer, "ansha", 1, 1, false, true)
				if not selfplayer:faceUp() then
					selfplayer:turnOver()
				end
				room:doAnimate(1, selfplayer:objectName(), player:objectName())
				room:loseHp(player)
				--[[local x = player:getMaxCards()
				local z = player:getHandcardNum()
				if z > x then
					local e = z-x
					room:askForDiscard(player, "gamerule", e, e)
				end]]
			end
		end
	end
    end,
}

DSH:addSkill(yindun)
DSH:addSkill(yindunp)
DSH:addSkill(ansha)
extension:insertRelatedSkills("yindun", "#yindunp")

HAC = sgs.General(extension, "HAC", "OTHERS", 4, true, false)

gelinvs = sgs.CreateViewAsSkill{
    name = "gelin",
	n = 2,
	expand_pile = "dan",
	view_filter = function(self, selected, to_select)
		local pat = ".|.|.|dan"
		if string.endsWith(pat, "!") then
			if sgs.Self:isJilei(to_select) then return false end
			pat = string.sub(pat, 1, -2)
		end
	    local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if to_select:hasFlag("using") then return false end
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return #selected == 0 and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
		(usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return #selected == 0 and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
			else
				return (#selected <= 1) and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
			end
		end
		return false
	end,
    view_as = function(self, cards)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY or pattern == "slash" then
			if #cards == 1 then
				local glcard = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				glcard:addSubcard(cards[1])
				glcard:setSkillName(self:objectName())
				return glcard
			else
				return nil
			end
		else
			if #cards == 2 then
				local glcard = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				glcard:addSubcard(cards[1])
				glcard:addSubcard(cards[2])
				glcard:setSkillName(self:objectName())
				return glcard
			else
				return nil
			end
		end
    end,
    enabled_at_play = function(self,player)
        return sgs.Slash_IsAvailable(player) and player:getPile("dan"):length() >= 1
    end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getPile("dan"):length() >= 1
	end,
}

gelin = sgs.CreateTriggerSkill{
	name = "gelin",
	events = {sgs.GameStart},
	view_as_skill = gelinvs,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getPile("dan"):isEmpty() then
	        player:addToPile("dan", room:getNCards(10))
		end
	end
	end,
}

saoshe = sgs.CreateTriggerSkill
{
	name = "saoshe",
	events = {sgs.CardUsed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
				for _,p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "ssp")
				end
			end
		end
	end
}

saoshet = sgs.CreateTargetModSkill{
	name = "#saoshet",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("saoshe") and player:getPhase() == sgs.Player_Play then
			return player:getAliveSiblings():length() - 1
		end
	end,
}

saoshep = sgs.CreateProhibitSkill
{
	name = "#saoshep",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("saoshe") and
		not(from:getSlashCount() >= from:getAliveSiblings():length() and from:canSlashWithoutCrossbow()) and
		not((from:getWeapon() and from:getWeapon():getClassName() == "Crossbow")) and to and to:hasFlag("ssp") and
		from:getPhase() == sgs.Player_Play and not from:hasFlag("tactical_combo") then
			return card:isKindOf("Slash")
		end
	end,
}

--[[感谢小胖子唐飞通宵完成，但AI依然不礼貌→_→
function getMarkCount(room)
	local splist = room:getAllPlayers(true)
	local n = 0
	for _, p in sgs.qlist(splist) do
		n = n + p:getMark("numforcount")
	end
	return n
end

saoshe = sgs.CreateTriggerSkill{
	name = "saoshe",
	events = {sgs.CardFinished, sgs.EventPhaseStart, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local tos = use.to
			for _, to in sgs.qlist(tos) do
				room:setPlayerMark(to, "numforcount", to:getMark("numforcount") + 1)
				local n = player:getSlashCount()
				local sum = getMarkCount(room)
				local ton = to:getMark("numforcount")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local valid = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash)
				if sum > n then
					local y = sum - n
					room:setPlayerMark(to, "numforcount", to:getMark("numforcount") - y)
				end
				if not player:canSlashWithoutCrossbow() then
					local ton = to:getMark("numforcount")
					local splist = room:getAllPlayers()
					local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
					for _, p in sgs.qlist(splist) do
						if not (p:hasFlag("countmax") and p:getMark("numforcount") < valid) then continue end
						room:setPlayerFlag(p, "-countmax")
						if table.contains(nameslist, p:objectName()) then continue end
						table.insert(nameslist, p:objectName())
					end
					room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
					if sum >= valid then
						if ton < valid then continue end
						if to:hasFlag("countmax") then continue end
						local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
						table.removeOne(nameslist, to:objectName())
						room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
						room:setPlayerFlag(to, "countmax")
					end
				end
			end
		else
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local valid = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash)
			local splist = room:getAllPlayers()
			for _, p in sgs.qlist(splist) do
				if not (p:hasFlag("countmax") and p:getMark("numforcount") < valid) then continue end
				room:setPlayerFlag(p, "-countmax")
				if table.contains(nameslist, p:objectName()) then continue end
				table.insert(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	elseif event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Play then
			local splist = room:getAllPlayers(true)
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			for _, p in sgs.qlist(splist) do
			    if table.contains(nameslist, p:objectName()) then continue end
				table.insert(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		elseif player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			local splist = room:getAllPlayers(true)
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			for _, p in sgs.qlist(splist) do
				room:setPlayerMark(p, "numforcount", 0)
				if p:hasFlag("countmax") or p:isDead() then continue end
				table.removeOne(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	elseif event == sgs.Death then
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then return false end
		local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
		table.removeOne(nameslist, death.who:objectName())
		room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	end
}]]

HAC:addSkill(gelin)
HAC:addSkill(saoshe)
HAC:addSkill(saoshet)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#saoshep") then skills:append(saoshep) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("saoshe", "#saoshet")

SANDROCK = sgs.General(extension, "SANDROCK", "OTHERS", 4, true, false)

shuanglian = sgs.CreateTriggerSkill{
	name = "shuanglian",
	events = {sgs.CardUsed,sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = false
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				can_invoke = true
				break
			end
		end
	if event == sgs.CardUsed then
	    local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (not player:isKongcheng()) and can_invoke and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("slash")) then
            local jink = room:askForCard(player, "Jink", "@@shuanglianjink", data, sgs.Card_MethodDiscard, player, false, self:objectName(), false)
			if jink then
				room:broadcastSkillInvoke("shuanglian", 1)
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:inMyAttackRange(p) then
						tos:append(p)
					end
				end
				local target = room:askForPlayerChosen(player, tos, "shuanglian", "@@shuanglianjinktar", false, true)
				local acard = room:askForCard(target, "jink", "@@shuanglianjinkres", data, sgs.Card_MethodResponse, target, false, self:objectName(), false)
				if target then
					if not acard then
						local damage = sgs.DamageStruct()
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Normal
						damage.from = player
						damage.to = target
						room:damage(damage)
					end
				end
		    end
		end
	elseif event == sgs.CardResponded then
		local card = data:toCardResponse().m_card
		if card:isKindOf("Jink") and can_invoke and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("jink")) then
			room:setPlayerFlag(player, "shuanglian_jink")
			local tou = sgs.SPlayerList()
			for _,r in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(r, true) and not r:isProhibited(r, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)) then
					tou:append(r)
				end
			end
			local targetr = room:askForPlayerChosen(player, tou, "shuanglian", "@@shuanglianslashtar", true, true)
			if targetr then
				room:broadcastSkillInvoke("shuanglian", 2)
			    local slashr = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
				slashr:setSkillName("shuangliancard")
				player:turnOver()
				room:useCard(sgs.CardUseStruct(slashr, player, targetr, true), true)
			end
			room:setPlayerFlag(player, "-shuanglian_jink")
		end
	end
	end,
}

zaizhancard = sgs.CreateSkillCard{
	name = "zaizhan",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getLostHp()
	end,
	on_use = function(self, room, source, targets)
	    source:loseMark("@zaizhan")
		room:doSuperLightbox("SANDROCK", "zaizhan")
		source:turnOver()
		local all = sgs.SPlayerList()
		for _,p in ipairs(targets) do
		    all:append(p)
		end
		room:drawCards(all, 1, self:objectName())
		for _,q in ipairs(targets) do
		    q:gainAnExtraTurn()
		end
	end,
}

zaizhanvs = sgs.CreateZeroCardViewAsSkill{
	name = "zaizhan" ,
	view_as = function()
	    local acard = zaizhancard:clone()
		acard:setSkillName("zaizhan")
		return acard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern) 
    return pattern == "@@zaizhan" and player:getMark("@zaizhan") > 0
end,
}

zaizhan = sgs.CreateTriggerSkill{
	name = "zaizhan",
	events = {sgs.GameStart, sgs.EventPhaseEnd},
	frequency = sgs.Skill_Limited,
	view_as_skill = zaizhanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getMark("@zaizhan") == 0 then
		    player:gainMark("@zaizhan")
		end
	end
	if event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Finish and player:getMark("@zaizhan") > 0 and player:isWounded() and
		room:askForSkillInvoke(player, self:objectName(), data) then
		    room:askForUseCard(player, "@@zaizhan", "#zaizhan")
		end
	end
	end,
}

SANDROCK:addSkill(shuanglian)
SANDROCK:addSkill(zaizhan)

ALTRON = sgs.General(extension, "ALTRON", "OTHERS", 4, true, false)

shuanglongcard = sgs.CreateSkillCard{
    name = "shuanglong",
    will_throw = false,
    target_fixed = false,
    filter = function(self,targets,to_select,player)
        return to_select:objectName() ~= player:objectName() and (not to_select:isKongcheng()) and #targets < 1
    end,
    on_effect=function(self,effect)          
        local room = effect.from:getRoom()
        if (effect.from:pindian(effect.to,"shuanglong",self)) then
			room:setPlayerFlag(effect.from, "shuanglong_success")
            room:addPlayerMark(effect.to, "Armor_Nullified")
			room:setPlayerFlag(effect.to, "shuanglongt")
        else
			room:setPlayerFlag(effect.from, "shuanglong_failed")
			if effect.from:isKongcheng() then return false end
			local froms = sgs.SPlayerList()
			for _,r in sgs.qlist(room:getAlivePlayers()) do
				if r:getEquips():length() > 0 then
					froms:append(r)
				end
			end
			local from = room:askForPlayerChosen(effect.from, froms, "shuanglong1", "shuanglong_movefrom", true, false)
			if from then
				local card_id = room:askForCardChosen(effect.from, from, "e", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if ((card:isKindOf("Weapon") and p:getWeapon() == nil) or
					(card:isKindOf("Armor") and p:getArmor() == nil) or
					(card:isKindOf("DefensiveHorse") and p:getDefensiveHorse() == nil) or
					(card:isKindOf("OffensiveHorse") and p:getOffensiveHorse() == nil) or
					(card:isKindOf("Treasure") and p:getTreasure() == nil)) and hasEquipArea(p, card:getSubtype()) then
						tos:append(p)
					end
				end
				if (not tos:isEmpty()) then
					local to = room:askForPlayerChosen(effect.from, tos, "shuanglong2", ("shuanglong_moveto:%s"):format(card:objectName()), false, false)
					if to then
						local discard = room:askForDiscard(effect.from, "shuanglong", 1, 1, true, false, "shuanglong-discard")
						if effect.from:getAI() and effect.from:getHandcardNum() > 1 then --For AI use only
							discard = room:askForDiscard(effect.from, "shuanglong", 1, 1, false, false, "shuanglong-discard")
						end
						if discard then
							room:moveCardTo(card, to, place, true)
						end
					end
				end
			end
	    end
    end
}

shuanglongvs = sgs.CreateViewAsSkill{
    name = "shuanglong",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as=function(self, cards)
	if #cards == 1 then
        local acard = shuanglongcard:clone()
        acard:addSubcard(cards[1])                
        acard:setSkillName("shuanglong")
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return not (player:hasFlag("shuanglong_success") or player:hasFlag("shuanglong_failed"))
    end
}

shuanglong = sgs.CreateTriggerSkill
{
	name = "shuanglong",
	events = {sgs.EventPhaseStart,sgs.Death},
	view_as_skill = shuanglongvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	if (event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish))
		or (event == sgs.Death and data:toDeath().who:hasSkill(self:objectName())) then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("Armor_Nullified") > 0 then
					room:removePlayerMark(p,"Armor_Nullified")
				end
				if p:hasFlag("shuanglongt") then
					room:setPlayerFlag(p,"-shuanglongt")
				end
			end
		end
	end
}

shuanglongdis = sgs.CreateDistanceSkill{
   name = "#shuanglongdis",
   correct_func = function(self, from, to)
       if from and from:hasFlag("shuanglong_success") and to and to:hasFlag("shuanglongt") then
		   return -998
		end
	end
}

shuanglongslash = sgs.CreateTargetModSkill{
	name = "#shuanglongslash",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player and player:hasFlag("shuanglong_success") then
			return 998
		else
		    return 0
		end
	end
}

shuanglongp = sgs.CreateProhibitSkill
{
	name = "#shuanglongp",
	is_prohibited = function(self, from, to, card)
		if from and from:hasFlag("shuanglong_success") and from:getSlashCount() >= 1 and
		(not(from:getWeapon() and from:getWeapon():getClassName() == "Crossbow")) and to and (not to:hasFlag("shuanglongt")) then
			return card:isKindOf("Slash")
		end
	end
}

ALTRON:addSkill(shuanglong)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#shuanglongdis") then skills:append(shuanglongdis) end
if not sgs.Sanguosha:getSkill("#shuanglongslash") then skills:append(shuanglongslash) end
if not sgs.Sanguosha:getSkill("#shuanglongp") then skills:append(shuanglongp) end
sgs.Sanguosha:addSkills(skills)

DX = sgs.General(extension, "DX", "OTHERS", 4, true, false)

dxpoint = sgs.CreateTargetModSkill{
	name = "#dxpoint",
	pattern = "Slash",
	extra_target_func = function(self, player)
	if player and player:hasSkill(self:objectName()) and player:getMark("@point") >= 2 then
		return 1
	end
	end,
}

yueguang = sgs.CreateTriggerSkill{
	name = "yueguang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
	if player:getPhase() == sgs.Player_Start then
	    local judge = sgs.JudgeStruct()
		judge.pattern = ".|black"
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
		    room:broadcastSkillInvoke("yueguang",math.random(1,2))
		    player:gainMark("@point")
			if player:getMark("@point") == 2 then
			    local log = sgs.LogMessage()
				log.from = player
				log.type = "#point"
				log.arg = "#dxpoint"
				room:sendLog(log)
			end
		else
		    room:broadcastSkillInvoke("yueguang",math.random(3,4))
		    player:loseMark("@point")
		end
	end
	end,
}

weibocard = sgs.CreateSkillCard{
	name = "weibo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
        source:loseMark("@point")
		source:addMark("weibo")
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#weibo"
        room:sendLog(log)
	end,
}

weibovs = sgs.CreateViewAsSkill{
    name = "weibo",
    n = 0,
    view_as = function(self, cards)
	if #cards == 0 then
        local acard = weibocard:clone()               
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return player:getMark("@point") >= 1
    end,
}

weibo = sgs.CreateTriggerSkill{
	name = "weibo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ConfirmDamage,sgs.CardFinished,sgs.EventPhaseStart},
	view_as_skill = weibovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local use = data:toCardUse()
	if event == sgs.ConfirmDamage and damage.card and damage.card:isKindOf("Slash") and player:getMark("weibo") > 0 then
        local x = player:getMark("weibo")
		--room:setPlayerMark(player,"weibo",0)
		damage.damage = damage.damage + x
		data:setValue(damage)
		return false
	elseif event == sgs.CardFinished and use.card:isKindOf("Slash") and player:getMark("weibo") > 0 then
	    room:setPlayerMark(player,"weibo",0)
	elseif event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and player:getMark("weibo") > 0 then
	    room:setPlayerMark(player,"weibo",0)
	end
	end,
}

weixingcard = sgs.CreateSkillCard{
	name = "weixing",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
        source:loseMark("@point",2)
		source:addMark("weixing")
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#weixing"
        room:sendLog(log)
	end,
}

weixingvs = sgs.CreateViewAsSkill{
    name = "weixing",
    n = 0,
    view_as = function(self, cards)
	if #cards == 0 then
        local acard = weixingcard:clone()               
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return player:getMark("@point") >= 2
    end,
}

weixing = sgs.CreateTriggerSkill{
	name = "weixing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified,sgs.CardFinished,sgs.EventPhaseStart},
	view_as_skill = weixingvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if event == sgs.TargetSpecified and use.card and use.card:isKindOf("Slash") and player:getMark("weixing") > 0 then
        room:setPlayerMark(player,"weixing",0)
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			jink_table[index] = 0
		end
		index = index + 1
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	elseif event == sgs.CardFinished and use.card:isKindOf("Slash") and player:getMark("weixing") > 0 then
	    room:setPlayerMark(player,"weixing",0)
	elseif event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and player:getMark("weixing") > 0 then
	    room:setPlayerMark(player,"weixing",0)
	end
	end,
}

difacard = sgs.CreateSkillCard{
	name = "difa",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_effect = function(self, effect)
	end
}

difavs = sgs.CreateOneCardViewAsSkill{
	name = "difa",
	response_pattern = "@@difa",
	expand_pile = "difa",
	filter_pattern = ".|.|.|difa",
	view_as = function(self, card)
	    local acard = difacard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end
}

difa = sgs.CreateTriggerSkill{
	name = "difa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.AskForRetrial},
	view_as_skill = difavs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card then
				local id = damage.card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("damage")) then
						room:broadcastSkillInvoke("difa")
						player:addToPile("difa",damage.card)
					end
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:getPile("difa"):length() == 0 or judge.who:objectName() ~= player:objectName() then return false end
			local prompt_list = {
				"@difa-card" ,
				judge.who:objectName() ,
				self:objectName() ,
				judge.reason ,
				string.format("%d", judge.card:getEffectiveId())
			}
			local prompt = table.concat(prompt_list, ":")
			local ai_data = sgs.QVariant()
			ai_data:setValue(judge)
			player:setTag("difa", ai_data)
			local card = room:askForUseCard(player, "@@difa", prompt, -1, sgs.Card_MethodResponse)
			if card then
				room:retrial(card, player, judge, self:objectName())
			end
			player:removeTag("difa")
		end
	end,
}

DX:addSkill(dxpoint)
DX:addSkill(yueguang)
DX:addSkill(weibo)
DX:addSkill(weixing)
DX:addSkill(difa)

GINN = sgs.General(extension, "GINN", "ZAFT", 5, true, false)

laobing = sgs.CreateTriggerSkill
{
	name = "laobing",
	events = {sgs.StartJudge,sgs.FinishRetrial, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.StartJudge and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:broadcastSkillInvoke("laobing")
		local suit = room:askForSuit(player,self:objectName())
		if suit then
			local suit_str = sgs.Card_Suit2String(suit)
			local log = sgs.LogMessage()
			log.type = "#ChooseSuit"
			log.from = player
			log.arg = suit_str
			room:sendLog(log)
		    room:setPlayerMark(player,suit_str,1)
		end
	end
	if event == sgs.FinishRetrial and
	(player:getMark("spade") == 1 or player:getMark("heart") == 1 or player:getMark("club") == 1 or player:getMark("diamond") == 1) then
		local judge = data:toJudge()
		local suit_str = judge.card:getSuitString()
		room:addPlayerMark(player, suit_str)
		if player:getMark(suit_str) == 2 then
		    room:setEmotion(player, "judgegood")
			if player:isWounded() then
			    local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
				room:recover(player,recover)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGEDONE, player:objectName(), self:objectName(), nil)
            room:throwCard(judge.card, reason, nil)
			local ju = sgs.JudgeStruct()
			ju.reason = judge.reason
			ju.who = player
			ju.pattern = judge.pattern
			room:judge(ju)
			room:retrial(ju.card, player, judge, self:objectName())
			room:obtainCard(player, ju.card)
		else
		    room:setEmotion(player, "judgebad")
		    room:setPlayerFlag(player, "laobingfailed")
		end
		    room:setPlayerMark(player,"spade",0)
		    room:setPlayerMark(player,"heart",0)
		    room:setPlayerMark(player,"club",0)
		    room:setPlayerMark(player,"diamond",0)
			return true
		end
		if event == sgs.FinishJudge and player:hasFlag("laobingfailed") then
		    local judge = data:toJudge()
			room:setPlayerFlag(player, "-laobingfailed")
			room:obtainCard(player, judge.card)
			return true
		end
	end,
}

baopo = sgs.CreateTriggerSkill
{
	name = "baopo",
	events = {sgs.Damage},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") and damage.to:getEquips():length() > 0 and not player:isNude() and
	damage.to:objectName() ~= player:objectName() and not damage.chain and not damage.transfer and
	room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke("baopo")
	    if room:askForDiscard(player, self:objectName(), 1, 1, false, true) then
	        room:throwCard(room:askForCardChosen(player, damage.to, "e", self:objectName()), damage.to, player)
		end
	end
    end,
}

GINN:addSkill(laobing)
GINN:addSkill(baopo)

STRIKE = sgs.General(extension, "STRIKE", "OMNI", 4, true, false)

huanzhuang = sgs.CreateTriggerSkill
{
	name = "huanzhuang",
	events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local log = sgs.LogMessage()
				if player:getMark("@liren") > 0 then
					log.type = "#huanzhuangexn"
				else
					log.type = "#huanzhuangn"
				end
				if room:askForSkillInvoke(player,self:objectName(),data) then
					room:broadcastSkillInvoke("huanzhuang", math.random(2))
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					room:getThread():delay(0250)
					if judge:isGood() then
						if player:getMark("@liren") > 0 then
							log.type = "#huanzhuangexb"
						else
							log.type = "#huanzhuangb"
						end
						room:broadcastSkillInvoke("huanzhuang", 5)
						room:setPlayerMark(player, "huanzhuangb", 1)
					else
						if player:getMark("@liren") > 0 then
							log.type = "#huanzhuangexr"
						else
							log.type = "#huanzhuangr"
						end
						room:broadcastSkillInvoke("huanzhuang", 4)
						room:setPlayerMark(player, "huanzhuangr", 1)
					end
				else
					room:broadcastSkillInvoke("huanzhuang", 3)
					room:setPlayerMark(player, "huanzhuangn", 1)
				end
				room:sendLog(log)
			end
		end
    end
}

huanzhuangeffect = sgs.CreateTriggerSkill
{
	name = "#huanzhuangeffect",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.SlashMissed, sgs.ConfirmDamage},
	global = true,
	can_trigger = function(self, player)
		return player and (player:getMark("huanzhuangb") > 0 or player:getMark("huanzhuangr") > 0 or player:getMark("huanzhuangn") > 0)
	end,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("huanzhuangn") > 0 then
					room:sendCompulsoryTriggerLog(player, "huanzhuang")
					player:drawCards(1)
					if player:getMark("@liren") > 0 then
						room:askForUseCard(player, "slash", "@dummy-slash") --Use lower case "slash" so that AI can use.
					end
				end
				room:setPlayerMark(player, "huanzhuangb", 0)
				room:setPlayerMark(player, "huanzhuangr", 0)
				room:setPlayerMark(player, "huanzhuangn", 0)
			end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				room:setPlayerMark(player, "huanzhuangb", 0)
				room:setPlayerMark(player, "huanzhuangr", 0)
				room:setPlayerMark(player, "huanzhuangn", 0)
			end
		elseif event == sgs.SlashMissed then
			if player:getMark("@liren") > 0 then return false end
			local effect = data:toSlashEffect()
			if player:getMark("huanzhuangb") > 0 and effect.to:canDiscard(player, "h") and room:askForSkillInvoke(effect.to, "huanzhuang", sgs.QVariant("throw:"..player:objectName())) then
				room:throwCard(room:askForCardChosen(effect.to, effect.from, "h", self:objectName(), false, sgs.Card_MethodDiscard), player, effect.to)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card and damage.card:isKindOf("Slash") and player:getMark("huanzhuangb") > 0 then
				room:sendCompulsoryTriggerLog(player, "huanzhuang")
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
    end
}

huanzhuangd = sgs.CreateAttackRangeSkill{
	name = "#huanzhuangd",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("huanzhuangr") > 0 then
			return 1
		end
	end
}

--[[xiangzhuan = sgs.CreateTriggerSkill
{
	name = "xiangzhuan",
	events = {sgs.DamageForseen},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") and damage.card:isBlack() and not player:getEquips():isEmpty() and player:canDiscard(player, "e") and room:askForSkillInvoke(player, self:objectName(), data) then
	    local card = room:askForCardChosen(player, player, "e", self:objectName(), false, sgs.Card_MethodDiscard)
		if card then
			if player:getGeneralName() == "STRIKE" then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			elseif player:getGeneralName() == "AEGIS" then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			end
			room:throwCard(card, player, player)
			room:notifySkillInvoked(player, self:objectName())
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#xiangzhuan"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
	        return true
		end
	end
    end,
}]]

liren = sgs.CreateTriggerSkill
{
	name = "liren",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getMark("@liren") == 0 then
			room:setEmotion(player, "zhongzi")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke("liren")
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:setPlayerMark(player, "liren", 1)
			player:gainMark("@liren")
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
		end
	end
}

huanzhuangs = sgs.CreateTargetModSkill{
	name = "#huanzhuangs",
	pattern = "Slash",
	residue_func = function(self, player)
		if player and player:getMark("@liren") > 0 and player:getMark("huanzhuangr") > 0 then
			return 1
		else
			return 0
		end
	end
}

STRIKE:addSkill(huanzhuang)
--STRIKE:addSkill(xiangzhuan)
STRIKE:addSkill(liren)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#huanzhuangeffect") then skills:append(huanzhuangeffect) end
if not sgs.Sanguosha:getSkill("#huanzhuangd") then skills:append(huanzhuangd) end
if not sgs.Sanguosha:getSkill("#huanzhuangs") then skills:append(huanzhuangs) end
sgs.Sanguosha:addSkills(skills)

AEGIS = sgs.General(extension, "AEGIS", "ZAFT", 4, true, false)

jiechicard = sgs.CreateSkillCard
{
	name = "jiechi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		if to_select:objectName() == player:objectName() then return false end
		return to_select:getEquips():length() > 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:throwCard(room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard), effect.to, effect.from)
	end
}

jiechivs = sgs.CreateViewAsSkill
{
	name = "jiechi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	if #cards == 1 then
		local acard = jiechicard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName(self:objectName())
		return acard
	end
	end,
}

jiechi = sgs.CreateTriggerSkill
{
	name = "jiechi",
	events = {sgs.PreCardUsed},
	view_as_skill = jiechivs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() then
			local name = use.to:first():getGeneralName()
			if name == "STRIKE" or name == "FREEDOM" or name == "FREEDOM_D" or name == "SF" then
				room:broadcastSkillInvoke(self:objectName(), 3)
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			end
			return true
		end
	end,
}

juexincard = sgs.CreateSkillCard
{
	name = "juexin",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		return to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setEmotion(effect.from, "juexin")
		effect.from:loseMark("@juexin")
		effect.from:throwAllHandCards()
		room:setPlayerMark(effect.to, "@2887", 1)
	end
}

juexinvs = sgs.CreateViewAsSkill
{
	name = "juexin",
	n = 0,
	view_as = function(self, cards)
		local acard = juexincard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@juexin") > 0
	end,
}

juexin = sgs.CreateTriggerSkill
{
	name = "juexin",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Limited,
	view_as_skill = juexinvs,
	limit_mark = "@juexin",
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == self:objectName() then
			local to = use.to:first()
			if to:getGeneralName() == "STRIKE" or string.find(to:getGeneralName(), "FREEDOM") or to:getGeneralName() == "SF" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:getThread():delay(1500)
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			return true
		end
	end,
}

juexineffect = sgs.CreateTriggerSkill
{
	name = "#juexineffect",
	events = {sgs.TurnStart},
	global = true,
	can_trigger = function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.TurnStart and player:getMark("@2887") > 0 then
	    room:setPlayerMark(player, "@2887", 0)
	    local judge = sgs.JudgeStruct()
		judge.pattern = ".|^spade"
		judge.good = false
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
			room:setEmotion(player, "juexin2")
			room:getThread():delay(2000)
		    room:loseHp(player, 2)
			local selfplayer = room:findPlayerBySkillName("juexin")
			if selfplayer:isAlive() then
				room:killPlayer(selfplayer)
			end
		end
	end
	end,
}

AEGIS:addSkill(jiechi)
AEGIS:addSkill(juexin)
AEGIS:addSkill(juexineffect)
--AEGIS:addSkill("xiangzhuan")

BUSTER = sgs.General(extension, "BUSTER", "ZAFT", 4, true, false)

shuangqiangvs = sgs.CreateViewAsSkill
{
	name = "shuangqiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not (to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard")) then return false end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(to_select:getEffectiveId())
		slash:deleteLater()
		return slash:isAvailable(sgs.Self)
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName("shuangqiang")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Play
	end,
}

shuangqiang = sgs.CreateTriggerSkill
{
	name = "shuangqiang",
	events = {sgs.Damage},
	view_as_skill = shuangqiangvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "shuangqiang" and not damage.chain and not damage.transfer then
		local subcard = sgs.Sanguosha:getCard(damage.card:getSubcards():first())
	    if subcard:isKindOf("EquipCard") and damage.to:getEquips():length() > 0 then
		    room:throwCard(room:askForCardChosen(player, damage.to, "e", self:objectName(), false, sgs.Card_MethodDiscard), damage.to, player)
		elseif subcard:isKindOf("TrickCard") and not damage.to:isKongcheng() then
	        room:throwCard(room:askForCardChosen(player, damage.to, "h", self:objectName(), false, sgs.Card_MethodDiscard), damage.to, player)
		end
	end
	end,
}

zuzhuangvs = sgs.CreateViewAsSkill
{
	name = "zuzhuang",
	n = 2,
	view_filter = function(self, selected, to_select)
		if not (to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard")) then return false end
		if #selected == 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		elseif #selected == 1 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			if selected[1]:isKindOf("EquipCard") then
				return to_select:isKindOf("TrickCard") and slash:isAvailable(sgs.Self)
			elseif selected[1]:isKindOf("TrickCard") then
				return to_select:isKindOf("EquipCard") and slash:isAvailable(sgs.Self)
			end
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local acard = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1) 
			acard:addSubcard(cards[1])
			acard:addSubcard(cards[2])
			acard:setSkillName("zuzhuang")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Play
	end,
}

zuzhuang = sgs.CreateTriggerSkill
{
	name = "zuzhuang",
	events = {sgs.Damage},
	view_as_skill = zuzhuangvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()		
	if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "zuzhuang" and not damage.chain and not damage.transfer then
		local pattern = {}
		if damage.to:isNude() then return false end
		if damage.to:getEquips():length() > 0 then
			table.insert(pattern, "zze")
		end
		if not damage.to:isKongcheng() then
			table.insert(pattern, "zzh")
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), sgs.QVariant(damage.to:objectName()))
	    if choice == "zze" then
		    damage.to:throwAllEquips()
		elseif choice == "zzh" then
	        damage.to:throwAllHandCards()
		end
	end
	end,
}

BUSTER:addSkill(shuangqiang)
BUSTER:addSkill(zuzhuang)

DUEL_AS = sgs.General(extension, "DUEL_AS", "ZAFT", 4, true, false)

sijuevs = sgs.CreateViewAsSkill
{
	name = "sijue",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isBlack() and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return true
	end,
}

sijue = sgs.CreateTriggerSkill
{
	name = "sijue",
	events = {sgs.TargetSpecified},
	view_as_skill = sijuevs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() then
	    for _,p in sgs.qlist(use.to) do
			p:drawCards(1)
		end
	end
	end,
}

pojia = sgs.CreateTriggerSkill
{
	name = "pojia",
	events = {sgs.Damaged, sgs.DamageForseen},
	frequency = sgs.Skill_Limited,
	limit_mark = "@pojia",
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Damaged and player:getMark("@pojia") > 0 and player:getEquips():length() > 0 and damage.from and room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke(self:objectName())
		player:loseMark("@pojia")
		room:doSuperLightbox("DUEL_AS", self:objectName())
		player:throwAllEquips()
	    for i=1, 2, 1 do
			if damage.from:isDead() then return false end
		    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		    duel:setSkillName("pojiacard")
			local use = sgs.CardUseStruct()
            use.from = player
            use.to:append(damage.from)
            use.card = duel
            room:useCard(use)
		end
	elseif event == sgs.DamageForseen and damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == "pojiacard" then
	    return true
	end
	end,
}

DUEL_AS:addSkill(sijue)
DUEL_AS:addSkill(pojia)

BLITZ = sgs.General(extension, "BLITZ", "ZAFT", 4, true, false)

yinxian = sgs.CreateTriggerSkill
{
	name = "yinxian",
	events = {sgs.CardResponded, sgs.ConfirmDamage, sgs.TargetSpecified, sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.CardResponded then
		local card = data:toCardResponse().m_card
		if card and card:isKindOf("Jink") and player:getMark("@yinxian") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
			room:setPlayerMark(player, "@yinxian", 1)
			local log = sgs.LogMessage()
			log.type = "#EnterYinxian"
			log.from = player
			room:sendLog(log)
			if player:getGeneralName() == "BLITZ" or player:getGeneral2Name() == "BLITZ" then
				room:changeHero(player, "BLITZ_Y", false, false, player:getGeneralName() ~= "BLITZ", false)
			end
		end
	elseif event == sgs.ConfirmDamage then
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			damage.nature = sgs.DamageStruct_Thunder
			data:setValue(damage)
			return false
		end
	elseif event == sgs.TargetSpecified then
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				jink_table[index] = 0
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		end
	elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			room:broadcastSkillInvoke(self:objectName(), math.random(4, 6))
			room:setPlayerMark(player, "@yinxian", 0)
			local log = sgs.LogMessage()
			log.type = "#RemoveYinxian"
			log.from = player
			room:sendLog(log)
			if player:getGeneralName() == "BLITZ_Y" or player:getGeneral2Name() == "BLITZ_Y" then
				room:changeHero(player, "BLITZ", false, false, player:getGeneralName() ~= "BLITZ_Y", false)
			end
		end
	end
	end,
}

yinxiand = sgs.CreateDistanceSkill{
	name = "#yinxiand",
	correct_func = function(self, from, to)
		if to:hasSkill("yinxian") and to:getMark("@yinxian") > 0 then
			return 1
		else
			return 0
		end
	end
}

zhuanjin = sgs.CreateTriggerSkill
{
	name = "zhuanjin",
	events = {sgs.GameStart, sgs.Dying},
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("@zhuanjin") == 0 then
				player:gainMark("@zhuanjin")
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() and player:getMark("@zhuanjin") > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
				if dying.who:getGeneralName() == "AEGIS" or dying.who:getGeneralName() == "JUSTICE" or dying.who:getGeneralName() == "SAVIOUR" then
					room:broadcastSkillInvoke(self:objectName(), 2)
				else
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				player:loseMark("@zhuanjin")
				room:doSuperLightbox("BLITZ", self:objectName())
				--room:setPlayerProperty(dying.who, "hp", sgs.QVariant(1))
				room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
				dying.who:drawCards(player:getLostHp() + dying.who:getLostHp())
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("zhuanjincard")
				if dying.damage.from and dying.damage.from:isAlive() and not player:isProhibited(player, slash) then
					local use = sgs.CardUseStruct()
					use.from = dying.damage.from
					use.to:append(player)
					use.card = slash
					room:useCard(use)
				end
			end
		end
	end
}

BLITZ:addSkill(yinxian)
BLITZ:addSkill(yinxiand)
BLITZ:addSkill(zhuanjin)
extension:insertRelatedSkills("yinxian", "#yinxiand")

BLITZ_Y = sgs.General(extension, "BLITZ_Y", "ZAFT", 4, true, true, true)--海市蜃楼特效

BLITZ_Y:addSkill("yinxian")
BLITZ_Y:addSkill("#yinxiand")
BLITZ_Y:addSkill("zhuanjin")

FREEDOM = sgs.General(extension, "FREEDOM", "ORB", 3, true, false)

helie = sgs.CreateTriggerSkill{
	name = "helie",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			if string.find(player:getGeneralName(), "FREEDOM") then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			elseif string.find(player:getGeneralName(), "JUSTICE") then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			elseif string.find(player:getGeneralName(), "PROVIDENCE") then
				room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
			end
			player:throwAllHandCards()
			player:drawCards(player:getMaxHp())
		end
	end,
}

jiaoxie = sgs.CreateTriggerSkill{
	name = "jiaoxie",
	events = {sgs.EnterDying},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and dying.damage.from and dying.damage.from:objectName() ~= dying.who:objectName() then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local target
				if dying.damage.from:objectName() == p:objectName() then
					target = dying.who
				elseif dying.who:objectName() == p:objectName() then
					target = dying.damage.from
				end
				if target == nil then return false end
				local skill_list = {}
				for _,skill in sgs.qlist(target:getVisibleSkillList()) do
					if (not table.contains(skill_list, skill:objectName())) and (not skill:isAttachedLordSkill())
						and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Wake then
						table.insert(skill_list, skill:objectName())
					end
				end
				if #skill_list > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					local choice = room:askForChoice(p, self:objectName(), table.concat(skill_list, "+"), data)
					if choice then
						if target:getGeneralName() == "PROVIDENCE" then
							room:broadcastSkillInvoke(self:objectName(), 3)
						else
							room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
						end
						room:doSuperLightbox("FREEDOM", choice)
						room:detachSkillFromPlayer(target, choice)
					end
				end
			end
		end
	end,
}

zhongzi = sgs.CreateTriggerSkill{
	name = "zhongzi",
	events = {sgs.AskForPeachesDone},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	    local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getHp() < 1 and player:getMark("@seed") == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, "zhongzi")
			player:gainMark("@seed")
			room:setEmotion(player, "zhongzi")
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:broadcastSkillInvoke(self:objectName(), 2)
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
			room:detachSkillFromPlayer(player, "jiaoxie")
			room:acquireSkill(player, "qishe")
		end
	end,
}

qishe = sgs.CreateViewAsSkill{
	name = "qishe",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
			card:addSubcards(sgs.Self:getHandcards())
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and sgs.Slash_IsAvailable(player)
	end,
}

qishes = sgs.CreateTargetModSkill{
	name = "#qishes",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("qishe") and card:getSkillName() == "qishe" then
			return card:subcardsLength() - 1
		end
	end,
	distance_limit_func = function(self, player, card)
		if player and player:hasSkill("qishe") and card:getSkillName() == "qishe" then
			return 998
		end
	end
}

qishea = sgs.CreateTriggerSkill
{
	name = "#qishea",
	events = {sgs.PreCardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "qishe" then
			room:broadcastSkillInvoke("qishe")
			room:setEmotion(player, "qishe")
			room:getThread():delay(2100)
			room:broadcastSkillInvoke("gdsbgm", 1)
			return true
		end
	end,
}

FREEDOM:addSkill(helie)
FREEDOM:addSkill(jiaoxie)
FREEDOM:addSkill(zhongzi)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("qishe") then skills:append(qishe) end
if not sgs.Sanguosha:getSkill("#qishes") then skills:append(qishes) end
if not sgs.Sanguosha:getSkill("#qishea") then skills:append(qishea) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("qishe", "#qishes")
extension:insertRelatedSkills("qishe", "#qishea")
FREEDOM:addRelateSkill("qishe")

JUSTICE = sgs.General(extension, "JUSTICE", "ORB", 4, true, false)

shouwangvs = sgs.CreateZeroCardViewAsSkill
{
	name = "shouwang",
	view_as = function(self, cards)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		peach:setSkillName(self:objectName())
		return peach
	end,
	enabled_at_play = function(self, player)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		return peach:isAvailable(player) and player:getMaxHp() > 0 and player:getMark("Global_PreventPeach") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and player:getMaxHp() > 0 and player:getMark("Global_PreventPeach") == 0
	end
}

shouwang = sgs.CreateTriggerSkill
{
	name = "shouwang",
	events = {sgs.PreCardUsed},
	view_as_skill = shouwangvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Peach") and use.card:getSkillName() == "shouwang" then
			room:loseMaxHp(player)
		end
	end,
}

zhongzij = sgs.CreateTriggerSkill
{
	name = "zhongzij",
	events = {sgs.MaxHpChanged},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getMaxHp() == 1 and player:getMark("@seedj") == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, "zhongzij")
			player:gainMark("@seedj")
			room:setEmotion(player, "zhongzij")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke(self:objectName())
			local log = sgs.LogMessage()
			log.type = "#GainMaxHp"
			log.from = player
			log.arg = 3 - player:getMaxHp()
			room:sendLog(log)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(3))
			room:detachSkillFromPlayer(player, "shouwang")
			room:acquireSkill(player, "huiwu")
			room:getThread():delay(4000)
		end
	end,
}

huiwu = sgs.CreateTriggerSkill
{
	name = "huiwu",
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play and not player:hasFlag("huiwu") and not player:isKongcheng() then
			if use.card:isBlack() then
				local can_invoke = false
				for _,p in sgs.qlist(use.to) do
					if p:isAlive() and p:getEquips():length() > 0 then
						can_invoke = true
					end
				end
				if can_invoke and room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerFlag(player, "huiwu")
					if player:getGeneralName() == "FREEDOM_D" then
						if use.to:first():getGeneralName() == "PROVIDENCE" then
							room:broadcastSkillInvoke("jiaoxie", 3)
						else
							room:broadcastSkillInvoke("jiaoxie", math.random(1, 2))
						end
					else
						room:broadcastSkillInvoke(self:objectName())
					end
					player:throwAllHandCards()
					for _,q in sgs.qlist(use.to) do
						if q:isAlive() and q:getEquips():length() > 0 then
							room:throwCard(room:askForCardChosen(player, q, "e", self:objectName()), q, player)
						end
					end
				end
			elseif use.card:isRed() then
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(use.to) do
					if p:isAlive() then
						tos:append(p)
					end
				end
				if (not tos:isEmpty()) and room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerFlag(player, "huiwu")
					if player:getGeneralName() == "FREEDOM_D" then
						if use.to:first():getGeneralName() == "PROVIDENCE" then
							room:broadcastSkillInvoke("jiaoxie", 3)
						else
							room:broadcastSkillInvoke("jiaoxie", math.random(1, 2))
						end
					else
						room:broadcastSkillInvoke(self:objectName())
					end
					player:throwAllHandCards()
					use.to = tos
					room:useCard(use)
				end
			end
		end
	end,
}

JUSTICE:addSkill("helie")
JUSTICE:addSkill(shouwang)
JUSTICE:addSkill(zhongzij)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("huiwu") then skills:append(huiwu) end
sgs.Sanguosha:addSkills(skills)
JUSTICE:addRelateSkill("huiwu")

CFR = sgs.General(extension, "CFR", "OMNI", 3, true, false)

wenshencard = sgs.CreateSkillCard{
	name = "wenshen",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local pattern = {}
		if sgs.Analeptic_IsAvailable(source) then
			table.insert(pattern, "analeptic")
		end
	    if sgs.Slash_IsAvailable(source) then
			table.insert(pattern, "slash")
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(pattern, "+"))
		if choice then
			room:setPlayerProperty(source, "wenshen", sgs.QVariant(choice))
			room:askForUseCard(source, "@@wenshen", "@wenshen:"..choice)
			room:setPlayerProperty(source, "wenshen", sgs.QVariant())
		end
	end
}

wenshenvs = sgs.CreateViewAsSkill{
	name = "wenshen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if sgs.Self:property("wenshen"):toString() == "slash" then
			if sgs.Self:getSlashCount() > 0 and not sgs.Self:canSlashWithoutCrossbow() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getClassName() == "Crossbow" then
				return to_select:isKindOf("EquipCard") and not (to_select:isEquipped() and to_select:objectName() == "crossbow") and (not to_select:hasFlag("using"))
			end
		end
		return to_select:isKindOf("EquipCard") and (not to_select:hasFlag("using"))
	end,
	view_as = function(self, cards)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 0 then
				local acard = wenshencard:clone()
				acard:setSkillName(self:objectName())
				return acard
			end
		else
			if #cards == 1 then
				local acard
				if pattern == "@@wenshen" then
					local name = sgs.Self:property("wenshen"):toString()
					if name then
						acard = sgs.Sanguosha:cloneCard(name, cards[1]:getSuit(), cards[1]:getNumber())
					end
				elseif pattern == "slash" then
					acard = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
				else
					acard = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
				end
				acard:addSubcard(cards[1])
				acard:setSkillName(self:objectName())
				return acard
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) or sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@wenshen" or string.find(pattern, "analeptic") or (pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
	end
}

wenshen = sgs.CreateTriggerSkill
{
	name = "wenshen",
	events = {sgs.PreCardUsed},
	view_as_skill = wenshenvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "wenshen" and use.card:isKindOf("SkillCard") then
			return true
		end
	end
}

jinduan = sgs.CreateTriggerSkill
{
	name = "jinduan",
	events = {sgs.TargetConfirming},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:isRed() and use.to:contains(player) and
			use.from:objectName() ~= player:objectName() and room:alivePlayerCount() > 2 then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			for _,p in sgs.qlist(players) do
				if p:isProhibited(p, use.card) then
					players:removeOne(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "@jinduan", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), target:objectName())
					local log1 = sgs.LogMessage()
					log1.type = "$CancelTarget"
					log1.from = use.from
					log1.arg = use.card:objectName()
					log1.to:append(player)
					room:sendLog(log1)
					local log2 = sgs.LogMessage()
					log2.type = "#BecomeTarget"
					log2.from = target
					log2.card_str = use.card:toString()
					room:sendLog(log2)
					use.to:removeOne(player)
					use.to:append(target)
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			end
		end
	end
}

liesha = sgs.CreateTriggerSkill
{
	name = "liesha",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:isBlack() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)
		end
	end
}

CFR:addSkill(wenshen)
CFR:addSkill(jinduan)
CFR:addSkill(liesha)

PROVIDENCE = sgs.General(extension, "PROVIDENCE", "ZAFT", 4, true, false)

longqi = sgs.CreateTriggerSkill{
	name = "longqi",
	events = {sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local card = data:toCardResponse().m_card
		local room = player:getRoom()
		if card and card:isKindOf("Jink") then
			local invoked = false
			while true do
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() then
						players:append(p)
					end
				end
				if players:isEmpty() then break end
				local cn = card:getNumber()
				room:setPlayerMark(player, "longqi_ai", cn)
				local target = room:askForPlayerChosen(player, players, self:objectName(), "@longqi:"..cn, true, true)
				if target then
					local id = room:askForCardChosen(player, target, "h", self:objectName(), true, sgs.Card_MethodDiscard)
					if id ~= -1 then
						room:setPlayerMark(player, "longqi_ai", 0)
						if not invoked then
							invoked = true
							room:broadcastSkillInvoke(self:objectName())
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), target:objectName(), self:objectName(), "")
						local to_throw = sgs.Sanguosha:getCard(id)
						room:throwCard(to_throw, reason, target, player)
						if cn == 0 then break end
						local idn = to_throw:getNumber()
						if idn == cn then
							local d = sgs.DamageStruct()
							d.from = player
							d.to = target
							d.damage = 1
							room:damage(d)
							break
						elseif math.abs(idn-cn) > 1 then
							break
						end
					else
						break
					end
				else
					break
				end
			end
		end
	end
}

chuangshi = sgs.CreateTriggerSkill
{
	name = "chuangshi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    local damage = data:toDamage()
		if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and damage.damage >= player:getHp() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:loseMaxHp(player)
			local d = sgs.DamageStruct()
			if player:isAlive() then
				d.from = player
			end
			d.to = damage.from
			d.damage = damage.damage
			room:damage(d)
		end
	end
}

PROVIDENCE:addSkill("helie")
PROVIDENCE:addSkill(longqi)
PROVIDENCE:addSkill(chuangshi)

CAG = sgs.General(extension, "CAG", "OMNI", 3, true, false)
CAG:setGender(sgs.General_Neuter)

hunduncard = sgs.CreateSkillCard
{
	name = "hundun",	
	target_fixed = false,	
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		return #targets < 2 and (not to_select:isProhibited(to_select, slash)) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
	    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("hunduncard")
		local use = sgs.CardUseStruct()
		use.from = source
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
		use.card = slash
		room:useCard(use, false)
	end
}

hundunvs = sgs.CreateZeroCardViewAsSkill
{
	name = "hundun",
	response_pattern = "@@hundun",
	view_as = function()
		return hunduncard:clone()
	end
}

hundun = sgs.CreateTriggerSkill
{
	name = "hundun",
	events = {sgs.TurnedOver},
	view_as_skill = hundunvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:faceUp() then
		    room:askForUseCard(player, "@@hundun", "@hundun")
		end
	end
}

shenyuan = sgs.CreateTriggerSkill
{
	name = "shenyuan",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isRed() and (not damage.card:isKindOf("SkillCard")) and (not player:isKongcheng())
			and room:askForDiscard(player, self:objectName(), 1, 1, (not player:getAI()), false, "@shenyuan") then
		    room:broadcastSkillInvoke(self:objectName())
			player:turnOver()
			local log = sgs.LogMessage()
			log.type = "#burstd"
			log.to:append(player)
			log.arg = damage.damage
			log.arg2 = damage.damage - 1
			room:sendLog(log)
			damage.damage = damage.damage - 1
			if damage.damage < 1 then
				room:setEmotion(player, "skill_nullify")
				return true
			end
			data:setValue(damage)
		end
	end
}

dadivs = sgs.CreateZeroCardViewAsSkill{
	name = "dadi",
	view_filter = function(self, card)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(sgs.Self:getHandcards():first())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(sgs.Self:getHandcards():first())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getHandcardNum() == 1
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and player:getHandcardNum() == 1
	end
}

dadi = sgs.CreateTriggerSkill
{
	name = "dadi",
	events = {sgs.TargetSpecified, sgs.CardUsed, sgs.CardResponded},
	view_as_skill = dadivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "dadi" then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					jink_table[index] = 0
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
				return false
			end
		else
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				card = response.m_card
			end
			if card and card:getSkillName() == "dadi" then
				player:turnOver()
				if player:isWounded() then
					room:recover(player, sgs.RecoverStruct(player))
				end
			end
		end
	end
}

CAG:addSkill(hundun)
CAG:addSkill(shenyuan)
CAG:addSkill(dadi)

IMPULSE = sgs.General(extension, "IMPULSE", "ZAFT", 4, true, false)

daohe = sgs.CreateTriggerSkill{
	name = "daohe",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
			local pattern = {"meiying", "jianyingg", "jiying"}
			::emengeffect::
			local choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), data)
			if choice then
				room:setPlayerMark(player, "@"..choice, 1)
				local log = sgs.LogMessage()
				log.type = "#daohe"
				log.from = player
				log.arg = choice
				log.arg2 = ":"..choice
				room:sendLog(log)
				if player:getMark("@emeng") > 0 and #pattern == 3 then
					table.removeOne(pattern, choice)
					goto emengeffect
				end
			end
			if player:getMark("@emeng") > 0 then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			end
		end
	end
}

daohemark = sgs.CreateTriggerSkill{
	name = "#daohemark",
	events = {sgs.EventPhaseChanging},
	global = true,
	can_trigger = function(self, player)
		return player and (player:getMark("@meiying") > 0 or player:getMark("@jianyingg") > 0 or player:getMark("@jiying") > 0)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@meiying", 0)
				if player:getMark("@nuhuo") == 0 then
					room:setPlayerMark(player, "@jianyingg", 0)
				end
				room:setPlayerMark(player, "@jiying", 0)
				room:setPlayerMark(player, "meiyingadd", 0)
			end
		end
	end
}

meiying = sgs.CreateTriggerSkill
{
	name = "meiying",
	events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
	global = true,
	can_trigger = function(self, player)
		return player and player:getMark("@meiying") > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "meiyingslash")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:hasFlag("meiyingslash") then
				room:setPlayerFlag(player, "-meiyingslash")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasFlag("meiyingslash") then
				room:setPlayerFlag(player, "-meiyingslash")
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, "meiyingadd")
			end
		end
	end,
}

meiyingslash = sgs.CreateAttackRangeSkill{
	name = "#meiyingslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@meiying") > 0 then
			return 1
		end
	end,
}

meiyingslash2 = sgs.CreateTargetModSkill{
	name = "#meiyingslash2",
	pattern = "Slash",
	residue_func = function(self, player)
		if player and player:getMark("@meiying") > 0 and player:getMark("meiyingadd") > 0 then
			return player:getMark("meiyingadd")
		else
			return 0
		end
	end
}

jianyingg = sgs.CreateTriggerSkill
{
	name = "jianyingg",
	events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
	global = true,
	can_trigger = function(self, player)
		return player and (player:getMark("@jianyingg") > 0 or player:hasSkill("nuhuo"))
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "jianyinggslash")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") and player:hasFlag("jianyinggslash") then
				room:setPlayerFlag(player, "-jianyinggslash")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasFlag("jianyinggslash") then
				room:setPlayerFlag(player, "-jianyinggslash")
				if player:getMark("@jianyingg") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1)
				end
			end
		end
	end
}

jianyinggslash = sgs.CreateAttackRangeSkill{
	name = "#jianyinggslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@jianyingg") > 0 then
			return 1
		end
	end
}

jiying = sgs.CreateTriggerSkill
{
	name = "jiying",
	events = {sgs.ConfirmDamage},
	global = true,
	can_trigger = function(self, player)
		return player and player:getMark("@jiying") > 0
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.damage >= damage.to:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

jiyingslash = sgs.CreateAttackRangeSkill{
	name = "#jiyingslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@jiying") > 0 then
			return 2
		end
	end
}

emeng = sgs.CreateTriggerSkill
{
	name = "emeng",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:getMark("@emeng") > 0 then return false end
		if damage.from and (not player:inMyAttackRange(damage.from)) and damage.card and damage.card:isKindOf("Slash") and damage.by_user then
			room:broadcastSkillInvoke(self:objectName(), math.random(2, 3))
			room:getThread():delay(3000)
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:setEmotion(player, "emeng")
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:setPlayerMark(player, "emeng", 1)
			player:gainMark("@emeng")
		end
	end
}

IMPULSE:addSkill(daohe)
IMPULSE:addSkill(emeng)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#daohemark") then skills:append(daohemark) end
if not sgs.Sanguosha:getSkill("meiying") then skills:append(meiying) end
if not sgs.Sanguosha:getSkill("#meiyingslash") then skills:append(meiyingslash) end
if not sgs.Sanguosha:getSkill("#meiyingslash2") then skills:append(meiyingslash2) end
if not sgs.Sanguosha:getSkill("jianyingg") then skills:append(jianyingg) end
if not sgs.Sanguosha:getSkill("#jianyinggslash") then skills:append(jianyinggslash) end
if not sgs.Sanguosha:getSkill("jiying") then skills:append(jiying) end
if not sgs.Sanguosha:getSkill("#jiyingslash") then skills:append(jiyingslash) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("meiying", "#meiyingslash")
extension:insertRelatedSkills("meiying", "#meiyingslash2")
extension:insertRelatedSkills("jianyingg", "#jianyinggslash")
extension:insertRelatedSkills("jiying", "#jiyingslash")
IMPULSE:addRelateSkill("meiying")
IMPULSE:addRelateSkill("jianyingg")
IMPULSE:addRelateSkill("jiying")

FREEDOM_D = sgs.General(extension, "FREEDOM_D", "ORB", 4, true, false)

xinnian = sgs.CreateTriggerSkill
{
	name = "xinnian",
	events = {sgs.EventPhaseChanging, sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_NotActive and change.to ~= sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local record = {}
					for _,skill in sgs.qlist(p:getVisibleSkillList()) do
						if skill and not skill:isAttachedLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake then
							local mark = "Qingcheng"..skill:objectName()
							room:addPlayerMark(p, mark)
							table.insert(record, mark)
						end
					end
					if #record > 0 then
						p:setTag("xinnian_record", sgs.QVariant(table.concat(record, "+")))
					end
					--room:addPlayerMark(p, "@skill_invalidity")
					--room:filterCards(p, p:getCards("he"), true)
				end
				--room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode({9}))
			elseif change.from ~= sgs.Player_NotActive and change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local record = p:getTag("xinnian_record"):toString()
					if record and record ~= "" then
						record = record:split("+")
						for _,mark in ipairs(record) do
							room:removePlayerMark(p, mark)
						end
						p:setTag("xinnian_record", sgs.QVariant())
					end
					--room:removePlayerMark(p, "@skill_invalidity")
					--room:filterCards(p, p:getCards("he"), false)
				end
				--room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode({9}))
			end
		else
			local damage = data:toDamage()
			if damage.from and (damage.from:getGeneralName() == "AEGIS" or damage.from:getGeneralName() == "JUSTICE"
				or damage.from:getGeneralName() == "SAVIOUR" or damage.from:getGeneralName() == "IJ") 
				and (not room:getTag("xinnian_voice"):toBool()) then
				room:setTag("xinnian_voice", sgs.QVariant(true))
				room:broadcastSkillInvoke(self:objectName(), 3)
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if damage.from:getGeneralName() == "IMPULSE" then --For death special scene use only
				room:setPlayerFlag(player, "IMPULSE_FREEDOM")
				room:loseHp(player)
				room:setPlayerFlag(player, "-IMPULSE_FREEDOM")
			else
				room:loseHp(player)
			end
			return true
		end
	end
}

xinniana = sgs.CreateTriggerSkill
{
	name = "#xinniana",
	events = {sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.Death},
	global = true,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventAcquireSkill then
			local current = room:getCurrent()
			local name = data:toString()
			if current and current:hasSkill("xinnian") and current:objectName() ~= player:objectName() then
				local skill = sgs.Sanguosha:getSkill(name)
				if not skill:isAttachedLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake then
					local mark = "Qingcheng"..name
					room:addPlayerMark(player, mark)
					local record = player:getTag("xinnian_record"):toString()
					if record and record ~= "" then
						record = record.."+"..name
					else
						record = name
					end
					player:setTag("xinnian_record", sgs.QVariant(record))
				end
			end
			if name == "xinnian" and player:getPhase() ~= sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local record = {}
					for _,skill in sgs.qlist(p:getVisibleSkillList()) do
						if skill and not skill:isAttachedLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake then
							local mark = "Qingcheng"..skill:objectName()
							room:addPlayerMark(p, mark)
							table.insert(record, mark)
						end
					end
					if #record > 0 then
						p:setTag("xinnian_record", sgs.QVariant(table.concat(record, "+")))
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_NotActive then return false end
			if (event == sgs.EventLoseSkill and data:toString() == "xinnian")
				or (event == sgs.Death and data:toDeath().who:objectName() == player:objectName() and player:hasSkill("xinnian")) then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local record = p:getTag("xinnian_record"):toString()
					if record and record ~= "" then
						record = record:split("+")
						for _,mark in ipairs(record) do
							room:removePlayerMark(p, mark)
						end
						p:setTag("xinnian_record", sgs.QVariant())
					end
				end
			end
		end
	end
}

luanzhan = sgs.CreateTriggerSkill
{
	name = "luanzhan",
	events = {sgs.Dying},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() and player:getMark("@luanzhan") == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			player:gainMark("@luanzhan")
			room:setPlayerMark(player, "luanzhan", 1)
			room:setEmotion(player, "zhongzi")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke(self:objectName())
			room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
			room:loseMaxHp(player)
			local x = room:alivePlayerCount()
			local gain = "qishe"
			local lose = "huiwu"
			if x <= 3 then
				gain = "huiwu"
				lose = "qishe"
			end
			if player:getMark("@luanzhan") > 0 then
				if player:hasSkill(lose) and not player:hasInnateSkill(lose) then
					room:detachSkillFromPlayer(player, lose, true)
				end
				if not player:hasSkill(gain) then
					room:acquireSkill(player, gain)
				end
			end
		end
	end
}

luanzhane = sgs.CreateTriggerSkill
{
	name = "#luanzhane",
	events = {sgs.Death},
	global = true,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local x = room:alivePlayerCount()
			local gain = "qishe"
			local lose = "huiwu"
			if x <= 3 then
				gain = "huiwu"
				lose = "qishe"
			end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@luanzhan") > 0 then
					if p:hasSkill(lose) and not p:hasInnateSkill(lose) then
						room:detachSkillFromPlayer(p, lose)
					end
					if not p:hasSkill(gain) then
						room:acquireSkill(p, gain)
					end
				end
			end
		end
	end
}

FREEDOM_D:addSkill(xinnian)
FREEDOM_D:addSkill(xinniana)
FREEDOM_D:addSkill(luanzhan)
FREEDOM_D:addSkill(luanzhane)
FREEDOM_D:addRelateSkill("huiwu")
FREEDOM_D:addRelateSkill("qishe")

SAVIOUR = sgs.General(extension, "SAVIOUR", "ZAFT", 4, true, false)

shanzhuan = sgs.CreateTriggerSkill{
	name = "shanzhuan",
	events = {sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardResponse().m_card
		if card and card:isKindOf("Jink") and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local id = room:getDrawPile():first()
			room:drawCards(player, 1, self:objectName())
			room:showCard(player, id)
			local draw = sgs.Sanguosha:getCard(id)
			if draw:isKindOf("Slash") then
				if draw:isRed() then
					room:setCardFlag(id, "shanzhuanred")
				end
				if player:getAI() then
					room:askForUseCard(player, "@@shanzhuan", tostring(id)) --For AI use only
				else
					room:askForUseCard(player, draw:toString(), "@dummy-slash")
				end
				room:setCardFlag(id, "-shanzhuanred")
			end
		end
	end
}

shanzhuanred = sgs.CreateTargetModSkill{
	name = "#shanzhuanred",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("shanzhuan") and card:hasFlag("shanzhuanred") then
			return 1
		end
	end
}

zhongcheng = sgs.CreateTriggerSkill
{
	name = "zhongcheng",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:hasEquip() and room:askForSkillInvoke(player, self:objectName(), data) then
		    room:broadcastSkillInvoke(self:objectName())
			damage.from:throwAllEquips()
		end
	end
}

SAVIOUR:addSkill(shanzhuan)
SAVIOUR:addSkill(shanzhuanred)
SAVIOUR:addSkill(zhongcheng)

DESTROY = sgs.General(extension, "DESTROY", "OMNI", 5, false, false) --全都是锁定技，不用写AI，倍儿爽！

huohai = sgs.CreateTriggerSkill
{
	name = "huohai",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local to = sgs.SPlayerList()
			local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, -1)
			card:setSkillName(self:objectName())
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isKongcheng() and (not p:isProhibited(p, card)) then
					to:append(p)
				end
			end
			if to:isEmpty() then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local use = sgs.CardUseStruct()
			use.card = card
			use.from = player
			use.to = to
			room:useCard(use)
		end
	end
}

tiebi = sgs.CreateTriggerSkill
{
	name = "tiebi",
	events = {sgs.SlashEffected},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		if (effect.slash:isRed() or effect.slash:isKindOf("FireSlash")) and player:distanceTo(effect.from) > 1 then
			room:broadcastSkillInvoke(self:objectName())
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = effect.slash:objectName()
			room:sendLog(log)
			return true
		end
	end
}

kongju = sgs.CreateTriggerSkill
{
	name = "kongju",
	events = {sgs.Death, sgs.ConfirmDamage},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() and player:getMark("@kongju") == 0 then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("DESTROY", "kongju")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:setPlayerMark(player, "kongju", 1)
				player:gainMark("@kongju")
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isNude() then
						local n = math.min(2, p:getCardCount())
						room:askForDiscard(p, self:objectName(), n, n, false, true)
					end
				end
				room:loseMaxHp(player)
				room:detachSkillFromPlayer(player, "tiebi")
			end
		else
			if player:getMark("@kongju") > 0 then
				local damage = data:toDamage()
				if damage.card and damage.card:getSkillName() == "huohai" then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					local log = sgs.LogMessage()
					log.type = "#tiexuedamage"
					log.from = player
					log.to:append(damage.to)
					log.card_str = damage.card:toString()
					log.arg = damage.damage
					log.arg2 = damage.damage + 1
					room:sendLog(log)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			end
		end
	end
}

DESTROY:addSkill(huohai)
DESTROY:addSkill(tiebi)
DESTROY:addSkill(kongju)

AKATSUKI = sgs.General(extension, "AKATSUKI", "ORB", 3, true, false)

bachicard = sgs.CreateSkillCard{
	name = "bachi",
	filter = function(self, targets, to_select, player)
		return #targets < 2 and to_select:objectName() ~= player:objectName() and (not to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitRed, 0)))
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerFlag(effect.to, "bachi")
	end
}

bachivs = sgs.CreateOneCardViewAsSkill{
	name = "bachi",
	response_pattern = "@@bachi",
	filter_pattern = ".!",
	view_as = function(self, card)
		local acard = bachicard:clone()
		acard:addSubcard(card)
		return acard
	end
}

bachi = sgs.CreateTriggerSkill{
	name = "bachi",
	events = {sgs.TargetConfirming},
	view_as_skill = bachivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:isRed() and use.to:contains(player) and player:canDiscard(player, "he") then
			local players = room:getOtherPlayers(player)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if (not p:isProhibited(p, use.card)) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@bachi:" .. use.from:objectName()
				if room:askForUseCard(player, "@@bachi", prompt, -1, sgs.Card_MethodDiscard) then
					local log1 = sgs.LogMessage()
					log1.type = "$CancelTarget"
					log1.from = use.from
					log1.arg = use.card:objectName()
					log1.to:append(player)
					room:sendLog(log1)
					use.to:removeOne(player)
					for _,p in sgs.qlist(players) do
						if p:hasFlag("bachi") then
							p:setFlags("-bachi")
							room:doAnimate(1, player:objectName(), p:objectName())
							local log2 = sgs.LogMessage()
							log2.type = "#BecomeTarget"
							log2.from = p
							log2.card_str = use.card:toString()
							room:sendLog(log2)
							use.to:append(p)
						end
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			end
		end
	end
}

hubicard = sgs.CreateSkillCard{
	name = "hubi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.to:addToPile("&hubi", self)
		room:drawCards(effect.from, 1, "hubi")
	end
}

hubivs = sgs.CreateOneCardViewAsSkill{
	name = "hubi",
	filter_pattern = "Jink",
	view_as = function(self, card)
	    local acard = hubicard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#hubi"))
	end
}

hubi = sgs.CreateTriggerSkill{
	name = "hubi",
	events = {sgs.EventPhaseStart},
	view_as_skill = hubivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPile("&hubi"):length() > 0 then
					local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					card:addSubcards(p:getPile("&hubi"))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName())
					room:obtainCard(player, card, reason)
				end
			end
		end
	end
}

AKATSUKI:addSkill(bachi)
AKATSUKI:addSkill(hubi)

SF = sgs.General(extension, "SF", "ORB", 4, true, false)

daijinvs = sgs.CreateViewAsSkill
{
	name = "daijin",
	n = 998,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("@seedsf") > 0 then
			return not to_select:isEquipped()
		end
		return not to_select:isEquipped() and #selected < 2
	end,
	view_as = function(self, cards)
		if #cards >= 2 then
			local acard = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1) 
			for _,card in ipairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName("daijin")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and (not player:hasUsed("daijin"))
	end
}

daijin = sgs.CreateTriggerSkill
{
	name = "daijin",
	events = {sgs.Damage, sgs.PreCardUsed},
	view_as_skill = daijinvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() and damage.to and damage.to:isAlive() and (not damage.chain) and (not damage.transfer) then
				local record = {}
				for _,skill in sgs.qlist(damage.to:getVisibleSkillList()) do
					if skill and not skill:isAttachedLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and damage.to:getMark("Qingcheng"..skill:objectName()) == 0 then
						table.insert(record, skill:objectName())
					end
				end
				if #record > 0 then
					local choice = room:askForChoice(player, self:objectName(), table.concat(record, "+"), data)
					if choice then
						local log = sgs.LogMessage()
						log.type = "$DaijinNullify"
						log.from = player
						log.to:append(damage.to)
						log.arg = choice
						room:sendLog(log)
						room:addPlayerMark(damage.to, "Qingcheng"..choice)
						damage.to:setTag("daijin_record", sgs.QVariant(choice))
					end
				end
			end
		else
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "daijin" then
				room:addPlayerHistory(player, "daijin")
				if player:getMark("@seedsf") > 0 then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "daijin")
					room:getThread():delay(0600)
					room:broadcastSkillInvoke("gdsbgm", 1)
				else
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				return true
			end
		end
	end
}

daijina = sgs.CreateTriggerSkill
{
	name = "#daijina",
	events = {sgs.TurnStart, sgs.EventPhaseChanging},
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getTag("daijin_record"):toString() ~= ""
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TurnStart and not player:faceUp())
			or (event == sgs.EventPhaseChanging and data:toPhaseChange().from ~= sgs.Player_NotActive and data:toPhaseChange().to == sgs.Player_NotActive) then
			local record = player:getTag("daijin_record"):toString()
			local log = sgs.LogMessage()
			log.type = "$DaijinReset"
			log.from = player
			log.arg = record
			room:sendLog(log)
			room:removePlayerMark(player, "Qingcheng"..record)
			player:setTag("daijin_record", sgs.QVariant())
		end
	end
}

daijins = sgs.CreateTargetModSkill{
	name = "#daijins",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("daijin") and card:getSkillName() == "daijin" then
			return card:subcardsLength() - 1
		end
	end,
	distance_limit_func = function(self, player, card)
		if player and player:hasSkill("daijin") and card:getSkillName() == "daijin" then
			return 998
		end
	end
}

zhongzisf = sgs.CreateTriggerSkill{
	name = "zhongzisf",
	events = {sgs.EventPhaseStart, sgs.TargetConfirming},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or (data:toCardUse().card and data:toCardUse().card:isKindOf("Slash")))
			and player:isKongcheng() and player:getMark("@seedsf") == 0 then
			if event == sgs.EventPhaseStart then
				room:setPlayerFlag(player, "skip_anime")
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, "zhongzisf")
			player:gainMark("@seedsf")
			room:setEmotion(player, "zhongzi")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke(self:objectName())
			room:loseMaxHp(player)
			room:drawCards(player, 2, self:objectName())
			room:acquireSkill(player, "chaoqi")
		end
	end
}

chaoqi = sgs.CreateTriggerSkill{
	name = "chaoqi",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.card and use.card:isKindOf("Slash") and use.to and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			::chaoqi_loop::
			local id = room:getDrawPile():first()
			room:drawCards(player, 1, self:objectName())
			room:showCard(player, id)
			room:getThread():delay(0500)
			local draw = sgs.Sanguosha:getCard(id)
			if draw:getSuit() == sgs.Card_Heart then --Probability of ending with heart = 1/3, ending with black = 2/3
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = use.from
				damage.damage = 1
				room:damage(damage)
			elseif draw:getSuit() == sgs.Card_Diamond then --Expected number of throw = 1/3, standard deviation = 2/3
				if player:canDiscard(use.from, "he") then
					local throw = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					if throw ~= -1 then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), use.from:objectName(), self:objectName(), "")
						local to_throw = sgs.Sanguosha:getCard(throw)
						room:throwCard(to_throw, reason, use.from, player)
					end
				end
				goto chaoqi_loop
			end
		end
	end
}

SF:addSkill(daijin)
SF:addSkill(daijina)
SF:addSkill(daijins)
SF:addSkill(zhongzisf)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("chaoqi") then skills:append(chaoqi) end
sgs.Sanguosha:addSkills(skills)
SF:addRelateSkill("chaoqi")

IJ = sgs.General(extension, "IJ", "ORB", 4, true, false)

hanwei = sgs.CreateTriggerSkill{
	name = "hanwei",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			for _,p in sgs.qlist(use.to) do
				local voice = true
				if (player:getWeapon() or player:getArmor()) and (not p:getEquips():isEmpty())
					and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(("throw:%s:%s"):format(p:getGeneralName(), p:objectName()))) then
					room:broadcastSkillInvoke(self:objectName())
					voice = false
					room:throwCard(room:askForCardChosen(player, p, "e", self:objectName()), p, player)
				end
				if (player:getDefensiveHorse() or player:getOffensiveHorse())
					and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(("jink:%s:%s"):format(p:getGeneralName(), p:objectName()))) then
					local log = sgs.LogMessage()
					log.type = "#hanwei"
					log.to:append(p)
					room:sendLog(log)
					if voice or (not player:getAI()) then
						room:broadcastSkillInvoke(self:objectName())
					end
					local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					for i = 0, use.to:length() - 1, 1 do
						if jink_list[i + 1] == 1 then
							jink_list[i + 1] = 2
						end
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_list))
					player:setTag("Jink_" .. use.card:toString(), jink_data)
				end
			end
		end
	end
}

zhongziij = sgs.CreateTriggerSkill{
	name = "zhongziij",
	events = {sgs.EventPhaseStart, sgs.TargetConfirming},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or (data:toCardUse().card and data:toCardUse().card:isKindOf("Slash")))
			and player:isWounded() and (not player:getEquips():isEmpty()) and player:getMark("@seedij") == 0 then
			if event == sgs.EventPhaseStart then
				room:setPlayerFlag(player, "skip_anime")
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, "zhongziij")
			player:gainMark("@seedij")
			room:setEmotion(player, "zhongzij")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke(self:objectName())
			room:loseMaxHp(player)
			room:acquireSkill(player, "shijiu")
		end
	end
}

shijiuvs = sgs.CreateOneCardViewAsSkill{
	name = "shijiu",
	response_pattern = "@@shijiu",
	response_or_use = true,
	view_filter = function(self, card)
		local suits = {}
		for _,cd in sgs.qlist(sgs.Self:getEquips()) do
			local suit = cd:getSuit()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		return (not card:isEquipped()) and table.contains(suits, card:getSuit())
	end,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end
}

shijiu = sgs.CreateTriggerSkill{
	name = "shijiu",
	events = {sgs.TargetConfirmed},
	view_as_skill = shijiuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) and (not player:isKongcheng())
			and (not player:getEquips():isEmpty()) and room:askForUseCard(player, "@@shijiu", "@shijiu") then
			use.to = sgs.SPlayerList()
			data:setValue(use)
		end
	end
}

IJ:addSkill(hanwei)
IJ:addSkill(zhongziij)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("shijiu") then skills:append(shijiu) end
sgs.Sanguosha:addSkills(skills)
IJ:addRelateSkill("shijiu")

DESTINY = sgs.General(extension, "DESTINY", "ZAFT", 4, true, false)

feiniao = sgs.CreateTriggerSkill{
	name = "feiniao",
	events = {sgs.PreCardUsed, sgs.TargetSpecified, sgs.SlashMissed, sgs.ConfirmDamage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local range = player:getAttackRange()
		if event == sgs.PreCardUsed and range == 1 then
			local use = data:toCardUse()
			if use.card and use.card:objectName() == "slash" then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				local log = sgs.LogMessage()
				log.type = "#CardViewAs"
				log.from = player
				log.arg = "thunder_slash"
				log.card_str = use.card:toString()
				room:sendLog(log)
				local tslash = sgs.Sanguosha:cloneCard("thunder_slash", use.card:getSuit(), use.card:getNumber())
				tslash:addSubcard(use.card)
				if use.card:getSkillName() ~= "" then
					tslash:setSkillName(use.card:getSkillName())
				else
					tslash:setSkillName("feiniaocard")
				end
				
				if use.card:hasFlag("drank") then --Analeptic
					room:setCardFlag(use.card, "-drank")
					room:setCardFlag(tslash, "drank")
					local x = use.card:getTag("drank"):toInt()
					tslash:setTag("drank", sgs.QVariant(x))
					use.card:setTag("drank", sgs.QVariant(0))
				end
				
				use.card = tslash
				data:setValue(use)
			end
		elseif event == sgs.TargetSpecified and range == 2 then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				local log = sgs.LogMessage()
				log.type = "#IgnoreArmor"
				log.from = player
				log.card_str = use.card:toString()
				room:sendLog(log)
				for _,p in sgs.qlist(use.to) do
					if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
						p:addQinggangTag(use.card)
					end
				end
			end
		elseif event == sgs.SlashMissed and range == 3 then
			local effect = data:toSlashEffect()
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 3)
			room:obtainCard(player, effect.slash)
		elseif event == sgs.ConfirmDamage and range >= 4 then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 4)
				local log = sgs.LogMessage()
				log.type = "#tiexuedamage"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = damage.damage
				log.arg2 = damage.damage + 1
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end
}

huanyivs = sgs.CreateViewAsSkill{
	name = "huanyi",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and (not to_select:isEquipped())
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:setSkillName(self:objectName())
			jink:addSubcard(card:getId())
			return jink
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink" and player:getMark("@huanyi") > 0
	end
}

huanyi = sgs.CreateTriggerSkill{
	name = "huanyi",
	events = {sgs.EventPhaseStart},
	view_as_skill = huanyivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				room:addPlayerMark(player, "@huanyi")
				local use = sgs.CardUseStruct()
				local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				card:setSkillName(self:objectName())
				use.card = card
				use.from = player
				room:useCard(use)
			end
		end
	end
}

huanyiclear = sgs.CreateTriggerSkill{
	name = "#huanyiclear",
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "@huanyi", 0)
	end
}

nuhuo = sgs.CreateTriggerSkill{
	name = "nuhuo",
	events = {sgs.SlashMissed},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@nuhuo") == 0 then
			if player:getMark("nuhuo_record") < 2 then
				room:addPlayerMark(player, "nuhuo_record")
			else
				room:broadcastSkillInvoke(self:objectName())
				room:getThread():delay(0500)
				room:broadcastSkillInvoke("emeng", 1)
				room:setEmotion(player, "emeng")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:setPlayerMark(player, "nuhuo", 1)
				player:gainMark("@nuhuo")
				room:loseMaxHp(player)
				room:setPlayerMark(player, "@jianyingg", 1)
				local log = sgs.LogMessage()
				log.type = "#daohe"
				log.from = player
				log.arg = "jianyingg"
				log.arg2 = ":jianyingg"
				room:sendLog(log)
				room:addPlayerMark(player, "nuhuo_buff")
			end
		end
	end
}

nuhuodamage = sgs.CreateTriggerSkill{
	name = "#nuhuodamage",
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:getMark("nuhuo_buff") > 0 then
			room:sendCompulsoryTriggerLog(player, "nuhuo")
			local log = sgs.LogMessage()
			log.type = "#tiexuedamage"
			log.from = player
			log.to:append(damage.to)
			log.card_str = damage.card:toString()
			log.arg = damage.damage
			log.arg2 = damage.damage + player:getMark("nuhuo_buff")
			room:sendLog(log)
			damage.damage = damage.damage + player:getMark("nuhuo_buff")
			data:setValue(damage)
			room:setPlayerMark(player, "nuhuo_buff", 0)
		end
	end
}

DESTINY:addSkill(feiniao)
DESTINY:addSkill(huanyi)
DESTINY:addSkill(huanyiclear)
DESTINY:addSkill(nuhuo)
DESTINY:addSkill(nuhuodamage)

LEGEND = sgs.General(extension, "LEGEND", "ZAFT", 4, true, false)

jiqicard = sgs.CreateSkillCard{
	name = "jiqi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < player:getMark("jiqi")
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not room:askForCard(effect.to, "jink", "@fengong", sgs.QVariant(), sgs.Card_MethodResponse, nil, false, self:objectName(), false) then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		end
	end
}

jiqivs = sgs.CreateZeroCardViewAsSkill{
	name = "jiqi",
	response_pattern = "@@jiqi",
	view_as = function(self)
		return jiqicard:clone()
    end
}

jiqi = sgs.CreateTriggerSkill{
	name = "jiqi",
	events = {sgs.CardResponded},
	view_as_skill = jiqivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCardResponse().m_card
		if card and card:isKindOf("Jink") and card:getNumber() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local x = player:getHp()
			local ids = room:getNCards(2*x)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = player
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local throw = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local attack = false
			for _,id in sgs.qlist(ids) do
				if math.abs(card:getNumber() - sgs.Sanguosha:getCard(id):getNumber()) == 1 then
					dummy:addSubcard(id)
				else
					throw:addSubcard(id)
					if card:getNumber() == sgs.Sanguosha:getCard(id):getNumber() then
						attack = true
					end
				end
			end
			if dummy:subcardsLength() > 0 then
				room:obtainCard(player, dummy)
			end
			if attack then
				room:setPlayerMark(player, "jiqi", x)
				room:askForUseCard(player, "@@jiqi", "@jiqi")
				room:setPlayerMark(player, "jiqi", 0)
			end
			if throw:subcardsLength() > 0 then
				room:throwCard(throw, nil)
			end
		end
	end
}

--[[kelong = sgs.CreateTriggerSkill{ --句神lua
	name = "kelong",
	events = {sgs.Dying, sgs.QuitDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    if event == sgs.Dying then
			local dying = data:toDying()
			local damage  = dying.damage
			local from = damage.from
		    if dying.who:objectName() ~= player:objectName() then
		        return false 
		    end
		    if damage and from and from:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
		        from:turnOver()
				room:setPlayerFlag(player, "kelong")
		    end	
		else
			local dying = data:toDying()
			local damage  = dying.damage
			local from = damage.from
		    if player:isAlive() and player:hasFlag("kelong") then
				room:setPlayerFlag(player, "-kelong")
				if damage and from and from:isAlive() and (not from:isNude()) then
					local card_id = room:askForCardChosen(player, from, "he", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				end
			end
		end
	end
}

kelongd = sgs.CreateTriggerSkill{
	name = "#kelongd",
	events = {sgs.Death},
	can_trigger = function(self, player)
		return player ~= nil and player:hasSkill("kelong")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local damage = death.damage
		local from = damage.from
		if player:hasFlag("kelong") then
			room:setPlayerFlag(player, "-kelong")
			if damage and from and from:isAlive() then
				room:loseHp(from)
			end
		end
	end
}]]

kelongvs = sgs.CreateOneCardViewAsSkill{
	name = "kelong",
	response_pattern = "jink",
	expand_pile = "kelong",
	filter_pattern = ".|.|.|kelong",
	view_as = function(self, card)
	    local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
		jink:addSubcard(card)
		jink:setSkillName(self:objectName())
		return jink
	end
}

kelong = sgs.CreateTriggerSkill{
	name = "kelong",
	events = {sgs.Damaged},
	view_as_skill = kelongvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card then
			local id = damage.card:getEffectiveId()
			if room:getCardPlace(id) == sgs.Player_PlaceTable then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:addToPile("kelong",damage.card)
				end
			end
		end
	end
}

LEGEND:addSkill(jiqi)
LEGEND:addSkill(kelong)
--LEGEND:addSkill(kelongd)

SP_DESTINY = sgs.General(extension, "SP_DESTINY", "ZAFT", 4, true, true)

shanshuocard = sgs.CreateSkillCard{
	name = "shanshuo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:addToPile("&yi", self)
	end
}

shanshuovs = sgs.CreateViewAsSkill{
    name = "shanshuo",
    n = 998,
	view_filter = function(self, selected, to_select)
		return true
	end,
    view_as = function(self, cards)
	if #cards > 0 then
        local acard = shanshuocard:clone()
		for _,card in pairs(cards) do
			acard:addSubcard(card)
		end
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return false
    end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@shanshuo"
	end
}

shanshuo = sgs.CreateTriggerSkill{
	name = "shanshuo",
	events = {sgs.EventPhaseEnd},
	view_as_skill = shanshuovs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and (not player:isNude()) then
			room:askForUseCard(player, "@@shanshuo", "@shanshuo:"..self:objectName())
		end
	end
}

shanshuodistance = sgs.CreateDistanceSkill{
    name = "#shanshuodistance",
    correct_func = function(self, from, to)
		if from and from:hasSkill("shanshuo") and from:getPile("&yi"):length() > 0 then
			return -(from:getPile("&yi"):length())
		end
	end
}

xingzhuivs = sgs.CreateZeroCardViewAsSkill{
    name = "xingzhui",
    view_as = function(self)
	    local pattern = sgs.Self:property("xzuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName(self:objectName())
		return acard
    end,
    enabled_at_play = function(self,player)
        return false
    end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xingzhui"
	end
}

xingzhui = sgs.CreateTriggerSkill{
	name = "xingzhui",
	events = {sgs.EventPhaseStart},
	view_as_skill = xingzhuivs,
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Start then
			for _,selfplayer in sgs.qlist(allplayers) do
				local yi = selfplayer:getPile("&yi")
				if yi:length() > 0 and room:askForSkillInvoke(selfplayer, self:objectName(), data) then
					local samecolor = true
					if yi:length() > 1 then
						for i=1, yi:length()-1, 1 do
							if not sgs.Sanguosha:getCard(yi:at(0)):sameColorWith(sgs.Sanguosha:getCard(yi:at(i))) then
								samecolor = false
								break
							end
						end
					end
					selfplayer:clearOnePrivatePile("&yi")
					local xzbasic = {"slash", "peach"}
					local xztrick = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(xzbasic, 2, "thunder_slash")
						table.insert(xzbasic, 2, "fire_slash")
						table.insert(xzbasic, "analeptic")
						table.insert(xztrick, "fire_attack")
						table.insert(xztrick, "iron_chain")
					end
					local pattern = xzbasic
					if not samecolor then
						pattern = xztrick
					end
					for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(player) then
							table.removeOne(pattern, patt)
						end
					end
					local choice = room:askForChoice(selfplayer, self:objectName(), table.concat(pattern, "+"), data)
					if choice then
						if choice == "peach" or choice == "analeptic" or choice == "ex_nihilo" or choice == "amazing_grace" or
						choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then
							local use = sgs.CardUseStruct()
							local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)
							card:setSkillName(self:objectName())
							use.card = card
							use.from = selfplayer
							room:useCard(use)
						else
							room:setPlayerProperty(selfplayer, "xzuse", sgs.QVariant(choice))
							room:askForUseCard(selfplayer, "@@xingzhui", "@xingzhui:"..choice)
							room:setPlayerProperty(selfplayer, "xzuse", sgs.QVariant())
						end
					end
				end
			end
		end
	end
}

SP_DESTINY:addSkill(shanshuo)
SP_DESTINY:addSkill(shanshuodistance)
SP_DESTINY:addSkill(xingzhui)
extension:insertRelatedSkills("shanshuo", "#shanshuodistance")

STRIKE_NOIR = sgs.General(extension, "STRIKE_NOIR", "OMNI", 4, true, false)

huantongvs = sgs.CreateOneCardViewAsSkill{
	name = "huantong",
	response_pattern = "@@huantong",
	filter_pattern = ".|black",
	response_or_use = true,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end
}

huantong = sgs.CreateTriggerSkill
{
	name = "huantong",
	events = {sgs.CardAsked},
	view_as_skill = huantongvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if data:toStringList()[1] == "jink" and not player:isNude() then
			local card = room:askForUseCard(player, "@@huantong", "@huantong")
			if card then
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jink:setSkillName("huantongcard")
				room:provide(jink)
				return true
			end
		end
	end
}

huantongc = sgs.CreateTriggerSkill
{
	name = "#huantongc",
	events = {sgs.ChainStateChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	global = true,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ChainStateChanged then
			local splayers = room:findPlayersBySkillName("huantong")
			for _,splayer in sgs.qlist(splayers) do
				if splayer:objectName() ~= player:objectName() then
					if player:isChained() then
						room:insertAttackRangePair(splayer, player)
					else
						room:removeAttackRangePair(splayer, player)
					end
				end
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toString() == "huantong" then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isChained() then
						room:insertAttackRangePair(player, p)
					end
				end
			end
		else
			if data:toString() == "huantong" then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isChained() then
						room:removeAttackRangePair(player, p)
					end
				end
			end
		end
	end
}

jianmiecard = sgs.CreateSkillCard{
	name = "jianmie",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:cloneCard("fire_slash", self:getSuit(), self:getNumber())
		card:addSubcard(self)
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and sgs.Self:canSlash(to_select, card) and not sgs.Self:isProhibited(to_select, card, qtargets) then
			if #targets == 0 then
				return true
			elseif #targets == 1 then
				return to_select:isChained()
			else
				return false
			end
		end
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		local card = sgs.Sanguosha:cloneCard("fire_slash", self:getSuit(), self:getNumber())
		card:addSubcard(self)
		card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(use.to) do
			if use.from:isProhibited(p, card)	then
				available = false
				break
			end
		end
		available = available and card:isAvailable(use.from)
		if not available then return nil end
		return card
	end
}

jianmie = sgs.CreateViewAsSkill{
	name = "jianmie",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "slash"
	end,
	view_as = function(self, cards)
	    if #cards == 1 then
			local acard = jianmiecard:clone()
			acard:addSubcard(cards[1])
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end
}

STRIKE_NOIR:addSkill(huantong)
STRIKE_NOIR:addSkill(huantongc)
STRIKE_NOIR:addSkill(jianmie)

EXIA_R = sgs.General(extension, "EXIA_R", "CB", 4, true, false)

liejian = sgs.CreateTriggerSkill{
	name = "liejian",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if use.card:getSuit() == sgs.Card_Spade then
				if player:getWeapon() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					--room:broadcastSkillInvoke(self:objectName())
					room:throwCard(player:getWeapon():getRealCard(), player, player)
				end
			elseif use.card:getSuit() == sgs.Card_Heart then
				if player:getArmor() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					--room:broadcastSkillInvoke(self:objectName())
					room:throwCard(player:getArmor():getRealCard(), player, player)
				end
			elseif use.card:getSuit() == sgs.Card_Club then
				local invoked = false
				for _,p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						if not invoked then
							invoked = true
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
						end
						local id = room:askForCardChosen(player, p, "h", self:objectName())
						room:throwCard(id, p, player)
					end
				end
			elseif use.card:getSuit() == sgs.Card_Diamond then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
	end
}

duzhan = sgs.CreateOneCardViewAsSkill{
	name = "duzhan",
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not card:isEquipped()
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return not card:isEquipped()
			else
				return card:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, card)
		if card:isEquipped() then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		else
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			return slash
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if not p:inMyAttackRange(player) then
				return false
			end
		end
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if not p:inMyAttackRange(player) then
				return false
			end
		end
		return (pattern == "slash") or (pattern == "jink")
	end
}

EXIA_R:addSkill(liejian)
EXIA_R:addSkill(duzhan)

REBORNS_CANNON = sgs.General(extension, "REBORNS_CANNON", "OTHERS", 4, true, false)
REBORNS_GUNDAM = sgs.General(extension, "REBORNS_GUNDAM", "OTHERS", 4, true, true)

jidongcard = sgs.CreateSkillCard{
	name = "jidong",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		if source:getGeneralName() == "REBORNS_CANNON" or source:getGeneral2Name() == "REBORNS_CANNON" then
			room:broadcastSkillInvoke("jidong", math.random(3, 4))
			room:changeHero(source, "REBORNS_GUNDAM", false, false, source:getGeneralName() ~= "REBORNS_CANNON", true)
		elseif source:getGeneralName() == "REBORNS_GUNDAM" or source:getGeneral2Name() == "REBORNS_GUNDAM" then
			room:broadcastSkillInvoke("jidong", math.random(1, 2))
			room:changeHero(source, "REBORNS_CANNON", false, false, source:getGeneralName() ~= "REBORNS_GUNDAM", true)
		end
	end
}

jidongvs = sgs.CreateViewAsSkill{
	name = "jidong",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasUsed("#reborns_transam") then
			return false
		else
			return #selected == 0
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 or sgs.Self:hasUsed("#reborns_transam") then
			local acard = jidongcard:clone()
			if #cards == 1 then
				acard:addSubcard(cards[1])
			end
			acard:setSkillName("jidong")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#jidong")) or (player:hasUsed("#reborns_transam"))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

jidong = sgs.CreateTriggerSkill{-- ZY奆神的技能卡静音黑科技
	name = "jidong",
	events = {sgs.PreCardUsed},
	view_as_skill = jidongvs,
	on_trigger = function(self, event, player, data)
		if data:toCardUse().card:getSkillName() == "jidong" then return true end
	end
}

fengongcard = sgs.CreateSkillCard{
	name = "fengong",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local card = room:askForCard(effect.to, "jink", "@fengong", sgs.QVariant(), sgs.Card_MethodResponse, nil, false, self:objectName(), false)
		if not card then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		end
	end,
}

fengong = sgs.CreateOneCardViewAsSkill{
	name = "fengong",
	filter_pattern = "ThunderSlash,FireSlash",
	view_as = function(self, card)
	    local acard = fengongcard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#fengong")) or (player:hasUsed("#reborns_transam"))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

zaishengcard = sgs.CreateSkillCard{
	name = "zaisheng",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n = 0
		local subcard = self:subcardsLength()
		repeat
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = source
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			room:getThread():delay(500)
			if sgs.Sanguosha:getCard(ids:at(0)):isKindOf("BasicCard") then
				n = n + 1
				room:obtainCard(source, ids:at(0))
			else
				room:throwCard(ids:at(0), nil)
			end
		until n >= subcard
	end,
}

zaisheng = sgs.CreateViewAsSkill{
	name = "zaisheng",
	n = 998,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = zaishengcard:clone()
			for _,card in pairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zaisheng") and not player:isNude()
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

REBORNS_TRANSAMcard = sgs.CreateSkillCard{
	name = "reborns_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@reborns_transam")
		room:broadcastSkillInvoke("gdsbgm", 3)
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
	end,
}

REBORNS_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "reborns_transam",
	view_as = function(self)
	    local acard = REBORNS_TRANSAMcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@reborns_transam") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

REBORNS_TRANSAM = sgs.CreateTriggerSkill{
	name = "reborns_transam",
	frequency = sgs.Skill_Limited,
	view_as_skill = REBORNS_TRANSAMvs,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

REBORNS_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#reborns_transammark",
	events = {sgs.GameStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("@reborns_transam") == 0 then
				player:gainMark("@reborns_transam")
			end
		else
		
			if data:toPhaseChange().to == sgs.Player_NotActive then --Clear mask
				room:setPlayerMark(player, "drank", 0)
			end
			
		end
	end
}

REBORNS_CANNON:addSkill(jidong)
REBORNS_CANNON:addSkill(fengong)
REBORNS_CANNON:addSkill(REBORNS_TRANSAMmark)
REBORNS_GUNDAM:addSkill("jidong")
REBORNS_GUNDAM:addSkill(zaisheng)
REBORNS_GUNDAM:addSkill(REBORNS_TRANSAM)
REBORNS_GUNDAM:addSkill("#reborns_transammark")

HARUTE = sgs.General(extension, "HARUTE", "CB", 4, true, false)
HARUTE:setGender(sgs.General_Neuter)

feijianvs = sgs.CreateOneCardViewAsSkill{
	name = "feijian",
	response_or_use = true,
	view_filter = function(self, card)
		local suits = {}
		for _,id in sgs.qlist(sgs.Self:getPile("jian")) do
			local suit = sgs.Sanguosha:getCard(id):getSuitString()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		if not table.contains(suits, card:getSuitString()) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:isNude() and not player:getPile("jian"):isEmpty()
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:isNude() and not player:getPile("jian"):isEmpty()
	end
}

feijian = sgs.CreateTriggerSkill{
	name = "feijian",
	events = {sgs.GameStart},
	view_as_skill = feijianvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		player:addToPile("jian", room:getNCards(4))
	end,
}

feijianslash = sgs.CreateTargetModSkill{
	name = "#feijianslash",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("feijian") and card:getSkillName() == "feijian" then
			return 1
		end
	end,
}

liuyanvs = sgs.CreateOneCardViewAsSkill{
	name = "liuyan",
	expand_pile = "jian",
	filter_pattern = ".|.|.|jian",
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
	enabled_at_play = function(self, player)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
		peach:deleteLater()
		return peach:isAvailable(player) and player:getMark("@MARUT") > 0 and not player:getPile("jian"):isEmpty()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and player:getMark("@MARUT") > 0 and not player:getPile("jian"):isEmpty() and player:getMark("Global_PreventPeach") == 0
	end
}

liuyan = sgs.CreateTriggerSkill{
	name = "liuyan",
	events = {sgs.EventPhaseStart, sgs.PreCardUsed},
	frequency = sgs.Skill_Wake,
	view_as_skill = liuyanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getMark("@MARUT") == 0 and player:getPhase() == sgs.Player_Start and player:getHp() <= 2 then
				room:setPlayerFlag(player, "skip_anime")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:getThread():delay(4500)
				room:setEmotion(player, "liuyan")
				player:gainMark("@MARUT")
				room:setPlayerMark(player, "liuyan", 1)
				room:loseMaxHp(player)
				player:drawCards(6)
			end
		elseif event == sgs.PreCardUsed then
			if data:toCardUse().card:getSkillName() == "liuyan" then
				room:broadcastSkillInvoke(self:objectName(), math.random(2, 5))
				return true
			end
		end
	end,
}

HARUTE_TRANSAMcard = sgs.CreateSkillCard{
	name = "harute_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@harute_transam")
		room:setPlayerMark(source, "harute_transammark", 1)
		room:broadcastSkillInvoke("gdsbgm", 3)
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
	end,
}

HARUTE_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "harute_transam",
	view_as = function(self)
	    local acard = HARUTE_TRANSAMcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@harute_transam") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

HARUTE_TRANSAM = sgs.CreateTriggerSkill{
	name = "harute_transam",
	frequency = sgs.Skill_Limited,
	limit_mark = "@harute_transam",
	view_as_skill = HARUTE_TRANSAMvs,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

HARUTE_TRANSAMslash = sgs.CreateTargetModSkill{
	name = "#harute_transamslash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player and player:hasUsed("#harute_transam") then
			return 998
		end
	end,
	residue_func = function(self, player)
		if player and player:hasUsed("#harute_transam") then
			return 2
		else
			return 0
		end
	end
}

HARUTE_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#harute_transammark",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and player:getMark("harute_transammark") > 0 then
				room:setPlayerMark(player, "harute_transammark", 0)
				player:skip(sgs.Player_Draw)
				return true
			end
		else
		
			if data:toPhaseChange().to == sgs.Player_NotActive then --Clear mask
				room:setPlayerMark(player, "drank", 0)
			end
			
		end
	end
}

HARUTE:addSkill(feijian)
HARUTE:addSkill(feijianslash)
extension:insertRelatedSkills("feijian", "#feijianslash")
HARUTE:addSkill(liuyan)
HARUTE:addSkill(HARUTE_TRANSAM)
HARUTE:addSkill(HARUTE_TRANSAMslash)
HARUTE:addSkill(HARUTE_TRANSAMmark)
--extension:insertRelatedSkills("harute_transam", "#harute_transamslash")

--[[ELSQ = sgs.General(extension, "ELSQ", "CB", 3, true, dlc, dlc)
if dlc then
	if t[1] then
		local times = tonumber(t[1]:split("/")[2])
		if times == 10 and sgs.Sanguosha:translate("ELSQ") == "ELSQ" then
			sgs.Alert("累计10场游戏——你获得新机体：ELS Q！")
		end
		if times >= 10 then]]
			ELSQ = sgs.General(extension, "ELSQ", "CB", 3, true, false)
		--[[end
	end
end]]

function RongheMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "ronghe", ""))
		move.to_pile_name = "&ronghe"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "ronghe", ""))
		move.from_pile_name = "&ronghe"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

ronghecard = sgs.CreateSkillCard{
	name = "ronghe",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and (not to_select:isKongcheng())
		and to_select:getHp() > player:getHp() and #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local ids = effect.to:handCards()
		effect.from:turnOver()
		RongheMove(ids, true, effect.from)
		room:setPlayerProperty(effect.from, "ronghe", sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
		room:setTag("Dongchaee", sgs.QVariant(effect.to:objectName()))
		room:setTag("Dongchaer", sgs.QVariant(effect.from:objectName()))
	end
}

ronghe = sgs.CreateZeroCardViewAsSkill{
	name = "ronghe",
	view_as = function()
	    local acard = ronghecard:clone()
		acard:setSkillName("ronghe")
		return acard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ronghe")
	end
}

rongheclear = sgs.CreateTriggerSkill{
	name = "#rongheclear",
	events = {sgs.TurnStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local list = player:property("ronghe"):toString():split("+")
			if #list > 0 then
				RongheMove(Table2IntList(list), false, player)
			end
			room:setTag("Dongchaee", sgs.QVariant())
			room:setTag("Dongchaer", sgs.QVariant())
			room:setPlayerProperty(player, "ronghe", sgs.QVariant())
		else
			local move = data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceHand) and move.from:objectName() == room:getTag("Dongchaee"):toString() then
				local list = player:property("ronghe"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					for _,l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						end
					end
					RongheMove(to_remove, false, player)
					for _,id in sgs.qlist(to_remove) do
						table.removeOne(list, tostring(id))
					end
					local pattern = sgs.QVariant()
					if #list > 0 then
						pattern = sgs.QVariant(table.concat(list, "+"))
					end
					room:setPlayerProperty(player, "ronghe", pattern)
				end
			elseif move.to and move.to_place == sgs.Player_PlaceHand and move.to:objectName() == room:getTag("Dongchaee"):toString() then
				local list = player:property("ronghe"):toString():split("+")
				local to_add = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids) do
					if not table.contains(list, tostring(id)) then
						table.insert(list, tostring(id))
						to_add:append(id)
					end
				end
				RongheMove(to_add, true, player)
				local pattern = sgs.QVariant(table.concat(list, "+"))
				room:setPlayerProperty(player, "ronghe", pattern)
			end
		end
	end
}

lijie = sgs.CreateTriggerSkill{
	name = "lijie",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and (not damage.from:isKongcheng()) and player:objectName() ~= damage.from:objectName()
			and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local id = room:askForCardChosen(player, damage.from, "h", self:objectName())
			local card = sgs.Sanguosha:getCard(id)
			room:throwCard(card, damage.from, player)
			if card:getSuit() == sgs.Card_Heart then
				room:recover(player, sgs.RecoverStruct(player))
				room:recover(damage.from, sgs.RecoverStruct(player))
			end
		end
	end
}

ELSQ:addSkill(ronghe)
ELSQ:addSkill(rongheclear)
ELSQ:addSkill(lijie)

FS = sgs.General(extension, "00QFS", "CB", 4, true, dlc, dlc)
if dlc then
	if t[1] then
		local times = tonumber(t[1]:split("/")[2])
		if times == 5 and sgs.Sanguosha:translate("#00QFS") == "#00QFS" then
			sgs.Alert("累计5场游戏——你获得新机体：00QAN[T] FULL SABER！")
		end
		if times >= 5 then
			FS = sgs.General(extension, "00QFS", "CB", 4, true, false)
		end
	end
end

function QuanrenMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "quanren", ""))
		move.to_pile_name = "quanrenshow"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "quanren", ""))
		move.from_pile_name = "quanrenshow"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

quanrenvs = sgs.CreateOneCardViewAsSkill{
	name = "quanren",
	view_filter = function(self, card)
		local list = sgs.Self:property("quanren"):toString():split("+")
		if not table.contains(list, tostring(card:getEffectiveId())) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		if player:getMark("fs_transam_limit") == 1 then return false end
		return sgs.Slash_IsAvailable(player) and player:property("quanren"):toString() ~= ""
	end, 
	enabled_at_response = function(self, player, pattern)
		if player:getMark("fs_transam_limit") == 1 then return false end
		return pattern == "slash" and player:property("quanren"):toString() ~= ""
	end
}

quanren = sgs.CreateTriggerSkill{
	name = "quanren",
	events = {sgs.EventPhaseStart},
	view_as_skill = quanrenvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if player:getMark("fs_transam_limit") == 1 then return false end
			local list = player:property("quanren"):toString()
			if list == "" and (not player:isKongcheng()) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				QuanrenMove(player:handCards(), true, player)
				room:setPlayerProperty(player, "quanren", sgs.QVariant(table.concat(sgs.QList2Table(player:handCards()), "+")))
				for _,id in sgs.qlist(player:handCards()) do
					room:showCard(player, id)
				end
			end
		end
	end
}

quanren_global = sgs.CreateTriggerSkill{
	name = "#quanren_global",
	events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				local list = player:property("quanren"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					local to_set = {}
					for _,l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						else
							table.insert(to_set, l)
						end
					end
					if not to_remove:isEmpty() then
						QuanrenMove(to_remove, false, player)
						local pattern = sgs.QVariant()
						if #to_set > 0 then
							pattern = sgs.QVariant(table.concat(to_set, "+"))
						end
						room:setPlayerProperty(player, "quanren", pattern)
					end
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local source = move.reason.m_playerId
			if source and move.from and move.from:objectName() ~= source and player:objectName() == source
				and move.from_places:contains(sgs.Player_PlaceHand) and move.reason.m_skillName ~= "longqi"
				and not(room:getTag("Dongchaer"):toString() == player:objectName()
				and room:getTag("Dongchaee"):toString() == move.from:objectName()) then
				local list = move.from:property("quanren"):toString():split("+")
				if #list > 0 then
					if #list == 1 and move.from:getHandcards():length() == 1 then return false end
					local ids = sgs.IntList()
					for _,l in pairs(list) do
						ids:append(tonumber(l))
					end
					local to_move = move.card_ids
					local invisible_hands = move.from:getHandcards()
					for _,k in sgs.qlist(move.from:getHandcards()) do
						if ids:contains(k:getId()) then
							invisible_hands:removeOne(k)
						end
					end
					if invisible_hands:length() == 0 then
						local poi = ids
						for _,x in sgs.qlist(move.card_ids) do
							if ids:contains(x) then
								room:fillAG(poi)
								local id = room:askForAG(player, poi, false, "quanren")
								if id ~= -1 then
									to_move:append(id)
									to_move:removeOne(x)
									poi:removeOne(id)
								end
								room:clearAG()
							end
						end
					else
						local hands = sgs.IntList()
						for _,i in sgs.qlist(move.card_ids) do
							if room:getCardPlace(i) == sgs.Player_PlaceHand then
								if ids:contains(i) then
									local rand = invisible_hands:at(math.random(0, invisible_hands:length() - 1)):getId()
									to_move:append(rand)
									to_move:removeOne(i)
									i = rand
								end
								hands:append(i)
							end
						end
						if hands:length() == move.from:getHandcardNum() or hands:length() == 0 then return false end
						local view = ids
						for _,j in sgs.qlist(hands) do
							if view:length() == 0 then break end
							local choice = room:askForChoice(player, "quanren", "quanrenpile+quanrenhand", data)
							if choice == "quanrenpile" then
								if view:length() == 1 then
									local id = view:first()
									to_move:append(id)
									to_move:removeOne(j)
									view:removeOne(id)
								else
									room:fillAG(view)
									local id = room:askForAG(player, view, false, "quanren")
									if id ~= -1 then
										to_move:append(id)
										to_move:removeOne(j)
										view:removeOne(id)
									end
									room:clearAG()
								end
							else
								break
							end
						end
					end
					local bools = sgs.BoolList()
					for _,t in sgs.qlist(to_move) do
						bools:append(ids:contains(t))
					end
					move.card_ids = to_move
					move.open = bools
					data:setValue(move)
				end
			end
		end
	end
}

yueqian = sgs.CreateTriggerSkill{
	name = "yueqian",
	events = {sgs.Damage, sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player:inMyAttackRange(damage.to) and (not room:getCurrent():hasFlag("yueqian")) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(room:getCurrent(), "yueqian")
				local id = room:getDrawPile():first()
				room:drawCards(player, 1, self:objectName())
				local ids = sgs.IntList()
				ids:append(id)
				QuanrenMove(ids, true, player)
				local list = player:property("quanren"):toString():split("+")
				table.insert(list, tostring(id))
				room:setPlayerProperty(player, "quanren", sgs.QVariant(table.concat(list, "+")))
				room:showCard(player, id)
				local draw = sgs.Sanguosha:getCard(id)
				if draw:isRed() then
					local log = sgs.LogMessage()
					log.type = "#yueqian"
					log.from = player
					room:sendLog(log)
					room:setPlayerMark(player, "@yueqian", 1)
				end
			end
		else
			local pattern = data:toStringList()[1]
			if pattern == "jink" and player:getMark("@yueqian") > 0 then
				room:setPlayerMark(player, "@yueqian", 0)
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				jink:setSkillName(self:objectName())
				room:provide(jink)
				return true
			end
		end
	end
}

FS_TRANSAMcard = sgs.CreateSkillCard{
	name = "fs_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@fs_transam")
		room:broadcastSkillInvoke("gdsbgm", 3)
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
		local list = source:property("quanren"):toString():split("+")
		QuanrenMove(Table2IntList(list), false, source)
		room:setPlayerProperty(source, "quanren", sgs.QVariant())
		room:setPlayerMark(source, "fs_transam_buff", #list)
		room:setPlayerMark(source, "fs_transam_limit", 3)
	end
}

FS_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "fs_transam",
	view_as = function(self)
	    local acard = FS_TRANSAMcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@fs_transam") > 0 and player:property("quanren"):toString() ~= ""
	end
}

FS_TRANSAM = sgs.CreateTriggerSkill{
	name = "fs_transam",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fs_transam",
	view_as_skill = FS_TRANSAMvs,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Play and player:getMark("fs_transam_buff") > 0 then
			room:setPlayerMark(player, "fs_transam_buff", 0)
		end
	end
}

FS_TRANSAMr = sgs.CreateAttackRangeSkill{
	name = "#fs_transamr",
	extra_func = function(self, player, include_weapon)
		local mark = player:getMark("fs_transam_buff")
		if player and mark > 0 then
			return mark
		end
	end
}

FS_TRANSAMt = sgs.CreateTargetModSkill{
	name = "#fs_transamt",
	pattern = "Slash",
	residue_func = function(self, from)
		local mark = from:getMark("fs_transam_buff")
		if from and mark > 0 then
			return mark
		else
			return 0
		end
	end
}

FS_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#fs_transammark",
	events = {sgs.TurnStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart or (event == sgs.EventPhaseChanging and
			data:toPhaseChange().from ~= sgs.Player_NotActive and data:toPhaseChange().to == sgs.Player_NotActive) then
			if player:getMark("fs_transam_limit") > 0 then
				room:removePlayerMark(player, "fs_transam_limit", 1)
			end
			if event == sgs.EventPhaseChanging then
				room:setPlayerMark(player, "drank", 0)
			end
		end
	end
}

FS:addSkill(quanren)
FS:addSkill(quanren_global)
FS:addSkill(yueqian)
FS:addSkill(FS_TRANSAM)
FS:addSkill(FS_TRANSAMr)
FS:addSkill(FS_TRANSAMt)
FS:addSkill(FS_TRANSAMmark)
--extension:insertRelatedSkills("fs_transam", "#fs_transamr")
--extension:insertRelatedSkills("fs_transam", "#fs_transamt")

SBS = sgs.General(extension, "SBS", "OTHERS")

jieneng = sgs.CreateTriggerSkill{
	name = "jieneng",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and (not use.card:isVirtualCard() or use.card:subcardsLength() > 0) and use.card:isKindOf("Slash") and use.to
			and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				player:addToPile("neng", use.card)
				room:setEmotion(player, "skill_nullify")
				local log = sgs.LogMessage()
				log.type = "#SkillNullify"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = use.card:objectName()
				room:sendLog(log)
				use.to:removeAll(player)
				data:setValue(use)
			end
		end
	end
}

jienengh = sgs.CreateMaxCardsSkill{
	name = "#jienengh",
	extra_func = function(self, player)
		local len = player:getPile("neng"):length()
		if len > 0 then
			return -(len)
		end
	end
}

shinengcard = sgs.CreateSkillCard{
	name = "shineng",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setEmotion(source, "shineng")
		room:getThread():delay(5200)
		source:loseMark("@shineng")
		local neng = source:getPile("neng")
		room:setPlayerMark(source, "neng_buff", neng:length())
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:addSubcards(neng)
		room:obtainCard(source, card)
	end
}

shinengvs = sgs.CreateZeroCardViewAsSkill{
	name = "shineng",
	view_as = function(self)
	    local acard = shinengcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@shineng") > 0 and (not player:getPile("neng"):isEmpty())
	end
}

shineng = sgs.CreateTriggerSkill{
	name = "shineng",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shineng",
	view_as_skill = shinengvs,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Play and player:getMark("neng_buff") > 0 then
			room:setPlayerMark(player, "neng_buff", 0)
		end
	end
}

shinengr = sgs.CreateAttackRangeSkill{
	name = "#shinengr",
	extra_func = function(self, player, include_weapon)
		local mark = player:getMark("neng_buff")
		if player and mark > 0 then
			return mark
		end
	end
}

shinengt = sgs.CreateTargetModSkill{
	name = "#shinengt",
	pattern = "Slash",
	residue_func = function(self, from)
		local mark = from:getMark("neng_buff")
		if from and mark > 0 then
			return mark
		else
			return 0
		end
	end
}

rg = sgs.CreateTriggerSkill{
	name = "rg",
	frequency = sgs.Skill_Limited,
	limit_mark = "@rg",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@rg") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setEmotion(player, "rg")
			room:getThread():delay(4200)
			room:setPlayerMark(player, "@shineng", 0)
			player:loseMark("@rg")
			player:clearOnePrivatePile("neng")
			room:handleAcquireDetachSkills(player, "-jieneng|-shineng|tiequan")
			room:filterCards(player, player:getCards("he"), false)
		end
	end
}

tiequan = sgs.CreateTriggerSkill{
	name = "tiequan",
	events = {sgs.ConfirmDamage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:objectName() ~= damage.to:objectName() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

tiequanf = sgs.CreateFilterSkill{
	name = "#tiequanf",
	view_filter = function(self, card)
		return card:isKindOf("Jink") and math.mod(card:getNumber(), 2) == 1
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("tiequan")
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}

SBS:addSkill(jieneng)
SBS:addSkill(jienengh)
SBS:addSkill(shineng)
SBS:addSkill(shinengr)
SBS:addSkill(shinengt)
SBS:addSkill(rg)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("tiequan") then skills:append(tiequan) end
if not sgs.Sanguosha:getSkill("#tiequanf") then skills:append(tiequanf) end
sgs.Sanguosha:addSkills(skills)
SBS:addRelateSkill("tiequan")
extension:insertRelatedSkills("jieneng", "#jienengh")
--extension:insertRelatedSkills("shineng", "#shinengr")
--extension:insertRelatedSkills("shineng", "#shinengt")
extension:insertRelatedSkills("tiequan", "#tiequanf")

DARK_MATTER = sgs.General(extension, "DARK_MATTER", "OTHERS", 3, true, false)

mingren = sgs.CreateTriggerSkill
{
	name = "mingren",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Duel") then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:setEmotion(player, "skill_nullify")
			return true
		end
	end
}

binghuo = sgs.CreateTriggerSkill{
	name = "binghuo",
	events = {sgs.TargetSpecified, sgs.ConfirmDamage, sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local fire = false
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _,p in sgs.qlist(use.to) do
					if p:getMark("@ice") == 0 then
						room:broadcastSkillInvoke("gdsbgm", 5) --room:broadcastSkillInvoke("@recast"), player:broadcastSkillInvoke("@recast")
						room:setEmotion(p, "ice")
						p:gainMark("@ice")
						room:addPlayerMark(p, "Equips_Nullified_to_Yourself")
						use.to:removeOne(p)
					else
						if not fire then
							fire = true
							room:broadcastSkillInvoke("gdsbgm", 6)
							if not use.card:isKindOf("FireSlash") then
								room:setEmotion(player, "fire_slash")
								local log = sgs.LogMessage()
								log.type = "#CardViewAs"
								log.from = player
								log.arg = "fire_slash"
								log.card_str = use.card:toString()
								room:sendLog(log)
								local fslash = sgs.Sanguosha:cloneCard("fire_slash", use.card:getSuit(), use.card:getNumber())
								fslash:addSubcard(use.card)
								if use.card:getSkillName() ~= "" then
									fslash:setSkillName(use.card:getSkillName())
								else
									fslash:setSkillName("binghuocard")
								end
								if use.card:hasFlag("drank") then --Analeptic
									room:setCardFlag(use.card, "-drank")
									room:setCardFlag(fslash, "drank")
									local x = use.card:getTag("drank"):toInt()
									fslash:setTag("drank", sgs.QVariant(x))
									use.card:setTag("drank", sgs.QVariant(0))
								end
								use.card = fslash
							end
						end
						jink_table[index] = 0
						index = index + 1
						local jink_data = sgs.QVariant()
						jink_data:setValue(Table2IntList(jink_table))
						player:setTag("Jink_" .. use.card:toString(), jink_data)
					end
				end
				data:setValue(use)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.chain or damage.transfer then return false end
			if damage.card and damage.card:isKindOf("FireSlash") and damage.to:getMark("@ice") > 0 then
				local log = sgs.LogMessage()
				log.type = "#tiexuedamage"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = damage.damage
				log.arg2 = damage.damage + 1
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		else
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("FireSlash") and damage.to:getMark("@ice") > 0 then
				damage.to:loseMark("@ice")
				room:removePlayerMark(damage.to, "Equips_Nullified_to_Yourself")
			end
		end
	end
}

DM_TRANSAMcard = sgs.CreateSkillCard{ --tassel/slumber/insomniac神之lua
	name = "dm_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@dm_transam")
		local count = self:subcardsLength()
		room:setPlayerMark(source, "dm_transammark", count)
		room:broadcastSkillInvoke("gdsbgm", 3)
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), self:objectName(), nil)
		room:throwCard(self, reason, nil)
		room:drawCards(source, count)
	end
}

DM_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "dm_transam",
	view_as = function(self, cards)
		local acard = DM_TRANSAMcard:clone()
		local equips = sgs.Self:getEquips()
		acard:addSubcards(equips)
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@dm_transam") > 0 and not player:getEquips():isEmpty()
	end
}

DM_TRANSAM = sgs.CreateGameStartSkill{
	name = "dm_transam",
	frequency = sgs.Skill_Limited,
	limit_mark = "@dm_transam",
	view_as_skill = DM_TRANSAMvs,
	on_gamestart = function(self, player)
	end
}

DM_TRANSAMslash = sgs.CreateTargetModSkill{
	name = "#dm_transamslash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player and player:hasUsed("#dm_transam") and player:getMark("dm_transammark") > 0 then
			return player:getMark("dm_transammark")
		else
			return 0
		end
	end
}

DM_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#dm_transammark",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("dm_transammark") > 0 and data:toPhaseChange().to == sgs.Player_NotActive then --Clear mask
			room:setPlayerMark(player, "dm_transammark", 0)
			room:setPlayerMark(player, "drank", 0)
		end
	end
}

DARK_MATTER:addSkill(mingren)
DARK_MATTER:addSkill(binghuo)
DARK_MATTER:addSkill(DM_TRANSAM)
DARK_MATTER:addSkill(DM_TRANSAMslash)
DARK_MATTER:addSkill(DM_TRANSAMmark)

BUILD_BURNING = sgs.General(extension, "BUILD_BURNING", "OTHERS", 4, true, true)

ciyuanbawangliucard = sgs.CreateSkillCard{
	name = "ciyuanbawangliu",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		if source:getMark("@tonghua") > 0 then
			room:sendCompulsoryTriggerLog(source, "tonghua")
			room:obtainCard(source, self)
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, source:objectName(), self:objectName(), nil)
			room:throwCard(self, reason, source, source)
		end
	end
}

ciyuanbawangliuvs = sgs.CreateOneCardViewAsSkill{
	name = "ciyuanbawangliu",
	expand_pile = "quanfa",
	filter_pattern = ".|.|.|quanfa",
	response_pattern = "@@ciyuanbawangliu",
	view_as = function(self, card)
		local acard = ciyuanbawangliucard:clone()
		acard:addSubcard(card)
		return acard
	end
}

ciyuanbawangliu = sgs.CreateTriggerSkill{ --FAQ:使用次数算转化前的牌，使用效果算转化后的牌（包括酒效果）
	name = "ciyuanbawangliu",
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	view_as_skill = ciyuanbawangliuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local n = player:getPile("quanfa"):length()
				if n >= 5 then return false end
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local ids = room:getNCards(3, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local card_to_gotback = sgs.IntList()
				local card_to_throw = sgs.IntList()
				for _,id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if n < 5 and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or card:isKindOf("FireAttack")) then
						n = n + 1
						card_to_gotback:append(id)
					else
						card_to_throw:append(id)
					end
				end
				if card_to_gotback:length() > 0 then
					player:addToPile("quanfa", card_to_gotback)
				end
				if card_to_throw:length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcards(card_to_throw)
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
					room:throwCard(dummy, reason, nil)
				end
			end
		else
			local use = data:toCardUse()
			if use.card and (not player:getPile("quanfa"):isEmpty()) and
				(use.card:isKindOf("Slash") or use.card:isKindOf("Duel") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch") or use.card:isKindOf("FireAttack")) then
				local card = room:askForUseCard(player, "@@ciyuanbawangliu", "@ciyuanbawangliu")
				if card then
					local qcard = sgs.Sanguosha:getCard(card:getSubcards():first())
					local name = qcard:objectName()
					if player:getMark("@tonghua") > 0 and qcard:isRed() then
						name = "fire_slash"
					end
					local log = sgs.LogMessage()
					log.type = "#CardViewAs"
					log.from = player
					log.arg = name
					log.card_str = use.card:toString()
					room:sendLog(log)
					local acard = sgs.Sanguosha:cloneCard(name, use.card:getSuit(), use.card:getNumber())
					acard:addSubcard(use.card)
					
					if use.card:isKindOf("Slash") and acard:isKindOf("Slash") then --Analeptic
						if use.card:hasFlag("drank") then
							room:setCardFlag(use.card, "-drank")
							room:setCardFlag(acard, "drank")
							local x = use.card:getTag("drank"):toInt()
							acard:setTag("drank", sgs.QVariant(x))
							use.card:setTag("drank", sgs.QVariant(0))
						end
					elseif use.card:isKindOf("Slash") and not acard:isKindOf("Slash") then
						if use.card:hasFlag("drank") then
							room:setCardFlag(use.card, "-drank")
							local x = use.card:getTag("drank"):toInt()
							room:addPlayerMark(player, "drank", x)
							use.card:setTag("drank", sgs.QVariant(0))
						end
					elseif player:getMark("drank") > 0 and acard:isKindOf("Slash") then
						room:setCardFlag(acard, "drank")
						acard:setTag("drank", sgs.QVariant(player:getMark("drank")))
					end
					
					if use.card:objectName() ~= name then --Emotion and audio
						if acard:isKindOf("Slash") then
							room:setEmotion(player, name)
						end
						room:broadcastSkillInvoke(name)
					end
					
					use.card = acard
					data:setValue(use)
				end
			end
		end
	end
}

tonghua = sgs.CreateTriggerSkill{
	name = "tonghua",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@tonghua") == 0 then
			local quanfa = player:getPile("quanfa")
			if quanfa:isEmpty() then return false end
			local red = 0
			for _,id in sgs.qlist(quanfa) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isRed() then
					red = red + 1
					if red >= 3 then break end
				end
			end
			if red < 3 then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			--Emotion
			--Avator
			player:gainMark("@tonghua")
			room:setPlayerMark(player, "tonghua", 1)
			room:loseMaxHp(player)
			player:drawCards(2)
		end
	end
}

BUILD_BURNING:addSkill(ciyuanbawangliu)
BUILD_BURNING:addSkill(tonghua)

BARBATOS = sgs.General(extension, "BARBATOS", "TEKKADAN", 4, true, false)

eji = sgs.CreateTriggerSkill{
	name = "eji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local count = data:toInt() - 1
		data:setValue(count)
	end
}

ejih = sgs.CreateMaxCardsSkill{
	name = "#ejih",
	extra_func = function(self, player)
		if player:hasSkill("eji") then
			return 1
		end
	end
}

tiexue = sgs.CreateTriggerSkill{
	name = "tiexue",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:isWounded() and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "tiexuedraw+tiexuebuff", data)
			if choice == "tiexuedraw" then
				room:broadcastSkillInvoke(self:objectName(), 1)
				player:drawCards(player:getLostHp())
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:addPlayerMark(player, "tiexue")
				local log = sgs.LogMessage()
				log.type = "#tiexuebuff"
				log.from = player
				room:sendLog(log)
			end
		end
	end
}

tiexuemark = sgs.CreateTriggerSkill{
	name = "#tiexuemark",
	events = {sgs.TurnStart, sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("tiexue") == 0 then return false end
		if event == sgs.TurnStart then
			room:removePlayerMark(player, "tiexue")
		else
			local damage = data:toDamage()
			if damage.chain or damage.transfer then return false end
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				room:broadcastSkillInvoke("tiexue", 3)
				room:sendCompulsoryTriggerLog(player, "tiexue")
				local log = sgs.LogMessage()
				log.type = "#tiexuedamage"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = damage.damage
				log.arg2 = damage.damage + 1
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end
}

BARBATOS:addSkill(eji)
BARBATOS:addSkill(ejih)
BARBATOS:addSkill(tiexue)
BARBATOS:addSkill(tiexuemark)
extension:insertRelatedSkills("eji", "#ejih")
extension:insertRelatedSkills("tiexue", "#tiexuemark")

LUPUS = sgs.General(extension, "LUPUS", "TEKKADAN", 4, true, false)

zaie = sgs.CreateTriggerSkill{
	name = "zaie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local count = data:toInt() + 1
		data:setValue(count)
	end
}

zaieh = sgs.CreateMaxCardsSkill{
	name = "#zaieh",
	extra_func = function(self, player)
		if player:hasSkill("zaie") then
			return -1
		end
	end
}

tianlang = sgs.CreateTriggerSkill{
	name = "tianlang",
	events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Analeptic") or use.card:isKindOf("Duel")) and room:askForCard(player, ".|black", "@@tianlang", data,  sgs.Card_MethodDiscard, nil, false, self:objectName(), false) then
				room:broadcastSkillInvoke(self:objectName())
				
				if use.card:isKindOf("Slash") then --qinggang_sword solution
					room:setCardFlag(use.card, "tianlang")
				end
				
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					players:append(p)
				end
				for _, p in sgs.qlist(players) do
					use.to:append(p)
				end
				local log = sgs.LogMessage()
				log.type = "#tianlang"
				log.to = players
				log.card_str = use.card:toString()
				room:sendLog(log)
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif event == sgs.TargetConfirmed then --qinggang_sword solution
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:hasFlag("tianlang") then
				room:setCardFlag(use.card, "-tianlang")
				for _,p in sgs.qlist(use.to) do
					if p:getTag("Qinggang"):toStringList()[1] == use.card:toString() and p:getTag("Qinggang"):toStringList()[2] == nil then
						p:addQinggangTag(use.card)
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_Finish and player:getMark("damage_point_round") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player)
				player:drawCards(2, self:objectName())
			end
		end
	end
}

LUPUS:addSkill(zaie)
LUPUS:addSkill(zaieh)
LUPUS:addSkill(tianlang)


REX = sgs.General(extension, "REX", "TEKKADAN", 4, true, false)

diwang = sgs.CreateTriggerSkill{
	name = "diwang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from:hasFlag("king_buff") then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					jink_table[index] = 0
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.DrawNCards then
			local x = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() < player:getHp() then
					x = x + 1
				end
			end
			if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..x)) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				if x <= 2 then
					room:setPlayerFlag(player, "king_buff")
				end
				data:setValue(x)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getHandcardNum() > damage.to:getHandcardNum() and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) and not damage.chain and not damage.transfer then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
					local log = sgs.LogMessage()
					log.type = "#tiexuedamage"
					log.from = player
					log.to:append(damage.to)
					log.card_str = damage.card:toString()
					log.arg = damage.damage
					log.arg2 = damage.damage + 1
					room:sendLog(log)
					damage.damage = damage.damage + 1
					damage.nature = sgs.DamageStruct_Thunder
					data:setValue(damage)
				end
			end
		end
	end
}

diwang_buff = sgs.CreateTargetModSkill{
	name = "#diwang",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasFlag("king_buff") then
			return player:getLostHp()
		else
			return 0
		end
	end
}

kuangxi = sgs.CreateTriggerSkill{
    name = "kuangxi",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		if player:getMark("@kuangxi") == 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("image=image/animate/kuangxi.png", 3000)
			room:setEmotion(player, "kuangxi")
			room:getThread():delay(3000)
			player:gainMark("@kuangxi")
			room:addPlayerMark(player, self:objectName())
			player:throwAllCards()
			player:drawCards(room:alivePlayerCount(), self:objectName())
			player:gainAnExtraTurn()
        end
    end
}

kuangxi_atk = sgs.CreateAttackRangeSkill{
	name = "#kuangxi_atk",
	extra_func = function(self, player)
		if player and player:getMark("@kuangxi") > 0 then
			return 1
		end
	end
}

--巴巴托斯的buff：当你使用【杀】或【决斗】令其他角色进入濒死时，其有5%机率立即死亡。（狂袭觉醒+1%机率）
REX_buff = sgs.CreateTriggerSkill{
	name = "REX_buff",
	events = {sgs.EnterDying},
	priority = 1,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and dying.damage.from and dying.damage.from:objectName() ~= player:objectName()
			and dying.damage.card and (dying.damage.card:isKindOf("Slash") or dying.damage.card:isKindOf("Duel"))
			and dying.damage.from:getGeneralName() == "REX" and math.random(1, 100) <= (5 + dying.damage.from:getMark("@kuangxi")) then
			local log = sgs.LogMessage()
			log.from = dying.damage.from
			log.type = "#REX_bug"
			room:sendLog(log)
			room:setEmotion(player, "REX_bug")
			room:getThread():delay(0500)
			room:broadcastSkillInvoke(self:objectName())
			room:getThread():delay(3500)
			room:killPlayer(player, dying.damage)
		end
	end
}

REX:addSkill(diwang)
REX:addSkill(diwang_buff)
extension:insertRelatedSkills("diwang", "#diwang")
REX:addSkill(kuangxi)
REX:addSkill(kuangxi_atk)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("REX_buff") then skills:append(REX_buff) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["gaoda"] = "高达杀",
	["EFSF"] = "地球联邦",
	["SLEEVE"] = "带袖的",
	["OMNI"] = "连合",
	["ZAFT"] = "扎多",
	["ORB"] = "奥布",
	["CB"] = "天人",
	["TEKKADAN"] = "铁华团",
	["OTHERS"] = "其他",
	["@point"] = "点数",
	["gdsvoice"] = "通信员",
	["seshia"] = "塞西娅",
	["meiling"] = "美玲",
	["yuudachi"] = "夕立",
	["#RemoveEquipArea"] = "%from 失去了%arg区",
	["#CardViewAs"] = "%from 的 %card 视为【%arg】",
	["@gdsrecord"] = "你想存档吗？",
	["~gdsrecord"] = "确定：存档",
	["@luckyrecord"] = "你想获得金币吗？",
	["~luckyrecord"] = "确定：获得",
	["map"] = "M炮",
	[":map"] = "<font color='red'><b>地图炮，</b></font>出牌阶段，对敌方发动大型攻击！（无伤害来源）<br><b>镭射炮(其他系列)</b>：令<b>任意多名</b>其他角色各受到2点雷电伤害。<br><b>创世纪(SEED系列)</b>：令<b>任意多名</b>其他角色各失去2点体力。<br><b>GN粒子炮(00系列)</b>：令<b>任意多名</b>其他角色各受到2点火焰伤害。",
	["#map"] = "%from 发动了 <font color='red'><b>地图炮</b></font>：%arg",
	["map1"] = "镭射炮",
	["map2"] = "创世纪",
	["map3"] = "GN粒子炮",
	["bursta"] = "A爆",
	[":bursta"] = "<font color='red'><b>攻击爆发(Attack Burst)：</b></font>当你造成伤害时，30%机率消耗3点爆发能量，令伤害+1。",
	["#bursta"] = "%from 对 %to 造成的伤害从 %arg 点增加至 %arg2 点",
	["burstd"] = "D爆",
	[":burstd"] = "<font color='#2E9AFE'><b>防御爆发(Defense Burst)：</b></font>当你受到伤害时，30%机率消耗3点爆发能量，令伤害-1。",
	["#burstd"] = "%to 受到的伤害从 %arg 点减少至 %arg2 点",
	["burstp"] = "P爆",
	[":burstp"] = "<font color='#2EFE64'><b>能力爆发(Power Burst)：</b></font>摸牌阶段，30%机率消耗3点能量，令摸牌数+1。",
	["#burstp"] = "%from 额外摸 %arg 张牌",
	["skin"] = "换肤",
	[":skin"] = "出牌阶段，你可以更换武将皮肤。（课金啊~）",
	["#lucky_card"] = "本局彩蛋卡牌为：%card<br>使用同名同花色同点数的牌时可获得 <b><font color='yellow'>1</font></b> 枚金币",
	["#coin"] = "恭喜 %from 获得<img src=\"image/mark/@coin.png\">× %arg",
	["zy_system_z"] = "昼",
	["zy_system_y"] = "夜",
	["sun"] = "昼：判定牌\
	♣视为♦",
	["moon"] = "夜：判定牌\
	♥视为♠",
	["#sun"] = "<img src=\"image/animate/sun.png\" width = \"40.75\" height = \"30.6\"><b>昼</b>：判定牌<img src=\"image/system/log/club.png\">视为<img src=\"image/system/log/diamond.png\">",
	["#moon"] = "<img src=\"image/animate/moon.png\" width = \"40.75\" height = \"30.6\"><b>夜</b>：判定牌<img src=\"image/system/log/heart.png\">视为<img src=\"image/system/log/spade.png\">",
	["#BGM"] = "%arg",
	["BGM0"] = "♪ ☆Divine Act -The EXTREME-MAXI BOOST-",
	["BGM1"] = "♪ FINAL MISSION~QUANTUM BURST",
	["BGM2"] = "♪ 妖気と微笑み",
	["BGM3"] = "♪ SALLY <出擊>",
	["BGM4"] = "♪ 宇宙海賊クロスボーンバンガード戦闘テーマ",
	["BGM5"] = "♪ 俺のこの手が光って念るぅ！",
	["BGM6"] = "♪ 明镜止水",
	["BGM7"] = "♪ 覚醒シン・アスカ",
	["BGM8"] = "♪ 出撃！インパルス",
	["BGM9"] = "♪ UNICORN",
	["BGM10"] = "♪ 翔ベ！フリーダム",
	["BGM11"] = "♪ 思春期を殺した少年の翼",
	["BGM12"] = "♪ LAST IMPRESSION",
	["BGM13"] = "♪ STRIKE出撃",
	["BGM14"] = "♪ DECISIVE BATTLE",
	["BGM15"] = "♪ Superior Attack",
	["BGM16"] = "♪ GX Dashes Out",
	["BGM17"] = "♪ 正義と自由",
	["BGM18"] = "♪ 悪の3兵器",
	["BGM19"] = "♪ 立ち上がれ！怒りよ",
	["BGM20"] = "♪ FIGHT",
	["BGM21"] = "♪ GUNDAM BUILD FIGHTERS",
	["BGM22"] = "♪ 宇宙を駆ける",
	["BGM23"] = "♪ Mobile Suit Gundam - Iron-Blooded Orphans",
	["BGM24"] = "♪ 颯爽たるシャア",
	["BGM25"] = "♪ 燃えあがれ闘志 - 忌まわしき宿命を越えて",
	["BGM26"] = "♪ 叫びと撃鉄",
	["BGM27"] = "♪ キラ、その心のままに",
	["BGM28"] = "♪ Crescent Moon - Mobile Suit Gundam : Iron-Blooded Orphans 2",
	["BGM29"] = "♪ STARGAZER ～星の扉",
	
	["IIVS"] = "辉勇面",
	["#IIVS"] = "极限全力",
	["~IIVS"] = "レオス！！帰ってきてください…お願いっ…！！",
	["designer:IIVS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IIVS"] = "雷奥斯·阿莱",
	["illustrator:IIVS"] = "wch5621628",
	["yuexian"] = "越限",
	[":yuexian"] = "<b>[1]</b>出牌阶段，你可以增加<b>1</b>点数激活<b><font color='orange'>“日蚀”</font></b>、<b><font color='orange'>“异化”</font></b>或<b><font color='orange'>“神圣”</font></b>，时限直到你的下回合开始前。\
	\
	<b>{3}点数特效</b>：当你的点数达致<b>3</b>时，点数清零，下回合不可发动<b>“越限”</b>。",
	["rishi"] = "日蚀",
	[":rishi"] = "<b><font color='orange'>激活技</font></b>，你使用的【杀】可额外指定一个目标且无距离限制。",
	["yihua"] = "异化",
	[":yihua"] = "<b><font color='orange'>激活技</font></b>，当其他角色对你使用非延时类锦囊牌结算后，你可以摸一张牌，然后将一张【杀】当火【杀】对其使用。",
	["#yihua"] = "请将一张【杀】当火【杀】对其使用",
	["shensheng"] = "神圣",
	[":shensheng"] = "<b><font color='orange'>激活技</font></b>，当你成为【杀】的目标后，你可以亮出牌堆顶的两张牌，你依次使用或获得之。",
	["#shensheng"] = "请选择【%src】的目标，或按取消获得此牌",
	["~shensheng"] = "选择目标→确定",
	["ssuse"] = "使用此装备牌",
	["ssobtain"] = "获得此装备牌",
	["#point"] = "%from 发动了<b><font color='orange'>点数特效</font></b>：%arg",
	["#IIVSp"] = "点数清零，下回合不可发动<b>“越限”</b>。",
	["#yuexian"] = "%from 激活了<b>“%arg”</b>",
	["$yuexian1"] = "エクリプス·フェース！",
	["$yuexian2"] = "ゼノン·フェース！",
	["$yuexian3"] = "アイオス·フェース！",
	["$rishi"] = "全ての人類の希望を…この一撃に！",
	["$yihua"] = "パイルピリオド！",
	["$shensheng"] = "アリス·ファンネル！",
	
	["GUNDAM"] = "高达",
	["yuanzu"] = "元祖",
	[":yuanzu"] = "游戏开始时、回合开始时或结束后，你可以获得一名其他角色的一项技能，直到你下一次发动<b>“元祖”</b>。（不可为限定技、觉醒技或主公技）",
	["$yuanzu"] = "我来让你见识一下，高达不只是白兵战用MS！",
	["gprevious"] = "上一页",
	["gnext"] = "下一页",
	["~GUNDAM"] = "可…可恶！到此为止了吗？",
	["#GUNDAM"] = "白色恶魔",
	["designer:GUNDAM"] = "wch5621628 & Sankies & NOS7IM",
	["cv:GUNDAM"] = "阿姆罗·雷",
	["illustrator:GUNDAM"] = "wch5621628",
	
	["UNICORN"] = "独角兽",
	["UNICORN_NTD"] = "毁灭模式",
	["#UNICORN"] = "可能性之兽",
	["~UNICORN"] = "御免…オードリー…",
	["~UNICORN_NTD"] = "御免…オードリー…",
	["designer:UNICORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:UNICORN"] = "巴纳吉·林克斯",
	["illustrator:UNICORN"] = "wch5621628",
	["shenshou"] = "神兽",
	[":shenshou"] = "当你使用一张<font color='red'><b>红色</b></font>的【杀】指定一名角色为目标后，你可以令其交给你一张<font color='red'><b>红色</b></font>牌，否则此【杀】不可被【闪】响应。",
	["@@shenshou"] = "请交给 %src 一张<font color='red'><b>红色</b></font>牌，否则此【杀】不可被【闪】响应",
	["NTD"] = "NT-D",
	[":NTD"] = "<img src=\"image/mark/@NTD.png\"><b><font color='green'>觉醒技，</font></b>当你成为一张非延时类锦囊牌的目标时，若你的体力不多于2，你须减1点体力上限终止此牌结算，展示你当前手牌，其中每有一张<font color='red'><b>红色</b></font>牌，你回复1点体力或摸一张牌，并获得技能<b>“毁灭”</b>（当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'><b>红色</b></font>手牌终止此牌结算，并视为你使用此牌）。",
	["@NTD"] = "NT-D",
	["ntddraw"] = "摸一张牌",
	["ntdrecover"] = "回复 1 点体力",
	["quanwu"] = "全武",
	[":quanwu"] = "<img src=\"image/mark/@linguang.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时，若你装备区的牌数不小于3，且已发动<b>“NT-D”</b>，将武将牌更换为<b><font color='green'>“彩虹的彼方 – FA UNICORN”</font></b>。",
	["huimie"] = "毁灭",
	[":huimie"] = "当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'><b>红色</b></font>手牌终止此牌结算，并视为你使用此牌。",
	["huimiecard"] = "毁灭",
	["@huimie"] = "请弃置一张<font color='red'><b>红色</b></font>手牌终止【%src】结算",
	["~huimie"] = "选择目标→确定",
	["#huimie"] = "请选择【%src】的目标",
	["$shenshou"] = "（Beam Magnum）",
	["$NTD"] = "（NT-D Activated）",
	["$huimie1"] = "信じるんだ!自分の成すべきと思ったことを…!",
	["$huimie2"] = "人の心を知るものなら、ガンダム!俺に力を貸せ!",
	["$quanwu"] = "人の未来は…人が創るものだろ!!",
	
	["FA_UNICORN"] = "FA独角兽",
	["#FA_UNICORN"] = "彩虹的彼方",
	["~FA_UNICORN"] = "御免…オードリー…",
	["designer:FA_UNICORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:FA_UNICORN"] = "巴纳吉·林克斯",
	["illustrator:FA_UNICORN"] = "wch5621628",
	["zhonggong"] = "重攻",
	[":zhonggong"] = "出牌阶段限一次，你可以失去装备区的一个位置，然后对一名其他角色造成1点伤害。",
	["qingzhuang"] = "轻装",
	[":qingzhuang"] = "<b><font color='blue'>锁定技，</font></b>若你没有装备区：你与其他角色的距离-2，<font color='red'><b>红色</b></font>【杀】对你无效。",
	["qingzhuang_redslash"] = "<font color='red'><b>红色</b></font>杀",
	["linguang"] = "磷光",
	[":linguang"] = "<img src=\"image/mark/@linguang.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以：回复1点体力，并将所有其他角色的武将牌翻面。若如此做，你的装备牌视为【杀】，你失去装备区。",
	["@linguang"] = "磷光",
	["#linguangfilter"] = "磷光",
	["$zhonggong1"] = "パージする!",
	["$zhonggong2"] = "装備、切り離すぞ!",
	["$qingzhuang"] = "サイコ…フィールド",
	["$linguang"] = "俺の声に応えろ! ユニコーン!",
	
	["KSHATRIYA"] = "刹帝利",
	["#KSHATRIYA"] = "四枚羽根",
	["~KSHATRIYA"] = "姫様、申し訳ありません…。\
マリーダ・クルス、ここまでです…",
	["designer:KSHATRIYA"] = "wch5621628 & Sankies & NOS7IM",
	["cv:KSHATRIYA"] = "玛莉妲·库鲁斯",
	["illustrator:KSHATRIYA"] = "wch5621628",
	["qingyu"] = "青羽",
	[":qingyu"] = "弃牌阶段弃牌后，你可以依次将被弃置的牌中所有：\
♠牌当一张【南蛮入侵】、\
<font color='red'>♥</font>牌当一张【万箭齐发】、\
♣牌当一张【过河拆桥】、\
<font color='red'>♦</font>牌当一张【顺手牵羊】使用。",
	["#qingyu1"] = "请使用【南蛮入侵】",
    ["#qingyu2"] = "请使用【万箭齐发】",
    ["#qingyu3"] = "请选择【过河拆桥】的目标",
    ["#qingyu4"] = "请选择【顺手牵羊】的目标",
	["~qingyu"] = "选择目标→确定",
    ["siyi"] = "四翼",
	[":siyi"] = "当你使用一张非延时类锦囊牌时，你可以额外或减少指定至多X个目标（X为你当前装备区的牌数）。",
	["#siyi1"] = "请选择要减少的目标（至多X个目标，X为你当前装备区的牌数）",
	["#siyi2"] = "请选择要减少的目标（至多X个目标，X为你当前装备区的牌数）",
	["~siyi"] = "选择目标→确定",
	["$siyilog"] = "%from 取消了 %to 为目标角色",
	["$qingyu1"] = "行けっ、ファンネル!",
	["$qingyu2"] = "ファンネル!",
	["$qingyu3"] = "ファンネル達!",
	["$qingyu4"] = "光の中に消えろ!",
	["$siyi1"] = "ならばこれ、受けてみるか!",
	["$siyi2"] = "お前だけは…落とす!",
	["$siyi3"] = "この機体の実力…その魂に刻め!",
	["$siyi4"] = "光…全てを焼き尽くす、浄化の光…",
	
	["SINANJU"] = "新安洲",
	["#SINANJU"] = "赤色彗星再临",
	["~SINANJU"] = "まさか…こんな可能性がっ…!",
	["designer:SINANJU"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SINANJU"] = "弗尔·伏朗托",
	["illustrator:SINANJU"] = "Sankies",
	["xiaya"] = "夏亚",
	[":xiaya"] = "你可以将一张<font color='red'><b>红色</b></font>牌当【闪】使用或打出。",
	["zaishi"] = "再世",
	[":zaishi"] = "摸牌阶段摸牌时，你可以放弃摸牌，然后展示你的手牌，你重复摸牌，直到你拥有<font color='red'><b>三张红色</b></font>手牌，或以此法获得四张牌。",
	["wangling"] = "亡灵",
	[":wangling"] = "当你受到一次伤害时，你可以失去一项其他技能并防止此伤害，然后视为你对伤害来源使用一张【杀】。",
	["wanglingcard"] = "亡灵",
	["$xiaya1"] = "当たらなければどうという事はない!",
	["$xiaya2"] = "この程度では落とされんよ!",
	["$xiaya3"] = "見事と言いたいところだが、まだ甘い",
	["$zaishi1"] = "これは、ニュータイプを否定した人類への報いだ!",
	["$zaishi2"] = "これが光を見た者の思いと知れ!",
	["$wangling1"] = "これが、赤い彗星の再来とはな…",
	["$wangling2"] = "私が君を殺す",
	
	["ReZEL"] = "里歇尔",
	["#ReZEL"] = "联邦精锐",
	["~ReZEL"] = "",
	["designer:ReZEL"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ReZEL"] = "诺姆队长",
	["illustrator:ReZEL"] = "Sankies",
	["duilie"] = "队列",
	[":duilie"] = "准备阶段开始时，你可以进行一次判定，根据判定牌获得相应效果，直到你的下回合开始前：\
<b>单数</b>：你使用点数为<b>单数</b>的牌时无距离限制。\
<b>双数</b>：点数为<b>双数</b>的牌对你无效。\
<b>黑色</b>：当你使用一张<b>黑色</b>牌时，你可以弃置目标角色的一张牌。\
<b><font color='red'>红色</font></b>：当你成为一张<b><font color='red'>红色</font></b>牌的目标后，你可以摸一张牌。",
	["#duiliee"] = "队列",
	["duilie:draw"] = "你是否发动“%dest”摸一张牌？",
	["duilie:throw"] = "你是否发动“%dest”弃置 %src 的一张牌？",
    ["#duilieA"] = "%from 获得效果：\
<font color='yellow'>你使用点数为<b>单数</b>的牌时无距离限制</font>",
	["#duilieB"] = "%from  获得效果：\
<font color='yellow'>点数为<b>双数</b>的牌对你无效</font>",
	["#duilieC"] = "%from  获得效果：\
<font color='yellow'>当你使用一张</font><b><font color='black'>黑色</font></b><font color='yellow'>牌时，你可以弃置目标角色的一张牌</font>",
	["#duilieD"] = "%from  获得效果：\
<font color='yellow'>当你成为一张</font><b><font color='red'>红色</font></b><font color='yellow'>牌的目标后，你可以摸一张牌</font>",
	["#duilieBe"] = "%from 的技能 %arg 被触发，点数为<b>双数</b>的牌对其无效",
	["zhihui"] = "指挥",
	[":zhihui"] = "当你发动“队列”后，你可以令你攻击范围内的一名其他角色共享你的效果。",
	["@@zhihui"] = "请选择攻击范围内的一名其他角色共享“队列”",
	
	["DELTA_PLUS"] = "德尔塔+",
	["#DELTA_PLUS"] = "时代的反抗者",
	["~DELTA_PLUS"] = "みんなで俺を否定するのか…!",
	["designer:DELTA_PLUS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DELTA_PLUS"] = "利迪·马瑟纳斯",
	["illustrator:DELTA_PLUS"] = "wch5621628",
	["xiezhan"] = "协战",
	[":xiezhan"] = "出牌阶段，你可以将一张装备牌置于你攻击范围内的一名其他角色的装备区里，视为其对你选择的另一名角色使用一张<b><font color='red'>红色</font></b>【杀】。",
	["xiezhancard"] = "协战",
	["tupo"] = "突破",
	[":tupo"] = "出牌阶段限一次，你可以视为使用一张【借刀杀人】，若目标角色选择不使用【杀】：你须装备此武器并视为你使用一张【杀】，结算后你失去1点体力。",
	["#tuporecord"] = "突破",
	["tupocard"] = "突破",
	["$xiezhan1"] = "変形機構を試す。こらえてくれよ!",
	["$xiezhan2"] = "やっぱ俺は、人型よりもこっちだね",
	["$xiezhan3"] = "お前の打撃力と俺の機動力。2つを合わせてヤツの土手っ腹をブチ抜く!",
	["$tupo1"] = "こいつだって、Z計画の名残なんだ!",
	["$tupo2"] = "箱の犠牲になる人間は、俺一人で十分だ!",
	
	["BANSHEE"] = "黑独角兽",
	["#BANSHEE"] = "报丧妖女",
	["~BANSHEE"] = "私は…ガンダム?",
	["designer:BANSHEE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BANSHEE"] = "普路十二",
	["illustrator:BANSHEE"] = "wch5621628",
	["mengshi"] = "猛狮",
	[":mengshi"] = "当你使用一张<b>黑色</b>的【杀】指定一名角色为目标后，你可以将其装备区里的一张牌置于其手牌，若如此做，你于此阶段可额外使用一张【杀】。",
	["#mengshislash"] = "猛狮",
	["ntdtwo"] = "NT-D",
	[":ntdtwo"] = "<img src=\"image/mark/@NTD2.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以：减1点体力上限，展示你当前手牌，每有一张<b>黑色</b>牌，视为你使用一张【过河拆桥】，并获得技能<b>“报丧”</b>（当你成为一张非延时类锦囊牌的目标时，你可以将一张<b>黑色</b>手牌当【乐不思蜀】或【兵粮寸断】使用，并终止此牌结算）",
	["@NTD2"] = "NT-D",
	["@ntdtwo"] = "请选择【过河拆桥】的目标角色",
	["~ntdtwo"] = "选择目标→确定",
	["baosang"] = "报丧",
	[":baosang"] = "当你成为一张非延时类锦囊牌的目标时，你可以将一张<b>黑色</b>手牌当【乐不思蜀】或【兵粮寸断】使用，并终止此牌结算。",
	["@baosang"] = "请选择【%src】的目标角色",
	["~baosang"] = "选择一张黑色手牌→选择目标→确定",
	["$mengshi1"] = "敵は全て焼き払う",
	["$mengshi2"] = "障害となる存在は破壊する",
	["$mengshi3"] = "立ちはだかるつもりか!",
	["$ntdtwo1"] = "この光は、憎しみの光!",
	["$ntdtwo2"] = "バンシィ…憎しみを流し込めぇ!!",
	["$ntdtwo3"] = "私を救ってくれる光…誰にも奪わせはしない!",
	["$baosang1"] = "灼いてやる! 苦しむがいい!",
	["$baosang2"] = "何も感じない人間などに!",
	["$baosang3"] = "誰にも邪魔はさせない。お前の腹も切り裂いてやる…!",
	
	["NORN"] = "黑独角兽N",
	["#NORN"] = "命运女神",
	["~NORN"] = "ガンダム…ガンダム…ガンダム…ガンダム!! ガン……ッ",
	["designer:NORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:NORN"] = "利迪·马瑟纳斯",
	["illustrator:NORN"] = "wch5621628",
	["shenshi"] = "神狮",
	--[":shenshi"] = "出牌阶段结束时，你可以将一至三张手牌明置于一名其他角色的手牌里，称为<b>“破”</b>。其他角色的结束阶段开始时，若其拥有<b>“破”</b>，你对其造成1点伤害，将其所有<b>“破”</b>置入弃牌堆。",
	[":shenshi"] = "当你指定或成为<b>黑色</b>【杀】的目标后，你可以令此【杀】视为【决斗】（计入【杀】的使用次数）。",
	--["shenshipile"] = "选择“破”",
	--["shenshihand"] = "选择其他手牌",
	--["@shenshi"] = "请将一至三张手牌明置于一名其他角色的手牌里",
	--["~shenshi"] = "选择手牌→选择目标→确定",
	--["po"] = "破",
	["ntdthree"] = "NT-D",
	[":ntdthree"] = "<img src=\"image/mark/@NTD3.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以：减1点体力上限，展示你当前手牌，每有一张<b>黑色</b>牌，视为你使用一张【过河拆桥】，并获得技能<b>“诅咒”</b>（当你成为一张非延时类锦囊牌的目标时，你可以将一张<b>黑色</b>手牌当【杀】使用，并终止此牌结算）。",
	["@NTD3"] = "NT-D",
	["@ntdthree"] = "请选择【过河拆桥】的目标角色",
	["~ntdthree"] = "选择目标→确定",
	["zuzhou"] = "诅咒",
	[":zuzhou"] = "当你成为一张非延时类锦囊牌的目标时，你可以将一张<b>黑色</b>手牌当【杀】使用，并终止此牌结算。",
	["@zuzhou"] = "请选择【杀】的目标角色",
	["~zuzhou"] = "选择一张黑色手牌→选择目标→确定",
	["xuanguang"] = "炫光",
	[":xuanguang"] = "<img src=\"image/mark/@xuanguang.png\"><b><font color='green'>觉醒技，</font></b>当你处于濒死状态求桃完毕后，且已发动<b>“NT-D”</b>，你失去装备区，失去技能<b>“诅咒”</b>，体力回复至1点，并获得以下效果：你的装备牌视为【桃】，没有装备的角色防止属性伤害。",
	["@xuanguang"] = "炫光",
	["#xuanguangfilter"] = "炫光",
	["#xuanguang"] = "%from 没有装备，触发“%arg”效果，防止了属性伤害",
	["$shenshi1"] = "バラバラになっちまえ!",
	["$shenshi2"] = "狙いは外さない!",
	["$ntdthree1"] = "お前さえいなければ!!",
	["$ntdthree2"] = "忌まわしいガンダム共が!!",
	["$zuzhou1"] = "みんなで俺を否定するのか…",
	["$zuzhou2"] = "抗えないのさ…現実には!",
	["$zuzhou3"] = "俺の邪魔をするからこうなる!",
	["$zuzhou4"] = "バナァァジィィィ!!",
	["$xuanguang1"] = "行け…バンシィ!!",
	["$xuanguang2"] = "バンシィ、俺に力を貸してくれ…!",
	
	["PHENEX"] = "凤凰独角兽",
	["#PHENEX"] = "金色的不死鸟",
	["~PHENEX"] = "",
	["designer:PHENEX"] = "wch5621628 & Sankies & NOS7IM",
	["cv:PHENEX"] = "",
	["illustrator:PHENEX"] = "wch5621628",
	["shenniao"] = "神鸟",
	[":shenniao"] = "出牌阶段限一次，你可以弃置两张基本牌，令一至两名其他角色的所有装备效果无效，直到你的下回合开始前。",
	["$shenniaolog"] = "%from 对 %to 发动了“%arg”，%to 的 %card 效果无效",
	
	["EX_S"] = "EX-S",
	["#EX_S"] = "精灵的意志",
	["~EX_S"] = "",
	["designer:EX_S"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EX_S"] = "",
	["illustrator:EX_S"] = "wch5621628",
	["fanshe"] = "反射",
	[":fanshe"] = "出牌阶段限一次，你可以亮出牌堆顶的一张牌，若为<b><font color='red'>红色</font></b>，将其置于一名其他角色的武将牌上，称为<b><font color='red'>“INCOM”</font></b>，本回合你使用的牌由<b><font color='red'>“INCOM”</font></b>角色计算距离，且视为<b><font color='red'>“INCOM”</font></b>角色使用（你为伤害来源）。结束阶段开始时，你回收<b><font color='red'>“INCOM”</font></b>。",
	["@fanshe"] = "请将<b><font color='red'>“INCOM”</font></b>置于一名其他角色的武将牌上",
	[":ALICE"] = "当你受到【杀】造成的伤害时，你可以观看牌堆顶的三张牌，若其中有两张相同花色的牌，你亮出之。你获得其中一张牌，将另一张牌交给伤害来源并防止此伤害。",
	["@ALICE-obtain"] = "请选择一张你获得的牌",
	["@ALICE-give"] = "请选择一张 %src 获得的牌",
	
	["HYAKU_SHIKI"] = "百式",
	["#HYAKU_SHIKI"] = "战场之金",
	["~HYAKU_SHIKI"] = "家族共々死刑になるぞ!停戦信号の見落としは!",
	["designer:HYAKU_SHIKI"] = "高达杀制作组",
	["cv:HYAKU_SHIKI"] = "古华多罗·巴兹纳",
	["illustrator:HYAKU_SHIKI"] = "VerBiKeo",
	["luashipo"] = "识破",
	[":luashipo"] = "出牌阶段，你可以将一张除【无懈可击】外的锦囊牌置于你的武将牌上，称为<b>“历战”</b>（至多三张）。你可以将一张<b>“历战”</b>牌当【无懈可击】使用。",
	["lizhan"] = "历战",
	["leishe"] = "镭射",
	[":leishe"] = "<img src=\"image/mark/@leishe.png\">当你发动<b>“识破”</b>使用一张【无懈可击】时，你获得一个<b>“镭射”</b>标记。出牌阶段限一次，你可以弃置三个<b>“镭射”</b>标记，然后对一名其他角色造成1点雷电伤害。",
	["@leishe"] = "镭射",
	["$luashipo1"] = "これは戦争だ",
	["$luashipo2"] = "下がれ、私が全て倒す!",
	["$luashipo3"] = "無駄だ",
	["$luashipo4"] = "あまいな",
	["$leishe1"] = "各モビルスーツはメガ・バズーカ・ランチャーの射線上に近づくな!",
	["$leishe2"] = "メガ・バズーカ・ランチャーを射出してくれ。聞こえるか!?",
	["$leishe3"] = "全パワーを解放!",
	
	["SHINING"] = "闪光",
	["#SHINING"] = "天降的战士",
	["~SHINING"] = "駄目だ……駄目だ駄目だぁッ!!",
	["designer:SHINING"] = "高达杀制作组",
	["cv:SHINING"] = "多蒙·卡修",
	["illustrator:SHINING"] = "wch5621628",
	["shanguang"] = "闪光",
	[":shanguang"] = "出牌阶段限一次，你可以弃置一张【闪】并令攻击范围内的一名其他角色选择一项：1.弃置一张装备牌；2.受到你造成的1点伤害。",
	["@@shanguang"] = "请弃置一张装备牌，否则受到1点伤害",
	["chaojimoshi"] = "超级模式",
	[":chaojimoshi"] = "<img src=\"image/mark/@supermode.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时，若你受到过至少3点伤害，体力上限减至1点，攻击范围+1，将<b>“闪光”</b>描述中的<b>“限一次”</b>改为<b>“限两次”</b>、<b>“【闪】”</b>改为<b>“【闪】或武器牌”</b>。",
	["chaojimoshi:jink"] = "你是否发动【真·超级模式】，视为使用一张【闪】？",
	["chaojimoshi_jink"] = "真·超级模式",
	["@supermode"] = "超级模式",
	["jingxin"] = "净心",
	[":jingxin"] = "当你发动<b>“超级模式”</b>时，若你的点数：小于3，你可以拒绝发动，摸一张牌并获得1点数；不小于3，<b>“超级模式”</b>增加描述<b>“手牌上限+2；你可以花费1点数，视为使用或打出【闪】”</b>。",
	["SHINING_S"] = "闪光·明镜止水",
	["$shanguang1"] = "必殺!シャイニングフィンガー!",
	["$shanguang2"] = "シャイニングフィンガーソオォォォォォドッ!!",
	["$chaojimoshi1"] = "愛と!!怒りと!!悲しみのぉぉッ!!",
	["$chaojimoshi2"] = "はぁぁぁぁぁぁあああ……てやあああぁぁッ!!!",
	["$chaojimoshi3"] = "明鏡止水の心で勝ち取ったあのパワーで…勝負!",
	["$jingxin"] = "（~水滴声~）",
	
	["WZ"] = "飞翼零式",
	["#WZ"] = "零式之翼",
	["~WZ"] = "俺は…俺は…俺は、俺は死なない…!",
	["designer:WZ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:WZ"] = "希罗·尤",
	["illustrator:WZ"] = "Sankies",
	["wzpoint"] = "点数特效",
	[":wzpoint"] = "<b>{X}</b>出牌阶段，你可以花费所有点数，然后摸等量张牌。",
	["feiyi"] = "飞翼",
	[":feiyi"] = "<b><font color='blue'>锁定技，</font></b>若你的体力为2或更少，你使用【杀】时无距离限制；若你的体力为1，你于出牌阶段可以额外使用一张【杀】。",
	["liuxing"] = "流星",
	[":liuxing"] = "<b>[1]</b>你可以增加<b>1</b>点数，将两张手牌当【杀】使用，使用时进行一次判定，若为<font color='red'><b>红色</b></font>，此牌造成的伤害+1。\
	\
	<b>{X}点数特效：</b>出牌阶段，你可以花费所有点数，然后摸等量张牌。",
	["lingshi"] = "零式",
	[":lingshi"] = "准备阶段开始时，若你的点数为3或更多，你可以观看牌堆顶的三张牌，并以任意顺序置于牌堆顶。",
	["$wzpoint1"] = "完全に破壊する",
	["$wzpoint2"] = "逃がしはしない",
	["$wzpoint3"] = "ガンダムは宇宙には必要だ…! 宇宙を守るため、俺は戦う!",
	["$wzpoint4"] = "やはり…ガンダムの敵はガンダムか!",
	["$liuxing1"] = "排除開始",
	["$liuxing2"] = "フォーメーションを寸断する",
	["$liuxing3"] = "ターゲット、ロックオン…",
	["$liuxing4"] = "殲滅する",
	["$liuxing5"] = "逃れる事は出来ない!",
	["$lingshi1"] = "行くぞ、ゼロ!",
	["$lingshi2"] = "ゼロよ、俺を導いてくれ",
	["$lingshi3"] = "俺にははっきり見える、俺の敵が!",
	["$lingshi4"] = "コードZ.E.R.O.、ゼロシステム発動…!",
	["$lingshi5"] = "ウイングゼロが見せた未来から、俺が選んだのはこれだ!",
	["$lingshi6"] = "未来は視えている筈だ!",
	["$lingshi7"] = "ゼクス!強者などどこにもいない!人類全てが弱者なんだ!俺もお前も弱者なんだ!",
	["$lingshi8"] = "（Zero System）",
	
	["EPYON"] = "艾比安",
	["#EPYON"] = "恶魔的獠牙",
	["~EPYON"] = "リリーナ…なんとしても生き抜いてくれ。\
	さらばだ、我が妹!",
	["designer:EPYON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EPYON"] = "米利亚尔特·匹斯克拉福特",
	["illustrator:EPYON"] = "Sankies",
	["qishi"] = "骑士",
	[":qishi"] = "<b><font color='blue'>锁定技，</font></b>你的【南蛮入侵】、【万箭齐发】及【火攻】均视为【杀】；你的攻击范围始终为1。",
	["mosu"] = "魔速",
	[":mosu"] = "当一名其他角色于其回合内对你造成一次伤害后，你可以令当前回合立即结束，然后你进行一个额外的回合，本回合，你与其距离视为1。",
	["cishi"] = "次式",
	[":cishi"] = "当你于出牌阶段杀死一名角色时，你可以：摸两张牌，你于此阶段内使用【杀】时无次数限制。",
	["$qishi1"] = "私なりの騎士道、貫かせてもらう!",
	["$qishi2"] = "この刃、受けてみろ!",
	["$qishi3"] = "弱者を作り出すのは強者だ!",
	["$mosu1"] = "この戦いに何の意味がある…?どんな意味が有るというのだ!!",
	["$mosu2"] = "この距離はエピオンの間合いだ!",
	["$mosu3"] = "エピオンの真の力…見せてやろう!",
	["$mosu4"] = "私はここだぁあ!",
	["$mosu5"] = "所詮は血塗られた運命、今更この罪から免れようとは思わん‼",
	["$mosu6"] = "必要ないのだ! 宇宙にとって貴様は!",
	["$mosu7"] = "決着をつけるぞ、ヒイロ!",
	["$cishi1"] = "この機体の能力、分かっていないようだな!",
	["$cishi2"] = "ゼロシステム…私に本当の敵を見せろ!",
	["$cishi3"] = "エピオン…未来を見せてくれ",
	["$cishi4"] = "行け! エピオン! 私に未来を見せるのだ!",
	["$cishi5"] = "ゼロシステムの力…最大限まで引き出す!",
	
	["WZC"] = "飞翼零式改",
	["#WZC"] = "纯白之翼",
	["~WZC"] = "任務…完了…自爆する",
	["designer:WZC"] = "wch5621628 & Sankies & NOS7IM",
	["cv:WZC"] = "希罗·尤",
	["illustrator:WZC"] = "Sankies",
    ["shuangpao"] = "双炮",
	[":shuangpao"] = "出牌阶段限一次，你可以失去1点体力，若如此做，你本回合使用【杀】对距离1以外的目标角色造成的伤害+1。",
	["#shuangpao"] = "%from 发动了“%arg”，本回合使用【杀】对距离1以外的目标角色造成的伤害+1。",
	["ew_lingshi"] = "零式",
	["@ew_lingshi"] = "零式",
	[":ew_lingshi"] = "<img src=\"image/mark/@ew_lingshi.png\"><b><font color='red'>限定技，</font></b>当你没有手牌时失去体力后，你可以观看牌堆顶的十张牌，将其中任意数量的牌以任意顺序置于牌堆顶，你获得其余的牌，然后将你的武将牌翻面。",
	["$shuangpao1"] = "排除開始",
	["$shuangpao2"] = "フォーメーションを寸断する",
	["$shuangpao3"] = "ターゲット、ロックオン…",
	["$shuangpao4"] = "殲滅する",
	["$ew_lingshi1"] = "行くぞ、ゼロ!",
	["$ew_lingshi2"] = "ゼロよ、俺を導いてくれ",
	["$ew_lingshi3"] = "俺にははっきり見える、俺の敵が!",
	["$ew_lingshi4"] = "コードZ.E.R.O.、ゼロシステム発動…!",
	["$ew_lingshi5"] = "ウイングゼロが見せた未来から、俺が選んだのはこれだ!",
	["$ew_lingshi6"] = "未来は視えている筈だ!",
	["$ew_lingshi7"] = "ゼクス!強者などどこにもいない!人類全てが弱者なんだ!俺もお前も弱者なんだ!",
	["$ew_lingshi8"] = "（Zero System）",
	["$ew_lingshi9"] = "零式、（哪咤）、引导我吧！",
	
	["DSH"] = "地狱死神改",
	["#DSH"] = "月下的死神",
	["~DSH"] = "くっそぉ~、結構な仕事だったぜ",
	["designer:DSH"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DSH"] = "迪奥·麦克斯维尔",
	["illustrator:DSH"] = "Sankies",
	["yindun"] = "隐遁",
	[":yindun"] = "结束阶段开始时，你可以摸一张牌，然后将你的武将牌翻面；当你的武将牌背面朝上时，你不能成为【杀】的目标。",
	["ansha"] = "暗杀",
	[":ansha"] = "当一名其他角色于其弃牌阶段弃置牌后，若你的武将牌背面朝上，你可以弃置一张牌并将你的武将牌翻至正面朝上，然后令其失去1点体力。",
	["$yindun1"] = "行くぜぇ!",
	["$yindun2"] = "俺と一緒に、地獄行くぜぇ!",
	["$ansha1"] = "死ぬぜぇ……俺を見たやつは、みんな死んじまうぞぉ!",
	["$ansha2"] = "オラオラ、死神様のお通りだぁー!",
	
	["HAC"] = "重武装改",
	["#HAC"] = "小丑之泪",
	["~HAC"] = "始めるか、俺の自爆ショーを…",
	["designer:HAC"] = "wch5621628 & Sankies & NOS7IM",
	["cv:HAC"] = "多洛华·巴顿",
	["illustrator:HAC"] = "Sankies",
	["gelin"] = "格林",
	[":gelin"] = "游戏开始时，你将牌堆顶的十张牌移出游戏，称为<b>“弹”</b>；你可以将一张<b>“弹”</b>当【杀】、两张“弹”当【闪】使用或打出。",
	["dan"] = "弹",
	["saoshe"] = "扫射",
	[":saoshe"] = "<b><font color='blue'>锁定技，</font></b>当你于出牌阶段计算你使用【杀】的次数限制时，每名目标角色独立计算。",
	["$gelin1"] = "后方支援交给我吧",
	["$gelin2"] = "歼灭敌机!",
	
	["SANDROCK"] = "沙漠改",
	["#SANDROCK"] = "沙漠之双镰",
	["~SANDROCK"] = "これ以上は戦えない…",
	["designer:SANDROCK"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SANDROCK"] = "卡托鲁·拉贝巴·温纳",
	["illustrator:SANDROCK"] = "Sankies",
	["shuanglian"] = "双镰",
	["shuangliancard"] = "双镰",
	[":shuanglian"] = "当你使用【杀】时，你可以弃置一张【闪】，令攻击范围内的一名其他角色打出一张【闪】，否则你对其造成1点伤害；当你使用或打出【闪】时，你可以将你的武将牌翻面，视为对一个目标使用一张【杀】。",
	["shuanglian:slash"] = "你想发动技能“双镰”吗?<br>当你使用【杀】时，你可以弃置一张【闪】，令攻击范围内的一名其他角色打出一张【闪】，否则你对其造成1点伤害。",
	["shuanglian:jink"] = "你想发动技能“双镰”吗?<br>当你使用或打出【闪】时，你可以将你的武将牌翻面，视为对一个目标使用一张【杀】。",
	["@@shuanglianjink"] = "请弃置一张【闪】",
	["@@shuanglianjinktar"] = "请选择攻击范围内的一名其他角色",
	["@@shuanglianjinkres"] = "请打出一张【闪】，否则受到1点伤害",
	["@@shuanglianslashtar"] = "请选择一名【杀】的目标角色",
	["zaizhan"] = "再战",
	[":zaizhan"] = "<img src=\"image/mark/@zaizhan.png\"><b><font color='red'>限定技，</font></b>结束阶段开始时，你可以将你的武将牌翻面，令至多X名角色各摸一张牌并依次进行一个额外的回合。（X为你已损失的体力值）",
	["@zaizhan"] = "再战",
	["#zaizhan"] = "请选择至多X名角色（可选自己），X为你已损失的体力值",
	["~zaizhan"] = "选择目标角色→确定",
	["$shuanglian1"] = "僕は…戦争を凌ぐ平和を信じる! 平和を望む心を信じる!!",
	["$shuanglian2"] = "力を貸してくれ! サンドロック!",
	["$zaizhan1"] = "僕達の出番だ、サンドロック!",
	["$zaizhan2"] = "サンドロック、僕達の戦いを始めよう",
	
	["ALTRON"] = "双头龙改",
	["#ALTRON"] = "哪咤之魂",
	["~ALTRON"] = "哪咤，在暗夜中沉睡吧",
	["designer:ALTRON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ALTRON"] = "张五飞",
	["illustrator:ALTRON"] = "Sankies",
	["shuanglong"] = "双龙",
	["shuanglong1"] = "双龙",
	["shuanglong2"] = "双龙",
	["shuanglong-discard"] = "请弃置一张手牌以移动场上的装备",
	[":shuanglong"] = "出牌阶段限一次，你可以与一名其他角色拼点。若你赢，你与其距离始终为1；你无视其防具；你对其使用【杀】时无次数限制。直到回合结束。若你没赢，你可以弃置一张手牌，然后将场上的一张装备牌置于一名角色的装备区里。",
	["shuanglong_movefrom"] = "请选择一名拥有装备的角色",
	["shuanglong_moveto"] = "请选择一名获得【%src】的角色",
	["$shuanglong1"] = "我知道，你是邪恶！",
	["$shuanglong2"] = "正义……正义由我来决定！",
	["$shuanglong3"] = "我是……士兵们和人们的代言者！",
	["$shuanglong4"] = "我是要打倒你士兵，为了所有而战斗！",
	["$shuanglong5"] = "谁都不能……把我停止！",
	
	["#DX"] = "月色下的恶魔",
	["~DX"] = "だめぇ!",
	["designer:DX"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DX"] = "卡洛德·兰 & 蒂法·雅蒂尔",
	["illustrator:DX"] = "Sankies",
	["yueguang"] = "月光",
	[":yueguang"] = "<b><font color='blue'>锁定技，</font></b>准备阶段开始时，你须进行一次判定，若为<b>黑色</b>，你增加1点数，若为<font color='red'><b>红色</b></font>，你减少1点数。\
	\
	<b>{≥2}点数特效</b>：若你的点数<b>≥2</b>，你使用【杀】时可额外指定一名目标角色。",
	["weibo"] = "微波",
	[":weibo"] = "<b>[↓1]</b>出牌阶段，你可以花费<b>1</b>点数令你本回合使用的下一张【杀】造成的伤害+1。",
	["#weibo"] = "%from 发动了“%arg”，本回合使用的下一张【杀】造成的伤害+1。",
	["weixing"] = "卫星",
	[":weixing"] = "<b>[↓2]</b>出牌阶段，你可以花费<b>2</b>点数令你本回合使用的下一张【杀】不可被【闪】响应。",
	["#weixing"] = "%from 发动了“%arg”，本回合使用的下一张【杀】不可被【闪】响应。",
	["difa"] = "蒂法",
	[":difa"] = "你可以将对你造成伤害的牌置于你的武将牌上，称为<b>“蒂法”</b>；在你的判定牌生效前，你可以打出一张<b>“蒂法”</b>代替之。",
	["difa:damage"] = "你是否发动“蒂法”，将对你造成伤害的牌置于你的武将牌上？",
	["@difa-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
	["~difa"] = "选择一张“蒂法”→点击确定",
	["#dxpoint"] = "你使用【杀】时可额外指定一名目标角色。",
	["$yueguang1"] = "見えた!",
	["$yueguang2"] = "月が見えた!",
	["$yueguang3"] = "ええい、エネルギー消す?",
	["$yueguang4"] = "チャージに時間がかかるのかよ!",
	["$weibo1"] = "行けぇ!",
	["$weibo2"] = "死なせるもんかぁーっ!!",
	["$weibo3"] = "わかってたまるかぁー!!",
	["$weibo4"] = "世界を滅ぼされてたまるかぁー!!",
	["$weixing1"] = "俺もう、ニュータイプに…?",
	["$weixing2"] = "これがお前達の求めていた戦争か!?",
	["$weixing3"] = "たとえ地球がメチャメチャになっても、ティファの事守ってみせる",
	["$difa1"] = "ガロード…あなたに力を",
	["$difa2"] = "私達を守って",
	["$difa3"] = "あきらめないで、希望はあります",
	["$difa4"] = "ガロード…私を見て",
	
	["GINN"] = "米基尔基恩",
	["#GINN"] = "黄昏的魔弹",
	["~GINN"] = "可恶……脱出！",
	["designer:GINN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:GINN"] = "米基尔·艾曼",
	["illustrator:GINN"] = "Sankies",
	["laobing"] = "老兵",
	[":laobing"] = "当你进行判定前，你可以声明一种花色，若该次判定牌的花色与你声明的相同，你可以回复1点体力并重新进行判定；若花色不同，你获得判定牌。",
	["baopo"] = "爆破",
	[":baopo"] = "当你使用【杀】对目标角色造成一次伤害后，你可以弃置一张牌，然后弃置其装备区里的一张牌。",
	["$laobing1"] = "哼……很容易呢",
	["$laobing2"] = "好……前进！",
	["$baopo1"] = "来吧~击落吧！",
	["$baopo2"] = "将你击破吧！",
	
	["STRIKE"] = "突击",
	["#STRIKE"] = "觉醒的利刃",
	["huanzhuang"] = "换装",
	[":huanzhuang"] = "准备阶段开始时，你可以进行一次判定，你可以获得相应效果直到回合结束：\
<b><font color='black'>黑色</font></b>：你使用【杀】造成的伤害+1、被目标角色的【闪】抵消时，其可以弃置你一张手牌。\
<b><font color='red'>红色</font></b>：你的攻击范围+1。\
<b>不判定</b>：结束阶段开始时，你摸一张牌。",
	["huanzhuang:throw"] = "你是否弃置来源一张手牌？",
	["#huanzhuangn"] = "<b>空装：<font color='yellow'>结束阶段开始时，摸一张牌</font></b>",
	["#huanzhuangb"] = "<b>剑装：<font color='yellow'>使用【杀】造成的伤害+1、被目标角色的【闪】抵消时，其可以弃置你一张手牌</font></b>",
	["#huanzhuangr"] = "<b>炮装：<font color='yellow'>攻击范围+1</font></b>",
	--["xiangzhuan"] = "相转",
	--[":xiangzhuan"] = "当你受到黑色【杀】造成的伤害时，你可以弃置装备区里的一张牌防止此伤害。",
	--["#xiangzhuan"] = "%from 的“%arg”效果被触发，防止了<b><font color='black'>黑色</font></b>【杀】造成的伤害",
	["liren"] = "利刃",
	[":liren"] = "<img src=\"image/mark/@liren.png\"><b><font color='green'>觉醒技，</font></b>当你进入濒死状态时，你将体力回复至1点，将<b>“换装”</b>改为：\
<b><font color='black'>黑色</font></b>：你使用【杀】造成的伤害+1。\
<b><font color='red'>红色</font></b>：你的攻击范围+1；你于出牌阶段可额外使用一张【杀】。\
<b>不判定</b>：结束阶段开始时，你摸一张牌，并可使用一张【杀】。",
	["@liren"] = "利刃",
	["#huanzhuangexn"] = "<b>空装强化：<font color='yellow'>结束阶段开始时，摸一张牌，并可使用一张【杀】</font></b>",
	["#huanzhuangexb"] = "<b>剑装强化：<font color='yellow'>使用【杀】造成的伤害+1</font></b>",
	["#huanzhuangexr"] = "<b>炮装强化：<font color='yellow'>攻击范围+1；于出牌阶段可额外使用一张【杀】</font></b>",
	["~STRIKE"] = "軍人でもない僕が、\
勝てるわけがないんだ!",
	["designer:STRIKE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STRIKE"] = "基拉·大和",
	["illustrator:STRIKE"] = "Sankies",
	["$huanzhuang1"] = "パック、換装を!",
	["$huanzhuang2"] = "ストライカーパックを換装します!",
	["$huanzhuang3"] = "エールストライカーを!",
	["$huanzhuang4"] = "ランチャーストライカーを!",
	["$huanzhuang5"] = "ソードストライカーを!",
	["$liren1"] = "気持ちだけで、一体何が守れるって言うんだ!",
	["$liren2"] = "もう僕達を、放っておいてくれぇぇっ!",
	
	["AEGIS"] = "神盾",
	["#AEGIS"] = "闪光的一刻",
	["jiechi"] = "劫持",
	[":jiechi"] = "出牌阶段，你可以弃置一张手牌，然后弃置一名其他角色装备区里的一张牌。",
    ["juexin"] = "决心",
	["@juexin"] = "决心",
	[":juexin"] = "<img src=\"image/mark/@juexin.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以弃置所有手牌并指定一名其他角色，该角色于其回合开始前进行一次判定，若不为♠，该角色失去2点体力，然后你死亡。",
    ["~AEGIS"] = "……尼哥路！",
	["designer:AEGIS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:AEGIS"] = "亚斯兰·察拉",
	["illustrator:AEGIS"] = "wch5621628",
	["$jiechi1"] = "我说过我要向你开枪！",
	["$jiechi2"] = "向他开枪…这次一定要！",
	["$jiechi3"] = "向基拉开枪…这次一定要！",
	["$juexin1"] = "我…要向你开枪！",
	["$juexin2"] = "基拉！",
	--["$xiangzhuan3"] = "停下来！快停止这场战斗。",
	--["$xiangzhuan4"] = "无论如何都要动手的话，我就要把你杀了。",
	
	["BUSTER"] = "暴风",
	["#BUSTER"] = "决意的炮火",
	["shuangqiang"] = "双枪",
	[":shuangqiang"] = "出牌阶段，你可以将一张装备牌或锦囊牌当【杀】使用，对目标角色造成伤害后：若为前者，你弃置其装备区里的一张牌；后者，你弃置其一张手牌。",
    ["zuzhuang"] = "组装",
	[":zuzhuang"] = "出牌阶段，你可以将一张装备牌和一张锦囊牌当【杀】使用，对目标角色造成伤害后：你弃置其装备区里的所有牌，或你弃置其所有手牌。",
    ["zze"] = "弃置其装备区里的所有牌",
	["zzh"] = "弃置其所有手牌",
	["~BUSTER"] = "嘁…界限高度么？",
	["designer:BUSTER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BUSTER"] = "迪亚卡·艾尔斯曼",
	["illustrator:BUSTER"] = "wch5621628",
	["$shuangqiang1"] = "（口哨声）…又一个！",
	["$shuangqiang2"] = "GREAT！",
	["$zuzhuang1"] = "我不会让你在此再上前！",
	["$zuzhuang2"] = "快从这里离开，大天使号！",
	
	["DUEL_AS"] = "决斗AS",
	["#DUEL_AS"] = "战意的疤痕",
	["sijue"] = "死决",
	[":sijue"] = "出牌阶段，你可以将一张<b>黑色</b>基本牌当【决斗】使用，你以此法指定一名角色为目标后，该角色摸一张牌。",
    ["pojia"] = "破甲",
	["@pojia"] = "破甲",
	["pojiacard"] = "破甲",
	[":pojia"] = "<img src=\"image/mark/@pojia.png\"><b><font color='red'>限定技，</font></b>当你受到伤害后，你可以弃置你装备区里的所有牌（至少一张），视为对伤害来源使用两张【决斗】，并防止此【决斗】对你造成的伤害。",
    ["~DUEL_AS"] = "痛い…!痛い痛いぃ!!!",
	["designer:DUEL_AS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DUEL_AS"] = "伊撒古·玖尔",
	["illustrator:DUEL_AS"] = "wch5621628",
	["$sijue1"] = "この一撃、受けてみろ!",
	["$sijue2"] = "イザーク様をなめるなよ!",
	["$pojia1"] = "さぁ、見せてやるぞ! コーディネーターの力を!",
	["$pojia2"] = "もう好き勝手はさせんぞ! 貴様ら!",
	
	["BLITZ"] = "迅雷",
	["#BLITZ"] = "消失的高达",
	["yinxian"] = "隐现",
	["@yinxian"] = "海市蜃楼",
	[":yinxian"] = "当你使用或打出【闪】时，你可以进入<b>“海市蜃楼”</b>状态。当你使用【杀】结算后，解除<b>“海市蜃楼”</b>状态。\
<img src=\"image/mark/@yinxian.png\"><b>海市蜃楼</b>：你使用的【杀】具雷电伤害且不可被【闪】响应，其他角色与你的距离+1。",
    ["#EnterYinxian"] = "%from 进入“<b><font color='yellow'>海市蜃楼</font></b>”状态：\
<font color='yellow'>你使用的【杀】具雷电伤害且不可被【闪】响应，其他角色与你的距离+1</font>",
	["#RemoveYinxian"] = "%from 解除“<b><font color='yellow'>海市蜃楼</font></b>”状态",
	["zhuanjin"] = "转进",
	["@zhuanjin"] = "转进",
	["zhuanjincard"] = "转进",
	[":zhuanjin"] = "<img src=\"image/mark/@zhuanjin.png\"><b><font color='red'>限定技，</font></b>当一名其他角色处于濒死状态时，你可以令其体力回复至1点并摸X张牌（X为你与其已损失的体力值和），然后视为伤害来源对你使用一张【杀】。",
    ["~BLITZ"] = "母さん…僕の、ピアノ…",
	["designer:BLITZ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLITZ"] = "尼哥路·阿玛菲",
	["illustrator:BLITZ"] = "wch5621628",
	["BLITZ_Y"] = "迅雷",
	["#BLITZ_Y"] = "消失的高达",
	["~BLITZ_Y"] = "母さん…僕の、ピアノ…",
	["designer:BLITZ_Y"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLITZ_Y"] = "尼哥路·阿玛菲",
	["illustrator:BLITZ_Y"] = "wch5621628",
	["$yinxian1"] = "ミラージュコロイド!",
	["$yinxian2"] = "僕の姿が、見えないはずです!",
	["$yinxian3"] = "あなたには僕が見えないはずだ!",
	["$yinxian4"] = "ミラージュコロイドを解きます!",
	["$yinxian5"] = "もう隠れる必要はありません!",
	["$yinxian6"] = "ミラージュコロイドを使った高速戦闘…",
	["$zhuanjin1"] = "みんな下がって!ここは僕が!",
	["$zhuanjin2"] = "アスラン下がって!",
	
	["FREEDOM"] = "自由",
	["#FREEDOM"] = "自由之翼",
	["helie"] = "核裂",
	[":helie"] = "出牌阶段开始和结束时，你可以弃置所有手牌，然后摸等同于你体力上限的牌。",
	["jiaoxie"] = "缴械",
	[":jiaoxie"] = "当你使一名其他角色进入濒死状态、或一名其他角色使你进入濒死状态时，你可以令其失去一项技能（不可为限定技或觉醒技）。",
	["zhongzi"] = "种子",
	["@seed"] = "SEED",
	[":zhongzi"] = "<img src=\"image/mark/@seed.png\"><b><font color='green'>觉醒技，</font></b>当你处于濒死状态求桃完毕后，你将体力回复至1点，失去技能<b>“缴械”</b>并获得技能<b>“齐射”</b>（出牌阶段，你可以将所有手牌（至少一张）当火【杀】使用，此【杀】可指定至多X个目标且无距离限制（X为手牌数））。",
	["qishe"] = "齐射",
	[":qishe"] = "出牌阶段，你可以将所有手牌（至少一张）当火【杀】使用，此【杀】可指定至多X个目标且无距离限制（X为手牌数）。",
	["~FREEDOM"] = "僕のせいで、僕のせいで!",
	["designer:FREEDOM"] = "wch5621628 & Sankies & NOS7IM & lulux",
	["cv:FREEDOM"] = "基拉·大和",
	["illustrator:FREEDOM"] = "Sankies",
	["$helie1"] = "想いだけでも、力だけでも…!",
	["$helie2"] = "僕には…やれるだけの力がある!",
	["$jiaoxie1"] = "そんなに死にたいのか!",
	["$jiaoxie2"] = "もうやめるんだー!!",
	["$jiaoxie3"] = "それでも…守りたい世界があるんだ!",
	["$zhongzi1"] = "（SEED）",
	["$zhongzi2"] = "それでも、守りたいものがあるんだ!",
	["$qishe1"] = "僕は…それでも僕は!",
	["$qishe2"] = "これ以上、僕にさせないでくれ!",
	
	["shouwang"] = "守望",
	[":shouwang"] = "当你需要使用一张【桃】时，你可以减1点体力上限，视为你使用之。",
	["zhongzij"] = "种子",
	[":zhongzij"] = "<img src=\"image/mark/@seedj.png\"><b><font color='green'>觉醒技，</font></b>当你的体力上限为1时，你将体力上限增加至3点，失去技能<b>“守望”</b>并获得技能<b>“挥舞”</b>（出牌阶段限一次，当你使用【杀】结算后，你可以弃置所有手牌（至少一张）：<b>黑色</b>【杀】：弃置目标角色装备区里的一张牌；<b><font color='red'>红色</font></b>【杀】：额外结算一次。）",
	["@seedj"] = "SEED",
	["huiwu"] = "挥舞",
	[":huiwu"] = "出牌阶段限一次，当你使用【杀】结算后，你可以弃置所有手牌（至少一张）：<b>黑色</b>【杀】：弃置目标角色装备区里的一张牌；<b><font color='red'>红色</font></b>【杀】：额外结算一次。",
	["~JUSTICE"] = "就算是这样，也不会挽回些什么！",
	["JUSTICE"] = "正义",
	["#JUSTICE"] = "正义之剑",
	["designer:JUSTICE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:JUSTICE"] = "亚斯兰·察拉",
	["illustrator:JUSTICE"] = "Sankies",
	["$helie3"] = "军方对这次战斗并没有下达任何命令。",
	["$helie4"] = "这次介入…是我个人的意思。",
	["$shouwang1"] = "在这种地方，怎么可以让你死掉!",
	["$shouwang2"] = "现在请尽快进行维修。",
	["$zhongzij"] = "你们真的要破坏所有东西吗?!",
	["$huiwu1"] = "决一胜负吧!",
	["$huiwu2"] = "你们倒是怎么了?!到底为了什么而战斗?!",
	
	["wenshen"] = "瘟神",
	[":wenshen"] = "你可以将一张装备牌当【酒】或【杀】使用。",
	["@wenshen"] = "请将一张装备牌当【%src】使用",
	["~wenshen"] = "选择一张装备牌→（选择目标）→确定",
	["jinduan"] = "禁断",
	[":jinduan"] = "当你成为其他角色使用的<b><font color='red'>红色</font></b>【杀】的目标时，你可以转移给另一名其他角色。",
	["@jinduan"] = "请选择另一名其他角色，代替你成为<font color='red'>红色</font>【杀】的目标",
	["liesha"] = "猎杀",
	[":liesha"] = "当你使用一张<b>黑色</b>【杀】时，你可以摸一张牌。",
	["~CFR"] = "あーあ、やっちゃったー…",
	["CFR"] = "瘟神禁断猎杀",
	["#CFR"] = "恶之三兵器",
	["designer:CFR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CFR"] = "奥尔加·萨布纳克&夏尼·安德拉斯&古朗度·布路",
	["illustrator:CFR"] = "Sankies",
	["$wenshen1"] = "うざいんだよ!",
	["$wenshen2"] = "オラ、いくぜ!",
	["$jinduan1"] = "お前、お前、お前ェッ!!",
	["$jinduan2"] = "ばいばーい",
	["$liesha1"] = "そりゃー、滅殺!!",
	["$liesha2"] = "でりゃー、必殺!!",
	
	["longqi"] = "龙骑",
	["@longqi"] = "请观看一名其他角色的手牌并弃置其中一张<br>【闪】点数=%src<br>弃置点数%src的牌：对其造成1点伤害<br>弃置点数差为1的牌：重复此流程",
	[":longqi"] = "当你使用或打出一张【闪】时，你可以：观看一名其他角色的手牌并弃置其中一张，若此牌与【闪】的点数相同，你对其造成1点伤害；若点数差为1，你可以重复此流程。",
    ["chuangshi"] = "创世",
	[":chuangshi"] = "<b><font color='blue'>锁定技，</font></b>当你受到其他角色造成的伤害时，若伤害不小于你的体力值，你减1点体力上限，然后对伤害来源造成等量伤害。",
	["~PROVIDENCE"] = "扉がっ…! 最後の扉が!",
	["PROVIDENCE"] = "天意",
	["#PROVIDENCE"] = "终末之光",
	["designer:PROVIDENCE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:PROVIDENCE"] = "劳·鲁·克鲁泽",
	["illustrator:PROVIDENCE"] = "wch5621628",
	["$helie5"] = "存分に殺し合うがいい!",
	["$helie6"] = "私を止められはせぬ!!",
	["$longqi1"] = "これが人の夢!人の望み!!人の業!!!",
	["$longqi2"] = "他者より強く!他者より先へ!!他者より上へ!!!",
	["$chuangshi1"] = "自ら育てた闇に喰われて、人は滅ぶとな!",
	["$chuangshi2"] = "もう誰にも止められはしないさ! この宇宙を覆う、憎しみの渦はなぁ!!",
	
	["CAG"] = "混沌深渊大地",
	["#CAG"] = "妖气的微笑",
	["~CAG"] = "あぁ…嫌…死ぬの…嫌ぁーっ!",
	["designer:CAG"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CAG"] = "史汀·奥古利&奥尔·尼达&史汀娜·露茜",
	["illustrator:CAG"] = "wch5621628",
	["hundun"] = "混沌",
	[":hundun"] = "当你的武将牌翻至正面朝上时，你可以视为对一至两名其他角色使用一张【杀】。",
	["@hundun"] = "你想发动技能“混沌”视为对一至两名其他角色使用一张【杀】吗？",
	["~hundun"] = "选择角色→确定",
	["hunduncard"] = "混沌",
	["shenyuan"] = "深渊",
	[":shenyuan"] = "当你受到<b><font color='red'>红色</font></b>牌造成的伤害时，你可以弃置一张手牌并将武将牌翻面，若如此做，此伤害-1。",
	["@shenyuan"] = "你想发动技能“深渊”弃置一张手牌并翻面，令伤害-1吗？",
	["dadi"] = "大地",
	[":dadi"] = "你可以将最后一张手牌当【杀】使用或打出，若如此做，你将武将牌翻面并回复1点体力，此【杀】不可被【闪】响应。",
	["$hundun1"] = "これで決めるぜ!",
	["$hundun2"] = "ははははっ…最高だぜこれは!",
	["$shenyuan1"] = "あはははっ…ごめんね，強いくてさ!",
	["$shenyuan2"] = "待ってました!",
	["$dadi1"] = "近寄るなーっ!",
	["$dadi2"] = "私は…私はぁーっ!",
	
	["daohe"] = "氘核",
	[":daohe"] = "准备阶段开始时，你可以获得以下一项效果直到回合结束：\
<img src=\"image/mark/@meiying.png\">：攻击范围+1；当你使用【杀】后没有造成伤害，你可以额外使用一张【杀】。\
<img src=\"image/mark/@jianyingg.png\">：攻击范围+1；当你使用【杀】后没有造成伤害，你可以摸一张牌。\
<img src=\"image/mark/@jiying.png\">：攻击范围+2；当你使用【杀】对一名角色造成伤害时，若伤害不小于其体力值，你可以令此伤害+1。",
	["meiying"] = "魅影",
	["@meiying"] = "魅影",
	[":meiying"] = "攻击范围+1；当你使用【杀】后没有造成伤害，你可以额外使用一张【杀】。",
	["jianyingg"] = "剑影",
	["@jianyingg"] = "剑影",
	[":jianyingg"] = "攻击范围+1；当你使用【杀】后没有造成伤害，你可以摸一张牌。",
	["jiying"] = "疾影",
	["@jiying"] = "疾影",
	[":jiying"] = "攻击范围+2；当你使用【杀】对一名角色造成伤害时，若伤害不小于其体力值，你可以令此伤害+1。",
	["#daohe"] = "%from 获得效果“%arg”：%arg2",
	["emeng"] = "恶梦",
	["@emeng"] = "恶梦",
	[":emeng"] = "<img src=\"image/mark/@emeng.png\"><b><font color='green'>觉醒技，</font></b>当你受到攻击范围外的角色使用【杀】造成的伤害后，将技能<b>“氘核”</b>改为<b>“你可以获得以下两项效果”</b>。",
	["~IMPULSE"] = "いくら綺麗に花が咲いても…\
	人はまた吹き飛ばす…",
	["IMPULSE"] = "脉冲",
	["#IMPULSE"] = "新生之鸟",
	["designer:IMPULSE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IMPULSE"] = "真·飞鸟",
	["illustrator:IMPULSE"] = "Sankies",
	["$daohe1"] = "また戦争がしたいのか! アンタ達は!!",
	["$daohe2"] = "どんな敵とでも、戦ってやるさ!",
	["$daohe3"] = "なんでそんなに殺したいんだ!",
	["$daohe4"] = "アンタは俺が討つんだ…今日、ここで！",
	["$emeng1"] = "（SEED）",
	["$emeng2"] = "こんな事で…こんな事で俺はぁ!!",
	["$emeng3"] = "いっつもそうやって…やれると思うなアアアァァァ！",
	["$meiying"] = "ちょこまかとぉ!",
	["$jianyingg"] = "大した腕も無いくせに…",
	["$jiying"] = "弱いからそういう事を!",
	
	["FREEDOM_D"] = "自由-乱战",
	["#FREEDOM_D"] = "甦醒之翼",
	["~FREEDOM_D"] = "僕のせいで、僕のせいで!",
	["designer:FREEDOM_D"] = "wch5621628 & Sankies & NOS7IM",
	["cv:FREEDOM_D"] = "基拉·大和",
	["illustrator:FREEDOM_D"] = "Sankies",
	["xinnian"] = "信念",
	[":xinnian"] = "<b><font color='blue'>锁定技，</font></b>你的回合内，所有其他角色的非觉醒技无效；当你受到伤害时，你失去1点体力並防止此伤害。",
	["luanzhan"] = "乱战",
	[":luanzhan"] = "<img src=\"image/mark/@luanzhan.png\"><b><font color='green'>觉醒技，</font></b>当其他角色处于濒死状态时，其体力回复至1点，你减1点体力上限并获得以下效果：X小于等于3，你拥有技能<b>“挥舞”</b>，X大于等于4，你拥有技能<b>“齐射”</b>。（X为存活角色数）",
	["@luanzhan"] = "乱战",
	["$xinnian1"] = "討ちたくない…討たせないで…",
	["$xinnian2"] = "残念だけど、もうどうしようもないみたいだね",
	["$xinnian3"] = "亚斯兰：退下，基拉！你的力量只是让战场更加混乱而已！基拉：虽然明白，虽然也明白你说的，但是，卡嘉莉现在在哭！",
	["$luanzhan"] = "僕は…君を討つ!",
	
	["SAVIOUR"] = "救世主",
	["#SAVIOUR"] = "忠诚的回归",
	["~SAVIOUR"] = "就算是这样，也不会挽回些什么！",
	["designer:SAVIOUR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SAVIOUR"] = "亚斯兰·察拉",
	["illustrator:SAVIOUR"] = "wch5621628",
	["shanzhuan"] = "闪转",
	[":shanzhuan"] = "当你使用或打出一张【闪】时，你可以摸一张牌并展示之，若为【杀】，你可以使用之，若为<font color='red'><b>红色</b></font>，你可额外指定一个目标。",
	["zhongcheng"] = "忠诚",
	[":zhongcheng"] = "当你受到伤害后，你可以弃置伤害来源装备区里的所有牌。",
	["$shanzhuan1"] = "不要妨碍我!",
	["$shanzhuan2"] = "就算是我们也明白的，在战斗中有不可不保护的东西!",
	["$zhongcheng1"] = "快停下来。",
	["$zhongcheng2"] = "都说了要你停下来。",
	
	["DESTROY"] = "毁灭",
	["#DESTROY"] = "未明之夜",
	["~DESTROY"] = "嫌ぁ!死ぬのは嫌ッ!!",
	["designer:DESTROY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DESTROY"] = "史汀娜·露茜",
	["illustrator:DESTROY"] = "wch5621628",
	["huohai"] = "火海",
	[":huohai"] = "<b><font color='blue'>锁定技，</font></b>准备阶段开始时，视为你对所有没有手牌的其他角色使用一张火【杀】。",
	["tiebi"] = "铁壁",
	[":tiebi"] = "<b><font color='blue'>锁定技，</font></b>你距离1以外的角色使用的<b><font color='red'>红色</font></b>【杀】或火【杀】对你无效。",
	["kongju"] = "恐惧",
	[":kongju"] = "<img src=\"image/mark/@kongju.png\"><b><font color='green'>觉醒技，</font></b>当一名其他角色死亡时，所有角色须弃置两张牌（不足则全弃），你减1点体力上限，失去技能<b>“铁壁”</b>，因<b>“火海”</b>造成的伤害+1。",
	["@kongju"] = "恐惧",
	["$huohai"] = "やっつけなきゃ…怖いものは全部!",
	["$tiebi"] = "こっちに来ないで!",
	["$kongju"] = "みんな沈め!!",
	
	["AKATSUKI"] = "晓",
	["#AKATSUKI"] = "黄金的意志",
	["~AKATSUKI"] = "嘻嘻…果然我是…\
	化不可能为可能的…",
	["designer:AKATSUKI"] = "wch5621628 & Sankies & NOS7IM",
	["cv:AKATSUKI"] = "穆·拉·弗拉加",
	["illustrator:AKATSUKI"] = "wch5621628",
	["bachi"] = "八呎",
	[":bachi"] = "当你成为<b><font color='red'>红色</font></b>【杀】的目标时，你可以弃置一张牌并转移给一至两名其他角色。",
	["@bachi"] = "%src 对你使用【杀】，你可以弃置一张牌发动“八呎”",
	["~bachi"] = "选择一张牌→指定一至两名其他角色→确定",
	["hubi"] = "护壁",
	[":hubi"] = "出牌阶段限一次，你可以将一张【闪】置于一名角色的武将牌上，称为<b>“护壁”</b>，然后你摸一张牌，其可以将<b>“护壁”</b>使用或打出。准备阶段开始时，你回收<b>“护壁”</b>。",
	["&hubi"] = "护壁",
	["$bachi1"] = "买多买多!",
	["$bachi2"] = "噢哩呀!",
	["$hubi1"] = "我是化不可能为可能的男人。",
	["$hubi2"] = "回来之前别被击沉唷!",
	
	["SF"] = "突击自由",
	["#SF"] = "黄金之翼",
	["~SF"] = "いくら吹き飛ばされても、\
	僕らはまた、花を植えるよ…きっと",
	["designer:SF"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SF"] = "基拉·大和",
	["illustrator:SF"] = "wch5621628",
	["daijin"] = "殆烬",
	[":daijin"] = "出牌阶段限一次，你可以将两张手牌当火【杀】使用，此【杀】可指定至多等量目标且无距离限制，对目标角色造成伤害后，令其一项非觉醒技无效，直到其下回合结束。",
	["$DaijinNullify"] = "%to 的技能“%arg”由于“<font color=\"yellow\"><b>殆烬</b></font>”效果无效直到其下回合结束",
	["$DaijinReset"] = "%from 回合结束，“%arg”恢复有效",
	["zhongzisf"] = "种子",
	[":zhongzisf"] = "<img src=\"image/mark/@seedsf.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时或成为【杀】的目标时，若你没有手牌，你减1点体力上限并摸两张牌，将<b>“殆烬”</b>描述中的<b>“两张”</b>改为<b>“至少两张”</b>，并获得技能<b>“超骑”</b>（当你成为【杀】的目标后，你可以：摸一张牌并展示之，若为红桃，你对其造成1点伤害；若为方块，你弃置来源一张牌，重复此流程）。",
	["@seedsf"] = "SEED",
	["chaoqi"] = "超骑",
	[":chaoqi"] = "当你成为【杀】的目标后，你可以：摸一张牌并展示之，若为红桃，你对其造成1点伤害；若为方块，你弃置来源一张牌，重复此流程。",
	["$daijin1"] = "未来を作るのは、運命じゃない…",
	["$daijin2"] = "どんなに苦しくても、変わらない世界は嫌なんだ!",
	["$zhongzisf1"] = "もう、終わらせよう…こんな事は!",
	["$zhongzisf2"] = "覚悟はある!僕は戦う!",
	["$chaoqi1"] = "当たれえええ!",
	["$chaoqi2"] = "いっけえええ!",
	
	["IJ"] = "无限正义",
	["#IJ"] = "白银之剑",
	["~IJ"] = "これでは、何も変えられない…",
	["designer:IJ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IJ"] = "亚斯兰·察拉",
	["illustrator:IJ"] = "wch5621628",
	["hanwei"] = "捍卫",
	[":hanwei"] = "当你使用【杀】指定一个目标后，若你的装备区有：<b>武器</b>或<b>防具</b>，你可弃置其装备区里的一张牌；<b>坐骑</b>，你可令其使用两张【闪】抵消。",
	["hanwei:throw"] = "你想发动技能“捍卫”弃置 %src 装备区里的一张牌吗？",
	["hanwei:jink"] = "你想发动技能“捍卫”令 %src 使用两张【闪】抵消此【杀】吗？",
	["#hanwei"] = "%to 须使用两张【闪】抵消此【杀】",
	["zhongziij"] = "种子",
	[":zhongziij"] = "<img src=\"image/mark/@seedij.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时或成为【杀】的目标时，若你已受伤且装备区有牌，你减1点体力上限，并获得技能<b>“狮鹫”</b>（当你成为【杀】的目标后，你可以将一张与装备区中相同花色的手牌当【杀】使用，若如此做，终止其【杀】结算）。",
	["@seedij"] = "SEED",
	["shijiu"] = "狮鹫",
	[":shijiu"] = "当你成为【杀】的目标后，你可以将一张与装备区中相同花色的手牌当【杀】使用，若如此做，终止其【杀】结算。",
	["@shijiu"] = "你想发动技能“狮鹫”吗？",
	["~shijiu"] = "将一张与装备区中相同花色的手牌当【杀】使用，若如此做，终止其【杀】结算",
	["$hanwei1"] = "邪魔をするな!君を討ちたくなどない!",
	["$hanwei2"] = "お前も、過去に囚われたまま戦うのはやめろ!!",
	["$hanwei3"] = "未来まで殺す気か?",
	["$zhongziij1"] = "これで終わらせる!",
	["$zhongziij2"] = "何としても、墜とすっ!",
	["$shijiu1"] = "この、馬鹿野郎ォォッ!",
	["$shijiu2"] = "お前が欲しかったのは、本当にそんな力か!?",
	
	["DESTINY"] = "命运",
	["#DESTINY"] = "明日的业火",
	["~DESTINY"] = "あんたは一体、何なんだぁ!?",
	["designer:DESTINY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DESTINY"] = "真·飞鸟",
	["illustrator:DESTINY"] = "wch5621628",
	["feiniao"] = "飞鸟",
	[":feiniao"] = "<b><font color='blue'>锁定技，</font></b>根据你的攻击范围，你拥有以下效果：\
1：你使用的普通【杀】视为雷【杀】；\
2：你使用的【杀】无视目标角色的防具；\
3：你使用的【杀】被【闪】抵消后，回收之；\
≥4：你使用【杀】造成的伤害+1。",
	["feiniaocard"] = "飞鸟",
	["#IgnoreArmor"] = "%from 使用的 %card 无视防具",
	["huanyi"] = "幻翼",
	[":huanyi"] = "<img src=\"image/mark/@huanyi.png\">准备阶段开始时，你可以进行一次判定，若为<b><font color='red'>红色</font></b>，视为你使用一张【酒】，且可将一张<b><font color='red'>红色</font></b>手牌当【闪】使用或打出，直到你的下回合开始前。",
	["@huanyi"] = "幻翼",
	["nuhuo"] = "怒火",
	[":nuhuo"] = "<img src=\"image/mark/@nuhuo.png\"><b><font color='green'>觉醒技，</font></b>当你使用的【杀】第三次被【闪】抵消后，你减1点体力上限，获得效果<img src=\"image/mark/@jianyingg.png\"><font color='red'>（攻击范围+1；当你使用【杀】后没有造成伤害，你可以摸一张牌）</font>，且你下一次造成的伤害+1。",
	["@nuhuo"] = "怒火",
	["$feiniao1"] = "やめろぉ!",
	["$feiniao2"] = "やってやる…やってやるさ!",
	["$feiniao3"] = "お前たちなんかがいるから、世界はぁ!",
	["$feiniao4"] = "あんたらの理想ってヤツで戦争を止められるのか!?",
	["$huanyi1"] = "ルナも艦もプラントも、みんな俺が守る!",
	["$huanyi2"] = "あんたが正しいっていうのなら! 俺に勝ってみせろっ!!",
	["$nuhuo1"] = "あんた達はぁぁッ!!",
	["$nuhuo2"] = "お前ら…ふざけるなぁぁっ!",
	
	["LEGEND"] = "传说",
	["#LEGEND"] = "最后之力",
	["~LEGEND"] = "啊啊啊————!!!",
	["designer:LEGEND"] = "wch5621628 & Sankies & NOS7IM",
	["cv:LEGEND"] = "雷·札·巴雷尔",
	["illustrator:LEGEND"] = "wch5621628",
	["jiqi"] = "极骑",
	[":jiqi"] = "当你使用或打出一张有点数的【闪】时，你可以亮出牌堆顶的2X张牌，若有与【闪】点数差为1的牌，你获得之，若有与【闪】点数相同的牌，你可以令至多X名其他角色选择一项：1.打出一张【闪】；2.受到你造成的1点伤害。（X为你的体力值）",
	["@jiqi"] = "你可以令至多X名其他角色选择一项：1.打出一张【闪】；2.受到你造成的1点伤害。（X为你的体力值）",
	["~jiqi"] = "选择角色→确定",
	["kelong"] = "克隆",
	[":kelong"] = "你可以将对你造成伤害的牌置于你的武将牌上，称为<b>“克隆”</b>；你可以将一张<b>“克隆”</b>当【闪】使用或打出。",
	["$jiqi1"] = "敌人…由我来击落。",
	["$jiqi2"] = "这不是闹玩的，快消失吧。",
	["$kelong1"] = "向不断战斗的历史休止符开枪，我……",
	["$kelong2"] = "怎能让你们为所欲为！",	
	
	["SP_DESTINY"] = "SP命运",
	["#SP_DESTINY"] = "恶魔的契约",
	["~SP_DESTINY"] = "",
	["designer:SP_DESTINY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SP_DESTINY"] = "真·飞鸟",
	["illustrator:SP_DESTINY"] = "Sankies",
	["shanshuo"] = "闪烁",
	[":shanshuo"] = "出牌阶段结束时，你可以将任意数量的牌至于武将牌上，称为<b>“翼”</b>；你可以在合理的时机使用或打出<b>“翼”</b>；每有一张<b>“翼”</b>，你计算与其他角色的距离便-1。",
	["&yi"] = "翼",
	["@shanshuo"] = "你想发动技能“%src”吗?",
	["~shanshuo"] = "请选择至少一张牌→确定",
	["xingzhui"] = "星坠",
	[":xingzhui"] = "一名角色的准备阶段开始时，你可以将所有<b>“翼”</b>（至少一张）置入弃牌堆，若颜色相同，视为你使用了一张基本牌，若颜色不同，视为你使用了一张非延时类锦囊牌。",
	["@xingzhui"] = "请选择【%src】的目标",
	["~xingzhui"] = "选择目标→确定",
	
	["STRIKE_NOIR"] = "漆黑突击",
	["#STRIKE_NOIR"] = "幻痛之袭",
	["~STRIKE_NOIR"] = "作戦続行不可能…",
	["designer:STRIKE_NOIR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STRIKE_NOIR"] = "史威恩·卡尔·巴亚",
	["illustrator:STRIKE_NOIR"] = "wch5621628",
	["huantong"] = "幻痛",
	[":huantong"] = "当你需要使用或打出【闪】时，你可以将一张<b>黑色</b>牌当【铁索连环】使用，若如此做，视为你使用或打出【闪】。处于<b>“连环状态”</b>的其他角色视为在你的攻击范围内。",
	["@huantong"] = "你可以将一张黑色牌当【铁索连环】使用，视为你使用或打出【闪】",
	["~huantong"] = "选择一张黑色牌→选择目标→确定",
	["huantongcard"] = "幻痛",
	["jianmie"] = "歼灭",
	[":jianmie"] = "出牌阶段，你可以将一张普通【杀】当火【杀】使用且可额外选择一名处于<b>“连环状态”</b>的目标角色。",
	["$huantong1"] = "隙がある",
	["$huantong2"] = "動きが読める",
	["$jianmie1"] = "敵を…殲滅する…",
	["$jianmie2"] = "今終わる!",
	["$jianmie3"] = "敵対するものは死ぬ",
	
	["EXIA_R"] = "艾斯亚R",
	["#EXIA_R"] = "能天使",
	["liejian"] = "裂剑",
	[":liejian"] = "<b><font color='blue'>锁定技，</font></b>当你使用各花色的【杀】指定一个目标后：\
	黑桃：弃置你的武器。\
	红桃：弃置你的防具。\
	梅花：弃置其一张手牌。\
	方块：其须使用两张【闪】抵消。",
	["duzhan"] = "独战",
	[":duzhan"] = "若你在所有其他角色攻击范围内，你可以将一张手牌当【杀】、装备区里的一张牌当【闪】使用或打出。",
	["~EXIA_R"] = "エクシアに乗っていながら…俺は…!",
	["designer:EXIA_R"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EXIA_R"] = "刹那·F·塞尔",
	["illustrator:EXIA_R"] = "Sankies",
	["$liejian1"] = "エクシア、紛争地域を確認。武力介入に移行する",
	["$liejian2"] = "貴様の歪み…俺が断つ!",
	["$liejian3"] = "その歪みを…破壊する…!",
	["$duzhan1"] = "俺が…ガンダムだ!",
	["$duzhan2"] = "俺のガンダムは!",
	["$duzhan3"] = "俺は…託されたんだ!",
	
	["REBORNS_CANNON"] = "再生加农",
	["#REBORNS_CANNON"] = "原始的变革者",
	["~REBORNS_CANNON"] = "この、人間風情が!",
	["designer:REBORNS_CANNON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:REBORNS_CANNON"] = "利邦兹·阿尔马克",
	["illustrator:REBORNS_CANNON"] = "NOS7IM",
	["jidong"] = "机动",
	[":jidong"] = "出牌阶段限一次，你可以弃置一张牌，将武将牌更换为<b>“再生加农”</b>或<b>“再生高达”</b>。",
	["fengong"] = "奋攻",
	[":fengong"] = "出牌阶段限一次，你可以弃置一张属性【杀】，令一至两名其他角色：打出一张【闪】，否则你对其造成1点伤害。",
	["@fengong"] = "请打出一张【闪】，否则受到1点伤害",
	["$jidong1"] = "リボーンズキャノン!",
	["$jidong2"] = "かわしても僕は構わないんだよ",
	["$jidong3"] = "リボーンズガンダム!",
	["$jidong4"] = "そうとも。この機体こそ、人類を導くガンダムだ!",
	["$fengong1"] = "新しい創造主さ!",
	["$fengong2"] = "この距離は届く!",
	["$fengong3"] = "さようならだ",
	
	["REBORNS_GUNDAM"] = "再生高达",
	["#REBORNS_GUNDAM"] = "变革者的再生",
	["~REBORNS_GUNDAM"] = "この、人間風情が!",
	["designer:REBORNS_GUNDAM"] = "wch5621628 & Sankies & NOS7IM",
	["cv:REBORNS_GUNDAM"] = "利邦兹·阿尔马克",
	["illustrator:REBORNS_GUNDAM"] = "NOS7IM",
	["zaisheng"] = "再生",
	[":zaisheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后重复亮出牌堆顶的牌，若为基本牌，你获得之，直到你以此法获得X张牌（X为你以此法弃置的牌数）。",
	["reborns_transam"] = "TRANS-AM",
	[":reborns_transam"] = "<img src=\"image/mark/@reborns_transam.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以令你于本回合发动<b>“机动”</b>或<b>“奋攻”</b>时无次数限制，且发动<b>“机动”</b>时不需弃牌。",
	["@reborns_transam"] = "TRANS-AM",
	["$zaisheng1"] = "さぁ始めよう。来たるべき未来のために",
	["$zaisheng2"] = "ボクを叩けなかった君達の負けだよ",
	["$zaisheng3"] = "救世主なんだよ僕は",
	["$reborns_transam"] = "トランザム!",
	
	["HARUTE"] = "哈鲁特",
	["#HARUTE"] = "妖天使",
	["~HARUTE"] = "あぁ!アレルヤァ!!マ…マリー!大丈夫か?",
	["designer:HARUTE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:HARUTE"] = "阿路耶/哈路耶·哈帝姆&索玛·皮里斯",
	["illustrator:HARUTE"] = "Sankies",
	["feijian"] = "飞剪",
	[":feijian"] = "游戏开始时，你将牌堆顶的四张牌置于你的武将牌上，称为<b>“剪”</b>。你可以将一张与<b>“剪”</b>相同花色的牌当【杀】使用或打出，你以此法使用【杀】时可额外指定一名目标角色。",
	["jian"] = "剪",
	["liuyan"] = "六眼",
	[":liuyan"] = "<img src=\"image/mark/@MARUT.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时，若你的体力为2或更少，你减1点体力上限，摸六张牌，并获得以下效果：你可以将一张<b>“剪”</b>当【桃】使用。",
	["@MARUT"] = "MARUT",
	["harute_transam"] = "TRANS-AM",
	[":harute_transam"] = "<img src=\"image/mark/@harute_transam.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以令你于此阶段：可以额外使用两张【杀】且无距离限制。若如此做，你跳过下一个摸牌阶段。",
	["@harute_transam"] = "TRANS-AM",
	["$feijian1"] = "GNシザービット展開!",
	["$feijian2"] = "断ち切れ!シザービット!",
	["$feijian3"] = "いけよシザービットォ!",
	["$feijian4"] = "GNシザービット展開!",
	["$feijian5"] = "GNシザービット!",
	["$liuyan1"] = "いいか?反射と思考の融合だ!わかってる!了解!いくぜぇえ!!",
	["$liuyan2"] = "これが!超兵の力だァー!!違う!未来を切り開く力だ!!",
	["$liuyan3"] = "もう遅え！それでも行くさ！",
	["$liuyan4"] = "理屈なんかどうでもいい!殺るだけだぁ!!",
	["$liuyan5"] = "てめぇの行為は偽善だ!それでも善だ!!僕はもう、命を見捨てたりしない!!",
	["$harute_transam1"] = "トランザム!",
	["$harute_transam2"] = "トランザム!",
	["$harute_transam3"] = "トランザム!!",
	
	["ELSQ"] = "ELS Q",
	["#ELSQ"] = "和平之桥",
	["~ELSQ"] = "何故…分かり合えないん…俺達は",
	["designer:ELSQ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ELSQ"] = "刹那·F·塞尔",
	["illustrator:ELSQ"] = "Sankies",
	["ronghe"] = "融合",
	[":ronghe"] = "出牌阶段限一次，你可以将武将牌翻面，指定一名体力比你多且有手牌的角色，其手牌对你可见，且你可以将其手牌使用或打出，直到你的下回合开始前。",
	["&ronghe"] = "融合",
	["lijie"] = "理解",
	[":lijie"] = "当你受到其他角色造成的伤害后，你可以弃置其的一张手牌，若为<font color='red'>♥</font>，你与其各回复1点体力。",
	["$ronghe1"] = "これが…俺の望んだガンダム…!",
	["$ronghe2"] = "示さなければならない…世界はこんなにも、簡単だということを",
	["$lijie1"] = "言われるまでもない。絶対に生きて帰る。それが俺の戦いだ…!",
	["$lijie2"] = "お前達のやろうとしていることは理解できる。だが、それは対話ではない…!",
	
	["#00QFS"] = "全刃式",
	["~00QFS"] = "何故…分かり合えないん…俺達は",
	["designer:00QFS"] = "高达杀制作组",
	["cv:00QFS"] = "刹那·F·塞尔",
	["illustrator:00QFS"] = "Sankies",
	["quanren"] = "全刃",
	[":quanren"] = "出牌阶段开始时，若你没有明置的手牌，你可以明置当前所有手牌。你可以将一张明置的手牌当【杀】使用或打出。",
	["quanrenshow"] = "明置牌",
	["quanrenpile"] = "选择明置的手牌",
	["quanrenhand"] = "选择其他的手牌",
	["yueqian"] = "跃迁",
	[":yueqian"] = "<img src=\"image/mark/@yueqian.png\">每名角色的回合內限一次，当你对攻击范围内的角色造成伤害后，你可以摸一张牌并明置之，若为<font color='red'><b>红色</b></font>，你下一次需要使用或打出【闪】时，视为你使用或打出一张【闪】。",
	["@yueqian"] = "跃迁",
	["#yueqian"] = "%from 下一次需要使用或打出【闪】时，视为其使用或打出一张【闪】",
	["fs_transam"] = "TRANS-AM",
	[":fs_transam"] = "<img src=\"image/mark/@fs_transam.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以暗置所有明置的手牌（至少一张），每暗置一张，此阶段你的攻击范围和【杀】的额外使用次数便均+1，下回合內不可发动技能<b>“全刃”</b>。",
	["@fs_transam"] = "TRANS-AM",
	["$quanren1"] = "突入する!",
	["$quanren2"] = "俺達は、分かり合えるはずだ!",
	["$yueqian1"] = "刹那・F・セイエイ…今こそ、未来をこの手に掴む!",
	["$yueqian2"] = "このまま対話を実現させる",
	["$fs_transam"] = "トランザム!",
		
	["SBS"] = "星创突击",
	["#SBS"] = "星之创战者",
	["~SBS"] = "",
	["designer:SBS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SBS"] = "伊织·诚 & 澪司",
	["illustrator:SBS"] = "wch5621628",
	["jieneng"] = "劫能",
	[":jieneng"] = "当你成为卡牌【杀】的目标后，你可以进行判定：若为<b><font color='red'>红色</font></b>，你将此【杀】置于武将牌上，称为<b>“能”</b>，且此【杀】对你无效。每有一张<b>“能”</b>，你的手牌上限-1。",
	["neng"] = "能",
	["shineng"] = "释能",
	[":shineng"] = "<img src=\"image/mark/@shineng.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以将所有<b>“能”</b>（至少一张）置入手牌，若如此做，此阶段：你的攻击范围和【杀】的额外使用次数均+X。（X为<b>“能”</b>的数量）",
	["@shineng"] = "释能",
	["rg"] = "RG",
	[":rg"] = "<img src=\"image/mark/@rg.png\"><b><font color='red'>限定技，</font></b>准备阶段开始时，你可以失去技能<b>“劫能”</b>和<b>“释能”</b>，并获得技能<b>“铁拳”</b>（<b><font color='blue'>锁定技，</font></b>你对其他角色造成的伤害+1；你的单数【闪】视为【杀】）。",
	["@rg"] = "RG",
	["tiequan"] = "铁拳",
	[":tiequan"] = "<b><font color='blue'>锁定技，</font></b>你对其他角色造成的伤害+1；你的单数【闪】视为【杀】。",
	
	["DARK_MATTER"] = "暗物质",
	["#DARK_MATTER"] = "冰火能天使",
	["~DARK_MATTER"] = "",
	["designer:DARK_MATTER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DARK_MATTER"] = "结城·达也",
	["illustrator:DARK_MATTER"] = "Sankies",
	["mingren"] = "名人",
	[":mingren"] = "<b><font color='blue'>锁定技，</font></b>你防止【决斗】对你造成的伤害。",
	["binghuo"] = "冰火",
	[":binghuo"] = "<img src=\"image/mark/@ice.png\"><b><font color='blue'>锁定技，</font></b>当你使用【杀】指定一名角色为目标后：\
①若其没有<b>“冰封”</b>标记：其获得<b>“冰封”</b>标记，终止此牌结算。\
②若其拥有<b>“冰封”</b>标记：此【杀】视为火【杀】，伤害+1，且\
不可被【闪】响应，造成伤害后，其失去<b>“冰封”</b>标记。\
●拥有<b>“冰封”</b>标记的角色装备无效。",
	["binghuocard"] = "冰火",
	["@ice"] = "冰封",
	["dm_transam"] = "TRANS-AM",
	[":dm_transam"] = "<img src=\"image/mark/@dm_transam.png\"><b><font color='red'>限定技，</font></b>出牌阶段，你可以将装备区的所有牌（至少一张）置入弃牌堆，若如此做，你摸等量张牌，此阶段你可以额外使用等量张【杀】。",
	["@dm_transam"] = "TRANS-AM",
	
	["BUILD_BURNING"] = "创制燃焰",
	["#BUILD_BURNING"] = "呼唤风的少年",
	["~BUILD_BURNING"] = "",
	["designer:BUILD_BURNING"] = "高达杀制作组",
	["cv:BUILD_BURNING"] = "神木·世界",
	["illustrator:BUILD_BURNING"] = "wch5621628",
	["ciyuanbawangliu"] = "次元霸王流",
	[":ciyuanbawangliu"] = "出牌阶段开始时，若你的<b>“拳法”</b>少于五张，你亮出牌堆顶的三张牌，将其中的【杀】、【决斗】、【过河拆桥】、【顺手牵羊】和【火攻】依次置于武将牌上，称为<b>“拳法”</b>（至多五张）。当你使用【杀】、【决斗】、【过河拆桥】、【顺手牵羊】或【火攻】时，你可以弃置一张<b>“拳法”</b>，令效果视为此<b>“拳法”</b>。",
	["@ciyuanbawangliu"] = "你可以发动“次元霸王流”，令牌名视为“拳法”",
	["~ciyuanbawangliu"] = "选择“拳法”→确定",
	["quanfa"] = "拳法",
	["tonghua"] = "同化",
	[":tonghua"] = "<img src=\"image/mark/@tonghua.png\"><b><font color='green'>觉醒技，</font></b>准备阶段开始时，若你的<b>“拳法”</b>有三张<b><font color='red'>红色</font></b>牌，你减1点体力上限，摸两张牌，并获得以下效果：你的<b><font color='red'>红色</font></b><b>“拳法”</b>视为火【杀】，<b>“次元霸王流”</b>描述的<b>“弃置”</b>改为<b>“获得”</b>。",
	["@tonghua"] = "同化",
	
	["BARBATOS"] = "巴巴托斯",
	["#BARBATOS"] = "铁血的孤儿",
	["~BARBATOS"] = "オルガ…アトラ…みんな…!",
	["designer:BARBATOS"] = "高达杀制作组",
	["cv:BARBATOS"] = "三日月·奥格斯",
	["illustrator:BARBATOS"] = "wch5621628",
	["eji"] = "厄祭",
	[":eji"] = "<b><font color='blue'>锁定技，</font></b>摸牌阶段，你少摸一张牌；你的手牌上限+1。",
	["tiexue"] = "铁血",
	[":tiexue"] = "准备阶段开始时，若你已受伤，你可以选择一项：\
1. 摸X张牌。（X为你已损失的体力值）\
2. 以你为伤害来源的【杀】或【决斗】造成的伤害+1，直到你的下回合开始前。",
	["tiexuedraw"] = "摸X张牌（X为你已损失的体力值）",
	["tiexuebuff"] = "【杀】或【决斗】造成的伤害+1",
	["#tiexuebuff"] = "以 %from 为伤害来源的【杀】或【决斗】造成的伤害+1，直到其下回合开始前",
	["#tiexuedamage"] = "%from 的 %card 对 %to 造成的伤害从 %arg 点增加至 %arg2 点",
	["$tiexue1"] = "まだだ…バルバトス!",
	["$tiexue2"] = "一機に切り込む!",
	["$tiexue3"] = "終わりだ!",
	
	["LUPUS"] = "巴巴托斯 天狼",
	["#LUPUS"] = "铁华团的恶魔",
	["~LUPUS"] = "鉄華団お…俺達の家族お…",
	["designer:LUPUS"] = "高达杀制作组",
	["cv:LUPUS"] = "三日月·奥格斯",
	["illustrator:LUPUS"] = "wch5621628",
	["zaie"] = "灾厄",
	[":zaie"] = "<b><font color='blue'>锁定技，</font></b>摸牌阶段，你多摸一张牌；你的手牌上限-1。",
	["tianlang"] = "天狼",
	[":tianlang"] = "当你使用【杀】、【酒】或【决斗】时，你可以弃置一张<b>黑色</b>牌，若如此做，目标角色再次成为目标；结束阶段开始时，若你于本回合造成过伤害，你可以失去1点体力，然后摸两张牌。",
	["@@tianlang"] = "你可以弃置一张黑色牌发动“天狼”",
	["#tianlang"] = "%to 再次成为 %card 的目标",
	["$zaie1"] = "オルガ、次はどうすればいい？",
	["$zaie2"] = "オルガの邪魔はさせない!",
	["$tianlang1"] = "あんた達に鉄華団はやらせない!",
	["$tianlang2"] = "俺はオルガに言われたんだ、あんたを殺っちまえってね",
	["$tianlang3"] = "オルガと鉄華団は、俺が守る…!",
	
	["REX"] = "巴巴托斯 帝王",
	["#REX"] = "狼中之王",
	["#REX_bug"] = "%from 打出了<b><font color='red'>致命一击</font></b>",
	["~REX"] = "俺たちの、本当の居場所…",
	["designer:REX"] = "高达杀制作组",
	["cv:REX"] = "三日月·奥格斯",
	["illustrator:REX"] = "wch5621628",
	["diwang"] = "帝王",
	[":diwang"] = "摸牌阶段，你可以令摸牌数为体力小于你的角色数，若此数不大于2，你于本回合使用的【杀】不可被【闪】响应且额外使用次数+X；当你使用【杀】或【决斗】对手牌数小于你的目标角色造成伤害时，你可以令伤害+1且具雷电伤害。（X为你已损失的体力值）",
	["diwang:draw"] = "你想发动技能“帝王”令摸牌数为%src吗?",
	["kuangxi"] = "狂袭",
	[":kuangxi"] = "<img src=\"image/mark/@kuangxi.png\"><b><font color='green'>觉醒技，</font></b>当你进入濒死状态时，你减1点体力上限，弃置区域里的所有牌，摸X张牌，攻击范围+1，然后进行一个额外的回合。（X为存活角色数）",
	["@kuangxi"] = "狂袭",
	["$diwang1"] = "このまま突っ込むよ!",
	["$diwang2"] = "俺は、強くなる!!",
	["$diwang3"] = "確実に当てる!",
	["$diwang4"] = "やっと捕まえた…!",
	["$diwang5"] = "これで終わり…!!",
	["$diwang6"] = "貫け!",
	["$kuangxi"] = "おい、バルバトス。お前だって止まりたくないだろう！",
}

--【显示胜率】（置于页底以确保武将名翻译成功）
if show_winrate then
	--[[caocao = sgs.General(extension, "caocao", "wei", 0, true, true, true)
	simayi = sgs.General(extension, "simayi", "wei", 0, true, true, true)
	xiahoudun = sgs.General(extension, "xiahoudun", "wei", 0, true, true, true)
	zhangliao = sgs.General(extension, "zhangliao", "wei", 0, true, true, true)
	xuchu = sgs.General(extension, "xuchu", "wei", 0, true, true, true)
	guojia = sgs.General(extension, "guojia", "wei", 0, true, true, true)
	zhenji = sgs.General(extension, "zhenji", "wei", 0, true, true, true)
	lidian = sgs.General(extension, "lidian", "wei", 0, true, true, true)
	liubei = sgs.General(extension, "liubei", "shu", 0, true, true, true)
	guanyu = sgs.General(extension, "guanyu", "shu", 0, true, true, true)
	zhangfei = sgs.General(extension, "zhangfei", "shu", 0, true, true, true)
	zhugeliang = sgs.General(extension, "zhugeliang", "shu", 0, true, true, true)
	zhaoyun = sgs.General(extension, "zhaoyun", "shu", 0, true, true, true)
	machao = sgs.General(extension, "machao", "shu", 0, true, true, true)
	huangyueying = sgs.General(extension, "huangyueying", "shu", 0, true, true, true)
	st_xushu = sgs.General(extension, "st_xushu", "shu", 0, true, true, true)
	sunquan = sgs.General(extension, "sunquan", "wu", 0, true, true, true)
	ganning = sgs.General(extension, "ganning", "wu", 0, true, true, true)
	lvmeng = sgs.General(extension, "lvmeng", "wu", 0, true, true, true)
	huanggai = sgs.General(extension, "huanggai", "wu", 0, true, true, true)
	zhouyu = sgs.General(extension, "zhouyu", "wu", 0, true, true, true)
	luxun = sgs.General(extension, "luxun", "wu", 0, true, true, true)
	daqiao = sgs.General(extension, "daqiao", "wu", 0, true, true, true)
	sunshangxiang = sgs.General(extension, "sunshangxiang", "wu", 0, true, true, true)
	lvbu = sgs.General(extension, "lvbu", "qun", 0, true, true, true)
	huatuo = sgs.General(extension, "huatuo", "qun", 0, true, true, true)
	diaochan = sgs.General(extension, "diaochan", "qun", 0, true, true, true)
	st_yuanshu = sgs.General(extension, "st_yuanshu", "qun", 0, true, true, true)
	st_gongsunzan = sgs.General(extension, "st_gongsunzan", "qun", 0, true, true, true)
	st_huaxiong = sgs.General(extension, "st_huaxiong", "qun", 0, true, true, true)
	zombie = sgs.General(extension, "zombie", "die", 0, true, true, true)]]--颜神的神作（Serious AI Bugs）
	local g_property = "<font color='red'><b>欢迎来玩高达杀！</b></font>"
	if dlc then
		if t[1] then
			g_property = ""
			local x, y = 0, 0
			for i,a in ipairs(t) do
				local str = a:split("=")
				local first = str[1]
				local second = str[2]
				local rate = second:split("/")
				if rate[2] == "0" then
					rate = "未知"
				else
					local round = function(num, idp)
						local mult = 10^(idp or 0)
						return math.floor(num * mult + 0.5) / mult
					end
					rate = round(rate[1]/rate[2]*100).."%"
				end
				if first == "GameTimes" then
					g_property = g_property.."\n".."<b>总胜率</b>"
					x, y = second, rate
				else
					g_property = g_property.."\n"..sgs.Sanguosha:translate(first)
				end
				g_property = g_property.." = "..second.." <b>("..rate..")</b>"
				if i == #t then
					g_property = g_property.."\n".."<b>总胜率</b>"
					g_property = g_property.." = "..x.." <b>("..y..")</b>"
				end
			end
		end
	end
	sgs.LoadTranslationTable{
		["winshow"] = "胜率",
		["#winshow"] = "玩家资讯",
		["designer:winshow"] = "高达杀制作组",
		["cv:winshow"] = "贴吧：高达杀s吧",
		["illustrator:winshow"] = "QQ群：565837324",
		["winrate"] = "胜率",
		[":winrate"] = g_property
	}
end

--【皮肤系统】（置于页底以确保武将名翻译成功）
if g_skin then
	FREEDOM_skin1 = sgs.General(extension, "FREEDOM_skin1", "ORB", 3, true, true, true)
	JUSTICE_skin1 = sgs.General(extension, "JUSTICE_skin1", "ORB", 4, true, true, true)
	PROVIDENCE_skin1 = sgs.General(extension, "PROVIDENCE_skin1", "ZAFT", 4, true, true, true)
	PROVIDENCE_skin2 = sgs.General(extension, "PROVIDENCE_skin2", "ZAFT", 4, true, true, true)
	SAVIOUR_skin1 = sgs.General(extension, "SAVIOUR_skin1", "ZAFT", 4, true, true, true)
	BARBATOS_skin1 = sgs.General(extension, "BARBATOS_skin1", "TEKKADAN", 4, true, true, true)
	LUPUS_skin1 = sgs.General(extension, "LUPUS_skin1", "TEKKADAN", 4, true, true, true)
	REX_skin1 = sgs.General(extension, "REX_skin1", "TEKKADAN", 4, true, true, true)
	
	for _,cp in ipairs(g_skin_cp) do
		for i,name in ipairs(cp) do
			if i > 1 then
				sgs.Sanguosha:addTranslationEntry(name, sgs.Sanguosha:translate(cp[1]))
			end
		end
	end
end

--【扭蛋、彩蛋模式】（置于页底以确保武将名翻译成功）
if lucky_card then
	g2_property = "\n金币 = 0"
	local file = io.open(g2data, "r")
	local tt = ""
	if file ~= nil then
		tt = file:read("*all")
		file:close()
	end
	if tt ~= "" then
		local n = tt:split("=")[2]
		g2_property = "\n金币 = " .. n
	end
	sgs.LoadTranslationTable{
		["itemshow"] = "扭蛋机",
		["#itemshow"] = "道具数量",
		["designer:itemshow"] = "高达杀制作组",
		["cv:itemshow"] = "贴吧：高达杀s吧",
		["illustrator:itemshow"] = "QQ群：565837324",
		["itemnum"] = "扭蛋",
		[":itemnum"] = g2_property
	}
end