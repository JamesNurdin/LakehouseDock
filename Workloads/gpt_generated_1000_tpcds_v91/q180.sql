WITH store_data AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        d.d_date AS return_date,
        d.d_weekend,
        d.d_qoy,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_fee
    FROM store_returns sr
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_weekend = 'N'
      AND ib.ib_upper_bound >= 60000
      AND sr.sr_return_quantity > 0
),
web_data AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        d.d_date AS return_date,
        d.d_weekend,
        d.d_qoy,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_fee
    FROM web_returns wr
    LEFT JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_weekend = 'N'
      AND ib.ib_upper_bound >= 60000
      AND wr.wr_return_quantity > 0
)
SELECT
    COALESCE(s.date_sk, w.date_sk) AS date_sk,
    COALESCE(s.return_date, w.return_date) AS return_date,
    COALESCE(s.ib_income_band_sk, w.ib_income_band_sk) AS income_band_sk,
    COALESCE(s.ib_lower_bound, w.ib_lower_bound) AS income_lower,
    COALESCE(s.ib_upper_bound, w.ib_upper_bound) AS income_upper,
    COALESCE(s.sr_net_loss, w.wr_net_loss) AS net_loss,
    CASE
        WHEN COALESCE(s.sr_net_loss, w.wr_net_loss) > 0 THEN 'Loss'
        WHEN COALESCE(s.sr_net_loss, w.wr_net_loss) < 0 THEN 'Gain'
        ELSE 'Neutral'
    END AS loss_indicator,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(s.ib_income_band_sk, w.ib_income_band_sk)
        ORDER BY COALESCE(s.sr_net_loss, w.wr_net_loss) DESC
    ) AS loss_rank
FROM store_data s
FULL OUTER JOIN web_data w
    ON s.date_sk = w.date_sk
   AND s.ib_income_band_sk = w.ib_income_band_sk
ORDER BY date_sk ASC, loss_rank ASC
