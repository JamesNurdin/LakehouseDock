WITH
  sales AS (
    SELECT
      hd.hd_demo_sk,
      SUM(ss.ss_ext_sales_price)                                   AS total_sales,
      SUM(ss.ss_net_profit)                                        AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 100000                     -- focus on higher income bands
    GROUP BY hd.hd_demo_sk
  ),
  returns AS (
    SELECT
      hd.hd_demo_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*)                AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
  ),
  web_ret AS (
    SELECT
      hd.hd_demo_sk,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
  ),
  intersected_keys AS (
    SELECT hd_demo_sk
    FROM (
      SELECT hd_demo_sk FROM sales   WHERE total_sales > 50000
      INTERSECT
      SELECT hd_demo_sk FROM returns WHERE total_return_amount < 1000
    ) AS i
    EXCEPT
    SELECT hd_demo_sk FROM web_ret WHERE return_cnt > 10
  )
SELECT
  s.hd_demo_sk,
  s.total_sales,
  s.profit_category
FROM sales s
JOIN intersected_keys ik ON s.hd_demo_sk = ik.hd_demo_sk
ORDER BY s.total_sales DESC
LIMIT 100
