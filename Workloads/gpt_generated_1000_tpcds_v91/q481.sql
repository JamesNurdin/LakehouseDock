WITH fact1 AS (
   SELECT
     d_cs.d_year AS year,
     i.i_item_id AS item_id,
     i.i_brand AS brand,
     cs.cs_quantity * cs.cs_sales_price AS sales_amount,
     sr.sr_return_amt_inc_tax AS return_amount,
     ws.ws_quantity * ws.ws_sales_price AS web_sales_amount,
     wr.wr_return_amt_inc_tax AS web_return_amount,
     cc.cc_name AS call_center_name,
     cp.cp_type AS catalog_page_type,
     p_cs.p_promo_name AS promo_name,
     we.web_name AS website_name,
     ca_bill.ca_state AS customer_state
   FROM catalog_sales cs
   JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d_cs.d_date_sk
   LEFT JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d_cs.d_date_sk
   LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   WHERE d_cs.d_year = 2001
     AND ca_bill.ca_state = 'CA'
     AND cc.cc_gmt_offset >= -5.00
     AND we.web_tax_percentage > 0.0
),
fact2 AS (
   SELECT
     d_cs.d_year AS year,
     i.i_item_id AS item_id,
     i.i_brand AS brand,
     cs.cs_quantity * cs.cs_sales_price AS sales_amount,
     sr.sr_return_amt_inc_tax AS return_amount,
     ws.ws_quantity * ws.ws_sales_price AS web_sales_amount,
     wr.wr_return_amt_inc_tax AS web_return_amount,
     cc.cc_name AS call_center_name,
     cp.cp_type AS catalog_page_type,
     p_cs.p_promo_name AS promo_name,
     we.web_name AS website_name,
     ca_bill.ca_state AS customer_state
   FROM catalog_sales cs
   JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d_cs.d_date_sk
   LEFT JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d_cs.d_date_sk
   LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   WHERE d_cs.d_year = 2002
     AND ca_bill.ca_state = 'NY'
     AND cc.cc_gmt_offset >= -2.00
     AND p_cs.p_discount_active = 'Y'
),
combined AS (
   SELECT * FROM fact1
   UNION DISTINCT
   SELECT * FROM fact2
),
agg AS (
   SELECT
     year,
     item_id,
     brand,
     SUM(sales_amount) AS total_sales,
     SUM(return_amount) AS total_returns,
     SUM(web_sales_amount) AS total_web_sales,
     SUM(web_return_amount) AS total_web_returns,
     COUNT(DISTINCT call_center_name) AS distinct_call_centers,
     COUNT(DISTINCT promo_name) AS distinct_promos,
     COUNT(DISTINCT website_name) AS distinct_websites
   FROM combined
   GROUP BY year, item_id, brand
   HAVING SUM(sales_amount) > 5000
)
SELECT
  a.year,
  a.item_id,
  a.brand,
  a.total_sales,
  a.total_returns,
  a.total_web_sales,
  a.total_web_returns,
  a.distinct_call_centers,
  a.distinct_promos,
  a.distinct_websites,
  (a.total_sales - COALESCE(a.total_returns, 0) + a.total_web_sales - COALESCE(a.total_web_returns, 0)) AS net_sales
FROM agg a
WHERE NOT EXISTS (
   SELECT 1
   FROM store_returns sr2
   JOIN item i2 ON sr2.sr_item_sk = i2.i_item_sk
   WHERE i2.i_item_id = a.item_id
     AND sr2.sr_net_loss > 1000
)
ORDER BY net_sales DESC
LIMIT 100
