import redis
from datetime import datetime

REDIS_HOST = "127.0.0.1"
REDIS_PORT = 6379
KEY = "key5"
INIT_VAL = 5
INCREMENT = 5

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def main():
    log("Подключение к Redis...")
    try:
        r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, socket_timeout=2, socket_connect_timeout=2)
        r.ping()
        log("✅ Соединение с Redis установлено.")
    except Exception as e:
        log(f"❌ Не удалось подключиться к Redis: {e}")
        return

    # Шаг 1: запись числа 5
    log(f"--- Шаг 1: SET {KEY} = {INIT_VAL} ---")
    r.set(KEY, INIT_VAL)
    log("✅ Ключ установлен.")

    # Проверка начального значения
    val_before = r.get(KEY)
    if val_before is not None:
        val_before_int = int(val_before)
        log(f"Текущее значение: {val_before_int}")
    else:
        log("⚠️ Ключ не найден.")
        return

    # Шаг 2: атомарное увеличение на 5
    log(f"--- Шаг 2: INCRBY {KEY} {INCREMENT} ---")
    new_val = r.incrby(KEY, INCREMENT)
    log(f"Результат INCRBY: {new_val} (это и есть новое значение ключа)")

    # Шаг 3: финальная проверка
    log("--- Шаг 3: финальная проверка GET ---")
    val_after = r.get(KEY)
    if val_after is not None:
        val_after_int = int(val_after)
        log(f"Финальное значение (GET): {val_after_int}")
    else:
        log("⚠️ Ключ удалён или не найден.")
        return

    # Итог
    print("\n" + "=" * 60)
    if new_val == 10 and val_after_int == 10:
        print("🎉 ЗАДАНИЕ ВЫПОЛНЕНО: key5 = 10")
    else:
        print(f"⚠️ Результат отличается от ожидаемого: key5 = {val_after_int}")
    print("=" * 60)

    # Для полноты картины: тип ключа и список ключей
    log("--- Дополнительная проверка (для отчёта) ---")
    log(f"TYPE {KEY}: {r.type(KEY)}")
    log(f"KEYS *: {r.keys('*')}")

if __name__ == "__main__":
    main()
