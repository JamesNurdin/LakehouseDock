WITH sales_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         wp.wp_url,
         SUM(ws.ws_ext_discount_amt) AS total_discount,
         COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
         MAX(ws.ws_ext_sales_price) AS max_sale_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_url LIKE 'https://%news%'
    AND d.d_month_seq BETWEEN 250 AND 260  -- specific month range
  GROUP BY d.d_year, d.d_week_seq, ws.ws_web_page_sk, wp.wp_url
),
returns_week AS (
  SELECT d.d_year,
         d.d_week_seq,
         ws.ws_web_page_sk,
         SUM(wr.wr_account_credit) AS total_account_credit,
         COUNT(DISTINCT wr.wr_reason_sk) AS distinct_return_reasons
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
       s.max_sale_price,
       COALESCE(r.total_account_credit, 0) AS total_account_credit,
       (s.total_discount - COALESCE(r.total_account_credit, 0)) AS net_discount,
       CUME_DIST() OVER (PARTITION BY s.d_year ORDER BY s.max_sale_price DESC) AS cum_dist_max_price,
       AVG(r.distinct_return_reasons) OVER (PARTITION BY s.wp_url) AS avg_return_reasons_per_page
FROM sales_week s
LEFT JOIN returns_week r
  ON s.d_year = r.d_year
 AND s.d_week_seq = r.d_week_seq
 AND s.ws_web_page_sk = r.ws_web_page_sk
ORDER BY s.d_year ASC, cum_dist_max_price DESC, s.wp_url
