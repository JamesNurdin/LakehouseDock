WITH daily_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 200000 THEN 'High' ELSE 'Medium' END AS sales_tier
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_fy_year IN (1913, 1914, 1915)
        AND d.d_month_seq BETWEEN 1200 AND 1300
        AND d.d_weekend = 'N'
        AND cs.cs_net_paid_inc_tax >= 500
        AND cs.cs_quantity BETWEEN 1 AND 5
        AND EXISTS (
            SELECT 1
            FROM warehouse w
            WHERE w.w_warehouse_sk = cs.cs_warehouse_sk
              AND w.w_country = 'United States'
              AND w.w_gmt_offset = -5.00
        )
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ds.d_year,
    AVG(ds.total_sales) AS avg_monthly_sales,
    SUM(ds.total_profit) AS year_profit,
    COUNT(*) AS months_count,
    CASE WHEN SUM(ds.total_profit) > 500000 THEN 'Profitable' ELSE 'Less Profitable' END AS profit_category
FROM daily_sales ds
WHERE
    ds.sales_tier = 'High'
    AND ds.order_cnt > 10
    AND ds.total_sales IS NOT NULL
GROUP BY ds.d_year
HAVING AVG(ds.total_sales) > 100000
ORDER BY avg_monthly_sales DESC
LIMIT 100
