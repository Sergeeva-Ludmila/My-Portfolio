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
