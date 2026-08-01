WITH sampled_sales AS (
    SELECT cs_sold_date_sk,
           cs_bill_customer_sk,
           cs_ship_customer_sk,
           cs_quantity,
           cs_wholesale_cost,
           cs_ext_wholesale_cost,
           cs_net_paid,
           cs_ext_discount_amt,
           cs_ext_sales_price
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
exclusive_bill_keys AS (
    SELECT cs_bill_customer_sk
    FROM catalog_sales
    EXCEPT
    SELECT cs_ship_customer_sk
    FROM catalog_sales
)
SELECT
    customer.c_customer_sk,
    customer.c_last_name,
    customer.c_first_name,
    SUM(sampled_sales.cs_net_paid) AS total_net_paid,
    AVG(sampled_sales.cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_transactions,
    MIN(sampled_sales.cs_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(sampled_sales.cs_ext_wholesale_cost) AS max_wholesale_cost,
    (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = customer.c_customer_sk
    ) AS total_sales_price_for_customer,
    CASE WHEN sampled_sales.cs_bill_customer_sk IN (
        SELECT cs_bill_customer_sk FROM exclusive_bill_keys
    ) THEN 1 ELSE 0 END AS is_exclusive_bill_key
FROM sampled_sales
FULL OUTER JOIN customer
    ON sampled_sales.cs_bill_customer_sk = customer.c_customer_sk
WHERE
    sampled_sales.cs_ext_wholesale_cost > 1000
    AND customer.c_birth_day = 23
    AND customer.c_last_review_date >= 2452400
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_ship_customer_sk = customer.c_customer_sk
          AND cs3.cs_ext_discount_amt > 50
    )
GROUP BY
    customer.c_customer_sk,
    customer.c_last_name,
    customer.c_first_name,
    sampled_sales.cs_bill_customer_sk
ORDER BY total_net_paid DESC
LIMIT 100
