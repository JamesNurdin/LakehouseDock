/* goal: Compare total net profit from web sales and total return amount by ship mode for specific customer demographics and carriers, ranking each metric */
WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_amount,
        'sales' AS metric
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND c.c_birth_month IN (2, 8)
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_image_count > 3
      )
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
returns_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_mode_type,
        SUM(wr.wr_return_amt) AS total_amount,
        'returns' AS metric
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND wr.wr_return_amt > 0
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT
    ship_mode_id,
    ship_mode_type,
    total_amount,
    metric,
    RANK() OVER (PARTITION BY metric ORDER BY total_amount DESC) AS metric_rank
FROM (
    SELECT ship_mode_id, ship_mode_type, total_amount, metric FROM sales_agg
    UNION ALL
    SELECT ship_mode_id, ship_mode_type, total_amount, metric FROM returns_agg
) t
ORDER BY metric, metric_rank
LIMIT 100
