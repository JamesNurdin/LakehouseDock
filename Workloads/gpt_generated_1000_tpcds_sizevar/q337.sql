WITH regex_items AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
),
like_items AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_units LIKE '%Box%'
),
intersect_items AS (
    SELECT cs_item_sk FROM regex_items
    INTERSECT
    SELECT cs_item_sk FROM like_items
),
sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS sales_category
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
)
SELECT
    COALESCE(i.i_item_id, 'UNKNOWN') AS item_id,
    i.i_size,
    w.w_country,
    s.total_sales,
    s.avg_discount,
    s.sales_category,
    CONCAT('Size-', SUBSTRING(i.i_size, 1, 3)) AS size_code
FROM sales_agg s
FULL OUTER JOIN item i
    ON s.cs_item_sk = i.i_item_sk
FULL OUTER JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
WHERE (
        i.i_category IS NOT NULL AND i.i_category LIKE 'Elect%'
    )
    OR (
        w.w_city IS NOT NULL AND w.w_city LIKE 'San%'
    )
ORDER BY total_sales DESC
LIMIT 100
