WITH sales_data AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       d.d_date,
       i.i_category,
       i.i_class,
       sm.sm_ship_mode_id,
       ss.ss_ext_sales_price AS store_sales,
       ws.ws_ext_sales_price AS web_sales,
       sr.sr_return_amt AS store_return,
       wr.wr_return_amt AS web_return,
       inv_l.total_inventory_qty,
       (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN LATERAL (
       SELECT SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
       FROM inventory inv
       WHERE inv.inv_item_sk = i.i_item_sk
         AND inv.inv_date_sk = d.d_date_sk
   ) AS inv_l ON TRUE
   JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND i.i_category = 'Electronics'
     AND c.c_preferred_cust_flag = 'Y'
     AND cd.cd_education_status = 'College'
     AND p.p_discount_active = 'Y'
     AND sm.sm_carrier = 'FEDEX'
),
aggregated AS (
   SELECT
       d_year,
       d_month_seq,
       i_category,
       i_class,
       sm_ship_mode_id,
       COUNT(*) AS txn_count,
       SUM(store_sales) AS total_store_sales,
       SUM(web_sales) AS total_web_sales,
       SUM(store_return) AS total_store_return,
       SUM(web_return) AS total_web_return,
       SUM(total_inventory_qty) AS total_inventory_qty,
       MAX(max_promo_cost) AS max_promo_cost
   FROM sales_data
   GROUP BY ROLLUP (d_year, d_month_seq, i_category, sm_ship_mode_id), i_class
)
SELECT
   d_year,
   d_month_seq,
   i_category,
   i_class,
   sm_ship_mode_id,
   txn_count,
   total_store_sales,
   total_web_sales,
   total_store_return,
   total_web_return,
   total_inventory_qty,
   max_promo_cost,
   SUM(total_store_sales) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_store_sales,
   ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_store_sales DESC) AS sales_rank
FROM aggregated
ORDER BY d_year, d_month_seq, i_category, sm_ship_mode_id
