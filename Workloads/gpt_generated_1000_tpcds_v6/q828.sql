SELECT
    cc.cc_call_center_id,
    regexp_extract(cc.cc_name, '(\\w+)') AS first_word,
    concat(cc.cc_name, ' - ', cc.cc_company_name) AS full_label,
    d.d_fy_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
     WHERE d2.d_fy_year = d.d_fy_year) AS overall_avg_return_amount,
    SUM(CASE WHEN cr.cr_returning_cdemo_sk IN (
        SELECT DISTINCT cr3.cr_refunded_cdemo_sk
        FROM catalog_returns cr3
        WHERE cr3.cr_store_credit > 500
    ) THEN 1 ELSE 0 END) AS matching_demo_cnt
FROM catalog_returns AS cr
JOIN date_dim AS d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center AS cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_fy_year = 1902
  AND regexp_like(cc.cc_name, 'center')
  AND cc.cc_company_name LIKE 'a%'
GROUP BY
    cc.cc_call_center_id,
    regexp_extract(cc.cc_name, '(\\w+)'),
    concat(cc.cc_name, ' - ', cc.cc_company_name),
    d.d_fy_year
ORDER BY total_net_loss DESC
LIMIT 100
