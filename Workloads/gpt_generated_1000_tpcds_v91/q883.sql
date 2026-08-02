WITH cs_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_ship_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_customer_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_ship_mode_sk,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_ext_ship_cost,
    cs.cs_ext_tax,
    -- Array and map for UNNEST demonstration
    ARRAY[cs.cs_quantity, cs.cs_sales_price] AS qty_price_arr,
    MAP(ARRAY['quantity','sales_price'], ARRAY[cs.cs_quantity, cs.cs_sales_price]) AS qty_price_map
  FROM catalog_sales cs
  WHERE cs.cs_quantity > 0
    AND cs.cs_sales_price > 0
    AND cs.cs_ext_sales_price > 0
    AND cs.cs_ext_discount_amt >= 0
    AND cs.cs_ext_ship_cost >= 0
    AND cs.cs_ext_tax >= 0
)
SELECT
  d.d_year,
  i.i_category,
  c.c_first_name,
  c.c_last_name,
  sm.sm_type,
  p.p_promo_name,
  t.metric,
  SUM(t.amount) AS metric_total,
  SUM(cs_base.cs_ext_sales_price) AS total_sales,
  AVG(cs_base.cs_quantity) AS avg_quantity,
  COUNT(DISTINCT cs_base.cs_order_number) AS orders_cnt,
  MIN(cs_base.cs_net_paid) AS min_net_paid,
  MAX(cs_base.cs_net_paid) AS max_net_paid,
  SUM(CASE WHEN cs_base.cs_net_profit > 0 THEN cs_base.cs_net_profit ELSE 0 END) AS total_positive_profit,
  (SELECT MAX(p2.p_cost) FROM promotion p2) AS max_promo_cost
FROM cs_base
JOIN date_dim d ON cs_base.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs_base.cs_item_sk = i.i_item_sk
JOIN customer c ON cs_base.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs_base.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm ON cs_base.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs_base.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
CROSS JOIN UNNEST(cs_base.qty_price_map) AS t(metric, amount)
WHERE
  d.d_year = 2000
  AND i.i_brand = 'Brand#12'
  AND sm.sm_code = 'AIR'
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'California'
  AND wsit.web_country = 'United States'
  AND cd.cd_gender = 'M'
  AND cs_base.cs_item_sk IN (
    SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red'
  )
  AND NOT EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_item_sk = i.i_item_sk
      AND sr2.sr_return_quantity > cs_base.cs_quantity
  )
GROUP BY
  d.d_year,
  i.i_category,
  c.c_first_name,
  c.c_last_name,
  sm.sm_type,
  p.p_promo_name,
  t.metric
ORDER BY total_sales DESC
LIMIT 100
