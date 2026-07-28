WITH returns_week AS (
   SELECT
       r.r_reason_desc AS category,
       'Return' AS metric,
       SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_fy_week_seq = 5
   GROUP BY r.r_reason_desc
   HAVING SUM(cr.cr_return_amount) > (
       SELECT AVG(cr2.cr_return_amount)
       FROM catalog_returns cr2
       JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
       WHERE d2.d_fy_week_seq = 5
   )
),
sales_week AS (
   SELECT
       cp.cp_department AS category,
       'Sales' AS metric,
       SUM(ss.ss_ext_sales_price) AS total_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   WHERE d.d_fy_week_seq = 5
   GROUP BY cp.cp_department
)
SELECT *
FROM returns_week
UNION ALL
SELECT *
FROM sales_week
ORDER BY metric DESC, total_amount DESC
LIMIT 100
