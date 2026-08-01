WITH
  refunded AS (
    SELECT
      cc.cc_call_center_id,
      sm.sm_carrier,
      regexp_extract(cc.cc_name, '(\\w+) Center', 1) AS attr,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT cr.cr_order_number) AS orders_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cc.cc_name, '^.*Center$')
      AND sm.sm_carrier LIKE 'Fed%'
      AND cd.cd_dep_employed_count >= 2
    GROUP BY cc.cc_call_center_id, sm.sm_carrier, regexp_extract(cc.cc_name, '(\\w+) Center', 1)
    HAVING SUM(cr.cr_return_amount) > 500
  ),
  returning AS (
    SELECT
      cc.cc_call_center_id,
      sm.sm_carrier,
      substring(cc.cc_city, 1, 3) AS attr,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(DISTINCT cr.cr_order_number) AS orders_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer_demographics cd
      ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cd.cd_dep_college_count > 0
    GROUP BY cc.cc_call_center_id, sm.sm_carrier, substring(cc.cc_city, 1, 3)
    HAVING SUM(cr.cr_return_amount) > 500
  )
SELECT *
FROM refunded
UNION ALL
SELECT *
FROM returning
ORDER BY total_return_amount DESC
LIMIT 100
