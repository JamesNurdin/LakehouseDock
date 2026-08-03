SELECT w.w_warehouse_id,
       w.w_city,
       w.w_state,
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_sales_price,
       cs.cs_net_profit,
       sm.sm_type,
       cd.cd_gender,
       hd.hd_buy_potential,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
       (SELECT MAX(cs2.cs_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk) AS max_item_price,
       lr.returns_cnt
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                     AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS returns_cnt
    FROM store_returns sr_l
    WHERE sr_l.sr_item_sk = cs.cs_item_sk
) AS lr
WHERE cs.cs_sales_price > 10
  AND sm.sm_type = 'OVERNIGHT'
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = 'HIGH'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr_corr
        WHERE sr_corr.sr_customer_sk = ss.ss_customer_sk
          AND sr_corr.sr_return_quantity > 0
      )
  AND cs.cs_sales_price > (
        SELECT MAX(cs3.cs_sales_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = cs.cs_item_sk
      )
ORDER BY profit_rank, cs.cs_order_number
LIMIT 100
