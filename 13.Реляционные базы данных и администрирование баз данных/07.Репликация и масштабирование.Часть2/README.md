# 13.07 Репликация и масштабирование.Часть2

----------------------------------------------------------------------------------------------------------------

## Задание 1

Опишите основные преимущества использования масштабирования методами:
- активный master-сервер и пассивный репликационный slave-сервер;
- master-сервер и несколько slave-серверов;

*Дайте ответ в свободной форме.*

## Ответ:

**1 - Активный master‑сервер и пассивный репликационный slave‑сервер (Master‑Slave):**
Такая схема даёт следующие преимущества:
- Разделение нагрузки по типу операций. На master идут все операции записи (INSERT/UPDATE/DELETE) и DDL, на slave — преимущественно чтение (SELECT). Это снижает нагрузку на основной сервер и повышает общую пропускную способность для запросов на чтение.
- Базовая отказоустойчивость. При падении master можно вручную или автоматически перевести один из slave в роль master (при наличии GTID и корректной настройки), чтобы система продолжила обслуживать запросы.
- Резервное копирование без остановки сервиса. Снимки и дампы (mysqldump/xtrabackup) удобно делать на slave, не нагружая master и не блокируя операции записи. Это напрямую улучшает показатели восстановления: RPO (меньше потерянных транзакций) и RTO (быстрее поднять резервную копию).
- Аналитика и отчёты на реплике. Тяжёлые аналитические запросы, агрегации, JOIN‑ы по большим таблицам выполняются на slave и не тормозят основную транзакционную нагрузку (OLTP).
- Проверка миграций перед применением. В контролируемом окружении можно сначала прогнать миграции на slave, посмотреть, как себя ведёт репликация, и только потом применять на master — это снижает риск ошибок.
- Тестовые среды из реплики. Можно клонировать slave (или делать снапшот тома) и использовать как тестовую среду с актуальными данными, не нагружая production. В Docker это реализуется через отдельные сервисы в docker-compose и изолированные volume.
- Географическое распределение. Slave можно разместить ближе к пользователям в другом регионе, уменьшая задержки при чтении.

**2 - Master‑сервер и несколько slave‑серверов:**
Это развитие схемы Master‑Slave, где к одному master подключено несколько slave. К преимуществам предыдущей схемы добавляются:
- Масштабирование чтения почти линейно. Добавление каждого нового slave позволяет увеличить суммарную пропускную способность на чтение пропорционально, пока не упрётесь в сеть или CPU.
- Гибкая маршрутизация чтения. Разные типы клиентов могут ходить на разные slave: API‑запросы — на быстрые реплики с низкой задержкой, отчёты и ETL — на отдельные реплики, чтобы не мешать друг другу.
- Изоляция проблемных нагрузок. Если какой‑то отчёт «вешает» один slave, остальные продолжают обслуживать обычные запросы — это повышает общую стабильность.
- Повышенная отказоустойчивость. Если один slave выходит из строя или начинает отставать (lag), нагрузка перераспределяется на оставшиеся. При потере master любой slave можно быстро сделать новым master.
- Разные сценарии использования реплик. Одни slave можно использовать для обычных пользовательских SELECT, другие — для ETL‑процессов, третьи — как песочницы для отладки.
- Размещение ближе к пользователям. Slave можно размещать в разных датацентрах/кластерах, чтобы уменьшить latency для чтения в конкретных регионах. В Docker Compose это реализуется как отдельные сервисы mysql-slave-1, mysql-slave-2 и т. д., с одинаковым набором параметров репликации, но разными volume/сетью.

----------------------------------------------------------------------------------------------------------------

## Задание 2

1. Разработайте план для выполнения горизонтального и вертикального шаринга базы данных. База данных состоит из трёх таблиц:
- пользователи,
- книги,
- магазины (столбцы произвольно).
2. Опишите принципы построения системы и их разграничение или разбивку между базами данных.
3. Пришлите блоксхему, где и что будет располагаться. Опишите, в каких режимах будут работать сервера.

## Ответ:

**1 - У нас есть три таблицы и мы их назовем:**
users - пользователи,
books - книги,
stores - магазины.
Надо раскидать их так, чтобы при росте нагрузки всё не легло.

**2 - Вертикальный шардинг (сделаем по таблицам).**
Смысл этого в том, что мы не храним всё в одной базе, а каждую таблицу в свою БД. Это как разложить вещи по разным шкафам: если в одном станет слишком много,то второй не страдает.

*Это будет выглядеть вот так:*
users → база db_users
stores → база db_stores
books → база db_books

И делаем мы это потому, что если пользователей станет очень много, ты масштабируешь только db_users. Миграции, бэкапы, настройки — всё отдельно, так проще и безопаснее.

**3 - Горизонтальный шардинг (делем таблицу на части).**
То есть мы нашу одну большую таблицу режем на части (шарды). Каждый шард — это отдельный экземпляр БД (в Docker — отдельный сервис).

*Как мы это будем делать:*
1. users: по user_id. Например, shard_id = user_id % 2.
- Если остаток 0 → Shard1.
- Если 1 → Shard2.
Приложение по ID сразу знает, куда идти.
2. stores: по региону или store_id. Удобно, если магазины географически разбросаны по территории: Санкт-Петербург → Shard1, Псков → Shard2 и т.д.
3. books: по book_id % N (например, % 4) можно выбрать  по жанру, если хотим группировать по тематике.

 Когда данных становится много, просто добавляешь новый шард — и нагрузка распределяется.

**4 - Как всё это работает вместе:**
 - У каждой базы - db_users, db_stores, db_books - свои шарды.
- В каждом шарде — мини‑кластер: 1 мастер (на запись) + 2–3 слейва (на чтение).
- Между базами нет внешних ключей. Просто храним ID: в books лежит store_id, приложение само идёт в db_stores и запрашивает данные. Целостность держим в коде (валидация, проверки).
- Маршрутизация (куда слать запрос) — на стороне приложения. Оно смотрит на user_id и выбирает нужный шард.

**5 - Как работают сервера:**
- *Мастер (M):* принимает *INSERT/UPDATE/DELETE*. Только один на шард.
- *Слейв (S):* только *SELECT*. Их несколько на каждый шард. Для чтения можно выбирать по кругу *(round‑robin).*
- *Failover:* если мастер упал, один из слейвов становится мастером. В идеале — автоматически *(через Orchestrator/MHA)*, но можно и вручную. В Docker это отдельные сервисы, статус репликации проверяется через *SHOW REPLICA STATUS.*

**Схема - 1:**

[db_users]──┬──[Shard1]──┬──[M]
            │           ├──[S]
            │           └──[S]
            └──[Shard2]──┬──[M]
                        ├──[S]
                        └──[S]

[db_stores]──┬──[Shard1]──┬──[M]
            │           ├──[S]
            │           └──[S]
            └──[Shard2]──┬──[M]
                        ├──[S]
                        └──[S]

[db_books]──┬──[Shard1]──┬──[M]
           │           ├──[S]
           │           └──[S]
           └──[Shard2]──┬──[M]
                       ├──[S]
                       └──[S]


**Схема - 2:**

Была создана в diagrams.net

![alt text](<Screenshots/Задание 2-1.png>)

**Схема - 3:**

Была создана в Graphviz online

![alt text](<Screenshots/Задание 2-2.png>)


Схема 1 -3 : вертикальный шардинг по доменам + горизонтальный шардинг по шардам внутри каждого домена + репликация Master‑Slave в каждом шарде.


**Схема - 4:**

Была создана в diagrams.net

![alt text](<Screenshots/Задание 2-3.png>)

В ней видно, что база разделена на три независимых части: пользователи, книги и склады. Это важно, чтобы понимать, где искать проблему. Например, если «упали» книги, по этой схеме видно, что авторизация пользователей работать должна — значит, чинить надо только домен db_books.

**Схема - 5:**

Была создана в diagrams.net

![alt text](<Screenshots/Задание 2-4.png>)

Схема с пометками — это инструкция по настройке. В ней есть важные детали, без которых система не заработает правильно: флаги GTID=ON для синхронизации, режим read_only на репликах, чтобы туда случайно не записали данные. Если не смотреть на эти пометки, можно ошибиться в конфиге и получить рассинхронизацию баз.


Первая схема отвечает на вопрос «что у нас есть», вторая — «как это правильно включить». Вместе они помогают развернуть систему без ошибок и быстро разобраться, если что-то пойдет не так».

----------------------------------------------------------------------------------------------------------------

## Задание 3*

1. Выполните настройку выбранных методов шардинга из задания 2.
2. Пришлите конфиг Docker и SQL скрипт с командами для базы данных.

## Ответ:

**Запускаем docker контейнер:**

[Конфигурационный файл: docker-compose.yml](Files/docker-compose.yml)

```bash
- docker compose up -d
- docker ps
```

![alt text](<Screenshots/Задание 3-1.png>)

![alt text](<Screenshots/Задание 3-2.png>)

## Первый кластер - users:

**1 - Вход на master (контейнер users-m1):**
```bash
- docker exec -it users-m1 mysql -u root -p
```
**Создаем пользователя для репликации и даём права:**
```sql
- CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'supersecret';
- GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl_user'@'%';
- FLUSH PRIVILEGES;
- SELECT user, host FROM mysql.user WHERE user = 'repl_user';
```
![alt text](<Screenshots/Задание 3-3.png>)

**Получение координат бинарного лога (чтобы слейв «знал, откуда начать»):**
```sql
- SHOW MASTER STATUS;
```

![alt text](<Screenshots/Задание 3-4.png>)

**2 - Вход на slave (контейнер users-s1):**
```bash
- docker exec -it users-s1 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- CHANGE MASTER TO
  MASTER_HOST='users-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='mysql-bin.000003',
  MASTER_LOG_POS=5462;
```
 **Запуск репликации на slave:**
 ```sql
- START REPLICA;
```

![alt text](<Screenshots/Задание 3-5.png>)

**Проверка статуса репликации:**
```bash
docker exec -it users-s1 mysql -u root -p
```
```sql
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-6.png>)

![alt text](<Screenshots/Задание 3-7.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**3 - Вход на slave (контейнер users-s2):**
```bash
- docker exec -it users-s2 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- CHANGE MASTER TO
  MASTER_HOST='users-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_PORT=3306,
  MASTER_LOG_FILE='mysql-bin.000003',
  MASTER_LOG_POS=5462;
```
 **Запуск репликации на slave:**
 ```sql
- START REPLICA;
```

![alt text](<Screenshots/Задание 3-8.png>)

**Проверка статуса репликации:**
```bash
docker exec -it users-s2 mysql -u root -p
```
```sql
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-9.png>)

![alt text](<Screenshots/Задание 3-10.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**4 - Вход на master (контейнер users-m1):**
```bash
docker exec -it users-m1 mysql -u root -p
```
**Создаем базу и таблицу:**
```sql
- CREATE DATABASE db_users;
- USE db_users;

- CREATE TABLE IF NOT EXISTS users_core (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  birth_date DATE,
  email VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

- INSERT INTO users_core (username, birth_date, email) VALUES
  ('Meredith_Grey', '1982-04-15', 'meredith@example.com'),
  ('Amelia_Shepherd', '1989-07-06', 'amelia@example.com'),
  ('Jo_Wilson', '1997-11-21', 'jo@example.com');

- SHOW TABLES;
- SELECT * FROM users_core;
```

![alt text](<Screenshots/Задание 3-11.png>)

![alt text](<Screenshots/Задание 3-12.png>)

**5 - Вход и проверка данных на slave (контейнер users-s1):**
```bash
- docker exec -it users-s1 mysql -u root -p
```
```sql
- USE db_users;
- SHOW TABLES;
- SELECT * FROM users_core ORDER BY user_id;
```

![alt text](<Screenshots/Задание 3-13.png>)

**6 - Вход и проверка данных на slave (контейнер users-s2):**
```bash
- docker exec -it users-s2 mysql -u root -p
```
```sql
- USE db_users;
- SHOW TABLES;
- SELECT * FROM users_core ORDER BY user_id;
```

![alt text](<Screenshots/Задание 3-14.png>)

**Вывод по пунктам 4-6:**
Проверка репликации выполнена в три этапа:
- На мастере users-m1 создана таблица.
- На слейве users-s1 командой SELECT подтверждено наличие тех же данных — репликация работает.
- На слейве users-s2 аналогично подтверждено наличие данных — оба слейва независимо синхронизированы с мастером.
Из чего можно сделать вывод что топология Master + multiple Slaves функционирует корректно, данные реплицируются без потерь и расхождений.


## Второй кластер - stores:

**1 - Вход на master (контейнер stores-m1):**
```bash
- docker exec -it stores-m1 mysql -u root -p
```
**Создаем пользователя для репликации и даём права:**
```sql
- CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'supersecret';
- GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl_user'@'%';
- FLUSH PRIVILEGES;
```

![alt text](<Screenshots/Задание 3-15.png>)

**2 - Вход на slave (контейнер stores-s1):**
```bash
- docker exec -it stores-s1 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- CHANGE MASTER TO
  MASTER_HOST='stores-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_AUTO_POSITION=1;
- START REPLICA;
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-16.png>)

![alt text](<Screenshots/Задание 3-17.png>)

![alt text](<Screenshots/Задание 3-18.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**3 - Вход на slave (контейнер stores-s2):**
```bash
- docker exec -it stores-s2 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- CHANGE MASTER TO
  MASTER_HOST='stores-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_AUTO_POSITION=1;
- START REPLICA;
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-19.png>)

![alt text](<Screenshots/Задание 3-20.png>)

![alt text](<Screenshots/Задание 3-21.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**4 - Вход на master (контейнер stores-m1):**
```bash
- docker exec -it stores-m1 mysql -u root -p
```
**Создаем таблицу и данные:**
```sql
- USE db_stores;
- CREATE TABLE IF NOT EXISTS stores (
  store_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  region VARCHAR(50),
  address VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

- INSERT INTO stores (name, region, address) VALUES
  ('Store A', 'St. Petersburg', 'Nevsky 7'),
  ('Store B', 'Pscov', 'Sovetskaya 21'),
  ('Store C', 'Vladivostok ', 'Bauman 5');
- SELECT * FROM stores;
```

![alt text](<Screenshots/Задание 3-22.png>)

**5 - Вход и проверка данных на slave (контейнер stores-s1):**
```bash
- docker exec -it stores-s1 mysql -u root -p
```
```sql
 - USE db_stores;
 - SHOW TABLES;
 - SELECT * FROM stores;
```

![alt text](<Screenshots/Задание 3-23.png>)

**6 - Вход и проверка данных на slave (контейнер stores-s2):**
```bash
- docker exec -it stores-s2 mysql -u root -p
```
```sql
- USE db_stores;
- SHOW TABLES;
- SELECT * FROM stores;
```

![alt text](<Screenshots/Задание 3-24.png>)


## Третий кластер - books:

**1 - Вход на master (контейнер books-m1):**
```bash
- docker exec -it books-m1 mysql -u root -p
```
**Создаем пользователя для репликации и даём права:**
```sql
- CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'supersecret';
- GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl_user'@'%';
- FLUSH PRIVILEGES;
- EXIT;
```
![alt text](<Screenshots/Задание 3-25.png>)

**2 - Вход на slave (контейнер books-s1):**
```bash
- docker exec -it books-s1 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- STOP REPLICA;
- CHANGE MASTER TO
  MASTER_HOST='books-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_AUTO_POSITION=1;
- START REPLICA;
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-26.png>)

![alt text](<Screenshots/Задание 3-27.png>)

![alt text](<Screenshots/Задание 3-28.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**3 - Вход на slave (контейнер books-s2):**
```bash
- docker exec -it books-s2 mysql -u root -p
```
**Настройка репликации на слейве:**
```sql
- STOP REPLICA;
- CHANGE MASTER TO
  MASTER_HOST='books-m1',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='supersecret',
  MASTER_AUTO_POSITION=1;
- START REPLICA;
- SHOW REPLICA STATUS\G;
```

![alt text](<Screenshots/Задание 3-29.png>)

![alt text](<Screenshots/Задание 3-30.png>)

![alt text](<Screenshots/Задание 3-31.png>)

Результат:
Replica_IO_Running: Yes — поток чтения лога работает.
Replica_SQL_Running: Yes — поток применения изменений работает.
Seconds_Behind_Source: 0 — отставания нет.
Last_Error пуст — ошибок нет.

**4 - Вход на master (контейнер books-m1):**
```bash
- docker exec -it books-m1 mysql -u root -p
```
**Создаем таблицу и данные:**
```sql
- USE db_books;
- CREATE TABLE IF NOT EXISTS books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  author VARCHAR(100),
  genre VARCHAR(50),
  price DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
- INSERT INTO books (title, author, genre, price) VALUES
    ('The Master and Margarita', 'Mikhail Bulgakov', 'Classic Prose', 699.00),
    ('Dracula', 'Bram Stoker', 'Gothic Fiction / Horror', 520.00),
    ('The Alchemist', 'Paulo Coelho', 'Adventure Prose / Magical Realism', 649.00),
    ('The Great Gatsby', 'F. Scott Fitzgerald', 'American Classic', 580.00),
    ('The Three Musketeers', 'Alexandre Dumas', 'Adventure Novel', 560.00),
    ('The Cherry Orchard', 'Anton Chekhov', 'Drama / Russian Classic', 460.00),
    ('A Hero of Our Time', 'Mikhail Lermontov', 'Psychological Prose / Russian Classic', 470.00);

- SELECT * FROM books;
```

![alt text](<Screenshots/Задание 3-32.png>)

**5 - Вход и проверка данных на slave (контейнер books-s1 ):**
```bash
- docker exec -it books-s1 mysql -u root -p
```
```sql
- USE db_books;
- SHOW TABLES;
- SELECT * FROM books;
```

![alt text](<Screenshots/Задание 3-33.png>)

**6 - Вход и проверка данных на slave (контейнер books-s2 ):**
```bash
- docker exec -it books-s2 mysql -u root -p
```
```sql
- USE db_books;
- SHOW TABLES;
- SELECT * FROM books;
```
![alt text](<Screenshots/Задание 3-34.png>)


## Общий итог о проделанной работе:
- Была проведена настройка вертикального шардинга и репликация «Master + 2 Slaves» для каждого шарда.
- Вертикальный шардинг — это разделение данных по сущностям (таблицам) и вынос их в отдельные базы/кластеры.
- users → отдельный кластер users-m1/s1/s2 + db_users.
- stores → отдельный кластер stores-m1/s1/s2 + db_stores.
- books → отдельный кластер books-m1/s1/s2 + db_books.
- Т.е в каждом кластере 1 мастер (RW) + 2 слейва (RO).Где 1 мастер-сервер (RW) — принимает операции записи, а
2 слейв-сервера (RO) — предназначены только для чтения.
Параметры: GTID (gtid_mode=ON), binlog_format=ROW, read_only на слейвах, healthcheck в Docker Compose.
Пользователь репликации: repl_user с правами REPLICATION SLAVE, REPLICATION CLIENT
1. Инфраструктура развернута с помощью  Docker-compose.
2. Кластер users (первый кластер) — настроен вручную: на этом кластере были выполнены все ключевые операции «вживую» через интерактивный режим (mysql>): создание пользователя репликации repl_user, выдача прав, проверка SHOW MASTER STATUS, выполнение команд CHANGE MASTER TO и START REPLICA на слейвах.Также вручную проверена логика синхронизации: данные, вставленные на мастере, подтверждены на слейвах через SELECT.
3. Кластеры stores и books (второй и третий кластеры) — развёрнуты через командную строку (bash + mysql) в режиме GTID.
- После настройки первого кластера логика настройки была последовательно воспроизведена вручную на оставшихся кластерах без использования скриптов: каждый шаг (создание пользователя, выдача прав, CHANGE MASTER TO, START REPLICA) выполнялся прямыми командами в терминале.
- При настройке репликации на слейвах этих кластеров не использовались параметры MASTER_LOG_FILE и MASTER_LOG_POS, вместо этого репликация автоматически подхватывала нужную позицию на основе GTID - это современный подход к репликации и умение работать без ручных позиций.
4. Горизонтальный шардинг на данном этапе не требуется, так как объем данных в каждом домене покрывается одним шардом (кластером). Архитектура спроектирована так, что при росте данных мы просто добавим новые независимые кластеры (например, users-m2), и тогда это станет горизонтальным шардингом.

-----------------------------------------------------------------------------------------------------------
