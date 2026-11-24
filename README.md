![Hide names when hiding UI](Assets/banner.webp)

### **Supports WoW: Forever!**

Tired of creature and player names ruining your beautiful screenshots?

This simple addon hides these things away when you toggle your UI off (default ALT+Z)

![Comparison between addon on and addon off](Assets/demo.webp)

### Controls

| Setting                              | Minimap button      | Slash commands                                         |
| ------------------------------------ | ------------------- | ------------------------------------------------------ |
| Enable or disable the addon          | Left-click          | `/hidenames on` or `/hidenames off`                    |
| Player names while the UI is hidden  | Right-click         | `/hidenames players hide` or `/hidenames players show` |
| Interact glow while the UI is hidden | Shift + right-click | `/hidenames glow hide` or `/hidenames glow show`       |
| Combat text while the UI is hidden   | Ctrl + right-click  | `/hidenames combat hide` or `/hidenames combat show`   |

All settings are saved between sessions.

The minimap button shows the right-click controls while HideNames is enabled.

For player names, **SHOW** uses your normal name, guild, title and nameplate settings.

For interact glow, **SHOW** is the default and keeps the Interact key working while the UI is hidden. **HIDE** suppresses the glow and pauses the Interact key.  
(If you like **fishing** with your UI hidden and use the interact key to reel in, you will want this setting to be **SHOW**!)

For combat text, **HIDE** is the default and hides Blizzard's floating damage, healing and absorb numbers. **SHOW** uses your normal combat text settings. Good for action shots without text cluttering the screen :D

Use `/hidenames` to see your current settings and available commands.

![Minimap Button](Assets/bonus.webp)

### Notes on dependency

CurseForge installs LibDBIcon separately for the minimap button.

Manual ZIP users can install LibDBIcon themselves or use an embedded version provided by another add-on.

Without the library, hiding names with Alt+Z still works, but the minimap button won't be there.
