WITH distinct_promos AS (
    SELECT DISTINCT p_promo_sk, p_promo_name
    FROM promotion
    WHERE p_channel_catalog = 'Y'
),
cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
    WHERE cs_sold_time_sk IN (31835, 74512, 10687, 77322, 40538)
)

SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship,
    cr.cr_return_amount,
    dp.p_promo_name,
    sm.sm_type,
    t_cs.t_hour AS cs_hour,
    t_cr.t_hour AS cr_hour,
    t_ss.t_hour AS ss_hour,
    ss.ss_net_paid,
    DENSE_RANK() OVER (ORDER BY cs.cs_net_paid_inc_ship DESC) AS order_rank,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_reason_sk = cr.cr_reason_sk) AS avg_return_amt_for_reason,
    CASE
        WHEN cr.cr_return_amount > 0 THEN 'Returned'
        ELSE 'No Return'
    END AS return_flag
FROM cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN distinct_promos dp
    ON cs.cs_promo_sk = dp.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN store_sales ss
    ON ss.ss_promo_sk = dp.p_promo_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
WHERE
    cs.cs_net_paid_inc_ship > 2000
    AND cr.cr_return_quantity > 0
    AND sm.sm_type = 'AIR'
    AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
          AND r.r_reason_desc LIKE '%damaged%'
    )
    AND t_cs.t_hour BETWEEN 9 AND 17
ORDER BY cs.cs_net_paid_inc_ship DESC
LIMIT 100
