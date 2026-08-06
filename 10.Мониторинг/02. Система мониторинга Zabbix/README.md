# 10.2 Система мониторинга Zabbix

-----------------------------------------------------------------------------------------------------------------

## Задание 1

Установите *Zabbix Server* с веб-интерфейсом.

### Процесс выполнения:

Выполняя ДЗ, сверяйтесь с процессом отражённым в записи лекции.

1. Установите *PostgreSQL*. Для установки достаточна та версия, что есть в системном репозитороии *Debian 11*.
2. Пользуясь конфигуратором команд с официального сайта, составьте набор команд для установки последней версии *Zabbix* с поддержкой *PostgreSQL* и *Apache*.
3. Выполните все необходимые команды для установки *Zabbix Server* и *Zabbix Web Server*.

### Требования к результатам:

Прикрепите в файл README.md скриншот авторизации в админке.

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)

![alt text](<Screenshots/Задание 1-3.png>)

![alt text](<Screenshots/Задание 1-4.png>)

![alt text](<Screenshots/Задание 1-5.png>)

![alt text](<Screenshots/Задание 1-6.png>)

![alt text](<Screenshots/Задание 1-7.png>)

![alt text](<Screenshots/Задание 1-8.png>)

![alt text](<Screenshots/Задание 1-9.png>)


Приложите в файл README.md текст использованных команд в GitHub.

```

sudo apt update
sudo apt upgrade -y
sudo apt install postgresql
sudo wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_6.0+debian11_all.deb
sudo dpkg -i zabbix-release_latest_6.0+debian11_all.deb
sudo apt update
sudo apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-apache-conf zabbix-sql-scripts
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '123457';"
sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;"
sudo zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
sudo sed -i 's/^DBPassword=.*/DBPassword=123457/' /etc/zabbix/zabbix_server.conf
sudo grep '^DBPassword=' /etc/zabbix/zabbix_server.conf
sudo systemctl restart zabbix-server apache2
sudo systemctl enable zabbix-server apache2
sudo systemctl status zabbix-server.service

```

--------------------------------------------------------------------------------------------------------------

## Задание 2

Установите *Zabbix Agent* на два хоста.

### Процесс выполнения:

Выполняя ДЗ, сверяйтесь с процессом отражённым в записи лекции.

1. Установите *Zabbix Agent* на 2 вирт.машины, одной из них может быть ваш *Zabbix Server*.
2. Добавьте *Zabbix Server* в список разрешенных серверов ваших *Zabbix Agentоv*.
3. Добавьте *Zabbix Agentоv* в раздел Configuration > Hosts вашего *Zabbix Servera*.
4. Проверьте, что в разделе *Latest Data* начали появляться данные с добавленных агентов.

### Требования к результатам:

Приложите в файл README.md скриншот раздела Configuration > Hosts, где видно, что агенты подключены к серверу
Приложите в файл README.md скриншот лога zabbix agent, где видно, что он работает с сервером
Приложите в файл README.md скриншот раздела Monitoring > Latest data для обоих хостов, где видны поступающие от агентов данные.
Приложите в файл README.md текст использованных команд в GitHub

### Решение:

Установливаем *Zabbix Agent* на два хоста. На одной машине Zabbix server + Agent1, а на второй машине -Agent2

![alt text](<Screenshots/Задание 2-1.png>)

Подключаемся к виртуальным машинам по ssh

![alt text](<Screenshots/Задание 2-2.png>)

Правим конфигурацию агентов в  /etc/zabbix/xabbix_agentd.conf и перезапускаем агенты.

![alt text](<Screenshots/Задание 2-3.png>)

Проверяем статус установленных двух агентов

![alt text](<Screenshots/Задание 2-4.png>)

Проверяем конфигурацию установленных двух агентов

![alt text](<Screenshots/Задание 2-5.png>)

Скриншот раздела Configuration > Hosts, где видно, что агенты подключены к серверу

![alt text](<Screenshots/Задание 2-6.png>)

Скриншот лога zabbix agent, где видно, что он работает с сервером

![alt text](<Screenshots/Задание 2-7.png>)

Скриншот раздела Monitoring > Latest data для обоих хостов, где видны поступающие от агентов данные.

![alt text](<Screenshots/Задание 2-8.png>)

![alt text](<Screenshots/Задание 2-9.png>)

Использованные команды в GitHub

```
sudo apt update
sudo apt upgrade -y
sudo wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_6.0+debian11_all.deb
sudo dpkg -i zabbix-release_latest_6.0+debian11_all.deb
sudo apt update
sudo apt install zabbix-agent
sudo systemctl enable zabbix-agent
sudo systemctl status zabbix-agent.service

```

--------------------------------------------------------------------------------------------------------------
