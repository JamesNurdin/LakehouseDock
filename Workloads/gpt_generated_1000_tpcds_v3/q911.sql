WITH catalog_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(cr.cr_net_loss) > (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND i.i_item_sk IN (
          SELECT p.p_item_sk
          FROM promotion p
          JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
          WHERE d2.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      )
    GROUP BY d.d_date, i.i_item_id
),
store_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        CASE
            WHEN SUM(sr.sr_net_loss) > (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS loss_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_date, i.i_item_id
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY return_date DESC, total_net_loss DESC
LIMIT 100
