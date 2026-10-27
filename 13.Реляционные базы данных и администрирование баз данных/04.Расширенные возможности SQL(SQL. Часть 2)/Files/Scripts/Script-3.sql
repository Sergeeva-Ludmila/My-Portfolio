SELECT
    DATE_FORMAT(p.payment_date, '%Y-%m') AS 'Год и месяц c наибольшей суммой платежей',
    SUM(p.amount) AS 'Сумма платежей за месяц',
    COUNT(r.rental_id) AS 'Количество аренд за месяц'
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY SUM(p.amount) DESC
LIMIT 1;
