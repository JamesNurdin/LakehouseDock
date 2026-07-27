WITH cc_returns_maverick AS (
   SELECT
       cc.cc_county,
       cc.cc_city,
       cc.cc_name,
       SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
       SUM(cr.cr_return_tax) AS total_return_tax,
       COUNT(*) AS return_cnt
   FROM tpcds.catalog_returns cr
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_county = 'Maverick County'
     AND cr.cr_return_amt_inc_tax > 1000
     AND cc.cc_rec_start_date >= DATE '2000-01-01'
   GROUP BY cc.cc_county, cc.cc_city, cc.cc_name
),
cc_returns_levy AS (
   SELECT
       cc.cc_county,
       cc.cc_city,
       cc.cc_name,
       SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
       SUM(cr.cr_return_tax) AS total_return_tax,
       COUNT(*) AS return_cnt
   FROM tpcds.catalog_returns cr
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_county = 'Levy County'
     AND cr.cr_return_amt_inc_tax <= 500
     AND cc.cc_rec_start_date >= DATE '2000-01-01'
   GROUP BY cc.cc_county, cc.cc_city, cc.cc_name
)
SELECT
    cc_county,
    cc_city,
    cc_name,
    total_return_amount,
    total_return_tax,
    return_cnt
FROM cc_returns_maverick
UNION ALL
SELECT
    cc_county,
    cc_city,
    cc_name,
    total_return_amount,
    total_return_tax,
    return_cnt
FROM cc_returns_levy
ORDER BY total_return_amount DESC
LIMIT 100
