(
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND ws.ws_ext_sales_price > 100
) INTERSECT (
    SELECT DISTINCT c2.c_customer_id
    FROM web_page wp
    JOIN web_sales ws2 ON wp.wp_web_page_sk = ws2.ws_web_page_sk
    JOIN date_dim d2 ON wp.wp_access_date_sk = d2.d_date_sk
    JOIN customer c2 ON wp.wp_customer_sk = c2.c_customer_sk
    WHERE d2.d_year = 2000
      AND wp.wp_max_ad_count >= 2
)
ORDER BY c_customer_id
LIMIT 100
