WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk BETWEEN 2452000 AND 2452400
      AND ws.ws_ext_ship_cost > 100
      AND ws.ws_quantity >= 1
      AND ws.ws_net_profit IS NOT NULL
    GROUP BY ws.ws_warehouse_sk
)
SELECT DISTINCT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    agg.order_cnt,
    agg.total_sales,
    agg.total_profit,
    agg.total_ship_cost,
    CASE WHEN agg.total_profit > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    RANK() OVER (PARTITION BY w.w_state ORDER BY agg.total_profit DESC) AS profit_state_rank,
    ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS overall_rank
FROM warehouse w
JOIN ws_agg agg
  ON agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_warehouse_sk = w.w_warehouse_sk
          AND w2.w_suite_number LIKE 'Suite %'
          AND w2.w_gmt_offset >= -5.00
          AND w2.w_gmt_offset <= 5.00
          AND w2.w_city = w.w_city
      )
  AND w.w_state IN ('CA', 'TX', 'NY', 'WA')
  AND w.w_city <> 'Unknown'
ORDER BY agg.total_profit DESC
LIMIT 100
