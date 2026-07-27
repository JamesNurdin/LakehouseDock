WITH recent_sales AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_ext_sales_price) > 1000
)
SELECT * FROM (
    SELECT
        c.c_customer_id,
        ca.ca_city,
        wp.wp_url,
        ws.ws_ext_sales_price,
        rs.total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN recent_sales rs
      ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_image_count > 3
      AND ca.ca_location_type = 'single family'
      AND ws.ws_ext_sales_price > (
          SELECT MAX(ws2.ws_ext_sales_price)
          FROM tpcds.web_sales ws2
          WHERE ws2.ws_web_page_sk = wp.wp_web_page_sk
      ) * 0.5

    UNION ALL

    SELECT
        c.c_customer_id,
        ca.ca_city,
        wp.wp_url,
        ws.ws_ext_sales_price,
        rs.total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
      ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN recent_sales rs
      ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count <= 3
      AND ca.ca_gmt_offset = -6.00
      AND ws.ws_quantity >= 2
) AS combined
ORDER BY total_sales DESC, c_customer_id
LIMIT 100
