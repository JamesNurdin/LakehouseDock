WITH base AS (
   SELECT
      p.p_promo_id,
      i.i_category,
      SUM(cs.cs_net_profit)              AS catalog_net_profit,
      SUM(ss.ss_net_profit)              AS store_net_profit,
      SUM(ws.ws_net_profit)              AS web_net_profit,
      SUM(cr.cr_net_loss)                AS catalog_return_loss,
      SUM(sr.sr_net_loss)                AS store_return_loss,
      SUM(wr.wr_net_loss)                AS web_return_loss,
      SUM(inv.inv_quantity_on_hand)      AS qty_on_hand,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_sign
   FROM tpcds.catalog_sales cs
   JOIN tpcds.item i               ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.customer c_bill      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN tpcds.customer c_ship      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
   JOIN tpcds.promotion p          ON cs.cs_promo_sk = p.p_promo_sk
   JOIN tpcds.call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm         ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN tpcds.catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk      = cs.cs_item_sk
   LEFT JOIN tpcds.reason r_cr      ON cr.cr_reason_sk = r_cr.r_reason_sk
   LEFT JOIN tpcds.inventory inv    ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN tpcds.store_sales ss  ON ss.ss_item_sk = i.i_item_sk
                                   AND ss.ss_customer_sk = c_bill.c_customer_sk
   LEFT JOIN tpcds.promotion p_ss   ON ss.ss_promo_sk = p_ss.p_promo_sk
   LEFT JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = i.i_item_sk
   LEFT JOIN tpcds.reason r_sr      ON sr.sr_reason_sk = r_sr.r_reason_sk
   LEFT JOIN tpcds.web_sales ws    ON ws.ws_item_sk = i.i_item_sk
                                   AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
                                   AND ws.ws_ship_customer_sk = c_ship.c_customer_sk
   LEFT JOIN tpcds.promotion p_ws   ON ws.ws_promo_sk = p_ws.p_promo_sk
   LEFT JOIN tpcds.ship_mode sm_ws  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
   LEFT JOIN tpcds.warehouse w_ws   ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
   LEFT JOIN tpcds.web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN tpcds.web_returns wr  ON wr.wr_order_number = ws.ws_order_number
                                   AND wr.wr_item_sk = i.i_item_sk
   LEFT JOIN tpcds.reason r_wr      ON wr.wr_reason_sk = r_wr.r_reason_sk
   LEFT JOIN tpcds.web_page wp_wr   ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
   WHERE NOT EXISTS (
         SELECT 1 FROM tpcds.web_returns wr_ex
         WHERE wr_ex.wr_refunded_customer_sk = c_bill.c_customer_sk
       )
   GROUP BY GROUPING SETS (
        (p.p_promo_id, i.i_category),
        (p.p_promo_id),
        ()
   )
)
SELECT
   b.p_promo_id,
   b.i_category,
   b.catalog_net_profit,
   b.store_net_profit,
   b.web_net_profit,
   b.catalog_return_loss,
   b.store_return_loss,
   b.web_return_loss,
   b.qty_on_hand,
   b.profit_sign,
   RANK() OVER (ORDER BY (b.catalog_net_profit + b.store_net_profit + b.web_net_profit) DESC) AS promo_rank,
   (SELECT AVG(cs2.cs_net_profit) FROM tpcds.catalog_sales cs2) AS overall_avg_profit,
   CASE WHEN (b.catalog_net_profit + b.store_net_profit + b.web_net_profit) >
             (SELECT AVG(cs2.cs_net_profit) FROM tpcds.catalog_sales cs2)
        THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
   END AS profit_vs_avg
FROM base b
WHERE b.p_promo_id NOT IN (
        SELECT p2.p_promo_id FROM tpcds.promotion p2 WHERE p2.p_discount_active = 'Y'
     )
ORDER BY promo_rank
LIMIT 100
