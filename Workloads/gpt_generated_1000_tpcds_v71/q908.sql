/*
Goal: Summarize catalog return activity by call‑center, return reason and ship‑mode, showing counts and monetary totals for high‑value returns. The query joins all six TPC‑DS tables, applies several realistic filter predicates, uses a LEFT OUTER JOIN to bring in optional refunded‑address information, groups and aggregates the measures, orders by total return amount, and limits the result to the top 100 rows.
*/
WITH filtered_returns AS (
    SELECT cr.*
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100.00
      AND cr.cr_return_quantity BETWEEN 1 AND 5
)
SELECT
    cc.cc_name,
    r.r_reason_desc,
    sm.sm_type,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_store_credit) AS avg_store_credit,
    MAX(cr.cr_return_quantity) AS max_quantity
FROM filtered_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE cp.cp_catalog_page_number IN (1, 12, 14)
  AND sm.sm_type = 'AIR'
  AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
  AND cc.cc_state = 'CA'
GROUP BY cc.cc_name, r.r_reason_desc, sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 100
