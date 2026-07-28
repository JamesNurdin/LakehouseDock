WITH
  sales_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_warehouse_sk,
      cs.cs_item_sk,
      cs.cs_net_profit,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      ws.ws_sold_date_sk        AS ws_sold_date_sk,
      ws.ws_sold_time_sk        AS ws_sold_time_sk,
      ws.ws_warehouse_sk        AS ws_warehouse_sk,
      ws.ws_item_sk             AS ws_item_sk,
      ws.ws_net_profit,
      ws.ws_bill_cdemo_sk,
      ws.ws_bill_hdemo_sk
    FROM catalog_sales cs
    JOIN web_sales ws
      ON cs.cs_order_number = ws.ws_order_number
  ),
  returns_union AS (
    SELECT cr.cr_order_number AS order_number FROM catalog_returns cr
    UNION
    SELECT wr.wr_order_number AS order_number FROM web_returns wr
  ),
  store_ret AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_reason_sk
    FROM store_returns sr
  )
SELECT
  d_sales.d_year AS year,
  cd.cd_gender,
  hd.hd_vehicle_count,
  SUM(s.cs_net_profit + s.ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT s.cs_order_number) AS orders_sold,
  (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_band
FROM sales_data s
JOIN date_dim d_sales
  ON s.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws
  ON s.ws_sold_date_sk = d_ws.d_date_sk
JOIN call_center cc_sales
  ON s.cs_call_center_sk = cc_sales.cc_call_center_sk
JOIN call_center cc_returns
  ON s.cs_call_center_sk = cc_returns.cc_call_center_sk
JOIN warehouse w_sales
  ON s.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN warehouse w_ws
  ON s.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN customer_demographics cd
  ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_ret sr_ret
  ON d_sales.d_date_sk = sr_ret.sr_returned_date_sk
JOIN reason r
  ON sr_ret.sr_reason_sk = r.r_reason_sk
WHERE EXISTS (
        SELECT 1 FROM returns_union ru WHERE ru.order_number = s.cs_order_number
      )
  AND NOT EXISTS (
        SELECT 1 FROM reason ex WHERE ex.r_reason_desc = 'Did not like the color' AND ex.r_reason_sk = r.r_reason_sk
      )
GROUP BY ROLLUP (d_sales.d_year, cd.cd_gender, hd.hd_vehicle_count)
ORDER BY total_net_profit DESC
LIMIT 100
