WITH
store_cust_ids AS (
    SELECT DISTINCT c.c_customer_id AS cust_id
    FROM customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_promo_sk IN (1044, 7, 412)
),
web_cust_ids AS (
    SELECT DISTINCT c.c_customer_id AS cust_id
    FROM customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_promo_sk IN (1044, 7, 412)
),
exclusive_store_cust AS (
    SELECT cust_id
    FROM store_cust_ids
    EXCEPT
    SELECT cust_id
    FROM web_cust_ids
)
SELECT
    c.c_customer_id AS cust_id,
    c.c_customer_sk,
    (SELECT sum(ss1.ss_net_paid) FROM store_sales ss1 WHERE ss1.ss_customer_sk = c.c_customer_sk) AS total_store_net_paid,
    l.last_sold_date,
    EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_type = 'product'
    ) AS has_product_page
FROM exclusive_store_cust esc
JOIN customer c
    ON c.c_customer_id = esc.cust_id
LEFT JOIN LATERAL (
    SELECT max(ss2.ss_sold_date_sk) AS last_sold_date
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = c.c_customer_sk
) l ON TRUE
WHERE c.c_birth_year BETWEEN 1950 AND 1960
ORDER BY total_store_net_paid DESC
LIMIT 100
