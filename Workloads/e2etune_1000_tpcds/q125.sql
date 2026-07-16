WITH agg AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_type AS type,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS num_pages,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(DISTINCT sm.sm_carrier) AS num_carriers,
        COUNT(DISTINCT ca.ca_country) AS num_countries,
        ROUND(SUM(i.inv_quantity_on_hand) / NULLIF(COUNT(DISTINCT cp.cp_catalog_page_id), 0), 2) AS qty_per_page
    FROM catalog_page cp
    JOIN inventory i
        ON i.inv_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = i.inv_item_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = i.inv_warehouse_sk
    LEFT JOIN customer_address ca
        ON ca.ca_address_sk = i.inv_warehouse_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
        AND cp.cp_start_date_sk >= 2450800
        AND cp.cp_end_date_sk <= 2451100
    GROUP BY cp.cp_department, cp.cp_type
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    department,
    type,
    num_pages,
    total_quantity,
    avg_vehicle_count,
    num_carriers,
    num_countries,
    qty_per_page,
    RANK() OVER (PARTITION BY department ORDER BY total_quantity DESC) AS dept_qty_rank
FROM agg
ORDER BY total_quantity DESC
LIMIT 20
