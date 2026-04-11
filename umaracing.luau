local players = game:GetService("Players")
local rs = game:GetService("RunService")
local lp = players.LocalPlayer

local state = {
    esp = true,
    ult = true,
    lock = true,
    val = 150 -- stamina value for inf, max normal stamina is 150
}

local tags = {}

UI.AddTab("uma racing", function(tab)
    local sec = tab:Section("modules", "left")
    
    sec:Toggle("esp_toggle", "player esp", true, function(v)
        state.esp = v
    end)
    
    sec:Toggle("ult_toggle", "show ultimate", true, function(v)
        state.ult = v
    end)
    
    sec:Toggle("lock_toggle", "lock stamina", true, function(v)
        state.lock = v
    end)
end)

local function clean()
    for i = 1, #tags do
        if tags[i] then
            tags[i].Visible = false
            tags[i]:Remove()
        end
    end
    tags = {}
end

local function update()
    clean()

    if state.lock then
        -- checking both lowercase and uppercase just in case the game folder name is inconsistent
        local my_info = lp:FindFirstChild("Info") or lp:FindFirstChild("info")
        if my_info then
            local my_stam = my_info:FindFirstChild("Stamina") or my_info:FindFirstChild("stamina")
            if my_stam then
                my_stam.Value = state.val
            end
        end
    end

    if not state.esp then return end

    for _, p in ipairs(players:GetChildren()) do
        if p ~= lp and p.Character then
            local head = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("head")
            if head then
                local world_pos = head.Position + Vector3.new(0, 3, 0)
                local screen_pos, on_screen = WorldToScreen(world_pos)

                if on_screen then
                    local s_val = "0"
                    local u_val = "0"
                    local display_text = ""
                    
                    local info = p:FindFirstChild("Info") or p:FindFirstChild("info")
                    if info then
                        local stam_obj = info:FindFirstChild("Stamina") or info:FindFirstChild("stamina")
                        if stam_obj then
                            s_val = tostring(math.floor(stam_obj.Value))
                        end
                        
                        local ult_obj = info:FindFirstChild("Ultimate") or info:FindFirstChild("ultimate") or p:FindFirstChild("Ultimate") or p:FindFirstChild("ultimate")
                        if ult_obj then
                            u_val = tostring(math.floor(ult_obj.Value))
                        end
                    end

                    display_text = "stamina: " .. s_val
                    if state.ult then
                        display_text = display_text .. "\nultimate: " .. u_val .. "%"
                    end

                    local text = Drawing.new("Text")
                    text.Visible = true
                    text.Center = true
                    text.Outline = true
                    text.Size = 18
                    text.Color = Color3.fromRGB(0, 255, 150)
                    text.Position = screen_pos
                    text.Text = display_text
                    
                    table.insert(tags, text)
                end
            end
        end
    end
end

rs.RenderStepped:Connect(function()
    pcall(update)
end)

print("horse racing game")
