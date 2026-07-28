WITH store_returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(sr.sr_net_loss) > 0
),
catalog_returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2002
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, d.d_month_seq
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    year,
    month,
    total_net_loss,
    return_count,
    'store' AS source
FROM store_returns_monthly

UNION ALL

SELECT
    year,
    month,
    total_net_loss,
    return_count,
    'catalog' AS source
FROM catalog_returns_monthly
ORDER BY year, month, source
LIMIT 100
