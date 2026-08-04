WITH cs_agg AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_catalog_page_sk,
    cs.cs_promo_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM tpcds.catalog_sales cs
  WHERE cs.cs_ext_sales_price > 100
    AND cs.cs_quantity >= 1
    AND cs.cs_wholesale_cost > 0
    AND cs.cs_list_price > cs.cs_wholesale_cost
    AND cs.cs_ext_discount_amt < 5000
  GROUP BY
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_catalog_page_sk,
    cs.cs_promo_sk
)
SELECT
  d.d_year,
  t_sold.t_hour,
  i.i_category,
  i.i_brand,
  cc.cc_name,
  sm.sm_type,
  cp.cp_type,
  p.p_promo_name,
  wp.wp_type,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  SUM(ca.total_sales) AS yearly_sales,
  SUM(ca.total_profit) AS yearly_profit,
  COUNT(DISTINCT ca.cs_item_sk) AS distinct_items,
  AVG(ca.total_sales) AS avg_item_sales,
  COUNT(DISTINCT wr.wr_order_number) AS return_orders
FROM cs_agg ca
JOIN tpcds.item i
  ON ca.cs_item_sk = i.i_item_sk
JOIN tpcds.date_dim d
  ON ca.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t_sold
  ON ca.cs_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.call_center cc
  ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
  ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.catalog_page cp
  ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p
  ON ca.cs_promo_sk = p.p_promo_sk
LEFT JOIN tpcds.web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
     AND d.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND i.i_brand IN ('Brand#12', 'Brand#23')
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND cp.cp_department = 'Sports'
  AND t_sold.t_hour BETWEEN 9 AND 17
GROUP BY
  d.d_year,
  t_sold.t_hour,
  i.i_category,
  i.i_brand,
  cc.cc_name,
  sm.sm_type,
  cp.cp_type,
  p.p_promo_name,
  wp.wp_type,
  hd.hd_buy_potential,
  ib.ib_lower_bound
HAVING SUM(ca.total_sales) > 100000
   AND COUNT(DISTINCT ca.cs_item_sk) >= 5
ORDER BY yearly_sales DESC
LIMIT 100
