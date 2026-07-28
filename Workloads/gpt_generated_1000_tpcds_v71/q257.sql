WITH sales_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(*) AS txn_count
    FROM tpcds.catalog_sales
    WHERE cs_list_price > 100
      AND cs_ext_discount_amt < 50
      AND cs_quantity >= 1
    GROUP BY cs_warehouse_sk, cs_sold_date_sk, cs_sold_time_sk, cs_bill_hdemo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    ib.ib_income_band_sk,
    SUM(s.total_sales) AS sum_sales,
    AVG(s.avg_sales_price) AS avg_price,
    SUM(s.txn_count) AS total_transactions,
    MIN(s.total_sales) AS min_daily_sales,
    MAX(s.total_sales) AS max_daily_sales
FROM sales_agg s
JOIN tpcds.date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t ON s.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND t.t_hour BETWEEN 9 AND 17
  AND hd.hd_dep_count = 5
  AND ib.ib_lower_bound >= 50000
  AND w.w_state = 'CA'
GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, ib.ib_income_band_sk
ORDER BY d.d_year DESC, sum_sales DESC
LIMIT 100
