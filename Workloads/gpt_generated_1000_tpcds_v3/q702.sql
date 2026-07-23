WITH filtered_store_returns AS (
    SELECT
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        sr_net_loss,
        sr_hdemo_sk,
        sr_return_time_sk
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 100
)
SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    td.t_sub_shift,
    td.t_hour,
    COUNT(*) AS return_cnt,
    SUM(fsr.sr_return_amt) AS total_return_amt,
    AVG(fsr.sr_return_quantity) AS avg_quantity,
    MIN(fsr.sr_return_amt_inc_tax) AS min_return_amt_inc_tax,
    MAX(fsr.sr_return_tax) AS max_return_tax,
    SUM(fsr.sr_net_loss) AS total_net_loss
FROM filtered_store_returns fsr
INNER JOIN time_dim td
    ON fsr.sr_return_time_sk = td.t_time_sk
INNER JOIN household_demographics hd
    ON fsr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_buy_potential = '>10000'
  AND hd.hd_dep_count >= 2
  AND ib.ib_upper_bound >= 130000
  AND ib.ib_lower_bound <= 80001
  AND td.t_sub_shift = 'evening'
  AND td.t_hour >= 6
GROUP BY
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    td.t_sub_shift,
    td.t_hour
ORDER BY total_return_amt DESC
