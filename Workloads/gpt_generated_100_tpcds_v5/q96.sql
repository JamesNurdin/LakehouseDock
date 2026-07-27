WITH
  store_agg AS (
    SELECT
      d_sold.d_year,
      i_sold.i_item_sk,
      SUM(ss_ext_sales_price) AS store_sales,
      COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN item i_sold ON ss.ss_item_sk = i_sold.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY d_sold.d_year, i_sold.i_item_sk
  ),
  catalog_agg AS (
    SELECT
      d_sold.d_year,
      i_cat.i_item_sk,
      SUM(cs_ext_sales_price) AS catalog_sales,
      COUNT(DISTINCT cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i_cat ON cs.cs_item_sk = i_cat.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY d_sold.d_year, i_cat.i_item_sk
  ),
  returns_agg AS (
    SELECT
      d_ret.d_year,
      i_ret.i_item_sk,
      SUM(sr_return_amt) AS return_sales,
      COUNT(DISTINCT sr_ticket_number) AS return_transactions
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY d_ret.d_year, i_ret.i_item_sk
  ),
  combined AS (
    SELECT DISTINCT d_year, i_item_sk, store_sales AS sales_amount, store_orders AS orders_count, 'store'   AS source FROM store_agg
    UNION ALL
    SELECT DISTINCT d_year, i_item_sk, catalog_sales AS sales_amount, catalog_orders AS orders_count, 'catalog' AS source FROM catalog_agg
    UNION ALL
    SELECT DISTINCT d_year, i_item_sk, return_sales AS sales_amount, return_transactions AS orders_count, 'return'  AS source FROM returns_agg
  )
SELECT
  c.d_year,
  i.i_item_id,
  SUM(c.sales_amount)        AS total_sales,
  SUM(c.orders_count)       AS total_orders,
  COUNT(DISTINCT c.source)  AS source_count,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  ws.web_name
FROM combined c
JOIN item i ON c.i_item_sk = i.i_item_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_inv.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_inv.d_date_sk
GROUP BY c.d_year, i.i_item_id, ws.web_name
ORDER BY total_sales DESC
LIMIT 100
