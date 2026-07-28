WITH sales_page AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_list_price,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_ship_cost,
        ws.ws_ext_discount_amt,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        wp.wp_rec_end_date
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'Content'
      AND wp.wp_image_count BETWEEN 2 AND 6
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND ws.ws_list_price > (
          SELECT AVG(ws2.ws_list_price)
          FROM tpcds.web_sales ws2
      )
      AND ws.ws_quantity >= 2
)
SELECT
    wp_type,
    wp_image_count,
    COUNT(*) AS orders_cnt,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_list_price) AS avg_list_price,
    MIN(ws_ext_ship_cost) AS min_ship_cost,
    MAX(ws_ext_discount_amt) AS max_discount_amt
FROM sales_page
GROUP BY GROUPING SETS (
    (wp_type, wp_image_count),
    (wp_type),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
