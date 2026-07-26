WITH sales_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         wp.wp_url,
         SUM(ws.ws_net_paid_inc_tax) AS total_sales,
         SUM(ws.ws_net_profit) AS total_profit,
         COUNT(*) AS txn_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
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
  WHERE wr.wr_return_quantity > 0
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk
)
SELECT s.d_year,
       s.d_week_seq,
       s.wp_url,
       s.total_sales,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       s.total_profit - COALESCE(r.total_return_loss, 0) AS net_weekly_profit,
       CASE WHEN s.txn_count >= 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
       ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rownum,
       AVG(s.total_sales) OVER (PARTITION BY s.wp_url) AS avg_sales_per_page
FROM sales_week s
LEFT JOIN returns_week r
  ON s.d_year = r.d_year
 AND s.d_week_seq = r.d_week_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year ASC, s.d_week_seq ASC, sales_rownum
