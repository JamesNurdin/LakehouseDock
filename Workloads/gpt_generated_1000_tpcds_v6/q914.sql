WITH returns_with_demo AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_returning_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_ship_mode_sk,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 20
      AND hd.hd_dep_count <= 4
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential LIKE '5%'
)
SELECT
    r.cr_returned_date_sk,
    r.cr_item_sk,
    r.cr_returning_customer_sk,
    r.cr_return_quantity,
    r.cr_return_amount,
    sm.sm_ship_mode_id,
    sm.sm_type,
    CASE
        WHEN r.cr_return_amount > 100 THEN 'HIGH'
        WHEN r.cr_return_amount > 50 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY r.cr_return_amount DESC) AS rn_type,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY r.cr_return_amount DESC) AS rank_type,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = r.cr_ship_mode_sk
          AND cr2.cr_return_amount IS NOT NULL
    ) AS avg_return_amount_by_shipmode
FROM returns_with_demo r
JOIN ship_mode sm
    ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
  AND sm.sm_ship_mode_id = 'AAAAAAAANAAAAAAA'
  AND r.cr_returning_customer_sk IN (4902047, 11079572, 1202670)
  AND r.cr_item_sk BETWEEN 200000 AND 300000
LIMIT 100
