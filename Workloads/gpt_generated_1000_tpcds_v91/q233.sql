/* goal: Compute total net return and average return quantity per return reason and customer gender, filtered by purchase estimate, vehicle count, return amount and income band, then rank reasons by total net return */
WITH base AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_tax,
        wr.wr_account_credit,
        wr.wr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc AS r_reason_desc,
        (wr.wr_return_amt - wr.wr_return_tax) AS net_return_without_tax,
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_reason_sk = wr.wr_reason_sk) AS same_reason_return_cnt
    FROM web_returns wr
    LEFT JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    FULL OUTER JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT r2.r_reason_desc AS alt_reason_desc
        FROM reason r2
        WHERE r2.r_reason_sk = wr.wr_reason_sk
        LIMIT 1
    ) alt
    WHERE cd.cd_purchase_estimate > 3000
      AND hd.hd_vehicle_count <= 2
      AND wr.wr_return_amt > 50
      AND ib.ib_lower_bound > 20000
),
agg1 AS (
    SELECT
        r_reason_desc,
        cd_gender,
        cd_purchase_estimate,
        SUM(net_return_without_tax) AS total_net_return,
        AVG(wr_return_quantity) AS avg_return_qty,
        COUNT(*) AS cnt_returns,
        SUM(same_reason_return_cnt) AS sum_same_reason_cnt
    FROM base
    GROUP BY r_reason_desc, cd_gender, cd_purchase_estimate
),
agg2 AS (
    SELECT
        r_reason_desc,
        total_net_return,
        avg_return_qty,
        cnt_returns,
        sum_same_reason_cnt,
        RANK() OVER (ORDER BY total_net_return DESC) AS net_return_rank
    FROM agg1
    WHERE cnt_returns >= 5
)
SELECT
    r_reason_desc,
    total_net_return,
    avg_return_qty,
    cnt_returns,
    net_return_rank
FROM agg2
ORDER BY net_return_rank
LIMIT 100
