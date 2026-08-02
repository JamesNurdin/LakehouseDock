WITH store_agg AS (
    SELECT ss.ss_hdemo_sk AS hd_demo_sk,
           COUNT(*) AS store_txn_cnt,
           SUM(ss.ss_ext_sales_price) AS store_sales_sum,
           AVG(ss.ss_quantity) AS store_qty_avg,
           MIN(ss.ss_ext_sales_price) AS store_sales_min,
           MAX(ss.ss_ext_sales_price) AS store_sales_max
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    WHERE ss.ss_item_sk IN (94873, 51933)
      AND ss.ss_ext_wholesale_cost > 1000
      AND ss.ss_quantity >= 1
    GROUP BY ss.ss_hdemo_sk
),
catalog_agg AS (
    SELECT cs.cs_bill_hdemo_sk AS hd_demo_sk,
           COUNT(*) AS catalog_txn_cnt,
           SUM(cs.cs_ext_sales_price) AS catalog_sales_sum,
           AVG(cs.cs_quantity) AS catalog_qty_avg,
           MIN(cs.cs_ext_sales_price) AS catalog_sales_min,
           MAX(cs.cs_ext_sales_price) AS catalog_sales_max
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    WHERE cs.cs_wholesale_cost > 50
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_quantity >= 1
    GROUP BY cs.cs_bill_hdemo_sk
)
SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
       COALESCE(sa.store_sales_sum, 0) AS store_sales_sum,
       COALESCE(sa.store_qty_avg, 0) AS store_qty_avg,
       COALESCE(ca.catalog_txn_cnt, 0) AS catalog_txn_cnt,
       COALESCE(ca.catalog_sales_sum, 0) AS catalog_sales_sum,
       COALESCE(ca.catalog_qty_avg, 0) AS catalog_qty_avg
FROM household_demographics hd
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_agg sa
  ON sa.hd_demo_sk = hd.hd_demo_sk
LEFT JOIN catalog_agg ca
  ON ca.hd_demo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential = '1001-5000'
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 30000
ORDER BY store_sales_sum DESC, catalog_sales_sum DESC
LIMIT 100
