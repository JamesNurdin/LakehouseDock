WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_type,
        cp.cp_catalog_page_number,
        CONCAT(cp.cp_type, '-', CAST(cp.cp_catalog_page_number AS VARCHAR)) AS page_code,
        regexp_extract(cp.cp_description, '(\\w+)') AS first_word,
        CASE
            WHEN regexp_like(cp.cp_description, '(?i)\\bsale\\b') THEN 'ContainsSale'
            ELSE 'Other'
        END AS sale_flag
    FROM catalog_page cp
    WHERE cp.cp_type LIKE 'monthly%'
      AND regexp_like(cp.cp_description, '(?i)\\b[0-9]{4}\\b')
)
SELECT
    fp.page_code,
    fp.sale_flag,
    r.r_reason_desc,
    d.d_year,
    COUNT(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS row_num
FROM filtered_pages fp
JOIN catalog_returns cr
  ON cr.cr_catalog_page_sk = fp.cp_catalog_page_sk
JOIN reason r
  ON r.r_reason_sk = cr.cr_reason_sk
JOIN date_dim d
  ON d.d_date_sk = cr.cr_returned_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY fp.page_code, fp.sale_flag, r.r_reason_desc, d.d_year
ORDER BY total_return_amount DESC
LIMIT 100
