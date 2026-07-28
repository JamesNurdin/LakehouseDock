WITH 
  catalog_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      w.w_warehouse_name AS warehouse_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      0.0 AS total_sales_amount,
      COUNT(*) AS total_transactions,
      AVG(cr.cr_return_tax) AS avg_return_tax
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.inventory inv 
      ON inv.inv_item_sk = i.i_item_sk 
     AND inv.inv_date_sk = d.d_date_sk 
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND w.w_gmt_offset = -5.00
    GROUP BY d.d_year, i.i_category, w.w_warehouse_name
  ),
  store_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      w.w_warehouse_name AS warehouse_name,
      SUM(sr.sr_return_amt) AS total_return_amount,
      0.0 AS total_sales_amount,
      COUNT(*) AS total_transactions,
      AVG(sr.sr_return_tax) AS avg_return_tax
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.inventory inv 
      ON inv.inv_item_sk = i.i_item_sk 
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
    GROUP BY d.d_year, i.i_category, w.w_warehouse_name
  ),
  web_return_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      w.w_warehouse_name AS warehouse_name,
      SUM(wr.wr_return_amt) AS total_return_amount,
      0.0 AS total_sales_amount,
      COUNT(*) AS total_transactions,
      AVG(wr.wr_return_tax) AS avg_return_tax
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.inventory inv 
      ON inv.inv_item_sk = i.i_item_sk 
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
    GROUP BY d.d_year, i.i_category, w.w_warehouse_name
  ),
  web_sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      w.w_warehouse_name AS warehouse_name,
      0.0 AS total_return_amount,
      SUM(ws.ws_sales_price) AS total_sales_amount,
      COUNT(*) AS total_transactions,
      NULL AS avg_return_tax
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.inventory inv 
      ON inv.inv_item_sk = i.i_item_sk 
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
    GROUP BY d.d_year, i.i_category, w.w_warehouse_name
  ),
  second_set AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_return_agg
    UNION ALL
    SELECT * FROM web_sales_agg
  )
SELECT
  year,
  category,
  warehouse_name,
  SUM(total_return_amount) AS sum_return_amount,
  SUM(total_sales_amount) AS sum_sales_amount,
  SUM(total_transactions) AS sum_transactions,
  AVG(avg_return_tax) AS avg_return_tax
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM second_set
) u
GROUP BY year, category, warehouse_name
ORDER BY sum_return_amount DESC
LIMIT 100
