#!/data/data/com.termux/files/usr/bin/python
# adb-panel.py — native Termux:GUI window hosting a WebView UI for the ADB toolkit.
# Full HTML/CSS design, no server, no browser app. Two-way bridge:
#   page -> script : console.log("ACT:<name>")  (webviewConsoleMessage / navigation)
#   script -> page : webview.evaluatejs("render(...)")
import subprocess, os, re, json, base64
import termuxgui as tg

BIN    = os.path.expanduser("~/termux-adb-toolkit/bin")
DBG    = os.path.expanduser("~/.cache/adb-panel.log")
def dbg(s):
    print(s, flush=True)                       # live in the tmux terminal
    try: open(DBG, "a").write(str(s) + "\n")   # and to a log the agent can read
    except Exception: pass
PORT   = "5588"
TUNNEL = "termux-phone-oneplus-15"
SVC    = "/data/data/com.termux/files/usr/var/service/cloudflared"

def sh(cmd, timeout=90, shell=False):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, shell=shell)
        return p.returncode, (p.stdout + p.stderr).strip()
    except Exception as e:
        return 1, str(e)

def adb_state():
    rc, out = sh(["adb", "-s", f"localhost:{PORT}", "shell", "getprop", "ro.product.model"], 12)
    if rc == 0 and out:
        return {"ok": True, "text": f"{out.strip()} · localhost:{PORT}"}
    return {"ok": False, "text": "לא מחובר"}

def shizuku_state():
    rc, out = sh("RISH_APPLICATION_ID=com.termux rish -c 'id -u' 2>/dev/null", 10, shell=True)
    ok = out.strip().endswith("2000")
    return {"ok": ok, "text": "פעיל (uid 2000)" if ok else "לא רץ"}

def tunnel_state():
    rc, out = sh(["cloudflared", "tunnel", "info", TUNNEL], 20)
    edges = []
    for line in out.splitlines():
        parts = line.split()
        if parts and re.match(r"^[0-9a-f]{8}-[0-9a-f]{4}-", parts[0]):
            edges.append(parts[-1])
    if edges:
        return {"ok": True, "text": f"{len(edges)} connector · edges {edges[0]}"}
    return {"ok": False, "text": "אין connector פעיל (API)"}

def full_state():
    return {"adb": adb_state(), "shizuku": shizuku_state(), "tunnel": tunnel_state()}

HTML = r"""<!doctype html><html lang="he" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
:root{--bg:#0b1120;--card:#131c31;--line:#243149;--txt:#e8eefc;--dim:#93a4c4;
--ok:#37d399;--bad:#f87171;--accent:#6ea8fe;--accent2:#3b5bdb}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{margin:0;font-family:system-ui,sans-serif;background:
linear-gradient(160deg,#0b1120,#0e1730 60%,#101a36);color:var(--txt);padding:14px}
h1{font-size:19px;margin:2px 0 14px;display:flex;align-items:center;gap:8px}
h1 .lock{filter:drop-shadow(0 0 6px #6ea8fe66)}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;
padding:12px 14px;margin-bottom:10px;display:flex;align-items:center;gap:12px}
.dot{width:11px;height:11px;border-radius:50%;flex:0 0 auto;box-shadow:0 0 8px}
.dot.ok{background:var(--ok);box-shadow:0 0 8px var(--ok)}
.dot.bad{background:var(--bad);box-shadow:0 0 8px var(--bad)}
.dot.wait{background:#f5c451;box-shadow:0 0 8px #f5c451;animation:p 1s infinite}
@keyframes p{50%{opacity:.35}}
.card .k{font-weight:600;font-size:14px}
.card .v{color:var(--dim);font-size:12.5px;margin-top:2px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin:4px 0 12px}
button{font:inherit;font-size:14px;font-weight:600;color:var(--txt);
background:linear-gradient(180deg,#1c2a49,#16223c);border:1px solid var(--line);
border-radius:13px;padding:13px 10px;cursor:pointer;transition:.12s;
display:flex;align-items:center;justify-content:center;gap:7px}
button:active{transform:scale(.97);border-color:var(--accent)}
button.p{background:linear-gradient(180deg,var(--accent),var(--accent2));border:0}
button:disabled{opacity:.5}
.log{background:#070c17;border:1px solid var(--line);border-radius:13px;
padding:11px;font-family:ui-monospace,monospace;font-size:11.5px;line-height:1.5;
color:#b9c8e6;white-space:pre-wrap;height:180px;overflow:auto;direction:ltr}
.spin{width:13px;height:13px;border:2px solid #ffffff55;border-top-color:#fff;
border-radius:50%;animation:s .7s linear infinite;display:none}
@keyframes s{to{transform:rotate(360deg)}}
.busy .spin{display:inline-block}
</style></head><body>
<h1><span class="lock">🔌</span> ‏ADB Toolkit</h1>

<div class="card"><span id="d_adb" class="dot wait"></span>
<div><div class="k">‏ADB</div><div class="v" id="v_adb">בודק…</div></div></div>
<div class="card"><span id="d_shz" class="dot wait"></span>
<div><div class="k">Shizuku</div><div class="v" id="v_shz">בודק…</div></div></div>
<div class="card"><span id="d_tun" class="dot wait"></span>
<div><div class="k">‏Cloudflare Tunnel</div><div class="v" id="v_tun">בודק…</div></div></div>

<div class="grid">
<button class="p" onclick="act('fixport')"><span class="spin"></span>⚡ Fix Port</button>
<button onclick="act('refresh')">↻ רענן</button>
<button onclick="act('disconnect')">⏏ נתק ADB</button>
<button onclick="act('shizuku')">🔁 Shizuku</button>
<button onclick="act('tunnel_up')">🌐 Tunnel ↑</button>
<button onclick="act('tunnel_down')">⤓ Tunnel ↓</button>
</div>

<div class="log" id="log">מוכן.</div>

<script>
function act(a){
  if(a==='fixport'){document.body.classList.add('busy');}
  console.log('ACT:'+a);
}
function dot(id,ok){var e=document.getElementById(id);
  e.className='dot '+(ok?'ok':'bad');}
function render(s){
  dot('d_adb',s.adb.ok); document.getElementById('v_adb').textContent=s.adb.text;
  dot('d_shz',s.shizuku.ok); document.getElementById('v_shz').textContent=s.shizuku.text;
  dot('d_tun',s.tunnel.ok); document.getElementById('v_tun').textContent=s.tunnel.text;
  document.body.classList.remove('busy');
}
function logln(t){var l=document.getElementById('log');
  l.textContent+=t+'\n'; l.scrollTop=l.scrollHeight;}
function busy(on){document.body.classList.toggle('busy',on);}
window.addEventListener('load',function(){
  console.log('LOADED bg='+getComputedStyle(document.body).backgroundColor
    +' h='+document.body.offsetHeight);
});
window.onerror=function(m,s,l){console.log('JSERR '+m+' @'+l);};
</script></body></html>"""

def js(code):
    try: wv.evaluatejs(code)
    except Exception: pass

def push_state():
    js("render(" + json.dumps(full_state()) + ")")

def run_action(a):
    if a == "refresh":
        push_state(); return
    busy = 'busy(true)'; js(busy)
    if a == "fixport":
        rc, out = sh([BIN + "/adb-fix-port"], 90)
    elif a == "disconnect":
        rc, out = sh(["adb", "disconnect"], 15)
    elif a == "shizuku":
        rc, out = sh(BIN + "/../shortcuts/adbtool-start.sh 2>/dev/null; "
                     "APK=$(adb -s localhost:5588 shell pm path moe.shizuku.privileged.api 2>/dev/null | sed 's/package://' | tr -d '\\r' | head -1); "
                     "[ -n \"$APK\" ] && adb -s localhost:5588 shell \"$(dirname $APK)/lib/arm64/libshizuku.so\"", 30, shell=True)
    elif a == "tunnel_up":
        rc, out = sh(["sv", "up", SVC], 15)
    elif a == "tunnel_down":
        rc, out = sh(["sv", "down", SVC], 15)
    else:
        rc, out = 1, "unknown action"
    js("logln(" + json.dumps(f"$ {a}\n{out}") + ")")
    push_state()

with tg.Connection() as c:
    a = tg.Activity(c)
    root = tg.LinearLayout(a)
    wv = tg.WebView(a, root)
    wv.setlinearlayoutparams(1)
    wv.allowjavascript(True)
    wv.allownavigation(True)
    wv.handleevent(tg.Event.webviewNavigation)
    wv.handleevent(tg.Event.webviewConsoleMessage)
    for _e in ("webviewError", "webviewHTTPError", "webviewProgress"):
        try: wv.handleevent(getattr(tg.Event, _e))
        except Exception: pass
    _b64 = base64.b64encode(HTML.encode("utf-8")).decode()
    wv.loaduri("data:text/html;base64," + _b64)

    push_state()

    try:
        for ev in c.events():
            blob = json.dumps(ev.value) if isinstance(ev.value, (dict, list)) else str(ev.value)
            dbg(f"EV {ev.type} :: {blob}")
            if ev.type in (tg.Event.destroy, tg.Event.back):
                break
            if ev.type in (tg.Event.webviewConsoleMessage, tg.Event.webviewNavigation):
                m = re.search(r"ACT:([a-z_]+)", blob)
                if m:
                    run_action(m.group(1))
    finally:
        a.finish()
