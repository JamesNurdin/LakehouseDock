WITH aggregated AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_country,
        d_cc_closed.d_date AS cc_closed_date,
        d_cc_open.d_year AS cc_open_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_store_closed.d_year AS store_closed_year,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_closed_date,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created_on_closed_date,
        COUNT(DISTINCT CASE WHEN wp.wp_access_date_sk = d_cc_closed.d_date_sk THEN wp.wp_web_page_id END) AS web_pages_accessed_on_closed_date
    FROM call_center cc
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_inventory ON i.inv_date_sk = d_inventory.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
        AND wp.wp_access_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE cc.cc_country = 'United States'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_country,
        d_cc_closed.d_date,
        d_cc_open.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_store_closed.d_year
)
SELECT
    a.*,
    ROW_NUMBER() OVER (ORDER BY a.total_inventory_on_closed_date DESC) AS inventory_rank
FROM aggregated a
ORDER BY a.total_inventory_on_closed_date DESC
LIMIT 100
