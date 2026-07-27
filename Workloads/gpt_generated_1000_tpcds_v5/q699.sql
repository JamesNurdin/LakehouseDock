WITH catalog_data AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    cr.cr_return_amt_inc_tax AS return_amount,
    cr.cr_return_quantity AS quantity,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY cr.cr_return_amt_inc_tax DESC) AS rn,
    CASE
      WHEN cr.cr_return_amt_inc_tax > (
        SELECT AVG(cr2.cr_return_amt_inc_tax)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
      ) THEN 'Above Avg'
      ELSE 'Below Avg'
    END AS return_category,
    'Catalog' AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2022
    AND EXISTS (
      SELECT 1
      FROM ship_mode sm2
      WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
        AND sm2.sm_type = 'AIR'
    )
),
web_data AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    wr.wr_return_amt_inc_tax AS return_amount,
    wr.wr_return_quantity AS quantity,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY wr.wr_return_amt_inc_tax DESC) AS rn,
    CASE
      WHEN wr.wr_return_amt_inc_tax > (
        SELECT AVG(wr2.wr_return_amt_inc_tax)
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
      ) THEN 'Above Avg'
      ELSE 'Below Avg'
    END AS return_category,
    'Web' AS source
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2022
)
SELECT DISTINCT
  d_year,
  d_month_seq,
  i_item_id,
  source,
  return_category,
  return_amount,
  rn
FROM (
  SELECT * FROM catalog_data
  UNION ALL
  SELECT * FROM web_data
) combined
ORDER BY d_year DESC, d_month_seq, return_amount DESC
LIMIT 100
