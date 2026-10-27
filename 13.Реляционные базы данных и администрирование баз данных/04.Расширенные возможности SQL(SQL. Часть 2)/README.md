# 13.05 Расширенные возможности SQL(SQL. Часть 2)

----------------------------------------------------------------------------------------------------------------

**Для выполнения задания с 1 по 5 было проделано:**
1. Развернута СУБД MySQL с учебной базой данных от MySQL - Sakila с помощью docker-compose.

[Конфигурационный файл: docker-compose.yml](Files/docker-compose.yml)

2. И был использован уже установленный **DBeaver** — универсальный графический клиент для работы с базами данных для выполнения SQL-запросов.

3. SQL - запросы ввиде скриптов прикреплены каждый к своему заданию.

4. Данные были взяты из таблиц - базы данных Sakila.

[sakila-data.sql](Files/sakila-db/sakila-data.sql)

[sakila-schema.sql](Files/sakila-db/sakila-schema.sql)


## Задание 1

Одним запросом получите информацию о магазине, в котором обслуживается более 300 покупателей, и выведите в результат следующую информацию:

- фамилия и имя сотрудника из этого магазина;
- город нахождения магазина;
- количество пользователей, закреплённых в этом магазине.

## Ответ:

```sql
SELECT
    CONCAT(stf.first_name, ' ', stf.last_name) AS 'Сотрудник магазина',
    cty.city AS 'Город нахождения магазина',
    COUNT(c.customer_id) AS 'Количество покупателей'
FROM store s
JOIN staff stf ON s.manager_staff_id = stf.staff_id
JOIN address a ON s.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
JOIN customer c ON c.store_id = s.store_id
GROUP BY
    s.store_id,
    stf.staff_id,
    stf.first_name,
    stf.last_name,
    cty.city
HAVING COUNT(c.customer_id) > 300;
```

[Script 1-1.sql](<Files/Scripts/Script 1-1.sql>)

![alt text](<Screenshots/Задание 1-1.png>)

```sql
SELECT
    stf.last_name,
    stf.first_name,
    cty.city,
    COUNT(c.customer_id) AS customers_count
FROM store s
JOIN staff stf ON s.manager_staff_id = stf.staff_id
JOIN address a ON s.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
JOIN customer c ON c.store_id = s.store_id
GROUP BY s.store_id, stf.staff_id, stf.last_name, stf.first_name, cty.city
HAVING COUNT(c.customer_id) > 300;
```

[Script 1-2.sql](<Files/Scripts/Script 1-2.sql>)

![alt text](<Screenshots/Задание 1-2.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 2

Получите количество фильмов, продолжительность которых больше средней продолжительности всех фильмов.

## Ответ:

```sql
SELECT COUNT(*) AS 'Количество фильмов больше средней продолжительности'
FROM film
WHERE length > (SELECT AVG(length) FROM film);
```

[Script-2.sql](Files/Scripts/Script-2.sql)

![alt text](<Screenshots/Задание 2-1.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 3

Получите информацию, за какой месяц была получена наибольшая сумма платежей, и добавьте информацию по количеству аренд за этот месяц.

## Ответ:

```sql
SELECT
    DATE_FORMAT(p.payment_date, '%Y-%m') AS 'Год и месяц c наибольшей суммой платежей',
    SUM(p.amount) AS 'Сумма платежей за месяц',
    COUNT(r.rental_id) AS 'Количество аренд за месяц'
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY SUM(p.amount) DESC
LIMIT 1;
```

[Script-3.sql](Files/Scripts/Script-3.sql)

![alt text](<Screenshots/Задание 3-1.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 4*

Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку «Премия». Если количество продаж превышает 8000, то значение в колонке будет «Да», иначе должно быть значение «Нет».

## Ответ:

```sql
SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS 'Сотрудник',
    COUNT(p.payment_id) AS 'Количество продаж',
    CASE
        WHEN COUNT(p.payment_id) > 8000 THEN 'Да'
        ELSE 'Нет'
    END AS 'Премия'
FROM staff s
JOIN payment p ON s.staff_id = p.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY COUNT(p.payment_id) DESC;
```

[Script-4.sql](Files/Scripts/Script-4.sql)

![alt text](<Screenshots/Задание 4-1.png>)

----------------------------------------------------------------------------------------------------------------

## Задание 5*

Найдите фильмы, которые ни разу не брали в аренду.

## Ответ:

```sql
SELECT
    f.film_id AS 'ID фильма',
    f.title AS 'Название фильма',
    f.length AS 'Длительность (мин)',
    'Не арендовался' AS 'Статус'
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL;
```

[Script-5.sql](Files/Scripts/Script-5.sql)

![alt text](<Screenshots/Задание 5-1.png>)

----------------------------------------------------------------------------------------------------------------