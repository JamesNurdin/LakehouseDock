WITH
  d_sold AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_ship AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  ),
  d_closed AS (
    SELECT * FROM date_dim WHERE d_year = 2001
  )
SELECT
  s.s_store_name,
  w.w_warehouse_name,
  d_sold.d_year,
  d_sold.d_month_seq,
  SUM(cs.cs_net_paid)                AS total_catalog_net_paid,
  SUM(ss.ss_net_paid)                AS total_store_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(cs.cs_ext_discount_amt)        AS avg_catalog_discount,
  MAX(ss.ss_ext_tax)                 AS max_store_tax,
  MIN(w.w_warehouse_sq_ft)           AS min_warehouse_sq_ft
FROM catalog_sales cs
JOIN d_sold   ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN d_ship   ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s   ON ss.ss_store_sk = s.s_store_sk
JOIN d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
  ss.ss_coupon_amt > 100
  AND cs.cs_ext_sales_price > 5000
  AND s.s_state = 'CA'
  AND w.w_state = 'TX'
  AND w.w_gmt_offset = -6.00
GROUP BY
  s.s_store_name,
  w.w_warehouse_name,
  d_sold.d_year,
  d_sold.d_month_seq
ORDER BY
  total_catalog_net_paid DESC,
  s.s_store_name ASC
LIMIT 100
