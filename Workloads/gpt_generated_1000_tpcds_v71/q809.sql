WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(cr.cr_net_loss) AS total_net_loss,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND i.i_current_price > 100
    GROUP BY d.d_year, r.r_reason_desc
),
store_agg AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'Store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND i.i_current_price > 100
    GROUP BY d.d_year, r.r_reason_desc
)
SELECT year, reason, total_net_loss, source
FROM catalog_agg
UNION ALL
SELECT year, reason, total_net_loss, source
FROM store_agg
ORDER BY year, total_net_loss DESC
LIMIT 100
