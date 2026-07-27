WITH agg AS (
  SELECT
    wp.wp_type,
    dr_return.d_month_seq,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_ship_cost) AS avg_ship_cost,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN date_dim dr_return ON wr.wr_returned_date_sk = dr_return.d_date_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim dr_creation ON wp.wp_creation_date_sk = dr_creation.d_date_sk
  WHERE dr_return.d_year = 2001
    AND dr_return.d_month_seq BETWEEN 1200 AND 1220
    AND wp.wp_type IN ('A', 'B', 'C')
    AND wp.wp_image_count >= 2
    AND wp.wp_char_count BETWEEN 1000 AND 6000
    AND wr.wr_return_amt > 100
    AND wr.wr_return_ship_cost < 500
    AND dr_creation.d_day_name = 'Monday'
  GROUP BY ROLLUP (wp.wp_type, dr_return.d_month_seq)
)
SELECT
  wp_type,
  d_month_seq,
  total_return_amt,
  avg_ship_cost,
  return_cnt,
  RANK() OVER (PARTITION BY wp_type ORDER BY total_return_amt DESC) AS month_rank_by_return
FROM agg
ORDER BY wp_type, d_month_seq
