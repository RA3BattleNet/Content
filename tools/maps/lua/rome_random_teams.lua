RA3BNPairWaypoints = {"RA3BN_Random_A1","Player_6_Start","RA3BN_Random_B1","Player_8_Start","Player_3_Start","Player_4_Start","Player_5_Start","Player_7_Start"}
RA3BNPairHeights = {200,210,280,350,350,280,280,280}
RA3BN4V4Automatic = 1
RA3BN4V4FogTarget = 'PlyrCivilian'
RA3BN4V4StartHeights = { 210, 350, 350, 280, 280, 210, 280, 350 }
RA3BN4V4SmallStarts = { [2] = {{1,6},{2,5},{3,4}}, [4] = {{1,6,2,5},{2,5,3,4}}, [6] = {{1,6,2,5,3,4}} }
RA3BN4V4TeamByStart = { 1, 1, 1, 2, 2, 2, 2, 1 }
RA3BN4V4TerrainMaxY = 9800
RA3BN4V4PlayableBounds = { minX = 0, minY = 0, maxX = 9500, maxY = 9500 }
-- Lua 4.0. The map embeds the team split, playable bounds and full terrain edge.
-- Display text is local; the dialog callback is a game command.
RA3BN4V4 = {
    phase = "startup",
    dialog = 49044,
    activeCounter = "RA3BN4V4Active",
}

local textByLanguage = {
    en = {
        title = "Teams and starting positions",
        randomize = "Randomize (4v4)",
        normalStart = "Keep lobby setup",
        waiting = "Waiting for a player to choose how to start.",
        shuffling = "Randomizing teams and starting positions...",
        ready = "Teams are set. You can start building.",
        startingNormally = "Starting with the lobby setup.",
        restored = "Could not randomize teams. Starting with the lobby setup.",
        restoreFailed = "Randomization stopped. Some bases could not return to their starting positions.",
    },
    zh = {
        title = "本局的队伍和出生点怎么安排？",
        randomize = "随机安排（4v4）",
        normalStart = "直接开始",
        waiting = "等待玩家选择开局方式。",
        shuffling = "正在随机分配队伍和出生点，请稍候。",
        ready = "分队完成，可以开始建造了。",
        startingNormally = "对局开始，可以建造了。",
        restored = "没能完成随机分队，按原安排开局。",
        restoreFailed = "随机分队中断，部分基地未能返回原位。",
    },
}

local automaticTextByLanguage = {
    en = {
        title = "How should this match start?",
        randomize = "Shuffle (%dv%d)",
        normalStart = "Skip shuffle",
        pairs = "Shuffle (%s)",
        solo = "With %d players, the solo player gets a main base at both starting points in their area.",
        waiting = "Waiting for a choice. Teams will shuffle in 15 seconds.",
        splitting = "We'll keep teammates together where possible. Some teams may need to split.",
        shuffling = "Shuffling teams and starting positions...",
        ready = "You can start building now.",
        startingNormally = "Keeping your teams and starting positions.",
        odd = "There's an odd number of players, so we're keeping the lobby setup.",
        restored = "The shuffle couldn't finish. Starting with your original setup.",
        restoreFailed = "The shuffle stopped. Some bases couldn't return to their starting positions.",
    },
    zh = {
        title = "这局怎么开？",
        randomize = "随机分队（%dv%d）",
        normalStart = "跳过随机分队",
        pairs = "随机分队（%s）",
        solo = "%d 人开局时，落单玩家会在自己区域的两个出生点各有一个主基地。",
        waiting = "等待选择开局方式，15 秒后将自动随机分队。",
        splitting = "会尽量保留原队友；分不开时，可能需要拆开部分队友。",
        shuffling = "正在随机安排队伍和出生点……",
        ready = "可以开始建造了。",
        startingNormally = "保留原队伍和出生点。",
        odd = "这局人数无法随机分队，保留原队伍和出生点。",
        restored = "这次没能随机分队，保留原队伍和出生点。",
        restoreFailed = "随机分队中断，部分基地未能返回原位。",
    },
}

function RA3BN4V4:readMap()
    local starts, parking = {}, {}
    for i = 1, 8 do
        local point = exWaypointGetPos("Player_" .. i .. "_Start")
        if not point or point[1] == nil or point[2] == nil
            or (point[1] == -1 and point[2] == -1 and point[3] == -1) then
            return
        end
        for j = 1, i - 1 do
            if starts[j][1] == point[1] and starts[j][2] == point[2] then
                return
            end
        end
        starts[i] = point
        parking[i] = {500 + 3000 * mod(i - 1, 4), RA3BN4V4TerrainMaxY + 3000 * (1 + floor((i - 1) / 4))}
    end
    self.starts = starts
    self.parking = parking
    self.pairStarts = {}
    for i = 1, 8 do
        local point = exWaypointGetPos(RA3BNPairWaypoints[i])
        if not point or point[1] == nil or point[2] == nil
            or (point[1] == -1 and point[2] == -1 and point[3] == -1) then
            return
        end
        self.pairStarts[i] = point
    end
    return 1
end

function RA3BN4V4:findHost()
    local previous = SetWorldBuilderThisPlayer(1)
    local player = ObjectPlayerScriptName("<1st Human Player>")
    if not player or not strfind(player, "^Player_[1-8]$") then
        player = nil
        for i = 1, 8 do
            local candidate = "Player_" .. i
            if EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", candidate, "Human") then
                player = candidate
                break
            end
        end
    end
    SetWorldBuilderThisPlayer(previous)
    return player
end

function RA3BN4V4:setBuildPermission(enabled)
    local baseAction = "PLAYER_DISABLE_BASE_CONSTRUCTION"
    local unitAction = "PLAYER_DISABLE_UNIT_CONSTRUCTION"
    if enabled then
        baseAction = "PLAYER_ENABLE_BASE_CONSTRUCTION"
        unitAction = "PLAYER_ENABLE_UNIT_CONSTRUCTION"
    end
    for i = 1, getn(self.roster) do
        local player = "Player_" .. self.roster[i].seat
        ExecuteAction(baseAction, player)
        ExecuteAction(unitAction, player)
    end
end

function RA3BN4V4:closeDialog()
    if self.host then
        exHideCustomBtnChoiceDialogForPlayer(self.host)
    end
end

function RA3BN4V4:finish()
    if self.locked then
        self:setBuildPermission(1)
        self.locked = nil
    end
    self.phase = "done"
    exCounterSetByName(self.activeCounter, 0)
end

function RA3BN4V4:sameRoster(groups)
    if getn(groups) ~= getn(self.roster) then
        return
    end
    for i = 1, getn(groups) do
        if groups[i].seat ~= self.roster[i].seat or groups[i].base.id ~= self.roster[i].base.id then
            return
        end
    end
    return 1
end

function RA3BN4V4:captureStarts()
    local bounds = RA3BN4V4PlayableBounds
    local groups = {}
    for i = 1, 8 do
        local objects, count = CopyPlayerRegisteredObjectSet("Player_" .. i, "UNITS_AND_STRUCTURES")
        local spawn = self.starts[i]
        local group = {seat = i, objects = {}}
        for j = 1, count or 0 do
            local obj = objects[j]
            if ObjectIsAlive(obj) then
                local x, y, z = ObjectGetPosition(obj)
                if x == nil then
                    return
                end
                if x >= bounds.minX and x < bounds.maxX and y >= bounds.minY and y < bounds.maxY then
                    local selectable = ObjectTestTargetObjectWithFilter(nil, obj, self.selectable)
                    local construction = ObjectIsInPlayerRegisteredObjectSet(obj, "CONYARDS")
                        or ObjectIsInPlayerRegisteredObjectSet(obj, "MCVS")
                    local id = ObjectGetId(obj)
                    -- Attached AI yards inside the map travel with their main base.
                    if selectable or construction or exObjectGetShroudClearingDistance(id) ~= 0 then
                        local member = {id = id, x = x, y = y, z = z}
                        if construction and selectable then
                            local dx, dy = x - spawn[1], y - spawn[2]
                            if group.base or dx * dx + dy * dy > 200 * 200 then
                                return
                            end
                            group.base = member
                        end
                        tinsert(group.objects, member)
                    end
                end
            end
        end
        if not group.base then
            if not RA3BN4V4Automatic or getn(group.objects) > 0 then
                return
            end
        else
            for j = 1, getn(group.objects) do
                local obj = group.objects[j]
                local dx, dy = obj.x - group.base.x, obj.y - group.base.y
                if dx * dx + dy * dy > 200 * 200 then
                    return
                end
            end
            tinsert(groups, group)
        end
    end
    return groups
end

function RA3BN4V4:planTeams(groups)
    local count = getn(groups)
    local bases, allies = {}, {}
    for i = 1, count do
        bases[i] = GetObjectById(groups[i].base.id)
        if not bases[i] then
            return
        end
        allies[i] = {}
    end
    for i = 1, count - 1 do
        for j = i + 1, count do
            local friend = ObjectTestTargetObjectWithFilter(bases[i], bases[j], self.allied)
            local enemy = ObjectTestTargetObjectWithFilter(bases[i], bases[j], self.enemy)
            local reverseFriend = ObjectTestTargetObjectWithFilter(bases[j], bases[i], self.allied)
            local reverseEnemy = ObjectTestTargetObjectWithFilter(bases[j], bases[i], self.enemy)
            if (friend and not enemy and reverseFriend and not reverseEnemy) then
                allies[i][j] = 1
            elseif not (enemy and not friend and reverseEnemy and not reverseFriend) then
                return
            end
        end
    end
    -- Keep all equally good partitions, including both map-side orientations.
    local candidates, fewestSeparated = {}, count * count
    for mask = 1, 2 ^ count - 1 do
        local firstSide, size = {}, 0
        for i = 1, count do
            if mod(floor(mask / 2 ^ (i - 1)), 2) == 1 then
                size = size + 1
                firstSide[i] = 1
            end
        end
        if size == count / 2 then
            local separated = 0
            for i = 1, count - 1 do
                for j = i + 1, count do
                    if allies[i][j] and firstSide[i] ~= firstSide[j] then
                        separated = separated + 1
                    end
                end
            end
            if separated < fewestSeparated then
                fewestSeparated = separated
                candidates = {}
            end
            if separated == fewestSeparated then
                tinsert(candidates, firstSide)
            end
        end
    end
    self.originalAllies = allies
    return candidates, fewestSeparated
end

-- Canonical unlabeled pair partitions: every pairing occurs once, including
-- every possible solo player for odd rosters. Map areas are randomized later.
function RA3BN4V4:pairPartitions(index, assignments, sizes, used, state)
    local count = getn(self.roster)
    if index > count then
        if used ~= state.teamCount then return end
        local separated = 0
        for i = 1, count - 1 do
            for j = i + 1, count do
                if self.originalAllies[i][j] and assignments[i] ~= assignments[j] then
                    separated = separated + 1
                end
            end
        end
        if separated < state.fewest then
            state.fewest, state.candidates = separated, {}
        end
        if separated == state.fewest then
            local copy = {}
            for i = 1, count do copy[i] = assignments[i] end
            tinsert(state.candidates, copy)
        end
        return
    end
    for team = 1, min(used + 1, state.teamCount) do
        if (sizes[team] or 0) < 2 then
            assignments[index] = team
            sizes[team] = (sizes[team] or 0) + 1
            self:pairPartitions(index + 1, assignments, sizes, max(used, team), state)
            sizes[team] = sizes[team] - 1
        end
    end
end

function RA3BN4V4:prepareModes()
    local count = getn(self.roster)
    self.modes, self.buttons = {}, {}
    if mod(count, 2) == 0 then
        tinsert(self.modes, "halves")
        tinsert(self.buttons, format(self.ui.randomize, count / 2, count / 2))
    end
    if count >= 5 then
        local state = {teamCount = floor((count + 1) / 2), fewest = count * count, candidates = {}}
        self:pairPartitions(1, {}, {}, 0, state)
        self.pairCandidates = state.candidates
        self.pairFewestSeparated = state.fewest
        tinsert(self.modes, "pairs")
        tinsert(self.buttons, format(self.ui.pairs, count >= 7 and "2v2v2v2" or "2v2v2"))
        if mod(count, 2) == 1 then
            exMessageAppendToMessageArea(format(self.ui.solo, count))
        end
    end
    tinsert(self.modes, "skip")
    tinsert(self.buttons, self.ui.normalStart)
end

function RA3BN4V4:randomPairStarts()
    local assignments = self.pairCandidates[floor(GetRandomNumber() * getn(self.pairCandidates)) + 1]
    local areas = {{1, 2}, {3, 4}, {5, 6}, {7, 8}}
    if getn(self.groups) <= 6 then areas = {{1, 2}, {3, 4}, {7, 6}} end
    self:shuffle(areas)
    for i = 1, getn(areas) do self:shuffle(areas[i]) end
    local used, slots = {}, {}
    self.plannedTeams = assignments
    for i = 1, getn(self.groups) do
        local team = assignments[i]
        used[team] = (used[team] or 0) + 1
        slots[i] = areas[team][used[team]]
    end
    self.extraStart = nil
    for i = 1, getn(self.groups) do
        local team = assignments[i]
        if used[team] == 1 then self.extraStart = {group = i, slot = areas[team][2]} end
    end
    return slots
end

function RA3BN4V4:shuffle(slots)
    for i = getn(slots), 2, -1 do
        local j = floor(GetRandomNumber() * i) + 1
        slots[i], slots[j] = slots[j], slots[i]
    end
end

function RA3BN4V4:randomStarts()
    if self.pairMode then return self:randomPairStarts() end
    if not self.candidates then
        local slots = {1, 2, 3, 4, 5, 6, 7, 8}
        self:shuffle(slots)
        return slots
    end
    local firstSide = self.candidates[floor(GetRandomNumber() * getn(self.candidates)) + 1]
    local sides, slots = {{}, {}}, {}
    local count = getn(self.groups)
    if count < 8 then
        local presets = RA3BN4V4SmallStarts[count]
        local preset = presets[1]
        if getn(presets) > 1 then
            preset = presets[floor(GetRandomNumber() * getn(presets)) + 1]
        end
        for i = 1, getn(preset) do
            local seat = preset[i]
            tinsert(sides[RA3BN4V4TeamByStart[seat]], seat)
        end
    else
        for i = 1, 8 do
            tinsert(sides[RA3BN4V4TeamByStart[i]], i)
        end
    end
    self:shuffle(sides[1])
    self:shuffle(sides[2])
    local nextStart = {1, 1}
    for i = 1, count do
        local side = 2
        if firstSide[i] then
            side = 1
        end
        slots[i] = sides[side][nextStart[side]]
        nextStart[side] = nextStart[side] + 1
    end
    return slots
end

function RA3BN4V4:at(obj, x, y, z)
    local actualX, actualY, actualZ = ObjectGetPosition(obj)
    return actualX ~= nil and abs(actualX - x) <= 1 and abs(actualY - y) <= 1
        and abs(actualZ - z) <= 2
end

function RA3BN4V4:position(group, x, y, z, move)
    for j = 1, getn(group.objects) do
        local original = group.objects[j]
        local obj = GetObjectById(original.id)
        local toX, toY, toZ = x + (original.x - group.base.x),
            y + (original.y - group.base.y), z + (original.z - group.base.z)
        if not obj or not ObjectIsAlive(obj) then
            return
        end
        if move then
            ObjectSetPosition(obj, toX, toY, toZ)
        end
        if not self:at(obj, toX, toY, toZ) then
            return
        end
    end
    return 1
end

function RA3BN4V4:restore()
    local restored = 1
    for i = 1, getn(self.groups) do
        local group = self.groups[i]
        for j = 1, getn(group.objects) do
            local original = group.objects[j]
            local obj = GetObjectById(original.id)
            if not obj or not ObjectIsAlive(obj) then
                restored = nil
            elseif not self:at(obj, original.x, original.y, original.z) then
                ObjectSetPosition(obj, original.x, original.y, original.z)
                if not self:at(obj, original.x, original.y, original.z) then
                    restored = nil
                end
            end
        end
    end
    return restored
end

function RA3BN4V4:changeRelations(pairs, relation)
    for i = 1, getn(pairs) do
        local pair = pairs[i]
        ExecuteAction("PLAYER_RELATES_PLAYER", pair[1], pair[2], relation)
        ExecuteAction("PLAYER_RELATES_PLAYER", pair[2], pair[1], relation)
    end
end

function RA3BN4V4:abortShuffle()
    if self.extraBaseName then
        local obj = GetObjectByScriptName(self.extraBaseName)
        if obj then ExecuteAction("NAMED_DELETE", obj) end
        self.extraBaseName = nil
    end
    local restored = not self.groups or self:restore()
    if self.brokenAlliances then
        self:changeRelations(self.brokenAlliances, "Friend")
        self.brokenAlliances = nil
    end
    self:finish()
    if restored then
        exMessageAppendToMessageArea(self.ui.restored)
    else
        exMessageAppendToMessageArea(self.ui.restoreFailed)
    end
end

function RA3BN4V4:park(groups)
    self.groups = groups
    for i = 1, getn(groups) do
        local point = self.parking[i]
        if not self:position(self.groups[i], point[1], point[2], self.groups[i].base.z, 1) then
            self:abortShuffle()
            return
        end
    end
    self.phase = "clearing"
    -- Allow the engine to enqueue the old sight once the groups are off-map.
    self.deadline = GetFrame() + (RA3BN4V4FogTarget and 1 or 75)
end

function RA3BN4V4:planRelations(slots)
    local friends, enemies = {}, {}
    local count = getn(self.groups)
    for i = 1, count - 1 do
        for j = i + 1, count do
            local sameSide
            if self.pairMode then
                sameSide = self.plannedTeams[i] == self.plannedTeams[j]
            else
                sameSide = RA3BN4V4TeamByStart[slots[i]] == RA3BN4V4TeamByStart[slots[j]]
            end
            if not self.originalAllies or sameSide ~= self.originalAllies[i][j] then
                tinsert(sameSide and friends or enemies,
                    {"Player_" .. self.groups[i].seat, "Player_" .. self.groups[j].seat})
            end
        end
    end
    return friends, enemies
end

function RA3BN4V4:createExtraBase()
    if not self.extraStart then return 1 end
    local group = self.groups[self.extraStart.group]
    local base = GetObjectById(group.base.id)
    local typeName
    for i = 1, getn(self.baseTypes) do
        local entry = self.baseTypes[i]
        if ObjectIsInPlayerRegisteredObjectSet(base, entry.registry)
            and ObjectTestTargetObjectWithFilter(nil, base, entry.filter) then
            typeName = entry.name
            break
        end
    end
    if not typeName then return end
    local player = "Player_" .. group.seat
    local slot = self.extraStart.slot
    local point, z = self.pairStarts[slot], RA3BNPairHeights[slot]
    self.extraBaseName = "RA3BN_RandomTeams_ExtraBase"
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", self.extraBaseName,
        typeName, player .. "/team" .. player, {X = point[1], Y = point[2], Z = z}, -3.1415926 / 4)
    local created = GetObjectByScriptName(self.extraBaseName)
    if not created or not ObjectIsAlive(created) or ObjectPlayerScriptName(created) ~= player
        or not self:at(created, point[1], point[2], z)
        or not ObjectTestTargetObjectWithFilter(nil, created, self.selectable)
        or not (ObjectIsInPlayerRegisteredObjectSet(created, "CONYARDS")
            or ObjectIsInPlayerRegisteredObjectSet(created, "MCVS")) then
        return
    end
    return 1
end

function RA3BN4V4:clearPairStructures()
    local filter = CreateObjectFilter({Rule = "ANY",
        IncludeThing = {"FI_FloatingFortressMainGun", "VeterancyTechStructure"}})
    local objects, count = ObjectFindObjects(nil, nil, filter)
    for i = 1, count do
        ExecuteAction("NAMED_KILL", objects[i])
    end
end

function RA3BN4V4:deploy()
    local count = getn(self.groups)
    for i = 1, count do
        local point = self.parking[i]
        if not self:position(self.groups[i], point[1], point[2], self.groups[i].base.z) then
            self:abortShuffle()
            return
        end
    end
    local fogTarget = RA3BN4V4FogTarget
    if fogTarget and ObjectPlayerScriptName(fogTarget) ~= fogTarget then
        -- A missing player resolves to an empty mask, which would shroud other players.
        self:abortShuffle()
        return
    end
    local slots = self:randomStarts()
    local friends, enemies = self:planRelations(slots)
    if fogTarget then
        self.brokenAlliances = enemies
        self:changeRelations(enemies, "Enemy")
        -- This action drains pending unlook requests globally before shrouding its target.
        ExecuteAction("MAP_SHROUD_ALL", fogTarget)
    end
    for i = 1, count do
        local destination = slots[i]
        local point = self.pairMode and self.pairStarts[destination] or self.starts[destination]
        local z = self.pairMode and RA3BNPairHeights[destination] or RA3BN4V4StartHeights[destination]
        if not self:position(self.groups[i], point[1], point[2], z, 1) then
            self:abortShuffle()
            return
        end
    end
    if not self:createExtraBase() then
        self:abortShuffle()
        return
    end
    if not fogTarget then
        self:changeRelations(enemies, "Enemy")
    end
    self:changeRelations(friends, "Friend")
    self.brokenAlliances = nil
    if self.pairMode then self:clearPairStructures() end
    for i = 1, count do
        ExecuteAction("PLAYER_CAMERA_MOVE_TO_NAMED", "Player_" .. self.groups[i].seat,
            GetObjectById(self.groups[i].base.id), 0, 0, 0, 0)
    end
    self:finish()
    exMessageAppendToMessageArea(self.ui.ready)
end

function RA3BN4V4:tick()
    local now = GetFrame()
    if self.phase == "startup" then
        local groups = self:captureStarts()
        local splitCount
        if RA3BN4V4Automatic then
            local count = groups and getn(groups) or 0
            if now < self.earliestPark then
                if not self.locked and count >= 2 and (mod(count, 2) == 0 or count >= 5) then
                    self.roster = groups
                    self:setBuildPermission(nil)
                    self.locked = 1
                end
                return
            end
            if mod(count, 2) == 1 and count < 5 then
                self:finish()
                exMessageAppendToMessageArea(self.ui.odd)
                return
            end
            if count >= 2 and (not self.locked or self:sameRoster(groups)) then
                self.candidates, splitCount = self:planTeams(groups)
            end
            if not self.candidates then
                groups = nil
            end
        end
        local host = self:findHost()
        if host and groups then
            self.host = host
            self.roster = groups
            if not self.locked then
                self:setBuildPermission(nil)
                self.locked = 1
            end
            self.phase = "choosing"
            self.deadline = now + (RA3BN4V4Automatic and 15 or 20) * 15
            exMessageAppendToMessageArea(self.ui.waiting)
            self.halvesFewestSeparated = splitCount
            self:prepareModes()
            exShowCustomBtnChoiceDialogForPlayer(host, self.dialog, self.ui.title,
                self.buttons[1], self.buttons[2], self.buttons[3] or "", "", "", "", "")
        elseif now >= self.deadline then
            self:finish()
            if RA3BN4V4Automatic then
                exMessageAppendToMessageArea(self.ui.restored)
            end
        end
    elseif self.phase == "choosing" then
        local choice = self.choice
        if not choice and now >= self.deadline then choice = 1 end
        if choice then
            self:closeDialog()
            if self.modes[choice] == "skip" then
                self:finish()
                exMessageAppendToMessageArea(self.ui.startingNormally)
            else
                self.pairMode = self.modes[choice] == "pairs"
                self.phase, self.deadline = "settling", now + 45
                local separated = self.pairMode and self.pairFewestSeparated or self.halvesFewestSeparated
                if separated > 0 then exMessageAppendToMessageArea(self.ui.splitting) end
                exMessageAppendToMessageArea(self.ui.shuffling)
            end
        end
    elseif self.phase == "clearing" and now >= self.deadline then
        self:deploy()
    end
    -- Corona can add the attached AI construction yards in the opening frames.
    if self.phase == "settling" and now >= self.earliestPark then
        local groups = self:captureStarts()
        if groups and RA3BN4V4Automatic and not self:sameRoster(groups) then
            groups = nil
        end
        if groups then
            self:park(groups)
        elseif now >= self.deadline then
            self:abortShuffle()
        end
    end
end

function onUserBtnChoiceDialogEvent(player, button, dialog)
    local setup = RA3BN4V4
    if setup.phase == "choosing" and not setup.choice and player == setup.host
        and dialog == setup.dialog and button >= 1 and button <= getn(setup.modes) then
        -- Enhancer's game-command callback has no WorldBuilder player context.
        setup.choice = button
    end
end

if exShowCustomBtnChoiceDialogForPlayer and exHideCustomBtnChoiceDialogForPlayer
    and SetWorldBuilderThisPlayer and ObjectPlayerScriptName and EvaluateCondition
    and exMessageAppendToMessageArea and exCounterSetByName and CopyPlayerRegisteredObjectSet
    and ObjectSetPosition and ObjectGetPosition
    and ObjectGetId and GetObjectById and ObjectIsAlive
    and GetObjectByScriptName
    and ObjectIsInPlayerRegisteredObjectSet and GetFrame and GetRandomNumber
    and CreateObjectFilter and ObjectFindObjects and ObjectTestTargetObjectWithFilter and exObjectGetShroudClearingDistance
    and exWaypointGetPos and RA3BN4V4:readMap() then
    -- Like DSA, use a translated stock UI label to detect the local language.
    local okLabel = TextTranslate and TextTranslate("GUI:OK")
    local texts = textByLanguage
    if RA3BN4V4Automatic then
        texts = automaticTextByLanguage
        RA3BN4V4.allied = CreateObjectFilter({Rule = "ANY", Relationship = "ALLIES", Include = "SELECTABLE"})
        RA3BN4V4.enemy = CreateObjectFilter({Rule = "ANY", Relationship = "ENEMIES", Include = "SELECTABLE"})
    end
    RA3BN4V4.ui = texts.en
    if okLabel == "确定" or okLabel == "確定" then
        RA3BN4V4.ui = texts.zh
    end
    RA3BN4V4.selectable = CreateObjectFilter({Rule = "ANY", Include = "SELECTABLE"})
    RA3BN4V4.baseTypes = {}
    local factions = {"Allied", "Soviet", "Japan", "Celestial"}
    for i = 1, getn(factions) do
        for j = 1, 2 do
            local typeName = factions[i] .. (j == 1 and "ConstructionYard" or "MCV")
            tinsert(RA3BN4V4.baseTypes, {name = typeName, registry = j == 1 and "CONYARDS" or "MCVS",
                filter = CreateObjectFilter({Rule = "ANY", IncludeThing = {typeName}})})
        end
    end
    RA3BN4V4.deadline = GetFrame() + 30
    RA3BN4V4.earliestPark = RA3BN4V4.deadline
    exCounterSetByName(RA3BN4V4.activeCounter, 1)
end
