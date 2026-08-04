WITH sales_by_customer AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        wp.wp_url,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, 1, 5) AS email_prefix
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND wp.wp_url LIKE '%/promo/%'
),
eligible_orders AS (
    SELECT ws_order_number
    FROM sales_by_customer
    WHERE ws_ext_sales_price > 5000
    INTERSECT
    SELECT ws_order_number
    FROM sales_by_customer
    WHERE c_first_name LIKE 'J%'
),
non_returned_orders AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
)
SELECT
    url_parts.domain,
    COUNT(DISTINCT sbc.customer_sk) AS unique_customers,
    SUM(sbc.ws_ext_sales_price) AS total_sales
FROM sales_by_customer sbc
CROSS JOIN LATERAL (
    SELECT regexp_extract(sbc.wp_url, 'https?://([^/]+)/', 1) AS domain
) AS url_parts
JOIN eligible_orders eo
  ON sbc.ws_order_number = eo.ws_order_number
JOIN non_returned_orders nro
  ON sbc.ws_order_number = nro.ws_order_number
WHERE url_parts.domain = 'www.example.com'
GROUP BY url_parts.domain
ORDER BY total_sales DESC
LIMIT 10
