# 13.06 Репликация и масштабирование.Часть 1

----------------------------------------------------------------------------------------------------------------

## Задание 1

На лекции рассматривались режимы репликации: master-slave,master-master,опишите их различия.

*Ответить в свободной форме.*

## Ответ:

**Master‑Slave (ведущий‑ведомый,т.е однонаправленная репликация) — классическая асимметричная схема:**
1. Один источник истины.
- Все изменения (INSERT/UPDATE/DELETE) идут только на Master. Slave только читает данные и реплицирует изменения с Master.
2. Нагрузка распределяется.
- Master держит запись, Slave берут на себя чтение (репортные запросы, аналитика, веб‑приложение в режиме read‑only).
3. Отказоустойчивость частичная.
- Если падает Master, система перестаёт принимать записи;
- при грамотной настройке можно вручную или автоматически перевести один из Slave в роль Master.
4. Задержка репликации (replication lag).
- Slave может отставать на секунды или минуты — данные на нём не всегда «свежие». Это нормально и учитывается в логике приложения (критичные операции — на Master, отчёты — на Slave).
5. Простота настройки и предсказуемость.
- Конфликтов почти нет, потому что пишет только один сервер.

**Master‑Master (двунаправленная репликация) — симметричная схема, где оба узла могут принимать запись:**

1.Оба сервера — источники истины.
- Изменения, сделанные на любом из них, реплицируются на другой.
2. Риск конфликтов.
- Если две сессии одновременно меняют одну и ту же строку на разных узлах, возникает конфликт, который нужно разрешать (автоматически или вручную). В MySQL это особенно актуально при использовании AUTO_INCREMENT без правильной настройки auto_increment_offset и auto_increment_increment.
3. Сложность эксплуатации.
- Нужно тщательно настраивать автоинкременты, следить за консистентностью, иметь план разрешения конфликтов и отката.
4. Не всегда даёт «настоящую» высокую доступность.
- Без внешнего арбитра (HAProxy, Keepalived, Pacemaker и т. п.) переключение при падении узла часто делается вручную.
5. Чаще используется как переходный вариант или для специфических задач.
- Например, для географически распределённых офисов с локальной записью, либо как подготовка к шардированию. В современных архитектурах чаще выбирают либо Master‑Slave + автоматический фейловер, либо полноценные HA‑кластеры (Group Replication, Galera, Patroni).

**Ключевое отличие:** в Master‑Slave запись централизована (меньше конфликтов, проще), в Master‑Master запись распределена (больше гибкости, но выше риск проблем с консистентностью).

----------------------------------------------------------------------------------------------------------------

## Задание 2

1. Выполните конфигурацию master-slave репликации, примером можно пользоваться из лекции.
2. Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.

## Ответ:

**Для выполнения этого задания были использованы:**
1. [Конфигурационный файл: docker-compose.yml](Files/TASK-2/docker-compose.yml)
2. В папке master - [my.cnf](Files/TASK-2/master/my.cnf)
3. В папке slave - [my.cnf](Files/TASK-2/slave/my.cnf)

**1 - Поднимаем контейнеры**

-  mysql-master и mysql-slave из compose-файла в фоновом режиме; docker ps показывает список работающих контейнеров со статусами и портами.

```bash
- docker-compose up -d
- docker ps
```

![alt text](<Screenshots/Задание 2-1.png>)

**2 - Проверка уникальности server-id**

```bash
- docker exec -it mysql-master mysql -u root -p
```
```sql
- SHOW VARIABLES LIKE 'server_id';
```

![alt text](<Screenshots/Задание 2-2.png>)

```bash
- docker exec -it mysql-slave mysql -u root -p
```
```sql
- SHOW VARIABLES LIKE 'server_id';
```

![alt text](<Screenshots/Задание 2-3.png>)

*Зачем мы это делаем:* идентификаторы серверов должны различаться — при совпадении репликация не стартует (ошибка 13117). Проверка подтверждает корректность конфигурации.

**3 - Создание пользователя репликации**
```bash
- docker exec -it mysql-master mysql -u root -p
```
```sql
- CREATE USER 'mila'@'%' IDENTIFIED WITH mysql_native_password BY 'NewSecret';
- GRANT REPLICATION SLAVE ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';
- SHOW MASTER STATUS;
```

![alt text](<Screenshots/Задание 2-4.png>)

![alt text](<Screenshots/Задание 2-5.png>)

*Что делает:*  создает пользователя с аутентификацией mysql_native_password (альтернатива стандартному caching_sha2_password, упрощающая подключение реплики без шифрования); проверочный SELECT подтверждает, что пользователь существует и какой плагин используется; SHOW MASTER STATUS фиксирует координаты репликации.

**4 - Настройка репликации на слейве**
```bash
- docker exec -it mysql-slave mysql -u root -p
```
```sql
- CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'mysql-master',
  SOURCE_USER = 'mila',
  SOURCE_PASSWORD = 'NewSecret',
  SOURCE_LOG_FILE = 'mysql-bin.000003',
  SOURCE_LOG_POS = 827,
  GET_SOURCE_PUBLIC_KEY = 1;

- START REPLICA;

- SHOW REPLICA STATUS\G
```

![alt text](<Screenshots/Задание 2-6.png>)

![alt text](<Screenshots/Задание 2-7.png>)

![alt text](<Screenshots/Задание 2-8.png>)

**Что делает:** указывает слейву адрес мастера, учётные данные и стартовые координаты binlog; START REPLICA запускает два потока — поток ввода-вывода (I/O thread), который забирает события binlog в relay log, и SQL-поток, который применяет их локально; SHOW REPLICA STATUS\G выводит полное состояние репликации.

*Результат:*
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**5 - Создаем базу данных,таблицу и строку**

```bash
- docker exec -it mysql-master mysql -u root -p
```
```sql
- CREATE DATABASE new_repl_db;
- USE new_repl_db;
- CREATE TABLE repl_test (id INT PRIMARY KEY AUTO_INCREMENT, val VARCHAR(50));
- INSERT INTO repl_test (val) VALUES ('hello-replication');
- SELECT * FROM repl_test;
```

![alt text](<Screenshots/Задание 2-9.png>)

*Что делает:* каждое из этих действий записывается в binlog мастера и, соответственно, транслируется на слейв.

**6 - Проверка данных на слейве**
```bash
- docker exec -it mysql-slave mysql -u root -p
```
```sql
- USE new_repl_db;
- SELECT * FROM repl_test;
```

![alt text](<Screenshots/Задание 2-10.png>)

**Итог:**
1. Выполнена конфигурация репликации master-slave на двух контейнерах MySQL 8.0, объединённых сетью Docker Compose. Проверка SHOW VARIABLES LIKE 'server_id' подтвердила уникальные идентификаторы серверов: 1 на мастере и 2 на слейве, что является обязательным условием репликации. На мастере создан пользователь репликации с плагином mysql_native_password и привилегией REPLICATION SLAVE; координаты бинарного лога получены командой SHOW MASTER STATUS.
2. Слейв подключён к мастеру командой CHANGE REPLICATION SOURCE TO с указанием координат binlog и параметром GET_SOURCE_PUBLIC_KEY = 1 для корректной аутентификации в незашифрованном соединении. Команда SHOW REPLICA STATUS подтвердила запуск обеих нитей репликации: Replica_IO_Running = Yes, Replica_SQL_Running = Yes, отставание Seconds_Behind_Source = 0, ошибки ввода-вывода и применения отсутствуют.
3. Для проверки работоспособности на мастере создана база новая база данных, таблица и выполнена вставка строки 'hello-replication'. На слейве база, таблица и данные воспроизведены автоматически: вывод SELECT * FROM repl_test на обоих узлах идентичен, при этом на слейве операции записи не выполнялись. Это подтверждает корректную работу репликации master-slave: все изменения данных на мастере реплицируются на слейв без ручного вмешательства.

----------------------------------------------------------------------------------------------------------------

## Задание 3*

1. Выполните конфигурацию master-master репликации. Произведите проверку.
2. Приложите скриншоты конфигурации, выполнения работы: состояния и режимы работы серверов.

## Ответ:

**Для выполнения этого задания были использованы:**
1. [Конфигурационный файл: docker-compose.yml ](Files/TASK-3/docker-compose.yml)
2. В папке db1 - [my.cnf](Files/TASK-3/db1/my.cnf)
3. В папке db2 - [my.cnf](Files/TASK-3/db2/my.cnf)


**1. Поднимаем контейнеры:**
```bash
- docker-compose up -d
- docker ps -a
```

![alt text](<Screenshots/Задание 3-1.png>)

**2 - Проверка конфигурации узлов на (контейнере db1):**
```bash
- docker exec -it mysql-db1 mysql -u root -p
```
```sql
- SHOW VARIABLES LIKE 'server_id';
- SHOW VARIABLES LIKE 'auto_increment%';
- SHOW VARIABLES LIKE 'log_replica_updates';
```

![alt text](<Screenshots/Задание 3-2.png>)

**3 - Проверка конфигурации узлов на (контейнере db2):**
```bash
- docker exec -it mysql-db2 mysql -u root -p
```
```sql
- SHOW VARIABLES LIKE 'server_id';
- SHOW VARIABLES LIKE 'auto_increment%';
- SHOW VARIABLES LIKE 'log_replica_updates';
```

![alt text](<Screenshots/Задание 3-3.png>)

**4 -  Создание пользователя репликации и выдача прав (контейнер db1)**
```bash
- docker exec -it mysql-db1 mysql -u root -p
```
```sql
- CREATE USER 'mila'@'%' IDENTIFIED WITH mysql_native_password BY 'SecretSuper';
- GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';
```
![alt text](<Screenshots/Задание 3-4.png>)

**5 -  Создание пользователя репликации (контейнер db2)**
```bash
- docker exec -it mysql-db2 mysql -u root -p
```

```sql
- CREATE USER 'mila'@'%' IDENTIFIED WITH mysql_native_password BY 'SecretSuper';
- GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'mila'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host, plugin FROM mysql.user WHERE user = 'mila';
```

![alt text](<Screenshots/Задание 3-5.png>)

**6 - Настройка взаимной репликации (контейнер db1)**
На db1 (подключаемся к db2):
```bash
- docker exec -it mysql-db1 mysql -u root -p
```
```sql
- CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'mysql-db2',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'mila',
  SOURCE_PASSWORD = 'SecretSuper',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

- START REPLICA;
- SHOW REPLICA STATUS\G
```

![alt text](<Screenshots/Задание 3-6.png>)

![alt text](<Screenshots/Задание 3-7.png>)

![alt text](<Screenshots/Задание 3-8.png>)

**7 - Настройка взаимной репликации (контейнер db2)**
На db2(подключаемся к db1):
```bash
- docker exec -it mysql-db2 mysql -u root -p
```
```sql
- CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = 'mysql-db1',
  SOURCE_PORT = 3306,
  SOURCE_USER = 'mila',
  SOURCE_PASSWORD = 'SecretSuper',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;

- START REPLICA;
- SHOW REPLICA STATUS\G
```

![alt text](<Screenshots/Задание 3-9.png>)

![alt text](<Screenshots/Задание 3-10.png>)

![alt text](<Screenshots/Задание 3-11.png>)

**8 - Создаем тестовую базу данных и таблицу (контейнер db1):**
```bash
- docker exec -it mysql-db1 mysql -u root -p
```
```sql
- CREATE DATABASE IF NOT EXISTS my_new_db;
- USE my_new_db;
- CREATE TABLE repl_table (
  id INT AUTO_INCREMENT PRIMARY KEY,
  val VARCHAR(50),
  node VARCHAR(20)
);
- INSERT INTO repl_table (val, node) VALUES ('insert-from-db1-Hello-World', 'db1');
- SELECT * FROM repl_table;
```

![alt text](<Screenshots/Задание 3-12.png>)

**9 - Проверяем что данные пришли в контейнер db2**
```bash
- docker exec -it mysql-db2 mysql -u root -p
```
```sql
- USE my_new_db;
- SELECT * FROM repl_table;
```

![alt text](<Screenshots/Задание 3-13.png>)

**10 - Проверка обратной репликации (контейнер db2)**
На db2 делаем свою вставку:
```bash
- docker exec -it mysql-db2 mysql -u root -p
```
```sql
- USE my_new_db;
- INSERT INTO my_new_db.repl_table (val, node) VALUES ('insert-from-db2-Hello-Replica', 'db2');
- SELECT * FROM repl_table;
```

![alt text](<Screenshots/Задание 3-14.png>)

**11 - Проверяем что данные пришли на (контейнер db1)**
```bash
- docker exec -it mysql-db1 mysql -u root -p
```
```sql
- USE my_new_db;
- SELECT * FROM my_new_db.repl_table ORDER BY id;
```

![alt text](<Screenshots/Задание 3-15.png>)

**Общий вывод:**
1. Выполнена настройка **master-master** репликации между контейнерами **mysql-db1** и **mysql-db2** с использованием **GTID (SOURCE_AUTO_POSITION = 1)**.
2. Тестовые данные созданы последовательно: первая строка (id=1, node='db1') добавлена на узле db1, вторая строка (id=2, node='db2') — на узле db2 после подтверждения репликации первой.
3. Данные на обоих узлах идентичны, нумерация id последовательна, разрывов в автоинкременте не наблюдается.
Последовательная нумерация получилась за счёт строгой последовательности операций: вставка на одном узле выполнялась только после того, как предыдущая строка была подтверждена на втором узле. Это позволило избежать одновременных конфликтов автоинкремента. При параллельной нагрузке нумерация может иметь разрывы, что является нормальным поведением для master-master без настройки auto_increment_offset.
4. Статус репликации на обоих узлах стабилен: IO_Running=Yes, SQL_Running=Yes, ошибок нет.Репликация подтверждена.

----------------------------------------------------------------------------------------------------------------