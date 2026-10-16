from pymemcache.client import base
import time

client = base.Client(('127.0.0.1', 11211))

keys = ["key1", "key2", "key3"]
value = "Hello World!"
ttl = 5


for k in keys:
    client.set(k, value, expire=ttl)
    print(f"Set key={k}, value={value}, ttl={ttl}")

print("\nПроверка сразу после записи:")
for k in keys:
    val = client.get(k)
    print(f"key={k} -> {val}")

print(f"\nЖдём {ttl} секунд...")
time.sleep(ttl)

print("\nПроверка после истечения TTL:")
for k in keys:
    val = client.get(k)
    if val is None:
        print(f"key={k} -> удалён (None)")
    else:
        print(f"key={k} -> всё ещё есть: {val}")
