WITH inv_sample AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           AVG(inv_quantity_on_hand) AS avg_qty,
           COUNT(*) AS cnt
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_date_sk, inv_warehouse_sk
),
date_filt AS (
    SELECT d_date_sk,
           d_date,
           d_fy_year,
           d_month_seq,
           d_weekend,
           d_holiday
    FROM date_dim
    WHERE d_fy_year = 1912
      AND d_month_seq BETWEEN 1200 AND 1300
      AND d_weekend = 'N'
      AND d_holiday = 'N'
),
warehouse_filt AS (
    SELECT w_warehouse_sk,
           w_warehouse_name,
           w_city,
           w_state,
           w_gmt_offset
    FROM warehouse
    WHERE w_state IN ('CA', 'TX')
      AND w_gmt_offset > -5
),
store_filt AS (
    SELECT s_store_sk,
           s_store_name,
           s_closed_date_sk,
           s_city,
           s_state,
           s_number_employees
    FROM store
    WHERE s_number_employees > 50
      AND s_state = 'CA'
      AND s_closed_date_sk IS NOT NULL
),
intersect_warehouses AS (
    SELECT w_warehouse_sk FROM warehouse_filt
    INTERSECT
    SELECT inv_warehouse_sk FROM inv_sample WHERE total_qty > 500
)
SELECT
    d.d_date,
    w.w_warehouse_name,
    s.s_store_name,
    i.total_qty,
    i.avg_qty,
    i.cnt
FROM inv_sample i
JOIN date_filt d ON i.inv_date_sk = d.d_date_sk
JOIN store_filt s ON s.s_closed_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk IN (SELECT w_warehouse_sk FROM intersect_warehouses)
  AND NOT EXISTS (
        SELECT 1
        FROM inv_sample i2
        JOIN warehouse w2 ON i2.inv_warehouse_sk = w2.w_warehouse_sk
        WHERE w2.w_city = w.w_city
          AND i2.total_qty > i.total_qty
    )
ORDER BY i.total_qty DESC, d.d_date
OFFSET 0
LIMIT 100
