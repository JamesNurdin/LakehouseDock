WITH base AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_date_sk,
        i.inv_quantity_on_hand,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        d.d_current_quarter
    FROM inventory i
    JOIN date_dim d
      ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_name = 'Q1'
      AND d.d_current_quarter = 'Y'
      AND i.inv_warehouse_sk IN (3, 5, 20)
      AND i.inv_quantity_on_hand > 0
),
agg AS (
    SELECT
        inv_warehouse_sk,
        d_year,
        d_quarter_name,
        SUM(inv_quantity_on_hand) AS total_qty,
        MAX(d_date) AS latest_date
    FROM base
    GROUP BY inv_warehouse_sk, d_year, d_quarter_name
),
ranked AS (
    SELECT
        inv_warehouse_sk,
        d_year,
        d_quarter_name,
        total_qty,
        latest_date,
        RANK() OVER (PARTITION BY d_year ORDER BY total_qty DESC) AS warehouse_rank
    FROM agg
)
SELECT DISTINCT
    r.inv_warehouse_sk,
    r.d_year,
    r.d_quarter_name,
    r.total_qty,
    r.warehouse_rank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_item_sk = b.inv_item_sk
              AND i2.inv_quantity_on_hand > 1000
        ) THEN 'HIGH_DEMAND'
        ELSE 'NORMAL'
    END AS demand_category
FROM ranked r
JOIN base b
  ON r.inv_warehouse_sk = b.inv_warehouse_sk
WHERE r.warehouse_rank <= 5
ORDER BY r.total_qty DESC
