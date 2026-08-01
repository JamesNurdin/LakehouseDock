WITH
  -- Apply selective filters on the fact table
  base_sales AS (
    SELECT
      ss.ss_hdemo_sk,
      ss.ss_ext_sales_price,
      ss.ss_quantity,
      ss.ss_net_profit,
      ss.ss_item_sk,
      ss.ss_customer_sk
    FROM tpcds.store_sales ss
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_quantity BETWEEN 1 AND 10
      AND ss.ss_item_sk IN (168038, 6380, 170084)
  ),

  -- Full outer join between the two dimension tables (allowed join rule)
  hd_income_full AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    FULL OUTER JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),

  -- Aggregate sales per household demographic key
  agg_sales AS (
    SELECT
      bs.ss_hdemo_sk,
      COUNT(*) AS sales_cnt,
      SUM(bs.ss_ext_sales_price) AS total_sales,
      AVG(bs.ss_net_profit) AS avg_profit,
      SUM(CASE WHEN bs.ss_quantity > 5 THEN bs.ss_ext_sales_price ELSE 0 END) AS high_qty_sales
    FROM base_sales bs
    GROUP BY bs.ss_hdemo_sk
  ),

  -- Small dimension used for a cross join
  categories AS (
    SELECT DISTINCT hd_buy_potential FROM tpcds.household_demographics
  ),
  cross_set AS (
    SELECT c.hd_buy_potential, seq.n
    FROM categories c
    CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3) seq
  ),

  -- Two SELECTs combined with UNION DISTINCT
  union_agg AS (
    SELECT
      agg.ss_hdemo_sk,
      hd.hd_buy_potential,
      agg.sales_cnt,
      agg.total_sales,
      agg.avg_profit,
      agg.high_qty_sales,
      (
        SELECT COUNT(*)
        FROM tpcds.store_sales ss2
        WHERE ss2.ss_hdemo_sk = agg.ss_hdemo_sk
          AND ss2.ss_ext_sales_price > 2000
      ) AS high_price_cnt
    FROM agg_sales agg
    JOIN hd_income_full hd
      ON agg.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count IS NOT NULL

    UNION DISTINCT

    SELECT
      agg.ss_hdemo_sk,
      hd.hd_buy_potential,
      agg.sales_cnt,
      agg.total_sales,
      agg.avg_profit,
      agg.high_qty_sales,
      (
        SELECT COUNT(*)
        FROM tpcds.store_sales ss2
        WHERE ss2.ss_hdemo_sk = agg.ss_hdemo_sk
          AND ss2.ss_ext_sales_price > 2000
      ) AS high_price_cnt
    FROM agg_sales agg
    JOIN hd_income_full hd
      ON agg.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count IS NULL
  )

SELECT
  ua.ss_hdemo_sk,
  ua.hd_buy_potential,
  ua.sales_cnt,
  ua.total_sales,
  ua.avg_profit,
  ua.high_qty_sales,
  ua.high_price_cnt,
  CASE
    WHEN ua.total_sales > 50000 THEN 'High'
    WHEN ua.total_sales BETWEEN 20000 AND 50000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_category
FROM union_agg ua
WHERE EXISTS (
  SELECT 1
  FROM tpcds.store_sales s3
  WHERE s3.ss_hdemo_sk = ua.ss_hdemo_sk
    AND s3.ss_net_profit > 0
    AND s3.ss_ext_sales_price > (
      SELECT AVG(ss_ext_sales_price) FROM tpcds.store_sales
    )
)
ORDER BY ua.total_sales DESC
LIMIT 100
