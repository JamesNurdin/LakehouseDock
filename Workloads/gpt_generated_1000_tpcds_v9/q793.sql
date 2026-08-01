WITH filtered_returns AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_reversed_charge,
        cr.cr_returned_date_sk,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_description,
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_contract
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount|sale')
      AND sm.sm_code LIKE 'A%'
      AND sm.sm_contract LIKE 'I3u%'
)
SELECT
    p.cp_catalog_page_id,
    p.sm_ship_mode_id,
    CONCAT('Page_', p.cp_catalog_page_id) AS page_label,
    COUNT(*) AS total_returns,
    SUM(p.cr_return_amount) AS total_return_amount,
    AVG(p.cr_return_amount) AS avg_return_amount,
    MAX(p.cr_return_ship_cost) AS max_ship_cost,
    regexp_extract(p.sm_contract, '\\d+', 0) AS contract_digits,
    (SELECT SUM(cr2.cr_reversed_charge)
     FROM catalog_returns cr2
     WHERE cr2.cr_catalog_page_sk = p.cp_catalog_page_sk) AS total_rev_charge_for_page
FROM filtered_returns p
GROUP BY
    p.cp_catalog_page_id,
    p.sm_ship_mode_id,
    p.sm_contract,
    p.cp_catalog_page_sk
HAVING COUNT(*) > 3
ORDER BY total_return_amount DESC, p.cp_catalog_page_id
LIMIT 100
