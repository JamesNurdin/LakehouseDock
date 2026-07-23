WITH avg_net AS (
    SELECT AVG(cs.cs_net_paid_inc_tax) AS avg_net
    FROM catalog_sales cs
)

SELECT
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    cd.cd_credit_rating,
    cd.cd_gender,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    (
        SELECT COUNT(DISTINCT sm2.sm_carrier)
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk
    ) AS carrier_count
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_gender = 'F'
  AND cs.cs_net_paid_inc_tax > (SELECT avg_net FROM avg_net)
  AND sm.sm_carrier IN (
        SELECT DISTINCT sm2.sm_carrier
        FROM ship_mode sm2
        WHERE sm2.sm_code = 'AIR'
    )
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_ship_mode_sk,
    w.w_warehouse_name,
    cd.cd_credit_rating,
    cd.cd_gender

UNION ALL

SELECT
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    cd.cd_credit_rating,
    cd.cd_gender,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    (
        SELECT COUNT(DISTINCT sm2.sm_carrier)
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = sm.sm_ship_mode_sk
    ) AS carrier_count
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_gender = 'M'
  AND cs.cs_net_paid_inc_tax > (SELECT avg_net FROM avg_net)
  AND sm.sm_carrier IN (
        SELECT DISTINCT sm2.sm_carrier
        FROM ship_mode sm2
        WHERE sm2.sm_code = 'SEA'
    )
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_ship_mode_sk,
    w.w_warehouse_name,
    cd.cd_credit_rating,
    cd.cd_gender

ORDER BY total_net_paid DESC
LIMIT 100
