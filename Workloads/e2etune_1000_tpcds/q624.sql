WITH agg AS (
  SELECT
    dr.d_fy_year AS fy_year,
    dr.d_fy_quarter_seq AS fy_quarter,
    wp.wp_type AS page_type,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_fee) AS total_fee
  FROM web_returns wr
  JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE dr.d_fy_year BETWEEN 1902 AND 1904
    AND dr.d_fy_quarter_seq IN (2, 3)
    AND wp.wp_type <> ''
  GROUP BY dr.d_fy_year, dr.d_fy_quarter_seq, wp.wp_type
  HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
  fy_year,
  fy_quarter,
  page_type,
  return_cnt,
  total_return_amt,
  total_net_loss,
  avg_return_qty,
  total_fee,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
