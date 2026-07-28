WITH sales_agg AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_state,
    cp.cp_department,
    sm.sm_code,
    w.w_state,
    SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_catalog_sales,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
  WHERE cc.cc_state = 'CA'
    AND cp.cp_department = 'Sports'
    AND sm.sm_code = 'AIR'
    AND w.w_state = 'CA'
    AND c.c_birth_country = 'United States'
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_coupon_amt > 0
    AND inv.inv_quantity_on_hand > 0
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_ext_sales_price > 1000
    )
  GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_state,
    cp.cp_department,
    sm.sm_code,
    w.w_state
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  total_catalog_sales,
  total_web_sales,
  total_returns,
  total_inventory
FROM sales_agg
WHERE total_catalog_sales > (
    SELECT AVG(total_catalog_sales) FROM sales_agg
)
ORDER BY total_catalog_sales DESC
LIMIT 100
