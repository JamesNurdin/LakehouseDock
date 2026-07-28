WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 0
   GROUP BY inv_item_sk, inv_warehouse_sk
   HAVING SUM(inv_quantity_on_hand) > 100
)
SELECT DISTINCT
   i.i_item_id,
   i.i_product_name,
   s.s_store_id,
   s.s_store_name,
   s.s_state,
   cd.cd_gender,
   hd.hd_buy_potential,
   p.p_promo_name,
   sm.sm_type,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   inv_agg.total_qty_on_hand,
   SUM(ss.ss_net_profit) AS total_net_profit,
   SUM(ss.ss_net_paid) AS total_net_paid,
   COALESCE(SUM(sr.sr_return_amt), 0) +
   COALESCE(SUM(cr.cr_return_amount), 0) +
   COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
   ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE i.i_current_price > 10.00
  AND s.s_state = 'CA'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '>10000'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND cr.cr_return_amount > 100.00
GROUP BY i.i_item_id,
         i.i_product_name,
         s.s_store_id,
         s.s_store_name,
         s.s_state,
         cd.cd_gender,
         hd.hd_buy_potential,
         p.p_promo_name,
         sm.sm_type,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         inv_agg.total_qty_on_hand
HAVING SUM(ss.ss_net_profit) > 500.00
ORDER BY profit_rank, s.s_store_id
LIMIT 100
