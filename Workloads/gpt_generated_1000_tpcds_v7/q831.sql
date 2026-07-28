WITH filtered AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        d.d_year,
        d.d_month_seq,
        d.d_current_month,
        d.d_current_week,
        d.d_date
    FROM tpcds.customer c
    JOIN tpcds.date_dim d
        ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE 
        d.d_current_month = 'Y'                     -- predicate 1
        AND d.d_current_week = 'N'                  -- predicate 2
        AND d.d_year BETWEEN 2000 AND 2020          -- predicate 3
        AND c.c_birth_year BETWEEN 1950 AND 2000    -- predicate 4
        AND c.c_preferred_cust_flag = 'Y'           -- predicate 5
        AND c.c_last_review_date > 2452400         -- predicate 6
),
agg AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT c_customer_id) AS cust_cnt,
        AVG(c_birth_year) AS avg_birth_year
    FROM filtered
    GROUP BY d_year, d_month_seq
)
SELECT 
    d_year,
    d_month_seq,
    cust_cnt,
    avg_birth_year,
    RANK() OVER (PARTITION BY d_year ORDER BY cust_cnt DESC) AS rank_in_year,
    SUM(cust_cnt) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_cust_cnt
FROM agg
ORDER BY d_year, d_month_seq
