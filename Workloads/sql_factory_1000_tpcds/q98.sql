WITH sales_daily AS (
  SELECT d_sales.d_date AS activity_date,
         wp.wp_url,
         SUM(ws.ws_net_profit) AS total_sales_profit
  FROM web_sales ws
  JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  GROUP BY d_sales.d_date, wp.wp_url
),
returns_daily AS (
  SELECT d_ret.d_date AS activity_date,
         wp.wp_url,
         SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  GROUP BY d_ret.d_date, wp.wp_url
),
combined_daily AS (
  SELECT COALESCE(s.activity_date, r.activity_date) AS activity_date,
         COALESCE(s.wp_url, r.wp_url) AS wp_url,
         COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
         COALESCE(r.total_return_loss, 0) AS total_return_loss,
         COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
         CASE 
           WHEN COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) > 1000 THEN 'High'
           WHEN COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) > 0 THEN 'Medium'
           ELSE 'Low'
         END AS profit_level
  FROM sales_daily s
  FULL OUTER JOIN returns_daily r
    ON s.activity_date = r.activity_date
   AND s.wp_url = r.wp_url
)
SELECT activity_date,
       wp_url,
       total_sales_profit,
       total_return_loss,
       net_profit,
       profit_level,
       RANK() OVER (PARTITION BY activity_date ORDER BY net_profit DESC) AS profit_rank,
       DENSE_RANK() OVER (PARTITION BY activity_date ORDER BY profit_level) AS profit_level_rank
FROM combined_daily
ORDER BY activity_date DESC, profit_rank
