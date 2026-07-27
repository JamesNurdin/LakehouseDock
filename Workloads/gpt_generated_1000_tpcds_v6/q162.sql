WITH returns_a AS (
    SELECT
        sm.sm_carrier AS carrier,
        w.w_city AS city,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450990 AND 2450995
      AND sm.sm_carrier = 'BOXBUNDLES'
      AND w.w_county = 'Fairfield County'
    GROUP BY sm.sm_carrier, w.w_city
),
returns_b AS (
    SELECT
        sm.sm_carrier AS carrier,
        w.w_city AS city,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451030 AND 2451035
      AND sm.sm_carrier = 'GREAT EASTERN'
      AND w.w_county = 'Ziebach County'
    GROUP BY sm.sm_carrier, w.w_city
)
SELECT carrier, city, total_return_amount
FROM returns_a
UNION ALL
SELECT carrier, city, total_return_amount
FROM returns_b
ORDER BY total_return_amount DESC
LIMIT 100
