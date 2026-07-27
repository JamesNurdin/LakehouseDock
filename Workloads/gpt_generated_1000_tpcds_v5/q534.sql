WITH sales_agg AS (
    SELECT
        cs_ship_mode_sk,
        cs_bill_hdemo_sk,
        SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 500
      AND cs_ext_ship_cost < 2000
      AND cs_quantity >= 2
    GROUP BY cs_ship_mode_sk, cs_bill_hdemo_sk
    HAVING SUM(cs_net_paid_inc_ship_tax) > 5000
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    sa.total_net_paid,
    sa.avg_discount,
    sa.sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY sa.total_net_paid DESC) AS rn,
    CASE WHEN sm.sm_contract = 'HVDFCcQ' THEN 'Preferred' ELSE 'Standard' END AS contract_type,
    (SELECT MAX(cs_net_paid) FROM catalog_sales) AS max_net_paid_overall
FROM sales_agg sa
JOIN household_demographics hd
    ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE hd.hd_vehicle_count >= 0
  AND sm.sm_code IN ('AIR', 'SEA')
  AND EXISTS (
        SELECT 1 FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk
          AND sm2.sm_contract = 'HVDFCcQ'
    )
ORDER BY sm.sm_code, rn
LIMIT 100
