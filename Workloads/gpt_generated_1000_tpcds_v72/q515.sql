WITH returns_by_channel AS (
    SELECT
        CAST('Store' AS varchar) AS channel,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%size%'
    GROUP BY r.r_reason_desc

    UNION ALL

    SELECT
        CAST('Web' AS varchar) AS channel,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%size%'
    GROUP BY r.r_reason_desc
)
SELECT
    channel,
    reason_desc,
    net_loss
FROM returns_by_channel
ORDER BY net_loss DESC
LIMIT 100
