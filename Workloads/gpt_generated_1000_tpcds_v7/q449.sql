WITH sales_agg AS (
   SELECT
       st.s_store_id,
       r.r_reason_desc,
       p.p_promo_name,
       SUM(ws.ws_net_profit) AS total_net_profit,
       SUM(ws.ws_quantity) AS total_quantity,
       COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
       COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
       COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_return_loss,
       COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss
   FROM web_sales ws
   JOIN time_dim t
       ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i
       ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p
       ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm
       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca
       ON ws.ws_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
          AND sr.sr_return_time_sk = t.t_time_sk
          AND sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_addr_sk = ca.ca_address_sk
   LEFT JOIN store st
       ON sr.sr_store_sk = st.s_store_sk
   LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
          AND cr.cr_returned_time_sk = t.t_time_sk
          AND cr.cr_refunded_customer_sk = c.c_customer_sk
          AND cr.cr_refunded_addr_sk = ca.ca_address_sk
   LEFT JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
          AND wr.wr_returned_time_sk = t.t_time_sk
          AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
   WHERE
       p.p_discount_active = 'Y'
       AND cc.cc_division = 4
       AND i.i_color = 'Red'
       AND st.s_state = 'CA'
       AND t.t_hour BETWEEN 9 AND 17
   GROUP BY
       st.s_store_id,
       r.r_reason_desc,
       p.p_promo_name
)
SELECT
   s_store_id,
   AVG(total_net_profit) AS avg_net_profit,
   SUM(total_quantity) AS sum_quantity,
   COUNT(*) AS grp_count
FROM sales_agg
GROUP BY s_store_id
HAVING AVG(total_net_profit) > 1000
ORDER BY avg_net_profit DESC
LIMIT 100
