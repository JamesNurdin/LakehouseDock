/* Goal: Compare total sales for high‑income vs low‑income households, distinguishing those that made purchases during midday hours. The query uses a CTE to aggregate sales, a scalar subquery for the overall average, DISTINCT, EXISTS/NOT EXISTS filters, and combines the two result sets with UNION ALL. */
WITH agg_sales AS (
    SELECT
        hd.hd_demo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ib.ib_upper_bound AS income_upper,
        hd.hd_buy_potential AS buy_potential
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        hd.hd_demo_sk,
        ib.ib_upper_bound,
        hd.hd_buy_potential
)
SELECT DISTINCT
    a.hd_demo_sk,
    a.buy_potential,
    a.total_sales,
    (SELECT AVG(total_sales) FROM agg_sales) AS avg_sales
FROM agg_sales a
WHERE a.income_upper >= 90000
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN time_dim td ON ss2.ss_sold_time_sk = td.t_time_sk
        WHERE ss2.ss_hdemo_sk = a.hd_demo_sk
          AND td.t_hour BETWEEN 12 AND 14
      )
UNION ALL
SELECT DISTINCT
    a.hd_demo_sk,
    a.buy_potential,
    a.total_sales,
    (SELECT AVG(total_sales) FROM agg_sales) AS avg_sales
FROM agg_sales a
WHERE a.income_upper <= 50000
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN time_dim td ON ss2.ss_sold_time_sk = td.t_time_sk
        WHERE ss2.ss_hdemo_sk = a.hd_demo_sk
          AND td.t_hour BETWEEN 12 AND 14
      )
LIMIT 100
