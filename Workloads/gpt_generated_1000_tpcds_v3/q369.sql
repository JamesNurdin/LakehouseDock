WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS sum_quantity,
        AVG(inv_quantity_on_hand) AS avg_quantity,
        COUNT(*) AS cnt_records
    FROM inventory
    WHERE inv_quantity_on_hand >= 600
      AND inv_quantity_on_hand <= 850
    GROUP BY inv_warehouse_sk, inv_date_sk
)
SELECT
    d.d_date,
    d.d_day_name,
    d.d_fy_year,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    SUM(i.sum_quantity) AS total_quantity,
    AVG(i.avg_quantity) AS overall_avg_quantity,
    SUM(i.cnt_records) AS total_records
FROM inv_agg i
INNER JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
INNER JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_day_name = 'Wednesday'
  AND d.d_fy_year = 1912
  AND d.d_current_week = 'N'
  AND w.w_suite_number = 'Suite 90'
  AND w.w_street_type = 'Avenue'
GROUP BY d.d_date, d.d_day_name, d.d_fy_year,
         w.w_warehouse_name, w.w_city, w.w_state
ORDER BY total_quantity DESC
LIMIT 100
