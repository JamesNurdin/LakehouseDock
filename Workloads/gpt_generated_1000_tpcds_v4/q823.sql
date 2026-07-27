WITH
  joined_data AS (
    SELECT
      cc.cc_call_center_id,
      ib.ib_income_band_sk,
      CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
      cs.cs_net_profit           AS catalog_profit,
      ss.ss_net_profit           AS store_profit,
      ws.ws_net_profit           AS web_profit,
      cr.cr_net_loss             AS return_loss
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i1
      ON cs.cs_item_sk = i1.i_item_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = i1.i_item_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i1.i_item_sk
    JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i1.i_item_sk
    JOIN household_demographics hd_ws_bill
      ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i1.i_item_sk
  )
SELECT
  cc_call_center_id,
  ib_income_band_sk,
  income_category,
  SUM(catalog_profit) AS total_catalog_profit,
  SUM(store_profit)   AS total_store_profit,
  SUM(web_profit)     AS total_web_profit,
  SUM(return_loss)    AS total_return_loss,
  (SUM(catalog_profit) + SUM(store_profit) + SUM(web_profit) - SUM(return_loss)) AS net_total_profit
FROM joined_data
GROUP BY
  cc_call_center_id,
  ib_income_band_sk,
  income_category
ORDER BY net_total_profit DESC
LIMIT 100
