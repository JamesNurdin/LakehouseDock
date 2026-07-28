WITH catalog_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    'Catalog' AS source,
    cm.d_year,
    cm.month_seq,
    cm.total_return_amount,
    cm.total_net_loss,
    cm.loss_category
FROM catalog_monthly cm
UNION ALL
SELECT
    'Web' AS source,
    wm.d_year,
    wm.month_seq,
    wm.total_return_amount,
    wm.total_net_loss,
    wm.loss_category
FROM web_monthly wm
ORDER BY d_year, month_seq
LIMIT 100
