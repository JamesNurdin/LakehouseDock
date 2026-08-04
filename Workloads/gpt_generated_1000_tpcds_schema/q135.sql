WITH sub1 AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_ship_cost,
    sm.sm_code,
    sm.sm_contract
  FROM catalog_returns cr
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'AIR'
    AND cr.cr_return_amount > 1000
    AND EXISTS (
      SELECT 1
      FROM ship_mode sm2
      WHERE sm2.sm_contract = 'A5BYO1qH8HGTTN'
    )
),
sub2 AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_ship_cost,
    sm.sm_code,
    sm.sm_contract
  FROM catalog_returns cr
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'SEA'
    AND cr.cr_return_amount < 500
    AND cr.cr_refunded_hdemo_sk IN (
      SELECT cr2.cr_refunded_hdemo_sk
      FROM catalog_returns cr2
      WHERE cr2.cr_return_ship_cost > 1000
    )
)
SELECT
  u.cr_order_number,
  u.cr_return_amount,
  u.cr_return_ship_cost,
  u.sm_code,
  u.sm_contract,
  ROW_NUMBER() OVER (ORDER BY u.cr_return_amount DESC) AS row_num
FROM (
  SELECT * FROM sub1
  UNION ALL
  SELECT * FROM sub2
) u
ORDER BY row_num
LIMIT 100
