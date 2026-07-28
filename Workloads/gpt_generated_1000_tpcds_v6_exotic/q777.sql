WITH filtered_sales AS (
  SELECT cs.cs_sold_date_sk,
         cs.cs_sold_time_sk,
         cs.cs_item_sk,
         cs.cs_bill_customer_sk,
         cs.cs_bill_addr_sk,
         cs.cs_quantity,
         cs.cs_net_paid,
         cs.cs_ext_sales_price,
         cs.cs_catalog_page_sk
  FROM catalog_sales cs
  WHERE cs.cs_quantity > 0
    AND cs.cs_net_paid > 0
)
SELECT
  d.d_year,
  i.i_category,
  i.i_product_name,
  c.c_first_name,
  ca.ca_city,
  cs.cs_quantity,
  cs.cs_net_paid,
  (SELECT avg(cs2.cs_net_paid)
   FROM catalog_sales cs2
   WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_item_net_paid,
  CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_paid DESC) AS sales_rank,
  sr.sr_net_loss,
  r.r_reason_desc,
  ws.web_name
FROM filtered_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Electronics'
  AND c.c_birth_year BETWEEN 1950 AND 1970
  AND r.r_reason_desc LIKE '%damage%'
  AND ws.web_state = 'CA'
  AND t.t_hour BETWEEN 9 AND 17
LIMIT 100
