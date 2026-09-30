# Runs in the background (started by GlazeWM, see config.yaml) and:
#   1. starts VcXsrv if it isn't running yet;
#   2. makes GlazeWM manage new VcXsrv windows.
#
# GlazeWM misses VcXsrv windows when they first appear: VcXsrv shows them
# before adding the title bar and resize border (~15 ms later). Hiding and
# re-showing an unmanaged window makes GlazeWM pick it up. VcXsrv then resets the window to its original geometry, so a
# `wm-redraw` afterwards re-applies the tile.
#
# See ../docs/zathura-vcxsrv.md.

$vcxsrv = "$env:ProgramFiles\VcXsrv\vcxsrv.exe"
$vcxsrvArgs = ":0 -multiwindow -clipboard -wgl -ac"

# Only one watcher at a time (e.g. after a GlazeWM restart).
$mutex = New-Object System.Threading.Mutex($false, "Local\glazewm-vcxsrv-watcher")
if (-not $mutex.WaitOne(0)) { exit }

if (-not (Get-Process vcxsrv -ErrorAction SilentlyContinue)) {
  Start-Process $vcxsrv $vcxsrvArgs
}

Add-Type @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

public static class VcXsrvWatcher {
  delegate void WinEventProc(IntPtr hook, uint ev, IntPtr hwnd, int idObject,
    int idChild, uint thread, uint time);

  [DllImport("user32.dll")] static extern IntPtr SetWinEventHook(uint min,
    uint max, IntPtr mod, WinEventProc proc, uint pid, uint tid, uint flags);
  [DllImport("user32.dll")] static extern int GetClassName(IntPtr h,
    StringBuilder s, int n);
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr h, uint cmd);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] static extern uint MsgWaitForMultipleObjects(
    uint n, IntPtr[] handles, bool all, uint ms, uint mask);
  [DllImport("user32.dll")] static extern bool PeekMessage(out MSG m,
    IntPtr h, uint min, uint max, uint remove);
  [DllImport("user32.dll")] static extern bool TranslateMessage(ref MSG m);
  [DllImport("user32.dll")] static extern IntPtr DispatchMessage(ref MSG m);

  [StructLayout(LayoutKind.Sequential)] struct MSG {
    public IntPtr hwnd; public uint message; public IntPtr wParam;
    public IntPtr lParam; public uint time; public int x; public int y;
  }

  const uint EVENT_OBJECT_SHOW = 0x8002;
  const uint WINEVENT_OUTOFCONTEXT = 0;
  const int WS_CAPTION = 0x00C00000;
  const int WS_EX_TOOLWINDOW = 0x80;
  const uint GW_OWNER = 4;

  static readonly WinEventProc Proc = OnShow;
  static readonly Dictionary<IntPtr, DateTime> Pending =
    new Dictionary<IntPtr, DateTime>();
  static readonly Dictionary<IntPtr, int> Attempts =
    new Dictionary<IntPtr, int>();

  // Top-level VcXsrv windows with a title bar. Skips menus/popups, which
  // GlazeWM should leave alone.
  static bool IsAppWindow(IntPtr h) {
    return IsVcXsrvWindow(h)
      && (GetWindowLong(h, -16) & WS_CAPTION) == WS_CAPTION
      && (GetWindowLong(h, -20) & WS_EX_TOOLWINDOW) == 0
      && GetWindow(h, GW_OWNER) == IntPtr.Zero;
  }

  static bool IsVcXsrvWindow(IntPtr h) {
    var c = new StringBuilder(64);
    GetClassName(h, c, 64);
    return c.ToString() == "vcxsrv/x X rl";
  }

  // Styles aren't final yet when the window is shown, so IsAppWindow is
  // checked later in ProcessPending.
  static void OnShow(IntPtr hook, uint ev, IntPtr hwnd, int idObject,
      int idChild, uint thread, uint time) {
    if (idObject != 0 || hwnd == IntPtr.Zero || !IsVcXsrvWindow(hwnd)) return;
    Pending[hwnd] = DateTime.Now;
  }

  static string Glazewm(string args) {
    var psi = new ProcessStartInfo("glazewm", args) {
      UseShellExecute = false, RedirectStandardOutput = true,
      CreateNoWindow = true };
    using (var p = Process.Start(psi)) {
      var output = p.StandardOutput.ReadToEnd();
      p.WaitForExit();
      return output;
    }
  }

  static void ProcessPending() {
    var due = new List<IntPtr>();
    foreach (var kv in Pending)
      if ((DateTime.Now - kv.Value).TotalMilliseconds > 150) due.Add(kv.Key);
    if (due.Count == 0) return;
    foreach (var h in due) Pending.Remove(h);

    var managed = new HashSet<long>();
    foreach (Match m in Regex.Matches(Glazewm("query windows"),
        "\"handle\":(\\d+)"))
      managed.Add(long.Parse(m.Groups[1].Value));

    var reshown = false;
    foreach (var h in due) {
      if (managed.Contains(h.ToInt64()) || !IsWindowVisible(h)
          || !IsAppWindow(h)) continue;
      int n; Attempts.TryGetValue(h, out n);
      if (n >= 3) continue;
      Attempts[h] = n + 1;
      ShowWindow(h, 0); // SW_HIDE
      Thread.Sleep(100);
      ShowWindow(h, 5); // SW_SHOW
      reshown = true;
    }
    if (reshown) {
      Thread.Sleep(300);
      Glazewm("command wm-redraw");
    }
  }

  public static void Run() {
    SetWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_SHOW, IntPtr.Zero, Proc,
      0, 0, WINEVENT_OUTOFCONTEXT);
    MSG msg;
    while (true) {
      MsgWaitForMultipleObjects(0, null, false, 100, 0x04FF); // QS_ALLINPUT
      while (PeekMessage(out msg, IntPtr.Zero, 0, 0, 1)) { // PM_REMOVE
        TranslateMessage(ref msg);
        DispatchMessage(ref msg);
      }
      try { ProcessPending(); } catch { }
    }
  }
}
"@

[VcXsrvWatcher]::Run()
