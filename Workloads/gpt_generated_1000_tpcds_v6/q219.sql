WITH date_filtered AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
),
store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'Store' AS source,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_filtered df ON sr.sr_returned_date_sk = df.d_date_sk
    GROUP BY r.r_reason_desc
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'Web' AS source,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_filtered df ON wr.wr_returned_date_sk = df.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
)
SELECT
    c.reason_desc,
    c.source,
    c.total_net_loss,
    c.return_cnt,
    CASE
        WHEN c.total_net_loss > (SELECT AVG(total_net_loss) FROM combined) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM combined c
ORDER BY c.total_net_loss DESC
LIMIT 100
