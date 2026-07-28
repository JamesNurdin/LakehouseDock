WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    d_sold.d_year,
    cc.cc_name,
    i.i_category,
    i.i_product_name,
    p.p_promo_name,
    sm.sm_type,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
    AND p.p_channel_email = 'Y'
    AND sm.sm_type = 'AIR'
    AND cc.cc_employees > 50
)
SELECT
  b.cc_name,
  b.i_category,
  b.i_product_name,
  SUM(b.cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT b.cs_order_number) AS orders_count,
  SUM(CASE WHEN EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = b.cs_order_number
          AND cr.cr_return_quantity > 0
      ) THEN 1 ELSE 0 END) AS return_orders,
  RANK() OVER (ORDER BY SUM(b.cs_net_profit) DESC) AS profit_rank
FROM base b
GROUP BY
  b.cc_name,
  b.i_category,
  b.i_product_name
ORDER BY profit_rank
LIMIT 100
