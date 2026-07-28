WITH sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_product_name,
    i.i_units,
    i.i_rec_end_date,
    p.p_promo_sk,
    p.p_promo_name,
    p.p_cost,
    p.p_channel_dmail,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_net_paid_inc_ship > 2000
    AND ws.ws_ship_mode_sk IN (1, 12, 16)
    AND i.i_units = 'Box'
    AND p.p_channel_dmail = 'Y'
    AND i.i_rec_end_date > DATE '1999-12-31'
  GROUP BY
    i.i_item_sk,
    i.i_brand,
    i.i_product_name,
    i.i_units,
    i.i_rec_end_date,
    p.p_promo_sk,
    p.p_promo_name,
    p.p_cost,
    p.p_channel_dmail
)
SELECT
  s.i_item_sk,
  s.i_brand,
  s.i_product_name,
  s.i_units,
  s.i_rec_end_date,
  s.p_promo_name,
  s.total_sales,
  s.total_profit,
  CASE
    WHEN s.p_cost > 1500 THEN 'High Cost'
    ELSE 'Low Cost'
  END AS cost_category,
  RANK() OVER (PARTITION BY s.i_brand ORDER BY s.total_sales DESC) AS brand_sales_rank,
  ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS overall_profit_rank
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
