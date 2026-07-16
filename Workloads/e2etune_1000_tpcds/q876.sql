WITH agg AS (
  SELECT
    d.d_year AS d_year,
    d.d_quarter_seq AS d_quarter_seq,
    cc.cc_state AS cc_state,
    i.i_category AS i_category,
    s.s_city AS s_city,
    cp.cp_department AS cp_department,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_year >= 2002
    AND t.t_shift = 'Evening'
    AND cc.cc_state IN ('TN', 'LA', 'GA')
    AND i.i_category IS NOT NULL
    AND s.s_city IS NOT NULL
  GROUP BY d.d_year, d.d_quarter_seq, cc.cc_state, i.i_category, s.s_city, cp.cp_department
)
SELECT
  d_year,
  d_quarter_seq,
  cc_state,
  i_category,
  s_city,
  cp_department,
  total_return_amount,
  total_net_loss,
  avg_return_quantity,
  return_count,
  RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_return_amount DESC) AS category_rank
FROM agg
WHERE return_count >= 10
ORDER BY d_year DESC, d_quarter_seq, category_rank
LIMIT 100
