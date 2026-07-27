WITH base AS (
    SELECT
        ws.web_site_id,
        ws.web_city,
        wp.wp_url,
        c.c_customer_id,
        hd.hd_vehicle_count,
        d_access.d_year,
        d_access.d_month_seq,
        wp.wp_char_count,
        CASE
            WHEN hd.hd_vehicle_count >= 2 THEN 'Multiple Vehicles'
            ELSE 'Few Vehicles'
        END AS vehicle_category
    FROM web_page wp
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_access.d_date_sk
    WHERE
        d_access.d_year = 2002
        AND d_access.d_month_seq BETWEEN 1200 AND 1220
        AND hd.hd_vehicle_count > 0
        AND hd.hd_income_band_sk IN (3, 12, 17)
        AND ws.web_manager = 'Adam Stonge'
),
agg_city AS (
    SELECT
        web_city,
        vehicle_category,
        COUNT(*) AS page_views,
        SUM(wp_char_count) AS total_chars,
        AVG(wp_char_count) AS avg_chars
    FROM base
    GROUP BY web_city, vehicle_category
    HAVING COUNT(*) >= 10
)
SELECT
    ac.web_city,
    ac.vehicle_category,
    ac.page_views,
    ac.total_chars,
    ac.avg_chars,
    (SELECT AVG(total_chars) FROM agg_city) AS avg_total_chars_all_cities
FROM agg_city ac
WHERE EXISTS (
    SELECT 1
    FROM web_site ws2
    WHERE ws2.web_city = ac.web_city
      AND ws2.web_tax_percentage > 0.05
)
ORDER BY ac.total_chars DESC
LIMIT 100
