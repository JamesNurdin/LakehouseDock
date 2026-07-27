WITH agg_n AS (
    SELECT
        s.s_state AS state,
        ws.web_mkt_desc AS market_desc,
        d.d_month_seq AS month_seq,
        SUM(wp.wp_image_count) AS total_images,
        COUNT(*) AS row_cnt
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND s.s_state = 'CA'
      AND s.s_gmt_offset >= 0
      AND wp.wp_image_count >= 3
      AND wp.wp_autogen_flag = 'N'
      AND ws.web_mkt_desc LIKE '%Electric%'
    GROUP BY GROUPING SETS (
        (s.s_state, ws.web_mkt_desc, d.d_month_seq),
        (s.s_state, ws.web_mkt_desc),
        (s.s_state),
        ()
    )
),
agg_y AS (
    SELECT
        s.s_state AS state,
        ws.web_mkt_desc AS market_desc,
        d.d_month_seq AS month_seq,
        SUM(wp.wp_image_count) AS total_images,
        COUNT(*) AS row_cnt
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND s.s_state = 'CA'
      AND s.s_gmt_offset >= 0
      AND wp.wp_image_count >= 3
      AND wp.wp_autogen_flag = 'Y'
      AND ws.web_mkt_desc LIKE '%Home%'
    GROUP BY GROUPING SETS (
        (s.s_state, ws.web_mkt_desc, d.d_month_seq),
        (s.s_state, ws.web_mkt_desc),
        (s.s_state),
        ()
    )
)
SELECT
    u.state,
    u.market_desc,
    u.month_seq,
    SUM(u.total_images) AS total_images,
    SUM(u.row_cnt) AS total_rows,
    AVG(u.total_images) AS avg_images_per_group
FROM (
    SELECT * FROM agg_n
    UNION ALL
    SELECT * FROM agg_y
) u
GROUP BY GROUPING SETS (
    (u.state, u.market_desc, u.month_seq),
    (u.state, u.market_desc),
    (u.state),
    ()
)
ORDER BY u.state, u.market_desc, u.month_seq
