WITH reason_agg AS (
    SELECT
        cr_reason_sk,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        COUNT(*) AS total_returns
    FROM catalog_returns
    WHERE cr_return_quantity > 10
      AND cr_reversed_charge BETWEEN 20 AND 200
    GROUP BY cr_reason_sk
),
call_center_agg AS (
    SELECT
        cr_reason_sk,
        cr_call_center_sk,
        AVG(cr_reversed_charge) AS avg_reversed_charge,
        SUM(cr_return_quantity) AS total_quantity
    FROM catalog_returns
    GROUP BY cr_reason_sk, cr_call_center_sk
)
SELECT
    ra.cr_reason_sk,
    ra.total_net_loss,
    ra.avg_return_amount,
    ra.distinct_orders,
    ra.total_returns,
    cca.cr_call_center_sk,
    cca.avg_reversed_charge,
    cca.total_quantity,
    ROW_NUMBER() OVER (ORDER BY ra.total_net_loss DESC) AS net_loss_rank,
    (SELECT COUNT(*) FROM web_site WHERE web_state = 'CA') AS ca_web_sites
FROM reason_agg ra
JOIN call_center_agg cca
  ON ra.cr_reason_sk = cca.cr_reason_sk
WHERE ra.total_net_loss > 0
ORDER BY ra.total_net_loss DESC
LIMIT 10
