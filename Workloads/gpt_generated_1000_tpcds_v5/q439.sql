WITH store_agg AS (
  SELECT
    'store' AS return_source,
    d.d_year,
    d.d_month_seq AS month_seq,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_dep_college_count >= 2
    AND d.d_year = 2002
  GROUP BY d.d_year, d.d_month_seq
),
catalog_agg AS (
  SELECT
    'catalog' AS return_source,
    d.d_year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_dep_employed_count >= 1
    AND d.d_year = 2002
  GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM catalog_agg
ORDER BY d_year, month_seq, return_source
LIMIT 100
