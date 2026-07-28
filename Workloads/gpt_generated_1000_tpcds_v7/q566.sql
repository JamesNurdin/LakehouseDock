/*
  Goal: Analyze the financial impact of web sales and returns across household income bands and buying potential, focusing on higher‑value shipments and low return taxes.
*/
SELECT
  hd.hd_income_band_sk,
  hd.hd_buy_potential,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_ext_sales_price) AS sum_ws_ext_sales_price,
  AVG(ws.ws_net_profit) AS avg_ws_net_profit,
  MIN(wr.wr_return_amt) AS min_return_amt,
  MAX(hd.hd_vehicle_count) AS max_vehicle_count
FROM tpcds.household_demographics AS hd
JOIN tpcds.web_sales AS ws
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_returns AS wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
WHERE
  hd.hd_income_band_sk IN (8, 15)                -- selective income bands
  AND hd.hd_vehicle_count >= 1                    -- households with at least one vehicle
  AND ws.ws_ext_ship_cost > 1000                  -- relatively expensive shipments
  AND ws.ws_net_paid_inc_ship BETWEEN 2000 AND 8000  -- mid‑range net payments
  AND wr.wr_return_tax < 10                       -- low tax on returns
GROUP BY
  hd.hd_income_band_sk,
  hd.hd_buy_potential
ORDER BY
  sum_ws_ext_sales_price DESC
LIMIT 100
