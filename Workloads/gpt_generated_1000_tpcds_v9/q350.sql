WITH agg_inventory AS (
  SELECT inv_item_sk,
         inv_warehouse_sk,
         SUM(inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory
  GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
  s.s_store_name,
  s.s_state,
  i.i_item_id,
  i.i_product_name,
  i.i_current_price,
  cc.cc_name AS call_center_name,
  cp.cp_department,
  p.p_promo_name,
  wp.wp_url,
  cs.cs_quantity AS catalog_quantity,
  ws.ws_quantity AS web_quantity,
  sr.sr_return_quantity,
  agg.total_qty_on_hand,
  cs.cs_net_paid AS catalog_net_paid,
  ws.ws_net_paid AS web_net_paid,
  sr.sr_refunded_cash,
  (cs.cs_net_profit + ws.ws_net_profit - sr.sr_net_loss) AS total_net_amount,
  RANK() OVER (PARTITION BY s.s_state ORDER BY (cs.cs_net_profit + ws.ws_net_profit - sr.sr_net_loss) DESC) AS state_sales_rank,
  (SELECT MAX(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_item_sk = i.i_item_sk) AS max_web_net_paid_for_item,
  (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk AND sr2.sr_store_sk = s.s_store_sk) AS store_return_count_for_item_store,
  CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END AS good_credit_flag
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_cdemo_sk = cd.cd_demo_sk
 AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN agg_inventory agg
  ON agg.inv_item_sk = i.i_item_sk
 AND agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
  cc.cc_gmt_offset > -5
  AND cp.cp_department = 'Sports'
  AND i.i_current_price BETWEEN 20 AND 500
  AND cd.cd_credit_rating = 'Good'
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 100000
  AND w.w_state = 'CA'
  AND cs.cs_quantity > 0
ORDER BY s.s_state, state_sales_rank
LIMIT 100
