WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d.d_date,
    i.total_qty,
    CASE WHEN i.total_qty > 800 THEN 'High' ELSE 'Normal' END AS inventory_level,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = s.s_state) AS stores_in_state,
    (SELECT AVG(i2.total_qty) FROM inv_agg i2 WHERE i2.inv_warehouse_sk = i.inv_warehouse_sk) AS avg_qty_per_warehouse
FROM inv_agg i
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND d.d_quarter_seq = 5
  AND d.d_holiday = 'N'
  AND d.d_weekend = 'N'
  AND d.d_fy_week_seq IN (8, 10, 11, 18, 20)
  AND s.s_company_id = 1
  AND s.s_number_employees > 0
ORDER BY i.total_qty DESC, s.s_store_id
