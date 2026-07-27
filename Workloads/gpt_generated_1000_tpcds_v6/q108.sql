WITH max_promo_cost AS (
       SELECT MAX(p_cost) AS max_cost
       FROM promotion
       WHERE p_channel_event = 'N'
   )
SELECT
       w.w_warehouse_name,
       p.p_promo_name,
       wp.wp_type,
       SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
       AVG(ws.ws_quantity) AS avg_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       MAX(ws.ws_ext_list_price) AS max_list_price,
       (
           SELECT COUNT(*)
           FROM promotion p2
           WHERE p2.p_cost = max_promo_cost.max_cost
       ) AS promo_with_max_cost_cnt
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
CROSS JOIN max_promo_cost
WHERE wp.wp_link_count >= 10
  AND wp.wp_rec_start_date >= DATE '1999-01-01'
  AND p.p_channel_event = 'N'
  AND ws.ws_quantity > 20
GROUP BY w.w_warehouse_name,
         p.p_promo_name,
         wp.wp_type,
         max_promo_cost.max_cost
ORDER BY total_net_paid DESC
LIMIT 100
