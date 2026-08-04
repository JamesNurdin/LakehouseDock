WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_customer_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_net_paid > 100
    GROUP BY ss_item_sk, ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_country,
    sa.total_net_paid,
    (SELECT SUM(ss2.ss_quantity)
     FROM store_sales ss2
     WHERE ss2.ss_customer_sk = c.c_customer_sk) AS overall_quantity,
    'CUSTOMER' AS src
FROM customer c
LEFT JOIN sales_agg sa
    ON sa.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_country IN ('GAMBIA', 'SWITZERLAND')
  AND EXISTS (
        SELECT 1
        FROM store_sales ss3
        WHERE ss3.ss_customer_sk = c.c_customer_sk
          AND ss3.ss_net_paid > 500
    )
UNION
SELECT
    i.i_item_id,
    i.i_category,
    COALESCE(sa2.total_net_paid, 0) AS total_net_paid,
    (SELECT COUNT(DISTINCT ss4.ss_customer_sk)
     FROM store_sales ss4
     WHERE ss4.ss_item_sk = i.i_item_sk) AS distinct_customers,
    'ITEM' AS src
FROM item i
FULL OUTER JOIN (
        SELECT ss_item_sk, SUM(ss_net_paid) AS total_net_paid
        FROM store_sales
        WHERE ss_net_paid BETWEEN 50 AND 1000
        GROUP BY ss_item_sk
    ) sa2
    ON i.i_item_sk = sa2.ss_item_sk
WHERE i.i_class_id IN (5, 8)
  AND i.i_formulation LIKE '%steel%'
ORDER BY src, total_net_paid DESC
LIMIT 100
