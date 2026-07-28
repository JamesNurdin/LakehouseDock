WITH year_dim AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year IN (2000, 2001, 2002)
)
SELECT * FROM (
    SELECT
        'catalog' AS source,
        y.d_year,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS txn_count,
        -- flag rows that are subtotals (used for ordering later)
        CASE WHEN y.d_year IS NULL THEN 'Year Total'
             WHEN cd.cd_gender IS NULL THEN 'Gender Total'
             ELSE 'Detail' END AS row_type
    FROM catalog_returns cr
    JOIN year_dim y ON cr.cr_returned_date_sk = y.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 0
    GROUP BY ROLLUP (y.d_year, cd.cd_gender)

    UNION ALL

    SELECT
        'web' AS source,
        y.d_year,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_amount,
        COUNT(*) AS txn_count,
        CASE WHEN y.d_year IS NULL THEN 'Year Total'
             WHEN cd.cd_gender IS NULL THEN 'Gender Total'
             ELSE 'Detail' END AS row_type
    FROM web_sales ws
    JOIN year_dim y ON ws.ws_sold_date_sk = y.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_net_paid > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_customer_sk = ws.ws_bill_customer_sk
            AND ss.ss_sold_date_sk = y.d_date_sk
      )
    GROUP BY ROLLUP (y.d_year, cd.cd_gender)
) combined
ORDER BY
    source,
    CASE WHEN combined.d_year IS NULL THEN 9999 ELSE combined.d_year END,
    CASE WHEN combined.cd_gender IS NULL THEN 'ZZ' ELSE combined.cd_gender END,
    row_type
LIMIT 100
