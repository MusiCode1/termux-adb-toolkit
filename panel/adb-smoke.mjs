// adb-smoke.mjs — proves the Node Termux:GUI binding end-to-end: connect,
// create an activity + root WebView, load HTML, and react to close.
import { TGUI } from "./tgui.mjs";

const g = new TGUI();
await g.connect();
console.log("CONNECT OK");
const aid = await g.newActivity(false);
console.log("activity", aid);
const wv = await g.createWebView(aid);          // no parent -> root, fills the activity
console.log("webview", wv);
// NOTE: static HTML needs no JS -> we skip allowJavascript, so NO permission dialog.
// (The "Allow Javascript without dialog" toggle is confirmed non-persistent in Termux:GUI.)

const html = `<!doctype html><html lang="he" dir="rtl"><body style="margin:0;
background:linear-gradient(160deg,#0b1120,#101a36);color:#e8eefc;
font-family:system-ui,sans-serif;display:flex;flex-direction:column;
align-items:center;justify-content:center;height:100vh;text-align:center;gap:12px">
<div style="font-size:46px">✅</div>
<div style="font-size:26px;font-weight:700">Node → Termux:GUI</div>
<div style="color:#6ea8fe;font-size:18px">הביינדינג שכתבנו עובד — הכל JavaScript</div>
</body></html>`;
g.loadURI(aid, wv, "data:text/html;base64," + Buffer.from(html).toString("base64"));
console.log("loaded — window should be visible");

for await (const ev of g.events()) {
  console.log("EV", JSON.stringify(ev));
  if (ev.type === "destroy" || ev.type === "back") break;
}
g.finishActivity(aid);
console.log("done");
process.exit(0);
