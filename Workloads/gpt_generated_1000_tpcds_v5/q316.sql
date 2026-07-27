WITH store_category_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        AVG(ss.ss_ext_sales_price) AS avg_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category IN ('Furniture', 'Electronics')
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category
)

SELECT
    scs.s_store_name,
    scs.i_category,
    scs.avg_sales
FROM store_category_sales scs
WHERE scs.i_category = 'Furniture'
  AND scs.avg_sales > 1000
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN customer c ON ss2.ss_customer_sk = c.c_customer_sk
        WHERE ss2.ss_store_sk = scs.s_store_sk
          AND c.c_first_name = 'Melvin'
    )
UNION ALL
SELECT
    scs.s_store_name,
    scs.i_category,
    scs.avg_sales
FROM store_category_sales scs
WHERE scs.i_category = 'Electronics'
  AND scs.avg_sales > 1000
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN customer c ON ss2.ss_customer_sk = c.c_customer_sk
        WHERE ss2.ss_store_sk = scs.s_store_sk
          AND c.c_first_name = 'Melvin'
    )
ORDER BY avg_sales DESC
LIMIT 100
