WITH first_set AS (
   SELECT
      CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_full_name,
      hd.hd_income_band_sk,
      cr.cr_return_amount,
      regexp_extract(cp.cp_description, '(\\d{3})', 1) AS discount_code
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE w.w_city LIKE 'San%'
     AND regexp_like(cp.cp_description, '.*Discount.*')
     AND NOT EXISTS (
         SELECT 1 FROM web_returns wr
         WHERE wr.wr_returned_date_sk = cr.cr_returned_date_sk
           AND wr.wr_item_sk = cr.cr_item_sk
     )
),
second_set AS (
   SELECT
      CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_full_name,
      hd.hd_income_band_sk,
      cr.cr_return_amount,
      regexp_extract(cp.cp_description, '(\\d{3})', 1) AS discount_code
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE w.w_suite_number LIKE 'Suite %'
     AND regexp_like(cp.cp_type, '^Online')
     AND NOT EXISTS (
         SELECT 1 FROM web_returns wr
         WHERE wr.wr_returned_date_sk = cr.cr_returned_date_sk
           AND wr.wr_item_sk = cr.cr_item_sk
     )
)
SELECT
   u.warehouse_full_name,
   COUNT(DISTINCT u.hd_income_band_sk) AS distinct_income_bands,
   SUM(DISTINCT u.cr_return_amount) AS distinct_return_amount_sum,
   (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound
FROM (
   SELECT * FROM first_set
   UNION
   SELECT * FROM second_set
) u
GROUP BY u.warehouse_full_name
ORDER BY distinct_return_amount_sum DESC
LIMIT 100
