WITH base_agg AS (
  SELECT
    p.p_promo_id,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND cs.cs_quantity > 1
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND we.web_country = 'United States'
  GROUP BY p.p_promo_id, d.d_year
)
SELECT
  p_promo_id,
  d_year,
  total_sales,
  total_catalog_returns,
  total_store_returns,
  total_web_sales,
  order_cnt,
  net_profit
FROM (
  SELECT
    p_promo_id,
    d_year,
    total_sales,
    total_catalog_returns,
    total_store_returns,
    total_web_sales,
    order_cnt,
    (total_sales - total_catalog_returns - total_store_returns - total_web_sales) AS net_profit
  FROM base_agg
  WHERE total_sales > 10000
  UNION ALL
  SELECT
    p_promo_id,
    d_year,
    total_sales,
    total_catalog_returns,
    total_store_returns,
    total_web_sales,
    order_cnt,
    (total_sales * 0.9) AS net_profit
  FROM base_agg
  WHERE total_sales <= 10000
) AS combined
ORDER BY net_profit DESC
LIMIT 100
