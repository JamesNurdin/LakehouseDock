WITH sales AS (
    SELECT
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_amount,
        'sales' AS transaction_type
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = cs.cs_promo_sk
              AND p.p_discount_active = 'Y'
      )
    GROUP BY w.w_warehouse_name, sm.sm_ship_mode_id
),
returns AS (
    SELECT
        w.w_warehouse_name,
        sm.sm_ship_mode_id,
        SUM(cr.cr_return_amount) AS total_amount,
        'returns' AS transaction_type
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 12
    GROUP BY w.w_warehouse_name, sm.sm_ship_mode_id
)
SELECT
    s.w_warehouse_name,
    s.sm_ship_mode_id,
    s.total_amount,
    s.transaction_type,
    (SELECT COUNT(*) FROM promotion p WHERE p.p_discount_active = 'Y') AS active_promo_cnt
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) s
ORDER BY s.w_warehouse_name, s.sm_ship_mode_id, s.transaction_type
LIMIT 100
