## Adaptive HUD

### 🔥 Hardcore Mode:
This version **permanently hides all UI elements except buffs**. Buffs will still automatically disappear after **a few seconds**. The game already provides clear visual and audio cues for stamina and health, such as the screen turning blue and Henry breathing heavily. This is the version I personally use.

### 🛡️ Full Mode:
This version does not permanently hide any UI elements. Instead, the **health bar, stamina bar, minimap, and buffs** will **automatically disappear** after **a few seconds** when closing the player menu (Inventory, Map, etc.). Health and stamina bars will also reappear when they drop below a set threshold.

### 🔧 Customization:
You can modify the settings by editing the Lua script and recompressing the mod:

```
adaptive_hud = {
    -- User preferences
    always_hide_health_stamina = true,
    always_hide_compass = true,
    always_hide_food = true,
    always_hide_weapon = true,
    ui_visibility_after_menu_close_ms = 5000,
    health_threshold = "0.75",
    -- No API function was found to get total stamina, only the current value.
    -- A static threshold was chosen instead.
    stamina_threshold = "75",
    -- END of user preferences
}
```

### 📌 Known Issues:
- The mod does not activate immediately upon loading a save. UI elements will persist until you move around or open/close a menu. This occurs because the game’s `Player:OnInit()` function does not trigger properly.
- Controller support will be added if people request it.

### 📖 Sources:
- [Open Source](https://github.com/rdok/kcd2_adaptive_hud)
- [VS Code Lua Runner](https://www.nexusmods.com/kingdomcomedeliverance2/mods/459)
- [Lua API from KCD 1](https://warhorse.nexusmods.com/)
- Lua examples from KCD 2; extract the PAK files, open with your favorite IDE, and search globally for Lua files.