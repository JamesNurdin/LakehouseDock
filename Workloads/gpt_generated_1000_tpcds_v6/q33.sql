SELECT
    d.d_year,
    c.c_last_name,
    cp.cp_department,
    w.w_state,
    ws.web_site_id,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs.cs_coupon_amt) AS avg_coupon,
    MIN(cs.cs_ext_sales_price) AS min_ext_sales,
    MAX(cs.cs_ext_sales_price) AS max_ext_sales,
    SUM(cs.cs_quantity) AS total_quantity
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND c.c_last_name = 'Little'
  AND cp.cp_department = 'Books'
  AND w.w_state = 'CA'
  AND ws.web_country = 'United States'
  AND cs.cs_net_paid_inc_ship_tax > 1000.0
  AND cs.cs_coupon_amt < 500.0
  AND cs.cs_promo_sk IN (731, 352)
  AND wr.wr_return_quantity = 0
GROUP BY
    d.d_year,
    c.c_last_name,
    cp.cp_department,
    w.w_state,
    ws.web_site_id
ORDER BY total_net_paid DESC
LIMIT 100
