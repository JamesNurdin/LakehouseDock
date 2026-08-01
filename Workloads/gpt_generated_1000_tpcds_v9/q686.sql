WITH agg_returns AS (
    SELECT
        cr_returning_addr_sk,
        cr_returning_hdemo_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 100
    GROUP BY cr_returning_addr_sk, cr_returning_hdemo_sk, cr_reason_sk
)
SELECT
    ca_ret.ca_state,
    ca_ret.ca_city,
    hd_ret.hd_dep_count,
    hd_ret.hd_vehicle_count,
    income_band.ib_lower_bound,
    income_band.ib_upper_bound,
    reason.r_reason_desc,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.return_cnt,
    CASE
        WHEN agg.total_net_loss > (
            SELECT AVG(cr_net_loss)
            FROM catalog_returns
            WHERE cr_returning_hdemo_sk = agg.cr_returning_hdemo_sk
        ) THEN 'Above Avg Loss'
        ELSE 'Below Avg Loss'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY ca_ret.ca_state ORDER BY agg.total_net_loss DESC) AS state_rank
FROM agg_returns AS agg
JOIN customer_address AS ca_ret
    ON agg.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN household_demographics AS hd_ret
    ON agg.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band
    ON hd_ret.hd_income_band_sk = income_band.ib_income_band_sk
JOIN reason
    ON agg.cr_reason_sk = reason.r_reason_sk
WHERE
    hd_ret.hd_dep_count <= 3
    AND hd_ret.hd_vehicle_count >= 0
    AND income_band.ib_lower_bound >= 30000
    AND reason.r_reason_desc LIKE '%product%'
    AND ca_ret.ca_state IN ('CA', 'TX')
ORDER BY ca_ret.ca_state, state_rank
