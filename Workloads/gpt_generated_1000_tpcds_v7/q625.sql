SELECT
    cc.cc_mkt_desc,
    regexp_extract(cc.cc_mkt_desc, '(?i)(\\w+) groups', 1) AS extracted_word,
    cp.cp_type,
    sm.sm_carrier,
    substring(c.c_last_name, 1, 1) AS last_name_initial,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
WHERE regexp_like(cc.cc_mkt_desc, '(?i)rich')
  AND c.c_salutation LIKE 'M%'
  AND sm.sm_type LIKE '%Air%'
  AND cp.cp_description LIKE '%discount%'
GROUP BY
    cc.cc_mkt_desc,
    regexp_extract(cc.cc_mkt_desc, '(?i)(\\w+) groups', 1),
    cp.cp_type,
    sm.sm_carrier,
    substring(c.c_last_name, 1, 1)
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
