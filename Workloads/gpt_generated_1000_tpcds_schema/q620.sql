WITH returns_sample AS (
    SELECT
        cr_returning_customer_sk AS customer_sk,
        cr_item_sk,
        cr_reason_sk,
        cr_return_quantity,
        cr_return_amount
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_returned_date_sk BETWEEN 2451500 AND 2451600
),
returns_customers AS (
    SELECT DISTINCT customer_sk
    FROM returns_sample
),
web_sales_customers AS (
    SELECT DISTINCT ws_bill_customer_sk AS customer_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451500 AND 2451600
),
customers_no_web AS (
    SELECT customer_sk
    FROM returns_customers
    EXCEPT
    SELECT customer_sk
    FROM web_sales_customers
)
SELECT
    c.customer_sk,
    COUNT(DISTINCT r.cr_item_sk) AS distinct_items_returned,
    COUNT(DISTINCT r.cr_reason_sk) AS distinct_return_reasons,
    SUM(r.cr_return_amount) AS total_return_amount
FROM customers_no_web c
JOIN returns_sample r
    ON c.customer_sk = r.customer_sk
JOIN customer cust
    ON cust.c_customer_sk = c.customer_sk
JOIN customer_address ca
    ON cust.c_current_addr_sk = ca.ca_address_sk
GROUP BY c.customer_sk
ORDER BY total_return_amount DESC
LIMIT 100
