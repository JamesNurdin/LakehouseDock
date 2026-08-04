WITH sampled_returns AS (
   SELECT *
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
),
page_warehouse AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cp.cp_catalog_page_sk,
       cp.cp_department,
       cp.cp_type,
       cp.cp_catalog_page_number,
       cp.cp_description,
       regexp_extract(cp.cp_description, '^([A-Za-z]+)') AS description_prefix,
       w.w_warehouse_sk,
       w.w_warehouse_name,
       w.w_city,
       w.w_state,
       w.w_street_name,
       w.w_street_number,
       concat(w.w_city, '-', w.w_state) AS location
   FROM sampled_returns cr
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(cp.cp_description, '^Special')
     AND w.w_street_name LIKE '%Spring%'
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
           AND cr2.cr_reason_sk = 5
           AND cr2.cr_catalog_page_sk = cr.cr_catalog_page_sk
     )
),
expanded_words AS (
   SELECT
       pw.cp_catalog_page_sk,
       pw.cp_department,
       pw.cp_type,
       pw.cp_catalog_page_number,
       pw.w_warehouse_sk,
       pw.w_warehouse_name,
       pw.location,
       pw.cr_return_amount,
       word
   FROM page_warehouse pw
   CROSS JOIN UNNEST(split(pw.cp_description, ' ')) AS t(word)
),
aggregated AS (
   SELECT
       ew.cp_department,
       ew.cp_type,
       ew.cp_catalog_page_number,
       ew.w_warehouse_name,
       ew.location,
       SUM(ew.cr_return_amount) AS total_return_amount,
       COUNT(DISTINCT ew.word) AS distinct_word_cnt,
       (
           SELECT AVG(cr3.cr_return_amount)
           FROM catalog_returns cr3
           WHERE cr3.cr_warehouse_sk = ew.w_warehouse_sk
       ) AS avg_return_per_warehouse
   FROM expanded_words ew
   GROUP BY
       ew.cp_department,
       ew.cp_type,
       ew.cp_catalog_page_number,
       ew.w_warehouse_name,
       ew.location,
       ew.w_warehouse_sk
),
ranked AS (
   SELECT
       a.*,
       row_number() OVER (PARTITION BY a.cp_department ORDER BY a.total_return_amount DESC) AS rn
   FROM aggregated a
)
SELECT
   rn,
   cp_department,
   cp_type,
   cp_catalog_page_number,
   w_warehouse_name,
   location,
   total_return_amount,
   distinct_word_cnt,
   avg_return_per_warehouse
FROM ranked
WHERE rn <= 5
ORDER BY cp_department, rn
