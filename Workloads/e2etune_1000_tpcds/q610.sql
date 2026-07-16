WITH cust_info AS (
    SELECT
        c.c_customer_sk,
        sd.d_year,
        sd.d_moy,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM customer c
    JOIN date_dim sd ON c.c_first_sales_date_sk = sd.d_date_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT
    cp.cp_department AS department,
    sd_start.d_year AS year,
    sd_start.d_moy AS month,
    COUNT(cp.cp_catalog_page_sk) AS total_pages,
    AVG(date_diff('day', sd_start.d_date, sd_end.d_date)) AS avg_duration_days,
    COUNT(DISTINCT CASE WHEN ci.hd_buy_potential = 'HIGH' THEN ci.c_customer_sk END) AS high_potential_customers,
    AVG(CASE WHEN ci.hd_buy_potential = 'HIGH' THEN ci.hd_vehicle_count END) AS avg_vehicles_high_potential,
    RANK() OVER (PARTITION BY sd_start.d_year, sd_start.d_moy ORDER BY COUNT(cp.cp_catalog_page_sk) DESC) AS dept_rank
FROM catalog_page cp
JOIN date_dim sd_start ON cp.cp_start_date_sk = sd_start.d_date_sk
JOIN date_dim sd_end   ON cp.cp_end_date_sk   = sd_end.d_date_sk
LEFT JOIN cust_info ci   ON ci.d_year = sd_start.d_year AND ci.d_moy = sd_start.d_moy
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department IN ('DEPARTMENT', 'ELECTRONICS', 'HOME')
GROUP BY cp.cp_department, sd_start.d_year, sd_start.d_moy
HAVING COUNT(cp.cp_catalog_page_sk) >= 10
ORDER BY year, month, dept_rank
