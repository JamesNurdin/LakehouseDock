WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_list_price BETWEEN 40 AND 100
      AND ws.ws_quantity >= 1
      AND ws.ws_net_profit > 0
      AND ws.ws_ship_mode_sk IN (1, 2, 3, 4)
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws.ws_ext_sales_price < 5000
)
SELECT
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_type,
    wp.wp_link_count,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_net_profit) AS avg_profit,
    CASE
        WHEN SUM(fs.ws_ext_sales_price) > 20000 THEN 'High'
        WHEN SUM(fs.ws_ext_sales_price) BETWEEN 10000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    RANK() OVER (ORDER BY SUM(fs.ws_ext_sales_price) DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY AVG(fs.ws_net_profit) DESC) AS row_in_type
FROM filtered_sales fs
JOIN tpcds.web_page wp
    ON fs.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
  AND wp.wp_rec_end_date <= DATE '2002-12-31'
  AND wp.wp_link_count >= 10
  AND wp.wp_customer_sk NOT IN (
        SELECT DISTINCT wp2.wp_customer_sk
        FROM tpcds.web_page wp2
        WHERE wp2.wp_type = 'Home'
    )
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_web_page_sk = wp.wp_web_page_sk
          AND ws2.ws_net_profit < 0
    )
GROUP BY
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_type,
    wp.wp_link_count
HAVING SUM(fs.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC, wp.wp_web_page_id
LIMIT 100
