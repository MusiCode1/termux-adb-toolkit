#!/data/data/com.termux/files/usr/bin/python
# Print the port of the _adb-tls-connect._tcp mDNS service (wireless debugging).
# Same discovery Shizuku uses (Android NSD). No brute-force, no rish.
from zeroconf import Zeroconf, ServiceBrowser
import time, sys
res = {}
class L:
    def add_service(self, zc, t, name):
        i = zc.get_service_info(t, name, timeout=2500)
        if i and i.port:
            res["port"] = i.port
    def update_service(self, *a): pass
    def remove_service(self, *a): pass
zc = Zeroconf()
ServiceBrowser(zc, "_adb-tls-connect._tcp.local.", L())
for _ in range(70):
    if "port" in res: break
    time.sleep(0.1)
zc.close()
if "port" in res:
    print(res["port"])
else:
    sys.exit(1)
