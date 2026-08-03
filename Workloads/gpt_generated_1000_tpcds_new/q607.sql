WITH
  catalog_sample AS (
    SELECT cs.*
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (5)   -- sample 5% of rows
    WHERE cs.cs_net_paid_inc_tax > 500
  ),
  promo_diff AS (
    SELECT cs.cs_promo_sk AS promo_sk
    FROM tpcds.catalog_sales cs
    EXCEPT
    SELECT ws.ws_promo_sk
    FROM tpcds.web_sales ws
  ),
  promo_with_catalog AS (
    SELECT p.p_promo_sk, p.p_promo_name, p.p_discount_active
    FROM tpcds.promotion p
    WHERE EXISTS (
      SELECT 1 FROM catalog_sample cs
      WHERE cs.cs_promo_sk = p.p_promo_sk
    )
  )
SELECT
  d.d_year,
  p.p_promo_name,
  COUNT(DISTINCT cs.cs_order_number)               AS catalog_orders,
  SUM(cs.cs_ext_sales_price)                       AS catalog_sales_amount,
  SUM(ss.ss_net_paid_inc_tax)                      AS store_sales_amount,
  SUM(ws.ws_ext_sales_price)                       AS web_sales_amount,
  COUNT(DISTINCT ca_bill.ca_address_sk)            AS distinct_bill_addresses,
  COUNT(DISTINCT ca_ship.ca_address_sk)            AS distinct_ship_addresses
FROM catalog_sample cs
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
RIGHT OUTER JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_promo_sk = cs.cs_promo_sk
LEFT JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d.d_date_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.web_site webs
  ON ws.ws_web_site_sk = webs.web_site_sk
WHERE p.p_promo_sk IN (SELECT promo_sk FROM promo_diff)
  AND d.d_year = 2001
GROUP BY
  d.d_year,
  p.p_promo_name
ORDER BY
  catalog_sales_amount DESC
LIMIT 100
