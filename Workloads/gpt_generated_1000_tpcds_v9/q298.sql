SELECT
    s.s_division_name,
    p_ss.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    SUM(ss.ss_net_profit) AS store_sales_net_profit,
    SUM(cr.cr_net_loss) AS catalog_returns_net_loss,
    SUM(ws.ws_net_profit) AS web_sales_net_profit,
    SUM(wr.wr_net_loss) AS web_returns_net_loss,
    AVG(ss.ss_quantity) AS avg_quantity_sold
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c_ss.c_customer_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c_ss.c_customer_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE t_ss.t_hour BETWEEN 9 AND 17
  AND ss.ss_quantity > (
      SELECT AVG(ss2.ss_quantity)
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = s.s_store_sk
  )
  AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_order_number = ws.ws_order_number
        AND wr2.wr_net_loss > 0
  )
GROUP BY ROLLUP (s.s_division_name, p_ss.p_promo_name)
ORDER BY store_sales_net_profit DESC
LIMIT 100
