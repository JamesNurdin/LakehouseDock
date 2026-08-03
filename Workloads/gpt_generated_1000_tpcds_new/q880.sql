WITH
cs_base AS (
   SELECT
     cs.cs_order_number,
     cs.cs_sold_date_sk,
     cs.cs_item_sk,
     cs.cs_quantity,
     cs.cs_net_paid,
     cs.cs_net_profit,
     cp.cp_type,
     p.p_promo_name,
     sm.sm_type,
     w.w_warehouse_name,
     w.w_state,
     ca.ca_state AS cust_state,
     ca.ca_country,
     i.i_brand,
     i.i_category,
     i.i_product_name
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN inventory inv
          ON inv.inv_item_sk = cs.cs_item_sk
         AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
   WHERE cp.cp_type IN ('monthly', 'quarterly')
     AND p.p_purpose = 'Unknown'
     AND sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
     AND ca.ca_country = 'United States'
     AND cs.cs_sold_date_sk BETWEEN 2451540 AND 2451550
),
store_ret AS (
   SELECT
     sr.sr_item_sk,
     sr.sr_return_quantity,
     ca.ca_state AS ret_state
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
cs_full AS (
   SELECT
     cs.*,
     sr.sr_return_quantity,
     sr.ret_state
   FROM cs_base cs
   FULL OUTER JOIN store_ret sr
     ON cs.cs_item_sk = sr.sr_item_sk
),
web_base AS (
   SELECT
     ws.ws_order_number,
     ws.ws_sold_date_sk,
     ws.ws_item_sk,
     ws.ws_quantity,
     ws.ws_net_paid,
     ws.ws_net_profit,
     wp.wp_type,
     p.p_promo_name AS web_promo_name,
     sm.sm_type AS web_ship_type,
     w.w_warehouse_name AS web_warehouse,
     ca.ca_state AS web_cust_state,
     ca.ca_country AS web_cust_country,
     i.i_brand,
     i.i_category,
     i.i_product_name,
     wr.wr_return_quantity,
     wr.wr_return_amt
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr
          ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
   WHERE wp.wp_type = 'homepage'
     AND p.p_purpose = 'Unknown'
     AND sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
     AND ca.ca_country = 'United States'
     AND ws.ws_sold_date_sk BETWEEN 2451540 AND 2451550
),
diff_orders AS (
   SELECT cs_order_number AS order_number FROM cs_full
   EXCEPT
   SELECT ws_order_number FROM web_base
),
final_set AS (
   SELECT
     cs.cs_order_number AS order_number,
     cs.cs_net_profit,
     cs.i_brand,
     cs.i_category,
     ROW_NUMBER() OVER (PARTITION BY cs.i_brand ORDER BY cs.cs_net_profit DESC) AS brand_profit_rank,
     CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
     cs.cs_quantity,
     cs.cs_net_paid
   FROM cs_full cs
   WHERE cs.cs_order_number IN (SELECT order_number FROM diff_orders)

   UNION DISTINCT

   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_net_profit,
     ws.i_brand,
     ws.i_category,
     ROW_NUMBER() OVER (PARTITION BY ws.i_brand ORDER BY ws.ws_net_profit DESC) AS brand_profit_rank,
     CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
     ws.ws_quantity,
     ws.ws_net_paid
   FROM web_base ws
   WHERE ws.ws_order_number IN (SELECT order_number FROM diff_orders)
)
SELECT *
FROM final_set
ORDER BY profit_flag DESC, brand_profit_rank
LIMIT 100
