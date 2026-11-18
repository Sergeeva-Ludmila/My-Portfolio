#!/bin/bash
# Лабораторная: ограничение подменённого man (ping) через AppArmor
# Полностью автоматический прогон, без пауз.

run() {
    echo -e "\e[1;36m\$ $*\e[0m"
    bash -c "$*"
    echo -e "\e[1;33mкод возврата: $?\e[0m"
    echo
}

echo "=== ШАГ 1. Установка пакетов и проверка загрузки модуля AppArmor ==="
run "sudo apt update"
run "sudo apt install apparmor apparmor-utils strace build-essential -y"
run "dmesg | grep -i 'apparmor' | head -3"
run "sudo apparmor_status | head -6"

echo "=== ШАГ 2. Доступные профили ==="
run "ls /etc/apparmor.d/"

echo "=== ШАГ 3. Резервная копия man и подмена на ping ==="
run "sudo cp /usr/bin/man /usr/bin/man1"
run "sudo cp /bin/ping /usr/bin/man"

echo "=== ШАГ 4. Запуск ДО применения профиля (пинг проходит) ==="
run "sudo man 127.0.0.1 -c 3"

echo "=== ШАГ 5. Создание профиля /etc/apparmor.d/man и перевод в enforce ==="
run "sudo tee /etc/apparmor.d/man <<'EOF'
#include <tunables/global>

/usr/bin/man {
  #include <abstractions/base>
  deny network inet stream,
  deny network inet dgram,
  deny network inet raw,
  deny capability net_raw,
}
EOF"
run "sudo apparmor_parser -rT /etc/apparmor.d/man"
run "sudo aa-enforce man"
run "sudo grep -w 'usr/bin/man' /sys/kernel/security/apparmor/profiles"

echo "=== ШАГ 6. Пинг под профилем, диапазон НЕ сужен ==="
run "echo '0 2147483647' | sudo tee /proc/sys/net/ipv4/ping_group_range"
run "sudo man 127.0.0.1 -c 3; echo код=\$?"

echo "=== ШАГ 7. Закрываем лазейку: сужаем ping_group_range ==="
run "echo '1 0' | sudo tee /proc/sys/net/ipv4/ping_group_range"
run "sudo man 127.0.0.1; echo код=\$?"

echo "=== ШАГ 8. Видимый отказ ядра через strace ==="
run "sudo strace -e trace=socket man 127.0.0.1 2>&1 | tail -5"

echo "=== ШАГ 9. Тестовая программа: текст ошибки вместо молчания ==="
run "sudo tee /tmp/socktest.c <<'EOF'
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>

int main(void) {
    int d = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    printf(\"dgram: %s\\n\", d < 0 ? strerror(errno) : \"OK\");
    int r = socket(AF_INET, SOCK_RAW | SOCK_CLOEXEC, IPPROTO_ICMP);
    printf(\"raw:   %s\\n\", r < 0 ? strerror(errno) : \"OK\");
    return 0;
}
EOF"
run "sudo gcc /tmp/socktest.c -o /usr/bin/man"
run "sudo man 127.0.0.1; echo код=\$?"

echo "=== ШАГ 10. Контроль: легитимный ping не пострадал ==="
run "sudo cp /bin/ping /usr/bin/man"
run "ping -c1 127.0.0.1; echo код=\$?"

echo "=== ШАГ 11. Отключение AppArmor ==="
run "echo '0 2147483647' | sudo tee /proc/sys/net/ipv4/ping_group_range"
run "sudo aa-teardown"
run "sudo systemctl stop apparmor"
run "sudo systemctl disable apparmor"
run "sudo man 127.0.0.1 -c 3"

echo "=== ШАГ 12. Удаление AppArmor ==="
run "sudo apt remove --purge apparmor apparmor-utils -y"
run "sudo aa-status 2>&1 || true"

echo "=== ШАГ 13. Возврат стенда и уборка ==="
run "sudo mv /usr/bin/man1 /usr/bin/man 2>/dev/null || true"
run "sudo apt install --reinstall man-db -y"
run "sudo rm -f /etc/apparmor.d/man /tmp/socktest.c /usr/bin/man1"
run "man --help | head -2"
run "cat /proc/sys/net/ipv4/ping_group_range"

echo "=== Лабораторная завершена, стенд в исходном состоянии ==="
