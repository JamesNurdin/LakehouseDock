WITH daily_stats AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_sales_price) AS avg_sale_price,
        SUM(ss.ss_quantity) AS total_units,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_day_name IN ('Monday','Tuesday','Wednesday','Thursday','Friday')
    GROUP BY d.d_date, d.d_day_name, d.d_weekend
)
SELECT
    d_date,
    d_day_name,
    CASE WHEN d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    total_sales,
    avg_sale_price,
    total_units,
    sales_transactions,
    total_sales / NULLIF(total_units,0) AS avg_price_per_unit,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM daily_stats
WHERE total_sales > 5000
ORDER BY d_date
