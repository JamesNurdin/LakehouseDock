WITH excluded_pages AS (
   SELECT cp.cp_catalog_page_sk
   FROM catalog_page cp
   WHERE cp.cp_type = 'Special'
   EXCEPT
   SELECT cr.cr_catalog_page_sk
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 0
),
avg_return_amount AS (
   SELECT AVG(cr_return_amount) AS avg_amt
   FROM catalog_returns
)
SELECT
   d.d_date AS return_date,
   cp.cp_catalog_page_number AS item_key,
   cr.cr_return_amount AS return_amount,
   CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_level,
   (
      SELECT COUNT(*)
      FROM catalog_returns cr2
      WHERE cr2.cr_catalog_page_sk = cr.cr_catalog_page_sk
   ) AS total_returns_for_key,
   r.r_reason_desc AS reason_desc
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return_amount)
  AND cp.cp_catalog_page_sk NOT IN (SELECT cp_catalog_page_sk FROM excluded_pages)

UNION

SELECT
   d2.d_date AS return_date,
   wr.wr_web_page_sk AS item_key,
   wr.wr_return_amt AS return_amount,
   CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_level,
   (
      SELECT COUNT(*)
      FROM web_returns wr2
      WHERE wr2.wr_web_page_sk = wr.wr_web_page_sk
   ) AS total_returns_for_key,
   r2.r_reason_desc AS reason_desc
FROM web_returns wr
JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
WHERE d2.d_year = 2001
  AND wr.wr_return_amt > (SELECT avg_amt FROM avg_return_amount)

ORDER BY return_date DESC, return_amount DESC
LIMIT 100
