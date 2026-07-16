WITH agg AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_char_count) AS avg_char_count,
        COUNT(DISTINCT r.r_reason_id) AS distinct_reasons,
        MAX(t.t_hour) AS max_hour,
        MIN(t.t_hour) AS min_hour
    FROM web_page wp
    JOIN time_dim t
        ON wp.wp_creation_date_sk = t.t_time_sk
    LEFT JOIN reason r
        ON wp.wp_type = r.r_reason_desc
    JOIN customer_address ca
        ON ca.ca_gmt_offset = CAST(t.t_hour AS decimal(5,2)) - 12.00
    WHERE ca.ca_country = 'United States'
        AND ca.ca_state IN ('Maricopa County', 'York County')
        AND t.t_meal_time = 'Lunch'
        AND t.t_shift = 'morning'
        AND wp.wp_link_count > 0
    GROUP BY ca.ca_state, ca.ca_city
    HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 5
)
SELECT
    *,
    RANK() OVER (ORDER BY total_links DESC) AS state_city_rank
FROM agg
ORDER BY total_links DESC, page_cnt DESC
LIMIT 100
