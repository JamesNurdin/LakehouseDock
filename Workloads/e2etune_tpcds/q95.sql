SELECT
    w.w_state,
    w.w_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(c.c_birth_year) FILTER (WHERE c.c_birth_year BETWEEN 1950 AND 1990) AS avg_birth_year,
    AVG(c.c_birth_month) AS avg_birth_month,
    COUNT(DISTINCT c.c_birth_country) AS distinct_birth_countries,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pref_cust_ratio,
    RANK() OVER (ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS state_rank
FROM
    customer c
JOIN
    warehouse w
    ON w.w_country = c.c_birth_country
WHERE
    c.c_birth_year BETWEEN 1960 AND 1990
    AND w.w_state IS NOT NULL
GROUP BY
    w.w_state,
    w.w_city
HAVING
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY
    total_customers DESC
LIMIT 20
