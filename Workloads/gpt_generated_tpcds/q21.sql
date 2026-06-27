WITH all_returns AS (
    SELECT
        cr_returned_date_sk AS returned_date_sk,
        cr_reason_sk      AS reason_sk,
        cr_net_loss       AS net_loss
    FROM catalog_returns

    UNION ALL

    SELECT
        sr_returned_date_sk,
        sr_reason_sk,
        sr_net_loss
    FROM store_returns

    UNION ALL

    SELECT
        wr_returned_date_sk,
        wr_reason_sk,
        wr_net_loss
    FROM web_returns
),
monthly_reason AS (
    SELECT
        format_datetime(d.d_date, '%Y-%m') AS month,
        r.r_reason_desc,
        sum(ar.net_loss) AS total_net_loss,
        count(*) AS return_count
    FROM all_returns ar
    JOIN date_dim d
        ON ar.returned_date_sk = d.d_date_sk
    JOIN reason r
        ON ar.reason_sk = r.r_reason_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date <  DATE '2002-01-01'
    GROUP BY
        format_datetime(d.d_date, '%Y-%m'),
        r.r_reason_desc
)
SELECT
    month,
    r_reason_desc,
    total_net_loss,
    return_count,
    total_net_loss * 100.0 / sum(total_net_loss) OVER (PARTITION BY month) AS pct_of_month
FROM monthly_reason
ORDER BY
    month,
    total_net_loss DESC
LIMIT 20
