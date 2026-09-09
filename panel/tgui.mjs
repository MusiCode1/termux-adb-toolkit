// ⚠️ Node.js ONLY. Bun on Termux runs under a proot/glibc-runner wrapper that
// isolates Linux abstract-namespace unix sockets — which this protocol requires
// (am-socket broadcast + our client sockets). Bun cannot speak it here; use `node`.
// tgui.mjs — minimal Node.js binding for the Termux:GUI plugin.
// Protocol reverse-learned from the official Python binding (ground truth) + Protocol.md.
// Scope: just what an all-JS WebView panel needs — connect, activity, webview, events.
import net from "node:net";
import { execFile } from "node:child_process";
import { randomBytes } from "node:crypto";

const rnd = (n) =>
  randomBytes(96).toString("base64").replace(/[^a-zA-Z0-9]/g, "").slice(0, n);

// listen on an abstract-namespace unix socket, resolve with (server, firstConnPromise)
function listenAbstract(addr) {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    const conn = new Promise((res) => srv.once("connection", res));
    srv.on("error", reject);
    srv.listen("\0" + addr, () => resolve({ srv, conn }));
  });
}

// read exactly n bytes from a stream that we buffer manually
class FrameReader {
  constructor(sock) {
    this.buf = Buffer.alloc(0);
    this.waiters = [];
    sock.on("data", (d) => {
      this.buf = Buffer.concat([this.buf, d]);
      this._pump();
    });
  }
  _pump() {
    while (true) {
      if (this.buf.length < 4) return;
      const len = this.buf.readUInt32BE(0);
      if (this.buf.length < 4 + len) return;
      const payload = this.buf.subarray(4, 4 + len);
      this.buf = this.buf.subarray(4 + len);
      const msg = JSON.parse(payload.toString("utf8"));
      const w = this.waiters.shift();
      if (w) w(msg);
      else (this.queue ??= []).push(msg);
    }
  }
  next() {
    if (this.queue && this.queue.length) return Promise.resolve(this.queue.shift());
    return new Promise((res) => this.waiters.push(res));
  }
}

function frame(sock, obj) {
  const body = Buffer.from(JSON.stringify(obj), "utf8");
  const hdr = Buffer.alloc(4);
  hdr.writeUInt32BE(body.length, 0);
  sock.write(hdr);
  sock.write(body);
}

export class TGUI {
  async connect() {
    const adrMain = rnd(50), adrEvent = rnd(50);
    const m = await listenAbstract(adrMain);
    const e = await listenAbstract(adrEvent);
    const broadcast = (bin) =>
      new Promise((res) => execFile(bin, [
        "broadcast", "-n", "com.termux.gui/.GUIReceiver",
        "--es", "mainSocket", adrMain, "--es", "eventSocket", adrEvent,
      ], () => res()));
    await broadcast("termux-am");
    const withTimeout = (p, ms) =>
      Promise.race([p, new Promise((_, rej) => setTimeout(() => rej(new Error("timeout")), ms))]);
    let main, event;
    try {
      main = await withTimeout(m.conn, 5000);
      event = await withTimeout(e.conn, 5000);
    } catch {
      await broadcast("am");                    // gotcha #2: fallback to full `am`
      main = await withTimeout(m.conn, 8000);
      event = await withTimeout(e.conn, 8000);
    }
    // gotcha #3: Python verifies SO_PEERCRED == our uid. Node can't easily; relaxed on a personal device.
    this.main = main; this.event = event;
    this.eventR = new FrameReader(event);
    main.write(Buffer.from([0x01]));            // gotcha #4: 0x01 = JSON protocol, version 0
    // read the 1-byte ack BEFORE attaching the frame reader, or it corrupts framing:
    const first = await new Promise((res) => main.once("data", (d) => res(d)));
    if (first[0] !== 0) throw new Error("bad protocol handshake: " + first[0]);
    this.mainR = new FrameReader(main);
    if (first.length > 1) { this.mainR.buf = first.subarray(1); this.mainR._pump(); }
    this._q = Promise.resolve();
    return this;
  }
  // gotcha #6: request() reads a reply; notify() does NOT. Mirror send_read_msg vs send_msg exactly.
  request(method, params) {
    const run = async () => { frame(this.main, { method, params }); return this.mainR.next(); };
    this._q = this._q.then(run, run);           // gotcha #7: serialize
    return this._q;
  }
  notify(method, params) { frame(this.main, { method, params }); }

  async *events() { while (true) yield await this.eventR.next(); }

  // --- helpers (reply/no-reply matched to the Python binding) ---
  async newActivity(dialog = false) {
    const r = await this.request("newActivity", { dialog });
    return Array.isArray(r) ? r[0] : r;         // [aid,tid] or aid
  }
  finishActivity(aid) { this.notify("finishActivity", { aid }); }
  async createWebView(aid, parent) {
    const params = { aid }; if (parent !== undefined) params.parent = parent;
    return this.request("createWebView", params); // replies with id
  }
  async allowJavascript(aid, id, allow) { return this.request("allowJavascript", { aid, id, allow }); }
  allowNavigation(aid, id, allow) { this.notify("allowNavigation", { aid, id, allow }); }
  loadURI(aid, id, uri) { this.notify("loadURI", { aid, id, uri }); }
  evaluateJS(aid, id, code) { this.notify("evaluateJS", { aid, id, code }); }
}
