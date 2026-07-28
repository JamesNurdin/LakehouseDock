/*
Goal: Identify the top 100 customers in the year 2001 whose web sales generated the highest total net paid, where the associated web site market manager's name starts with 'David' and the customer's city begins with 'M'. Exclude any customers who have made store returns. The query demonstrates string processing (REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT), uses a scalar subquery for the overall yearly average net paid, and includes an anti‑join via NOT EXISTS.
*/
WITH ws_filtered AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_order_number,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    web_site.web_market_manager,
    regexp_extract(web_site.web_market_manager, '(\\w+)', 1) AS manager_first_name,
    sum(ws_filtered.ws_net_paid) AS total_net_paid,
    count(DISTINCT ws_filtered.ws_order_number) AS orders_count,
    (
        SELECT avg(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_yearly_net_paid
FROM ws_filtered
JOIN customer c ON ws_filtered.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws_filtered.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site ON ws_filtered.ws_web_site_sk = web_site.web_site_sk
WHERE regexp_like(web_site.web_market_manager, '^David')
  AND ca.ca_city LIKE 'M%'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    )
GROUP BY
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name),
    ca.ca_city,
    web_site.web_market_manager,
    regexp_extract(web_site.web_market_manager, '(\\w+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
