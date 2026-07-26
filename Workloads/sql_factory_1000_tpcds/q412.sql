SELECT
    hd.hd_vehicle_count,
    AVG(DATE_DIFF('day', ds_ship.d_date, ds_sales.d_date)) AS avg_days_between,
    MIN(ds_ship.d_date) AS earliest_ship_date,
    MAX(ds_sales.d_date) AS latest_sales_date,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM customer c
JOIN date_dim ds_ship ON c.c_first_shipto_date_sk = ds_ship.d_date_sk
JOIN date_dim ds_sales ON c.c_first_sales_date_sk = ds_sales.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE ds_ship.d_date IS NOT NULL
  AND ds_sales.d_date IS NOT NULL
  AND hd.hd_vehicle_count > 0
GROUP BY hd.hd_vehicle_count
HAVING COUNT(*) > 5
ORDER BY avg_days_between ASC
