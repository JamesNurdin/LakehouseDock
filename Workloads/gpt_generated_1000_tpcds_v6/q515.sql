WITH sales_agg AS (
   SELECT i.i_item_sk,
          i.i_product_name,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2022
     AND regexp_like(i.i_product_name, '^A.*')
     AND regexp_like(i.i_item_desc, '[A-Z]{3}')
   GROUP BY i.i_item_sk, i.i_product_name
),
returns_agg AS (
   SELECT i.i_item_sk,
          i.i_product_name,
          SUM(cr.cr_return_amount) AS total_returns,
          COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2022
     AND NOT regexp_like(r.r_reason_desc, 'defect')
   GROUP BY i.i_item_sk, i.i_product_name
),
combined AS (
   SELECT s.i_item_sk,
          s.i_product_name,
          s.total_sales,
          s.sales_cnt,
          0 AS total_returns,
          0 AS return_cnt,
          'sales' AS src
   FROM sales_agg s
   UNION ALL
   SELECT r.i_item_sk,
          r.i_product_name,
          0 AS total_sales,
          0 AS sales_cnt,
          r.total_returns,
          r.return_cnt,
          'returns' AS src
   FROM returns_agg r
)
SELECT c.i_item_sk,
       c.i_product_name,
       c.total_sales,
       c.sales_cnt,
       c.total_returns,
       c.return_cnt,
       c.src
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
    WHERE cr2.cr_item_sk = c.i_item_sk
      AND regexp_like(r2.r_reason_desc, 'damage')
)
ORDER BY c.total_sales DESC, c.total_returns DESC
LIMIT 100
