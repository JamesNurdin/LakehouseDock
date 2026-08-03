WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_web_page_sk,
    wr.wr_return_amt,
    wr.wr_return_quantity
  FROM web_sales ws
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
),
aggregated AS (
  SELECT
    d.d_year,
    wp.wp_type,
    wp.wp_url,
    wp.wp_web_page_sk,
    COUNT(DISTINCT sr.ws_order_number) AS orders_cnt,
    SUM(sr.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.wr_return_amt, 0)) AS total_return_amt,
    AVG(sr.ws_net_profit) AS avg_profit,
    CASE WHEN SUM(sr.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_indicator,
    (SELECT SUM(wr2.wr_return_amt)
       FROM web_returns wr2
       WHERE wr2.wr_web_page_sk = wp.wp_web_page_sk) AS page_total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY SUM(sr.ws_ext_sales_price) DESC) AS rn
  FROM sales_returns sr
  LEFT JOIN date_dim d
    ON sr.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_page wp
    ON sr.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2001
    AND wp.wp_type = 'article'
    AND sr.ws_quantity > 2
  GROUP BY
    d.d_year,
    wp.wp_type,
    wp.wp_url,
    wp.wp_web_page_sk
)
SELECT
  d_year,
  wp_type,
  wp_url,
  orders_cnt,
  total_sales,
  total_return_amt,
  avg_profit,
  profit_indicator,
  page_total_return_amt
FROM aggregated
WHERE rn <= 3
ORDER BY d_year DESC, wp_type, total_sales DESC
LIMIT 10
