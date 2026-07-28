WITH store_part AS (
    SELECT r.r_reason_desc AS reason,
           sr.sr_net_loss AS loss,
           'Store' AS src
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE t.t_meal_time = 'lunch'
      AND s.s_state = 'CA'
),
catalog_part AS (
    SELECT r.r_reason_desc AS reason,
           cr.cr_net_loss AS loss,
           'Catalog' AS src
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE t.t_meal_time = 'lunch'
      AND sm.sm_carrier = 'PRIVATECARRIER'
)
SELECT reason,
       src,
       SUM(loss) AS total_loss
FROM (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM catalog_part
) AS combined
GROUP BY reason, src
ORDER BY reason, src
