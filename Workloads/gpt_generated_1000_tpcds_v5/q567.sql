WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_fee > 20
      AND wr.wr_return_quantity >= 2
      AND wr.wr_return_amt > 100
      AND wr.wr_return_tax < 30
)
SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS cnt_returns,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_fee) AS avg_fee,
    MIN(fr.wr_net_loss) AS min_net_loss,
    MAX(fr.wr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN household_demographics hd
    ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
  AND ib.ib_upper_bound BETWEEN 100000 AND 180000
  AND EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
          AND ib2.ib_lower_bound < 150000
      )
GROUP BY
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
