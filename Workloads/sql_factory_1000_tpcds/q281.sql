WITH sales_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         wp.wp_url,
         SUM(ws.ws_ext_sales_price) AS total_ext_sales,
         SUM(ws.ws_ext_tax) AS total_tax
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_type = 'Article'
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk, wp.wp_url
),
returns_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         SUM(wr.wr_refunded_cash) AS total_refunded_cash
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                  AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk
)
SELECT s.d_year,
       s.d_week_seq,
       s.wp_url,
       s.total_ext_sales,
       s.total_tax,
       COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
       (s.total_ext_sales - s.total_tax) - COALESCE(r.total_refunded_cash, 0) AS net_revenue,
       PERCENT_RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_ext_sales DESC) AS revenue_percentile,
       FIRST_VALUE(s.wp_url) OVER (PARTITION BY s.d_year ORDER BY s.total_ext_sales DESC) AS top_page_url
FROM sales_week s
LEFT JOIN returns_week r
  ON s.d_year = r.d_year
 AND s.d_week_seq = r.d_week_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year DESC, revenue_percentile
