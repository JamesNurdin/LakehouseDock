WITH sales_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         wp.wp_url,
         SUM(ws.ws_ext_discount_amt) AS total_discount,
         COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
         SUM(ws.ws_ext_sales_price) AS total_sales_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_url LIKE 'https://%news%'
    AND wp.wp_type = 'article'
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk, wp.wp_url
),
returns_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         SUM(wr.wr_account_credit) AS total_account_credit,
         SUM(wr.wr_return_amt) AS total_return_amount
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                  AND wr.wr_item_sk = ws.ws_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk
)
SELECT s.d_year,
       s.d_week_seq,
       s.wp_url,
       s.total_discount,
       s.distinct_items_sold,
       s.total_sales_price,
       COALESCE(r.total_account_credit, 0) AS total_account_credit,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       (s.total_discount - COALESCE(r.total_account_credit, 0)) AS net_discount,
       PERCENT_RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales_price DESC) AS sales_price_percentile,
       FIRST_VALUE(s.distinct_items_sold) OVER (PARTITION BY s.wp_url ORDER BY s.d_week_seq) AS first_week_items
FROM sales_week s
LEFT JOIN returns_week r
  ON s.d_year = r.d_year
 AND s.d_week_seq = r.d_week_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year DESC, sales_price_percentile, s.wp_url
