WITH agg_returns AS (
    SELECT
        sr_customer_sk,
        sr_cdemo_sk,
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk, sr_cdemo_sk, sr_return_time_sk
),
wp_stats AS (
    SELECT
        wp_customer_sk,
        COUNT(*) AS page_cnt,
        AVG(wp_char_count) AS avg_char_cnt
    FROM web_page
    WHERE wp_autogen_flag = 'N'
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    cd.cd_marital_status,
    t.t_hour,
    ar.total_return_amt,
    ar.return_cnt,
    ws.page_cnt,
    ws.avg_char_cnt,
    (SELECT AVG(sr_return_amt) FROM store_returns) AS overall_avg_return,
    RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY ar.total_return_amt DESC) AS marital_rank
FROM agg_returns ar
JOIN customer c
    ON ar.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ar.sr_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t
    ON ar.sr_return_time_sk = t.t_time_sk
JOIN wp_stats ws
    ON c.c_customer_sk = ws.wp_customer_sk
WHERE cd.cd_marital_status = 'M'
  AND cd.cd_dep_count >= 2
  AND t.t_hour BETWEEN 9 AND 17
ORDER BY marital_rank, ar.total_return_amt DESC
