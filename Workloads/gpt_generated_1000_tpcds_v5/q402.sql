WITH filtered AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_state,
        s.s_floor_space,
        wp.wp_image_count,
        d.d_year,
        CASE WHEN s.s_floor_space > 50000 THEN 'Large' ELSE 'Small' END AS store_size_category
    FROM store AS s
    JOIN date_dim AS d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page AS wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE s.s_company_id = 1
        AND d.d_year = 2000
        AND wp.wp_image_count > 2
)
SELECT
    store_name,
    s_state,
    store_size_category,
    SUM(wp_image_count) AS total_image_count,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(wp_image_count) DESC) AS rn_state,
    RANK() OVER (ORDER BY SUM(wp_image_count) DESC) AS overall_rank
FROM filtered
GROUP BY store_name, s_state, store_size_category
ORDER BY total_image_count DESC, store_name
LIMIT 100
