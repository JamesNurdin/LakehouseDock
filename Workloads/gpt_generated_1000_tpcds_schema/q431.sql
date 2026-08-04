WITH cte_first AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       d.d_year,
       i.i_category,
       ARRAY[cr.cr_return_amount, cr.cr_return_tax] AS amt_array
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND EXISTS (
         SELECT 1
         FROM household_demographics hd
         JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
         WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
           AND ib.ib_lower_bound > 50000
     )
),
cte_first_unnest AS (
   SELECT
       cr_returned_date_sk,
       cr_item_sk,
       d_year,
       i_category,
       amt
   FROM cte_first
   CROSS JOIN UNNEST(amt_array) AS t (amt)
),
cte_second AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       d.d_year,
       cp.cp_department
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2000
     AND cp.cp_department LIKE '%Health%'
)
SELECT cr_returned_date_sk, cr_item_sk
FROM cte_first_unnest
INTERSECT
SELECT cr_returned_date_sk, cr_item_sk
FROM cte_second
