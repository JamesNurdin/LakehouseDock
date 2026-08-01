WITH order_set AS (
   SELECT ws.ws_order_number AS order_number
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk = (
       SELECT d2.d_date_sk
       FROM date_dim d2
       WHERE d2.d_year = 1999
       LIMIT 1
   )
   UNION
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   WHERE cr.cr_returned_date_sk = (
       SELECT d3.d_date_sk
       FROM date_dim d3
       WHERE d3.d_year = 1999
       LIMIT 1
   )
)

SELECT 
    d.d_year,
    t.t_hour,
    i.i_category,
    CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS income_band_category,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MAX(p.p_discount_active) AS max_discount_active_flag,
    (SELECT MAX(i2.i_current_price)
     FROM item i2
     WHERE i2.i_category = i.i_category) AS max_category_price
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                 AND ws.ws_sold_time_sk = t.t_time_sk
                 AND ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                    AND wr.wr_item_sk = ws.ws_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                  AND inv.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 1999
  AND p.p_channel_dmail = 'Y'
  AND t.t_hour BETWEEN 8 AND 12
  AND ws.ws_order_number IN (SELECT order_number FROM order_set)
GROUP BY d.d_year, t.t_hour, i.i_category,
         CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END
HAVING COUNT(DISTINCT cr.cr_order_number) > 10
ORDER BY total_return_amount DESC
LIMIT 100
