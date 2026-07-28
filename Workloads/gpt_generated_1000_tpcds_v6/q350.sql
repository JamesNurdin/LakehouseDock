WITH sales_agg AS (
  SELECT
    wp.wp_type AS wp_type,
    wp.wp_autogen_flag AS wp_autogen_flag,
    CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'HIGH' ELSE 'LOW' END AS price_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_qty,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(*) AS order_cnt
  FROM tpcds.web_sales ws
  JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
    AND wp.wp_autogen_flag = 'Y'
    AND ws.ws_ext_sales_price > 500
  GROUP BY ROLLUP (wp.wp_type, wp.wp_autogen_flag),
           CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'HIGH' ELSE 'LOW' END
)
SELECT
  wp_type,
  wp_autogen_flag,
  price_category,
  total_sales,
  total_qty,
  avg_sales_price,
  order_cnt,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
