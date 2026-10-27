SELECT
    f.film_id AS 'ID фильма',
    f.title AS 'Название фильма',
    f.length AS 'Длительность (мин)',
    'Не арендовался' AS 'Статус'
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL;
