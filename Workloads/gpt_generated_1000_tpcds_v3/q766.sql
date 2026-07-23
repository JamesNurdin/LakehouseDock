WITH aggregated AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ca.ca_state,
    sm.sm_type,
    r.r_reason_desc,
    wp.wp_type,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    (SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) -
     SUM(sr.sr_return_amt) - SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt)) AS net_revenue,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_transactions
  FROM item i
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
  JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
  JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
  JOIN customer c
    ON c.c_customer_sk = ss.ss_customer_sk
  JOIN customer_address ca
    ON ca.ca_address_sk = ss.ss_addr_sk
  WHERE i.i_brand = 'Brand#12'
    AND ca.ca_state = 'CA'
    AND sm.sm_type = 'AIR'
  GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ca.ca_state,
    sm.sm_type,
    r.r_reason_desc,
    wp.wp_type
  HAVING (SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) -
          SUM(sr.sr_return_amt) - SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt)) > 10000
)
SELECT
  a.i_item_id,
  a.i_product_name,
  a.i_category,
  a.i_brand,
  a.ca_state,
  a.sm_type,
  a.r_reason_desc,
  a.wp_type,
  a.total_store_sales,
  a.total_store_returns,
  a.total_catalog_sales,
  a.total_catalog_returns,
  a.total_web_sales,
  a.total_web_returns,
  a.total_inventory_on_hand,
  a.net_revenue,
  a.store_sales_transactions,
  a.catalog_sales_transactions,
  a.web_sales_transactions,
  (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_avg_catalog_sales,
  ROW_NUMBER() OVER (ORDER BY a.net_revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.net_revenue DESC
LIMIT 100
