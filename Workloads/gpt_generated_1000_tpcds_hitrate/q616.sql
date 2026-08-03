WITH daily_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_item_sk IN (7, 22, 32)                           -- predicate 1
      AND i.inv_warehouse_sk BETWEEN 10 AND 20                  -- predicate 2
      AND i.inv_quantity_on_hand > 100                         -- predicate 3
      AND d.d_quarter_seq BETWEEN 3 AND 13                     -- predicate 4
      AND d.d_year = 2001                                      -- predicate 5
    GROUP BY CUBE (d.d_year, d.d_quarter_seq, d.d_month_seq, i.inv_warehouse_sk)
)
SELECT
    da.d_year,
    da.d_quarter_seq,
    da.d_month_seq,
    da.inv_warehouse_sk,
    da.total_qty,
    da.cnt,
    (SELECT da.total_qty / NULLIF(da.cnt, 0)) AS avg_qty_per_row,   -- scalar subquery
    EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_warehouse_sk = da.inv_warehouse_sk
          AND i2.inv_quantity_on_hand > 500
    ) AS has_large_qty,
    l.max_qty_warehouse_year
FROM daily_agg da
LEFT JOIN LATERAL (
    SELECT MAX(i3.inv_quantity_on_hand) AS max_qty_warehouse_year
    FROM inventory i3
    JOIN date_dim d3 ON i3.inv_date_sk = d3.d_date_sk
    WHERE i3.inv_warehouse_sk = da.inv_warehouse_sk
      AND d3.d_year = da.d_year
) l ON TRUE
WHERE da.total_qty > 200                                            -- additional filter
ORDER BY da.d_year DESC, da.d_quarter_seq, da.inv_warehouse_sk
LIMIT 100
