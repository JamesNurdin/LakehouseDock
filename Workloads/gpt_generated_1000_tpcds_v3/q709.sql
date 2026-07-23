WITH
    store_ret AS (
        SELECT
            r.r_reason_desc AS reason_desc,
            d.d_date AS return_date,
            SUM(sr.sr_net_loss) AS total_net_loss
        FROM store_returns sr
        JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        GROUP BY r.r_reason_desc, d.d_date
    ),
    catalog_ret AS (
        SELECT
            r.r_reason_desc AS reason_desc,
            d.d_date AS return_date,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        GROUP BY r.r_reason_desc, d.d_date
    ),
    all_returns AS (
        SELECT reason_desc, return_date, total_net_loss FROM store_ret
        UNION ALL
        SELECT reason_desc, return_date, total_net_loss FROM catalog_ret
    )
SELECT
    reason_desc,
    return_date,
    total_net_loss,
    SUM(total_net_loss) OVER (
        PARTITION BY reason_desc
        ORDER BY return_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM all_returns
ORDER BY return_date, reason_desc
