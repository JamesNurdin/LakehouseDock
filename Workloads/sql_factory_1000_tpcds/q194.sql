WITH page_brand_shift_qty AS (
    SELECT
        wp.wp_type,
        i.i_brand AS brand,
        td.t_shift,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY wp.wp_type, i.i_brand, td.t_shift
)
SELECT
    wp_type,
    brand,
    t_shift,
    total_return_qty,
    PERCENT_RANK() OVER (PARTITION BY t_shift ORDER BY total_return_qty) AS pct_rank_in_shift,
    CUME_DIST() OVER (PARTITION BY t_shift ORDER BY total_return_qty DESC) AS cum_dist_desc_in_shift,
    CASE WHEN total_return_qty > 2000 THEN 'HIGH' ELSE 'LOW' END AS activity_level
FROM page_brand_shift_qty
ORDER BY t_shift, total_return_qty DESC
LIMIT 30
