adaptive_hud = {
    -- User preferences
    always_hide_health_stamina = false,
    always_hide_compass = false,
    always_hide_food = false,
    always_hide_weapon = false,
    ui_visibility_after_menu_close_ms = 5000,
    health_threshold = "0.75",
    -- No API function to get the total stamina was found, only the current one.
    --   A static was picked instead
    stamina_threshold = "75",
    -- END of user preferences

    show_stats_upon_menu_close = false,
    stats_execution_interval_ms = "1000",
    stats_timer_id = nil,
    menu_close_timer_id = nil,
    first_on_action_executed = true,
    onload_executed = false,
}

local log_prefix = "adaptive_hud"

local function log_error(message, ...)
    local formatted_message = string.format("$4[%s.ERROR] " .. message, log_prefix, ...)
    System.LogAlways(formatted_message)
end

local function log_info(message, ...)
    local formatted_message = string.format("$5[%s.INFO] " .. message, log_prefix, ...)
    System.LogAlways(formatted_message)
end

log_info("Mod loaded.")

function adaptive_hud:StatsTimerOnLoad()
    if self.onload_executed then return end
    log_info("OnLoad")
    self.onload_executed = true
    self:start_stats_timer(tonumber(self.stats_execution_interval_ms))
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

function adaptive_hud:get_show_stats()
    log_info("get_show_stats called")
    local showStats = self.always_hide_health_stamina and "0" or (self:has_low_stats() and "1" or "0")

    log_info(string.format("Calculated showStats: %s", showStats))
    return showStats
end

function adaptive_hud:updateStats()
    log_info("updateStats called")
    if self.show_stats_upon_menu_close then
        log_info("updateStats - force show stats enabled")
        self:start_stats_timer(tonumber(self.stats_execution_interval_ms))
        return
    end
    log_info("System.SetCVar('wh_ui_ShowStats")
    System.SetCVar('wh_ui_ShowStats', self:get_show_stats())
    log_info("updateStats completed, restarting timer")
    self:start_stats_timer(tonumber(self.stats_execution_interval_ms))
end

function adaptive_hud:start_stats_timer(interval_ms)
    log_info("start_stats_timer")
    if self.stats_timer_id then Script.KillTimer(self.stats_timer_id) end
    self.stats_timer_id = Script.SetTimer(interval_ms, function(nTimerId)
        log_info("start_stats_timer.callback")
        self:updateStats()
    end)
end

function adaptive_hud:start_menu_close_timer()
    log_info("start_menu_close_timer called")
    if self.menu_close_timer_id then
        Script.KillTimer(self.menu_close_timer_id)
    end
    self.menu_close_timer_id = Script.SetTimer(adaptive_hud.ui_visibility_after_menu_close_ms, function(nTimerId)
        log_info("start_menu_close_timer.callback")
        self.show_stats_upon_menu_close = false
        System.SetCVar('wh_ui_ShowStats', self:get_show_stats())
        System.SetCVar('wh_ui_ShowStats', "0")
        System.SetCVar('wh_ui_showCompass', "0")
        System.SetCVar('wh_ui_ShowQAMFood', "0")
        System.SetCVar('wh_ui_ShowQAMWeapon', "0")
        System.SetCVar('wh_ui_ShowBuffs', "0")
        self.menu_close_timer_id = nil
    end)
end

local original_OnAction = Player.OnAction

function Player:OnAction(action, activation, value)
    if original_OnAction then
        local success, result = pcall(original_OnAction, self, action, activation, value)
        if not success then
            log_error("Error in original Player:OnAction: " .. tostring(result))
        end
    end

    adaptive_hud:StatsTimerOnLoad()

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
        log_info("Player:OnAction first_on_action_executed")
    elseif not valid_actions[action] or activation ~= "release" then
        return
    end
    System.SetCVar('wh_ui_ShowStats', adaptive_hud.always_hide_health_stamina and "0" or "1")
    System.SetCVar('wh_ui_showCompass', adaptive_hud.always_hide_compass and "0" or "1")
    System.SetCVar('wh_ui_ShowQAMFood', adaptive_hud.always_hide_food and "0" or "1")
    System.SetCVar('wh_ui_ShowQAMWeapon', adaptive_hud.always_hide_weapon and "0" or "1")
    System.SetCVar('wh_ui_ShowBuffs', "1")
    adaptive_hud.show_stats_upon_menu_close = true
    adaptive_hud:start_menu_close_timer()
end

local original_OnInit = Player.OnInit

function Player:OnInit()
    log_info("Player:OnInit")

    if original_OnInit then
        local success, result = pcall(original_OnInit, self)
        if not success then
            log_error("Error in original Player:OnInit: " .. tostring(result))
        end
    end

    adaptive_hud:StatsTimerOnLoad()
end