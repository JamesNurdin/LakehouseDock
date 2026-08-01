WITH base AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_ship_date_sk,
       cs.cs_item_sk,
       cs.cs_order_number,
       cs.cs_net_profit,
       cs.cs_quantity,
       cs.cs_net_paid,
       ws.ws_net_profit,
       ws.ws_sold_date_sk AS ws_sold_date_sk,
       i.i_item_id,
       i.i_category,
       i.i_class,
       i.i_brand,
       sm.sm_type,
       sm.sm_ship_mode_id,
       cc.cc_state,
       s.s_store_id,
       inv.inv_quantity_on_hand,
       cr.cr_return_quantity,
       bc.c_customer_sk,
       ds.d_year,
       ds.d_month_seq,
       ds.d_date_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
   JOIN time_dim ts ON cs.cs_sold_time_sk = ts.t_time_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer bc ON cs.cs_bill_customer_sk = bc.c_customer_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer sc ON cs.cs_ship_customer_sk = sc.c_customer_sk
   JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN date_dim dt_ship ON cs.cs_ship_date_sk = dt_ship.d_date_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
   LEFT JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
   LEFT JOIN time_dim tr ON cr.cr_returned_time_sk = tr.t_time_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = ds.d_date_sk
   LEFT JOIN store s ON s.s_closed_date_sk = ds.d_date_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = ds.d_date_sk
   LEFT JOIN date_dim ws_date ON ws.ws_sold_date_sk = ws_date.d_date_sk
   LEFT JOIN time_dim ws_time ON ws.ws_sold_time_sk = ws_time.t_time_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN date_dim wp_creation ON wp.wp_creation_date_sk = wp_creation.d_date_sk
   LEFT JOIN date_dim wp_access ON wp.wp_access_date_sk = wp_access.d_date_sk
   LEFT JOIN customer wp_cust ON wp.wp_customer_sk = wp_cust.c_customer_sk
   LEFT JOIN date_dim cp_start ON cp.cp_start_date_sk = cp_start.d_date_sk
   LEFT JOIN date_dim cp_end ON cp.cp_end_date_sk = cp_end.d_date_sk
   WHERE ds.d_year = 2001
     AND i.i_category = 'Electronics'
     AND sm.sm_type = 'OVERNIGHT'
     AND cc.cc_state = 'CA'
     AND inv.inv_quantity_on_hand > 0
     AND cs.cs_net_paid > 100
),
agg AS (
   SELECT
       d_year,
       d_month_seq,
       i_item_id,
       i_category,
       i_class,
       sm_type,
       cc_state,
       s_store_id,
       SUM(cs_net_profit) AS total_sales_profit,
       SUM(ws_net_profit) AS total_web_profit,
       SUM(inv_quantity_on_hand) AS total_inventory_qty,
       SUM(COALESCE(cr_return_quantity, 0)) AS total_returns,
       COUNT(DISTINCT cs_order_number) AS order_count,
       c_customer_sk,
       d_date_sk
   FROM base
   GROUP BY
       d_year,
       d_month_seq,
       i_item_id,
       i_category,
       i_class,
       sm_type,
       cc_state,
       s_store_id,
       c_customer_sk,
       d_date_sk
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.i_item_id,
    a.i_category,
    a.i_class,
    a.sm_type,
    a.cc_state,
    a.s_store_id,
    a.total_sales_profit,
    a.total_web_profit,
    a.total_inventory_qty,
    a.total_returns,
    a.order_count,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales_profit DESC) AS profit_rank_year,
    (SELECT COUNT(DISTINCT cs2.cs_order_number)
     FROM catalog_sales cs2
     JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
     WHERE cs2.cs_bill_customer_sk = a.c_customer_sk
       AND d2.d_year = a.d_year) AS cust_orders_year
FROM agg a
WHERE a.total_sales_profit > (
    SELECT AVG(cs3.cs_net_profit)
    FROM catalog_sales cs3
    JOIN date_dim d3 ON cs3.cs_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year = a.d_year
)
ORDER BY profit_rank_year, a.total_sales_profit DESC
LIMIT 100
