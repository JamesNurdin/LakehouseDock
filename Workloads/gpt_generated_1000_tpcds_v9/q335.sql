WITH ship_modes_union AS (
    SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'
    UNION
    SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'GROUND'
),
item_sales_summary AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_formulation,
        i.i_category,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        regexp_extract(i.i_formulation, '(plum)', 1) AS plum_match
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_formulation, 'plum')
      AND cc.cc_suite_number LIKE 'Suite %'
    GROUP BY i.i_item_sk,
             i.i_item_id,
             i.i_brand,
             i.i_formulation,
             i.i_category,
             cs.cs_call_center_sk,
             cs.cs_ship_mode_sk,
             regexp_extract(i.i_formulation, '(plum)', 1)
)
SELECT
    iss.i_item_id,
    substring(iss.i_item_id FROM 1 FOR 3) AS item_prefix,
    iss.i_brand,
    iss.i_category,
    iss.i_formulation,
    iss.plum_match,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    sm.sm_type,
    iss.total_sales,
    iss.total_profit,
    CASE WHEN iss.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    (SELECT MAX(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = iss.i_item_sk) AS max_item_sales_price,
    (SELECT AVG(cs3.cs_net_profit)
     FROM catalog_sales cs3
     JOIN item i3 ON cs3.cs_item_sk = i3.i_item_sk
     WHERE i3.i_brand = iss.i_brand) AS avg_brand_profit,
    EXISTS (SELECT 1 FROM ship_mode sm2 WHERE sm2.sm_ship_mode_sk = iss.cs_ship_mode_sk AND sm2.sm_code LIKE 'SM%') AS ship_mode_code_match
FROM item_sales_summary iss
JOIN call_center cc ON iss.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON iss.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE iss.cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_modes_union)
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs4
        WHERE cs4.cs_call_center_sk = iss.cs_call_center_sk
          AND cs4.cs_ext_list_price > 5000
          AND cs4.cs_ship_mode_sk = iss.cs_ship_mode_sk
    )
ORDER BY iss.total_sales DESC
LIMIT 100
