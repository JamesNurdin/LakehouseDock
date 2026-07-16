WITH base AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        td.t_shift,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        AVG(cp.cp_catalog_page_number) AS avg_page_number,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        AVG(hd.hd_dep_count) AS avg_dependents,
        COUNT(*) AS total_rows
    FROM
        catalog_page cp
        JOIN time_dim td ON cp.cp_start_date_sk = td.t_time_sk
        CROSS JOIN household_demographics hd
        CROSS JOIN customer_address ca
    WHERE
        cp.cp_type = 'monthly'
        AND cp.cp_department = 'DEPARTMENT'
        AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
        AND td.t_shift = 'Evening'
        AND ca.ca_country = 'United States'
        AND hd.hd_buy_potential = 'High'
    GROUP BY
        cp.cp_department,
        td.t_hour,
        td.t_shift
    HAVING
        COUNT(*) > 100
)
SELECT
    cp_department,
    t_hour,
    t_shift,
    distinct_pages,
    avg_page_number,
    total_vehicles,
    avg_dependents,
    total_rows,
    RANK() OVER (ORDER BY total_vehicles DESC) AS vehicle_rank
FROM base
ORDER BY vehicle_rank
LIMIT 50
