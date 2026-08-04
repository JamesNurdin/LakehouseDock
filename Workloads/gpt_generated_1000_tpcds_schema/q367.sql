WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        i.i_item_id,
        i.i_formulation,
        cc.cc_call_center_id,
        cc.cc_state,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_formulation LIKE '%steel%'
      AND hd.hd_vehicle_count > 0
)
SELECT
    COALESCE(jd.cc_call_center_id, 'UNKNOWN') AS call_center_id,
    jd.i_item_id,
    w.w_warehouse_name,
    jd.cr_return_amount,
    CASE WHEN jd.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = jd.cr_item_sk
    ) AS avg_return_amount_for_item,
    ROW_NUMBER() OVER (PARTITION BY jd.cc_call_center_id ORDER BY jd.cr_return_amount DESC) AS rn,
    SUM(jd.cr_return_amount) OVER (PARTITION BY jd.cc_call_center_id) AS total_return_amount_by_center
FROM joined_data jd
FULL OUTER JOIN warehouse w
    ON jd.cr_warehouse_sk = w.w_warehouse_sk
WHERE (w.w_county = 'Walker County' OR w.w_county IS NULL)
ORDER BY rn
LIMIT 100
