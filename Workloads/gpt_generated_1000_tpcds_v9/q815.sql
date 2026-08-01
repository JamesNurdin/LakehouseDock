WITH base_agg AS (
    SELECT
        sr.sr_store_sk,
        td.t_sub_shift,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_store_credit) AS avg_store_credit,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_return_amt > 0
        AND sr.sr_fee >= 2.00
        AND sr.sr_return_ship_cost <= 500
        AND sr.sr_return_quantity >= 1
        AND td.t_sub_shift IN ('morning', 'afternoon', 'evening', 'night')
        AND td.t_meal_time <> 'dinner'
    GROUP BY sr.sr_store_sk, td.t_sub_shift
),
ranked_agg AS (
    SELECT
        ba.sr_store_sk,
        ba.t_sub_shift,
        ba.total_return_amt,
        ba.total_net_loss,
        ba.avg_store_credit,
        ba.cnt_returns,
        CASE
            WHEN ba.avg_store_credit >= 500 THEN 'high_credit'
            WHEN ba.avg_store_credit >= 100 THEN 'mid_credit'
            ELSE 'low_credit'
        END AS credit_tier,
        RANK() OVER (PARTITION BY ba.t_sub_shift ORDER BY ba.total_return_amt DESC) AS rank_by_return_amt
    FROM base_agg ba
    WHERE ba.total_return_amt > 1000
        AND ba.total_net_loss < 5000
        AND ba.cnt_returns >= 5
        AND ba.avg_store_credit IS NOT NULL
        AND ba.total_return_amt / ba.cnt_returns > 200
)
SELECT
    sr_store_sk,
    t_sub_shift,
    credit_tier,
    SUM(total_return_amt) AS sum_total_return_amt,
    SUM(total_net_loss) AS sum_total_net_loss,
    AVG(avg_store_credit) AS avg_of_avg_store_credit,
    COUNT(*) AS grp_count,
    MAX(rank_by_return_amt) AS max_rank_by_return_amt
FROM ranked_agg
GROUP BY GROUPING SETS (
    (sr_store_sk, t_sub_shift, credit_tier),
    (t_sub_shift, credit_tier),
    (credit_tier),
    ()
)
ORDER BY sr_store_sk, t_sub_shift, credit_tier
LIMIT 100
