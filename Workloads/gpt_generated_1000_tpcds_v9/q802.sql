WITH filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_market_manager,
        cc.cc_city,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND cr.cr_return_amount > 50.00
      AND cr.cr_return_tax >= 5.00
),
agg AS (
    SELECT
        f.cc_call_center_sk,
        f.cc_name,
        f.cc_market_manager,
        f.cc_city,
        SUM(f.cr_net_loss) AS total_net_loss,
        SUM(f.cr_return_quantity) AS total_return_qty,
        AVG(f.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_count
    FROM filtered f
    GROUP BY
        f.cc_call_center_sk,
        f.cc_name,
        f.cc_market_manager,
        f.cc_city
    HAVING
        SUM(f.cr_net_loss) > 1000.00
        AND AVG(f.cr_return_amount) > 60.00
        AND COUNT(*) >= 5
)
SELECT
    a.cc_call_center_sk,
    a.cc_name,
    a.cc_market_manager,
    a.cc_city,
    a.total_net_loss,
    a.total_return_qty,
    a.avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.cc_market_manager ORDER BY a.total_net_loss DESC) AS rn_by_market,
    DENSE_RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank_global,
    (
        SELECT MAX(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = a.cc_call_center_sk
          AND cr2.cr_return_amount > 100.00
    ) AS max_loss_high_amount
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
