SELECT
    email,
    SUBSTRING_INDEX(email, '@', 1) AS local_part,
    SUBSTRING_INDEX(email, '@', -1) AS domain_part
FROM customer;
