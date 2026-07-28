WITH warehouse_year_qty AS (
    SELECT
        i.inv_warehouse_sk,
        d.d_year,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_warehouse_sk IN (13, 15, 8)
      AND d.d_current_quarter = 'N'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY i.inv_warehouse_sk, d.d_year
)
SELECT
    inv_warehouse_sk,
    d_year,
    total_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_qty DESC) AS warehouse_rank,
    CASE
        WHEN total_qty >= 1000 THEN 'High'
        WHEN total_qty >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category
FROM warehouse_year_qty
ORDER BY d_year, warehouse_rank
