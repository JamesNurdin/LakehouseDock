WITH
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE cs_sales_price > 30
          AND cs_ext_ship_cost < 2000
          AND cs_quantity >= 1
          AND cs_bill_customer_sk IS NOT NULL
          AND cs_ship_hdemo_sk BETWEEN 2000 AND 6000
    ),
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (5)
        WHERE ws_net_paid_inc_ship_tax > 1000
          AND ws_ext_wholesale_cost < 3000
          AND ws_quantity >= 1
          AND ws_ship_date_sk > 2451400
          AND ws_bill_customer_sk IS NOT NULL
    ),
    order_diff AS (
        SELECT cs_order_number
        FROM cs_sample
        EXCEPT
        SELECT ws_order_number
        FROM ws_sample
    ),
    final_agg AS (
        SELECT
            sm_id,
            carrier,
            SUM(cs_net_paid) AS total_cs_net_paid,
            AVG(ws_net_paid_inc_ship_tax) AS avg_ws_net_paid,
            COUNT(DISTINCT order_num) AS num_orders,
            qty_sum
        FROM (
            SELECT
                sm.sm_ship_mode_id AS sm_id,
                sm.sm_carrier   AS carrier,
                cs.cs_net_paid,
                ws.ws_net_paid_inc_ship_tax,
                cs.cs_order_number AS order_num,
                cs.cs_ship_mode_sk,
                l.qty_sum
            FROM cs_sample cs
            JOIN ship_mode sm
                ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
            LEFT JOIN ws_sample ws
                ON cs.cs_order_number = ws.ws_order_number
            CROSS JOIN LATERAL (
                SELECT SUM(cs3.cs_quantity) AS qty_sum
                FROM catalog_sales cs3
                WHERE cs3.cs_ship_mode_sk = cs.cs_ship_mode_sk
            ) l
            WHERE NOT EXISTS (
                SELECT 1
                FROM web_sales ws2
                WHERE ws2.ws_order_number = cs.cs_order_number
                  AND ws2.ws_ship_mode_sk = cs.cs_ship_mode_sk
            )
              AND cs.cs_order_number IN (SELECT cs_order_number FROM order_diff)
        ) sub
        GROUP BY sm_id, carrier, qty_sum
    )
SELECT
    sm_id,
    carrier,
    total_cs_net_paid,
    avg_ws_net_paid,
    num_orders,
    qty_sum
FROM final_agg
WHERE total_cs_net_paid > 5000
  AND avg_ws_net_paid < 20000
  AND num_orders >= 5
  AND qty_sum IS NOT NULL
ORDER BY total_cs_net_paid DESC
OFFSET 0
LIMIT 100
