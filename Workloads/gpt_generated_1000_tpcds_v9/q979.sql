WITH cs_agg AS (
  SELECT
    sm.sm_ship_mode_sk,
    sm.sm_carrier,
    ib.ib_lower_bound,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    SUM(cs.cs_quantity) AS total_catalog_quantity,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cp.cp_end_date_sk = 2451024
    AND cp.cp_catalog_number = 10
    AND cp.cp_department = 'Electronics'
    AND sm.sm_carrier = 'FEDEX'
    AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
    AND ib.ib_lower_bound >= 10000
    AND cs.cs_quantity >= 2
    AND cs.cs_net_paid > 500
  GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, ib.ib_lower_bound
),
ws_agg AS (
  SELECT
    sm.sm_ship_mode_sk,
    sm.sm_carrier,
    ib.ib_lower_bound,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    SUM(ws.ws_quantity) AS total_web_quantity,
    SUM(ws.ws_net_paid) AS total_web_net_paid
  FROM web_sales ws
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE sm.sm_carrier = 'FEDEX'
    AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
    AND ib.ib_lower_bound >= 10000
    AND ws.ws_quantity >= 2
    AND ws.ws_net_paid > 500
    AND EXISTS (
      SELECT 1 FROM catalog_sales cs2
      WHERE cs2.cs_ship_mode_sk = ws.ws_ship_mode_sk
        AND cs2.cs_sold_date_sk = ws.ws_sold_date_sk
    )
  GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, ib.ib_lower_bound
)
SELECT
  carrier,
  income_lower_bound,
  SUM(total_catalog_net_profit) AS total_catalog_net_profit,
  SUM(total_web_net_profit) AS total_web_net_profit,
  SUM(catalog_orders) AS catalog_orders,
  SUM(web_orders) AS web_orders,
  AVG(avg_catalog_discount) AS avg_catalog_discount,
  AVG(avg_web_discount) AS avg_web_discount,
  CASE
    WHEN SUM(total_catalog_net_profit) + SUM(total_web_net_profit) > 100000 THEN 'HIGH'
    WHEN SUM(total_catalog_net_profit) + SUM(total_web_net_profit) > 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_level,
  (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) AS overall_avg_catalog_profit
FROM (
  SELECT
    COALESCE(cs.sm_carrier, ws.sm_carrier) AS carrier,
    COALESCE(cs.ib_lower_bound, ws.ib_lower_bound) AS income_lower_bound,
    cs.total_catalog_net_profit,
    ws.total_web_net_profit,
    cs.catalog_orders,
    ws.web_orders,
    cs.avg_catalog_discount,
    ws.avg_web_discount
  FROM cs_agg cs
  FULL OUTER JOIN ws_agg ws
    ON cs.sm_ship_mode_sk = ws.sm_ship_mode_sk
    AND cs.ib_lower_bound = ws.ib_lower_bound
) AS combined
GROUP BY GROUPING SETS (
  (carrier, income_lower_bound),
  (carrier),
  (income_lower_bound),
  ()
)
ORDER BY carrier, income_lower_bound
