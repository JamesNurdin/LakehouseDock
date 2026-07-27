WITH joined AS (
  SELECT
    wp.wp_type,
    wp.wp_char_count,
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_ext_wholesale_cost,
    wr.wr_return_amt
  FROM tpcds.web_page wp
  JOIN tpcds.web_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_access_date_sk = 2452565
    AND wp.wp_char_count > 2000
    AND ws.ws_net_paid_inc_ship_tax > 1500.00
),
aggregated AS (
  SELECT
    wp_type,
    wp_char_count,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    SUM(ws_net_paid_inc_ship_tax) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    AVG(ws_ext_wholesale_cost) AS avg_wholesale_cost
  FROM joined
  GROUP BY wp_type, wp_char_count
)
SELECT
  wp_type,
  wp_char_count,
  num_orders,
  total_sales,
  total_returns,
  avg_wholesale_cost,
  SUM(total_sales) OVER (
    PARTITION BY wp_type
    ORDER BY total_sales DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales_by_type
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
