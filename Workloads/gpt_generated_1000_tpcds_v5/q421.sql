WITH agg_returns AS (
    SELECT
        wr_web_page_sk,
        wr_returned_time_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt) AS avg_return_amt
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_return_quantity >= 1
      AND wr_returned_date_sk BETWEEN 2451500 AND 2452000
      AND wr_reason_sk IS NOT NULL
    GROUP BY wr_web_page_sk, wr_returned_time_sk
)
SELECT DISTINCT
    wp.wp_web_page_id,
    td.t_hour,
    td.t_minute,
    ar.total_return_amt,
    ar.return_cnt,
    CASE
        WHEN ar.total_return_amt > 1000 THEN 'HIGH'
        WHEN ar.total_return_amt > 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    RANK() OVER (PARTITION BY td.t_hour ORDER BY ar.total_return_amt DESC) AS hour_rank
FROM agg_returns ar
JOIN time_dim td
    ON ar.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp
    ON ar.wr_web_page_sk = wp.wp_web_page_sk
WHERE td.t_hour BETWEEN 8 AND 12
  AND td.t_minute IN (5, 8, 15, 16)
  AND wp.wp_type = 'article'
  AND wp.wp_url LIKE '%example%'
ORDER BY hour_rank, td.t_hour
LIMIT 100
