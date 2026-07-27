SELECT
    i.i_category,
    i.i_brand,
    cc.cc_name,
    d1.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN date_dim d1
  ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN customer cust
  ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d2
  ON cr.cr_returned_date_sk = d2.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d3
  ON ws.ws_sold_date_sk = d3.d_date_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
WHERE d1.d_year = 2001
  AND d2.d_month_seq BETWEEN 1200 AND 1210
  AND cc.cc_state = 'CA'
  AND cust.c_preferred_cust_flag = 'Y'
  AND ib.ib_upper_bound >= 50000
  AND sm.sm_type = 'AIR'
  AND i.i_color = 'Red'
  AND web.web_country = 'USA'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
      )
GROUP BY i.i_category, i.i_brand, cc.cc_name, d1.d_year
ORDER BY total_sales_amount DESC
LIMIT 100
