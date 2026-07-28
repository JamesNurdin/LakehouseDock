/*
Goal: Identify the top customers (by net paid amount) whose email address ends with '.com', whose first name starts with 'A', and who bought items whose description contains the word "brand" (case‑insensitive). The query extracts the email domain, builds the full name, and aggregates sales per customer.
*/
WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_net_paid
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)brand')
)
SELECT
    c.c_customer_sk,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    count(*) AS num_transactions,
    sum(fs.ss_net_paid) AS total_net_paid
FROM filtered_sales fs
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@%.com'
  AND c.c_first_name LIKE 'A%'
GROUP BY
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
ORDER BY total_net_paid DESC
LIMIT 100
