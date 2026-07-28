WITH cat_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 100
    GROUP BY r.r_reason_desc
)
SELECT
    'Catalog' AS source,
    reason_desc,
    total_net_loss
FROM cat_agg
UNION ALL
SELECT
    'Web' AS source,
    reason_desc,
    total_net_loss
FROM web_agg
ORDER BY source, total_net_loss DESC
