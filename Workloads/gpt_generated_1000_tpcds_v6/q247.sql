WITH sales AS (
   SELECT
      CAST('Store Sales' AS varchar) AS source,
      d.d_date AS report_date,
      s.s_store_name AS entity,
      SUM(ss.ss_ext_sales_price) AS total_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE s.s_state = 'CA'
     AND s.s_suite_number LIKE 'Suite %'
     AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
   GROUP BY d.d_date, s.s_store_name
),
returns AS (
   SELECT
      CAST('Catalog Returns' AS varchar) AS source,
      d.d_date AS report_date,
      c.cc_name AS entity,
      SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
   WHERE c.cc_state = 'CA'
     AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
   GROUP BY d.d_date, c.cc_name
)
SELECT source, report_date, entity, total_amount
FROM sales
UNION ALL
SELECT source, report_date, entity, total_amount
FROM returns
ORDER BY report_date DESC, total_amount DESC
LIMIT 100
