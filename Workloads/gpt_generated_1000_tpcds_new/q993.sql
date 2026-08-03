/* goal: Identify top‑profit web sales per state for selected promotion and shipping characteristics, classify profit levels, and compare two filtered segments using a UNION with window ranking and lateral aggregations */
WITH sales_with_qty AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_promo_sk,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        p.p_promo_id,
        p.p_cost,
        p.p_channel_event,
        sm.sm_carrier,
        w.w_warehouse_id,
        w.w_state,
        l.total_qty
    FROM web_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_quantity) AS total_qty
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
    ) l
)
SELECT
    w_warehouse_id,
    p_promo_id,
    sm_carrier,
    ws_net_profit,
    CASE WHEN ws_net_profit > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY w_state ORDER BY ws_net_profit DESC) AS profit_rank,
    total_qty,
    (SELECT AVG(ws3.ws_ext_discount_amt)
     FROM web_sales ws3
     WHERE ws3.ws_promo_sk = ws_promo_sk) AS avg_discount
FROM sales_with_qty
WHERE p_cost > 500
  AND p_channel_event = 'N'
  AND sm_carrier = 'MSC'
  AND w_state = 'CA'
  AND ws_ext_sales_price > 1000

UNION DISTINCT

SELECT
    w_warehouse_id,
    p_promo_id,
    sm_carrier,
    ws_net_profit,
    CASE WHEN ws_net_profit > 3000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY w_state ORDER BY ws_net_profit DESC) AS profit_rank,
    total_qty,
    (SELECT AVG(ws3.ws_ext_discount_amt)
     FROM web_sales ws3
     WHERE ws3.ws_promo_sk = ws_promo_sk) AS avg_discount
FROM sales_with_qty
WHERE p_cost > 200
  AND p_channel_event = 'N'
  AND sm_carrier = 'DIAMOND'
  AND w_state = 'NY'
  AND ws_ext_sales_price > 2000

ORDER BY profit_rank ASC
OFFSET 0 LIMIT 100
