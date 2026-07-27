WITH union_ship_modes AS (
    SELECT sm_ship_mode_id AS ship_mode_id, sm_carrier
    FROM ship_mode
    WHERE sm_carrier = 'UPS'
    UNION
    SELECT sm_ship_mode_id, sm_carrier
    FROM ship_mode
    WHERE sm_carrier = 'BARIAN'
),
scalar_total_store_sales AS (
    SELECT SUM(ss_net_paid) AS total_store_sales
    FROM store_sales
    WHERE ss_list_price > 100
)
SELECT
    d.d_year,
    sm.sm_carrier,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    (SELECT total_store_sales FROM scalar_total_store_sales) AS total_store_sales_overall
FROM
    date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN union_ship_modes usm ON sm.sm_ship_mode_id = usm.ship_mode_id
WHERE
    d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND ss.ss_list_price > 50
    AND sm.sm_carrier IN ('UPS', 'BARIAN')
    AND cp.cp_department = 'Electronics'
    AND c.c_birth_country = 'United States'
GROUP BY
    d.d_year,
    sm.sm_carrier,
    cp.cp_department
ORDER BY
    store_net_paid DESC
LIMIT 100
