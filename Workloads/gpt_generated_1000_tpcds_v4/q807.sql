/* goal: Identify the highest‑spending customers in 2002 whose associated web pages have URLs that match a sale‑related pattern and page types starting with 'C'. The query extracts parts of email addresses, builds a full customer name, aggregates orders and sales, filters by a minimum total sales amount, and returns the top results. */
WITH sales_web AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.com/.*sale.*$')
      AND wp.wp_type LIKE 'C%'
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    COUNT(DISTINCT sw.ws_order_number) AS orders,
    SUM(sw.ws_net_paid_inc_ship_tax) AS total_sales,
    CONCAT('Customer ', c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUBSTR(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
FROM sales_web sw
JOIN customer c
    ON sw.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d
    ON sw.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
HAVING SUM(sw.ws_net_paid_inc_ship_tax) > 10000
ORDER BY total_sales DESC
LIMIT 100
