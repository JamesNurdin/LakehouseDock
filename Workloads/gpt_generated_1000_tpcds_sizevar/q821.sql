WITH regex_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_item_desc,
           i_brand,
           i_category,
           regexp_extract(i_item_desc, '(\\d{3})') AS code3
    FROM item
    WHERE regexp_like(i_item_desc, '\\d{3}')
      AND i_brand LIKE 'Brand%'
),
like_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_item_desc,
           i_brand,
           i_category
    FROM item
    WHERE i_product_name LIKE '%Pro%'
),
intersect_items AS (
    SELECT i_item_sk FROM regex_items
    INTERSECT
    SELECT i_item_sk FROM like_items
),
filtered_items AS (
    SELECT ri.i_item_sk,
           ri.i_item_id,
           ri.i_brand,
           ri.i_category,
           ri.code3
    FROM regex_items ri
    JOIN intersect_items ii ON ri.i_item_sk = ii.i_item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ri.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
),
sales_agg AS (
    SELECT
        fi.i_brand,
        fi.i_category,
        fi.code3,
        COUNT(ws.ws_order_number) AS orders_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS brand_category_rank,
        lc.concat_len
    FROM filtered_items fi
    JOIN web_sales ws ON ws.ws_item_sk = fi.i_item_sk
    CROSS JOIN LATERAL (
        SELECT length(concat(fi.i_brand, '-', fi.i_category)) AS concat_len
    ) lc
    GROUP BY fi.i_brand, fi.i_category, fi.code3, lc.concat_len
)
SELECT u.i_brand,
       u.i_category,
       u.code3,
       u.orders_cnt,
       u.total_sales,
       u.avg_sales_price,
       u.brand_category_rank,
       u.concat_len
FROM (
    SELECT i_brand,
           i_category,
           code3,
           orders_cnt,
           total_sales,
           avg_sales_price,
           brand_category_rank,
           concat_len
    FROM sales_agg
    UNION
    SELECT i_brand,
           i_category,
           code3,
           orders_cnt,
           total_sales,
           avg_sales_price,
           brand_category_rank,
           concat_len
    FROM sales_agg
) AS u
ORDER BY u.total_sales DESC
LIMIT 100
