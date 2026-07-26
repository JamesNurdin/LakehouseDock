WITH sales_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         wp.wp_url,
         SUM(ws.ws_net_paid_inc_tax) AS total_sales,
         SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk, wp.wp_url
),
returns_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                  AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk
)
SELECT 
  s.d_year,
  s.d_week_seq,
  s.wp_url,
  s.total_sales,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_weekly_profit,
  CASE 
    WHEN s.total_profit - COALESCE(r.total_return_loss, 0) > 0 THEN 'Profit'
    ELSE 'Loss'
  END AS profit_indicator,
  LAG(s.total_sales) OVER (PARTITION BY s.wp_url ORDER BY s.d_year, s.d_week_seq) AS prev_week_sales,
  CASE 
    WHEN LAG(s.total_sales) OVER (PARTITION BY s.wp_url ORDER BY s.d_year, s.d_week_seq) IS NULL THEN NULL
    ELSE (s.total_sales - LAG(s.total_sales) OVER (PARTITION BY s.wp_url ORDER BY s.d_year, s.d_week_seq)) * 100.0 / LAG(s.total_sales) OVER (PARTITION BY s.wp_url ORDER BY s.d_year, s.d_week_seq)
  END AS sales_change_pct,
  RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_week s
LEFT JOIN returns_week r
  ON s.d_year = r.d_year
 AND s.d_week_seq = r.d_week_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year DESC, s.d_week_seq DESC, sales_rank
