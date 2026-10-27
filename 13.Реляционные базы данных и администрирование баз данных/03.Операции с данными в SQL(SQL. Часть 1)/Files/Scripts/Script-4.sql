SELECT
    REPLACE(LOWER(first_name), 'll', 'pp') AS first_name_formatted,
    LOWER(last_name) AS last_name_formatted
FROM customer
WHERE active = 1
  AND first_name IN ('Kelly', 'Willie');
