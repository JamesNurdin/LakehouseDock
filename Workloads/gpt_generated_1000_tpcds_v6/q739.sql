SELECT
    ss.ss_ticket_number,
    p.p_promo_id,
    t.t_hour,
    w.w_warehouse_name,
    we.web_name,
    wp.wp_type,
    ss.ss_net_profit,
    sr.sr_net_loss,
    RANK() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
    avg_discount.avg_ext_discount
FROM store_sales ss
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
/* Subquery to compute average discount per promotion from web_sales */
LEFT JOIN (
    SELECT ws.ws_promo_sk,
           AVG(ws.ws_ext_discount_amt) AS avg_ext_discount
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk
) avg_discount
  ON avg_discount.ws_promo_sk = p.p_promo_sk
/* Join web_sales to bring in warehouse, web_page and web_site details */
LEFT JOIN web_sales ws
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
WHERE p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
  AND w.w_state = 'CA'
  AND we.web_class = 'Unknown'
  AND wp.wp_type = 'Content'
  AND ss.ss_net_paid > 1000
ORDER BY profit_rank
LIMIT 100
