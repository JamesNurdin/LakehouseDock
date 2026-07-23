WITH catalog_returns_agg AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id AS item_id,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_severity,
    'Catalog' AS return_type
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    AND i.i_current_price > 20
    AND w.w_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY d.d_date, i.i_item_id
),
web_returns_agg AS (
  SELECT
    d.d_date AS return_date,
    i.i_item_id AS item_id,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_severity,
    'Web' AS return_type
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
    AND i.i_current_price > 20
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY d.d_date, i.i_item_id
)
SELECT *
FROM catalog_returns_agg
UNION ALL
SELECT *
FROM web_returns_agg
ORDER BY return_date DESC, total_net_loss DESC
LIMIT 100
