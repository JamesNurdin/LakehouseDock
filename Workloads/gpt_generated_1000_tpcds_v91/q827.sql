WITH
  sales_agg AS (
    SELECT
      cs.cs_order_number,
      SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
      CASE
        WHEN sm.sm_code = 'AIR' THEN 'Air'
        WHEN sm.sm_code = 'SEA' THEN 'Sea'
        ELSE 'Other'
      END AS ship_category,
      REGEXP_EXTRACT(sm.sm_ship_mode_id, '^AAAAAAA([AE])', 1) AS ship_mode_suffix
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(sm.sm_ship_mode_id, '^AAAAAAA[AE].*$')
      AND cc.cc_hours LIKE '%8AM-%'
    GROUP BY cs.cs_order_number, sm.sm_code, sm.sm_ship_mode_id
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 5000
  ),

  returns_agg AS (
    SELECT
      cr.cr_order_number,
      SUM(cr.cr_return_amount) AS total_return_amount,
      CASE
        WHEN cc.cc_class = 'large' THEN 'LargeCC'
        WHEN cc.cc_class = 'medium' THEN 'MediumCC'
        ELSE 'SmallCC'
      END AS cc_category,
      SUBSTRING(sm.sm_contract, 1, 5) AS contract_prefix
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE 'hGoF18%'
      AND REGEXP_LIKE(cc.cc_class, '^(medium|large)$')
    GROUP BY cr.cr_order_number, cc.cc_class, sm.sm_contract
    HAVING SUM(cr.cr_return_amount) > 1000
  ),

  intersect_orders AS (
    SELECT s.cs_order_number AS order_number
    FROM sales_agg s
    INTERSECT
    SELECT r.cr_order_number AS order_number
    FROM returns_agg r
  )
SELECT
  s.cs_order_number,
  s.total_net_paid_inc_ship_tax,
  s.ship_category,
  s.ship_mode_suffix,
  r.total_return_amount,
  r.cc_category,
  r.contract_prefix
FROM intersect_orders io
JOIN sales_agg s ON io.order_number = s.cs_order_number
JOIN returns_agg r ON io.order_number = r.cr_order_number
ORDER BY s.total_net_paid_inc_ship_tax DESC
LIMIT 100
