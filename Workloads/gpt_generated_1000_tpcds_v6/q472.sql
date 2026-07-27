WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    ca.ca_state,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    t.t_hour
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cs.cs_quantity > 1
    AND cs.cs_ext_sales_price > 100
    AND cc.cc_state = 'CA'
)

SELECT
  ca_state AS state,
  i_category AS category,
  i_brand AS brand,
  t_hour AS hour_of_day,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_net_profit) AS total_profit,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  RANK() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
FROM sales
WHERE EXISTS (
  SELECT 1
  FROM web_returns wr
  WHERE wr.wr_item_sk = sales.cs_item_sk
    AND wr.wr_returned_time_sk = sales.cs_sold_time_sk
    AND wr.wr_return_quantity > 0
)
GROUP BY ca_state, i_category, i_brand, t_hour
HAVING SUM(cs_ext_sales_price) > 5000
   AND COUNT(DISTINCT cs_order_number) >= 5
ORDER BY sales_rank
LIMIT 100
