WITH
  center_details AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_city,
      REGEXP_EXTRACT(cc.cc_city, '(\\w+)', 1) AS city_first_word,
      CASE
        WHEN REGEXP_LIKE(cc.cc_mkt_desc, 'eyes') THEN 'has_eyes'
        ELSE 'no_eyes'
      END AS mkt_desc_tag
    FROM call_center cc
    WHERE cc.cc_city LIKE '%View%' OR cc.cc_city LIKE 'Cedar%'
  ),
  ship_mode_details AS (
    SELECT
      sm.sm_ship_mode_sk,
      sm.sm_type,
      sm.sm_carrier,
      CASE
        WHEN REGEXP_LIKE(sm.sm_carrier, '^US') THEN 'US_carrier'
        ELSE 'non_US'
      END AS carrier_region
    FROM ship_mode sm
    WHERE sm.sm_type LIKE 'Air%'
  ),
  sales_by_center_mode AS (
    SELECT
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_ship_mode_sk
  ),
  combined AS (
    SELECT
      cd.cc_call_center_sk,
      cd.cc_name,
      cd.city_first_word,
      smd.sm_ship_mode_sk,
      smd.sm_type,
      sbcm.total_net_paid,
      sbcm.sales_cnt,
      CONCAT(cd.cc_name, '_', smd.sm_type) AS center_mode_label,
      ROW_NUMBER() OVER (ORDER BY sbcm.total_net_paid DESC NULLS LAST) AS global_rn
    FROM center_details cd
    FULL OUTER JOIN ship_mode_details smd
      ON cd.cc_call_center_sk = smd.sm_ship_mode_sk
    LEFT JOIN sales_by_center_mode sbcm
      ON sbcm.cs_call_center_sk = cd.cc_call_center_sk
     AND sbcm.cs_ship_mode_sk = smd.sm_ship_mode_sk
  )
SELECT
  global_rn,
  cc_call_center_sk,
  cc_name,
  city_first_word,
  sm_ship_mode_sk,
  sm_type,
  total_net_paid,
  sales_cnt,
  center_mode_label
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    JOIN time_dim td ON cs2.cs_sold_time_sk = td.t_time_sk
    WHERE cs2.cs_call_center_sk = c.cc_call_center_sk
      AND td.t_am_pm = 'PM'
      AND td.t_sub_shift = 'evening'
  )
EXCEPT
SELECT
  global_rn,
  cc_call_center_sk,
  cc_name,
  city_first_word,
  sm_ship_mode_sk,
  sm_type,
  total_net_paid,
  sales_cnt,
  center_mode_label
FROM combined
WHERE total_net_paid IS NULL
ORDER BY total_net_paid DESC NULLS LAST, global_rn
LIMIT 100
