WITH item_sales AS (
  SELECT i.i_item_id, i.i_product_name, i.i_brand, i.i_category, t.t_hour,
    SUM(ws.ws_quantity) AS qty_sold,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS promo_cost
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category, t.t_hour
)
SELECT i_item_id,
  i_product_name,
  i_brand,
  i_category,
  t_hour,
  qty_sold,
  net_profit,
  promo_cost,
  CASE WHEN net_profit > 0 THEN (net_profit - promo_cost) / net_profit ELSE NULL END AS profit_margin_after_promo,
  RANK() OVER (PARTITION BY i_brand ORDER BY net_profit DESC) AS brand_rank,
  DENSE_RANK() OVER (ORDER BY net_profit DESC) AS overall_dense_rank
FROM item_sales
WHERE qty_sold > 0
ORDER BY i_brand, net_profit DESC
LIMIT 200
