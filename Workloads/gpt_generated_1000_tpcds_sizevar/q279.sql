WITH total_spent_per_customer AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
qualified_customers AS (
    (
        SELECT c.c_customer_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE i.i_category = 'Electronics'
          AND ss.ss_quantity > 2
    )
    EXCEPT
    (
        SELECT c.c_customer_sk
        FROM web_page wp
        JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
        WHERE wp.wp_type = 'home'
    )
)
SELECT
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    tspc.total_spent,
    (
        SELECT COUNT(DISTINCT ss_inner.ss_item_sk)
        FROM store_sales ss_inner
        WHERE ss_inner.ss_customer_sk = cust.c_customer_sk
    ) AS distinct_items_purchased
FROM qualified_customers qc
JOIN customer cust ON qc.c_customer_sk = cust.c_customer_sk
LEFT JOIN total_spent_per_customer tspc ON cust.c_customer_sk = tspc.customer_sk
ORDER BY tspc.total_spent DESC
LIMIT 100
