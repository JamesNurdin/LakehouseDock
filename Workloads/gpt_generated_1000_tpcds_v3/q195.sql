WITH inventory_agg AS (
  SELECT inv.inv_item_sk,
         inv.inv_warehouse_sk,
         SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory inv
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  WHERE d_inv.d_year = 2002
  GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
),

sales_agg AS (
  SELECT
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    cp.cp_catalog_number AS catalog_number,
    cp.cp_catalog_page_number AS catalog_page_number,
    i.i_item_id AS item_id,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    i.i_color AS item_color,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(ss.ss_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit,
    ia.total_qty_on_hand,
    CASE WHEN SUM(COALESCE(cr.cr_net_loss, 0)) > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
  LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  LEFT JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
  LEFT JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
  JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  JOIN customer_address ca_current ON c.c_current_addr_sk = ca_current.ca_address_sk
  JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
  WHERE d_ss.d_year = 2002
    AND d_cs.d_year = 2002
    AND sm.sm_carrier = 'FEDEX'
    AND i.i_category = 'Electronics'
    AND w.w_state = 'CA'
  GROUP BY
    s.s_store_name,
    s.s_state,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    i.i_color,
    ia.total_qty_on_hand
)
SELECT
  store_name,
  store_state,
  catalog_number,
  catalog_page_number,
  item_id,
  item_category,
  item_brand,
  item_color,
  total_store_profit,
  total_return_loss,
  net_profit,
  total_qty_on_hand,
  loss_category,
  ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS profit_rank,
  RANK() OVER (ORDER BY net_profit DESC) AS profit_dense_rank
FROM sales_agg
ORDER BY net_profit DESC
LIMIT 100
