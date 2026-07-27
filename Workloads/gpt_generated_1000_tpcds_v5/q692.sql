WITH filtered AS (
    SELECT
        i.inv_quantity_on_hand,
        i.inv_warehouse_sk,
        i.inv_date_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_county,
        w.w_city,
        d.d_year,
        d.d_date
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE w.w_county = 'Marshall County'
      AND w.w_city = 'Greenwood'
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND i.inv_quantity_on_hand > 0
)
SELECT
    f.w_warehouse_id,
    f.w_warehouse_name,
    f.d_year,
    COUNT(*) AS inventory_days,
    SUM(f.inv_quantity_on_hand) AS total_quantity,
    AVG(f.inv_quantity_on_hand) AS avg_quantity,
    MIN(f.inv_quantity_on_hand) AS min_quantity,
    MAX(f.inv_quantity_on_hand) AS max_quantity,
    SUM(CASE WHEN f.inv_quantity_on_hand > 100 THEN f.inv_quantity_on_hand ELSE 0 END) AS high_quantity_sum,
    SUM(CASE WHEN f.inv_quantity_on_hand <= 100 THEN f.inv_quantity_on_hand ELSE 0 END) AS low_quantity_sum
FROM filtered f
GROUP BY f.w_warehouse_id, f.w_warehouse_name, f.d_year
ORDER BY total_quantity DESC
LIMIT 100
