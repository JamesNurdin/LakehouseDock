WITH sales_cte AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'sale' AS metric_type,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_amount
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        cs.cs_sales_price > 30
        AND c.c_birth_month = 5
    GROUP BY
        i.i_item_id,
        i.i_product_name
),
returns_cte AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'return' AS metric_type,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_quantity,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_amount
    FROM
        catalog_returns cr
        FULL OUTER JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
        JOIN item i ON COALESCE(cr.cr_item_sk, cs.cs_item_sk) = i.i_item_sk
    WHERE
        cr.cr_return_amount > 20
        AND cr.cr_returning_customer_sk IN (9416573, 6114601, 7882809)
    GROUP BY
        i.i_item_id,
        i.i_product_name
)
SELECT
    i_item_id,
    i_product_name,
    metric_type,
    total_quantity,
    total_amount
FROM sales_cte
UNION ALL
SELECT
    i_item_id,
    i_product_name,
    metric_type,
    total_quantity,
    total_amount
FROM returns_cte
ORDER BY i_item_id, metric_type, total_amount DESC
LIMIT 100
