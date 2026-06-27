WITH promo_data AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        p.p_discount_active,
        d_start.d_date       AS start_date,
        d_start.d_year       AS start_year,
        d_start.d_moy        AS start_month,
        d_end.d_date         AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS duration_days,
        c.c_customer_sk      AS c_customer_sk,
        c.c_preferred_cust_flag
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN customer c
        ON c.c_first_sales_date_sk = d_start.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    start_year,
    start_month,
    COUNT(DISTINCT c_customer_sk) AS distinct_preferred_customers,
    COUNT(p_promo_sk)               AS promotion_count,
    SUM(p_cost)                     AS total_promo_cost,
    AVG(p_cost)                     AS avg_promo_cost,
    AVG(duration_days)              AS avg_promo_duration_days
FROM promo_data
WHERE start_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
GROUP BY start_year, start_month
ORDER BY start_year, start_month
