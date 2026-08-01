WITH ws_joined AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       d.d_year,
       ws.ws_bill_customer_sk,
       c.c_first_name,
       c.c_last_name,
       ws.ws_item_sk,
       i.i_brand,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_ship_mode_sk,
       sm.sm_type,
       ws.ws_warehouse_sk,
       w.w_warehouse_name,
       ws.ws_promo_sk,
       p.p_promo_name,
       ws.ws_web_page_sk,
       wp.wp_type
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND w.w_state = 'CA'
     AND sm.sm_type = 'AIR'
     AND p.p_discount_active = 'Y'
     AND wp.wp_type = 'home'
),
cr_joined AS (
   SELECT
       cr.cr_order_number,
       cr.cr_returned_date_sk,
       d_ret.d_year AS return_year,
       cr.cr_item_sk,
       i.i_brand AS return_brand,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       cr.cr_call_center_sk,
       cc.cc_city,
       cc.cc_state,
       cr.cr_ship_mode_sk,
       sm.sm_type AS return_ship_type,
       cr.cr_warehouse_sk,
       w.w_warehouse_name AS return_warehouse,
       cr.cr_refunded_customer_sk,
       cust.c_first_name AS refund_first,
       cust.c_last_name AS refund_last
   FROM catalog_returns cr
   FULL OUTER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN item i ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
   WHERE cc.cc_city = 'Mount Vernon'
     AND d_ret.d_year = 2001
     AND i.i_category = 'Electronics'
     AND sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
     AND cust.c_salutation = 'Mr.'
),
ws_agg AS (
   SELECT
       ws.ws_bill_customer_sk AS c_customer_sk,
       ws.i_brand,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_ext_sales_price) AS avg_sales,
       COUNT(*) AS cnt_sales
   FROM ws_joined ws
   WHERE ws.ws_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
   GROUP BY GROUPING SETS ((ws.ws_bill_customer_sk, ws.i_brand),
                           (ws.ws_bill_customer_sk),
                           (ws.i_brand))
   HAVING SUM(ws.ws_ext_sales_price) > 1000
),
cr_agg AS (
   SELECT
       cr.cr_refunded_customer_sk AS c_customer_sk,
       cr.return_brand AS i_brand,
       SUM(cr.cr_return_amount) AS total_sales,
       AVG(cr.cr_return_amount) AS avg_sales,
       COUNT(*) AS cnt_sales
   FROM cr_joined cr
   GROUP BY GROUPING SETS ((cr.cr_refunded_customer_sk, cr.return_brand),
                           (cr.cr_refunded_customer_sk),
                           (cr.return_brand))
   HAVING SUM(cr.cr_return_amount) > 500
),
union_all AS (
   SELECT * FROM ws_agg
   UNION DISTINCT
   SELECT * FROM cr_agg
)
SELECT
    c_customer_sk,
    i_brand,
    total_sales,
    avg_sales,
    cnt_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM union_all
ORDER BY total_sales DESC
LIMIT 100
