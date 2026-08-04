WITH full_join AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_store_sk,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       i.i_item_sk,
       i.i_brand,
       i.i_product_name,
       i.i_category,
       i.i_current_price
   FROM tpcds.store_returns sr
   FULL OUTER JOIN tpcds.item i
       ON sr.sr_item_sk = i.i_item_sk
),
agg AS (
   SELECT
       COALESCE(s.s_store_name, 'No Store') AS store_name,
       COALESCE(fj.i_brand, 'No Brand') AS brand,
       COALESCE(SUBSTRING(fj.i_product_name, 1, 15), 'No Product') AS product_name_prefix,
       COUNT(fj.sr_item_sk) AS returns_count,
       SUM(COALESCE(fj.sr_return_amt, 0)) AS total_return_amt,
       SUM(COALESCE(fj.sr_return_quantity, 0)) AS total_return_qty,
       CASE WHEN REGEXP_LIKE(s.s_hours, '^8AM') THEN 'MorningHours' ELSE 'OtherHours' END AS hours_category,
       CASE WHEN s.s_company_name LIKE '%Unknown%' THEN 'UnknownCompany' ELSE 'KnownCompany' END AS company_type,
       REGEXP_EXTRACT(COALESCE(fj.i_product_name, ''), '(\\w+)', 1) AS first_word_product
   FROM full_join fj
   LEFT JOIN tpcds.store s
       ON fj.sr_store_sk = s.s_store_sk
   WHERE (s.s_hours IS NOT NULL AND REGEXP_LIKE(s.s_hours, '^8AM'))
      OR (s.s_company_name IS NOT NULL AND s.s_company_name LIKE '%Unknown%')
   GROUP BY
       COALESCE(s.s_store_name, 'No Store'),
       COALESCE(fj.i_brand, 'No Brand'),
       COALESCE(SUBSTRING(fj.i_product_name, 1, 15), 'No Product'),
       CASE WHEN REGEXP_LIKE(s.s_hours, '^8AM') THEN 'MorningHours' ELSE 'OtherHours' END,
       CASE WHEN s.s_company_name LIKE '%Unknown%' THEN 'UnknownCompany' ELSE 'KnownCompany' END,
       REGEXP_EXTRACT(COALESCE(fj.i_product_name, ''), '(\\w+)', 1)
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS row_num,
    store_name,
    brand,
    product_name_prefix,
    returns_count,
    total_return_amt,
    total_return_qty,
    hours_category,
    company_type,
    first_word_product
FROM agg
ORDER BY row_num
LIMIT 100
