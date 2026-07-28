WITH catalog_return_loss AS (
    SELECT
        d.d_date AS return_date,
        SUM(cr.cr_net_loss) AS loss_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%fault%'
    GROUP BY d.d_date
),
web_return_loss AS (
    SELECT
        d.d_date AS return_date,
        SUM(wr.wr_net_loss) AS loss_amount,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%fault%'
    GROUP BY d.d_date
)
SELECT
    return_date,
    source,
    loss_amount,
    SUM(loss_amount) OVER (
        PARTITION BY source
        ORDER BY return_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_loss
FROM (
    SELECT return_date, source, loss_amount FROM catalog_return_loss
    UNION ALL
    SELECT return_date, source, loss_amount FROM web_return_loss
) AS combined
ORDER BY return_date DESC, source
LIMIT 100
