WITH promo_sales AS (
  SELECT
    w.w_state,
    p.p_promo_name,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'Y'
    AND p.p_channel_tv = 'Y'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
  GROUP BY w.w_state, p.p_promo_name
)
SELECT
  w_state,
  p_promo_name,
  total_sales,
  total_discount,
  total_profit,
  total_quantity,
  ROUND(total_profit / NULLIF(total_quantity, 0), 2) AS profit_per_unit,
  RANK() OVER (PARTITION BY p_promo_name ORDER BY total_profit DESC) AS profit_rank
FROM promo_sales
WHERE total_profit > 0
ORDER BY total_profit DESC
LIMIT 20
