WITH item_sales AS (
  SELECT i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    ws.ws_ship_mode_sk,
    t.t_shift,
    SUM(ws.ws_net_profit) AS item_net_profit,
    SUM(ws.ws_quantity) AS item_qty,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_promo_cost
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category, ws.ws_ship_mode_sk, t.t_shift
),
category_avg AS (
  SELECT i_category,
    t_shift,
    AVG(item_net_profit) OVER (PARTITION BY i_category, t_shift) AS category_avg_net_profit
  FROM item_sales
)
SELECT isel.i_item_id,
  isel.i_product_name,
  isel.i_brand,
  isel.i_category,
  isel.ws_ship_mode_sk AS ship_mode,
  isel.t_shift,
  isel.item_net_profit,
  isel.item_qty,
  isel.orders,
  isel.total_promo_cost,
  ca.category_avg_net_profit,
  CASE WHEN isel.item_net_profit > ca.category_avg_net_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_category,
  RANK() OVER (PARTITION BY isel.i_category ORDER BY isel.item_net_profit DESC) AS category_item_rank,
  DENSE_RANK() OVER (ORDER BY isel.item_net_profit DESC) AS overall_item_dense_rank
FROM item_sales isel
JOIN category_avg ca ON isel.i_category = ca.i_category AND isel.t_shift = ca.t_shift
WHERE isel.item_qty > 0
ORDER BY isel.i_category, isel.item_net_profit DESC
LIMIT 200
