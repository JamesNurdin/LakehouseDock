WITH refunds AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_birth_month AS birth_month,
        c.c_preferred_cust_flag AS preferred_flag,
        SUM(sr.sr_return_amt_inc_tax) AS metric1,
        SUM(sr.sr_refunded_cash) AS metric2,
        CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 1000 THEN 'HighValue' ELSE 'LowValue' END AS category
    FROM tpcds.customer c
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_refunded_cash > 100
    GROUP BY c.c_customer_id, c.c_birth_month, c.c_preferred_cust_flag
),
high_qty AS (
    SELECT DISTINCT
        c.c_customer_id AS customer_id,
        c.c_birth_month AS birth_month,
        c.c_preferred_cust_flag AS preferred_flag,
        SUM(sr.sr_return_amt) AS metric1,
        SUM(sr.sr_return_tax) AS metric2,
        CASE WHEN SUM(sr.sr_return_amt) > 500 THEN 'HighReturn' ELSE 'RegularReturn' END AS category
    FROM tpcds.customer c
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity >= 2
    GROUP BY c.c_customer_id, c.c_birth_month, c.c_preferred_cust_flag
)
SELECT
    COALESCE(birth_month, -1) AS birth_month,
    COALESCE(preferred_flag, 'All') AS preferred_flag,
    SUM(metric1) AS total_metric1,
    SUM(metric2) AS total_metric2,
    COUNT(DISTINCT category) AS distinct_category_count
FROM (
    SELECT * FROM refunds
    UNION ALL
    SELECT * FROM high_qty
) u
GROUP BY GROUPING SETS (
    (birth_month, preferred_flag),
    (birth_month),
    (preferred_flag),
    ()
)
ORDER BY
    birth_month ASC NULLS LAST,
    preferred_flag ASC NULLS LAST
LIMIT 100
