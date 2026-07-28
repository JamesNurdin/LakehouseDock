WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(inv_quantity_on_hand) AS avg_qty,
        COUNT(*) AS cnt_records
    FROM inventory
    WHERE inv_quantity_on_hand > 400
      AND inv_warehouse_sk IN (15, 16)
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.inv_warehouse_sk,
    SUM(i.total_qty) AS sum_qty_by_wh,
    AVG(i.avg_qty) AS avg_qty_by_wh,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    MIN(i.total_qty) AS min_qty,
    MAX(i.total_qty) AS max_qty
FROM inv_agg i
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1215
  AND d.d_holiday = 'N'
  AND d.d_weekend = 'N'
GROUP BY d.d_year, d.d_month_seq, i.inv_warehouse_sk
ORDER BY d.d_year DESC, d.d_month_seq, sum_qty_by_wh DESC
LIMIT 100
