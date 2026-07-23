SELECT
   d.d_year,
   p.p_promo_id,
   COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
   SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
   SUM(ws.ws_net_paid) AS total_web_sales,
   SUM(ss.ss_net_paid) AS total_store_sales,
   SUM(CASE WHEN r.r_reason_desc = 'Parts missing' THEN cr.cr_net_loss ELSE 0 END) AS net_loss_parts_missing,
   AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
   MAX(cs.cs_net_profit) AS max_catalog_profit,
   MIN(ws.ws_net_paid) AS min_web_net_paid
FROM
   catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN (
        SELECT ws_bill_customer_sk,
               ws_sold_date_sk,
               SUM(ws.ws_net_paid) AS ws_net_paid,
               SUM(ws.ws_ext_sales_price) AS ws_ext_sales_price
        FROM web_sales ws
        GROUP BY ws_bill_customer_sk, ws_sold_date_sk
   ) ws ON ws.ws_bill_customer_sk = c.c_customer_sk AND ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN (
        SELECT ss_customer_sk,
               ss_sold_date_sk,
               SUM(ss.ss_net_paid) AS ss_net_paid,
               SUM(ss.ss_ext_sales_price) AS ss_ext_sales_price
        FROM store_sales ss
        GROUP BY ss_customer_sk, ss_sold_date_sk
   ) ss ON ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk = d.d_date_sk
WHERE
   d.d_year = 2000
   AND p.p_channel_demo = 'N'
   AND ca.ca_state = 'CA'
   AND t.t_hour BETWEEN 8 AND 17
GROUP BY
   d.d_year,
   p.p_promo_id
ORDER BY
   total_catalog_sales DESC
LIMIT 100
