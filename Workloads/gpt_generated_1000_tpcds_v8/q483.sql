WITH ss_item_join AS (
    SELECT
        i.i_item_id,
        CASE WHEN ss.ss_ext_discount_amt > 0 THEN 'DISCOUNTED' ELSE 'FULL_PRICE' END AS price_type,
        SUM(ss.ss_ext_sales_price) OVER (
            PARTITION BY i.i_item_id
            ORDER BY ss.ss_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales
    FROM store_sales ss
    FULL OUTER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450830
       OR ss.ss_sold_date_sk IS NULL
),
catalog_sales_items AS (
    SELECT
        i.i_item_id,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'DISCOUNTED' ELSE 'FULL_PRICE' END AS price_type,
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY i.i_item_id
            ORDER BY cs.cs_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450830
),
returned_items AS (
    SELECT
        i.i_item_id,
        'RETURNED' AS price_type,
        SUM(cr.cr_return_amount) OVER (
            PARTITION BY i.i_item_id
            ORDER BY cr.cr_returned_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450830
)
SELECT *
FROM (
    SELECT i_item_id, price_type, running_sales FROM ss_item_join
    UNION
    SELECT i_item_id, price_type, running_sales FROM catalog_sales_items
) combined
EXCEPT
SELECT i_item_id, price_type, running_sales FROM returned_items
ORDER BY i_item_id
LIMIT 100
