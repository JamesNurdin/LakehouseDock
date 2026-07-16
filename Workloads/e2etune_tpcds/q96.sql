WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_returned_date_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
      AND cr.cr_ship_mode_sk IN (7, 12)
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
),
agg AS (
    SELECT
        r.r_reason_desc,
        hd_ret.hd_buy_potential,
        COUNT(*) AS num_returns,
        SUM(f.cr_net_loss) AS total_net_loss,
        AVG(f.cr_return_amount) AS avg_return_amount
    FROM filtered f
    JOIN reason r ON f.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_ret ON f.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    GROUP BY r.r_reason_desc, hd_ret.hd_buy_potential
    HAVING COUNT(*) >= 5
)
SELECT
    agg.r_reason_desc,
    agg.hd_buy_potential,
    agg.num_returns,
    agg.total_net_loss,
    agg.avg_return_amount,
    ROW_NUMBER() OVER (PARTITION BY agg.hd_buy_potential ORDER BY agg.total_net_loss DESC) AS loss_rank_within_potential
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 50
