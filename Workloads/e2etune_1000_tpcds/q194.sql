WITH agg AS (
    SELECT
        w.w_state,
        w.w_country,
        COUNT(DISTINCT w.w_warehouse_id) AS num_warehouses,
        AVG(w.w_warehouse_sq_ft) AS avg_warehouse_sq_ft,
        SUM(ws.web_tax_percentage) AS total_tax_percentage,
        COUNT(DISTINCT cp.cp_catalog_page_id) FILTER (WHERE cp.cp_type = 'Promo') AS promo_catalog_pages
    FROM
        warehouse w
        JOIN web_site ws
            ON w.w_state = ws.web_state
            AND w.w_country = ws.web_country
            AND w.w_city = ws.web_city
        LEFT JOIN catalog_page cp
            ON cp.cp_catalog_number = ((w.w_warehouse_sk % 5) + 1)
            AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
    WHERE
        w.w_warehouse_sq_ft > 50000
        AND ws.web_tax_percentage > 0.05
    GROUP BY
        w.w_state,
        w.w_country
    HAVING
        COUNT(DISTINCT w.w_warehouse_id) >= 2
)
SELECT
    w_state,
    w_country,
    num_warehouses,
    avg_warehouse_sq_ft,
    total_tax_percentage,
    promo_catalog_pages,
    RANK() OVER (PARTITION BY w_country ORDER BY total_tax_percentage DESC) AS tax_rank,
    ROW_NUMBER() OVER (PARTITION BY w_country ORDER BY avg_warehouse_sq_ft DESC) AS avg_sqft_rownum
FROM agg
ORDER BY total_tax_percentage DESC, avg_warehouse_sq_ft DESC
LIMIT 20
