WITH agg AS (
    SELECT
        ca.ca_state,
        wp.wp_type,
        AVG(wp.wp_link_count) AS avg_links,
        SUM(hd.hd_vehicle_count) AS total_vehicles,
        COUNT(DISTINCT wp.wp_web_page_id) AS unique_pages,
        approx_percentile(wp.wp_char_count, 0.5) AS median_char_count,
        COUNT(*) AS cnt
    FROM
        customer_address ca
    JOIN
        household_demographics hd
        ON (ca.ca_address_sk % 10) = (hd.hd_demo_sk % 10)
    JOIN
        web_page wp
        ON (hd.hd_demo_sk % 10) = (wp.wp_customer_sk % 10)
    WHERE
        ca.ca_country = 'United States'
        AND wp.wp_rec_end_date >= DATE '2023-01-01'
    GROUP BY
        ca.ca_state,
        wp.wp_type
    HAVING
        COUNT(*) > 10
)
SELECT
    ca_state,
    wp_type,
    avg_links,
    total_vehicles,
    unique_pages,
    median_char_count,
    RANK() OVER (PARTITION BY wp_type ORDER BY avg_links DESC) AS state_rank_by_links
FROM agg
ORDER BY wp_type, state_rank_by_links
