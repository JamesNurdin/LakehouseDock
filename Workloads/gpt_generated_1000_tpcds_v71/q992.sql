WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      s.s_store_id,
      hd.hd_demo_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_wholesale_cost > 20
      AND ss.ss_ext_tax < 100
      AND hd.hd_vehicle_count >= 2
      AND s.s_rec_start_date >= DATE '1999-01-01'
    GROUP BY ss.ss_store_sk, s.s_store_id, hd.hd_demo_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_refunded_hdemo_sk AS hd_demo_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity >= 1
      AND cr.cr_fee < 5
      AND cr.cr_refunded_hdemo_sk IS NOT NULL
    GROUP BY cr.cr_refunded_hdemo_sk
  ),
  combined AS (
    SELECT
      sagg.ss_store_sk,
      sagg.s_store_id,
      sagg.total_sales,
      sagg.total_profit,
      sagg.sales_cnt,
      COALESCE(ragg.total_return_amount, 0) AS total_return_amount,
      COALESCE(ragg.return_cnt, 0) AS return_cnt
    FROM sales_agg sagg
    LEFT JOIN returns_agg ragg ON sagg.hd_demo_sk = ragg.hd_demo_sk
    UNION ALL
    SELECT
      NULL AS ss_store_sk,
      'ALL_STORES' AS s_store_id,
      SUM(sagg.total_sales) AS total_sales,
      SUM(sagg.total_profit) AS total_profit,
      SUM(sagg.sales_cnt) AS sales_cnt,
      COALESCE(SUM(ragg.total_return_amount), 0) AS total_return_amount,
      COALESCE(SUM(ragg.return_cnt), 0) AS return_cnt
    FROM sales_agg sagg
    LEFT JOIN returns_agg ragg ON sagg.hd_demo_sk = ragg.hd_demo_sk
  )
SELECT DISTINCT
  c.s_store_id,
  c.total_sales,
  c.total_profit,
  c.total_return_amount,
  c.sales_cnt,
  c.return_cnt,
  (c.total_profit - c.total_return_amount) AS net_contribution
FROM combined c
WHERE c.total_sales > 10000
  AND c.total_profit > 1000
  AND c.total_return_amount < 5000
  AND c.sales_cnt >= 10
ORDER BY net_contribution DESC
LIMIT 100
