WITH customer_month_stats AS (
    SELECT
        c.c_birth_month,
        COUNT(*) AS cust_cnt,
        AVG(c.c_birth_year) AS avg_birth_year,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
    FROM customer c
    WHERE c.c_birth_month IN (12, 4, 9, 6, 5)
      AND c.c_preferred_cust_flag IS NOT NULL
    GROUP BY c.c_birth_month
)
SELECT
    sm.sm_type,
    cms.c_birth_month,
    cms.cust_cnt,
    cms.avg_birth_year,
    cms.pref_cust_cnt,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY cms.cust_cnt DESC) AS month_rank
FROM ship_mode sm
JOIN customer_month_stats cms ON 1 = 1
WHERE sm.sm_type IS NOT NULL
ORDER BY sm.sm_type, month_rank
LIMIT 100
