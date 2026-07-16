WITH page_returns AS (
  SELECT
    wp.wp_type AS page_type,
    date_format(date_add('day', wr.wr_returned_date_sk, date '1970-01-01'), '%Y-%m') AS return_month,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2451000 AND 2452000
    AND wp.wp_type IS NOT NULL
  GROUP BY wp.wp_type, date_format(date_add('day', wr.wr_returned_date_sk, date '1970-01-01'), '%Y-%m')
)
SELECT
  page_type,
  return_month,
  total_return_inc_tax,
  total_net_loss,
  avg_return_qty,
  return_cnt,
  RANK() OVER (PARTITION BY page_type ORDER BY total_net_loss DESC) AS net_loss_rank
FROM page_returns
WHERE total_return_inc_tax > 1000
ORDER BY page_type, net_loss_rank
LIMIT 50
