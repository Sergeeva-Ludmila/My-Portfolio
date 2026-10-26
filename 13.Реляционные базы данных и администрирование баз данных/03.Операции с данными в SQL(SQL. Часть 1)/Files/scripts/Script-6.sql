SELECT
    email,
    CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(email, '@', 1), 1)),
        LOWER(RIGHT(SUBSTRING_INDEX(email, '@', 1), CHAR_LENGTH(SUBSTRING_INDEX(email, '@', 1)) - 1))
    ) AS local_part_formatted,
    CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(email, '@', -1), 1)),
        LOWER(RIGHT(SUBSTRING_INDEX(email, '@', -1), CHAR_LENGTH(SUBSTRING_INDEX(email, '@', -1)) - 1))
    ) AS domain_part_formatted
FROM customer;
