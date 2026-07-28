WITH sales_by_site AS (
  SELECT
    web.web_site_sk,
    web.web_site_id,
    web.web_state,
    td.t_hour,
    SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_total,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_total,
    SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS combined_sales,
    COUNT(*) AS transaction_count
  FROM store_sales ss
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
  WHERE
    td.t_hour BETWEEN 9 AND 17
    AND td.t_shift = 'Afternoon'
    AND web.web_street_type IN ('Rd', 'St')
    AND web.web_gmt_offset > -5.0
    AND ss.ss_quantity > 1
    AND ws.ws_coupon_amt < 500
    AND web.web_rec_end_date >= DATE '2000-01-01'
  GROUP BY
    web.web_site_sk,
    web.web_site_id,
    web.web_state,
    td.t_hour
)
SELECT
  web_state,
  AVG(combined_sales) AS avg_combined_sales,
  SUM(transaction_count) AS total_transactions
FROM sales_by_site
GROUP BY web_state
HAVING AVG(combined_sales) > 10000
ORDER BY avg_combined_sales DESC
