WITH page_stats AS (
    SELECT
        td.t_hour,
        td.t_shift,
        td.t_sub_shift,
        COUNT(*) AS page_cnt,
        SUM(wp.wp_char_count) AS total_chars,
        AVG(wp.wp_char_count) AS avg_chars,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_image_count) AS avg_images,
        SUM(wp.wp_link_count) AS total_links,
        SUM(wp.wp_max_ad_count * wp.wp_image_count) AS total_ad_capacity
    FROM
        web_page wp
    JOIN
        time_dim td
        ON wp.wp_creation_date_sk = td.t_time_sk
    WHERE
        td.t_shift = 'first'
        AND td.t_sub_shift = 'morning'
        AND td.t_hour BETWEEN 8 AND 12
        AND wp.wp_type = 'article'
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_rec_start_date >= DATE '2021-01-01'
        AND wp.wp_rec_end_date < DATE '2023-01-01'
    GROUP BY
        td.t_hour,
        td.t_shift,
        td.t_sub_shift
    HAVING
        COUNT(*) > 10
)
SELECT
    ps.t_hour,
    ps.t_shift,
    ps.t_sub_shift,
    ps.page_cnt,
    ps.total_chars,
    ps.avg_chars,
    ps.total_images,
    ps.avg_images,
    ps.total_links,
    ps.total_ad_capacity,
    RANK() OVER (PARTITION BY ps.t_shift ORDER BY ps.total_chars DESC) AS hour_rank_by_chars
FROM
    page_stats ps
ORDER BY
    ps.total_chars DESC
LIMIT 100
