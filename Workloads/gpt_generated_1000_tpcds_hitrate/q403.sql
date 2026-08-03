WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_city,
        cc_state,
        concat(cc_name, ' - ', cc_city) AS cc_full_desc,
        regexp_extract(cc_name, '(\\w+)', 1) AS first_word_name
    FROM tpcds.call_center
    WHERE regexp_like(cc_name, 'Market')
      AND cc_city LIKE '%County'
)
SELECT
    fc.cc_call_center_sk,
    fc.cc_full_desc,
    fc.first_word_name,
    fc.cc_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(cr.cr_return_tax) > 100 THEN 'High Tax'
        ELSE 'Low Tax'
    END AS tax_category,
    ROW_NUMBER() OVER (PARTITION BY fc.cc_state ORDER BY SUM(cr.cr_return_amount) DESC) AS state_rank
FROM filtered_cc fc
JOIN tpcds.catalog_returns cr
    ON cr.cr_call_center_sk = fc.cc_call_center_sk
WHERE cr.cr_return_amount > 0
GROUP BY fc.cc_call_center_sk, fc.cc_full_desc, fc.first_word_name, fc.cc_state
HAVING COUNT(*) >= 5
ORDER BY total_return_amount DESC
LIMIT 100
