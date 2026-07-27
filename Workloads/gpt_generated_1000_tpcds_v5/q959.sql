WITH sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        'sales' AS metric,
        SUM(ss.ss_ext_sales_price) AS value
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY d.d_date
),
inventory_agg AS (
    SELECT
        d.d_date AS sale_date,
        'inventory' AS metric,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS value
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY d.d_date
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM inventory_agg
ORDER BY sale_date DESC, metric
LIMIT 100
