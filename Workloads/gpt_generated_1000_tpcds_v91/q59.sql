WITH cp_sampled AS (
   SELECT *
   FROM catalog_page
   TABLESAMPLE BERNOULLI (10)
)
SELECT
   d_sold.d_year,
   cp.cp_department,
   sm.sm_type,
   w.w_state,
   COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
   SUM(cs.cs_net_paid) AS total_net_paid,
   AVG(cs.cs_net_profit) AS avg_net_profit,
   MIN(cs.cs_net_paid) AS min_net_paid,
   MAX(cs.cs_net_paid) AS max_net_paid,
   SUM(ws.ws_net_paid_inc_ship_tax) AS total_ws_net_paid_inc_ship_tax,
   COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM
   catalog_sales cs
   JOIN cp_sampled cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
   LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
WHERE
   d_sold.d_year = 2001
   AND cp.cp_department = 'Electronics'
   AND sm.sm_type = 'AIR'
   AND w.w_state = 'CA'
   AND NOT EXISTS (
       SELECT 1
       FROM store_returns sr2
       WHERE sr2.sr_customer_sk = c.c_customer_sk
         AND sr2.sr_returned_date_sk = d_sold.d_date_sk
   )
GROUP BY
   d_sold.d_year,
   cp.cp_department,
   sm.sm_type,
   w.w_state
ORDER BY
   total_net_paid DESC
LIMIT 100
