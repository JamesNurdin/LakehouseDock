WITH size_hour_stats AS (
    SELECT
        i.i_size,
        td.t_hour,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wp.wp_char_count) AS total_char_count
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_size, td.t_hour
)
SELECT
    i_size,
    t_hour,
    avg_return_amt,
    total_char_count,
    CASE
        WHEN avg_return_amt > 500 THEN 'LARGE_RETURN'
        WHEN avg_return_amt > 200 THEN 'MEDIUM_RETURN'
        ELSE 'SMALL_RETURN'
    END AS return_category,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY avg_return_amt DESC) AS size_rank_in_hour
FROM size_hour_stats
ORDER BY t_hour, size_rank_in_hour
LIMIT 20
