WITH catalog_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cr.cr_net_loss) AS total_net_loss,
    'Catalog' AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
    AND i.i_category_id IN (1, 3)
  GROUP BY d.d_year, i.i_category
),
store_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(sr.sr_net_loss) AS total_net_loss,
    'Store' AS source
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
    AND i.i_category_id IN (1, 3)
  GROUP BY d.d_year, i.i_category
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
LIMIT 100
