SELECT
    r.r_reason_id,
    r.r_reason_desc,
    sm.sm_type,
    concat(cc.cc_city, ':', w.w_city) AS city_pair,
    substring(cc.cc_name, 1, 10) AS cc_name_prefix,
    regexp_extract(r.r_reason_desc, '(\\w+)$', 1) AS last_word,
    sum(cr.cr_net_loss) AS total_net_loss,
    count(*) AS return_cnt
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(r.r_reason_desc, '(?i)price|service')
  AND sm.sm_contract LIKE '%V%'
  AND substring(cc.cc_name, 1, 5) = 'Call '
GROUP BY
    r.r_reason_id,
    r.r_reason_desc,
    sm.sm_type,
    concat(cc.cc_city, ':', w.w_city),
    substring(cc.cc_name, 1, 10),
    regexp_extract(r.r_reason_desc, '(\\w+)$', 1)
HAVING sum(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
