WITH monthly_inventory AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_name AS warehouse_name,
        w.w_state,
        d.d_year,
        d.d_moy AS month,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2022
      AND d.d_holiday = 'N'  -- exclude holiday dates
      AND w.w_state IN ('CA', 'TX', 'NY')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_state, d.d_year, d.d_moy
)
SELECT
    warehouse_name,
    w_state,
    d_year,
    month,
    total_qty,
    LAG(total_qty) OVER (PARTITION BY warehouse_sk ORDER BY d_year, month) AS prev_month_qty,
    CASE
        WHEN LAG(total_qty) OVER (PARTITION BY warehouse_sk ORDER BY d_year, month) = 0 THEN NULL
        ELSE (total_qty - LAG(total_qty) OVER (PARTITION BY warehouse_sk ORDER BY d_year, month)) * 100.0 / LAG(total_qty) OVER (PARTITION BY warehouse_sk ORDER BY d_year, month)
    END AS mom_pct_change,
    RANK() OVER (PARTITION BY d_year, month ORDER BY total_qty DESC) AS monthly_warehouse_rank
FROM monthly_inventory
WHERE total_qty > 0
ORDER BY w_state, warehouse_name, d_year, month
