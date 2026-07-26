WITH band_category_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_category,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, i.i_category
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    i_category,
    num_returns,
    total_return_amount,
    total_net_loss,
    DENSE_RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_loss DESC) AS category_loss_rank,
    CASE
        WHEN total_net_loss > 5000 THEN 'Severe'
        WHEN total_net_loss BETWEEN 2000 AND 5000 THEN 'Moderate'
        ELSE 'Mild'
    END AS loss_severity
FROM band_category_agg
ORDER BY ib_income_band_sk, category_loss_rank
