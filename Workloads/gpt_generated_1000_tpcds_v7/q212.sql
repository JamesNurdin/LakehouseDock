WITH high_spenders AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_net_paid) > 5000
)
SELECT
    i.i_category,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ws.ws_net_paid) AS total_sales,
    MIN(CONCAT(SUBSTRING(c.c_first_name, 1, 1), '. ', c.c_last_name)) AS example_customer_name,
    MIN(REGEXP_EXTRACT(i.i_item_desc, '^([^ ]+)', 1)) AS first_word_desc
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN high_spenders hs ON ws.ws_bill_customer_sk = hs.ws_bill_customer_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '\\.org$')
    AND c.c_first_name LIKE 'A%'
    AND d.d_year = 2001
GROUP BY
    i.i_category
ORDER BY
    total_sales DESC
LIMIT 10
