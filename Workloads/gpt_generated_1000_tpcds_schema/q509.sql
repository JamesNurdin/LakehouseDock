WITH dept_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_ext_sales_price) AS dept_sales_total
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
    GROUP BY cs.cs_item_sk
),
brand_sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_ext_sales_price) AS brand_sales_total
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_brand_id = 3001002
    GROUP BY cs.cs_item_sk
),
addr_sales AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ship_addr_sk = 5602324
    GROUP BY cs.cs_item_sk
),
full_join AS (
    SELECT COALESCE(d.item_sk, b.item_sk) AS item_sk,
           d.dept_sales_total,
           b.brand_sales_total
    FROM dept_sales d
    FULL OUTER JOIN brand_sales b
      ON d.item_sk = b.item_sk
),
union_keys AS (
    SELECT item_sk FROM dept_sales
    UNION
    SELECT item_sk FROM brand_sales
),
intersect_keys AS (
    SELECT item_sk FROM dept_sales
    INTERSECT
    SELECT item_sk FROM brand_sales
),
final_set AS (
    SELECT item_sk FROM union_keys
    EXCEPT
    SELECT item_sk FROM addr_sales
)
SELECT f.item_sk,
       f.dept_sales_total,
       f.brand_sales_total,
       CASE WHEN i.item_sk IS NOT NULL THEN 'Both' ELSE 'One' END AS presence_flag
FROM full_join f
LEFT JOIN intersect_keys i
  ON f.item_sk = i.item_sk
WHERE f.item_sk IN (SELECT item_sk FROM final_set)
ORDER BY f.dept_sales_total DESC NULLS LAST
LIMIT 100
