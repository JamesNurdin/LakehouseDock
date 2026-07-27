WITH sales_cte AS (
    SELECT
        s.s_store_id AS store_id,
        'sales' AS activity,
        SUM(ss.ss_net_paid) AS total_amount,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id
),
returns_cte AS (
    SELECT
        s.s_store_id AS store_id,
        'return' AS activity,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id
)
SELECT
    store_id,
    activity,
    total_amount,
    amount_category
FROM sales_cte
UNION ALL
SELECT
    store_id,
    activity,
    total_amount,
    amount_category
FROM returns_cte
LIMIT 100
