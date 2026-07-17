WITH daily_inventory AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2002-12-31'
    GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq
),
monthly_avg_inventory AS (
    SELECT
        w_warehouse_name,
        d_year,
        AVG(total_quantity_on_hand) AS avg_quantity_per_month
    FROM daily_inventory
    GROUP BY w_warehouse_name, d_year
)
SELECT
    w_warehouse_name,
    AVG(avg_quantity_per_month) AS avg_quantity_over_years
FROM monthly_avg_inventory
GROUP BY w_warehouse_name
HAVING AVG(avg_quantity_per_month) > 1000
ORDER BY avg_quantity_over_years DESC
