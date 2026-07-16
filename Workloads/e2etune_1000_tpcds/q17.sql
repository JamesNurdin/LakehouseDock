WITH base AS (
    SELECT
        c.c_birth_year,
        hd.hd_vehicle_count,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(wp.wp_page_cnt) AS avg_pages_per_customer,
        SUM(wp.wp_page_cnt) AS total_pages,
        SUM(CASE WHEN c.c_salutation = 'Mr.' THEN 1 ELSE 0 END) AS mr_customers
    FROM
        customer c
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN (
            SELECT wp_customer_sk, COUNT(*) AS wp_page_cnt
            FROM web_page
            GROUP BY wp_customer_sk
        ) wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month IN (4, 6, 9, 12)
        AND hd.hd_income_band_sk BETWEEN 10 AND 20
        AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2453000
    GROUP BY
        c.c_birth_year,
        hd.hd_vehicle_count
    HAVING
        COUNT(DISTINCT c.c_customer_sk) >= 10
)
SELECT
    b.c_birth_year,
    b.hd_vehicle_count,
    b.num_customers,
    b.avg_pages_per_customer,
    b.total_pages,
    RANK() OVER (ORDER BY b.num_customers DESC) AS customer_rank,
    CASE WHEN b.num_customers > 0 THEN 100.0 * b.mr_customers / b.num_customers ELSE 0 END AS pct_mr_customers,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost,
    (SELECT COUNT(*) FROM ship_mode WHERE sm_type = 'AIR') AS total_air_ship_modes,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS total_ca_stores,
    (SELECT AVG(w_warehouse_sq_ft) FROM warehouse) AS avg_warehouse_sq_ft
FROM base b
ORDER BY b.num_customers DESC
LIMIT 20
