WITH page_a AS (
   SELECT cp_catalog_page_sk
   FROM catalog_page
   WHERE regexp_like(cp_description, '(?i)electronics')
     AND cp_type LIKE 'A%'
),
page_b AS (
   SELECT cp_catalog_page_sk
   FROM catalog_page
   WHERE cp_description LIKE '%home%'
     AND cp_type LIKE 'B%'
),
intersect_pages AS (
   SELECT cp_catalog_page_sk
   FROM page_a
   INTERSECT
   SELECT cp_catalog_page_sk
   FROM page_b
),
sales_sample AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),
joined AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       d.d_date,
       cs.cs_catalog_page_sk,
       cp.cp_description,
       cp.cp_type,
       cp.cp_catalog_page_number,
       cp.cp_department,
       cs.cs_net_paid,
       cs.cs_net_profit,
       sm.sm_ship_mode_id,
       c.c_first_name,
       c.c_last_name
   FROM sales_sample cs
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND cs.cs_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_pages)
)
SELECT
    j.cp_catalog_page_number,
    j.cp_department,
    j.cp_type,
    substring(j.cp_description FROM 1 FOR 30) AS short_desc,
    regexp_extract(j.cp_description, '(\\w+)', 1) AS first_word,
    j.sm_ship_mode_id,
    COUNT(*) AS sales_cnt,
    SUM(j.cs_net_paid) AS total_net_paid,
    AVG(j.cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT w.word) AS distinct_word_cnt,
    CASE
        WHEN SUM(j.cs_net_paid) > 10000 THEN 'high'
        ELSE 'low'
    END AS sales_volume_category
FROM joined j
CROSS JOIN LATERAL (
    SELECT word
    FROM UNNEST(split(j.cp_description, ' ')) AS t(word)
) AS w
GROUP BY
    j.cp_catalog_page_number,
    j.cp_department,
    j.cp_type,
    substring(j.cp_description FROM 1 FOR 30),
    regexp_extract(j.cp_description, '(\\w+)', 1),
    j.sm_ship_mode_id
ORDER BY total_net_paid DESC
LIMIT 100
