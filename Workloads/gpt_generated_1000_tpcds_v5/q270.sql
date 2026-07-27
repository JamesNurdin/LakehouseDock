WITH warehouse_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 1000
    GROUP BY cr.cr_warehouse_sk, w.w_warehouse_name
)
SELECT
    'HighLoss' AS loss_category,
    wr.w_warehouse_name,
    wr.total_return_amount,
    wr.total_net_loss,
    CASE WHEN wr.total_net_loss > 5000 THEN 'Critical' ELSE 'Moderate' END AS risk_level
FROM warehouse_returns wr
WHERE wr.total_net_loss > 5000

UNION ALL

SELECT
    'LowLoss' AS loss_category,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'Alert' ELSE 'Normal' END AS risk_level
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND cr.cr_return_amount BETWEEN 0 AND 500
GROUP BY w.w_warehouse_name
HAVING SUM(cr.cr_net_loss) > 0

ORDER BY loss_category, total_net_loss DESC
LIMIT 100
