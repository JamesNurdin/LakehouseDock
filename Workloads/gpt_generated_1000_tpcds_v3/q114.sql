WITH filtered_sales AS (
    SELECT cs.cs_sold_time_sk,
           cs.cs_catalog_page_sk,
           cs.cs_bill_customer_sk,
           cs.cs_net_profit,
           cs.cs_quantity
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'breakfast'
      AND regexp_like(td.t_time_id, '^AAAA.*A$')
),
page_metrics AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_catalog_number,
           cp.cp_department,
           cp.cp_type,
           cp.cp_description,
           SUM(fs.cs_net_profit) AS total_net_profit,
           COUNT(DISTINCT fs.cs_bill_customer_sk) AS distinct_customers,
           SUM(fs.cs_quantity) AS total_quantity
    FROM filtered_sales fs
    JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_catalog_page_id, '^AAAAAAA[AE].*')
      AND cp.cp_description LIKE '%catalog%'
    GROUP BY cp.cp_catalog_page_id,
             cp.cp_catalog_number,
             cp.cp_department,
             cp.cp_type,
             cp.cp_description
),
overall_avg AS (
    SELECT AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
)
SELECT DISTINCT
       pm.cp_catalog_page_id,
       pm.cp_catalog_number,
       pm.cp_department,
       CONCAT(SUBSTRING(pm.cp_catalog_page_id, 1, 8), '-', pm.cp_type) AS page_id_type_concat,
       REGEXP_EXTRACT(pm.cp_description, '(\\d{4})') AS extracted_year,
       pm.total_net_profit,
       pm.distinct_customers,
       pm.total_quantity,
       oa.avg_profit,
       (
           SELECT COUNT(*)
           FROM catalog_sales cs2
           JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
           WHERE cp2.cp_catalog_page_id = pm.cp_catalog_page_id
       ) AS page_sales_count
FROM page_metrics pm
CROSS JOIN overall_avg oa
WHERE pm.total_net_profit > oa.avg_profit
ORDER BY pm.total_net_profit DESC
LIMIT 100
