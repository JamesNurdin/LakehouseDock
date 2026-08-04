WITH catalog_sales_filtered AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_category = 'Sports'
    )
    GROUP BY cs.cs_bill_customer_sk
),
catalog_sales_keys AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
),
catalog_returns_keys AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
),
sales_without_returns AS (
    SELECT cs_key.cs_order_number
    FROM catalog_sales_keys cs_key
    EXCEPT
    SELECT cr_key.cr_order_number
    FROM catalog_returns_keys cr_key
),
customers_without_returns AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN sales_without_returns swr
        ON cs.cs_order_number = swr.cs_order_number
)
SELECT
    c.c_customer_id,
    csf.total_paid,
    csf.distinct_items,
    (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    ) AS total_store_return_amount
FROM customers_without_returns cw
JOIN customer c ON cw.customer_sk = c.c_customer_sk
JOIN catalog_sales_filtered csf ON csf.customer_sk = c.c_customer_sk
WHERE c.c_customer_sk IN (
    SELECT c2.c_customer_sk
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
ORDER BY total_store_return_amount DESC
LIMIT 100
