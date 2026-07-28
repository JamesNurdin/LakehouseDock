WITH catalog_agg AS (
    SELECT
        'Catalog' AS return_type,
        d.d_year AS year,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(cr.cr_net_loss) > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) THEN 'Y'
            ELSE 'N'
        END AS high_loss_flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
          WHERE sr.sr_item_sk = cr.cr_item_sk
            AND d2.d_year = d.d_year
      )
    GROUP BY d.d_year, i.i_category
),
store_agg AS (
    SELECT
        'Store' AS return_type,
        d.d_year AS year,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) THEN 'Y'
            ELSE 'N'
        END AS high_loss_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
    GROUP BY d.d_year, i.i_category
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY return_type, year, category
