WITH
  fact_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk      AS t_time_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_quantity,
      ws.ws_promo_sk,
      p.p_promo_name,
      p.p_channel_tv,
      p.p_discount_active,
      t.t_time,
      t.t_hour,
      t.t_minute,
      s.web_site_id,
      s.web_name,
      s.web_state,
      r.wr_return_quantity,
      r.wr_net_loss
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN web_returns r
      ON r.wr_item_sk = ws.ws_item_sk
     AND r.wr_order_number = ws.ws_order_number
    WHERE ws.ws_ext_sales_price > 500
      AND ws.ws_quantity BETWEEN 2 AND 10
      AND p.p_channel_tv = 'N'
      AND s.web_state IN ('CA', 'TX', 'NY')
      AND t.t_minute IN (12, 15, 16)
      AND ws.ws_net_profit IS NOT NULL
  ),
  scalar_avg AS (
    SELECT avg(ws_ext_sales_price) AS avg_price FROM web_sales
  ),
  intersect_set AS (
    SELECT ws_order_number FROM fact_join WHERE ws_ext_sales_price > 1000
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 5
  ),
  except_set AS (
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit < 0
    EXCEPT
    SELECT wr_order_number FROM web_returns WHERE wr_return_quantity > 0
  ),
  cross_join_set AS (
    SELECT t.t_time_sk, v.val
    FROM (SELECT 1 AS val UNION ALL SELECT 2) v
    CROSS JOIN (
      SELECT t_time_sk FROM time_dim WHERE t_hour = 12 LIMIT 2
    ) t
  ),
  ranked AS (
    SELECT
      ws_order_number,
      ws_ext_sales_price,
      ws_net_profit,
      ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY ws_net_profit DESC) AS rn_profit,
      RANK() OVER (PARTITION BY web_state ORDER BY ws_ext_sales_price DESC) AS r_price_state
    FROM fact_join
  ),
  union_set AS (
    SELECT ws_order_number, ws_ext_sales_price AS metric FROM fact_join WHERE ws_ext_sales_price > 800
    UNION
    SELECT ws_order_number, ws_net_profit      AS metric FROM fact_join WHERE ws_net_profit > 200
  )
SELECT
  f.ws_order_number,
  f.ws_ext_sales_price,
  f.ws_net_profit,
  f.p_promo_name,
  f.web_name,
  f.t_hour,
  r.rn_profit,
  r.r_price_state,
  CASE WHEN f.ws_ext_sales_price > (SELECT avg_price FROM scalar_avg) THEN 'Above Avg' ELSE 'Below Avg' END AS price_vs_avg,
  i.ws_order_number          AS intersect_order,
  e.ws_order_number          AS except_order,
  c.val                      AS cross_val,
  u.metric                   AS union_metric
FROM fact_join f
LEFT JOIN ranked r      ON f.ws_order_number = r.ws_order_number
LEFT JOIN intersect_set i ON f.ws_order_number = i.ws_order_number
LEFT JOIN except_set e   ON f.ws_order_number = e.ws_order_number
LEFT JOIN cross_join_set c ON f.t_time_sk = c.t_time_sk
LEFT JOIN union_set u    ON f.ws_order_number = u.ws_order_number
ORDER BY f.ws_ext_sales_price DESC, r.rn_profit
LIMIT 100
