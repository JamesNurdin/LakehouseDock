WITH sales_by_month AS (
    SELECT
        d_sold.d_year AS sales_year,
        d_sold.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS sum_sales,
        SUM(cs.cs_ext_discount_amt) AS sum_discount,
        SUM(cs.cs_net_profit) AS sum_profit,
        COUNT(*) AS cnt_orders,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
            WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 2001 AND 2002
      AND d_sold.d_moy IN (1, 5, 10)
      AND d_ship.d_moy IN (1, 5, 10)
      AND cs.cs_quantity >= 2
      AND cs.cs_ext_wholesale_cost < 5000
      AND cs.cs_net_paid_inc_tax > 1000
    GROUP BY ROLLUP (d_sold.d_year, d_sold.d_month_seq)
)
SELECT
    sales_year,
    sales_category,
    AVG(sum_sales) AS avg_monthly_sales,
    AVG(sum_profit) AS avg_monthly_profit,
    SUM(cnt_orders) AS total_orders,
    CASE
        WHEN AVG(sum_sales) > 80000 THEN 'Very High'
        WHEN AVG(sum_sales) > 60000 THEN 'High'
        ELSE 'Normal'
    END AS year_sales_tier
FROM sales_by_month
WHERE sales_year IS NOT NULL
GROUP BY GROUPING SETS (
    (sales_year, sales_category),
    (sales_year)
)
HAVING SUM(cnt_orders) >= 5
ORDER BY sales_year DESC, sales_category
LIMIT 100
