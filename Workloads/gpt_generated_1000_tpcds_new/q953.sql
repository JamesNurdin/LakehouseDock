WITH
    billed AS (
        SELECT cs_bill_customer_sk AS customer_sk,
               cs_net_paid_inc_ship_tax
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE cs_catalog_page_sk IN (272, 46)
    ),
    shipped AS (
        SELECT cs_ship_customer_sk AS customer_sk,
               cs_net_paid_inc_ship_tax
        FROM catalog_sales
        WHERE cs_catalog_page_sk IN (172, 50)
    ),
    union_customers AS (
        SELECT customer_sk FROM billed
        UNION
        SELECT customer_sk FROM shipped
    ),
    except_customers AS (
        SELECT customer_sk FROM billed
        EXCEPT
        SELECT customer_sk FROM shipped
    ),
    intersect_customers AS (
        SELECT customer_sk FROM billed
        INTERSECT
        SELECT customer_sk FROM shipped
    )
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    (SELECT SUM(cs.cs_net_paid_inc_ship_tax)
     FROM catalog_sales cs
     WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS total_billed_net,
    CASE
        WHEN ic.customer_sk IS NOT NULL THEN 'Both'
        WHEN ec.customer_sk IS NOT NULL THEN 'BilledOnly'
        ELSE 'Other'
    END AS customer_category
FROM (
        SELECT customer_sk FROM union_customers
        EXCEPT
        SELECT customer_sk FROM except_customers
    ) AS u
JOIN customer c ON c.c_customer_sk = u.customer_sk
LEFT JOIN intersect_customers ic ON ic.customer_sk = c.c_customer_sk
LEFT JOIN except_customers ec ON ec.customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mr.'
ORDER BY total_billed_net DESC
LIMIT 100
