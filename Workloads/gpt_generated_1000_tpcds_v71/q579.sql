WITH store_ret AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           'Store' AS source,
           CASE WHEN sr.sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
           sr.sr_net_loss AS loss_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_ret AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           'Catalog' AS source,
           CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
           cr.cr_net_loss AS loss_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    year,
    category,
    source,
    loss_level,
    SUM(loss_amount) AS total_loss
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) AS combined
GROUP BY GROUPING SETS (
    (year, category, source, loss_level),
    (year, category, source),
    (year, source, loss_level),
    (year, source),
    (source, loss_level),
    (source),
    ()
)
ORDER BY
    year NULLS LAST,
    category,
    source,
    loss_level
LIMIT 100
