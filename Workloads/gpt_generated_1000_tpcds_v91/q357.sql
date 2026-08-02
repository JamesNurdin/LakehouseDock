WITH sales_sub AS (
    SELECT
        'sale' AS activity_type,
        c.c_customer_id AS customer_id,
        cs.cs_net_paid AS amount,
        cs.cs_sold_date_sk AS activity_date_sk,
        sm.sm_ship_mode_id AS ship_mode
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND cs.cs_net_profit > 0
),
store_ret_sub AS (
    SELECT
        'store_return' AS activity_type,
        c.c_customer_id AS customer_id,
        sr.sr_return_amt AS amount,
        sr.sr_returned_date_sk AS activity_date_sk,
        NULL AS ship_mode
    FROM store_returns sr
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning' OR t.t_sub_shift IS NULL
)
SELECT
    unioned.activity_type,
    unioned.customer_id,
    unioned.amount,
    unioned.activity_date_sk,
    unioned.ship_mode
FROM (
    SELECT activity_type, customer_id, amount, activity_date_sk, ship_mode FROM sales_sub
    UNION ALL
    SELECT activity_type, customer_id, amount, activity_date_sk, ship_mode FROM store_ret_sub
) AS unioned
WHERE unioned.amount > (
    SELECT AVG(cs.cs_net_paid)
    FROM catalog_sales cs
    JOIN customer c2 ON cs.cs_bill_customer_sk = c2.c_customer_sk
    WHERE c2.c_customer_id = unioned.customer_id
)
ORDER BY unioned.activity_type, unioned.amount DESC
LIMIT 100
