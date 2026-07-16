WITH store AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    r.r_reason_desc,
    cp.cp_type,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_quantity AS return_qty,
    sr.sr_return_amt AS return_amt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2020-01-01'
),
web AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    r.r_reason_desc,
    cp.cp_type,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_quantity AS return_qty,
    wr.wr_return_amt AS return_amt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2020-01-01'
),
combined AS (
  SELECT * FROM store
  UNION ALL
  SELECT * FROM web
),
aggregated AS (
  SELECT
    d_year,
    d_moy,
    i_category,
    r_reason_desc,
    cp_type,
    SUM(net_loss) AS total_net_loss,
    SUM(return_qty) AS total_return_qty,
    AVG(return_amt) AS avg_return_amt
  FROM combined
  GROUP BY d_year, d_moy, i_category, r_reason_desc, cp_type
  HAVING SUM(net_loss) > 0
)
SELECT
  a.*, 
  RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_loss DESC) AS category_rank_by_net_loss
FROM aggregated a
ORDER BY d_year, d_moy, total_net_loss DESC
LIMIT 200
