WITH store_year_stats AS (
    SELECT
        dd.d_year AS store_close_year,
        AVG(s.s_floor_space) AS avg_floor_space,
        SUM(s.s_tax_percentage) AS total_tax_perc
    FROM store s
    JOIN date_dim dd ON s.s_closed_date_sk = dd.d_date_sk
    GROUP BY dd.d_year
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    dd_sales.d_year AS first_sales_year,
    dd_ship.d_moy AS first_ship_month,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_visits,
    CASE WHEN COUNT(DISTINCT wp.wp_web_page_id) > 10 THEN 'High' ELSE 'Low' END AS page_activity_level,
    MAX(dd_access.d_date) AS latest_page_access,
    MIN(dd_creation.d_date) AS earliest_page_creation,
    AVG(date_diff('day', dd_creation.d_date, dd_access.d_date)) AS avg_days_to_access,
    sy.avg_floor_space AS avg_store_floor_space_closed_in_sales_year,
    sy.total_tax_perc AS total_store_tax_closed_in_sales_year
FROM customer c
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim dd_sales ON c.c_first_sales_date_sk = dd_sales.d_date_sk
JOIN date_dim dd_ship ON c.c_first_shipto_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_access ON wp.wp_access_date_sk = dd_access.d_date_sk
JOIN date_dim dd_creation ON wp.wp_creation_date_sk = dd_creation.d_date_sk
LEFT JOIN store_year_stats sy ON sy.store_close_year = dd_sales.d_year
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    dd_sales.d_year,
    dd_ship.d_moy,
    sy.avg_floor_space,
    sy.total_tax_perc
