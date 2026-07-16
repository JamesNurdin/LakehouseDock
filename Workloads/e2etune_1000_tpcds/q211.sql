WITH cust_by_country AS (
    SELECT
        c.c_birth_country,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cnt
    FROM customer c
    WHERE c.c_birth_day IN (7, 15, 30)
      AND c.c_email_address LIKE '%@%.edu'
    GROUP BY c.c_birth_country
)
SELECT
    w.web_site_id,
    w.web_name,
    w.web_country,
    cb.cust_cnt,
    cb.avg_birth_year,
    cb.pref_cnt,
    ROUND(cb.pref_cnt * 100.0 / NULLIF(cb.cust_cnt, 0), 2) AS pref_pct,
    RANK() OVER (ORDER BY cb.cust_cnt DESC) AS cust_rank
FROM cust_by_country cb
JOIN web_site w
    ON cb.c_birth_country = w.web_country
WHERE w.web_state = 'CA'
ORDER BY cb.cust_cnt DESC
LIMIT 20
