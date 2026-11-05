# 13.05 Индексы

----------------------------------------------------------------------------------------------------------------

## Задание 1

Напишите запрос к учебной базе данных, который вернёт процентное отношение общего размера всех индексов к общему размеру всех таблиц.

## Ответ:

[Table and indexe.sql](<Files/Scripts/Table and indexe.sql>)

![alt text](<Screenshots/Задание 1-1.png>)

![alt text](<Screenshots/Задание 1-2.png>)

**Вывод:**

В ходе выполнения задания удалось получить наглядную и практичную аналитику по «весу» индексов в учебной базе данных sakila.

**Из данных видно несколько важных моментов:**
1. Общий процент индексов по БД стабилен — во всех строках он равен 33,33%. Это говорит о том, что CTE корректно посчитал суммарные значения и равномерно применил их к каждой таблице.
2. Доля индексов сильно варьируется от таблицы к таблице. Например:
- В таблицах «Аренды» и «Платежи» индексы занимают 80% и 75% соответственно — это может указывать на высокую нагрузку по поиску и фильтрации по этим таблицам (много внешних ключей, индексов по датам и т. п.).
- В «Инвентаре», «Персонале» и «Магазинах» доля индексов — 66,67%, что тоже довольно много.
- В «Категориях», «Странах» и «Языках» индексы отсутствуют (0%) — вероятно, это небольшие справочники, где индексы не требуются или не созданы.
3. Названия (например, «Актёры» вместо actor, «Фильмы» вместо film) действительно делают отчёт удобным для восприятия — сразу понятно, о какой сущности идёт речь, без сверки со схемой БД.
4. Такой отчёт можно использовать как «чек‑лист» для аудита базы:
- Таблицы с очень высокой долей индексов (вроде «Аренды») стоит проверить: все ли индексы реально используются, нет ли дублирующих или избыточных.
- Таблицы без индексов (вроде «Категории») — убедиться, что отсутствие индексов не приводит к медленным запросам при соединениях.
- Общий показатель в 33,33% — это базовый ориентир: если в будущем он начнёт заметно расти, это сигнал к более глубокому анализу структуры индексов.

----------------------------------------------------------------------------------------------------------------

## Задание 2

Выполните explain analyze следующего запроса:

```sql
select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id
```
- перечислите узкие места;
- оптимизируйте запрос: внесите корректировки по использованию операторов, при необходимости добавьте индексы.

## Ответ:

**1 - Проверка текущих индексов**
```bash
- docker exec -it sakila-mysql mysql -u root -p -D sakila
```
Проверяем текущее состояние индексов в целевой таблице до внесения изменений.

```sql
- SHOW INDEX FROM payment;
```
*Результат:*
- показал наличие только стандартных индексов (PRIMARY, idx_fk_staff_id, idx_fk_customer_id, fk_payment_rental). Пользовательских индексов, оптимизированных под аналитические запросы с фильтрацией по payment_date, в таблице не обнаружено. Это подтвердило необходимость создания дополнительного покрывающего индекса для ускорения выборки.

**2 - Проверка таблиц**

Проверяем наличие временных таблиц, созданных в ходе предыдущих операций.

```sql
- SHOW TABLES LIKE 'temp%';
```
*Результат:*
- показал пустой набор строк (Empty set). Это подтверждает отсутствие временных таблиц и гарантирует, что последующие замеры производительности не будут искажены остаточными данными от предыдущих операций.

![alt text](<Screenshots/Задание 2-1.png>)

**3 - Выполняем EXPLAIN ANALYZE исходного запроса:**

```sql
EXPLAIN ANALYZE
SELECT DISTINCT CONCAT(c.last_name, ' ', c.first_name), SUM(p.amount) OVER (PARTITION BY c.customer_id, f.title)
FROM payment p, rental r, customer c, inventory i, film f
WHERE DATE(p.payment_date) = '2005-07-30'
  AND p.payment_date = r.rental_date
  AND r.customer_id = c.customer_id
  AND i.inventory_id = r.inventory_id;
```
![alt text](<Screenshots/Задание 2-2.png>)

![alt text](<Screenshots/Задание 2-3.png>)

Результат:
```sql
-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=16081..16081 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=16081..16081 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=6302..15407 rows=642000 loops=1)
            -> Sort: c.customer_id, f.title  (actual time=6298..6550 rows=642000 loops=1)
                -> Stream results  (cost=104 rows=1000) (actual time=163..972 rows=642000 loops=1)
                    -> Inner hash join (no condition)  (cost=104 rows=1000) (actual time=163..408 rows=642000 loops=1)
                        -> Covering index scan on f using idx_title  (cost=103 rows=1000) (actual time=4.19..10.2 rows=1000 loops=1)
                        -> Hash
                            -> Nested loop inner join  (cost=1.4 rows=1) (actual time=34.9..153 rows=642 loops=1)
                                -> Nested loop inner join  (cost=1.05 rows=1) (actual time=30.8..133 rows=642 loops=1)
                                    -> Nested loop inner join  (cost=0.7 rows=1) (actual time=19.8..104 rows=642 loops=1)
                                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=0.35 rows=1) (actual time=16.4..74.9 rows=634 loops=1)
                                            -> Table scan on p  (cost=0.35 rows=1) (actual time=14.5..69.4 rows=16044 loops=1)
                                        -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.35 rows=1) (actual time=0.0381..0.0419 rows=1.01 loops=634)
                                    -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.35 rows=1) (actual time=0.0451..0.0451 rows=1 loops=642)
                                -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.35 rows=1) (actual time=0.0313..0.0314 rows=1 loops=642)
```

**Узкие места:**
1. Полное сканирование таблицы payment — 16 044 строки Table scan on p + Filter: (cast(p.payment_date as date) = '2005-07-30'). Условие DATE() не SARGable, а индекса по дате нет вообще — MySQL читает всю таблицу и фильтрует на лету. Сумма накладных: ~70 мс (самая долгая часть на этом уровне, но дальше хуже).
2. Декартово произведение с film — взрыв до 642 000 строк
```
-> Inner hash join (no condition) (rows=642000)
   -> Covering index scan on f using idx_title (rows=1000)
```
Связи f.film_id = i.film_id нет, поэтому 634 строки умножаются на 1000 фильмов. На этот этап уходит ~408 мс.
3. Сортировка 642 000 строк — ~250 мс Sort: c.customer_id, f.title (actual time=6298..6550) — обязательна для оконной функции PARTITION BY.
4. Оконная агрегация с буферизацией — ~9.1 сек Window aggregate with buffering (actual time=6302..15407) — самый дорогой этап: MySQL буферизует весь раздутый набор, чтобы посчитать SUM() OVER.
5. DISTINCT через временную таблицу — до ~16.08 сек Temporary table with deduplication (actual time=16081..16081) — на дедупликацию уходит почти всё оставшееся время.
Итог: из ~16 секунд запроса основное время съедают оконная агрегация (~9 сек) и дедупликация (~7 сек) — и обе работают с искусственно раздутым набором из 642 тысяч строк, которых в данных всего 634.


**Оптимизация запроса — корректировки по операторам + индексы:**

1. Создаём покрывающий составной индекс:
```sql
CREATE INDEX idx_payment_date_rental_amount
ON payment(payment_date, rental_id, amount);
```
Команда строит BTREE-индекс по трём столбцам таблицы payment в заданном порядке. Порядок столбцов критичен:
- payment_date (1-й) — по этому столбцу идёт фильтр в запросе. Первым в составном индексе он даёт оптимизатору возможность быстро найти нужный диапазон дат, не просматривая остальные данные.
- rental_id (2-й) — по нему выполняется соединение с таблицей rental. Значение подтягивается прямо из индекса.
- amount (3-й) — по нему считается SUM(). Поскольку столбец есть в индексе, агрегация выполняется без обращения к строкам самой таблицы — это и делает индекс покрывающим (covering).

2. Проверяем, что индекс создан:
```sql
SHOW INDEX FROM payment;
```

![alt text](<Screenshots/Задание 2-4.png>)

Результат:
- команда SHOW INDEX FROM payment подтвердила создание покрывающего индекса: таблица содержит пять индексов, включая idx_payment_date_rental_amount(payment_date, rental_id, amount). Столбцы следуют в порядке, соответствующем паттерну запроса: фильтр по дате, соединение по rental_id, агрегация по amount.

3. Оптимизированный запрос (главный):
```sql
EXPLAIN ANALYZE
SELECT
  CONCAT(c.last_name, ' ', c.first_name) AS customer_name,
  f.title AS film_title,
  SUM(p.amount) AS total_amount
FROM payment p
JOIN rental r    ON p.rental_id     = r.rental_id
JOIN customer c  ON r.customer_id   = c.customer_id
JOIN inventory i ON r.inventory_id  = i.inventory_id
JOIN film f      ON i.film_id       = f.film_id
WHERE p.payment_date >= '2005-07-30 00:00:00'
  AND p.payment_date <  '2005-07-31 00:00:00'
GROUP BY
  c.customer_id, c.last_name, c.first_name,
  f.film_id, f.title;
```

![alt text](<Screenshots/Задание 2-5.png>)

![alt text](<Screenshots/Задание 2-6.png>)

Результат:
```sql
 Table scan on <temporary>  (actual time=88.1..88.4 rows=634 loops=1)
    -> Aggregate using temporary table  (actual time=87.9..87.9 rows=634 loops=1)
        -> Nested loop inner join  (cost=1.75 rows=1) (actual time=19.9..78 rows=634 loops=1)
            -> Nested loop inner join  (cost=1.4 rows=1) (actual time=15.6..56 rows=634 loops=1)
                -> Nested loop inner join  (cost=1.05 rows=1) (actual time=15..44.9 rows=634 loops=1)
                    -> Nested loop inner join  (cost=0.7 rows=1) (actual time=13.8..36.6 rows=634 loops=1)
                        -> Filter: ((p.payment_date >= TIMESTAMP'2005-07-30 00:00:00') and (p.payment_date < TIMESTAMP'2005-07-31 00:00:00') and (p.rental_id is not null))  (cost=0.35 rows=1) (actual time=12.1..22.4 rows=634 loops=1)
                            -> Covering index scan on p using idx_payment_date_rental_amount  (cost=0.35 rows=1) (actual time=2.76..19.3 rows=16044 loops=1)
                        -> Single-row index lookup on r using PRIMARY (rental_id=p.rental_id)  (cost=0.35 rows=1) (actual time=0.0214..0.0214 rows=1 loops=634)
                    -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.35 rows=1) (actual time=0.0127..0.0128 rows=1 loops=634)
                -> Single-row index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.35 rows=1) (actual time=0.0169..0.017 rows=1 loops=634)
            -> Single-row index lookup on f using PRIMARY (film_id=i.film_id)  (cost=0.35 rows=1) (actual time=0.0339..0.034 rows=1 loops=634)
```

**Проверка контрольных точек:**
1. Доступ к payment через индекс
```
-> Covering index scan on p using idx_payment_date_rental_amount (actual time=2.76..19.3 rows=16044)
```
Вместо Table scan on p из «до»-версии — чтение только индекса, без обращения к строкам таблицы.
2. После фильтра — 634 строки
```
-> Filter: ((p.payment_date >= TIMESTAMP'...') and (p.payment_date < TIMESTAMP'...') and (p.rental_id is not null)) (actual time=12.1..22.4 rows=634)
```
Декартова произведения больше нет: 634 строки — реальное число платежей за день, а не 642 000.
3. Все соединения — точечные по первичным ключам
```Single-row index lookup on r using PRIMARY  (0.0214 мс на строку)
Single-row index lookup on c using PRIMARY  (0.0127 мс)
Single-row index lookup on i using PRIMARY  (0.0169 мс)
Single-row index lookup on f using PRIMARY  (0.0339 мс)
```
4. Тяжёлых операций нет.
В плане отсутствуют Sort, Window aggregate with buffering, Temporary table with deduplication. Агрегация — простая: Aggregate using temporary table на 634 строках, ~88 мс.
Общий итог: 88 мс против ~16.1 сек у исходного запроса без индекса — ускорение примерно в 180 раз.

**4 - Исходный (медленный) запрос с созданным индексом:**
```sql
EXPLAIN ANALYZE
SELECT DISTINCT CONCAT(c.last_name, ' ', c.first_name), SUM(p.amount) OVER (PARTITION BY c.customer_id, f.title)
FROM payment p, rental r, customer c, inventory i, film f
WHERE DATE(p.payment_date) = '2005-07-30'
  AND p.payment_date = r.rental_date
  AND r.customer_id = c.customer_id
  AND i.inventory_id = r.inventory_id;
```

![alt text](<Screenshots/Задание 2-7.png>)

![alt text](<Screenshots/Задание 2-8.png>)

Результат:
```sql
Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=6770..6770 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=6770..6770 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=2399..6464 rows=642000 loops=1)
            -> Sort: c.customer_id, f.title  (actual time=2398..2501 rows=642000 loops=1)
                -> Stream results  (cost=104 rows=1000) (actual time=31.2..340 rows=642000 loops=1)
                    -> Inner hash join (no condition)  (cost=104 rows=1000) (actual time=30.9..124 rows=642000 loops=1)
                        -> Covering index scan on f using idx_title  (cost=103 rows=1000) (actual time=0.431..2.29 rows=1000 loops=1)
                        -> Hash
                            -> Nested loop inner join  (cost=1.4 rows=1) (actual time=13.2..29.3 rows=642 loops=1)
                                -> Nested loop inner join  (cost=1.05 rows=1) (actual time=12.8..24 rows=642 loops=1)
                                    -> Nested loop inner join  (cost=0.7 rows=1) (actual time=12.2..19.9 rows=642 loops=1)
                                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=0.35 rows=1) (actual time=10.7..13.8 rows=634 loops=1)
                                            -> Covering index scan on p using idx_payment_date_rental_amount  (cost=0.35 rows=1) (actual time=3.33..12.1 rows=16044 loops=1)
                                        -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.35 rows=1) (actual time=0.00882..0.00934 rows=1.01 loops=634)
                                    -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.35 rows=1) (actual time=0.00617..0.0062 rows=1 loops=642)
                                -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.35 rows=1) (actual time=0.00791..0.00794 rows=1 loops=642)
```
*Что показал замер 2 (исходный запрос + индекс):*
```
-> Covering index scan on p using idx_payment_date_rental_amount (actual time=3.33..12.1 rows=16044)
   -> Filter: (cast(p.payment_date as date) = '2005-07-30') (rows=634)
```
- Table scan on p сменился на Covering index scan — индекс работает как покрывающий, MySQL читает только индексные страницы, не трогая строки таблицы. Само чтение ускорилось: доступ к payment занял ~12 мс против ~69 мс в прогоне без индекса.
- Но всё остальное на месте: Filter: (cast(...)) по-прежнему применяется после чтения всех 16 044 строк, дальше — декартово произведение (Inner hash join (no condition), 642 000 строк), сортировка (~2.5 сек), оконная агрегация с буферизацией (~4 сек) и дедупликация (~6.77 сек итог).
- Общее время: 6.86 сек против 16.1 сек без индекса — выигрыш в ~2.3 раза только от индекса, но узкие места логики не устранены.


**Общий итог проделанного:**
1. Выполнение EXPLAIN ANALYZE исходного запроса выявило пять узких мест: не SARGable-условие DATE(p.payment_date), декартово произведение с таблицей film из-за отсутствующего условия связи (642 000 промежуточных строк вместо 634 фактических), сортировку раздутого набора под оконную функцию, оконную агрегацию с буферизацией и дедупликацию через временную таблицу (DISTINCT), на которую приходилась большая часть времени выполнения.
2. Создание покрывающего индекса idx_payment_date_rental_amount(payment_date, rental_id, amount) ускорило доступ к данным: полный скан таблицы сменился покрывающим индексным сканом, время сократилось с ~16.1 до ~6.86 сек (в ~2.3 раза). Однако основные узкие места сохранились — индекс не применяется как поиск по диапазону, поскольку функция DATE() вокруг столбца препятствует SARGable-фильтрации.
3. Корректировка операторов (полуинтервал по датам вместо DATE(), явные JOIN со связью film.film_id = inventory.film_id, агрегация через GROUP BY вместо DISTINCT + оконной функции) в сочетании с индексом сократила время выполнения до ~88 мс. В итоговом плане отсутствуют декартово произведение, сортировка, оконная агрегация и временные таблицы; все соединения выполняются как точечные Single-row index lookup по первичным ключам. Суммарное ускорение относительно исходного состояния — примерно в 180 раз.

Вывод: создание индекса даёт ограниченный выигрыш, если структура запроса препятствует его эффективному использованию. Решающее значение имеет корректировка логики запроса: SARGable-условия, явные связи между таблицами и корректная агрегация.

---------------------------------------------------------------------------------------------------------------------

## Задание 3*

Самостоятельно изучите, какие типы индексов используются в PostgreSQL. Перечислите те индексы, которые используются в PostgreSQL, а в MySQL — нет.

Приведите ответ в свободной форме.

## Ответ:

*Список типов индексов, которые есть в PostgreSQL, но недоступны как явные индексы в MySQL (InnoDB):*
- GiST (Generalized Search Tree) — для геоданных, поиска ближайших соседей, триграммного поиска и исключающих ограничений.
- GIN (Generalized Inverted Index) — для полнотекстового поиска, массивов и JSONB.
- SP‑GiST (Space‑Partitioned Generalized Search Tree) — для несбалансированных структур (например, квадродеревьев, k‑d‑деревьев).
- BRIN (Block Range Index) — компактные индексы для огромных таблиц с естественным порядком данных (например, по времени).
- Hash — как явно создаваемый индекс для поиска по точному равенству (в MySQL Hash‑индексы есть только в движке MEMORY, а не в InnoDB).

---------------------------------------------------------------------------------------------------------------------