WITH store_year AS (
    SELECT s.s_store_id AS entity_id,
           d.d_year AS year,
           CAST(NULL AS decimal(7,2)) AS total_sales
    FROM store s
    FULL OUTER JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_open_date_sk = s.s_closed_date_sk
      )
),
callcenter_sales AS (
    SELECT cc.cc_call_center_id AS entity_id,
           d.d_year AS year,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY cc.cc_call_center_id, d.d_year
)
SELECT entity_id,
       year,
       total_sales
FROM store_year
UNION ALL
SELECT entity_id,
       year,
       total_sales
FROM callcenter_sales
ORDER BY year DESC,
         total_sales DESC
LIMIT 100
