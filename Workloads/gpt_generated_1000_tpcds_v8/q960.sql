WITH sales_agg AS (
   SELECT
       d.d_year AS report_year,
       cp.cp_department AS source_name,
       CAST('Catalog Sales' AS varchar) AS source_type,
       SUM(cs.cs_ext_sales_price) AS metric_value
   FROM catalog_sales cs
   RIGHT OUTER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
     AND EXISTS (
         SELECT 1
         FROM customer c
         JOIN customer_demographics cd
           ON c.c_current_cdemo_sk = cd.cd_demo_sk
         WHERE c.c_customer_sk = cs.cs_bill_customer_sk
           AND cd.cd_education_status = 'Advanced Degree'
     )
   GROUP BY d.d_year, cp.cp_department
),
promo_agg AS (
   SELECT
       d.d_year AS report_year,
       p.p_promo_name AS source_name,
       CAST('Promotion' AS varchar) AS source_type,
       SUM(p.p_cost) AS metric_value
   FROM date_dim d
   FULL OUTER JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, p.p_promo_name
)
SELECT report_year,
       source_type,
       source_name,
       metric_value
FROM sales_agg
UNION
SELECT report_year,
       source_type,
       source_name,
       metric_value
FROM promo_agg
ORDER BY report_year, metric_value DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
