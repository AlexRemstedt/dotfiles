# WSL GUI apps on VcXsrv, tiled by GlazeWM

Linux GUI apps from WSL (e.g. Zathura, opened by vimtex from nvim) are shown
through VcXsrv, a Windows X server, so GlazeWM can tile them like native
windows. WSLg (the built-in Linux GUI support) is only a fallback for when
VcXsrv isn't running.

## Why not WSLg

WSLg does not work with tiling:

- **Resizes don't reach the app.** When GlazeWM resizes a WSLg window, only the
  Windows-side frame changes. The Linux app keeps drawing at its old size, so
  the tile shows a small window with blank space (Wayland) or a floating-looking
  box (X11 through WSLg). Resizing the X11 window from Linux works, but it has to
  be re-synced after every layout change (opening/closing windows, resizes).
- **Transparency breaks rendering.** With `other_windows.transparency` enabled,
  unfocused WSLg windows render black or garbled.

With VcXsrv in `-multiwindow` mode, each X window is a regular Win32 window, and
VcXsrv passes Windows-side resizes on to the X app. Tiling then just works.

## How it fits together

```
GlazeWM startup
  └─ scripts/vcxsrv-watcher.ps1 (background)
       ├─ starts VcXsrv if it isn't running
       └─ makes GlazeWM manage new VcXsrv windows

zsh in WSL (conf.d/01_env.zsh)
  └─ DISPLAY=<windows host>:0, GDK_BACKEND=x11, QT_QPA_PLATFORM=xcb,
     WAYLAND_DISPLAY unset   (only if VcXsrv is reachable)
       └─ any GUI app (e.g. nvim → vimtex → zathura)
            └─ VcXsrv → Win32 window "vcxsrv/x X rl" → tiled by GlazeWM
```

### 1. VcXsrv

- Installed with `winget install marha.VcXsrv`.
- Started by the watcher (below) with
  `vcxsrv.exe :0 -multiwindow -clipboard -wgl -ac`
  - `-multiwindow`: one Win32 window per X window (needed for tiling).
  - `-clipboard`: shares the clipboard between X apps and Windows.
  - `-ac`: no X authentication, so access is restricted by the firewall (below).
- DPI override so text is sharp on the 125% monitor. This is a per-user registry
  value (same as Properties → Compatibility → High DPI → "Application"):
  `HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers`
  `"C:\Program Files\VcXsrv\vcxsrv.exe" = "~ HIGHDPIAWARE"`

### 2. Firewall

WSL uses NAT networking, so WSL reaches VcXsrv through the Windows host's
address on the WSL virtual network (e.g. `172.26.48.1`), not `localhost`.
The rules Windows created for VcXsrv ("VcXsrv windows xserver") are limited to
the WSL address range, so other devices on the network can't connect:

```powershell
# Admin PowerShell
Get-NetFirewallRule -DisplayName "VcXsrv windows xserver" |
  Set-NetFirewallRule -Action Allow -RemoteAddress 172.16.0.0/12 -EdgeTraversalPolicy Block
```

- `-EdgeTraversalPolicy Block` is needed because the rules from Windows'
  "allow access" popup default to "defer to user", which can't be combined with
  an address restriction.
- If a Windows update or VcXsrv reinstall recreates these rules, run the command
  again. Check with:
  `Get-NetFirewallRule -DisplayName "VcXsrv windows xserver" | Get-NetFirewallAddressFilter`
- Caveat: a network that itself uses 172.16–31.x addresses (some office networks
  and hotspots) could reach VcXsrv.

### 3. WSL shell (`~/.config/zsh/conf.d/01_env.zsh`, chezmoi-managed)

On WSL, if port 6000 on the Windows host answers within 0.2 s:

- `DISPLAY=<host>:0`, where the host is WSL's default gateway
  (`ip route show default`).
- `GDK_BACKEND=x11` and `QT_QPA_PLATFORM=xcb`, so GTK and Qt apps use X11.
- `WAYLAND_DISPLAY` is unset, so nothing picks WSLg's Wayland.

Otherwise the WSLg defaults stay, so GUI apps still work (untiled) when VcXsrv
is down. The check runs when a shell starts, so shells opened before VcXsrv was
running keep using WSLg until they're restarted.

The check adds about 0.1 s to shell startup. The source is
`~/.local/share/chezmoi/home/private_dot_config/zsh/conf.d/01_env.zsh.tmpl`.

The check itself lives in `~/.local/bin/wsl-xdisplay` (prints `<host>:0` or
exits 1). tmux runs it at server start (`tmux.conf`) and sets the same
variables in its global environment. Without that, panes that tmux starts
directly without a shell (e.g. nvim restored by tmux-resurrect) would keep
WSLg's `DISPLAY=:0`. On WSL, `DISPLAY` is also removed from tmux's
`update-environment`, so attaching from a shell that still has `:0` doesn't
override it. After changing this, restart the tmux server (`tmux kill-server`).

vimtex (`vim.g.vimtex_view_method = "zathura"`) needs nothing extra: nvim and
Zathura inherit the shell's environment.

### 4. GlazeWM

- **`scripts/vcxsrv-watcher.ps1`**, started from `general.startup_commands`
  through `conhost.exe --headless` (no console window). A mutex keeps it to one
  instance, so restarting GlazeWM doesn't start a second copy. It also starts
  VcXsrv only if it's not already running, which avoids VcXsrv's "display
  already in use" error.
  - GlazeWM (3.10.1) doesn't manage VcXsrv windows when they first appear.
    VcXsrv shows the window before it adds the title bar and resize border
    (~15 ms later), and GlazeWM only evaluates the window at that first show.
  - The watcher listens for VcXsrv windows being shown. After 150 ms it checks
    `glazewm query windows`; unmanaged top-level windows with a title bar are
    hidden and re-shown, which makes GlazeWM manage them. Menus and popups are
    left alone.
  - VcXsrv then puts the window back at its original geometry, overriding
    GlazeWM's tile (it can end up floating in place, or overlapping Zebar). So
    the watcher runs `wm-redraw` afterwards to re-apply the tile.
- **Window rule** in `config.yaml`: `set-tiling` for process `vcxsrv` and class
  `vcxsrv/x X rl`. Without it, the re-shown window starts out floating.
- Later resizes and layout changes are handled by VcXsrv itself: the window
  stays inside its tile, below Zebar.

## Troubleshooting

- **App opens but is blurry / on WSLg instead of VcXsrv:** check `echo $DISPLAY`
  in that shell. If it's `:0`, VcXsrv wasn't reachable when the shell started;
  open a new shell.
- **VcXsrv not running:** it's started by the watcher. Check
  `Get-Process vcxsrv`. Restart the watcher by restarting GlazeWM
  (`alt+shift+x`), or run the `shell-exec` command from `startup_commands` by
  hand.
- **WSL can't reach VcXsrv:** test with
  `DISPLAY=$(ip route show default | awk '{print $3}'):0 xdpyinfo | head -1`.
  If that hangs, check the firewall rules (section 2).
- **Window isn't tiled:** focus it and press `alt+t`. If this keeps happening,
  check the watcher is running:
  `Get-CimInstance Win32_Process | ? CommandLine -like "*vcxsrv-watcher*"`.
- **Tiled but in the wrong place / overlapping Zebar:** `alt+shift+w`
  (`wm-redraw`).

## Related config changes

- `window_effects.other_windows.transparency` is enabled. VcXsrv windows render
  fine with it; only WSLg windows (the fallback) go black when unfocused.

- f.lux is ignored by GlazeWM (`ignore` rule on process `flux`) so it keeps its
  own position instead of being centered.
- The old float rule for WSLg windows was removed. WSLg windows (fallback only)
  tile by default, with the resize problem described above.
