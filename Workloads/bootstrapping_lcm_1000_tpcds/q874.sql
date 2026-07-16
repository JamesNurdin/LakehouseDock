WITH wp_stats AS (
    SELECT
        wp_creation_date_sk AS date_sk,
        COUNT(DISTINCT wp_web_page_id) AS page_cnt,
        SUM(wp_char_count) AS total_char_cnt,
        AVG(wp_image_count) AS avg_image_cnt
    FROM web_page
    GROUP BY wp_creation_date_sk
),
inv_stats AS (
    SELECT
        inv_date_sk AS date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_item_cnt
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state,
    s.s_store_name,
    s.s_state AS store_state,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_closed.d_date,
    inv_stats.total_qty,
    inv_stats.distinct_item_cnt,
    wp_stats.page_cnt,
    wp_stats.total_char_cnt,
    cc.cc_tax_percentage,
    s.s_tax_percentage,
    d_open.d_year AS open_year,
    date_diff('day', d_open.d_date, d_closed.d_date) AS days_opened,
    CASE WHEN d_closed.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    RANK() OVER (PARTITION BY d_closed.d_year ORDER BY inv_stats.total_qty DESC) AS inventory_rank
FROM
    call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN inv_stats
    ON inv_stats.date_sk = d_closed.d_date_sk
LEFT JOIN wp_stats
    ON wp_stats.date_sk = d_closed.d_date_sk
WHERE
    inv_stats.total_qty IS NOT NULL
ORDER BY
    inv_stats.total_qty DESC,
    wp_stats.page_cnt DESC
LIMIT 200
