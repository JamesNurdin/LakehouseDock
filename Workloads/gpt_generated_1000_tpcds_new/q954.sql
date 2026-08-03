WITH sales_by_center AS (
   SELECT
      cs.cs_call_center_sk,
      cc.cc_name,
      sm.sm_ship_mode_id,
      SUM(cs.cs_ext_sales_price) AS total_sales
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cc.cc_state = 'CA'
     AND sm.sm_code = 'AIR'
   GROUP BY cs.cs_call_center_sk, cc.cc_name, sm.sm_ship_mode_id
),
full_center_ship AS (
   SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      sm.sm_ship_mode_sk,
      sm.sm_ship_mode_id
   FROM call_center cc
   FULL OUTER JOIN ship_mode sm ON 1 = 1
)
SELECT
   fcs.cc_call_center_sk,
   fcs.cc_name,
   fcs.sm_ship_mode_id,
   sbc.total_sales,
   (SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_call_center_sk = fcs.cc_call_center_sk
        AND cs2.cs_ship_mode_sk = fcs.sm_ship_mode_sk) AS sales_all_modes
FROM full_center_ship fcs
LEFT JOIN sales_by_center sbc
  ON fcs.cc_call_center_sk = sbc.cs_call_center_sk
  AND fcs.sm_ship_mode_id = sbc.sm_ship_mode_id
WHERE EXISTS (
   SELECT 1
   FROM catalog_sales cs3
   WHERE cs3.cs_call_center_sk = fcs.cc_call_center_sk
     AND cs3.cs_ship_mode_sk = fcs.sm_ship_mode_sk
     AND cs3.cs_ext_tax > 20
)
UNION ALL
SELECT
   cc.cc_call_center_sk,
   cc.cc_name,
   sm.sm_ship_mode_id,
   CAST(0.0 AS decimal(7,2)) AS total_sales,
   (SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        AND cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk) AS sales_all_modes
FROM call_center cc
JOIN ship_mode sm ON sm.sm_ship_mode_sk = 3
WHERE cc.cc_sq_ft > 50000000
  AND sm.sm_contract LIKE 'P7FBIt8yd%'
  AND EXISTS (
    SELECT 1
    FROM catalog_sales cs4
    WHERE cs4.cs_call_center_sk = cc.cc_call_center_sk
      AND cs4.cs_ship_mode_sk = sm.sm_ship_mode_sk
      AND cs4.cs_ext_tax > 20
)
ORDER BY total_sales DESC
LIMIT 100
