

local dungeonButton = QueueStatusButton

-- MIST Classic (used to be MiniMapLFGFrame before 5.5.4)
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
  dungeonButton = LFGMinimapFrameIcon
end



local indicator = {}
local update = function()

  -- Try each LFG category (like Blizzard's QueueStatusFrame does), so besides LE_LFG_CATEGORY_LFD
  -- and LE_LFG_CATEGORY_RF we also catch role-based queues such as Decor Duels. Scenarios, training
  -- grounds and World PvP have no meaningful roles, so we skip them.
  local hasData, _, tankNeeds, healerNeeds, dpsNeeds, totalTanks, totalHealers, totalDPS, instanceSubType
  for category = 1, NUM_LE_LFG_CATEGORYS do
    hasData, _, tankNeeds, healerNeeds, dpsNeeds, totalTanks, totalHealers, totalDPS, _, instanceSubType = GetLFGQueueStats(category)
    if hasData
    and category ~= LE_LFG_CATEGORY_SCENARIO
    and category ~= LE_LFG_CATEGORY_WORLDPVP
    and instanceSubType ~= LFG_SUBTYPEID_TRAINING_GROUNDS then
      break
    end
    hasData = nil
  end

  if not hasData then
    for _, v in pairs(indicator) do
      v:Hide()
    end
    return
  end


  -- -- For testing.
  -- if instanceSubType == LFG_SUBTYPEID_DUNGEON then
    -- print("dungeon", (totalTanks-tankNeeds).."/"..totalTanks, (totalHealers-healerNeeds).."/"..totalHealers , (totalDPS-dpsNeeds).."/"..totalDPS)
  -- end
  -- if instanceSubType == LFG_SUBTYPEID_RAID then
    -- print("raid", (totalTanks-tankNeeds).."/"..totalTanks, (totalHealers-healerNeeds).."/"..totalHealers , (totalDPS-dpsNeeds).."/"..totalDPS)
  -- end


  local totalAll = totalTanks + totalHealers + totalDPS

   -- Setup indicators.
  if not indicator[totalAll] then
    indicator[totalAll] = CreateFrame("Frame", nil, dungeonButton)

    -- Steps for the sin and cos functions.
    local temp = 2*math.pi / totalAll

    local buttonWidth = dungeonButton:GetWidth()

    -- For Classic the width needs to be a little bit smaller.
    if dungeonButton == MiniMapLFGFrame then
      buttonWidth = buttonWidth * 0.9
    end

    -- For dungeon,
    local indicatorWidth  = buttonWidth/5
    local indicatorRadius = buttonWidth/2.1

    -- For raid. (Better to check for totalAll than for instanceSubType, because some special events with 20 players go as LFG_SUBTYPEID_DUNGEON.)
    if totalAll >= 20 then
      indicatorWidth  = math.pi*buttonWidth/totalAll
      indicatorRadius = buttonWidth/1.9
    end

    -- Looks better!
    local yOffset = 0.02 * buttonWidth

    for i = 1, totalAll, 1 do
      local t = indicator[totalAll]:CreateTexture(nil, "OVERLAY")
      t:SetTexture("Interface\\AddOns\\LFGStatusIcon\\indicator.tga")
      t:SetWidth(indicatorWidth)
      t:SetHeight(indicatorWidth)
      t:SetPoint("CENTER", dungeonButton, "CENTER", indicatorRadius * math.cos((i - 1) * temp + math.pi/2), indicatorRadius * math.sin((i - 1) * temp + math.pi/2) + yOffset)
      indicator[totalAll][i] = t
    end
  end

  for i = 1, totalTanks, 1 do
    local r, g, b = 0.3, 0.5, 1.0
    local dim = 0.6
    if i <= (totalTanks - tankNeeds) then
      indicator[totalAll][i]:SetVertexColor(r, g, b, 1)
    else
      indicator[totalAll][i]:SetVertexColor(dim * r, dim * g, dim * b, 1)
    end
  end

  for i = totalTanks + 1, totalTanks + totalHealers, 1 do
    if i <= (totalTanks + totalHealers - healerNeeds) then
      indicator[totalAll][i]:SetVertexColor(0, 1, 0, 1)
    else
      indicator[totalAll][i]:SetVertexColor(0, 0.4, 0, 1)
    end
  end

  for i = totalTanks + totalHealers + 1, totalAll, 1 do
    if i <= (totalAll - dpsNeeds) then
      indicator[totalAll][i]:SetVertexColor(1, 0, 0, 1)
    else
      indicator[totalAll][i]:SetVertexColor(0.5, 0, 0, 1)
    end
  end

  if not indicator[totalAll]:IsShown() then
    indicator[totalAll]:Show()
  end

end


hooksecurefunc("QueueStatusEntry_SetUpLFG", update)
dungeonButton:HookScript("OnShow", update)
if dungeonButton:IsShown() then
  update()
end