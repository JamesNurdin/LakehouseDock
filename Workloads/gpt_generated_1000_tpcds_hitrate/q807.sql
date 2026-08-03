WITH recent_dates AS (
    SELECT d_date_sk,
           d_year,
           d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
),
max_year AS (
    SELECT MAX(d_year) AS max_yr FROM date_dim
)
SELECT
    u.d_year,
    COUNT(DISTINCT u.metric_name) AS metric_type_cnt,
    SUM(DISTINCT u.metric_value) AS sum_distinct_metric_value,
    CASE
        WHEN COUNT(DISTINCT u.metric_name) = 2 THEN 'Both'
        ELSE 'Partial'
    END AS completeness_flag
FROM (
    -- Inventory quantity per year (right‑outer join keeps all dates)
    SELECT
        rd.d_year,
        'InventoryQty' AS metric_name,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS metric_value
    FROM inventory i
    RIGHT OUTER JOIN recent_dates rd
        ON i.inv_date_sk = rd.d_date_sk
    GROUP BY rd.d_year

    UNION

    -- Distinct customers visiting article pages, filtered by vehicle count
    SELECT
        rd.d_year,
        'DistinctCustomers' AS metric_name,
        COUNT(DISTINCT c.c_customer_sk) AS metric_value
    FROM recent_dates rd
    JOIN web_page wp
        ON wp.wp_creation_date_sk = rd.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_type = 'article'
      AND (hd.hd_vehicle_count > 2 OR hd.hd_vehicle_count IS NULL)
    GROUP BY rd.d_year
) u
WHERE u.d_year <= (SELECT max_yr FROM max_year)
GROUP BY u.d_year
ORDER BY u.d_year
