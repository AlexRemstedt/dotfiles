# Windows Terminal

Windows Terminal profiles are managed through a [JSON fragment
extension](https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions)
rather than by chezmoi owning `settings.json` directly. Windows Terminal
generates and rewrites `settings.json` itself (dynamic WSL/Azure profiles,
GUIDs, window state), so replacing it wholesale on every `chezmoi apply` would
fight the app instead of working with it. Fragments are the mechanism Windows
Terminal ships specifically for third parties to contribute profiles and color
schemes without touching that file.

## What's managed here

`home/AppData/Local/Microsoft/Windows Terminal/Fragments/chezmoi/profiles.json`
(this repo's `.chezmoiignore` keeps it Windows-only) does two things:

- Defines a **Nord** color scheme, matching the theme already used for
  `LS_COLORS` in the zsh config (see
  `home/private_dot_config/zsh/conf.d/06_prompt.zsh.tmpl`).
- Updates the auto-generated **Ubuntu** WSL profile to use that scheme and
  JetBrainsMono Nerd Font (see [`.docs/fonts`](../fonts/README.md)).

Windows Terminal picks up fragment files automatically — no reload/restart
beyond opening a new tab is needed. If you rename the WSL distro away from
"Ubuntu", the profile GUID below needs recomputing (see the [profile GUID
docs](https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions#profile-guids));
the one used here (`{2c4de342-38b7-51cf-b940-2309a097f518}`) is the
well-known GUID Windows Terminal generates for a WSL distro literally named
"Ubuntu".

## What isn't managed here

Fragments can only add/update profiles and color schemes — they can't touch
top-level settings like `defaultProfile`, `theme`, or `keybindings`. Those
live in `settings.json` itself
(`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
for the standard Store/winget install), which is edited by hand:

```json
{
  "defaultProfile": "{2c4de342-38b7-51cf-b940-2309a097f518}",
  "theme": "dark"
}
```

Keybindings are left as whatever you already have — add to the `"actions"`
list in the same file if you want custom ones.
