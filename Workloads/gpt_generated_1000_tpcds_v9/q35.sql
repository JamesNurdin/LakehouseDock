WITH cr_filtered AS (
    SELECT
        cr.cr_return_amount,
        i.i_item_id,
        i.i_category,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 1915
      AND cr.cr_return_amount > (
          SELECT AVG(cr2.cr_return_amount)
          FROM catalog_returns cr2
      )
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim dp ON p.p_start_date_sk = dp.d_date_sk
          WHERE p.p_item_sk = i.i_item_sk
            AND dp.d_year = d.d_year
      )
),
wr_filtered AS (
    SELECT
        wr.wr_return_amt,
        i.i_item_id,
        i.i_category,
        d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 1915
      AND wr.wr_return_amt > (
          SELECT AVG(wr2.wr_return_amt)
          FROM web_returns wr2
      )
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim dp ON p.p_start_date_sk = dp.d_date_sk
          WHERE p.p_item_sk = i.i_item_sk
            AND dp.d_year = d.d_year
      )
)
SELECT
    'Catalog' AS return_source,
    i_item_id,
    i_category,
    d_year,
    SUM(cr_return_amount) AS total_return_amount
FROM cr_filtered
GROUP BY i_item_id, i_category, d_year
UNION ALL
SELECT
    'Web' AS return_source,
    i_item_id,
    i_category,
    d_year,
    SUM(wr_return_amt) AS total_return_amount
FROM wr_filtered
GROUP BY i_item_id, i_category, d_year
ORDER BY total_return_amount DESC
LIMIT 100
