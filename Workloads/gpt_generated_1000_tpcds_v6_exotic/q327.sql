WITH sales_summary AS (
   SELECT
       w.w_warehouse_id,
       s.s_store_id,
       d_sold.d_year AS year,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
   JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
        AND wp.wp_access_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2001
     AND t.t_am_pm = 'PM'
     AND cc.cc_state = 'CA'
     AND w.w_county = 'Mobile County'
     AND wp.wp_image_count >= 3
   GROUP BY GROUPING SETS (
       (w.w_warehouse_id, s.s_store_id, d_sold.d_year),
       (w.w_warehouse_id, d_sold.d_year),
       (s.s_store_id, d_sold.d_year),
       (d_sold.d_year)
   )
),
inventory_summary AS (
   SELECT
       w.w_warehouse_id,
       d_inv.d_year AS year,
       SUM(inv.inv_quantity_on_hand) AS total_qty
   FROM inventory inv
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d_inv.d_year BETWEEN 2000 AND 2002
     AND w.w_state = 'TX'
   GROUP BY w.w_warehouse_id, d_inv.d_year
),
combined AS (
   SELECT
       'sales' AS src,
       w_warehouse_id,
       s_store_id,
       year,
       total_sales,
       total_profit,
       order_cnt,
       CAST(NULL AS BIGINT) AS total_qty
   FROM sales_summary
   UNION ALL
   SELECT
       'inventory' AS src,
       w_warehouse_id,
       NULL AS s_store_id,
       year,
       NULL,
       NULL,
       NULL,
       total_qty
   FROM inventory_summary
)
SELECT
   src,
   w_warehouse_id,
   SUM(total_sales) AS sum_sales,
   SUM(total_profit) AS sum_profit,
   SUM(order_cnt) AS sum_orders,
   SUM(total_qty) AS sum_qty
FROM combined
GROUP BY ROLLUP (src, w_warehouse_id)
HAVING (SUM(total_sales) > 10000 OR SUM(total_qty) > 5000)
ORDER BY sum_sales DESC
LIMIT 100
