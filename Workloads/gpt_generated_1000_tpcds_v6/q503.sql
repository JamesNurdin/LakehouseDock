WITH sales AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY i.i_item_id, i.i_product_name
),
returns AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'returns' AS metric_type,
        SUM(cr.cr_return_amount) AS amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 100
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    item_id,
    product_name,
    metric_type,
    amount
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) AS combined
ORDER BY amount DESC
LIMIT 100
