WITH hd_ib AS (
   SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
   FROM household_demographics hd
   FULL OUTER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
group_sales AS (
   SELECT
      hd_ib.hd_buy_potential AS buy_potential,
      hd_ib.ib_lower_bound AS income_lower,
      SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS order_count
   FROM web_sales ws
   LEFT JOIN hd_ib
      ON ws.ws_bill_hdemo_sk = hd_ib.hd_demo_sk
   WHERE ws.ws_net_paid_inc_ship_tax > 500
     AND ws.ws_net_profit < 0
     AND hd_ib.hd_vehicle_count >= 0
   GROUP BY ROLLUP (hd_ib.hd_buy_potential, hd_ib.ib_lower_bound)
)
SELECT
   buy_potential,
   income_lower,
   total_net_paid,
   total_profit,
   order_count,
   total_net_paid / NULLIF(order_count, 0) AS avg_net_paid_per_order,
   ROW_NUMBER() OVER (PARTITION BY buy_potential ORDER BY total_net_paid DESC) AS rn_per_buy,
   AVG(total_profit) OVER () AS avg_profit_all_groups
FROM group_sales
WHERE total_profit < -1000
  AND buy_potential IS NOT NULL
  AND income_lower IS NOT NULL
ORDER BY total_net_paid DESC
LIMIT 100
