WITH aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND cr.cr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY cc.cc_name, sm.sm_type, r.r_reason_desc
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    call_center_name,
    ship_mode_type,
    reason_desc,
    total_net_loss,
    return_count,
    avg_quantity,
    total_net_loss / SUM(total_net_loss) OVER (PARTITION BY call_center_name) AS pct_of_center_loss,
    RANK() OVER (PARTITION BY call_center_name ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 50
