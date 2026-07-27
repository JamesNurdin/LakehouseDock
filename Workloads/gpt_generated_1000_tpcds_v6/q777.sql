SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    sm.sm_type,
    CONCAT(sm.sm_code, '_', COALESCE(sm.sm_carrier, '')) AS mode_full,
    REGEXP_EXTRACT(sm.sm_ship_mode_id, '(A+)', 1) AS a_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(cr.cr_refunded_cash) AS avg_refunded_cash
FROM catalog_returns cr
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE REGEXP_LIKE(sm.sm_code, '^A')                             -- code starts with 'A' (e.g., "AIR")
  AND sm.sm_carrier LIKE '%AIR%'                                 -- carrier contains the word AIR
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
          AND ws2.ws_net_paid > 1000
      )
  AND cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
      )
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_code,
    sm.sm_type,
    CONCAT(sm.sm_code, '_', COALESCE(sm.sm_carrier, '')),
    REGEXP_EXTRACT(sm.sm_ship_mode_id, '(A+)', 1)
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 10
