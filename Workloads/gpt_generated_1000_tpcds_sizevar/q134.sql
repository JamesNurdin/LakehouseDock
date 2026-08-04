WITH base AS (
   SELECT cr.cr_returning_hdemo_sk AS hd_demo_sk,
          w.w_county,
          hd.hd_buy_potential,
          cr.cr_return_amount,
          sr.sr_return_amt,
          cr.cr_return_ship_cost,
          sr.sr_return_ship_cost
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_ship_mode_sk = 10
     AND cr.cr_return_amount > 150.00
     AND w.w_warehouse_sq_ft > 300000
     AND hd.hd_income_band_sk BETWEEN 5 AND 15
     AND hd.hd_vehicle_count >= 2
),
set1 AS (
   SELECT hd_demo_sk FROM base WHERE hd_buy_potential = '1001-5000'
),
set2 AS (
   SELECT hd_demo_sk FROM base WHERE w_county = 'Franklin Parish'
),
common_hd AS (
   SELECT hd_demo_sk FROM set1 INTERSECT SELECT hd_demo_sk FROM set2
),
agg_part1 AS (
   SELECT hd.hd_buy_potential,
          w.w_county,
          SUM(cr.cr_return_amount) AS sum_return_amount,
          AVG(sr.sr_return_amt) AS avg_return_amt,
          COUNT(*) AS cnt
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_demo_sk IN (SELECT hd_demo_sk FROM common_hd)
     AND cr.cr_return_ship_cost < 200.00
     AND sr.sr_return_ship_cost < 100.00
   GROUP BY ROLLUP (hd.hd_buy_potential, w.w_county)
),
agg_part2 AS (
   SELECT hd.hd_buy_potential,
          w.w_county,
          SUM(cr.cr_return_amount) * 0.9 AS sum_return_amount,
          AVG(sr.sr_return_amt) * 1.1 AS avg_return_amt,
          COUNT(*) AS cnt
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_demo_sk IN (SELECT hd_demo_sk FROM common_hd)
     AND cr.cr_return_ship_cost BETWEEN 100.00 AND 300.00
     AND sr.sr_return_ship_cost BETWEEN 50.00 AND 150.00
   GROUP BY ROLLUP (hd.hd_buy_potential, w.w_county)
),
final_union AS (
   SELECT hd_buy_potential,
          w_county,
          sum_return_amount,
          avg_return_amt,
          cnt
   FROM agg_part1
   UNION
   SELECT hd_buy_potential,
          w_county,
          sum_return_amount,
          avg_return_amt,
          cnt
   FROM agg_part2
)
SELECT hd_buy_potential,
       w_county,
       SUM(sum_return_amount) AS total_return_amount,
       AVG(avg_return_amt) AS overall_avg_return_amt,
       SUM(cnt) AS total_count
FROM final_union
GROUP BY ROLLUP (hd_buy_potential, w_county)
ORDER BY hd_buy_potential, w_county
LIMIT 100
