WITH joined_data AS (
  SELECT
    d.d_date,
    d.d_year,
    cc.cc_name,
    ws.web_name,
    cs.cs_ext_sales_price,
    ss.ss_ext_sales_price,
    sr.sr_return_quantity,
    r.r_reason_desc,
    w.w_state
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_moy IN (6, 12)
    AND cc.cc_mkt_class LIKE '%Paintings%'
    AND w.w_state = 'CA'
    AND cs.cs_ext_sales_price > 500
    AND sr.sr_return_quantity > 0
)
SELECT
  d_date,
  d_year,
  cc_name,
  web_name,
  SUM(cs_ext_sales_price) AS total_catalog_sales,
  SUM(ss_ext_sales_price) AS total_store_sales,
  SUM(cs_ext_sales_price + ss_ext_sales_price) AS total_sales,
  CASE
    WHEN SUM(cs_ext_sales_price + ss_ext_sales_price) > 10000 THEN 'High'
    ELSE 'Low'
  END AS sales_level,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price + ss_ext_sales_price) DESC) AS sales_rank
FROM joined_data
GROUP BY d_date, d_year, cc_name, web_name
ORDER BY sales_rank
LIMIT 100
