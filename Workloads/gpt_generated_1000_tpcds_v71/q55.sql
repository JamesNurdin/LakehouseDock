WITH date_filter AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2022
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'sales' AS record_type,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'high' ELSE 'low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS activity_rank
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
),
returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'return' AS record_type,
        SUM(cr.cr_return_amount) AS total_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'high' ELSE 'low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(cr.cr_return_amount) DESC) AS activity_rank
    FROM catalog_returns cr
    JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) combined
ORDER BY total_amount DESC
LIMIT 100
