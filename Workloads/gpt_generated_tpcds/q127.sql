WITH catalog AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_net_loss AS net_loss,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        'Catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
store AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_reason_sk AS reason_sk,
        sr.sr_net_loss AS net_loss,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        'Store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
web AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_reason_sk AS reason_sk,
        wr.wr_net_loss AS net_loss,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        'Web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT date_sk, reason_sk, net_loss, year, month_seq, reason_desc, channel FROM catalog
    UNION ALL
    SELECT date_sk, reason_sk, net_loss, year, month_seq, reason_desc, channel FROM store
    UNION ALL
    SELECT date_sk, reason_sk, net_loss, year, month_seq, reason_desc, channel FROM web
),
aggregated AS (
    SELECT
        reason_desc,
        month_seq,
        channel,
        sum(net_loss) AS total_net_loss,
        count(*) AS return_cnt
    FROM combined
    GROUP BY reason_desc, month_seq, channel
)
SELECT
    reason_desc,
    month_seq,
    channel,
    total_net_loss,
    return_cnt,
    row_number() OVER (PARTITION BY month_seq ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY month_seq, loss_rank
LIMIT 100
