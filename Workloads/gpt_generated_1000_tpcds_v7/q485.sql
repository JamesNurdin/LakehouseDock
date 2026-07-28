/*
Goal: Compare yearly return amounts, net loss, and average return tax between store returns and catalog returns for fiscal weeks greater than 10 in the year 2001.
*/
WITH store_ret AS (
    SELECT
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        'store' AS source
    FROM store_returns sr
    INNER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_fy_week_seq > 10
    GROUP BY d.d_year
),
catalog_ret AS (
    SELECT
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        'catalog' AS source
    FROM catalog_returns cr
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_fy_week_seq > 10
    GROUP BY d.d_year
)
SELECT
    year,
    total_return_amount,
    total_net_loss,
    avg_return_tax,
    source
FROM store_ret
UNION ALL
SELECT
    year,
    total_return_amount,
    total_net_loss,
    avg_return_tax,
    source
FROM catalog_ret
ORDER BY year, source
