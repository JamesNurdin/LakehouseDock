WITH base AS (
   SELECT
       d.d_year,
       s.s_store_name,
       cc.cc_name,
       r.r_reason_desc,
       ws.ws_order_number,
       ws.ws_net_profit,
       ws.ws_quantity,
       ws.ws_list_price,
       p.p_promo_name,
       wsite.web_name,
       t.t_hour
   FROM date_dim d
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE d.d_year = 2002
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
),

sales_orders AS (
   SELECT ws.ws_order_number
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002 AND ws.ws_net_profit > 0
),

catalog_return_orders AS (
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
),

sales_not_returned AS (
   SELECT ws_order_number FROM sales_orders
   EXCEPT
   SELECT cr_order_number FROM catalog_return_orders
),

web_return_orders AS (
   SELECT wr.wr_order_number
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
),

sales_and_web_returns AS (
   SELECT ws_order_number FROM sales_orders
   INTERSECT
   SELECT wr_order_number FROM web_return_orders
),

reason_levels AS (
   SELECT r.r_reason_desc, v.discount_level
   FROM (SELECT r_reason_desc FROM reason WHERE r_reason_sk IN (1, 2, 3)) r
   CROSS JOIN (VALUES (0.0), (5.0), (10.0)) AS v(discount_level)
)
SELECT
    b.d_year,
    b.s_store_name,
    b.cc_name,
    b.r_reason_desc,
    b.p_promo_name,
    b.web_name,
    COUNT(DISTINCT b.ws_order_number) AS orders_cnt,
    SUM(b.ws_net_profit) AS total_net_profit,
    AVG(b.ws_quantity) AS avg_quantity,
    MIN(b.ws_list_price) AS min_list_price,
    MAX(b.ws_list_price) AS max_list_price
FROM base b
JOIN sales_not_returned snr ON b.ws_order_number = snr.ws_order_number
JOIN sales_and_web_returns sar ON b.ws_order_number = sar.ws_order_number
JOIN reason_levels rl ON b.r_reason_desc = rl.r_reason_desc
GROUP BY
    b.d_year,
    b.s_store_name,
    b.cc_name,
    b.r_reason_desc,
    b.p_promo_name,
    b.web_name
ORDER BY total_net_profit DESC
LIMIT 100
