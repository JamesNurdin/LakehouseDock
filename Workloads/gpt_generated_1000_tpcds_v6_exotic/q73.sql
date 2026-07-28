WITH joined AS (
  SELECT
    wp.wp_url,
    r.r_reason_desc,
    wr.wr_return_amt,
    ws.ws_net_profit,
    wr.wr_return_tax
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wp.wp_autogen_flag = 'N'
    AND wp.wp_rec_start_date >= DATE '1999-01-01'
    AND wp.wp_rec_end_date <= DATE '2001-12-31'
    AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    AND wr.wr_refunded_cash > 400
),
aggregated AS (
  SELECT
    wp_url,
    r_reason_desc,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt
  FROM joined
  GROUP BY ROLLUP (wp_url, r_reason_desc)
)
SELECT
  wp_url,
  r_reason_desc,
  total_return_amt,
  total_net_profit,
  avg_return_tax,
  return_cnt,
  CASE WHEN total_return_amt > 500 THEN 'High' ELSE 'Low' END AS return_category,
  ROW_NUMBER() OVER (PARTITION BY wp_url ORDER BY total_return_amt DESC) AS url_rank
FROM aggregated
ORDER BY wp_url, url_rank
LIMIT 100
