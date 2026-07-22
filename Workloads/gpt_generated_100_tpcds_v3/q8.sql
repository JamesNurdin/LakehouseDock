SELECT d.d_year AS year,
       sm.sm_ship_mode_id AS category,
       sum(cr.cr_return_amount) AS total_return_amount
FROM tpcds.catalog_returns AS cr
JOIN tpcds.date_dim AS d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.ship_mode AS sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer_demographics AS cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND cd.cd_gender = 'F'
  AND cd.cd_education_status = 'College'
GROUP BY d.d_year, sm.sm_ship_mode_id
HAVING sum(cr.cr_return_amount) > (
    SELECT avg(cr2.cr_return_amount)
    FROM tpcds.catalog_returns AS cr2
)
UNION ALL
SELECT d.d_year AS year,
       cc.cc_manager AS category,
       sum(cr.cr_return_amount) AS total_return_amount
FROM tpcds.catalog_returns AS cr
JOIN tpcds.date_dim AS d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.call_center AS cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 2001
  AND cc.cc_manager = 'Travis Wilson'
  AND cc.cc_tax_percentage > 0.05
GROUP BY d.d_year, cc.cc_manager
HAVING sum(cr.cr_return_amount) > (
    SELECT avg(cr2.cr_return_amount)
    FROM tpcds.catalog_returns AS cr2
)
ORDER BY total_return_amount DESC
LIMIT 100
