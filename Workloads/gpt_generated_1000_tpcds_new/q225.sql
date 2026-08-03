WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_amt > 20.00
),
joined AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_id,
        s.s_tax_percentage,
        s.s_city
    FROM sampled_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_tax_percentage > 0.03
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_lower_bound >= 60000
),
agg_per_store_income AS (
    SELECT
        s_store_id,
        ib_lower_bound,
        ib_upper_bound,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_fee) AS total_fee,
        SUM(sr_net_loss) AS total_net_loss
    FROM joined
    GROUP BY s_store_id, ib_lower_bound, ib_upper_bound
),
final_agg AS (
    SELECT
        s_store_id,
        SUM(total_return_amt) AS store_total_return,
        SUM(total_fee) AS store_total_fee,
        SUM(total_net_loss) AS store_total_net_loss,
        AVG(total_return_amt) AS avg_return_per_income_band,
        COUNT(*) AS income_band_cnt
    FROM agg_per_store_income
    GROUP BY s_store_id
    HAVING SUM(total_return_amt) > 1000
)
SELECT
    s_store_id,
    store_total_return,
    store_total_fee,
    store_total_net_loss,
    (store_total_fee / NULLIF(store_total_return, 0)) AS fee_to_return_ratio,
    avg_return_per_income_band
FROM final_agg
WHERE (store_total_fee / NULLIF(store_total_return, 0)) > 0.04
ORDER BY fee_to_return_ratio DESC
LIMIT 100
