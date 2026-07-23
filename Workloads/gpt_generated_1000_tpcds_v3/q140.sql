/*
Goal: Summarize catalog returns by page type and return reason for high‑income customers, extracting numeric codes from page descriptions, applying regex and LIKE filters, categorizing return amounts, and ordering by total return amount.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cp.cp_type,
        cp.cp_department,
        r.r_reason_desc AS reason_desc,
        regexp_extract(cp.cp_description, '(\\d+)', 1) AS extracted_number,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
        concat(cp.cp_department, '-', cp.cp_type) AS dept_type_concat,
        substr(cp.cp_type, 1, 1) AS type_prefix,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_type LIKE 'C%'
      AND regexp_like(r.r_reason_desc, '(?i)damaged|defective')
      AND regexp_extract(cp.cp_description, '(\\d+)', 1) IS NOT NULL
      AND ib.ib_upper_bound > 50000
)
SELECT
    cp_type,
    cp_department,
    reason_desc,
    extracted_number,
    return_amount_category,
    dept_type_concat,
    type_prefix,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count
FROM filtered_returns
GROUP BY
    cp_type,
    cp_department,
    reason_desc,
    extracted_number,
    return_amount_category,
    dept_type_concat,
    type_prefix
ORDER BY total_return_amount DESC
LIMIT 100
