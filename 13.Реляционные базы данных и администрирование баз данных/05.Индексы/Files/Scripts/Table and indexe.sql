WITH totals AS (
    SELECT
        SUM(INDEX_LENGTH) AS total_index_bytes,
        SUM(DATA_LENGTH + INDEX_LENGTH) AS total_bytes
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = 'sakila'
      AND ENGINE = 'InnoDB'
)
SELECT
    CASE t.TABLE_NAME
        WHEN 'actor'          THEN 'Актёры'
        WHEN 'address'        THEN 'Адреса'
        WHEN 'category'       THEN 'Категории'
        WHEN 'city'           THEN 'Города'
        WHEN 'country'        THEN 'Страны'
        WHEN 'customer'       THEN 'Клиенты'
        WHEN 'film'           THEN 'Фильмы'
        WHEN 'film_actor'     THEN 'Актёры в фильмах'
        WHEN 'film_category'  THEN 'Категории фильмов'
        WHEN 'inventory'      THEN 'Инвентарь'
        WHEN 'language'       THEN 'Языки'
        WHEN 'payment'        THEN 'Платежи'
        WHEN 'rental'         THEN 'Аренды'
        WHEN 'staff'          THEN 'Персонал'
        WHEN 'store'          THEN 'Магазины'
        ELSE t.TABLE_NAME
    END AS 'Название таблицы',
    t.DATA_LENGTH AS 'Размер данных (байт)',
    t.INDEX_LENGTH AS 'Размер индексов (байт)',
    (t.DATA_LENGTH + t.INDEX_LENGTH) AS 'Полный размер таблицы (данные+индексы, байт)',
    ROUND(
        (t.INDEX_LENGTH * 100.0 / NULLIF(t.DATA_LENGTH + t.INDEX_LENGTH, 0)),
        2
    ) AS 'Доля индексов в таблице (%)',
    ROUND(
        (tot.total_index_bytes * 100.0 / NULLIF(tot.total_bytes, 0)),
        2
    ) AS 'Общий процент индексов по БД (%)'
FROM information_schema.TABLES AS t
CROSS JOIN totals AS tot
WHERE t.TABLE_SCHEMA = 'sakila'
  AND t.ENGINE = 'InnoDB'
ORDER BY t.TABLE_NAME;
