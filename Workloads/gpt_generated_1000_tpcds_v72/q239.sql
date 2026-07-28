WITH store_sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(ss.ss_net_paid) AS total_paid,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (8, 9, 11)
    GROUP BY c.c_customer_id
),
catalog_sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        SUM(cs.cs_net_paid) AS total_paid,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (8, 9, 11)
    GROUP BY c.c_customer_id
)
SELECT
    customer_id,
    total_paid,
    sales_channel
FROM store_sales_agg
UNION ALL
SELECT
    customer_id,
    total_paid,
    sales_channel
FROM catalog_sales_agg
ORDER BY total_paid DESC
LIMIT 100
