/*
  Goal: Identify household demographics segments with strong catalog sales, significant store and web returns, and rank them by total sales within each income band.
*/
WITH
  store_agg AS (
    SELECT
      sr_hdemo_sk,
      COUNT(*) AS store_ret_cnt,
      SUM(sr_net_loss) AS store_net_loss
    FROM store_returns
    WHERE sr_return_amt > 150
    GROUP BY sr_hdemo_sk
  ),
  web_agg AS (
    SELECT
      wr_refunded_hdemo_sk AS wr_hdemo_sk,
      COUNT(*) AS web_ret_cnt,
      SUM(wr_net_loss) AS web_net_loss
    FROM web_returns
    WHERE wr_return_amt > 150
    GROUP BY wr_refunded_hdemo_sk
  ),
  intersect_demo AS (
    SELECT sr_hdemo_sk AS hd_demo_sk
    FROM store_returns
    WHERE sr_return_amt > 200
    INTERSECT
    SELECT wr_refunded_hdemo_sk
    FROM web_returns
    WHERE wr_return_amt > 200
  ),
  base AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      sa.store_ret_cnt,
      wa.web_ret_cnt,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      CASE WHEN hd.hd_income_band_sk > 10 THEN 'High' ELSE 'Low' END AS income_category
    FROM household_demographics hd
    JOIN store_agg sa ON sa.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_agg wa ON wa.wr_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count BETWEEN 2 AND 9
      AND hd.hd_income_band_sk IN (1, 6, 7, 9, 19)
      AND cs.cs_quantity > 30
      AND hd.hd_buy_potential LIKE '%-%'
      AND hd.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_demo)
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = hd.hd_demo_sk
          AND cs2.cs_wholesale_cost > 40
      )
    GROUP BY
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      sa.store_ret_cnt,
      wa.web_ret_cnt,
      CASE WHEN hd.hd_income_band_sk > 10 THEN 'High' ELSE 'Low' END
  )
SELECT
  hd_demo_sk,
  hd_income_band_sk,
  hd_buy_potential,
  store_ret_cnt,
  web_ret_cnt,
  total_sales,
  income_category,
  ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
