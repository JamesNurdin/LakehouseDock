WITH base AS (
   SELECT
       d.d_year,
       i.i_category,
       cs.cs_order_number,
       cs.cs_ext_sales_price AS cs_ext_sales_price,
       cs.cs_quantity AS cs_quantity,
       ws.ws_order_number,
       ws.ws_ext_sales_price AS ws_ext_sales_price,
       ws.ws_quantity AS ws_quantity,
       s.s_state,
       w.w_state,
       sm.sm_type,
       i.i_brand
   FROM date_dim d
   JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON i.i_item_sk = cs.cs_item_sk
   JOIN store s ON s.s_store_sk = ss.ss_store_sk
   JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
   JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
   LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
   LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
   LEFT JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
   WHERE d.d_year = 2002
     AND i.i_brand = 'Brand#12'
     AND s.s_state = 'CA'
     AND w.w_state = 'TX'
     AND sm.sm_type = 'AIR'
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
           AND inv.inv_date_sk = d.d_date_sk
           AND inv.inv_quantity_on_hand > 0
     )
)
SELECT
   d_year,
   i_category,
   SUM(revenue) AS total_revenue,
   COUNT(DISTINCT order_num) AS order_cnt
FROM (
   SELECT DISTINCT d_year, i_category, cs_ext_sales_price AS revenue, cs_order_number AS order_num
   FROM base
   WHERE cs_quantity > 5

   UNION ALL

   SELECT DISTINCT d_year, i_category, ws_ext_sales_price AS revenue, ws_order_number AS order_num
   FROM base
   WHERE ws_quantity > 5
) u
GROUP BY ROLLUP (d_year, i_category)
ORDER BY d_year, i_category
LIMIT 100
