# 13.09 Базы данных в облаке

----------------------------------------------------------------------------------------------------------------

## Задание

**1 - Создание кластера**

1) Перейдите на главную страницу сервиса *Managed Service for PostgreSQL.*
2) Создайте кластер *PostgreSQL* со следующими параметрами:
-  хоста: s2.micro, диск network-ssd любого размера;
- хосты: нужно создать два хоста в двух разных зонах доступности и указать необходимость публичного доступа, то есть публичного IP адреса, для них;
- установите учётную запись для пользователя и базы.

*Остальные параметры оставьте по умолчанию либо измените по своему усмотрению.*

- Нажмите кнопку «Создать кластер» и дождитесь окончания процесса создания, статус кластера = RUNNING. Кластер создаётся от 5 до 10 минут.

**2 - Подключение к мастеру и реплике**
- Используйте инструкцию по подключению к кластеру, доступную на вкладке «Обзор»: cкачайте SSL-сертификат и  подключитесь к кластеру с помощью утилиты psql, указав hostname всех узлов и атрибут target_session_attrs=read-write.

- Проверьте, что подключение прошло к master-узлу.
```sql
select case when pg_is_in_recovery() then 'REPLICA' else 'MASTER' end;
```

- Посмотрите количество подключенных реплик:
```sql
select count(*) from pg_stat_replication;
```

**3 - Проверьте работоспособность репликации в кластере**

- Создайте таблицу и вставьте одну-две строки.
```sql
CREATE TABLE test_table(text varchar);
```

```sql
insert into test_table values('Строка 1');
```

- Выйдите из **psql** командой **\q.**

- Теперь подключитесь к узлу-реплике. Для этого из команды подключения удалите атрибут target_session_attrs и в параметре атрибут host передайте только имя хоста-реплики. Роли хостов можно посмотреть на соответствующей вкладке UI консоли.

- Проверьте, что подключение прошло к узлу-реплике.
```sql
select case when pg_is_in_recovery() then 'REPLICA' else 'MASTER' end;
```

- Проверьте состояние репликации
```sql
select status from pg_stat_wal_receiver;
```

- Для проверки, что механизм репликации данных работает между зонами доступности облака, выполните запрос к таблице, созданной на предыдущем шаге:
```sql
select * from test_table;
```

**В качестве результата вашей работы пришлите скриншоты:**
1) Созданной базы данных;
2) Результата вывода команды на реплике **select * from test_table;.**

## Ответ:

**Для выполнения этого задания было проделано:**
1. В Yandex.cloud создан кластер.
2. Установлен postgresql-client — это пакет с клиентскими утилитами для работы с СУБД PostgreSQL.
В него входит:
- psql — интерактивная консоль для SQL: можно писать запросы, смотреть результаты, запускать скрипты. Именно её ты используешь для подключения к кластерам в Яндекс Облаке.
- pg_dump — утилита для выгрузки базы в SQL‑дамп. Полезно для бэкапов тестовых сред и переноса схем между контейнерами.
- pg_restore — восстановление из дампа. Удобно, когда разворачиваешь тестовую БД из бэкапа.
- Прочие утилиты (например, pg_isready для быстрой проверки доступности сервера).
3. Задания выполнялись в VM - Ubuntu 22.04, Yandex.cloud,psql.


**1 - Создаем директорию,скачиваем SSL-сертификат (root.crt). Для подключения к Managed Service for PostgreSQL требуется доверенный сертификат CA.Выдаем права:**
```bash
- mkdir -p ~/.postgresql
- wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" -O ~/.postgresql/root.crt
- chmod 0600 ~/.postgresql/root.crt
```

**2 - Установка клиента psql:**
```bash
- sudo apt update && sudo apt install -y postgresql-client
```

![alt text](<Screenshots/Задание 1-1.png>)

**3 - Проверяем установку проверив версию psql:**
```bash
- psql --version
```

![alt text](<Screenshots/Задание 1-2.png>)

**4 - Заходим в Yandex.cloud -> Managed Service for PostgreSQL создаем кластер и проверяем все статусы после создания что все запущено и создано:**

![alt text](<Screenshots/Задание 1-3.png>)

![alt text](<Screenshots/Задание 1-4.png>)

![alt text](<Screenshots/Задание 1-5.png>)

![alt text](<Screenshots/Задание 1-6.png>)

![alt text](<Screenshots/Задание 1-7.png>)

![alt text](<Screenshots/Задание 1-8.png>)

**5 - Проверяем доступность TCP‑порта на удалённых хостах с помощью утилиты nc (netcat):**
Команда nc -vz проверяет, открыт ли TCP‑порт (в нашем случае это 6432) на указанных хостах облачного кластера PostgreSQL — чтобы понять, доступно ли подключение до попытки зайти через psql.
```bash
- nc -vz rc1a-sl0hqg3mq6ihlsah.mdb.yandexcloud.net 6432
- nc -vz rc1d-aukjted8sf4ij7i1.mdb.yandexcloud.net 6432
```
![alt text](<Screenshots/Задание 1-9.png>)

**6 - Подключение к мастеру:**
```bash
- psql "host=,rc1a-sl0hqg3mq6ihlsah.mdb.yandexcloud.net,rc1d-aukjted8sf4ij7i1.mdb.yandexcloud.net \
      port=6432 \
      sslmode=verify-full \
      dbname=my-postgre-db \
      user=mila \
      target_session_attrs=read-write"
```

![alt text](<Screenshots/Задание 1-10.png>)

**7 - Проверяем что подключение прошло к master-узлу и проверяем количество подключенных реплик:**
```sql
- select case when pg_is_in_recovery() then 'REPLICA' else 'MASTER' end;
- select count(*) from pg_stat_replication;
```

![alt text](<Screenshots/Задание 1-11.png>)

**8 - На мастере создаем таблицу,две строки и выходим:**
```sql
- CREATE TABLE test_table(text varchar);
- insert into test_table values('Строка 1');
- insert into test_table values('Строка 2');
- \q
```
![alt text](<Screenshots/Задание 1-12.png>)

**9 - Подключаемся к реплике и проверяем, что мы на реплике.Проверяем таблицу которая была создана на мастере в одной зоне, а читаем её с реплики в другой:**
```bash
- psql "host=rc1d-aukjted8sf4ij7i1.mdb.yandexcloud.net \
      port=6432 \
      sslmode=verify-full \
      dbname=my-postgre-db \
      user=mila"
```
```sql
- select case when pg_is_in_recovery() then 'REPLICA' else 'MASTER' end;
- select status from pg_stat_wal_receiver;
- select * from test_table;
```

![alt text](<Screenshots/Задание 1-13.png>)

**Вывод о проделанной работе:**
1. Создан отказоустойчивый кластер PostgreSQL в Yandex Cloud:
- сервис Managed Service for PostgreSQL, класс хостов s2.micro, диск network-ssd;
- два хоста в разных зонах доступности (ru-central1-a и ru-central1-d), у обоих включён публичный доступ;
- созданы база данных my-postgre-db и пользователь с паролем;
- кластер доведён до статуса RUNNING.
2. Настроено и проверено подключение:
- скачан SSL-сертификат, подключение через psql с sslmode=verify-full на порт 6432;
- к мастеру — с атрибутом target_session_attrs=read-write, к реплике — с указанием только её FQDN;
- подтверждена роль каждого узла: на мастере pg_is_in_recovery() вернула MASTER, на реплике — REPLICA.
3. Проверена межзонная репликация:
- на мастере создана таблица test_table и вставлены две строки («Строка 1», «Строка 2»);
- на реплике выполнен select * from test_table; — обе строки дошли в другую зону доступности. Это ключевое доказательство: механизм репликации работает.

----------------------------------------------------------------------------------------------------------------