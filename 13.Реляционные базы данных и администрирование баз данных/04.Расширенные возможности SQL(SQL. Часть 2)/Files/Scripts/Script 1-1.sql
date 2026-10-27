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
