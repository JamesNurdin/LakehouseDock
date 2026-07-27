WITH store_data AS (
   SELECT
       i.i_item_id,
       'Store' AS channel,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS transaction_cnt
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE i.i_units = 'Case'
     AND hd.hd_vehicle_count > 2
     AND ib.ib_lower_bound > 50000
     AND EXISTS (
         SELECT 1 FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
           AND inv.inv_quantity_on_hand > 0
     )
   GROUP BY i.i_item_id
),
web_data AS (
   SELECT
       i.i_item_id,
       'Web' AS channel,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS transaction_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE i.i_units = 'Case'
     AND ws.ws_ext_discount_amt > 1000
     AND ib.ib_upper_bound < (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) - 10000
   GROUP BY i.i_item_id
)
SELECT i_item_id,
       channel,
       total_profit,
       transaction_cnt
FROM (
   SELECT i_item_id, channel, total_profit, transaction_cnt FROM store_data
   UNION ALL
   SELECT i_item_id, channel, total_profit, transaction_cnt FROM web_data
) AS combined
ORDER BY total_profit DESC
LIMIT 20
