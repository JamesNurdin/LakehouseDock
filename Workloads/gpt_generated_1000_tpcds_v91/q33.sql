WITH cr_agg AS (
    SELECT
        cr_ship_mode_sk,
        cr_returned_time_sk,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM catalog_returns
    WHERE cr_return_tax > 0
      AND cr_reversed_charge < 200
      AND cr_return_quantity >= 1
      AND cr_return_amount > 0
      AND cr_return_ship_cost <= 50
    GROUP BY cr_ship_mode_sk, cr_returned_time_sk
),
carrier_filter AS (
    SELECT DISTINCT sm.sm_carrier
    FROM ship_mode sm
    WHERE sm.sm_code IN ('AIR', 'SEA')
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    td.t_hour,
    td.t_am_pm,
    ca.return_cnt,
    ca.total_return_amount,
    ca.avg_return_amount,
    ca.min_return_amount,
    ca.max_return_amount,
    (
        SELECT MAX(cr_return_tax)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
    ) AS max_return_tax,
    ROW_NUMBER() OVER (PARTITION BY td.t_am_pm ORDER BY ca.total_return_amount DESC) AS carrier_rank,
    flag_set.flag
FROM cr_agg ca
JOIN ship_mode sm
    ON ca.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON ca.cr_returned_time_sk = td.t_time_sk
JOIN carrier_filter cf
    ON sm.sm_carrier = cf.sm_carrier
CROSS JOIN (SELECT 1 AS flag UNION ALL SELECT 2 AS flag) AS flag_set
WHERE sm.sm_carrier = 'LATVIAN'
  AND td.t_minute IN (0, 5, 8, 18)
  AND td.t_am_pm = 'PM'
  AND sm.sm_carrier <> 'ZHOU'
ORDER BY ca.total_return_amount DESC, sm.sm_carrier
LIMIT 100
