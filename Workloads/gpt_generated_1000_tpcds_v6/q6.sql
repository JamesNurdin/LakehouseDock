WITH store_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CAST('store' AS varchar) AS channel
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND sr.sr_refunded_cash > 100
    GROUP BY r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CAST('web' AS varchar) AS channel
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%time%'
      AND wr.wr_return_quantity >= 2
    GROUP BY r.r_reason_desc
)
SELECT reason_desc, total_net_loss, channel
FROM store_agg
UNION ALL
SELECT reason_desc, total_net_loss, channel
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
