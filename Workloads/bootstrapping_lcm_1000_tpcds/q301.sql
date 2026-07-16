SELECT
  d.d_year,
  i.i_category,
  s.s_state,
  w.wp_type,
  CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_amount_bucket,
  COUNT(*) AS num_returns,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_return_quantity) AS avg_return_quantity,
  SUM(cr.cr_fee) AS total_fee,
  COUNT(DISTINCT i.i_item_sk) AS distinct_items_returned,
  SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_amount_per_item
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page w
  ON w.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
GROUP BY
  d.d_year,
  i.i_category,
  s.s_state,
  w.wp_type,
  CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
