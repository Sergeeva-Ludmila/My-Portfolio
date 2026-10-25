SELECT constraint_name, table_name, count(*) AS cnt
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY'
  AND table_schema = 'public'
GROUP BY constraint_name, table_name
HAVING count(*) > 1;