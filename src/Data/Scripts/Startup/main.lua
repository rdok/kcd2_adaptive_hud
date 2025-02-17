adaptive_hud = {
    execution_interval_ms = "1000",
    health_threshold = "0.75",
    stamina_threshold = "100",
    stats_timer_id = nil,
    menu_close_timer_id = nil,
    force_show_stats = false,
    onload_executed = false,
    first_on_action_executed = true
}

local log_prefix = "$5[AdaptiveHUD] "

local function log_info(message, ...)
    local formatted_message = string.format(log_prefix .. message, ...)
    System.LogAlways(formatted_message)
end

function adaptive_hud:OnLoad()
    if self.onload_executed then return end
    log_info("OnLoad.init")
    self.onload_executed = true
    self:start_stats_timer(tonumber(self.execution_interval_ms))
end

function adaptive_hud:start_stats_timer(interval_ms)
    log_info("start_stats_timer with interval %d ms", interval_ms)
    if self.stats_timer_id then Script.KillTimer(self.stats_timer_id) end

    log_info("start_stats_timer setting timer")
    self.stats_timer_id = Script.SetTimer(interval_ms, function(nTimerId)
        log_info("start_stats_timer callback.")
        self:updateStats()
    end)
end

function adaptive_hud:start_menu_close_timer()
    if self.menu_close_timer_id then Script.KillTimer(self.menu_close_timer_id) end
    self.menu_close_timer_id = Script.SetTimer(7000, function(nTimerId)
        self.force_show_stats = false
        local showStats = self:has_low_stats() and 1 or 0
        System.SetCVar('wh_ui_ShowStats', showStats)
        System.SetCVar('wh_ui_showCompass', 0)
        System.SetCVar('wh_ui_ShowQAMFood', 0)
        System.SetCVar('wh_ui_ShowQAMWeapon', 0)
        System.SetCVar('wh_ui_ShowBuffs', 0)
        self.menu_close_timer_id = nil
    end)
end

function adaptive_hud:has_low_stats()
    local current_health = player.actor:GetHealth()
    local max_health = player.actor:GetMaxHealth()
    local stamina = player.soul:GetState("stamina")

    log_info("Stamina: %s", stamina)

    local health_low = current_health < (max_health * tonumber(self.health_threshold))
    local stamina_low = stamina < tonumber(self.stamina_threshold)

    return health_low or stamina_low
end

function Player:OnLoad(saved)
    log_info("Player:OnLoad")
	BasicActor.OnLoad(self, saved);
    log_info("Player:OnLoadSecond")
	self.WorldTimePausedReasons = saved.WorldTimePausedReasons;
end

function adaptive_hud:updateStats()
    log_info("updateStats called")

    if self.force_show_stats then
        log_info("updateStats.starting new timer")
        self:start_stats_timer(tonumber(self.execution_interval_ms))
        return
    end

    local showStats = self:has_low_stats() and "1" or "0"
    log_info("updateStats.showStats: %s", showStats)
    System.SetCVar('wh_ui_ShowStats', showStats)

    log_info("updateStats.starting new timer")
    self:start_stats_timer(tonumber(self.execution_interval_ms))
end

function Player:OnAction(action, activation, value)
    adaptive_hud:OnLoad()
    log_info(string.format("action: %s, activation: %s", action, activation))

    local valid_actions = {
        open_apse_map_keyboard = true,
        close = true,
        open_apse_player = true,
        open_apse_questlog = true,
        open_apse_inventory_keyboard = true,
        open_apse_codex = true
    }

    if adaptive_hud.first_on_action_executed then 
        adaptive_hud.first_on_action_executed = false
    elseif not valid_actions[action] or activation ~= "release" then
       return 
    end

    log_info("Showing hud")
    System.SetCVar('wh_ui_ShowStats', 1)
    System.SetCVar('wh_ui_showCompass', 1)
    System.SetCVar('wh_ui_ShowQAMFood', 1)
    System.SetCVar('wh_ui_ShowQAMWeapon', 1)
    System.SetCVar('wh_ui_ShowBuffs', 1)
    adaptive_hud.force_show_stats = true
    adaptive_hud:start_menu_close_timer()
end
