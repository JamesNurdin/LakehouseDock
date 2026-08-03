WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_agg AS (
    SELECT
        d.d_date,
        SUM(ss.ss_net_paid_inc_tax) AS metric_amount,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS metric_rank,
        (
            SELECT AVG(ib.ib_lower_bound)
            FROM household_demographics hd_corr
            JOIN income_band ib ON hd_corr.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd_corr.hd_demo_sk = ss.ss_hdemo_sk
        ) AS avg_income_lower_bound
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk
            AND ss2.ss_quantity > 5
      )
    GROUP BY d.d_date, d.d_year, ss.ss_hdemo_sk
),
returns_agg AS (
    SELECT
        d.d_date,
        SUM(cr.cr_net_loss) AS metric_amount,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS metric_rank,
        (
            SELECT AVG(ib.ib_lower_bound)
            FROM household_demographics hd_corr
            JOIN income_band ib ON hd_corr.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd_corr.hd_demo_sk = cr.cr_refunded_hdemo_sk
        ) AS avg_income_lower_bound
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, d.d_year, cr.cr_refunded_hdemo_sk
)
SELECT d_date,
       metric_amount,
       metric_rank,
       avg_income_lower_bound
FROM sales_agg
UNION ALL
SELECT d_date,
       metric_amount,
       metric_rank,
       avg_income_lower_bound
FROM returns_agg
ORDER BY d_date
LIMIT 100
