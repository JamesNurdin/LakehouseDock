WITH base AS (
  SELECT
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_sold_date_sk,
    cs.cs_net_profit AS cs_profit,
    cc.cc_name AS cc_name,
    cc.cc_gmt_offset,
    cp.cp_department,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_store_sk,
    ss.ss_net_profit AS ss_profit,
    s.s_store_name AS s_store_name,
    s.s_state,
    s.s_gmt_offset
  FROM tpcds.catalog_sales cs
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
    AND cp.cp_department = 'Electronics'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_ext_ship_cost > 1000
    AND s.s_state = 'CA'
    AND s.s_gmt_offset = -8.00
    AND cs.cs_quantity >= 2
    AND ss.ss_quantity >= 1
),
agg1 AS (
  SELECT
    s_store_name,
    cc_name,
    SUM(cs_profit) AS catalog_profit,
    SUM(ss_profit) AS store_profit,
    SUM(cs_profit + ss_profit) AS total_profit
  FROM base
  GROUP BY s_store_name, cc_name
)
SELECT
  s_store_name,
  cc_name,
  total_profit,
  AVG(total_profit) OVER (PARTITION BY s_store_name) AS avg_profit_per_store
FROM agg1
WHERE catalog_profit > 500
  AND store_profit > 800
  AND total_profit > 1500
ORDER BY total_profit DESC
LIMIT 100
