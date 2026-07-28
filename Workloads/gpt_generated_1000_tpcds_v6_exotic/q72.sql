WITH store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'store' AS channel
    FROM store_returns AS sr
    JOIN date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason AS r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND sr.sr_net_loss > 0
    GROUP BY r.r_reason_desc
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        'web' AS channel
    FROM web_returns AS wr
    JOIN date_dim AS d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason AS r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND wr.wr_net_loss > 0
    GROUP BY r.r_reason_desc
)
SELECT DISTINCT
    channel,
    reason_desc,
    total_net_loss
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
