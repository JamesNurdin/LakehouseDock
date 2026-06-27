SELECT
    sales_date.d_year AS year,
    sales_date.d_moy AS month,
    wp.wp_type AS web_page_type,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(wr.wr_net_loss) AS total_returns_loss,
    SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns
FROM web_sales ws
JOIN date_dim sales_date
  ON ws.ws_sold_date_sk = sales_date.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
  ON ws.ws_item_sk = wr.wr_item_sk
  AND ws.ws_order_number = wr.wr_order_number
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim returns_date
  ON wr.wr_returned_date_sk = returns_date.d_date_sk
WHERE sales_date.d_year = 2001
GROUP BY sales_date.d_year, sales_date.d_moy, wp.wp_type
ORDER BY sales_date.d_year, sales_date.d_moy, wp.wp_type
