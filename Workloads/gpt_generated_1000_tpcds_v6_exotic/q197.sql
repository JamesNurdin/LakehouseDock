SELECT
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  sm.sm_type,
  s.s_store_name,
  r.r_reason_desc,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  SUM(CASE WHEN sm.sm_type = 'AIR' THEN ws.ws_ext_sales_price ELSE 0 END) AS air_sales,
  MIN(ws.ws_ext_sales_price) AS min_sales,
  MAX(ws.ws_ext_sales_price) AS max_sales
FROM tpcds.web_sales ws
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
  AND ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
  AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
  AND ws.ws_ext_sales_price > 1500
  AND ws.ws_quantity >= 2
  AND sm.sm_type IN ('AIR', 'RAIL')
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_order_number = ws.ws_order_number
          AND cs2.cs_item_sk = ws.ws_item_sk
      )
GROUP BY
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  sm.sm_type,
  s.s_store_name,
  r.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
