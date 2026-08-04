WITH page_sales AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_number,
    cp.cp_description,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_list_price) AS avg_list_price,
    COUNT(cs.cs_order_number) AS order_cnt
  FROM catalog_sales cs
  RIGHT OUTER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE
    cs.cs_ext_ship_cost > 500.00                        -- predicate 1
    AND cs.cs_list_price BETWEEN 50 AND 200            -- predicate 2
    AND cs.cs_quantity >= 1                            -- predicate 3
    AND cp.cp_catalog_page_number IN (6,9,10,11,19)    -- predicate 4
    AND cp.cp_type = 'A'                               -- predicate 5
  GROUP BY
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_number,
    cp.cp_description
),
sales_above_avg AS (
  SELECT *
  FROM page_sales
  WHERE total_sales > (
    SELECT AVG(total_sales) FROM page_sales
  )
)
SELECT
  ps.cp_catalog_page_sk,
  ps.cp_catalog_page_number,
  ps.cp_description,
  ps.total_sales,
  ps.total_quantity,
  ps.avg_list_price,
  ps.order_cnt,
  RANK() OVER (PARTITION BY ps.cp_catalog_page_number ORDER BY ps.total_sales DESC) AS sales_rank
FROM sales_above_avg ps
ORDER BY ps.cp_catalog_page_number, sales_rank
