WITH joined AS (
   SELECT
      i.i_item_id,
      s.s_store_id,
      s.s_state,
      ss.ss_net_profit,
      sr.sr_net_loss,
      ws.ws_net_profit,
      wr.wr_net_loss,
      ss.ss_ticket_number,
      ws.ws_order_number
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
   LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
   LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
   LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
   LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
   LEFT JOIN customer_demographics cd_cr_refund ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
   LEFT JOIN customer_demographics cd_cr_return ON cr.cr_returning_cdemo_sk = cd_cr_return.cd_demo_sk
   LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND w_cr.w_warehouse_sk = inv.inv_warehouse_sk
   LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
   LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
   LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
   LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
   LEFT JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
   LEFT JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
   WHERE i.i_current_price > 150.00
     AND s.s_state = 'CA'
     AND w_ws.w_city = 'Seattle'
     AND ws.ws_quantity >= 2
     AND cr.cr_return_amount > 1000.00
),
agg AS (
   SELECT
      i_item_id,
      s_store_id,
      s_state,
      SUM(ss_net_profit) AS total_store_profit,
      SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
      SUM(COALESCE(ws_net_profit, 0)) AS total_web_profit,
      SUM(COALESCE(wr_net_loss, 0)) AS total_web_return_loss,
      COUNT(DISTINCT ss_ticket_number) AS store_sales_cnt,
      COUNT(DISTINCT ws_order_number) AS web_sales_cnt
   FROM joined
   GROUP BY i_item_id, s_store_id, s_state
)
SELECT
   i_item_id,
   s_store_id,
   s_state,
   total_store_profit,
   total_store_return_loss,
   total_web_profit,
   total_web_return_loss,
   (total_store_profit - total_store_return_loss + total_web_profit - total_web_return_loss) AS net_total,
   store_sales_cnt,
   web_sales_cnt,
   ROW_NUMBER() OVER (ORDER BY (total_store_profit - total_store_return_loss + total_web_profit - total_web_return_loss) DESC) AS rn
FROM agg
WHERE (total_store_profit - total_store_return_loss + total_web_profit - total_web_return_loss) > 5000
  AND store_sales_cnt >= 5
ORDER BY net_total DESC
LIMIT 100
