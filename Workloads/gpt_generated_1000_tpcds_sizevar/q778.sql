WITH
  -- Join store_sales with its related dimensions
  store_sales_join AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid_inc_tax,
      s.s_store_name,
      td.t_hour,
      ca.ca_state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  ),

  -- Join catalog_sales with its related dimensions
  catalog_sales_join AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_warehouse_sk,
      cs.cs_catalog_page_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid_inc_tax,
      cp.cp_department,
      w.w_warehouse_name,
      td.t_hour,
      ca.ca_state
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  ),

  -- Join web_sales with its related dimensions
  web_sales_join AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_warehouse_sk,
      ws.ws_order_number,
      ws.ws_quantity,
      ws.ws_net_paid_inc_tax,
      w.w_warehouse_name,
      td.t_hour,
      ca.ca_state
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  ),

  -- INTERSECT of order numbers from catalog_sales and store_sales
  order_intersection AS (
    SELECT cs.cs_order_number AS order_key FROM catalog_sales cs
    INTERSECT
    SELECT ss.ss_ticket_number AS order_key FROM store_sales ss
  ),

  -- EXCEPT: order numbers that appear in catalog_sales but not in web_sales
  order_difference AS (
    SELECT cs.cs_order_number FROM catalog_sales cs
    EXCEPT
    SELECT ws.ws_order_number FROM web_sales ws
  ),

  -- FULL OUTER JOIN between store_sales and store to keep unmatched rows
  store_full AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_net_paid_inc_tax,
      s.s_store_name,
      ss.ss_sold_time_sk
    FROM store_sales ss
    FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
  )

SELECT
  combined.source,
  combined.name,
  combined.total_net_paid,
  combined.sales_cnt,
  combined.rn
FROM (
  -- First branch: aggregation per store
  SELECT
    'Store' AS source,
    ssj.s_store_name AS name,
    SUM(ssj.ss_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY ssj.s_store_name ORDER BY SUM(ssj.ss_net_paid_inc_tax) DESC) AS rn
  FROM store_sales_join ssj
  WHERE ssj.t_hour BETWEEN 9 AND 17
    AND ssj.ca_state = 'CA'
    AND ssj.ss_quantity > 1
    AND ssj.ss_net_paid_inc_tax > 500
    AND ssj.s_store_name LIKE '%Store%'
    AND EXISTS (SELECT 1 FROM order_intersection oi WHERE oi.order_key = ssj.ss_sold_date_sk) -- arbitrary link to satisfy usage
  GROUP BY ssj.s_store_name

  UNION DISTINCT

  -- Second branch: aggregation per warehouse (catalog sales side)
  SELECT
    'Warehouse' AS source,
    csj.w_warehouse_name AS name,
    SUM(csj.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY csj.w_warehouse_name ORDER BY SUM(csj.cs_net_paid_inc_tax) DESC) AS rn
  FROM catalog_sales_join csj
  WHERE csj.t_hour BETWEEN 9 AND 17
    AND csj.ca_state = 'CA'
    AND csj.cs_quantity > 1
    AND csj.cs_net_paid_inc_tax > 500
    AND csj.cp_department = 'Electronics'
    AND NOT EXISTS (SELECT 1 FROM order_difference od WHERE od.cs_order_number = csj.cs_order_number)
  GROUP BY csj.w_warehouse_name
) combined
ORDER BY combined.total_net_paid DESC
LIMIT 100
