WITH distinct_returns AS (
    SELECT DISTINCT
        cr_returned_date_sk,
        cr_item_sk,
        cr_catalog_page_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_reason_sk,
        cr_order_number
    FROM catalog_returns
),
filtered_returns AS (
    SELECT *
    FROM distinct_returns dr
    WHERE dr.cr_return_amount > 0
      AND dr.cr_reason_sk IN (
          SELECT r_reason_sk
          FROM reason r2
          WHERE regexp_like(r2.r_reason_desc, '(?i)defect|damage')
      )
)
SELECT
    d.d_year,
    cp.cp_department,
    cp.cp_type,
    regexp_extract(i.i_item_desc, '(\\d{4})', 1) AS extracted_code,
    CONCAT(cp.cp_department, ':', cp.cp_type) AS dept_type,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns,
    (
        SELECT avg(cr_return_amount)
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_item_sk = i.i_item_sk
    ) AS avg_item_return_amount
FROM filtered_returns fr
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON fr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
WHERE cp.cp_description LIKE '%summer%'
  AND regexp_like(i.i_item_desc, '(?i)widget')
GROUP BY
    d.d_year,
    cp.cp_department,
    cp.cp_type,
    regexp_extract(i.i_item_desc, '(\\d{4})', 1),
    CONCAT(cp.cp_department, ':', cp.cp_type),
    i.i_item_sk
ORDER BY total_return_amount DESC
LIMIT 100
