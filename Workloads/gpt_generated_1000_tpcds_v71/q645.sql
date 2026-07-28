WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales
    WHERE ss_wholesale_cost > 20
      AND ss_ext_sales_price > 1000
    GROUP BY ss_sold_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    SUM(s.total_sales) AS quarter_sales,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN s.total_sales ELSE 0 END) AS weekend_sales,
    AVG(s.total_profit) AS avg_profit_per_date
FROM sales_agg s
JOIN date_dim d
    ON s.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_weekend = 'Y'
  AND s.total_sales > 5000
GROUP BY d.d_year, d.d_quarter_name
ORDER BY quarter_sales DESC
LIMIT 100
