WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    ss_agg.store_sk,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(wr.wr_return_amt_inc_tax) AS total_returns,
    ss_agg.total_sales,
    LAG(ss_agg.total_sales) OVER (PARTITION BY ss_agg.store_sk ORDER BY d.d_date) AS prev_day_sales,
    SUM(ss_agg.total_sales) OVER (PARTITION BY ss_agg.store_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store_sales_agg ss_agg ON ss_agg.sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND hd.hd_dep_count IN (3, 4)
  AND cs.cs_ext_tax > 100
GROUP BY d.d_date, d.d_year, hd.hd_income_band_sk, hd.hd_dep_count, ss_agg.store_sk, ss_agg.total_sales
ORDER BY d.d_date DESC
LIMIT 100
