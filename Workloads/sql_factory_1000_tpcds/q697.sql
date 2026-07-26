WITH catalog_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
store_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
combined_monthly AS (
    SELECT
        COALESCE(cm.year, sm.year) AS year,
        COALESCE(cm.month_seq, sm.month_seq) AS month_seq,
        COALESCE(cm.catalog_profit, 0) AS catalog_profit,
        COALESCE(sm.store_profit, 0) AS store_profit,
        COALESCE(cm.catalog_sales, 0) AS catalog_sales,
        COALESCE(sm.store_sales, 0) AS store_sales
    FROM catalog_monthly cm
    FULL OUTER JOIN store_monthly sm
      ON cm.year = sm.year AND cm.month_seq = sm.month_seq
)
SELECT
    year,
    month_seq,
    catalog_profit,
    store_profit,
    (catalog_profit + store_profit) AS total_profit,
    LAG(catalog_profit + store_profit) OVER (PARTITION BY year ORDER BY month_seq) AS prev_total_profit,
    (catalog_profit + store_profit) - LAG(catalog_profit + store_profit) OVER (PARTITION BY year ORDER BY month_seq) AS profit_change,
    CASE
        WHEN (catalog_profit + store_profit) >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS profit_sign
FROM combined_monthly
ORDER BY year, month_seq
