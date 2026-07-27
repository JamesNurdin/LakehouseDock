WITH joined AS (
  SELECT
    cc.cc_state,
    hd.hd_buy_potential,
    cs.cs_ext_sales_price AS cs_sales,
    cs.cs_net_profit AS cs_profit,
    ss.ss_ext_sales_price AS ss_sales,
    ss.ss_net_profit AS ss_profit
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE cc.cc_rec_end_date = DATE '2000-12-31'
    AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
    AND hd.hd_dep_count >= 3
    AND hd.hd_income_band_sk IN (4, 6, 10)
    AND cs.cs_ext_ship_cost > 100.00
    AND ss.ss_quantity > 1
),
agg AS (
  SELECT
    cc_state,
    hd_buy_potential,
    SUM(cs_sales + ss_sales) AS total_sales,
    SUM(cs_profit + ss_profit) AS total_profit,
    COUNT(*) AS txn_count
  FROM joined
  GROUP BY GROUPING SETS (
    (cc_state, hd_buy_potential),
    (cc_state),
    (hd_buy_potential),
    ()
  )
)
SELECT
  cc_state,
  hd_buy_potential,
  total_sales,
  total_profit,
  txn_count,
  ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_sales DESC) AS sales_rank_by_state
FROM agg
WHERE total_sales > 0
ORDER BY cc_state ASC NULLS FIRST, total_sales DESC
LIMIT 100
