WITH filtered_ship AS (
    SELECT DISTINCT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_code,
        sm_carrier,
        sm_contract
    FROM ship_mode
    WHERE sm_code = 'AIR'
      AND sm_contract LIKE 'hGoF18%'
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    t.t_hour,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(cr.cr_net_loss) AS min_net_loss,
    MAX(cr.cr_net_loss) AS max_net_loss
FROM filtered_ship sm
JOIN catalog_returns cr
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
WHERE t.t_minute IN (3, 14, 18)
  AND cr.cr_store_credit > 100
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
          AND ws.ws_sold_time_sk = t.t_time_sk
          AND ws.ws_quantity > 5
    )
GROUP BY
    sm.sm_carrier,
    sm.sm_code,
    t.t_hour
ORDER BY
    total_return_amount DESC
LIMIT 100
