WITH bill_stats AS (
   SELECT
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     hd.hd_buy_potential,
     SUM(ws.ws_ext_sales_price) AS total_sales,
     AVG(ws.ws_net_profit) AS avg_profit,
     COUNT(DISTINCT ws.ws_order_number) AS order_cnt
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ws.ws_web_site_sk IN (14, 4, 7)
     AND ws.ws_wholesale_cost > 30
     AND ib.ib_lower_bound >= 20001
     AND hd.hd_vehicle_count >= 1
     AND EXISTS (
        SELECT 1
        FROM web_sales ws_sub
        WHERE ws_sub.ws_bill_hdemo_sk = ws.ws_bill_hdemo_sk
          AND ws_sub.ws_ext_tax > 25
     )
   GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
ship_stats AS (
   SELECT
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     hd.hd_buy_potential,
     SUM(ws.ws_ext_sales_price) AS total_sales,
     AVG(ws.ws_net_profit) AS avg_profit,
     COUNT(DISTINCT ws.ws_order_number) AS order_cnt
   FROM web_sales ws
   JOIN household_demographics hd
     ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ws.ws_web_site_sk IN (51, 39)
     AND ws.ws_wholesale_cost BETWEEN 10 AND 20
     AND ib.ib_upper_bound <= 180000
     AND hd.hd_vehicle_count = 0
     AND ws.ws_quantity >= 2
     AND EXISTS (
        SELECT 1
        FROM web_sales ws_sub
        WHERE ws_sub.ws_ship_hdemo_sk = ws.ws_ship_hdemo_sk
          AND ws_sub.ws_ext_tax > 30
     )
   GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
   combined.ib_lower_bound,
   combined.ib_upper_bound,
   combined.hd_buy_potential,
   combined.total_sales,
   combined.avg_profit,
   combined.order_cnt
FROM (
   SELECT ib_lower_bound, ib_upper_bound, hd_buy_potential, total_sales, avg_profit, order_cnt
   FROM bill_stats
   UNION ALL
   SELECT ib_lower_bound, ib_upper_bound, hd_buy_potential, total_sales, avg_profit, order_cnt
   FROM ship_stats
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
