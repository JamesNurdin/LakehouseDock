WITH base AS (
    SELECT
        cr.cr_reason_sk,
        r.r_reason_desc,
        cr.cr_net_loss,
        cr.cr_return_amount,
        wr.wr_return_ship_cost,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_income_band_sk
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 4
      AND hd.hd_income_band_sk IN (4, 6, 8)
      AND hd.hd_buy_potential IN ('501-1000', '>10000')
      AND cr.cr_net_loss > 100.00
      AND wr.wr_return_ship_cost < 1000.00
),
agg_by_reason AS (
    SELECT
        r_reason_desc,
        hd_buy_potential,
        COUNT(*) AS return_cnt,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(wr_return_ship_cost) AS total_ship_cost,
        AVG(cr_return_amount) AS avg_return_amount
    FROM base
    GROUP BY r_reason_desc, hd_buy_potential
)
SELECT
    r_reason_desc,
    hd_buy_potential,
    return_cnt,
    total_net_loss,
    total_ship_cost,
    avg_return_amount,
    total_net_loss / NULLIF(return_cnt, 0) AS avg_net_loss_per_return,
    total_ship_cost / NULLIF(return_cnt, 0) AS avg_ship_cost_per_return
FROM agg_by_reason
WHERE return_cnt >= 5
  AND total_net_loss > 500.00
ORDER BY total_net_loss DESC
LIMIT 20
