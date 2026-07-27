WITH page_returns AS (
   SELECT
      cp.cp_catalog_page_number,
      cp.cp_department,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty
   FROM catalog_returns cr
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450980 AND 2451000
   GROUP BY cp.cp_catalog_page_number, cp.cp_department
)
SELECT
   pr.cp_catalog_page_number AS catalog_page_number,
   pr.cp_department AS department,
   pr.total_return_amount,
   pr.total_return_qty
FROM page_returns pr
WHERE pr.total_return_amount > (
        SELECT MAX(cr_return_amount)
        FROM catalog_returns
        WHERE cr_returned_date_sk < 2450990
      )
UNION ALL
SELECT
   cp.cp_catalog_page_number,
   cp.cp_department,
   SUM(cr.cr_return_amount) AS total_return_amount,
   SUM(cr.cr_return_quantity) AS total_return_qty
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cr.cr_returned_date_sk BETWEEN 2451001 AND 2451020
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
          AND cr2.cr_fee > 0
      )
GROUP BY cp.cp_catalog_page_number, cp.cp_department
ORDER BY total_return_amount DESC
LIMIT 100
