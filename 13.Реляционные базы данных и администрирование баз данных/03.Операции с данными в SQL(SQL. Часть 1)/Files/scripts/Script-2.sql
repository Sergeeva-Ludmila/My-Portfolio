SELECT *
FROM payment
WHERE payment_date >= '2005-06-15 00:00:00'
  AND payment_date <= '2005-06-18 23:59:59'
  AND amount > 10.00
ORDER BY payment_date;
