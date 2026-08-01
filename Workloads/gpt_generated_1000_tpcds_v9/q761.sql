WITH catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        'Catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_date
),
store_ret AS (
    SELECT
        d.d_date AS return_date,
        'Store' AS channel,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_date
),
web_ret AS (
    SELECT
        d.d_date AS return_date,
        'Web' AS channel,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_date
)
SELECT * FROM catalog_ret
UNION ALL
SELECT * FROM store_ret
UNION ALL
SELECT * FROM web_ret
ORDER BY return_date ASC, total_net_loss DESC
LIMIT 100
